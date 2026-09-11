-- =============================================================================
-- Yazi UI — Tokyo Night Moon
-- =============================================================================
-- git.yazi   → per-file git status signs (see [git] in theme.toml + fetchers
--              in yazi.toml).
-- yatline.yazi → status line styled like the nvim (lualine) statusline, and a
--              header/tab bar styled like kitty's tab_bar.py. Plugins are fetched
--              by .chezmoiexternal.toml.tmpl into ~/.config/yazi/plugins.
--
-- Custom line-getters below bypass yatline's section styling (line.create returns
-- the Line as-is) so name/cwd/tabs carry their own fg/bg and slants, matching
-- kitty's tab_bar.py. Powerline glyphs are \u{...} escapes so this file is ASCII.
-- A block's color fills the slant side ADJACENT to it: LCAP (a block's right
-- edge) fills top-LEFT; RCAP (a block's left edge) fills top-RIGHT.
-- =============================================================================

require("git"):setup({ order = 1500 })

local yatline = require("yatline") -- sets the global `Yatline`, returns { setup }

-- Tokyo Night Moon palette
local C = {
  dark     = "#1b1d2b", -- fg on light blocks
  green    = "#c3e88d", -- term_green — name + cwd blocks
  bar      = "#2f334d", -- ui_bg_highlight — bar body
  blue     = "#82aaff", -- active tab / mode normal
  inact    = "#545c7e", -- ui_dark3 — inactive tab index block
  inact_fg = "#828bb8", -- term_white — inactive tab title
}
-- Header (kitty-style) slants: top triangles, leaning ╱.
local LCAP = "\u{e0bc}" -- top-left filled  — right edge of a block (color on left)
local RCAP = "\u{e0be}" -- top-right filled — left edge of a RIGHT-side block (cwd)
local LSLL = "\u{e0ba}" -- bottom-right filled — left edge of a LEFT-side block,
                        -- so it leans the same ╱ way as LCAP (parallelogram)
-- Status-bar slant, matching lualine's section_separators (bottom triangle, ╲).
local SSEP = "\u{e0b8}" -- bottom-left filled — departing colour fills bottom-left

-- Whole left status as one continuous line: mode → ext → name(green) → count,
-- each slant going straight into the next block's colour so nothing floats. Mode
-- colour mirrors style_a.bg_mode (normal blue, select magenta, unset pink).
function Yatline.line.get:status_left()
  local mode = cx.active.mode
  local mname = tostring(mode):upper()
  if mname == "UNSET" then
    mname = "UN-SET"
  end
  local mbg = C.blue
  if mode.is_select then
    mbg = "#c099ff"
  elseif mode.is_unset then
    mbg = "#fca7ea"
  end

  local h = cx.active.current.hovered
  local ext = Yatline.string.get.ext_icon()
  local name = h and h.name or ""

  local spans = {
    ui.Span(" " .. mname .. " "):fg(C.dark):bg(mbg):bold(),      -- mode (flush left)
    ui.Span(SSEP):fg(mbg):bg(C.green),                           -- mode → ext (green)
    ui.Span(" " .. ext .. " "):fg(C.dark):bg(C.green):bold(),    -- ext (green capsule)
    ui.Span(SSEP):fg(C.green):bg(C.bar),                         -- ext → bar
    ui.Span(" " .. name .. " "):fg(C.green):bg(C.bar):bold(),    -- name (green on the bar)
  }
  -- count of selected / yanked files, after name, on the bar (hidden when zero).
  local count = Yatline.coloreds.get.count(Yatline.coloreds.get, false, true)
  if count then
    spans[#spans + 1] = ui.Span(" "):bg(C.bar)
    for _, c in ipairs(count) do
      spans[#spans + 1] = ui.Span(c[1]):fg(c[2]):bg(C.bar):bold()
    end
  end
  return ui.Line(spans)
end

-- Current directory in a green capsule flush to the right edge (header right).
function Yatline.line.get:cwd_capsule()
  local path = ya.readable_path(tostring(cx.active.current.cwd))
  return ui.Line({
    ui.Span(RCAP):fg(C.green):bg(C.bar),
    ui.Span(" " .. path .. " "):fg(C.dark):bg(C.green):bold(),
  })
end

-- kitty-style tabs: index capsule (slanted both edges) + title on the bar. The
-- first tab starts flush; the last tab has no trailing separator.
function Yatline.line.get:kitty_tabs()
  local spans = {}
  for i = 1, #cx.tabs do
    local active = i == cx.tabs.idx
    local idx_bg = active and C.blue or C.inact
    if i > 1 then
      spans[#spans + 1] = ui.Span(LSLL):fg(idx_bg):bg(C.bar) -- bar → capsule
    end
    spans[#spans + 1] = ui.Span(" " .. i .. " "):fg(C.dark):bg(idx_bg):bold()
    spans[#spans + 1] = ui.Span(LCAP):fg(idx_bg):bg(C.bar) -- capsule → bar
    spans[#spans + 1] = ui.Span(" " .. cx.tabs[i].name .. " ")
      :fg(active and C.blue or C.inact_fg):bg(C.bar):bold()
  end
  return ui.Line(spans)
end

-- Location + percentage combined into one component (no separator between them).
-- yatline calls no-param getters as `getter()` (no self), so reach the sibling
-- getters through the table rather than `self`.
function Yatline.string.get.loc_pct()
  local g = Yatline.string.get
  return g:cursor_percentage() .. " " .. g:cursor_position()
end

-- Hovered file's icon + extension. Uses the current `th.icon:match` API (guarded
-- by pcall) instead of yatline's built-in extension getter, which calls the
-- deprecated `File:icon()` and floods the UI with deprecation notifications.
function Yatline.string.get:ext_icon()
  local h = cx.active.current.hovered
  if not h then
    return ""
  end
  local label = h.cha.is_dir and "dir" or (h.name:match("^.+%.(.+)$") or h.name)
  local ok, icon = pcall(function()
    return th.icon:match(h)
  end)
  if ok and icon and icon.text and icon.text ~= "" then
    return icon.text .. " " .. label
  end
  return label
end

-- Hovered file's modification time (yatline has no built-in mtime getter).
function Yatline.string.get.mtime()
  local h = cx.active.current.hovered
  if not h then
    return ""
  end
  local ok, s = pcall(function()
    local t = h.cha.mtime
    return t and os.date("%d %b %H:%M", math.floor(t)) or ""
  end)
  return (ok and s) or ""
end

-- Hovered file's ownership, collapsed to a single name when uid == gid (the
-- common "norville:norville" case) instead of yatline's always-"user:group".
function Yatline.string.get.ownership()
  local h = cx.active.current.hovered
  if not h or not h.cha.uid or not h.cha.gid then
    return ""
  end
  local user = ya.user_name(h.cha.uid) or tostring(h.cha.uid)
  if h.cha.uid == h.cha.gid then
    return user
  end
  local group = ya.group_name(h.cha.gid) or tostring(h.cha.gid)
  return user .. ":" .. group
end

-- Right-status metadata: each item is a coloured glyph capsule (leading), leaning
-- ╱ like lualine's right sections, followed by flat text on the bar.
local function capsule(spans, glyph, color)
  spans[#spans + 1] = ui.Span(LSLL):fg(color):bg(C.bar)                        -- bar → colour
  spans[#spans + 1] = ui.Span(" " .. glyph .. " "):fg(C.dark):bg(color):bold() -- glyph capsule
  spans[#spans + 1] = ui.Span(LCAP):fg(color):bg(C.bar)                        -- colour → bar
end
local function flat(spans, color, text)
  spans[#spans + 1] = ui.Span(" " .. text .. "  "):fg(color):bg(C.bar):bold()
end

-- Per-bit permission colours (mirror theme.toml [status] / permissions_*_fg).
local PERM = { t = "#82aaff", r = "#ffc777", w = "#ff757f", x = "#c3e88d", s = "#444a73" }
local function perm_fg(ch)
  if ch == "r" then return PERM.r end
  if ch == "w" then return PERM.w end
  if ch == "x" or ch == "s" or ch == "S" or ch == "t" or ch == "T" then return PERM.x end
  if ch == "-" then return PERM.s end
  return PERM.t
end

function Yatline.line.get:meta_right()
  local h = cx.active.current.hovered
  if not h then
    return ui.Line({})
  end
  local spans = {}
  -- ownership: magenta capsule + flat text.
  local own = Yatline.string.get.ownership()
  if own ~= "" then
    capsule(spans, "\u{f007}", "#c099ff")
    flat(spans, "#c099ff", own)
  end
  -- permissions: orange capsule + per-bit coloured text.
  local ok, perm = pcall(function()
    return h.cha:perm()
  end)
  if ok and perm then
    capsule(spans, "\u{f044}", "#ff966c")
    spans[#spans + 1] = ui.Span(" "):bg(C.bar)
    for i = 1, #perm do
      local ch = perm:sub(i, i)
      spans[#spans + 1] = ui.Span(ch):fg(perm_fg(ch)):bg(C.bar):bold()
    end
    spans[#spans + 1] = ui.Span("  "):bg(C.bar)
  end
  -- mtime: teal capsule + flat text.
  local mt = Yatline.string.get.mtime()
  if mt ~= "" then
    capsule(spans, "\u{f253}", "#4fd6be")
    flat(spans, "#4fd6be", mt)
  end
  return ui.Line(spans)
end

yatline:setup({
  -- Status-right section slants match lualine (bottom triangles): right sections'
  -- left edge (open) is ╱; only the status right uses these (header is custom).
  section_separator = { open = "\u{e0ba}", close = "\u{e0b8}" },
  part_separator    = { open = "", close = "" },
  inverse_separator = { open = "\u{e0b8}", close = "\u{e0ba}" },

  -- Section styles. Bold everywhere (style_a is already bold via mode styling).
  style_a = {
    fg = "#1b1d2b",
    bg_mode = { normal = "#82aaff", select = "#c099ff", un_set = "#fca7ea" },
  },
  style_b = { bg = "#3b4261", fg = "#c8d3f5", bold = true }, -- ui_fg_gutter
  style_c = { bg = "#2f334d", fg = "#828bb8", bold = true }, -- ui_bg_highlight

  -- Permission colors mirror theme.toml [status].
  permissions_t_fg = "#82aaff",
  permissions_r_fg = "#ffc777",
  permissions_w_fg = "#ff757f",
  permissions_x_fg = "#c3e88d",
  permissions_s_fg = "#444a73",

  -- Header = kitty-style tab bar: custom tabs left, cwd capsule right.
  header_line = {
    left  = { section_a = { { type = "line", name = "kitty_tabs" } } },
    right = { section_c = { { type = "line", name = "cwd_capsule" } } },
  },

  -- Status = lualine layout:
  --   left : [mode → ext(green) → name(green on bar) → count]  (one continuous block)
  --   right: [owner | perms | mtime glyph-capsules] | size(ext style) | location+%
  status_line = {
    left = {
      section_a = { { type = "line", name = "status_left" } },
      section_b = {},
      section_c = {},
    },
    right = {
      section_a = { { type = "string", name = "loc_pct" } },
      section_b = { { type = "string", name = "hovered_size" } },
      section_c = { { type = "line", name = "meta_right" } },
    },
  },
})
