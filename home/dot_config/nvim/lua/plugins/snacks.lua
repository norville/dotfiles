-- Show hidden and gitignored files in the explorer by default
-- Toggle at runtime: H (hidden) | I (ignored)
return {
  "folke/snacks.nvim",
  opts = {
    picker = {
      sources = {
        explorer = {
          hidden = true,
          ignored = true,
        },
      },
    },
  },
}
