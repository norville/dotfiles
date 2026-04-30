from datetime import datetime
from kitty.fast_data_types import Screen, get_options
from kitty.utils import color_as_int
from kitty.tab_bar import DrawData, ExtraData, TabBarData, as_rgb

opts = get_options()

# Tab colors from kitty.conf — edit there, not here.
ACTIVE_BG   = as_rgb(color_as_int(opts.active_tab_background))
ACTIVE_FG   = as_rgb(color_as_int(opts.active_tab_foreground))
INACTIVE_BG = as_rgb(color_as_int(opts.inactive_tab_background))
INACTIVE_FG = as_rgb(color_as_int(opts.inactive_tab_foreground))
BAR_BG      = as_rgb(color_as_int(
    opts.tab_bar_background if opts.tab_bar_background is not None else opts.background
))
BELL_FG     = as_rgb(0xff757f)  # red — fixed
CLOCK_BG    = as_rgb(0xff966c)  # orange — Tokyo Night Moon
CLOCK_FG    = as_rgb(0x1e2030)  # ui_bg_dark — dark fg for contrast on orange

# U+E0BA ◢ (lower-right triangle): fg fills the lower-right half of the cell, bg the upper-left.
# Drawing with fg=next_bg, bg=current_bg produces a \ slanted transition into the next segment.
SEP = ''

_prev_bg = BAR_BG


def _clock() -> str:
    # U+F017 is the Nerd Font clock icon; surrounding spaces pad the segment.
    return f'  {datetime.now().strftime("%H:%M")} '


def draw_tab(
    draw_data: DrawData,
    screen: Screen,
    tab: TabBarData,
    before: int,
    max_title_length: int,
    index: int,
    is_last: bool,
    extra_data: ExtraData,
) -> int:
    global _prev_bg

    if index == 1:
        _prev_bg = BAR_BG

    tab_bg = ACTIVE_BG if tab.is_active else INACTIVE_BG
    tab_fg = ACTIVE_FG if tab.is_active else INACTIVE_FG

    # Left slanted cap: \ diagonal from _prev_bg into tab_bg
    screen.cursor.fg = tab_bg
    screen.cursor.bg = _prev_bg
    screen.draw(SEP)

    # Tab body
    screen.cursor.fg = tab_fg
    screen.cursor.bg = tab_bg
    if tab.needs_attention:
        screen.cursor.fg = BELL_FG
        screen.draw('! ')
        screen.cursor.fg = tab_fg
    title = f'{index}: {tab.title or "~"}'
    available = max_title_length - 3
    if len(title) > available:
        title = title[:available - 1] + '…'
    screen.draw(f' {title} ')

    _prev_bg = tab_bg

    if is_last:
        clock = _clock()
        clock_width = len(clock) + 1  # +1 for the left sep

        # Close last tab into bar strip
        screen.cursor.fg = BAR_BG
        screen.cursor.bg = tab_bg
        screen.draw(SEP)

        # Fill bar until clock section
        fill = screen.columns - clock_width - screen.cursor.x
        if fill > 0:
            screen.cursor.fg = BAR_BG
            screen.cursor.bg = BAR_BG
            screen.draw(' ' * fill)

        # Clock left cap: bar → clock
        screen.cursor.fg = CLOCK_BG
        screen.cursor.bg = BAR_BG
        screen.draw(SEP)

        # Clock body
        screen.cursor.fg = CLOCK_FG
        screen.cursor.bg = CLOCK_BG
        screen.draw(clock)

    return screen.cursor.x
