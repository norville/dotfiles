-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

-- Caddyfile — use real tabs (Caddy's canonical indent style)
vim.api.nvim_create_autocmd("BufEnter", {
  pattern = "Caddyfile",
  callback = function()
    vim.opt_local.expandtab = false
    vim.opt_local.tabstop = 4
    vim.opt_local.shiftwidth = 4
  end,
})

-- Markdown — prose-friendly line wrapping and spell checking
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "markdown", "text" },
  callback = function()
    vim.opt_local.wrap = true
    vim.opt_local.linebreak = true -- break at word boundaries, not mid-word
    vim.opt_local.breakindent = true -- wrapped lines preserve indentation
    vim.opt_local.showbreak = "  " -- two-space hang for wrapped lines (also needed if you enable repeat_linebreak on blockquotes)
    vim.opt_local.spell = true
    vim.opt_local.spelllang = "en_us" -- change to en_gb, nl, etc. as needed
  end,
})
