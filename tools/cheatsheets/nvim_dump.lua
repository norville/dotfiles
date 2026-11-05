-- Dump every keymap that carries a description, as Neovim actually has them
-- after LazyVim's deferred setup. Run headless against the config to inspect:
--   CHEATSHEETS_NVIM_OUT=<out.json> nvim --headless "+luafile nvim_dump.lua" +qa
-- Buffer-local maps (LSP on attach, filetype plugins) are not visible here.

-- LazyVim registers its keymaps and most plugin `keys` on VeryLazy, which a
-- headless start never fires on its own.
vim.api.nvim_exec_autocmds("User", { pattern = "VeryLazy", modeline = false })
vim.wait(1500)

local maps = {}
for _, mode in ipairs({ "n", "x", "v", "o", "i", "t", "s" }) do
  for _, m in ipairs(vim.api.nvim_get_keymap(mode)) do
    if m.desc and m.desc ~= "" and not m.lhs:match("^<Plug>") then
      table.insert(maps, {
        mode = mode,
        lhs = m.lhsraw and vim.fn.keytrans(m.lhsraw) or m.lhs,
        desc = m.desc,
      })
    end
  end
end

local f = assert(io.open(assert(os.getenv("CHEATSHEETS_NVIM_OUT")), "w"))
f:write(vim.json.encode({ maps = maps, leader = vim.g.mapleader, localleader = vim.g.maplocalleader }))
f:close()
