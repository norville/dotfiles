return {
  "mfussenegger/nvim-lint",
  optional = true,
  opts = {
    linters = {
      ["markdownlint-cli2"] = {
        -- Use prepend_args to extend default args, or args to replace them.
        -- stdpath("config") already returns the nvim config dir (e.g. ~/.config/nvim),
        -- so the path below resolves to ~/.config/nvim/lua/config/markdownlint-cli2.yaml.
        prepend_args = { "--config", vim.fn.stdpath("config") .. "/lua/config/markdownlint-cli2.yaml", "--" },
        -- OR for specific rule disabling:
        -- args = { "--disable", "MD013", "--" },
      },
    },
  },
}
