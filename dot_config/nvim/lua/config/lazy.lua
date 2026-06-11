local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  spec = {
    -- LazyVim core and its default plugins
    { "LazyVim/LazyVim", import = "lazyvim.plugins" },
    -- LazyVim language extras — must follow lazyvim.plugins, precede user plugins
    { import = "lazyvim.plugins.extras.lang.clangd" },     -- C · C++
    { import = "lazyvim.plugins.extras.lang.go" },         -- Go
    { import = "lazyvim.plugins.extras.lang.java" },       -- Java
    { import = "lazyvim.plugins.extras.lang.rust" },       -- Rust
    { import = "lazyvim.plugins.extras.lang.python" },     -- Python
    { import = "lazyvim.plugins.extras.lang.ruby" },       -- Ruby
    { import = "lazyvim.plugins.extras.lang.typescript" }, -- JS · TS · JSX · TSX
    { import = "lazyvim.plugins.extras.lang.json" },       -- JSON · JSONC
    { import = "lazyvim.plugins.extras.lang.yaml" },       -- YAML
    { import = "lazyvim.plugins.extras.lang.toml" },       -- TOML
    { import = "lazyvim.plugins.extras.lang.markdown" },   -- Markdown
    { import = "lazyvim.plugins.extras.lang.docker" },     -- Dockerfile
    { import = "lazyvim.plugins.extras.lang.terraform" },  -- Terraform · OpenTofu
    -- User plugin specs from lua/plugins/ — imported last so they can
    -- override both LazyVim defaults and the extras above
    { import = "plugins" },
  },
  defaults = {
    -- All custom plugins are lazy-loaded by default.
    -- Plugins that must load at startup (e.g. colorscheme) set `lazy = false` explicitly.
    lazy = true,
    -- Track latest git commits: many plugins tag releases rarely, so pinning
    -- to release versions ("*") would install stale code that can break LazyVim
    version = false,
  },
  install = { colorscheme = { "tokyonight", "habamax" } },
  checker = {
    enabled = true, -- periodically check for plugin updates...
    notify = false, -- ...but do not interrupt with a notification popup
  },
  performance = {
    rtp = {
      -- Built-in vim plugins that are never used here — skip loading them
      disabled_plugins = {
        "gzip",
        "tarPlugin",
        "tohtml",
        "tutor",
        "zipPlugin",
      },
    },
  },
})
