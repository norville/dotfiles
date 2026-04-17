-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- Keep syntax concealed (bold markers, heading ##, code fences) when the
-- cursor is on that line in normal and command mode. Without this, concealed
-- text flashes back into view on the current line, which is distracting with
-- render-markdown.nvim active.
vim.opt.concealcursor = "nc"
