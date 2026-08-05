from datetime import datetime
from kitty.fast_data_types import Screen, get_options
from kitty.utils import color_as_int
from kitty.tab_bar import DrawData, ExtraData, TabBarData, as_rgb

opts = get_options()

# Mirrors the starship prompt (home/dot_config/starship/config.toml.tmpl):
# a ui_bg_highlight bar carrying solid accent blocks, each entered and left by
# slanted powerline seps and floating on the bar with a gap between them. Each
# tab is a two-tone capsule — a solid accent block for the index (icon-capsule)
# followed by the title on the bar in that accent's color.

# Bar body + terminal bg. Tab colors come from kitty.conf — edit there, not here.
HL_BG       = as_rgb(0x2f334d)  # ui_bg_highlight — the continuous bar body
DARK_FG     = as_rgb(0x1e2030)  # ui_bg_dark — dark fg on light accent blocks
BAR_BG      = as_rgb(color_as_int(
    opts.tab_bar_background if opts.tab_bar_background is not None else opts.background
))

ACTIVE_BG   = as_rgb(color_as_int(opts.active_tab_background))    # #82aaff blue
ACTIVE_FG   = as_rgb(color_as_int(opts.active_tab_foreground))    # #1e2030 dark
INACT_IDX   = as_rgb(0x545c7e)  # ui_dark3 — muted index block for inactive tabs
INACT_FG    = as_rgb(0x828bb8)  # term_white — readable inactive title on the bar
BELL_FG     = as_rgb(0xff757f)  # term_red — needs-attention marker

# Right cluster accents, echoing the prompt's italic runtime bar. Tokyo Night Moon.
OPENER_BG   = as_rgb(0x589ed7)  # ui_border_highlight — bar opener (os-like)
SESSION_BG  = as_rgb(0x4fd6be)  # term_cyan_bright
CLOCK_BG    = as_rgb(0xcaabff)  # term_magenta_bright

# Slanted separator (Nerd Font). Draw with fg = departing color, bg = arriving
# color, moving left→right.
SLANT = ''  # top-left triangle powerline separator

# Icons (Nerd Font). MDI coverage is confirmed by the starship config's glyphs.
CAT      = '\U000f011b'  # nf-md-cat — kitty brand, opens the bar
TERM     = ''      # nf-fa-terminal — session segment
CLOCK    = ''      # nf-fa-clock — clock segment


def _clock() -> str:
    return f' {CLOCK} {datetime.now().strftime("%H:%M")} '


def _session_label(session_name: str) -> str:
    if session_name:
        return f' {TERM} [{session_name}] '
    return f' {TERM} <F1> save session | <F4> load session '


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
    # ── Bar opener: flat-edged accent block with the cat icon, slant into bar ──
    if index == 1:
        screen.cursor.bold = False
        screen.cursor.italic = False
        screen.cursor.fg = DARK_FG
        screen.cursor.bg = OPENER_BG
        screen.draw(f' {CAT} ')
        screen.cursor.fg = OPENER_BG
        screen.cursor.bg = HL_BG
        screen.draw(SLANT)

    idx_bg = ACTIVE_BG if tab.is_active else INACT_IDX
    title_fg = ACTIVE_BG if tab.is_active else INACT_FG

    # ── Tab capsule: highlight → accent index block → slant → title, floating ──
    # on the bar with the padding spaces preserved as the gap between tabs.
    # Entry ramp: the HL-colored slant is invisible on the HL bar, so the accent
    # index block simply gains a slanted left edge.
    screen.cursor.bold = False
    screen.cursor.italic = False
    screen.cursor.fg = HL_BG
    screen.cursor.bg = idx_bg
    screen.draw(SLANT)

    # Index block on solid accent
    screen.cursor.bold = True
    screen.cursor.fg = ACTIVE_FG if tab.is_active else DARK_FG
    screen.cursor.bg = idx_bg
    screen.draw(f' {index} ')

    # Capsule → body: same slanted separator (accent → highlight)
    screen.cursor.bold = False
    screen.cursor.fg = idx_bg
    screen.cursor.bg = HL_BG
    screen.draw(SLANT)

    # Title body on the highlight bar, in the accent's color
    screen.cursor.bold = True
    screen.cursor.fg = title_fg
    screen.cursor.bg = HL_BG
    title = tab.title or '~'
    available = max_title_length - 6  # opener + index block + seps already consumed
    if len(title) > available:
        title = title[:max(available - 1, 1)] + '…'
    if tab.needs_attention:
        screen.cursor.fg = BELL_FG
        screen.draw(' ! ')
        screen.cursor.fg = title_fg
        screen.draw(f'{title} ')
    else:
        screen.draw(f' {title} ')

    if is_last:
        session = _session_label(tab.session_name)
        clock = _clock()
        # session_entry + session + session_exit + gap + clock_entry + clock
        right_width = 1 + len(session) + 1 + 1 + 1 + len(clock)

        # Stretch the highlight bar up to the right cluster (continuous bar)
        screen.cursor.bold = False
        screen.cursor.italic = False
        fill = screen.columns - right_width - screen.cursor.x
        if fill > 0:
            screen.cursor.fg = HL_BG
            screen.cursor.bg = HL_BG
            screen.draw(' ' * fill)

        # Session: highlight → solid cyan block, italic
        screen.cursor.fg = HL_BG
        screen.cursor.bg = SESSION_BG
        screen.draw(SLANT)
        screen.cursor.italic = True
        screen.cursor.fg = DARK_FG
        screen.cursor.bg = SESSION_BG
        screen.draw(session)

        # Gap: session → bar, a bar space, then bar → clock (floats them apart)
        screen.cursor.italic = False
        screen.cursor.fg = SESSION_BG
        screen.cursor.bg = HL_BG
        screen.draw(SLANT)
        screen.cursor.fg = HL_BG
        screen.cursor.bg = HL_BG
        screen.draw(' ')

        # Clock: highlight → solid magenta block, italic
        screen.cursor.fg = HL_BG
        screen.cursor.bg = CLOCK_BG
        screen.draw(SLANT)
        screen.cursor.italic = True
        screen.cursor.fg = DARK_FG
        screen.cursor.bg = CLOCK_BG
        screen.draw(clock)

    # Reset so styling never bleeds into the terminal
    screen.cursor.bold = False
    screen.cursor.italic = False
    return screen.cursor.x
