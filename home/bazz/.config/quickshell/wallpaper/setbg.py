#!/usr/bin/env python3
"""Wallpaper picker backend, adapted from setbg.py. No interactive prompts.

`list` streams JSON thumbnail records; `apply` emits one JSON result.
Only `apply` changes the desktop. Existing Bash/Fuzzel workflows are independent.
"""

import argparse
import fcntl
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import signal
import subprocess
import sys
import tempfile


WALL_DIR = Path.home() / ".local/share/wall"
CACHE_DIR = (
    Path(os.environ.get("XDG_CACHE_HOME") or Path.home() / ".cache")
    / "quickshell-wallpaper"
)
EXTENSIONS = {
    ".png",
    ".jpg",
    ".jpeg",
    ".webp",
    ".gif",
    ".bmp",
    ".avif",
    ".tif",
    ".tiff",
    ".jxl",
}


def emit(record):
    print(json.dumps(record, ensure_ascii=True), flush=True)


def run(cmd, timeout=120):
    """Keep command output out of the JSON protocol and propagate failures."""
    result = subprocess.run(cmd, capture_output=True, text=True, timeout=timeout)
    if result.returncode:
        detail = result.stderr.strip()[-1500:]
        raise RuntimeError(f"{cmd[0]} failed" + (f": {detail}" if detail else ""))
    return result.stdout


def image_paths(directory):
    directory = directory.expanduser().resolve()
    if not directory.is_dir():
        raise ValueError(f"Wallpaper folder does not exist: {directory}")
    return sorted(
        (
            p
            for p in directory.rglob("*")
            if p.is_file() and p.suffix.lower() in EXTENSIONS
        ),
        key=lambda p: (str(p.relative_to(directory)).casefold(), str(p)),
    )


def thumbnail_path(source, cache):
    stat = source.stat()
    identity = f"v1:384x216:{source.resolve()}:{stat.st_size}:{stat.st_mtime_ns}"
    return cache / (hashlib.sha256(identity.encode()).hexdigest() + ".jpg")


def thumbnail(source, cache):
    target = thumbnail_path(source, cache)
    if target.is_file():
        return target
    cache.mkdir(parents=True, exist_ok=True)
    # Atomic replacement keeps interrupted scans from leaving a broken cache hit.
    fd, temporary = tempfile.mkstemp(suffix=".jpg", dir=cache)
    os.close(fd)
    try:
        run(
            [
                "magick",
                str(source.resolve()) + "[0]",
                "-auto-orient",
                "-thumbnail",
                "384x216^",
                "-gravity",
                "center",
                "-extent",
                "384x216",
                "-background",
                "#121212",
                "-alpha",
                "remove",
                "-strip",
                "-quality",
                "82",
                temporary,
            ],
            timeout=30,
        )
        os.replace(temporary, target)
    finally:
        Path(temporary).unlink(missing_ok=True)
    return target


def list_images(directory, cache):
    directory = directory.expanduser().resolve()
    cache = cache.expanduser().resolve()
    paths = image_paths(directory)
    failures = 0
    for source in paths:
        try:
            thumb = thumbnail(source, cache).as_uri()
        except (OSError, RuntimeError, subprocess.TimeoutExpired):
            # Keep corrupt/unsupported images selectable, but don't decode them in QML.
            thumb = ""
            failures += 1
        emit(
            {
                "path": str(source),
                "name": str(source.relative_to(directory)),
                "thumbnail": thumb,
            }
        )
    emit({"done": True, "count": len(paths), "failed": failures})


def resolution(outputs):
    sizes = []
    for output in outputs.values():
        index = output.get("current_mode")
        modes = output.get("modes", [])
        if isinstance(index, int) and 0 <= index < len(modes):
            mode = modes[index]
            sizes.append((int(mode["width"]), int(mode["height"])))
    if not sizes:
        raise ValueError("No active Niri output found")
    return max(sizes, key=lambda size: size[0] * size[1])


def background_color(value):
    value = value.lstrip("#")
    if not re.fullmatch(r"[0-9a-fA-F]{6}", value):
        raise argparse.ArgumentTypeError("Background must be a six-digit hex colour")
    return value


def refresh_env():
    # QuickShell watches colors.css itself. Never restart shells or portals here.
    if os.environ.get("DISPLAY") and shutil.which("xrdb"):
        wal_cache = (
            Path(os.environ.get("XDG_CACHE_HOME") or Path.home() / ".cache") / "wal"
        )
        run(["xrdb", "-merge", "-quiet", str(wal_cache / "colors.Xresources")])


def apply_wallpaper(source, pywal=False, background=None):
    source = source.expanduser().resolve(strict=True)
    if not source.is_file():
        raise ValueError("Selected wallpaper is not a file")
    if background and not pywal:
        raise ValueError("A fixed background requires Pywal")
    width, height = resolution(json.loads(run(["niri", "msg", "-j", "outputs"])))
    WALL_DIR.mkdir(parents=True, exist_ok=True)
    wallpaper = WALL_DIR / "wallpaper.png"
    lockscreen = WALL_DIR / "lockscreen.png"
    # Generate both before replacing the files used by login and the locker.
    with tempfile.TemporaryDirectory(prefix=".setbg-", dir=WALL_DIR) as temporary:
        staged = Path(temporary)
        run(
            [
                "magick",
                str(source) + "[0]",
                "-auto-orient",
                "-resize",
                f"{width}x{height}^",
                "-gravity",
                "center",
                "-extent",
                f"{width}x{height}",
                str(staged / "wallpaper.png"),
            ]
        )
        run(
            [
                "magick",
                str(staged / "wallpaper.png"),
                "-blur",
                "0x55",
                "-modulate",
                "80",
                str(staged / "lockscreen.png"),
            ]
        )
        os.replace(staged / "wallpaper.png", wallpaper)
        os.replace(staged / "lockscreen.png", lockscreen)
    run(
        [
            "awww",
            "img",
            str(wallpaper),
            "--transition-type=any",
            "--transition-step=60",
            "--transition-fps=60",
            "--transition-duration=.7",
        ]
    )
    run(["awww", "img", "-n", "overview", str(lockscreen), "--transition-type=none"])
    if pywal:
        extra = ["-b", background] if background else []
        run(["wal", "-e", "-n", "-i", str(wallpaper), *extra], timeout=180)
        refresh_env()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest="command", required=True)
    listing = commands.add_parser("list", help="Stream cached thumbnail records")
    listing.add_argument(
        "--directory", type=Path, default=Path.home() / "Pictures/wallpaper"
    )
    listing.add_argument("--cache", type=Path, default=CACHE_DIR / "thumbnails")
    apply = commands.add_parser("apply", help="Set wallpaper and blurred lockscreen")
    apply.add_argument("path", type=Path)
    apply.add_argument("--pywal", action="store_true")
    apply.add_argument("--background", type=background_color)
    args = parser.parse_args()
    try:
        if args.command == "list":
            list_images(args.directory, args.cache)
        else:
            CACHE_DIR.mkdir(parents=True, exist_ok=True)
            with (CACHE_DIR / "apply.lock").open("w") as lock:
                try:
                    fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
                except BlockingIOError:
                    raise RuntimeError(
                        "Another wallpaper change is still running"
                    ) from None
                apply_wallpaper(args.path, args.pywal, args.background)
            emit({"ok": True})
        return 0
    except (OSError, ValueError, RuntimeError, subprocess.TimeoutExpired) as error:
        emit({"ok": False, "error": str(error)})
        return 1


if __name__ == "__main__":
    # Let subprocess.run clean up a running thumbnail conversion when the picker closes.
    signal.signal(signal.SIGTERM, lambda *_: sys.exit(143))
    raise SystemExit(main())
