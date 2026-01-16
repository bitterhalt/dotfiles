import math
from datetime import datetime

MOON_EMOJIS = {
    "new": "🌑",
    "waxing_crescent": "🌒",
    "first_quarter": "🌓",
    "waxing_gibbous": "🌔",
    "full": "🌕",
    "waning_gibbous": "🌖",
    "last_quarter": "🌗",
    "waning_crescent": "🌘",
}


def moon_phase_accurate(date: datetime) -> float:
    known_new_moon = datetime(2000, 1, 6, 18, 14)
    synodic_month = 29.53058867
    days_diff = (date - known_new_moon).total_seconds() / 86400.0
    phase = (days_diff % synodic_month) / synodic_month

    return phase


def moon_illumination(date: datetime) -> float:
    phase = moon_phase_accurate(date)
    illumination = (1 - math.cos(phase * 2 * math.pi)) / 2 * 100

    return illumination


def days_until_full_moon(date: datetime) -> float:
    phase = moon_phase_accurate(date)
    synodic_month = 29.53058867

    if phase < 0.5:
        days_until = (0.5 - phase) * synodic_month
    else:
        days_until = (1.0 - phase + 0.5) * synodic_month

    return days_until


def days_until_new_moon(date: datetime) -> float:
    phase = moon_phase_accurate(date)
    synodic_month = 29.53058867
    days_until = (1.0 - phase) * synodic_month
    return days_until


def moon_phase_index(date: datetime) -> int:
    phase = moon_phase_accurate(date)
    index = int((phase + 0.0625) * 8) % 8
    return index


def moon_phase_name(date: datetime) -> str:
    phase_names = [
        "New Moon",
        "Waxing Crescent",
        "First Quarter",
        "Waxing Gibbous",
        "Full Moon",
        "Waning Gibbous",
        "Last Quarter",
        "Waning Crescent",
    ]
    return phase_names[moon_phase_index(date)]


def moon_emoji(date: datetime) -> str:
    phase_map = [
        "new",
        "waxing_crescent",
        "first_quarter",
        "waxing_gibbous",
        "full",
        "waning_gibbous",
        "last_quarter",
        "waning_crescent",
    ]

    index = moon_phase_index(date)
    phase_key = phase_map[index]

    return MOON_EMOJIS[phase_key]


def moon_info(date: datetime) -> dict:
    return {
        "phase_name": moon_phase_name(date),
        "emoji": moon_emoji(date),
        "illumination": moon_illumination(date),
        "days_to_full": days_until_full_moon(date),
        "days_to_new": days_until_new_moon(date),
    }


def moon_tooltip(date: datetime) -> str:
    info = moon_info(date)
    tooltip = f"{info['phase_name']} {info['emoji']}\n"
    tooltip += f"Illumination: {info['illumination']:.1f}%\n"

    if info["days_to_full"] < info["days_to_new"]:
        days = info["days_to_full"]
        if days < 1:
            tooltip += f"Full moon in {days * 24:.1f} hours"
        else:
            tooltip += f"Full moon in {days:.1f} days"
    else:
        days = info["days_to_new"]
        if days < 1:
            tooltip += f"New moon in {days * 24:.1f} hours"
        else:
            tooltip += f"New moon in {days:.1f} days"

    return tooltip


def moon_icon_for(date: datetime) -> str:
    return moon_emoji(date)
