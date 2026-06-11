-- indent-audit — indentation checker/fixer for this dotfiles repo.
--
-- Two rule sets (mirrors dot_editorconfig):
--   1. chezmoi templates (*.tmpl): lines that are entirely Go template
--      directives ({{ ... }}) indent in 2-space steps, one per nesting level
--      of the enclosing template blocks (if/range/with). Comment directives
--      ({{ /* ... */ }}) align with the directive they precede.
--   2. every other line follows the underlying filetype's indent unit —
--      flagged only (never auto-fixed: alignment continuations are legal).
--
-- Used by :IndentAudit / :IndentFix and as the conform.nvim formatter
-- "chezmoi_indent" (see lua/plugins/indent-audit.lua).

local M = {}

-- Template block openers that increase nesting depth (closed by "end").
local OPEN = { ["if"] = true, ["range"] = true, ["with"] = true }

-- Indent units per filetype for the content of .tmpl files. editorconfig
-- resolves *.tmpl buffers to indent_size = 2 (the directive rule), so the
-- underlying filetype's unit must come from this table instead.
local TMPL_CONTENT_UNIT = { sh = 4, bash = 4, zsh = 4, python = 4, qml = 4, sql = 4 }

local function first_word(body)
  return body:match("^(%S+)") or ""
end

-- Analyze (and compute fixes for) a list of lines.
-- opts: { is_tmpl = bool, unit = number, expandtab = bool }
-- Returns { issues = { {lnum, msg, severity, fixable} }, fixed = lines }.
function M.analyze(lines, opts)
  opts = opts or {}
  local unit = opts.unit or 2
  local issues, fixed = {}, {}
  for i, l in ipairs(lines) do
    fixed[i] = l
  end

  local depth = 0
  local pending = {} -- comment-directive line numbers awaiting an anchor indent
  local in_multi = false -- inside a directive spanning multiple lines

  local function flag(lnum, msg, severity, want)
    table.insert(issues, { lnum = lnum, msg = msg, severity = severity, fixable = want ~= nil })
    if want then
      fixed[lnum] = string.rep(" ", want) .. lines[lnum]:gsub("^%s+", "")
    end
  end

  -- Re-anchor any buffered comment directives to the given indent.
  local function flush_pending(want)
    for _, idx in ipairs(pending) do
      local cur = #lines[idx]:match("^%s*")
      if cur ~= want then
        flag(idx, ("comment directive: indent %d, want %d"):format(cur, want), vim.diagnostic.severity.WARN, want)
      end
    end
    pending = {}
  end

  for i, line in ipairs(lines) do
    repeat -- single-pass loop so `break` acts as a per-line `continue`
      if in_multi then
        -- continuation lines of a multi-line directive are alignment-styled; skip
        if line:find("}}", 1, true) then
          in_multi = false
        end
        break
      end
      if line:match("^%s*$") then
        break
      end

      local indent = line:match("^%s*")
      local trimmed = vim.trim(line)
      local is_directive = opts.is_tmpl and vim.startswith(trimmed, "{{")

      if is_directive then
        -- collect every {{ ... }} chunk on the line; detect multi-line directives
        local bodies, rest, multi = {}, trimmed, false
        while #rest > 0 do
          if not vim.startswith(rest, "{{") then
            bodies = nil -- trailing non-directive text: treat the line as content
            break
          end
          local close = rest:find("}}", 3, true)
          if not close then
            multi = true
            break
          end
          local body = rest:sub(3, close - 1):gsub("^[%-%s]+", ""):gsub("[%-%s]+$", "")
          bodies[#bodies + 1] = body
          rest = vim.trim(rest:sub(close + 2))
        end

        if bodies ~= nil or multi then
          local body1 = multi and trimmed:sub(3):gsub("^[%-%s]+", "") or bodies[1]

          if vim.startswith(body1, "/*") and not multi then
            pending[#pending + 1] = i -- align later, with the directive it precedes
            break
          end

          local d = depth
          local w1 = first_word(body1)
          if vim.startswith(w1, "else") or vim.startswith(w1, "end") then
            d = d - 1
          end
          local want = 2 * math.max(d, 0)
          flush_pending(want)
          if #indent ~= want or indent:find("\t") then
            flag(
              i,
              ("directive: indent %d, want %d (template depth %d)"):format(#indent, want, math.max(d, 0)),
              vim.diagnostic.severity.WARN,
              want
            )
          end

          if multi then
            if OPEN[w1] then
              depth = depth + 1
            elseif w1 == "end" then
              depth = depth - 1
            end
            in_multi = true
          else
            for _, b in ipairs(bodies) do
              local w = first_word(b)
              if OPEN[w] then
                depth = depth + 1
              elseif w == "end" then
                depth = depth - 1
              end
            end
          end
          break
        end
      end

      -- content line: comments waiting here belong to the surrounding depth
      flush_pending(2 * math.max(depth, 0))
      if opts.expandtab ~= false and indent:find("\t") then
        flag(i, "tab in indentation (indent_style = space)", vim.diagnostic.severity.WARN)
      elseif unit > 0 and #indent % unit ~= 0 then
        flag(
          i,
          ("indent %d is not a multiple of %d (fine if this is an alignment continuation)"):format(#indent, unit),
          vim.diagnostic.severity.HINT
        )
      end
    until true
  end
  flush_pending(2 * math.max(depth, 0))

  return { issues = issues, fixed = fixed }
end

-- Resolve analyze() options for a buffer: template detection plus the
-- effective indent unit (editorconfig-resolved for regular files, filetype
-- table for .tmpl content — see TMPL_CONTENT_UNIT).
function M.buf_opts(buf)
  buf = buf or 0
  local is_tmpl = vim.api.nvim_buf_get_name(buf):match("%.tmpl$") ~= nil
  local unit
  if is_tmpl then
    unit = TMPL_CONTENT_UNIT[vim.bo[buf].filetype] or 2
  else
    unit = vim.bo[buf].shiftwidth
    if unit == 0 then
      unit = vim.bo[buf].tabstop
    end
  end
  return { is_tmpl = is_tmpl, unit = unit, expandtab = vim.bo[buf].expandtab }
end

local ns = vim.api.nvim_create_namespace("indent-audit")

-- :IndentAudit — report violations in the current buffer as diagnostics.
function M.audit(buf)
  buf = buf or vim.api.nvim_get_current_buf()
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local result = M.analyze(lines, M.buf_opts(buf))
  local diags = {}
  for _, it in ipairs(result.issues) do
    diags[#diags + 1] = {
      lnum = it.lnum - 1,
      col = 0,
      message = it.msg,
      severity = it.severity,
      source = "indent-audit",
    }
  end
  vim.diagnostic.set(ns, buf, diags)
  vim.notify(("indent-audit: %d issue(s)"):format(#diags), vim.log.levels.INFO)
end

-- :IndentFix — apply the directive-indent fixes to the current buffer.
-- Content lines are never rewritten; rerun :IndentAudit to see what remains.
function M.fix(buf)
  buf = buf or vim.api.nvim_get_current_buf()
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local result = M.analyze(lines, M.buf_opts(buf))
  local changed = 0
  for i, l in ipairs(result.fixed) do
    if l ~= lines[i] then
      vim.api.nvim_buf_set_lines(buf, i - 1, i, false, { l })
      changed = changed + 1
    end
  end
  vim.notify(("indent-audit: fixed %d line(s)"):format(changed), vim.log.levels.INFO)
end

return M
