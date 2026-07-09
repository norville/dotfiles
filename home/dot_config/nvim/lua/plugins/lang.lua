return {

  -- ── LSP servers for languages without a LazyVim extra ────────────────────────
  -- Configured via nvim-lspconfig; Mason auto-installs the servers.
  -- Note: bashls, html, cssls, vimls are npm-based — require node+npm (in
  -- package matrix). sqls is a Go binary; Mason downloads a prebuilt release.

  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        -- sh · bash · zsh  (bash-language-server).
        -- Keep this entry so LazyVim installs and enables bashls. bashls
        -- surfaces shellcheck diagnostics, which would flag the Go template
        -- directives ({{ ... }}) in chezmoi *.tmpl files as parse errors — but
        -- chezmoi.vim gives those buffers the compound filetype
        -- `sh.chezmoitmpl`, and bashls only attaches to `sh`, so it skips
        -- templates while still working on real scripts. See plugins/chezmoi.lua.
        bashls = {},
        html   = {},  -- HTML · XML        (vscode-html-language-server)
        cssls  = {},  -- CSS · SCSS · Less (vscode-css-language-server)
        vimls  = {},  -- Vimscript         (vim-language-server)
        sqls   = {},  -- SQL               (sqls)
        -- clangd 22+ requires --function-arg-placeholders=<bool>; LazyVim passes
        -- it without a value, which clangd 22 rejects. Override the full cmd list.
        clangd = {
          cmd = {
            "clangd",
            "--background-index",
            "--clang-tidy",
            "--header-insertion=iwyu",
            "--completion-style=detailed",
            "--function-arg-placeholders=true",
            "--fallback-style=llvm",
          },
        },
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
