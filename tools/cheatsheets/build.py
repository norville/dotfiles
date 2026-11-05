"""Build keybinding cheatsheets (HTML) for the dotfiles' tool stack.

Each sheet merges the tool's official defaults with what the dotfiles define:

- defaults come from the installed tool itself (kitty's config loader, a live
  Neovim keymap dump, `less --help`, `noctalia config export full`) or from its
  official docs/source pinned to the installed version (lazygit, yazi, btop);
- dotfile settings are read from the chezmoi source rendered into a scratch
  home (`--home`, produced by generate.sh), so sheets track the source even
  before `chezmoi apply`. Dotfile-defined entries are tagged "custom" (orange).

A few facts have no machine-readable source and are curated below: less's key
summary, git's `add -p` prompt keys and Noctalia's launcher keys/prefixes. Each
records the version it was taken from; the build warns when the installed
version moves past it, so the curated table can be re-checked.

Usage: build.py --home DIR --cache DIR --repo DIR [tool ...]
"""
import argparse
import html
import json
import os
import re
import subprocess
import sys
import tomllib
import urllib.request

ap = argparse.ArgumentParser()
ap.add_argument("--home", required=True)
ap.add_argument("--cache", required=True)
ap.add_argument("--repo", required=True)
ap.add_argument("tools", nargs="*")
ARGS = ap.parse_args()
H, CACHE, REPO = ARGS.home, ARGS.cache, ARGS.repo
OUT = f"{CACHE}/html"
os.makedirs(OUT, exist_ok=True)
os.makedirs(f"{CACHE}/dl", exist_ok=True)


def warn(msg):
    print(f"warning: {msg}", file=sys.stderr)


def sh(*cmd):
    try:
        return subprocess.run(cmd, capture_output=True, text=True, timeout=60).stdout
    except (OSError, subprocess.TimeoutExpired):
        return ""


def version(cmd, pattern):
    m = re.search(pattern, re.sub(r"\x1b\[[0-9;]*m", "", sh(*cmd)))
    return m.group(1) if m else "?"


def fetch(url, name):
    """Download once into the cache (file names carry the version)."""
    path = f"{CACHE}/dl/{name}"
    if not os.path.exists(path):
        with urllib.request.urlopen(url, timeout=30) as r, open(path, "wb") as f:
            f.write(r.read())
    return path


def cfg(rel):
    """Path of a dotfile in the rendered source home (None if not managed)."""
    p = f"{H}/{rel}"
    return p if os.path.exists(p) else None


def read(path):
    return open(path).read() if path else ""


# ----------------------------------------------------------------------------
# Key formatting
# ----------------------------------------------------------------------------
NAMES = {
    "cr": "Enter", "enter": "Enter", "return": "Enter", "esc": "Esc", "escape": "Esc",
    "bs": "BkSp", "backspace": "BkSp", "tab": "Tab", "space": "Space", "spacebar": "Space",
    "up": "↑", "down": "↓", "left": "←", "right": "→", "pageup": "PgUp", "pagedown": "PgDn",
    "page_up": "PgUp", "page_down": "PgDn", "pgup": "PgUp", "pgdn": "PgDn", "home": "Home",
    "end": "End", "del": "Del", "delete": "Del", "insert": "Ins", "lt": "<", "bslash": "\\",
    "bar": "|", "kp_add": "Num+", "kp_subtract": "Num−", "kp_enter": "NumEnter",
    "iso_left_tab": "Tab",
}
# Plain combos ("Mod+Shift+H") only use full modifier names; single letters are keys.
MODS = {"ctrl": "Ctrl", "alt": "Alt", "shift": "Shift", "mod": "Mod", "super": "Super",
        "cmd": "Cmd", "kitty_mod": "Ctrl+Shift"}
# Vim-style "<C-x>" notation.
VIM_MODS = {"c": "Ctrl", "m": "Alt", "a": "Alt", "s": "Shift", "d": "Super"}


def nice(tok):
    t = tok.strip()
    low = t.lower()
    if low in NAMES:
        return NAMES[low]
    if re.fullmatch(r"f\d{1,2}", low):
        return low.upper()
    if low.startswith("xf86"):
        return t[4:]
    return t


def combo(s):
    """'Mod+Shift+H' / 'ctrl + z' / 'kitty_mod++' -> one pill label."""
    s = re.sub(r"\s*\+\s*(?=\S)", "+", s.strip())
    return "+".join(MODS.get(p.lower(), nice(p) if len(p) > 1 else p)
                    for p in re.split(r"\+(?=.)", s))


def vimkeys(lhs, leader=True, case_shift=False):
    """Vim notation ('<Space>ff', '<C-S>', 'gg') -> list of pill labels.

    case_shift: an uppercase letter inside <C-…> means Shift (yazi); Neovim's
    keytrans uppercases letters without implying Shift.
    """
    out = []
    for i, t in enumerate(re.findall(r"<[^<>]+>|.", lhs)):
        if i == 0 and leader and t in ("<Space>", "<leader>", " "):
            out.append("SPC")
        elif t.startswith("<") and t.endswith(">") and len(t) > 2:
            m = re.fullmatch(r"((?:[CMASDcmasd]-)+)(.+)", t[1:-1])
            if not m:
                out.append(nice(t[1:-1]))
                continue
            mods = [VIM_MODS[x.lower()] for x in m.group(1).split("-") if x]
            key = nice(m.group(2))
            if len(key) == 1 and key.isalpha():
                if case_shift and key.isupper() and "Shift" not in mods:
                    mods.append("Shift")
                key = key.lower()
            out.append("+".join(mods + [key]))
        else:
            out.append("Space" if t == " " else t)
    return out


def lgkeys(k):
    """One lazygit key: '<ctrl+p>' / 'q' / '<ctrl+d> (fn+down)' -> pill labels."""
    k = k.strip()
    m = re.fullmatch(r"<mouse wheel (up|down)>\s*\(fn\+(up|down)\)", k)
    if m:
        a = {"up": "↑", "down": "↓"}
        return [f"Wheel {a[m.group(1)]} (fn+{a[m.group(2)]})"]
    m = re.fullmatch(r"(<[^>]+>)\s*\(([^)]*)\)", k)
    if m:
        hint = "/".join(combo(h) for h in m.group(2).split("/"))
        return [lgkeys(m.group(1))[0] + f" ({hint})"]
    if k.startswith("<") and k.endswith(">") and len(k) > 2:
        inner = k[1:-1]
        if "+" in inner[:-1]:
            return [combo(inner)]
        m = re.fullmatch(r"c-(.)", inner)
        return ["Ctrl+" + m.group(1)] if m else [nice(inner)]
    return [k]


# An entry: keys = list of alternatives, each a list of pills (a key sequence).
def E(keys, desc, custom=False, modes=""):
    return {"k": keys, "d": desc, "c": custom, "m": modes}


# ----------------------------------------------------------------------------
# HTML (tokyonight-moon, JetBrains Mono)
# ----------------------------------------------------------------------------
CSS = """
:root{--bg:#222436;--bg2:#1e2030;--hl:#2f334d;--border:#3b4261;--fg:#c8d3f5;
--dim:#828bb8;--comment:#636da6;--blue:#82aaff;--cyan:#86e1fc;--orange:#ff966c;
--yellow:#ffc777;--magenta:#c099ff;--teal:#4fd6be}
*{box-sizing:border-box}
html,body{margin:0;background:var(--bg);color:var(--fg);
font-family:'JetBrains Mono',monospace;font-size:13px;line-height:1.35;font-variant-ligatures:none}
.page{padding:30px 34px 26px}
header{display:flex;align-items:flex-end;justify-content:space-between;gap:24px;
border-bottom:2px solid var(--hl);padding-bottom:12px;margin-bottom:18px}
h1{font-size:32px;margin:0;color:var(--blue);font-weight:800;letter-spacing:-.01em}
h1 .tag{font-size:14px;color:var(--comment);font-weight:400;margin-left:12px}
.meta{text-align:right;color:var(--comment);font-size:11.5px}
.meta b{color:var(--dim);font-weight:600}
.legend kbd{margin-right:4px}
.notes{color:var(--dim);font-size:12px;margin:-6px 0 16px;display:flex;flex-wrap:wrap;gap:6px 22px}
.notes span::before{content:"▸ ";color:var(--teal)}
.cols{column-gap:20px}
section{break-inside:avoid;margin:0 0 16px;background:var(--bg2);
border:1px solid var(--hl);border-radius:8px;padding:10px 12px 8px}
h2{font-size:12.5px;margin:0 0 7px;color:var(--magenta);text-transform:uppercase;
letter-spacing:.07em;font-weight:700}
h2 small{color:var(--comment);text-transform:none;letter-spacing:0;font-weight:400;margin-left:6px}
.row{display:grid;grid-template-columns:var(--kw) 1fr;gap:10px;padding:3px 0;
border-top:1px solid #2a2e45;align-items:baseline}
.row:first-of-type{border-top:0}
.keys{display:flex;flex-wrap:wrap;gap:3px 0;align-items:baseline}
.seq{display:inline-flex;gap:2px;white-space:nowrap}
.or{color:var(--comment);margin:0 5px}
kbd{font-family:inherit;font-size:11.5px;background:var(--hl);color:var(--cyan);
border:1px solid var(--border);border-bottom-width:2px;border-radius:4px;padding:0 5px;white-space:nowrap}
.mode{color:var(--yellow);font-size:10.5px;margin-left:6px}
.custom kbd{color:var(--orange);border-color:#ff966c66}
.custom .desc{color:var(--orange)}
footer{color:var(--comment);font-size:11px;border-top:1px solid var(--hl);
padding-top:9px;margin-top:4px;display:flex;justify-content:space-between}
"""


def keys_html(alts):
    return '<span class="or">/</span>'.join(
        '<span class="seq">' + "".join(f"<kbd>{html.escape(p)}</kbd>" for p in a) + "</span>"
        for a in alts)


def render(slug, title, tagline, ver, sources, sections, notes=(), cols=3, width=1500, kw="190px"):
    sections = [s for s in sections if s[2]]
    custom_n = sum(e["c"] for _, _, es in sections for e in es)
    total = sum(len(es) for _, _, es in sections)
    custom_legend = ('&nbsp;&nbsp;<span class="custom"><kbd>key</kbd>'
                     '<span class="desc">from your dotfiles</span></span>') if custom_n else ""
    out = [f'<!doctype html><html><head><meta charset="utf-8"><title>{title}</title>'
           f"<style>{CSS}</style></head><body>"
           f'<div class="page" style="width:{width}px;--kw:{kw}">'
           f'<header><h1>{html.escape(title)}<span class="tag">{html.escape(tagline)}</span></h1>'
           f'<div class="meta"><b>{html.escape(ver)}</b><br>'
           f'<span class="legend"><kbd>key</kbd>default{custom_legend}</span></div></header>']
    if notes:  # notes are trusted, may contain <b>
        out.append('<div class="notes">' + "".join(f"<span>{n}</span>" for n in notes) + "</div>")
    out.append(f'<div class="cols" style="column-count:{cols}">')
    for name, sub, entries in sections:
        out.append(f"<section><h2>{html.escape(name)}"
                   + (f"<small>{html.escape(sub)}</small>" if sub else "") + "</h2>")
        for e in entries:
            mode = f'<span class="mode">{html.escape(e["m"])}</span>' if e["m"] else ""
            out.append(f'<div class="row{" custom" if e["c"] else ""}">'
                       f'<div class="keys">{keys_html(e["k"])}</div>'
                       f'<div class="desc">{html.escape(e["d"])}{mode}</div></div>')
        out.append("</section>")
    out.append("</div>")
    out.append(f"<footer><span>Sources: {html.escape(sources)}</span><span>{total} bindings"
               + (f" · {custom_n} from dotfiles" if custom_n else "")
               + " · tokyonight-moon</span></footer></div></body></html>")
    with open(f"{OUT}/{slug}.html", "w") as f:
        f.write("".join(out))
    print(f"{slug:9} {total:4} bindings, {custom_n:3} custom, {len(sections):2} sections")


# ----------------------------------------------------------------------------
# less — shared by bat and delta. Curated from `less --help` (less 710).
# ----------------------------------------------------------------------------
LESS_DOC = "710"
LESS_MOVE = [
    E([["j"], ["↓"], ["Enter"]], "Forward one line"),
    E([["k"], ["↑"]], "Backward one line"),
    E([["Space"], ["f"], ["PgDn"]], "Forward one window"),
    E([["b"], ["PgUp"]], "Backward one window"),
    E([["d"], ["Ctrl+d"]], "Forward half a window"),
    E([["u"], ["Ctrl+u"]], "Backward half a window"),
    E([["→"], ["Alt+)"]], "Right half a screen"),
    E([["←"], ["Alt+("]], "Left half a screen"),
    E([["Ctrl+→"], ["Alt+}"]], "Right to the last column"),
    E([["Ctrl+←"], ["Alt+{"]], "Left to the first column"),
    E([["F"]], "Follow (like tail -f)"),
    E([["r"], ["Ctrl+l"]], "Repaint screen"),
]
LESS_JUMP = [
    E([["g"], ["<"], ["Home"]], "First line (Ng: line N)"),
    E([["G"], [">"], ["End"]], "Last line (NG: line N)"),
    E([["p"], ["%"]], "Np: N percent into file"),
    E([["m", "x"]], "Set mark x"),
    E([["'", "x"]], "Go to mark x"),
    E([["'", "'"]], "Back to previous position"),
]
LESS_SEARCH = [
    E([["/pattern"]], "Search forward"),
    E([["?pattern"]], "Search backward"),
    E([["n"]], "Next match"),
    E([["N"]], "Previous match"),
    E([["&pattern"]], "Show only matching lines"),
    E([["Alt+u"]], "Toggle search highlighting"),
    E([["Ctrl+o", "n"]], "Next OSC8 hyperlink"),
    E([["Ctrl+o", "p"]], "Previous OSC8 hyperlink"),
    E([["Ctrl+o", "l"]], "Open selected hyperlink"),
]
LESS_SEARCH_MODS = [
    E([["!"], ["Ctrl+n"]], "Pattern prefix: NON-matching lines"),
    E([["Ctrl+r"]], "Pattern prefix: literal (no regex)"),
    E([["Ctrl+w"]], "Pattern prefix: wrap around"),
]
LESS_MISC = [
    E([["q"], [":q"], ["ZZ"]], "Quit"),
    E([["h"], ["H"]], "Help (full command list)"),
    E([["-S"]], "Toggle chop / wrap long lines"),
    E([["-N"]], "Toggle line numbers"),
    E([["-i"]], "Toggle case-insensitive search"),
    E([["="]], "File info (position, size)"),
    E([["v"]], "Open the file in $VISUAL / $EDITOR"),
    E([["s", "file"]], "Save piped input to file"),
    E([["!cmd"]], "Run a shell command"),
]


def less_version():
    v = version(["less", "--version"], r"less (\d+)")
    if v != LESS_DOC:
        warn(f"less is {v}, curated keys are from less {LESS_DOC} — re-check `less --help`")
    return v


def build_bat():
    lv = less_version()
    conf = read(cfg(".config/bat/config"))
    opts = [l.strip() for l in conf.splitlines() if l.strip() and not l.lstrip().startswith("#")]
    pager = next((o for o in opts if o.startswith(("--pager", "--paging"))), None)
    notes = ["bat has no keys of its own — output longer than a screen is paged by <b>less</b>"
             " (-R -F: colors kept, quits if it fits one screen)"]
    notes.append(f"your config: {html.escape(' '.join(opts)) or 'none'}"
                 + ("" if pager else " (no pager override)"))
    render("bat", "bat", "pager keys (less)",
           f"bat {version(['bat', '--version'], r'bat ([0-9.]+)')} · less {lv}",
           "less --help · ~/.config/bat/config",
           [("Moving", "N prefix repeats", LESS_MOVE), ("Jumping & marks", "", LESS_JUMP),
            ("Searching", "", LESS_SEARCH), ("Search prefixes", "type before the pattern", LESS_SEARCH_MODS),
            ("Misc", "", LESS_MISC)],
           notes=notes, cols=3, width=1500, kw="200px")


# git's `add -p` prompt (git-add(1), "Interactive mode"), git 2.56.
ADD_P = [
    E([["y"]], "Stage this hunk"), E([["n"]], "Don't stage this hunk"),
    E([["a"]], "Stage this + all later hunks in file"), E([["d"]], "Skip this + all later hunks in file"),
    E([["s"]], "Split into smaller hunks"), E([["e"]], "Edit the hunk manually"),
    E([["j"]], "Next undecided hunk"), E([["J"]], "Next hunk"),
    E([["k"]], "Previous undecided hunk"), E([["K"]], "Previous hunk"),
    E([["g"]], "Go to a hunk by number"), E([["/"]], "Search hunks by regex"),
    E([["p"]], "Print the hunk again"), E([["q"]], "Quit"), E([["?"]], "Help"),
]


def build_delta():
    lv = less_version()
    git = {k.lower(): v for k, v in (l.split("=", 1) for l in
                                     sh("git", "config", "--global", "--list").splitlines() if "=" in l)}
    for line in read(cfg(".config/delta/tokyonight_moon.gitconfig")).splitlines():
        m = re.match(r"\s*([\w-]+)\s*=\s*(.*)", line)
        if m:
            git.setdefault("delta." + m.group(1).lower(), m.group(2).strip())
    on = lambda k: git.get(k, "false").lower() == "true"
    move = [e for e in LESS_MOVE if not e["d"].startswith(("Right to", "Left to", "Follow", "Repaint"))]
    sections = []
    if on("delta.navigate"):
        sections.append(("Navigate diffs", "delta.navigate = true",
                         [E([["n"]], "Next file / hunk", True), E([["N"]], "Previous file / hunk", True)]))
    sections += [("Scrolling", "less", move),
                 ("Jump & search", "less", LESS_JUMP[:2] + LESS_SEARCH[:4] + LESS_SEARCH[6:])]
    if "delta" in git.get("interactive.difffilter", ""):
        sections.append(("git add -p / -i", "interactive.diffFilter = delta", ADD_P))
    sections.append(("Misc", "less", LESS_MISC[:3]))
    feats = [f for f in ("navigate", "side-by-side", "line-numbers", "hyperlinks") if on(f"delta.{f}")]
    notes = ["delta is git's core.pager: it pages through <b>less</b>" if "delta" in git.get("core.pager", "")
             else "delta is not git's core.pager here",
             "your config: " + (", ".join(feats) or "defaults")
             + (" → click file paths in kitty" if "hyperlinks" in feats else "")]
    if "delta" in git.get("interactive.difffilter", ""):
        notes.append("the y/n/s/e prompt keys are git's — delta only colors those hunks")
    render("delta", "delta", "git pager keys",
           f"delta {version(['delta', '--version'], r'delta ([0-9.]+)')} · less {lv}"
           f" · git {version(['git', '--version'], r'version ([0-9.]+)')}",
           "delta docs (navigate) · git-add(1) · less --help · ~/.config/delta, gitconfig",
           sections, notes=notes, cols=3, width=1500, kw="170px")


def build_btop():
    v = version(["btop", "--version"], r"([0-9]+\.[0-9]+\.[0-9]+)")
    src = read(fetch(f"https://raw.githubusercontent.com/aristocratos/btop/v{v}/src/btop_menu.cpp",
                     f"btop-{v}-btop_menu.cpp"))
    start = src.index("help_text = {")
    items = [(k, d) for k, d in re.findall(r'\{"([^"]*)",\s*"([^"]*)"\}', src[start:src.index("};", start)]) if k]
    conf = dict(re.findall(r'^(\w+)\s*=\s*"?(.*?)"?\s*$', read(cfg(".config/btop/btop.conf")), re.M))
    presets = conf.get("presets", "").split()
    groups = {g: [] for g in ("General", "Boxes & views", "Network", "Process list", "Selected process", "Mouse")}
    for k, d in items:
        parts = [x.replace("Selected ", "") for x in re.split(r",\s*", k)]
        if k.startswith("Selected"):
            g = "Selected process"
        elif k.startswith("Mouse"):
            g = "Mouse"
        elif k in ("1", "2", "3", "4", "5", "d", "i", "p", "shift + p"):
            g = "Boxes & views"
        elif k in ("b, n", "z", "a", "y"):
            g = "Network"
        elif k in ("Esc, m", "F2, o", "F1, ?, h", "ctrl + z", "ctrl + r", "q, ctrl + c", "+, -"):
            g = "General"
        else:
            g = "Process list"
        desc, custom = d.rstrip("."), False
        if k in ("p", "shift + p") and presets:
            desc, custom = f"{desc} ({len(presets)} presets in your btop.conf)", True
        groups[g].append(E([[combo(x)] for x in parts], desc, custom))
    notes = []
    if conf.get("vim_keys") == "true":
        groups["General"].append(E([["h"], ["j"], ["k"], ["l"]], "Move ← ↓ ↑ → (vim_keys)", True))
        notes.append("vim_keys = true → h j k l move (help stays on F1 / ?)")
    else:
        notes.append("vim_keys = false → h opens help (not ←)")
    if presets:
        names = [" + ".join(b.split(":")[0] for b in p.split(",")) for p in presets]
        notes.append("presets (p): " + " · ".join(names))
    if conf.get("update_ms"):
        notes.append(f"update_ms = {conf['update_ms']}" + (f" · sorting: {conf['proc_sorting']}" if conf.get("proc_sorting") else ""))
    render("btop", "btop", "resource monitor", f"btop {v}",
           f"btop {v} help text (src/btop_menu.cpp) · ~/.config/btop/btop.conf",
           [(g, "", es) for g, es in groups.items()], notes=notes, cols=3, width=1450, kw="150px")


KITTY_DESC = {
    "copy_to_clipboard": "Copy", "paste_from_clipboard": "Paste",
    "paste_from_selection": "Paste primary selection", "pass_selection_to_program": "Open selection with program",
    "scroll_line_up smooth": "Scroll line up", "scroll_line_down smooth": "Scroll line down",
    "scroll_page_up": "Scroll page up", "scroll_page_down": "Scroll page down",
    "scroll_home": "Scroll to top", "scroll_end": "Scroll to bottom",
    "scroll_to_prompt -1": "Previous shell prompt", "scroll_to_prompt 1": "Next shell prompt",
    "show_scrollback": "Scrollback in pager", "show_last_command_output": "Last command output in pager",
    "search_scrollback": "Search scrollback",
    "new_window": "New window (split)", "new_os_window": "New OS window", "close_window": "Close window",
    "next_window": "Next window", "previous_window": "Previous window",
    "move_window_forward": "Move window forward", "move_window_backward": "Move window backward",
    "move_window_to_top": "Move window to top", "start_resizing_window": "Resize window",
    "focus_visible_window": "Pick window to focus", "swap_with_window": "Pick window to swap",
    "next_tab": "Next tab", "previous_tab": "Previous tab", "new_tab": "New tab", "close_tab": "Close tab",
    "move_tab_forward": "Move tab forward", "move_tab_backward": "Move tab backward", "set_tab_title": "Rename tab",
    "next_layout": "Next layout", "toggle_layout stack": "Toggle stack (zoom) layout",
    "layout_action mirror toggle": "Mirror layout", "layout_action bias 33 50 66": "Cycle split bias 33/50/66 %",
    "layout_action decrease_num_full_size_windows": "Fewer full-size windows",
    "layout_action increase_num_full_size_windows": "More full-size windows",
    "change_font_size all +2.0": "Font size +2", "change_font_size all -2.0": "Font size −2",
    "change_font_size all 0": "Reset font size", "open_url_with_hints": "Open URL (hints)",
    "kitten hints --type path --program -": "Insert path", "kitten hints --type path": "Open path",
    "kitten choose-files": "Insert chosen file", "kitten choose-files --mode=dir": "Insert chosen dir",
    "kitten hints --type line --program -": "Insert line", "kitten hints --type word --program -": "Insert word",
    "kitten hints --type hash --program -": "Insert git hash",
    "kitten hints --type linenum": "Open file:line in editor", "kitten hints --type hyperlink": "Open hyperlink",
    "show_kitty_doc overview": "kitty docs", "command_palette": "Command palette",
    "toggle_fullscreen": "Toggle fullscreen", "toggle_maximized": "Toggle maximized",
    "kitten unicode_input": "Unicode input", "edit_config_file": "Edit kitty.conf",
    "kitty_shell window": "kitty shell", "set_background_opacity +0.1": "Opacity +0.1",
    "set_background_opacity -0.1": "Opacity −0.1", "set_background_opacity 1": "Opacity 100 %",
    "set_background_opacity default": "Opacity default", "clear_terminal reset active": "Reset terminal",
    "load_config_file": "Reload kitty.conf", "debug_config": "Debug config",
}
ORDINALS = ["first", "second", "third", "fourth", "fifth", "sixth", "seventh", "eighth", "ninth", "tenth"]


def kitty_desc(a):
    if a in KITTY_DESC:
        return KITTY_DESC[a]
    if a.startswith("save_as_session"):
        return "Save session"
    if a.startswith("goto_session"):
        return "Switch session"
    return a  # unknown action: show it verbatim rather than guess


def kitty_group(a):
    if a.startswith(("copy", "paste", "pass_selection")):
        return "Clipboard"
    if a.startswith(("scroll", "show_scrollback", "show_last", "search_scrollback")):
        return "Scrollback"
    if "layout" in a:
        return "Layouts"
    if "window" in a:
        return "Windows"
    if "tab" in a:
        return "Tabs"
    if "font_size" in a:
        return "Font size"
    if a.startswith(("kitten hints", "open_url", "kitten choose")):
        return "Hints"
    if "session" in a:
        return "Sessions"
    return "Misc"


def build_kitty():
    d = json.load(open(f"{CACHE}/data/kitty-maps.json"))
    D, U, kmod = d["defaults"], d["active"], combo(d["kitty_mod"])
    by = {}
    for k, a in U.items():
        if a.split("_")[0] in ORDINALS and a.endswith("_window") and D.get(k) == a:
            continue  # first…tenth_window: folded into one row below
        by.setdefault((a, D.get(k) != a), []).append(k)
    groups = {}
    for (a, custom), keys in by.items():
        alts = [[combo(p).replace("Ctrl+Shift", kmod) for p in k.split(" > ")] for k in keys]
        groups.setdefault(kitty_group(a), []).append(E(alts, kitty_desc(a), custom))
    groups.setdefault("Windows", []).append(E([[f"{kmod}+1…0"]], "Go to window 1–10"))
    removed = [k for k in D if k not in U]
    if removed:
        groups["Removed (unmapped in your kitty.conf)"] = [E([[combo(k)]], kitty_desc(D[k]), True) for k in removed]
    notes = [f"kitty_mod = {kmod}"]
    tmpl = read(f"{REPO}/home/dot_config/kitty/kitty.conf.tmpl") if os.path.exists(
        f"{REPO}/home/dot_config/kitty/kitty.conf.tmpl") else ""
    if "cmd+ctrl" in tmpl:
        notes.append("your custom Ctrl+Alt keys are Cmd+Ctrl on macOS")
    if any("session" in a for a, _ in by):
        notes.append("sessions live in ~/.config/kitty/sessions")
    order = ["Windows", "Tabs", "Layouts", "Scrollback", "Clipboard", "Font size", "Hints", "Sessions", "Misc"]
    secs = [(g, f"{kmod}+P …" if g == "Hints" else "", groups[g]) for g in order if g in groups]
    secs += [(g, "", es) for g, es in groups.items() if g not in order]
    render("kitty", "kitty", "terminal", f"kitty {version(['kitty', '--version'], r'kitty ([0-9.]+)')}",
           "kitty's own config loader: defaults vs ~/.config/kitty/kitty.conf",
           secs, notes=notes, cols=3, width=1650, kw="230px")


def lazygit_overrides():
    """Minimal YAML read of config.yml's `keybinding:` block (section.key: value)."""
    text, out, sec, inside = read(cfg(".config/lazygit/config.yml")), [], None, False
    for line in text.splitlines():
        if not line.strip() or line.lstrip().startswith("#"):
            continue
        indent = len(line) - len(line.lstrip())
        if indent == 0:
            inside = line.startswith("keybinding:")
            continue
        if not inside:
            continue
        m = re.match(r"\s*([\w-]+):\s*(.*?)\s*$", line)
        if not m:
            continue
        if not m.group(2):
            sec = m.group(1)
        else:
            out.append((f"{sec}.{m.group(1)}", m.group(2).strip("'\"")))
    return out


def build_lazygit():
    v = version(["lazygit", "--version"], r"version=([0-9.]+)")
    doc = fetch(f"https://raw.githubusercontent.com/jesseduffield/lazygit/v{v}/docs/keybindings/Keybindings_en.md",
                f"lazygit-{v}-Keybindings_en.md")
    sections, cur, rows = [], None, []
    for line in open(doc):
        if line.startswith("## "):
            if cur and rows:
                sections.append((cur, "", rows))
            cur, rows = line[3:].strip(), []
            continue
        m = re.match(r"^\| `` (.+?) `` \| (.*?) \|", line)
        if m and cur:
            # cells list alternatives: "<pgup>, K, <ctrl+u>" / ", <home>" / "<mouse wheel up> (fn+down)"
            alts = re.findall(r"<[^>]+>(?:\s*\([^)]*\))?|,(?=\s|$)|[^,\s]+", m.group(1).replace("\\|", "|"))
            rows.append(E([lgkeys(a) for a in alts], re.sub(r"<[^>]+>", "", m.group(2)).strip()))
    if cur and rows:
        sections.append((cur, "", rows))
    first = ["Global keybindings", "List panel navigation", "Files", "Local branches", "Commits",
             "Commit files", "Main panel (normal)", "Main panel (merging)", "Stash", "Status"]
    sections.sort(key=lambda s: first.index(s[0]) if s[0] in first else len(first))
    ov = lazygit_overrides()
    notes = ["? in any panel lists its keys (with your overrides applied)"]
    if ov:
        sections.insert(0, ("Your overrides", "config.yml keybinding:",
                            [E([lgkeys(val)], key, True) for key, val in ov]))
        notes.insert(0, "your overrides replace the default key for that action in every panel")
    else:
        notes.insert(0, "your config.yml overrides no keys — all defaults")
    render("lazygit", "lazygit", "git TUI", f"lazygit {v}",
           f"docs/keybindings/Keybindings_en.md @ v{v} · ~/.config/lazygit/config.yml",
           sections, notes=notes, cols=5, width=2600, kw="120px")


def niri_binds():
    """(section, key, attrs, action) for every bind in the rendered keybinds.kdl."""
    out, cur = [], "General"
    for line in read(cfg(".config/niri/keybinds.kdl")).splitlines():
        s = line.strip()
        if not s or s.startswith("// ───"):
            continue
        if s.startswith("//"):
            text = s[2:].strip()
            # one-line headings name sections; wrapped explanatory comments don't
            if text and len(text) < 40 and not text.endswith((".", ",")):
                cur = text
            continue
        m = re.match(r"^(\S+)\s+(.*?)\{\s*(.*?);?\s*\}$", s)
        if m:
            out.append((cur,) + m.groups())
    return out


def build_niri():
    sections = {}
    for sec, key, attrs, action in niri_binds():
        title = re.search(r'hotkey-overlay-title="([^"]+)"', attrs)
        if title:
            desc = title.group(1)
        elif action.startswith("spawn"):
            desc = action.split('"')[1].removeprefix("noctalia msg ").replace("-", " ")
        else:
            name, _, args = action.partition(" ")
            desc = name.replace("-", " ") + (" " + args.replace('"', "") if args else "")
        desc = desc[0].upper() + desc[1:]
        rows = sections.setdefault(sec, {})
        rows.setdefault(action, {"keys": [], "d": desc,
                                 "m": "locked ok" if "allow-when-locked" in attrs else ""})["keys"].append([combo(key)])
    render("niri", "niri", "scrollable-tiling compositor",
           f"niri {version(['niri', '--version'], r'niri ([0-9.]+)')}",
           "~/.config/niri/keybinds.kdl (chezmoi) — replaces niri's defaults entirely",
           [(s, "", [E(v["keys"], v["d"], modes=v["m"]) for v in rows.values()]) for s, rows in sections.items()],
           notes=["Mod = Super", "every bind here is from your dotfiles (the config replaces niri's built-in defaults)",
                  "arrows and h j k l are interchangeable"],
           cols=3, width=1750, kw="260px")


# Noctalia launcher — docs.noctalia.dev/noctalia/v5.4.1/launcher/ (no machine-readable source).
NOCTALIA_DOC = "5.4.1"
NOCTALIA_LAUNCHER = [E([["Shift+Enter"]], "App options menu (also right-click)"),
                     E([["Enter"]], "Calculator: copy result")]
NOCTALIA_READLINE = [  # active only with shell.readline_shortcuts = true
    E([["Ctrl+a"]], "Line start"), E([["Ctrl+e"]], "Line end"), E([["Ctrl+b"], ["Ctrl+f"]], "Char back / forward"),
    E([["Alt+b"], ["Alt+f"]], "Word back / forward"), E([["Ctrl+w"]], "Delete previous word"),
    E([["Ctrl+u"]], "Delete to line start"), E([["Ctrl+k"]], "Delete to line end"), E([["Alt+d"]], "Delete next word")]
NOCTALIA_NO_READLINE = [E([["Ctrl+a"]], "Select all"), E([["Ctrl+u"]], "Clear field")]
NOCTALIA_PREFIXES = [
    E([["/"]], "List prefixed providers"), E([["/calc"]], "Calculator, units, currency"),
    E([["/emo"]], "Emoji → clipboard"), E([["/pan"]], "Open panels / control-center tabs"),
    E([["/wall"]], "Browse & apply wallpapers"), E([["/session"]], "Run session actions"),
    E([["/win"]], "Find & focus windows")]
NOCTALIA_KEYBINDS = {"cancel": "Cancel / close", "validate": "Validate / activate", "up": "Move up",
                     "down": "Move down", "left": "Move left", "right": "Move right", "tab_next": "Next focus / tab",
                     "tab_previous": "Previous focus / tab", "delete": "Delete / remove", "copy": "Copy", "save": "Save"}


def find_key(obj, key):
    if isinstance(obj, dict):
        for k, v in obj.items():
            if k == key:
                return v
            r = find_key(v, key)
            if r is not None:
                return r
    return None


def build_noctalia():
    v = version(["noctalia", "--version"], r"v([0-9.]+)")
    if v != NOCTALIA_DOC:
        warn(f"noctalia is {v}, launcher keys/prefixes are from the v{NOCTALIA_DOC} docs — re-check them")
    full = tomllib.loads(sh("noctalia", "config", "export", "full") or "")
    src_path = cfg(".config/noctalia/config.toml")
    src = tomllib.loads(read(src_path)) if src_path else {}
    glob, media = [], []
    for sec, key, attrs, action in niri_binds():
        if "noctalia msg" not in action:
            continue
        title = re.search(r'hotkey-overlay-title="([^"]+)"', attrs)
        desc = title.group(1) if title else action.split("noctalia msg ", 1)[1].rstrip('"').replace("-", " ")
        desc = desc[0].upper() + desc[1:]
        (media if key.lower().startswith("xf86") else glob).append(E([[combo(key)]], desc, True))
    user_kb = src.get("keybinds", {})
    panels = []
    kb = full.get("keybinds") or {}
    for name in [n for n in NOCTALIA_KEYBINDS if n in kb] + [n for n in kb if n not in NOCTALIA_KEYBINDS]:
        keys = kb[name]
        keys = user_kb.get(name, keys)
        panels.append(E([[combo(k)] for k in keys], NOCTALIA_KEYBINDS.get(name, name.replace("_", " ")),
                        name in user_kb))
    readline = bool(find_key(src, "readline_shortcuts") if find_key(src, "readline_shortcuts") is not None
                    else find_key(full, "readline_shortcuts"))
    launcher = NOCTALIA_LAUNCHER + (NOCTALIA_READLINE if readline else NOCTALIA_NO_READLINE)
    actions = (find_key(src, "session") or {}).get("actions") or (find_key(full, "session") or {}).get("actions", [])
    names = {"logout": "Log out", "lock": "Lock", "suspend": "Suspend", "reboot": "Reboot",
             "reboot-uefi": "Reboot to firmware", "shutdown": "Shut down"}
    session = []
    for a in actions:
        if not a.get("enabled", True) or not a.get("shortcut"):
            continue
        desc = a.get("label") or names.get(a.get("action"), a.get("action", "?"))
        if a.get("command"):
            desc += " — custom command"
        session.append(E([[a["shortcut"]]], desc, bool(a.get("command"))))
    countdown = next((a.get("countdown_seconds") for a in actions if a.get("countdown_seconds")), None)
    session_key = next((e["k"][0][0] for e in glob if "session" in e["d"].lower() and "menu" in e["d"].lower()), "")
    render("noctalia", "Noctalia", "desktop shell", f"noctalia v{v}",
           f"docs.noctalia.dev v{NOCTALIA_DOC} (launcher) · noctalia config export full · ~/.config/noctalia, niri keybinds.kdl",
           [("Global (niri binds)", "noctalia msg …", glob), ("Media & brightness", "work when locked", media),
            ("Panels & dialogs", "[keybinds]", panels), ("Launcher", "", launcher),
            ("Launcher providers", "type in the launcher", NOCTALIA_PREFIXES),
            ("Session menu", " · ".join(x for x in (session_key, f"{countdown:g} s countdown" if countdown else "") if x),
             session)],
           notes=["Noctalia has no global hotkeys of its own — your niri binds call noctalia msg",
                  f"readline_shortcuts = {str(readline).lower()}"
                  + ("" if readline else " (Ctrl+A/E/W… readline editing is off)")],
           cols=3, width=1500, kw="210px")


def build_yazi():
    v = version(["yazi", "--version"], r"Version: ([0-9.]+)")
    km = tomllib.load(open(fetch(f"https://raw.githubusercontent.com/sxyazi/yazi/v{v}/yazi-config/preset/keymap-default.toml",
                                 f"yazi-{v}-keymap-default.toml"), "rb"))
    user_path = cfg(".config/yazi/keymap.toml")
    user = tomllib.load(open(user_path, "rb")) if user_path else {}

    def on(e):
        o = e["on"] if isinstance(e["on"], list) else [e["on"]]
        return tuple(p for k in o for p in vimkeys(k, leader=False, case_shift=True))

    def run(e):
        r = e.get("run", "")
        return r[0] if isinstance(r, list) else r

    def entries(sec):
        """Defaults merged with keymap.toml: keymap replaces, prepend shadows, append adds."""
        u = user.get(sec, {})
        if "keymap" in u:
            return [(e, True) for e in u["keymap"]]
        pre = [(e, True) for e in u.get("prepend_keymap", [])]
        shadow = {on(e) for e, _ in pre}
        base = [(e, False) for e in km.get(sec, {}).get("keymap", []) if on(e) not in shadow]
        return pre + base + [(e, True) for e in u.get("append_keymap", [])]

    def merge(items):
        out = {}
        for keys, desc, custom in items:
            out.setdefault((desc, custom), []).append(list(keys))
        return [E(k, d, c) for (d, c), k in out.items()]

    mgr = {g: [] for g in ("General", "Navigation", "Selection", "File operations", "Find & jump", "Goto (g)",
                           "Copy path (c)", "Sort (,)", "Linemode (m)", "Tabs")}
    for e, custom in entries("mgr"):
        keys, desc = on(e), e.get("desc", run(e))
        verb = (run(e).split() or [""])[0]
        if len(keys) > 1 and keys[0] in ("g", "c", ",", "m"):
            g = {"g": "Goto (g)", "c": "Copy path (c)", ",": "Sort (,)", "m": "Linemode (m)"}[keys[0]]
        elif verb.startswith("tab"):
            g = "Tabs"
        elif verb in ("escape", "quit", "close", "suspend", "help", "tasks:show"):
            g = "General"
        elif verb in ("arrow", "leave", "enter", "back", "forward", "seek", "spot", "peek"):
            g = "Navigation"
        elif verb in ("toggle", "toggle_all", "visual_mode"):
            g = "Selection"
        elif verb in ("search", "find", "find_arrow", "filter", "plugin", "cd", "reveal"):
            g = "Find & jump"
        else:
            g = "File operations"
        mgr[g].append((keys, desc, custom))
    sections = [(g, "", merge(p)) for g, p in mgr.items()]
    for sec, title in (("tasks", "Task manager"), ("spot", "Spot (file info)"), ("pick", "Pick dialog"),
                       ("input", "Input fields"), ("confirm", "Confirm dialog"), ("cmp", "Completion"),
                       ("help", "Help menu")):
        sections.append((title, "", merge([(on(e), e.get("desc", run(e)), c) for e, c in entries(sec)])))
    render("yazi", "yazi", "file manager", f"yazi {v}",
           f"yazi-config/preset/keymap-default.toml @ v{v} · ~/.config/yazi",
           sections,
           notes=["your keymap.toml is merged in (orange)" if user else "no keymap.toml in your dotfiles — all defaults",
                  "F1 / ~ shows the live keymap"],
           cols=5, width=2700, kw="125px")


NV_GROUPS = {"<Tab>": "tabs", "b": "buffer", "c": "code", "d": "debug", "dp": "profiler", "f": "file / find",
             "g": "git", "gh": "hunks", "q": "quit / session", "s": "search", "u": "ui", "w": "windows",
             "x": "diagnostics / quickfix"}


def nvim_user_keys():
    """lhs (normalised) -> desc for keys defined in the dotfiles' Neovim config,
    plus lazily-mapped Snacks toggles a startup dump can't see."""
    lhs, toggles = set(), {}
    root = cfg(".config/nvim/lua")
    for dirpath, _, files in os.walk(root or "/nonexistent"):
        for fn in files:
            if not fn.endswith(".lua"):
                continue
            text = open(os.path.join(dirpath, fn)).read()
            for m in re.finditer(r'\{\s*"([^"]+)"\s*,[^\n]*desc\s*=', text):          # lazy `keys` specs
                lhs.add(m.group(1))
            for m in re.finditer(r'vim\.keymap\.set\([^,]+,\s*"([^"]+)"', text):     # keymaps.lua
                lhs.add(m.group(1))
            for m in re.finditer(r'Snacks\.toggle\(\{\s*name\s*=\s*"([^"]+)".*?\}\):map\("([^"]+)"\)', text, re.S):
                lhs.add(m.group(2))
                toggles[m.group(2)] = f"Toggle {m.group(1)}"
    norm = lambda k: k.replace("<leader>", "<Space>").lower()
    return {norm(k) for k in lhs}, {norm(k): (k.replace("<leader>", "<Space>"), d) for k, d in toggles.items()}


def lazyvim_lsp_keys():
    """Buffer-local LSP keys from LazyVim's lsp spec (set on LspAttach)."""
    data = os.environ.get("XDG_DATA_HOME", os.path.expanduser("~/.local/share"))
    base = f"{data}/nvim/lazy/LazyVim/lua/lazyvim/plugins"
    out = []
    # lsp/init.lua: the servers["*"] keys; snacks_picker extra: its picker-backed LSP keys
    for rel, only in (("lsp/init.lua", None), ("extras/editor/snacks_picker.lua", "Snacks.picker.lsp_")):
        path = f"{base}/{rel}"
        lines = read(path if os.path.exists(path) else None).splitlines()
        for i, line in enumerate(lines):
            m = re.match(r'\s*\{\s*"([^"]+)",', line)
            if not m or "keys" in line or (only and only not in line):
                continue
            d = re.search(r'desc = "([^"]+)"', " ".join(lines[i:i + 3]))
            if d and m.group(1) != "<leader>cm":
                ins = ' mode = "i"' in line
                key = (m.group(1).replace("<leader>", "<Space>"), d.group(1) + (" (insert)" if ins else ""))
                if key not in out:
                    out.append(key)
    return out


def build_lazyvim():
    d = json.load(open(f"{CACHE}/data/nvim-keymaps.json"))
    user_lhs, toggles = nvim_user_keys()
    merged, pairs = {}, []
    for m in d["maps"]:
        desc = m["desc"]
        if desc.startswith(("which_key_ignore", ":help ")) or m["lhs"] == "<Space>":
            continue  # Neovim's own documented defaults / which-key internals
        if m["mode"] == "i" and re.match(r"^(Open|Close|Closeopen) action for ", desc):
            pairs.append(m["lhs"])
            continue
        lsp = re.fullmatch(r"vim\.lsp\.(?:buf|codelens)\.(\w+)\(\)", desc)
        if lsp:
            desc = "LSP " + lsp.group(1).replace("_", " ") + " (Neovim default)"
        merged.setdefault((m["lhs"], desc), set()).add(m["mode"])
    for k, (lhs, desc) in toggles.items():
        if not any(l.lower() == k for l, _ in merged):
            merged[(lhs, desc)] = {"n"}

    def grp_of(lhs):
        if lhs.startswith("<Space>"):
            rest = lhs[len("<Space>"):]
            for p in ("dp", "gh"):
                if rest.startswith(p) and len(rest) > len(p):
                    return f"SPC {p} · {NV_GROUPS[p]}"
            if rest.startswith("<Tab>") and len(rest) > 5:
                return "SPC Tab · tabs"
            if rest[:1] in NV_GROUPS and len(rest) > 1:
                return f"SPC {rest[0]} · {NV_GROUPS[rest[0]]}"
            return "SPC · top level"
        if lhs[:1] in "[]":
            return "[ ] · prev / next"
        if lhs.startswith("gs"):
            return "gs · surround"
        if lhs[:1] == "g":
            return "g · goto"
        if lhs[:1] == "z":
            return "z · fold"
        return "Editing & motion"

    groups = {}
    for (lhs, desc), modes in merged.items():
        mstr = "".join(sorted(modes - {"n"})) if modes != {"n"} else ""
        mstr = "visual" if mstr in ("vx", "x", "v") else ("insert" if mstr == "i" else mstr)
        groups.setdefault(grp_of(lhs), []).append(
            (lhs, E([vimkeys(lhs)], desc, lhs.lower() in user_lhs, mstr)))
    groups["LSP · on attach"] = [(l, E([vimkeys(l)], dsc)) for l, dsc in lazyvim_lsp_keys()]
    if pairs:
        groups.setdefault("Editing & motion", []).append(
            ("(", E([[p] for p in sorted(set(pairs))], "Auto-pair brackets & quotes (mini.pairs)", modes="insert")))
    for g in groups:
        groups[g].sort(key=lambda t: t[0].lower())
    order = ["SPC · top level", "SPC f · file / find", "SPC s · search", "SPC c · code", "LSP · on attach",
             "SPC g · git", "SPC gh · hunks", "SPC b · buffer", "SPC w · windows", "SPC Tab · tabs", "SPC u · ui",
             "SPC x · diagnostics / quickfix", "SPC q · quit / session", "SPC d · debug", "SPC dp · profiler",
             "g · goto", "gs · surround", "[ ] · prev / next", "z · fold", "Editing & motion"]
    secs = [(g, "", [e for _, e in groups[g]]) for g in order if g in groups]
    secs += [(g, "", [e for _, e in es]) for g, es in groups.items() if g not in order]
    extras = []
    lv_json = cfg(".config/nvim/lazyvim.json")
    if lv_json:
        extras = [x.removeprefix("lazyvim.plugins.extras.") for x in json.load(open(lv_json)).get("extras", [])]
    notes = ["SPC = leader (Space) · \\ = localleader"]
    if extras:
        notes.append("extras: " + ", ".join(extras))
    if cfg(".config/nvim/lua/plugins/indent-audit.lua"):
        notes.append("SPC c f also runs your chezmoi_indent formatter on .tmpl files")
    notes.append("press SPC and wait: which-key shows everything live")
    render("lazyvim", "LazyVim", "Neovim distribution",
           f"NVIM {version(['nvim', '--version'], r'NVIM v([0-9.]+)')} · LazyVim",
           "live keymaps of your Neovim config (headless dump) · LazyVim lsp/init.lua · ~/.config/nvim",
           secs, notes=notes, cols=5, width=2800, kw="140px")


BUILDERS = {"bat": build_bat, "btop": build_btop, "delta": build_delta, "kitty": build_kitty,
            "lazygit": build_lazygit, "niri": build_niri, "noctalia": build_noctalia,
            "lazyvim": build_lazyvim, "yazi": build_yazi}
for name in ARGS.tools or BUILDERS:
    if name not in BUILDERS:
        sys.exit(f"unknown tool: {name} (choose from {', '.join(BUILDERS)})")
    BUILDERS[name]()
