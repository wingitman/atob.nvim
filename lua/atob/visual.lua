-- atob.nvim visual — replace visual selection with converted output
local M = {}
local core = require('atob.core')

--- Get the text covered by the current visual selection.
---@return string[], integer, integer, integer, integer  lines, start_row, start_col, end_row, end_col
local function get_visual_selection()
  -- Exit visual mode first so the '< '> marks are set correctly
  local esc = vim.api.nvim_replace_termcodes('<Esc>', true, false, true)
  vim.api.nvim_feedkeys(esc, 'x', false)

  local s_row = vim.fn.line("'<") - 1
  local s_col = vim.fn.col("'<") - 1
  local e_row = vim.fn.line("'>") - 1
  local e_col = vim.fn.col("'>")           -- exclusive end for nvim_buf_get_text

  local lines = vim.api.nvim_buf_get_text(0, s_row, s_col, e_row, e_col, {})
  return lines, s_row, s_col, e_row, e_col
end

--- Replace the visual selection in the current buffer with new_lines.
---@param s_row integer
---@param s_col integer
---@param e_row integer
---@param e_col integer
---@param new_lines string[]
local function replace_selection(s_row, s_col, e_row, e_col, new_lines)
  vim.api.nvim_buf_set_text(0, s_row, s_col, e_row, e_col, new_lines)
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

  -- filter out file-based converters — they don't make sense for visual selection
  local text_converters = vim.tbl_filter(function(c) return not c.file_based end, converters)

  local function format_item(c)
    return string.format('%-30s %s', c.name, c.description)
  end

  vim.ui.select(text_converters, {
    prompt = 'atob — convert selection:',
    format_item = format_item,
  }, function(choice)
    if not choice then return end

    local output, cerr = core.convert(choice.name, input)
    if cerr then
      vim.notify('[atob] ' .. cerr, vim.log.levels.ERROR)
      return
    end

    -- Strip trailing newline atob always adds before splitting back into lines
    output = output:gsub('\n$', '')
    local new_lines = vim.split(output, '\n', { plain = true })
    replace_selection(s_row, s_col, e_row, e_col, new_lines)
  end)
end

return M
