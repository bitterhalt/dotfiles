import time
from datetime import datetime


def format_time_until(fire_at: int) -> str:
    now = int(time.time())
    diff = fire_at - now

    if diff < 0:
        return "Overdue!"

    hours = diff // 3600
    minutes = (diff % 3600) // 60

    if hours >= 24:
        days = hours // 24
        hours = hours % 24
        return f"{days}d {hours}h"

    if hours > 0:
        return f"{hours}h {minutes}m"

    return f"{minutes}m"


def format_time_ago(timestamp: int) -> str:
    now = int(time.time())
    notif_date = datetime.fromtimestamp(timestamp).date()
    today_date = datetime.fromtimestamp(now).date()

    notif_time = datetime.fromtimestamp(timestamp)

    if notif_date == today_date:
        return notif_time.strftime("%H:%M:%S")

    return notif_time.strftime("%b %d")
