return {

  -- ── LSP servers for languages without a LazyVim extra ────────────────────────
  -- Configured via nvim-lspconfig; Mason auto-installs the servers.
  -- Note: bashls, html, cssls, vimls are npm-based — require node+npm (in
  -- package matrix). sqls is a Go binary; Mason downloads a prebuilt release.

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
