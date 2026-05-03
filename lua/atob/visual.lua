-- atob.nvim visual — replace visual selection with converted output
local M = {}
local core = require('atob.core')

--- Get the text covered by the current visual selection.
--- Returns lines, start_row, start_col, end_row, end_col (all 0-indexed).
local function get_visual_selection()
  -- Exit visual mode so '< '> marks are written correctly.
  local esc = vim.api.nvim_replace_termcodes('<Esc>', true, false, true)
  vim.api.nvim_feedkeys(esc, 'x', false)

  local s_row = vim.fn.line("'<") - 1
  local s_col = vim.fn.col("'<") - 1
  local e_row = vim.fn.line("'>") - 1
  local e_col = vim.fn.col("'>")  -- exclusive end for nvim_buf_get_text

  local lines = vim.api.nvim_buf_get_text(0, s_row, s_col, e_row, e_col, {})
  return lines, s_row, s_col, e_row, e_col
end

--- Replace the visual selection in the current buffer with new_lines.
local function replace_selection(s_row, s_col, e_row, e_col, new_lines)
  vim.api.nvim_buf_set_text(0, s_row, s_col, e_row, e_col, new_lines)
end

--- Format a picker entry — same style as picker.lua.
local function format_item(c)
  return string.format('%-25s %s', c.label, c.description)
end

--- Open the converter picker and replace the visual selection with the result.
function M.convert_selection()
  local sel_lines, s_row, s_col, e_row, e_col = get_visual_selection()
  local input = table.concat(sel_lines, '\n')

  local converters, err = core.list_converters()
  if not converters then
    vim.notify('[atob] ' .. (err or 'unknown error'), vim.log.levels.ERROR)
    return
  end

  -- File-based converters don't make sense for visual selection — exclude them.
  local text_converters = vim.tbl_filter(function(c)
    return not c.file_based
  end, converters)

  vim.ui.select(text_converters, {
    prompt = 'atob — convert selection:',
    format_item = format_item,
  }, function(choice)
    if not choice then return end

    local output, cerr = core.convert(choice.from, choice.to, input)
    if cerr then
      vim.notify('[atob] ' .. cerr, vim.log.levels.ERROR)
      return
    end

    -- Strip the trailing newline atob always appends before splitting back.
    output = output:gsub('\n$', '')
    local new_lines = vim.split(output, '\n', { plain = true })
    replace_selection(s_row, s_col, e_row, e_col, new_lines)
  end)
end

return M
