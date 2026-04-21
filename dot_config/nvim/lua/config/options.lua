-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- Honour .editorconfig files (indent, charset, trim_trailing_whitespace, etc.).
-- true is the default since Neovim 0.9; stated explicitly so the intent is clear.
vim.g.editorconfig = true

-- Keep syntax concealed (bold markers, heading ##, code fences) when the
-- cursor is on that line in normal and command mode. Without this, concealed
-- text flashes back into view on the current line, which is distracting with
-- render-markdown.nvim active.
vim.opt.concealcursor = "nc"
