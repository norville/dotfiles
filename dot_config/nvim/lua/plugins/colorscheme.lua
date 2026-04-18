return {

  -- config tokyonight theme
  {
    "folke/tokyonight.nvim",
    lazy = false,    -- must load at startup so the colorscheme is set before any UI renders
    priority = 1000, -- load before all other plugins
    opts = {
      style = "moon",
      transparent = true,
      styles = {
        sidebars = "transparent",
        floats = "transparent",
      },
      -- Restore background highlight groups that render-markdown.nvim depends on.
      -- Transparency wipes these out, making heading bands and code blocks invisible.
      on_highlights = function(hl, c)
        -- Heading backgrounds: subtle tinted bands, one per level
        hl.RenderMarkdownH1Bg = { bg = "#2d2257" } -- purple
        hl.RenderMarkdownH2Bg = { bg = "#1a2b4a" } -- blue
        hl.RenderMarkdownH3Bg = { bg = "#1a3a2a" } -- green
        hl.RenderMarkdownH4Bg = { bg = "#2a2a1a" } -- yellow
        hl.RenderMarkdownH5Bg = { bg = "#2a1a1a" } -- red/orange
        hl.RenderMarkdownH6Bg = { bg = "#1e2030" } -- neutral (matches moon base)

        -- Code blocks: slightly elevated surface so they stand out from prose
        hl.RenderMarkdownCode = { bg = "#1e2030" }
        hl.RenderMarkdownCodeBorder = { bg = "#1e2030" }
        hl.RenderMarkdownCodeInline = { bg = "#2a2d47", fg = c.green }

        -- Sign column background (used by heading/code signs on the left)
        hl.RenderMarkdownSign = { bg = c.bg_sidebar or "NONE" }
      end,
    },
  },
}
