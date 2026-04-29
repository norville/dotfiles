from kitty.fast_data_types import Screen, get_options
from kitty.utils import color_as_int
from kitty.tab_bar import DrawData, ExtraData, TabBarData, as_rgb

opts = get_options()

# Colors come from kitty.conf — change them there, not here.
ACTIVE_BG   = as_rgb(color_as_int(opts.active_tab_background))
ACTIVE_FG   = as_rgb(color_as_int(opts.active_tab_foreground))
INACTIVE_BG = as_rgb(color_as_int(opts.inactive_tab_background))
INACTIVE_FG = as_rgb(color_as_int(opts.inactive_tab_foreground))
BAR_BG      = as_rgb(color_as_int(
    opts.tab_bar_background if opts.tab_bar_background is not None else opts.background
))
BELL_FG     = as_rgb(0xff757f)  # red — fixed, not part of the tab color scheme

# U+E0BA ◢ (lower-right triangle): fg fills the lower-right half of the cell, bg the upper-left.
# Drawing it with fg=tab_bg and bg=prev_bg makes the tab color grow from the lower-right,
# producing the \ slanted powerline edge between consecutive segments.
SEP = ''

_prev_bg = BAR_BG  # tracks previous tab's bg so adjacent tabs share a clean diagonal edge


def _format_title(title: str, index: int) -> str:
    # SSH: the remote zsh precmd hook emits "user@host: /path" via OSC 2.
    # Detect by the presence of @ before the first colon.
    if ':' in title and '@' in title.split(':')[0]:
        user_host = title.split(':')[0].strip()
        path_part = title.split(':', 1)[1].strip()
        dirname   = path_part.rstrip('/').split('/')[-1] or path_part or '~'
        return f'{index}: {user_host} {dirname}'
    # Local: take the last path component (title may be a full path or a command name).
    dirname = title.rstrip('/').split('/')[-1] or title or '~'
    return f'{index}: {dirname}'


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

    # Slanted left cap: fg=tab_bg bg=_prev_bg draws the tab color in the lower-right half
    # of the separator cell, creating a \ diagonal against the preceding background.
    screen.cursor.fg = tab_bg
    screen.cursor.bg = _prev_bg
    screen.draw(SEP)

    # Tab content
    screen.cursor.fg = tab_fg
    screen.cursor.bg = tab_bg

    if tab.needs_attention:
        screen.cursor.fg = BELL_FG
        screen.draw('! ')
        screen.cursor.fg = tab_fg

    title = _format_title(tab.title or '', index)
    # Budget: left sep (1) + leading space (1) + trailing space (1) = 3 chars overhead
    available = max_title_length - 3
    if len(title) > available:
        title = title[:available - 1] + '…'
    screen.draw(f' {title} ')

    _prev_bg = tab_bg

    if is_last:
        # Closing cap: fg=BAR_BG bg=tab_bg — bar color grows from lower-right, tab recedes to upper-left.
        # After the tab content (all tab_bg), this cell transitions smoothly into the bar strip.
        screen.cursor.fg = BAR_BG
        screen.cursor.bg = tab_bg
        screen.draw(SEP)
        # Fill the remainder of the bar strip
        screen.cursor.fg = BAR_BG
        screen.cursor.bg = BAR_BG
        remaining = screen.columns - screen.cursor.x
        if remaining > 0:
            screen.draw(' ' * remaining)

    return screen.cursor.x
