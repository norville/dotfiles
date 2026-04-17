return {
  "mfussenegger/nvim-lint",
  optional = true,
  opts = {
    linters = {
      ["markdownlint-cli2"] = {
        -- Use prepend_args to extend default args, or args to replace them
        prepend_args = { "--config", vim.fn.stdpath("config") .. "nvim/lua/config/markdownlint-cli2.yaml", "--" },
        -- OR for specific rule disabling:
        -- args = { "--disable", "MD013", "--" },
      },
    },
  },
}
