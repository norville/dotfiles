-- Statusline tweaks:
--  1. Starship-style slanted separators. Only swaps the separator glyphs;
--     section fg/bg colors are left to LazyVim's theme = "auto", so lualine
--     keeps auto-coloring each separator with the adjacent sections' bg.
--       section (filled):     | component (line):  
--  2. Swap the y/z slots: y shows encoding + fileformat, z keeps
--     LazyVim's progress + location (moved down from y).
-- Only render the y/z slots for real file buffers; hide them on
-- neo-tree, dashboard, terminals, help, [No Name], etc.
local function is_file()
  return vim.bo.buftype == "" and vim.api.nvim_buf_get_name(0) ~= ""
end

return {
  "nvim-lualine/lualine.nvim",
  opts = {
    options = {
      section_separators = { left = "", right = "" },
      component_separators = { left = "", right = "" },
    },
    sections = {
      lualine_y = {
        { "fileformat", cond = is_file, separator = " ", padding = { left = 1, right = 0 } },
        { "encoding", cond = is_file, separator = " " },
        { "filesize", cond = is_file, padding = { left = 0, right = 1 } },
      },
      lualine_z = {
        { "progress", cond = is_file, separator = " ", padding = { left = 1, right = 0 } },
        { "location", cond = is_file, padding = { left = 0, right = 1 } },
      },
    },
  },
}
