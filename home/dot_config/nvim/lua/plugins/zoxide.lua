-- Directory jumping with frecency ranking via zoxide
-- :Z {query}  — jump to best match | :Zi {query} — interactive fzf picker
-- <leader>fz  — open interactive zoxide picker
return {
  "nanotee/zoxide.vim",
  cmd = { "Z", "Zi", "Zoxide" },
  keys = {
    { "<leader>fz", "<cmd>Zi<cr>", desc = "Zoxide (frecency)" },
  },
}
