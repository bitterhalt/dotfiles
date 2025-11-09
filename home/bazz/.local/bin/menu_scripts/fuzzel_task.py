#!/usr/bin/env python3
"""
Lightweight Python timer daemon with Waybar and fuzzel integration
This is my first ever Python program so don't kill me!
"""

import json
import os
import signal
import sys
import time
from datetime import datetime
from subprocess import DEVNULL, PIPE, Popen, run
from pathlib import Path

# === Configuration ===
QUEUE_FILE = Path("~/.local/share/timers/queue.json").expanduser()
LOCK_FILE = Path("/tmp/timer_daemon.lock")

MIN_SLEEP = 5
MAX_SLEEP = 60
EXPIRE_SECONDS = 4 * 60 * 60
SOUND_FILE = Path("~/.local/share/Sounds/complete.oga").expanduser()

ICON_NEW = "󰔛"
ICON_EDIT = "󰏫"
ICON_CLEAR = "󰆴"
ICON_START = "󰐊"
ICON_STOP = "󰅗"
ICON_DELETE = "󰆴 Trash"
ICON_SAVE = "󰏫 Save"


# === Helper Functions ===
def notify(title: str, message: str) -> None:
    """Send a desktop notification."""
    try:  # Normal notify
        run(["notify-send", "-t", "3000", title, message], check=False, stderr=DEVNULL)
    except Exception:
        pass


def fire_notify(title: str, message: str) -> None:
    """Send a desktop notification."""
    try:  # Timer notification is critical and annoying
        run(
            ["notify-send", "-u", "critical", title, message],
            check=False,
            stderr=DEVNULL,
        )
    except Exception:
        pass


def play_sound() -> None:
    """Play sound if available (detached, no zombies)."""
    if SOUND_FILE.exists():
        try:
            Popen(
                ["pw-play", str(SOUND_FILE)],
                stderr=DEVNULL,
                stdout=DEVNULL,
                start_new_session=True,
            )
        except Exception:
            pass


def signal_waybar() -> None:
    """Signal Waybar to update."""
    try:
        run(["pkill", "-RTMIN+3", "waybar"], stderr=DEVNULL, check=False)
    except FileNotFoundError:
        pass


def fuzzel_prompt(
    prompt: str = "", default_value: str = "", placeholder: str = ""
) -> str | None:
    """Prompt user using fuzzel in dmenu mode."""
    cmd = ["fuzzel", "--minimal-lines", "--dmenu"]
    if placeholder:
        cmd.extend(["--placeholder", placeholder])
    prompt_str = prompt if prompt.strip() else "\u200b"
    cmd.extend(["-p", prompt_str])

    try:
        proc = Popen(cmd, stdin=PIPE, stdout=PIPE, stderr=DEVNULL, text=True)
        input_data = default_value + "\n" if default_value else ""
        out, _ = proc.communicate(input_data)
        return out.strip() if out else None
    except FileNotFoundError:
        notify("Error", "'fuzzel' not found.")
        return None


def acquire_lock() -> bool:
    """Prevent multiple daemons running."""
    if LOCK_FILE.exists():
        try:
            with LOCK_FILE.open("r", encoding="utf-8") as f:
                pid = int(f.read().strip())
            if os.path.exists(f"/proc/{pid}"):
                return False
        except Exception:
            pass
    with LOCK_FILE.open("w", encoding="utf-8") as f:
        f.write(str(os.getpid()))
    return True


def release_lock() -> None:
    """Remove daemon lock file."""
    if LOCK_FILE.exists():
        LOCK_FILE.unlink()


# === Timer Manager ===
class TimerManager:
    """Manage timer creation, storage, and daemon loop."""

    def __init__(self) -> None:
        os.makedirs(QUEUE_FILE.parent, exist_ok=True)
        self.queue: list[dict[str, str | int]] = []
        self.load_timers()

    def load_timers(self) -> None:
        """Load timers from JSON file."""
        try:
            if not QUEUE_FILE.exists():
                self.queue = []
                self.save_timers()
                return
            with QUEUE_FILE.open("r", encoding="utf-8") as f:
                self.queue = json.load(f)
        except Exception:
            notify("Timer Error", "Failed to read timer queue. Resetting.")
            self.queue = []
            self.save_timers()

    def save_timers(self) -> None:
        """Save current queue to disk and notify Waybar."""
        with QUEUE_FILE.open("w", encoding="utf-8") as f:
            json.dump(self.queue, f, indent=2)
        signal_waybar()

    def add_timer(self, fire_at: int, message: str) -> None:
        """Add a new timer entry."""
        new_entry = {
            "id": str(int(time.time() * 1_000_000)),
            "fire_at": fire_at,
            "message": message or "Reminder",
        }
        self.queue.append(new_entry)
        self.save_timers()

    def delete_timer(self, timer_id: str) -> bool:
        """Delete a timer by ID."""
        before = len(self.queue)
        self.queue = [t for t in self.queue if t["id"] != timer_id]
        if len(self.queue) != before:
            self.save_timers()
            return True
        return False

    def clear_all(self) -> None:
        """Remove all timers."""
        self.queue = []
        self.save_timers()

    def update_timer(self, timer_id: str, new_fire_at: int, new_msg: str) -> bool:
        """Edit an existing timer."""
        for t in self.queue:
            if t["id"] == timer_id:
                t["fire_at"] = new_fire_at
                t["message"] = new_msg
                self.save_timers()
                return True
        return False

    # === Timer checking ===
    def _check_and_process_timers(self) -> int:
        """Check due timers and send notifications (notify + sound)."""
        now = int(time.time())
        next_fire = None
        pending = []
        fired = False

        for t in self.queue:
            fire_at = t["fire_at"]
            msg = t["message"]

            if fire_at <= now:
                if now - fire_at < EXPIRE_SECONDS:
                    fire_notify("⏰ Timer Done", msg)
                    play_sound()
                    fired = True
            else:
                pending.append(t)
                if not next_fire or fire_at < next_fire:
                    next_fire = fire_at

        if fired or len(pending) != len(self.queue):
            self.queue = pending
            self.save_timers()

        return max(MIN_SLEEP, next_fire - now) if next_fire else MAX_SLEEP

    # === Daemon loop ===
    def run_daemon(self) -> None:
        """Main loop that monitors and fires timers."""
        if not acquire_lock():
            notify("Timer Daemon", "Already running.")
            return

        signal.signal(signal.SIGCHLD, signal.SIG_IGN)
        print(f"[Daemon] Started (PID {os.getpid()})")

        last_mtime = 0
        try:
            while True:
                try:
                    # Use .stat().st_mtime from Path object
                    mtime = QUEUE_FILE.stat().st_mtime
                except FileNotFoundError:
                    mtime = 0

                if mtime != last_mtime:
                    last_mtime = mtime
                    self.load_timers()

                sleep_time = min(self._check_and_process_timers(), MAX_SLEEP)
                print(
                    f"[{datetime.now():%H:%M:%S}] Sleeping {sleep_time}s, timers={len(self.queue)}"
                )
                time.sleep(sleep_time)

        except KeyboardInterrupt:
            print("[Daemon] Interrupted.")
        finally:
            release_lock()
            print("[Daemon] Stopped.")

    def start_daemon(self) -> None:
        """Start as background daemon."""
        try:
            script_path = os.path.abspath(__file__)
            # Popen call without explicit env=... is clean and sufficient for notify-send
            Popen(
                ["setsid", sys.executable, script_path, "daemon"],
                stdout=DEVNULL,
                stderr=DEVNULL,
                start_new_session=True,
            )
            notify(f"{ICON_START} Daemon Started", "Background timer is active.")
        except Exception as exc:
            notify("Error", f"Failed to start daemon: {exc}")

    def stop_daemon(self) -> None:
        """Stop the running daemon."""
        if not LOCK_FILE.exists():
            notify("Timer Daemon", "Not running.")
            return
        try:
            with LOCK_FILE.open("r", encoding="utf-8") as f:
                pid = int(f.read().strip())
            run(["kill", str(pid)], stderr=DEVNULL)
            time.sleep(0.3)
            if os.path.exists(f"/proc/{pid}"):
                run(["kill", "-9", str(pid)], stderr=DEVNULL)
            release_lock()
            notify(f"{ICON_STOP} Daemon Stopped", "")
        except Exception:
            release_lock()
            notify("Timer Daemon", "Lock cleared. Process state unknown.")


# === Menu Actions ===
def handle_new_timer(manager: TimerManager) -> None:
    now = datetime.now()
    t_str = fuzzel_prompt("", now.strftime("%H:%M"), "Time (HH:MM)")
    if not t_str:
        return
    d_str = fuzzel_prompt("", now.strftime("%d-%m"), "Date (DD-MM)")
    if not d_str:
        return
    y_str = fuzzel_prompt("", now.strftime("%Y"), "Year (YYYY)")
    if not y_str:
        return
    msg = fuzzel_prompt("", "", "Message (optional)")

    try:
        dt = datetime.strptime(f"{d_str}-{y_str} {t_str}", "%d-%m-%Y %H:%M")
    except ValueError:
        notify("Invalid", "Bad date/time format.")
        return

    fire_at = int(dt.timestamp())

    # --- Cancel if time is in the past
    if fire_at <= int(time.time()):
        notify("Invalid", "Cannot set time in the past. Timer canceled.")
        return  # EXIT if invalid

    manager.add_timer(fire_at, msg)
    notify("Timer Set", f"{msg or 'Reminder'} at {dt:%H:%M %d-%m-%Y}")


def handle_edit_timers(manager: TimerManager) -> None:
    if not manager.queue:
        notify("No timers", "No active timers to edit.")
        return

    lines = []
    id_map = {}
    for i, t in enumerate(manager.queue):
        dt = datetime.fromtimestamp(t["fire_at"])
        label = f"[{i}] {dt:%H:%M %d-%m-%Y} → {t['message']}"
        lines.append(label)
        id_map[label] = t["id"]

    choice = fuzzel_prompt("", "\n".join(lines), "Select timer")
    if not choice or choice not in id_map:
        return

    tid = id_map[choice]
    timer = next((x for x in manager.queue if x["id"] == tid), None)
    if not timer:
        return

    action = fuzzel_prompt("", f"{ICON_EDIT} Edit\n{ICON_DELETE}", "Action")
    if not action:
        return

    if action.startswith(ICON_DELETE):
        manager.delete_timer(tid)
        notify("Timer Deleted", timer["message"])
        return

    dt = datetime.fromtimestamp(timer["fire_at"])
    new_t = fuzzel_prompt("", dt.strftime("%H:%M"), "New Time (HH:MM)")
    new_d = fuzzel_prompt("", dt.strftime("%d-%m"), "New Date (DD-MM)")
    new_y = fuzzel_prompt("", dt.strftime("%Y"), "New Year (YYYY)")
    new_m = fuzzel_prompt("", timer["message"], "New Message")

    try:
        new_dt = datetime.strptime(f"{new_d}-{new_y} {new_t}", "%d-%m-%Y %H:%M")
    except ValueError:
        notify("Invalid", "Bad format.")
        return

    if new_dt.timestamp() <= time.time():
        notify("Invalid", "Cannot set time in past.")
        return

    manager.update_timer(tid, int(new_dt.timestamp()), new_m)
    notify("Timer Updated", new_m)


def main_menu(manager: TimerManager) -> None:
    menu = f"{ICON_NEW} New Timer\n{ICON_EDIT} Edit Timers\n{ICON_CLEAR} Clear All"
    menu += (
        f"\n{ICON_STOP} Stop Daemon"
        if LOCK_FILE.exists()  # Use Path.exists()
        else f"\n{ICON_START} Start Daemon"
    )

    choice = fuzzel_prompt("", menu, "Manage timers")
    if not choice:
        return

    if choice.startswith(ICON_NEW):
        handle_new_timer(manager)
    elif choice.startswith(ICON_EDIT):
        handle_edit_timers(manager)
    elif choice.startswith(ICON_CLEAR):
        manager.clear_all()
        notify("All Timers Cleared", "")
    elif choice.startswith(ICON_START):
        manager.start_daemon()
    elif choice.startswith(ICON_STOP):
        manager.stop_daemon()


# === Entry point ===
if __name__ == "__main__":
    manager = TimerManager()
    if len(sys.argv) > 1:
        cmd = sys.argv[1]
        if cmd == "daemon":
            manager.run_daemon()
            sys.exit(0)
        if cmd == "kill":
            manager.stop_daemon()
            sys.exit(0)
    main_menu(manager)
