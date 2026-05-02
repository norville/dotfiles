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
CLOCK_BG    = as_rgb(0xcaabff)  # term_magenta_bright — Tokyo Night Moon
CLOCK_FG    = as_rgb(0x1e2030)  # ui_bg_dark — dark fg for contrast on orange
SESSION_BG  = as_rgb(0x4fd6be)  # term_cyan_bright — Tokyo Night Moon
SESSION_FG  = as_rgb(0x1e2030)  # ui_bg_dark — dark fg for contrast on teal

# U+E0BC  (upper-left triangle): fg fills the upper-left half of the cell, bg the lower-right.
# Drawing with fg=departing_bg, bg=arriving_bg: the departing segment occupies the upper-left,
# producing the / slanted entry into the arriving segment.
SEP      = ''   # used around the active tab
THIN_SEP = ''   # thin separator between two inactive tabs

_prev_bg = BAR_BG


def _clock() -> str:
    # U+F017 is the Nerd Font clock icon; surrounding spaces pad the segment.
    return f'  {datetime.now().strftime("%H:%M")} '


def _session_label(session_name: str) -> str:
    if session_name:
        return f' [{session_name}] '
    return ' <F1> save session | <F4> load session '


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

    if index != 1:
        if tab.is_active or _prev_bg == ACTIVE_BG:
            # Full separator around the active tab
            screen.cursor.fg = _prev_bg
            screen.cursor.bg = tab_bg
            screen.draw(SEP)
        else:
            # Thin separator between two inactive tabs; INACTIVE_FG on INACTIVE_BG
            # since both share the same bg, fg=_prev_bg would be invisible.
            screen.cursor.fg = INACTIVE_FG
            screen.cursor.bg = INACTIVE_BG
            screen.draw(THIN_SEP)

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
        session = _session_label(tab.session_name)
        clock = _clock()
        right_width = 1 + len(session) + 1 + len(clock)  # session_sep + session + clock_sep + clock

        # Close last tab into bar strip
        screen.cursor.fg = tab_bg
        screen.cursor.bg = BAR_BG
        screen.draw(SEP)

        # Fill bar until session section
        fill = screen.columns - right_width - screen.cursor.x
        if fill > 0:
            screen.cursor.fg = BAR_BG
            screen.cursor.bg = BAR_BG
            screen.draw(' ' * fill)

        # Session left cap: bar → session
        screen.cursor.fg = BAR_BG
        screen.cursor.bg = SESSION_BG
        screen.draw(SEP)

        # Session body
        screen.cursor.fg = SESSION_FG
        screen.cursor.bg = SESSION_BG
        screen.draw(session)

        # Session → clock cap
        screen.cursor.fg = SESSION_BG
        screen.cursor.bg = CLOCK_BG
        screen.draw(SEP)

        # Clock body
        screen.cursor.fg = CLOCK_FG
        screen.cursor.bg = CLOCK_BG
        screen.draw(clock)

    return screen.cursor.x

