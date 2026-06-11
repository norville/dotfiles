-- In-buffer markdown rendering: heading bands, code blocks, tables, callouts.
-- This is the full plugin config (not just overrides) so every knob is visible
-- in one place; values that deviate from plugin defaults carry a comment.
-- Option reference: https://github.com/MeanderingProgrammer/render-markdown.nvim
return {

  {
    "MeanderingProgrammer/render-markdown.nvim",
    dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-mini/mini.nvim" },
    ---@module 'render-markdown'
    ---@type render.md.UserConfig
    opts = {
      -- Render in normal and command mode; default renders in normal only,
      -- which makes raw markdown flash back whenever insert mode is entered.
      -- Add "i" to render while typing too — noisy in practice.
      render_modes = { "n", "c" },
      heading = {
        enabled = true,
        render_modes = false,
        atx = true,
        setext = true,
        sign = true,
        icons = { "󰲡 ", "󰲣 ", "󰲥 ", "󰲧 ", "󰲩 ", "󰲫 " },
        -- "inline" conceals the '#'s and puts the icon where they were;
        -- alternatives: overlay (pad over '#'), eol/right (icon at line end)
        position = "inline",
        signs = { "󰫎 " },
        -- Background band spans the whole window width, not just the text
        width = "full",
        left_margin = 0,
        left_pad = 0,
        right_pad = 0,
        min_width = 0,
        border = false,
        border_virtual = false,
        border_prefix = false,
        above = "▄",
        below = "▀",
        backgrounds = {
          "RenderMarkdownH1Bg",
          "RenderMarkdownH2Bg",
          "RenderMarkdownH3Bg",
          "RenderMarkdownH4Bg",
          "RenderMarkdownH5Bg",
          "RenderMarkdownH6Bg",
        },
        foregrounds = {
          "RenderMarkdownH1",
          "RenderMarkdownH2",
          "RenderMarkdownH3",
          "RenderMarkdownH4",
          "RenderMarkdownH5",
          "RenderMarkdownH6",
        },
        custom = {},
      },
      paragraph = {
        enabled = true,
        render_modes = false,
        left_margin = 0,
        indent = 0,
        min_width = 0,
      },
      code = {
        enabled = true,
        render_modes = false,
        sign = true,
        conceal_delimiters = true,
        language = true,
        position = "left",
        language_icon = true,
        language_name = true,
        language_info = true,
        language_pad = 0,
        disable = {},
        -- diff blocks highlight their own added/removed lines — a block
        -- background would fight with those colors
        disable_background = { "diff" },
        width = "full",
        left_margin = 0,
        left_pad = 0,
        right_pad = 0,
        min_width = 0,
        -- "hide" conceals the ``` fence lines entirely (the language label
        -- still shows); alternatives: none, thick, thin
        border = "hide",
        language_border = "█",
        language_left = "",
        language_right = "",
        above = "▄",
        below = "▀",
        inline = true,
        inline_left = "",
        inline_right = "",
        inline_pad = 0,
        priority = 140,
        highlight = "RenderMarkdownCode",
        highlight_info = "RenderMarkdownCodeInfo",
        highlight_language = nil,
        highlight_border = "RenderMarkdownCodeBorder",
        highlight_fallback = "RenderMarkdownCodeFallback",
        highlight_inline = "RenderMarkdownCodeInline",
        highlight_inline_left = nil,
        highlight_inline_right = nil,
        style = "full",
      },
      dash = {
        enabled = true,
        render_modes = false,
        icon = "─",
        width = "full",
        left_margin = 0,
        priority = nil,
        highlight = "RenderMarkdownDash",
      },
      bullet = {
        enabled = true,
        render_modes = false,
        -- One icon per nesting level, cycling: ● ○ ◆ ◇ ● …
        icons = { "●", "○", "◆", "◇" },
        -- Renumber ordered lists visually: "1. 1. 1." renders as "1. 2. 3."
        -- (markdown allows all-1 source; this shows the effective numbering)
        ordered_icons = function(ctx)
          local value = vim.trim(ctx.value)
          local index = tonumber(value:sub(1, #value - 1))
          return ("%d."):format(index > 1 and index or ctx.index)
        end,
        left_pad = 0,
        right_pad = 0,
        highlight = "RenderMarkdownBullet",
        scope_highlight = {},
        scope_priority = nil,
      },
      checkbox = {
        enabled = true,
        render_modes = false,
        bullet = false,
        left_pad = 0,
        right_pad = 1,
        unchecked = {
          icon = "󰄱 ",
          highlight = "RenderMarkdownUnchecked",
          scope_highlight = nil,
        },
        checked = {
          icon = "󰱒 ",
          highlight = "RenderMarkdownChecked",
          scope_highlight = nil,
        },
        -- Extra checkbox state beyond the grammar's [ ]/[x]:
        -- [-] renders as a clock icon, used for "in progress" items
        -- stylua: ignore
        custom = {
            todo = { raw = '[-]', rendered = '󰥔 ', highlight = 'RenderMarkdownTodo', scope_highlight = nil },
        },
        scope_priority = nil,
      },
      quote = {
        enabled = true,
        render_modes = false,
        icon = "▋",
        -- Repeating the quote bar on wrapped lines requires matching
        -- showbreak/breakindent settings (see config/autocmds.lua) — off here
        repeat_linebreak = false,
        highlight = {
          "RenderMarkdownQuote1",
          "RenderMarkdownQuote2",
          "RenderMarkdownQuote3",
          "RenderMarkdownQuote4",
          "RenderMarkdownQuote5",
          "RenderMarkdownQuote6",
        },
      },
      pipe_table = {
        enabled = true,
        render_modes = false,
        preset = "none",
        -- "padded" replaces the '|' separators and pads cells to equal visual
        -- width per column; alternatives: raw, trimmed, overlay
        cell = "padded",
        cell_offset = function()
          return 0
        end,
        padding = 1,
        min_width = 0,
        -- stylua: ignore
        border = {
            '┌', '┬', '┐',
            '├', '┼', '┤',
            '└', '┴', '┘',
            '│', '─',
        },
        border_enabled = true,
        border_virtual = false,
        alignment_indicator = "━",
        head = "RenderMarkdownTableHead",
        row = "RenderMarkdownTableRow",
        style = "full",
      },
      callout = {
        -- GitHub callouts (https://github.com/orgs/community/discussions/16925)
        note = {
          raw = "[!NOTE]",
          rendered = "󰋽 Note",
          highlight = "RenderMarkdownInfo",
          category = "github",
        },
        tip = {
          raw = "[!TIP]",
          rendered = "󰌶 Tip",
          highlight = "RenderMarkdownSuccess",
          category = "github",
        },
        important = {
          raw = "[!IMPORTANT]",
          rendered = "󰅾 Important",
          highlight = "RenderMarkdownHint",
          category = "github",
        },
        warning = {
          raw = "[!WARNING]",
          rendered = "󰀪 Warning",
          highlight = "RenderMarkdownWarn",
          category = "github",
        },
        caution = {
          raw = "[!CAUTION]",
          rendered = "󰳦 Caution",
          highlight = "RenderMarkdownError",
          category = "github",
        },
        -- Obsidian callouts (https://help.obsidian.md/Editing+and+formatting/Callouts)
        abstract = {
          raw = "[!ABSTRACT]",
          rendered = "󰨸 Abstract",
          highlight = "RenderMarkdownInfo",
          category = "obsidian",
        },
        summary = {
          raw = "[!SUMMARY]",
          rendered = "󰨸 Summary",
          highlight = "RenderMarkdownInfo",
          category = "obsidian",
        },
        tldr = {
          raw = "[!TLDR]",
          rendered = "󰨸 Tldr",
          highlight = "RenderMarkdownInfo",
          category = "obsidian",
        },
        info = {
          raw = "[!INFO]",
          rendered = "󰋽 Info",
          highlight = "RenderMarkdownInfo",
          category = "obsidian",
        },
        todo = {
          raw = "[!TODO]",
          rendered = "󰗡 Todo",
          highlight = "RenderMarkdownInfo",
          category = "obsidian",
        },
        hint = {
          raw = "[!HINT]",
          rendered = "󰌶 Hint",
          highlight = "RenderMarkdownSuccess",
          category = "obsidian",
        },
        success = {
          raw = "[!SUCCESS]",
          rendered = "󰄬 Success",
          highlight = "RenderMarkdownSuccess",
          category = "obsidian",
        },
        check = {
          raw = "[!CHECK]",
          rendered = "󰄬 Check",
          highlight = "RenderMarkdownSuccess",
          category = "obsidian",
        },
        done = {
          raw = "[!DONE]",
          rendered = "󰄬 Done",
          highlight = "RenderMarkdownSuccess",
          category = "obsidian",
        },
        question = {
          raw = "[!QUESTION]",
          rendered = "󰘥 Question",
          highlight = "RenderMarkdownWarn",
          category = "obsidian",
        },
        help = {
          raw = "[!HELP]",
          rendered = "󰘥 Help",
          highlight = "RenderMarkdownWarn",
          category = "obsidian",
        },
        faq = {
          raw = "[!FAQ]",
          rendered = "󰘥 Faq",
          highlight = "RenderMarkdownWarn",
          category = "obsidian",
        },
        attention = {
          raw = "[!ATTENTION]",
          rendered = "󰀪 Attention",
          highlight = "RenderMarkdownWarn",
          category = "obsidian",
        },
        failure = {
          raw = "[!FAILURE]",
          rendered = "󰅖 Failure",
          highlight = "RenderMarkdownError",
          category = "obsidian",
        },
        fail = {
          raw = "[!FAIL]",
          rendered = "󰅖 Fail",
          highlight = "RenderMarkdownError",
          category = "obsidian",
        },
        missing = {
          raw = "[!MISSING]",
          rendered = "󰅖 Missing",
          highlight = "RenderMarkdownError",
          category = "obsidian",
        },
        danger = {
          raw = "[!DANGER]",
          rendered = "󱐌 Danger",
          highlight = "RenderMarkdownError",
          category = "obsidian",
        },
        error = {
          raw = "[!ERROR]",
          rendered = "󱐌 Error",
          highlight = "RenderMarkdownError",
          category = "obsidian",
        },
        bug = {
          raw = "[!BUG]",
          rendered = "󰨰 Bug",
          highlight = "RenderMarkdownError",
          category = "obsidian",
        },
        example = {
          raw = "[!EXAMPLE]",
          rendered = "󰉹 Example",
          highlight = "RenderMarkdownHint",
          category = "obsidian",
        },
        quote = {
          raw = "[!QUOTE]",
          rendered = "󱆨 Quote",
          highlight = "RenderMarkdownQuote",
          category = "obsidian",
        },
        cite = {
          raw = "[!CITE]",
          rendered = "󱆨 Cite",
          highlight = "RenderMarkdownQuote",
          category = "obsidian",
        },
      },
      link = {
        enabled = true,
        render_modes = false,
        footnote = {
          enabled = true,
          icon = "󰯔 ",
          body = function(ctx)
            return ctx.text
          end,
          superscript = true,
          prefix = "",
          suffix = "",
        },
        image = "󰥶 ",
        image_custom = true,
        email = "󰀓 ",
        hyperlink = "󰌹 ",
        highlight = "RenderMarkdownLink",
        highlight_title = "RenderMarkdownLinkTitle",
        -- [[WikiLinks]]: icon only, body hidden (function returns nil)
        wiki = {
          enabled = true,
          icon = "󱗖 ",
          body = function()
            return nil
          end,
          highlight = "RenderMarkdownWikiLink",
          scope_highlight = nil,
        },
        custom = {
          web = { pattern = "^http", icon = "󰖟 " },
          apple = { pattern = "apple%.com", icon = " " },
          discord = { pattern = "discord%.com", icon = "󰙯 " },
          github = { pattern = "github%.com", icon = "󰊤 " },
          gitlab = { pattern = "gitlab%.com", icon = "󰮠 " },
          google = { pattern = "google%.com", icon = "󰊭 " },
          hackernews = { pattern = "ycombinator%.com", icon = " " },
          linkedin = { pattern = "linkedin%.com", icon = "󰌻 " },
          microsoft = { pattern = "microsoft%.com", icon = " " },
          neovim = { pattern = "neovim%.io", icon = " " },
          reddit = { pattern = "reddit%.com", icon = "󰑍 " },
          slack = { pattern = "slack%.com", icon = "󰒱 " },
          stackoverflow = { pattern = "stackoverflow%.com", icon = "󰓌 " },
          steam = { pattern = "steampowered%.com", icon = " " },
          twitter = { pattern = "twitter%.com", icon = " " },
          wikipedia = { pattern = "wikipedia%.org", icon = "󰖬 " },
          x = { pattern = "x%.com", icon = " " },
          youtube = { pattern = "youtube[^.]*%.com", icon = "󰗃 " },
          youtube_short = { pattern = "youtu%.be", icon = "󰗃 " },
        },
        -- ^ per-site link icons, matched against the destination URL;
        -- longest matching pattern wins, "web" is the catch-all
      },
      sign = {
        enabled = true,
        priority = nil,
        highlight = "RenderMarkdownSign",
      },
      -- org-indent-mode style body indenting per heading level — not used
      indent = {
        enabled = false,
        render_modes = false,
        per_level = 2,
        skip_level = 1,
        skip_heading = false,
        icon = "▎",
        priority = 0,
        highlight = "RenderMarkdownIndent",
      },
    },
    ft = { "markdown", "norg", "rmd", "org", "codecompanion" },
    config = function(_, opts)
      require("render-markdown").setup(opts)
      Snacks.toggle({
        name = "Render Markdown",
        get = require("render-markdown").get,
        set = require("render-markdown").set,
      }):map("<leader>um")
    end,
  },
}
