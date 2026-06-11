return {
  -- OpenTofu is used instead of Terraform (binary: tofu, not terraform).
  -- Override the cmd/command in both linter and formatter so they invoke tofu.

  {
    "mfussenegger/nvim-lint",
    optional = true,
    opts = {
      linters = {
        -- terraform_validate is defined as a function in nvim-lint (not a table),
        -- so LazyVim's deep-merge skips it and replaces entirely. Wrap the original
        -- function and override only cmd so the parser stays intact.
        terraform_validate = function()
          local def = require("lint.linters.terraform_validate")()
          def.cmd = "tofu"
          return def
        end,
      },
    },
  },

  {
    "stevearc/conform.nvim",
    optional = true,
    opts = {
      formatters = {
        terraform_fmt = { command = "tofu" },
      },
    },
  },
}
