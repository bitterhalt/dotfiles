#!/usr/bin/env python3
"""
Separate module to generate Waybar status JSON with dynamic CSS classes (today, future, idle).
"""

import json
import os
import time
from datetime import datetime
from pathlib import Path

# === Configuration (Must match fuzzel_task.py) ===
QUEUE_FILE = Path("~/.local/share/timers/queue.json").expanduser()
DEFAULT_ICON = "󰂚"
TODAY_ICON = "󰋼"


def get_status_json() -> str:
    """
    Reads the queue file, determines the next timer's urgency, and
    generates a JSON string with text, tooltip, and dynamic CSS class.
    """
    now_ts = int(time.time())
    now_dt = datetime.fromtimestamp(now_ts)
    today_date_str = now_dt.strftime("%Y-%m-%d")

    # 1. Default Output (No Timer / Idle)
    output = {
        "text": DEFAULT_ICON,
        "tooltip": "No active timers.",
        "class": "idle",
    }

    try:
        if not QUEUE_FILE.exists() or os.path.getsize(QUEUE_FILE) == 0:
            return json.dumps(output)

        with QUEUE_FILE.open("r", encoding="utf-8") as f:
            queue = json.load(f)

    except (FileNotFoundError, json.JSONDecodeError):
        # Gracefully handle file errors
        output["text"] = "ERR"
        output["tooltip"] = "Error reading queue file."
        output["class"] = "error"
        return json.dumps(output)

    # 2. Sort and filter active timers
    # Use .get(key, default) for robustness in case a timer entry is missing a key
    active_timers = sorted(
        [t for t in queue if t.get("fire_at", 0) > now_ts],
        key=lambda t: t["fire_at"],
    )

    if not active_timers:
        return json.dumps(output)

    # 3. Process the next timer
    next_timer = active_timers[0]
    fire_at = next_timer["fire_at"]
    message = next_timer["message"]
    fire_dt = datetime.fromtimestamp(fire_at)
    fire_date_str = fire_dt.strftime("%Y-%m-%d")

    time_label = fire_dt.strftime("%H:%M")

    # 4. Determine class and text based on urgency
    if fire_date_str == today_date_str:
        # Task is TODAY -> use 'today' class for color highlight
        class_name = "today"
        text_output = f"{TODAY_ICON} {message}"
        date_label = "Today"
    else:
        # Task is LATER -> use 'future' class for default color
        class_name = "future"
        text_output = DEFAULT_ICON
        date_label = fire_dt.strftime("%d.%m")

    # 5. Final JSON output
    output["text"] = text_output
    output["class"] = class_name
    output["tooltip"] = f"{date_label} @ <b>{time_label}</b>\n\nTask: {message}"

    return json.dumps(output)


if __name__ == "__main__":
    print(get_status_json())
