#!/usr/bin/env python3
#
# Minimal timer daemon for Ignis Task Menu
#

import json
import os
import signal
import time
from pathlib import Path
from subprocess import DEVNULL, Popen, run

# === Configuration ===
QUEUE_FILE = Path("~/.local/share/timers/queue.json").expanduser()
LOCK_FILE = Path("/tmp/timer_daemon.lock")
EXPIRE_SECONDS = 4 * 60 * 60
MIN_SLEEP = 5
MAX_SLEEP = 60
SOUND_FILE = Path("~/.local/share/Sounds/complete.oga").expanduser()


# === Utils ===
def notify_critical(title: str, message: str) -> None:
    """Critical timer notification."""
    run(
        ["notify-send", "-u", "critical", title, message],
        stderr=DEVNULL,
    )


def play_sound():
    """Play completion sound."""
    if SOUND_FILE.exists():
        try:
            Popen(
                ["pw-play", str(SOUND_FILE)],
                stdout=DEVNULL,
                stderr=DEVNULL,
                start_new_session=True,
            )
        except Exception:
            pass


def acquire_lock():
    """Simple lockfile to prevent duplicate daemons."""
    if LOCK_FILE.exists():
        try:
            pid = int(LOCK_FILE.read_text().strip())
            if os.path.exists(f"/proc/{pid}"):
                return False
        except Exception:
            pass

    LOCK_FILE.write_text(str(os.getpid()))
    return True


def release_lock():
    if LOCK_FILE.exists():
        LOCK_FILE.unlink()


# === Timer Handling ===
class TimerDaemon:
    def __init__(self):
        self.queue = []
        self.load()

    def load(self):
        """Load timer queue from disk."""
        try:
            if not QUEUE_FILE.exists():
                self.queue = []
                return
            self.queue = json.loads(QUEUE_FILE.read_text())
        except Exception:
            self.queue = []

    def save(self):
        """Write queue back to disk."""
        try:
            QUEUE_FILE.parent.mkdir(parents=True, exist_ok=True)
            QUEUE_FILE.write_text(json.dumps(self.queue, indent=2))
        except Exception:
            pass

    def process(self):
        """Check timers, fire events, compute next sleep."""
        now = int(time.time())
        pending = []
        next_fire = None
        fired = False

        for t in self.queue:
            fire_at = t["fire_at"]

            if fire_at <= now:
                if now - fire_at < EXPIRE_SECONDS:
                    notify_critical("⏰ Timer Done", t["message"])
                    play_sound()
                    fired = True
            else:
                pending.append(t)
                if next_fire is None or fire_at < next_fire:
                    next_fire = fire_at

        if fired or len(pending) != len(self.queue):
            self.queue = pending
            self.save()

        if next_fire:
            return max(MIN_SLEEP, next_fire - now)
        return MAX_SLEEP

    def run(self):
        """Main daemon loop."""
        if not acquire_lock():
            print("[Daemon] Already running.")
            return

        signal.signal(signal.SIGCHLD, signal.SIG_IGN)
        print(f"[Daemon] Started (pid {os.getpid()})")

        last_mtime = 0
        try:
            while True:
                try:
                    mtime = QUEUE_FILE.stat().st_mtime
                except FileNotFoundError:
                    mtime = 0

                if mtime != last_mtime:
                    last_mtime = mtime
                    self.load()

                sleep_for = self.process()
                time.sleep(sleep_for)

        except KeyboardInterrupt:
            pass
        finally:
            release_lock()
            print("[Daemon] Stopped.")


# === Entry ===
if __name__ == "__main__":
    TimerDaemon().run()
