#!/usr/bin/env python3
"""List user processes and safely signal a selected process identity."""

import json
import os
from pathlib import Path
import signal
import sys


def identity(pid):
    directory = Path("/proc") / str(pid)
    if directory.stat().st_uid != os.getuid():
        raise PermissionError("Process is not owned by the current user")
    # comm can contain spaces or parentheses; fields after its final ')' start
    # at field 3. Start time (field 22) distinguishes reused PIDs.
    fields = (directory / "stat").read_text().rsplit(")", 1)[1].split()
    return fields[19]


def list_processes():
    processes = []
    for directory in Path("/proc").iterdir():
        if not directory.name.isdigit():
            continue
        pid = int(directory.name)
        if pid == os.getpid():
            continue
        try:
            started = identity(pid)
            name = (directory / "comm").read_text().strip()
            processes.append({"pid": pid, "name": name, "started": started})
        except (OSError, ValueError, IndexError):
            continue
    return sorted(processes, key=lambda item: (item["name"].lower(), item["pid"]))


def kill_process(pid, started):
    if pid <= 1 or pid == os.getpid():
        raise PermissionError("This process is protected")
    # A pidfd pins the target even if it exits and its PID is reused.
    descriptor = os.pidfd_open(pid)
    try:
        if identity(pid) != started:
            raise ProcessLookupError("Process changed; refresh the list")
        signal.pidfd_send_signal(descriptor, signal.SIGKILL)
    finally:
        os.close(descriptor)


def main():
    try:
        if sys.argv[1] == "list":
            print(json.dumps(list_processes()))
        elif sys.argv[1] == "kill":
            kill_process(int(sys.argv[2]), sys.argv[3])
        else:
            raise ValueError("Unknown action")
    except (OSError, ValueError, IndexError) as error:
        print(str(error), file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
