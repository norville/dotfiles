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
    -- add LazyVim and import its plugins
    { "LazyVim/LazyVim", import = "lazyvim.plugins" },
    -- LazyVim language extras — must follow lazyvim.plugins, precede user plugins
    { import = "lazyvim.plugins.extras.lang.clangd" },     -- C · C++
    { import = "lazyvim.plugins.extras.lang.go" },         -- Go
    { import = "lazyvim.plugins.extras.lang.java" },       -- Java
    { import = "lazyvim.plugins.extras.lang.rust" },       -- Rust
    { import = "lazyvim.plugins.extras.lang.python" },     -- Python
    { import = "lazyvim.plugins.extras.lang.ruby" },       -- Ruby
    { import = "lazyvim.plugins.extras.lang.lua" },        -- Lua
    { import = "lazyvim.plugins.extras.lang.typescript" }, -- JS · TS · JSX · TSX
    { import = "lazyvim.plugins.extras.lang.json" },       -- JSON · JSONC
    { import = "lazyvim.plugins.extras.lang.yaml" },       -- YAML
    { import = "lazyvim.plugins.extras.lang.toml" },       -- TOML
    { import = "lazyvim.plugins.extras.lang.markdown" },   -- Markdown
    { import = "lazyvim.plugins.extras.lang.docker" },     -- Dockerfile
    { import = "lazyvim.plugins.extras.lang.terraform" },  -- Terraform · OpenTofu
    -- import/override with your plugins
    { import = "plugins" },
  },
  defaults = {
    -- All custom plugins are lazy-loaded by default.
    -- Plugins that must load at startup (e.g. colorscheme) set `lazy = false` explicitly.
    lazy = true,
    -- It's recommended to leave version=false for now, since a lot the plugin that support versioning,
    -- have outdated releases, which may break your Neovim install.
    version = false, -- always use the latest git commit
    -- version = "*", -- try installing the latest stable version for plugins that support semver
  },
  install = { colorscheme = { "tokyonight", "habamax" } },
  checker = {
    enabled = true, -- check for plugin updates periodically
    notify = false, -- notify on update
  }, -- automatically check for plugin updates
  performance = {
    rtp = {
      -- disable some rtp plugins
      disabled_plugins = {
        "gzip",
        -- "matchit",
        -- "matchparen",
        -- "netrwPlugin",
        "tarPlugin",
        "tohtml",
        "tutor",
        "zipPlugin",
      },
    },
  },
})
