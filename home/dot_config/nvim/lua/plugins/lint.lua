return {
  "mfussenegger/nvim-lint",
  optional = true,
  opts = {
    linters = {
      ["markdownlint-cli2"] = {
        -- Without an explicit --config, markdownlint-cli2 searches upward from
        -- the linted file and may pick up a repo's own rules; pin ours instead.
        -- prepend_args extends nvim-lint's default args rather than replacing them.
        prepend_args = { "--config", vim.fn.stdpath("config") .. "/lua/config/markdownlint-cli2.yaml", "--" },
      },
    },
  },
}
