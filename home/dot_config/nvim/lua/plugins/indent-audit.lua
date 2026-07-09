-- Wire lua/indent-audit/ into LazyVim:
--   - conform formatter "chezmoi_indent": reindents Go template directives in
--     .tmpl buffers (2-space steps per template depth) — runs via <leader>cf
--     only, since format-on-save is disabled in this config
--   - :IndentAudit reports rule violations as diagnostics, :IndentFix applies
--     the directive fixes without going through conform
return {
  {
    "stevearc/conform.nvim",
    optional = true,
    init = function()
      vim.api.nvim_create_user_command("IndentAudit", function()
        require("indent-audit").audit()
      end, { desc = "Report indentation violations as diagnostics" })
      vim.api.nvim_create_user_command("IndentFix", function()
        require("indent-audit").fix()
      end, { desc = "Fix template-directive indentation in this buffer" })
    end,
    opts = function(_, opts)
      opts.formatters = opts.formatters or {}
      opts.formatters.chezmoi_indent = {
        -- only meaningful for chezmoi templates; skipped everywhere else
        condition = function(_, ctx)
          return ctx.filename:match("%.tmpl$") ~= nil
        end,
        format = function(_, _, lines, callback)
          local result = require("indent-audit").analyze(lines, { is_tmpl = true })
          callback(nil, result.fixed)
        end,
      }
      -- Keep shfmt away from templates. chezmoi.vim gives *.tmpl buffers the
      -- compound filetype `<base>.chezmoitmpl` (e.g. dot_zshrc.tmpl → zsh.chezmoitmpl,
      -- a .sh.tmpl → sh.chezmoitmpl), so conform still runs the base formatter
      -- (shfmt for the sh part). shfmt cannot parse Go template directives, fails,
      -- and aborts the format chain before chezmoi_indent runs. Skip it on *.tmpl.
      opts.formatters.shfmt = opts.formatters.shfmt or {}
      opts.formatters.shfmt.condition = function(_, ctx)
        return ctx.filename:match("%.tmpl$") == nil
      end

      -- "*" appends to every filetype's formatter list, so chezmoi_indent is
      -- available regardless of the (compound) filetype a template ends up with.
      opts.formatters_by_ft = opts.formatters_by_ft or {}
      opts.formatters_by_ft["*"] = opts.formatters_by_ft["*"] or {}
      table.insert(opts.formatters_by_ft["*"], "chezmoi_indent")
    end,
  },
}
