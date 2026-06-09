return {

  -- ── LazyVim language extras ──────────────────────────────────────────────────
  -- Each extra bundles: tree-sitter grammar + Mason LSP install +
  -- formatter (conform.nvim) + optional linter (nvim-lint).
  -- Picked up automatically via `{ import = "plugins" }` in lazy.lua.

  -- Systems / compiled
  { import = "lazyvim.plugins.extras.lang.clangd" },     -- C · C++
  { import = "lazyvim.plugins.extras.lang.go" },         -- Go
  { import = "lazyvim.plugins.extras.lang.java" },       -- Java
  { import = "lazyvim.plugins.extras.lang.rust" },       -- Rust

  -- Scripting / interpreted
  { import = "lazyvim.plugins.extras.lang.python" },     -- Python
  { import = "lazyvim.plugins.extras.lang.ruby" },       -- Ruby
  { import = "lazyvim.plugins.extras.lang.lua" },        -- Lua

  -- Web
  { import = "lazyvim.plugins.extras.lang.typescript" }, -- JS · TS · JSX · TSX

  -- Data / config formats
  { import = "lazyvim.plugins.extras.lang.json" },       -- JSON · JSONC
  { import = "lazyvim.plugins.extras.lang.yaml" },       -- YAML
  { import = "lazyvim.plugins.extras.lang.toml" },       -- TOML

  -- Prose
  { import = "lazyvim.plugins.extras.lang.markdown" },   -- marksman LSP (complements lint.lua)

  -- Infrastructure
  { import = "lazyvim.plugins.extras.lang.docker" },     -- Dockerfile
  { import = "lazyvim.plugins.extras.lang.terraform" },  -- Terraform · OpenTofu

  -- ── LSP servers for languages without a LazyVim extra ────────────────────────
  -- Configured via nvim-lspconfig; Mason auto-installs the servers.
  -- Note: bashls, html, cssls, vimls, sqls are all npm-based — require node+npm
  -- (installed by 08-install-dev-env). sqls requires go.

  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        bashls = {},  -- sh · bash · zsh  (bash-language-server)
        html   = {},  -- HTML · XML        (vscode-html-language-server)
        cssls  = {},  -- CSS · SCSS · Less (vscode-css-language-server)
        vimls  = {},  -- Vimscript         (vim-language-server)
        sqls   = {},  -- SQL               (sqls)
      },
    },
  },

  -- ── Tree-sitter parsers for languages with no LSP ────────────────────────────
  -- Syntax highlighting only. Appended to LazyVim's default ensure_installed list.

  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, {
        "kdl",   -- KDL config files
        "ini",   -- INI / .conf files
        "cmake", -- CMake / Makefile variants
        "sql",   -- SQL (also used by sqls LSP)
      })
    end,
  },

}
