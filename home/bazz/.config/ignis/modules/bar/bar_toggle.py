from modules.osd.workspace_osd import set_bar_visibility
from modules.osd.clock_osd import set_barless_clock_visibility
from modules.utils import save_bar_state

_bar_windows = []


def register_bar(bar_window) -> None:
    _bar_windows.append(bar_window)


def toggle_bars():
    if not _bar_windows:
        return

    current_state = _bar_windows[0].visible
    new_state = not current_state

    for bar in _bar_windows:
        bar.set_visible(new_state)

    set_bar_visibility(new_state)
    set_barless_clock_visibility(new_state)
    save_bar_state(new_state)


def show_bars():
    for bar in _bar_windows:
        bar.set_visible(True)
    set_bar_visibility(True)
    set_barless_clock_visibility(True)
    save_bar_state(True)


def hide_bars():
    for bar in _bar_windows:
        bar.set_visible(False)
    set_bar_visibility(False)
    set_barless_clock_visibility(False)
    save_bar_state(False)


def get_bar_state() -> bool:
    if not _bar_windows:
        return True
    state = _bar_windows[0].visible
    return state
