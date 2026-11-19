#!/usr/bin/env python3
"""On-demand package update checks.

`check` prints one JSON report for the Updates popup. Nothing here is scheduled
or polled; the shell only runs it when the popup needs a report. System upgrades
are handled by `upgrade.sh` in the same directory.
"""

import argparse
from concurrent.futures import ThreadPoolExecutor
import json
from pathlib import Path
import re
import shutil
import subprocess
import sys
import time


COMMAND_TIMEOUT = 60
AUR_TIMEOUT = 90
AUR_HELPERS = ("yay", "paru")
ARCH_IDS = {"arch", "archlinux"}


class CommandError(RuntimeError):
    pass


def short_error(error, limit=300):
    text = " ".join(str(error).split())
    return text[:limit]


def run(cmd, timeout=COMMAND_TIMEOUT, ok_codes=(0,)):
    """Run a command with captured output, returning CompletedProcess."""
    try:
        result = subprocess.run(
            cmd, capture_output=True, text=True, errors="replace", timeout=timeout
        )
    except FileNotFoundError as error:
        raise CommandError(f"{cmd[0]} not found") from error
    except subprocess.TimeoutExpired as error:
        raise CommandError(f"{cmd[0]} timed out") from error
    except OSError as error:
        raise CommandError(f"{cmd[0]} failed: {error}") from error

    if result.returncode not in ok_codes:
        detail = (result.stderr or result.stdout).strip().splitlines()
        detail = detail[-1] if detail else ""
        raise CommandError(
            f"{cmd[0]} exited with {result.returncode}"
            + (f": {detail[:300]}" if detail else "")
        )
    return result


def read_os_release():
    try:
        return Path("/etc/os-release").read_text()
    except OSError:
        return ""


def is_arch(text):
    values = {}
    for line in text.splitlines():
        if "=" not in line:
            continue
        key, value = line.split("=", 1)
        values[key.strip()] = value.strip().strip('"').strip("'")

    if values.get("ID", "").casefold() in ARCH_IDS:
        return True
    likes = values.get("ID_LIKE", "").casefold().split()
    return "arch" in likes


def find_aur_helper():
    for helper in AUR_HELPERS:
        if shutil.which(helper):
            return helper
    return ""


def parse_version_updates(text):
    """Parse pacman, checkupdates, yay and paru `name old -> new` lines."""
    packages = []
    seen = set()
    for line in text.splitlines():
        line = line.strip()
        if not line:
            continue
        match = re.match(r"^(?:aur/)?(\S+?):?\s+(\S+)\s+->\s+(\S+)", line)
        if not match:
            continue
        name, old, new = match.groups()
        if name in seen:
            continue
        seen.add(name)
        packages.append({"name": name, "old": old, "new": new})
    return packages


def parse_apt(text):
    packages = []
    seen = set()
    for line in text.splitlines():
        match = re.match(r"^Inst\s+(\S+)\s+\[([^\]]+)\]\s+\((\S+)", line.strip())
        if not match:
            continue
        name, old, new = match.groups()
        if name in seen:
            continue
        seen.add(name)
        packages.append({"name": name, "old": old, "new": new})
    return packages


def parse_dnf(text):
    packages = []
    seen = set()
    obsoleting = False
    for line in text.splitlines():
        line = line.strip()
        if not line or line.startswith("Last metadata"):
            continue
        if line.startswith("Obsoleting"):
            obsoleting = True
            continue
        if obsoleting:
            continue
        fields = line.split()
        if len(fields) < 3:
            continue
        name_arch, new = fields[0], fields[1]
        name = re.sub(
            r"\.(?:x86_64|i686|aarch64|armv7hl|noarch|ppc64le|s390x)$",
            "",
            name_arch,
        )
        if name in seen:
            continue
        seen.add(name)
        packages.append({"name": name, "old": "", "new": new})
    return packages


def parse_flatpak_table(text):
    rows = {}
    for line in text.splitlines():
        line = line.strip()
        if not line:
            continue
        if "\t" in line:
            fields = [field.strip() for field in line.split("\t")]
        else:
            fields = line.split(None, 1)
        if len(fields) < 2 or not fields[0]:
            continue
        rows[fields[0]] = fields[1] if len(fields) > 1 else ""
    return rows


def parse_flatpak_updates(updates_text, installed_text):
    installed = parse_flatpak_table(installed_text)
    packages = []
    for name, new in parse_flatpak_table(updates_text).items():
        packages.append({"name": name, "old": installed.get(name, ""), "new": new})
    return packages


def parse_snap_table(text):
    rows = {}
    for line in text.splitlines():
        line = line.strip()
        if not line or line.startswith("Name") or line.startswith("All snaps"):
            continue
        fields = line.split()
        if len(fields) < 2:
            continue
        rows[fields[0]] = fields[1]
    return rows


def parse_snap_updates(refresh_text, installed_text):
    installed = parse_snap_table(installed_text)
    packages = []
    for name, new in parse_snap_table(refresh_text).items():
        packages.append({"name": name, "old": installed.get(name, ""), "new": new})
    return packages


HUMAN_PIPX = re.compile(
    r"^(.+?)(?:\s+\[pinned\])?(?:\s+\(injected in [^)]+\))?:\s+(\S+)\s+->\s+(\S+)\s*$"
)


def parse_pipx(text):
    packages = []
    seen = set()
    try:
        document = json.loads(text)
    except (TypeError, ValueError):
        document = None

    if isinstance(document, dict):
        data = document.get("data", document)
        entries = data.get("packages", []) if isinstance(data, dict) else []
        if isinstance(entries, list):
            for entry in entries:
                if not isinstance(entry, dict) or entry.get("pinned") or entry.get("injected"):
                    continue
                name = entry.get("package")
                old = entry.get("version")
                new = entry.get("latest_version")
                if not name or name in seen:
                    continue
                seen.add(name)
                packages.append(
                    {
                        "name": str(name),
                        "old": "" if old is None else str(old),
                        "new": "" if new is None else str(new),
                    }
                )
            return packages

    for line in text.splitlines():
        line = line.strip()
        if not line or "[pinned]" in line or "(injected in " in line:
            continue
        match = HUMAN_PIPX.match(line)
        if not match:
            continue
        name, old, new = match.groups()
        if name in seen:
            continue
        seen.add(name)
        packages.append({"name": name, "old": old, "new": new})
    return packages


def collect_pacman():
    if shutil.which("checkupdates"):
        result = run(["checkupdates"], ok_codes=(0, 2))
        return parse_version_updates(result.stdout), ""

    result = run(["pacman", "-Qu"], ok_codes=(0, 1))
    return (
        parse_version_updates(result.stdout),
        "pacman-contrib is not installed; using the local sync database",
    )


def collect_aur(helper):
    result = run([helper, "-Qua"], timeout=AUR_TIMEOUT, ok_codes=(0, 1))
    if result.returncode == 1 and not result.stdout.strip() and "error" in result.stderr.casefold():
        raise CommandError(short_error(result.stderr))
    return parse_version_updates(result.stdout), ""


def collect_apt():
    result = run(["apt-get", "-s", "-q", "upgrade"])
    return parse_apt(result.stdout), ""


def collect_dnf():
    result = run(["dnf", "-q", "check-update"], timeout=AUR_TIMEOUT, ok_codes=(0, 100))
    return parse_dnf(result.stdout), ""


def collect_flatpak():
    updates = run(
        ["flatpak", "remote-ls", "--updates", "--columns=application,version"],
        timeout=AUR_TIMEOUT,
    )
    installed = run(["flatpak", "list", "--columns=application,version"])
    return parse_flatpak_updates(updates.stdout, installed.stdout), ""


def collect_snap():
    refresh = run(["snap", "refresh", "--list"])
    installed = run(["snap", "list"])
    return parse_snap_updates(refresh.stdout, installed.stdout), ""


def collect_pipx():
    result = run(
        ["pipx", "list", "--outdated", "--output", "json"],
        timeout=AUR_TIMEOUT,
        ok_codes=(0, 1),
    )
    return parse_pipx(result.stdout), ""


def manager_jobs(arch, aur_helper):
    jobs = []
    if arch and shutil.which("pacman"):
        jobs.append(("pacman", "Pacman", collect_pacman))
        if aur_helper:
            jobs.append(("aur", "AUR", lambda: collect_aur(aur_helper)))
    if shutil.which("apt-get"):
        jobs.append(("apt", "APT", collect_apt))
    if shutil.which("dnf"):
        jobs.append(("dnf", "DNF", collect_dnf))
    if shutil.which("flatpak"):
        jobs.append(("flatpak", "Flatpak", collect_flatpak))
    if shutil.which("snap"):
        jobs.append(("snap", "Snap", collect_snap))
    if shutil.which("pipx"):
        jobs.append(("pipx", "pipx", collect_pipx))
    return jobs


def collect_managers(jobs, parallel=True):
    jobs = list(jobs)
    if not jobs:
        return [], [{"level": "error", "text": "No supported package manager found"}]

    def collect(job):
        manager_id, label, collector = job
        try:
            packages, note = collector()
            return (
                {"id": manager_id, "label": label, "packages": packages},
                note,
                "",
            )
        except Exception as error:
            return (
                {"id": manager_id, "label": label, "packages": []},
                "",
                f"{label}: {short_error(error)}",
            )

    if parallel and len(jobs) > 1:
        with ThreadPoolExecutor(max_workers=min(8, len(jobs))) as pool:
            results = list(pool.map(collect, jobs))
    else:
        results = [collect(job) for job in jobs]

    managers = []
    notices = []
    for manager, note, error in results:
        managers.append(manager)
        if error:
            notices.append({"level": "error", "text": error})
        if note:
            notices.append({"level": "note", "text": f"{manager['label']}: {note}"})
    return managers, notices


def check(parallel=True):
    arch = is_arch(read_os_release())
    aur_helper = find_aur_helper() if arch else ""
    managers, notices = collect_managers(
        manager_jobs(arch, aur_helper), parallel=parallel
    )

    return {
        "ok": True,
        "checked": int(time.time()),
        "managers": managers,
        "notices": notices,
    }


def main(argv=None):
    parser = argparse.ArgumentParser(description="Slimshell update helper")
    operations = parser.add_subparsers(dest="operation", required=True)

    operations.add_parser("check", help="print pending updates as JSON")

    parser.parse_args(argv)
    try:
        report = check()
    except Exception as error:
        print(
            json.dumps({"ok": False, "error": short_error(error)}, ensure_ascii=True)
        )
        return 1
    print(json.dumps(report, ensure_ascii=True))
    return 0


if __name__ == "__main__":
    sys.exit(main())
