from kitty.tab_bar import as_rgb, draw_title

ROUND = True  # False = square tabs
CAP_L, CAP_R = "\ue0b6", "\ue0b4"  # Nerd Font half circles


def _cap(screen, left, color, bar):
    screen.cursor.fg = color
    screen.cursor.bg = bar
    screen.draw(CAP_L if left else CAP_R)


def draw_tab(
    draw_data, screen, tab, before, max_title_length, index, is_last, extra_data
):
    tab_bg = as_rgb(int(draw_data.tab_bg(tab)))
    tab_fg = as_rgb(int(draw_data.tab_fg(tab)))
    bar_bg = as_rgb(int(draw_data.default_bg))

    if ROUND:
        _cap(screen, True, tab_bg, bar_bg)
        max_title_length -= 2

    screen.cursor.fg = tab_fg
    screen.cursor.bg = tab_bg
    draw_title(draw_data, screen, tab, index, max_title_length)

    if ROUND:
        _cap(screen, False, tab_bg, bar_bg)

    # gap between tabs
    screen.cursor.fg = tab_fg
    screen.cursor.bg = bar_bg
    screen.draw(" ")

    return screen.cursor.x
