-- Statusline tweaks:
--  1. Starship-style slanted separators. Only swaps the separator glyphs;
--     section fg/bg colors are left to LazyVim's theme = "auto", so lualine
--     keeps auto-coloring each separator with the adjacent sections' bg.
--       section (filled):     | component (line):  
--  2. Swap the y/z slots: y shows encoding + fileformat, z keeps
--     LazyVim's progress + location (moved down from y).
return {
  "nvim-lualine/lualine.nvim",
  opts = {
    options = {
      section_separators = { left = "", right = "" },
      component_separators = { left = "", right = "" },
    },
    sections = {
      lualine_y = {
        { "fileformat", separator = " ", padding = { left = 1, right = 0 } },
        { "encoding", separator = " " },
        { "filesize", padding = { left = 0, right = 1 } },
      },
      lualine_z = {
        { "progress", separator = " ", padding = { left = 1, right = 0 } },
        { "location", padding = { left = 0, right = 1 } },
      },
    },
  },
}
