import time


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
    diff = now - timestamp

    if diff < 0:
        return "just now"

    if diff < 60:
        return "just now"

    minutes = diff // 60
    if minutes < 60:
        if minutes == 1:
            return "1 minute ago"
        return f"{int(minutes)} minutes ago"

    hours = minutes // 60
    if hours < 24:
        if hours == 1:
            return "1 hour ago"
        return f"{int(hours)} hours ago"

    days = hours // 24
    if days < 7:
        if days == 1:
            return "yesterday"
        return f"{int(days)} days ago"

    weeks = days // 7
    if weeks < 4:
        if weeks == 1:
            return "1 week ago"
        return f"{int(weeks)} weeks ago"

    months = days // 30
    if months < 12:
        if months == 1:
            return "1 month ago"
        return f"{int(months)} months ago"

    years = days // 365
    if years == 1:
        return "1 year ago"
    return f"{int(years)} years ago"
