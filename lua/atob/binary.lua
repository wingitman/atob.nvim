-- atob.nvim binary — inspect binary files from Neovim
-- Two entry points:
--   inspect_current_buffer(operation?)  — inspects the file in the active buffer
--   inspect_path_from_selection()       — grabs a visual selection as a file path
local M = {}
local core = require('atob.core')

-- The three available binary operations shown in the picker.
local OPERATIONS = {
  { label = 'inspect', description = 'JSON metadata (type, arch, language, sections, …)' },
  { label = 'hexdump', description = 'Hex dump with offsets and ASCII panel'              },
  { label = 'strings', description = 'Extract printable strings'                          },
}

local function format_op(o)
  return string.format('%-10s %s', o.label, o.description)
end

-- filetype hint used by show_float for syntax highlighting
local FILETYPES = {
  inspect = 'json',
  hexdump = '',        -- no standard filetype for hex dumps
  strings = '',
}

--- Run a binary operation on filepath and show the result in a float.
---@param path      string  resolved, readable file path
---@param operation string  "inspect" | "hexdump" | "strings"
local function run_and_show(path, operation)
  local output, err = core.inspect_file(path, operation)
  if err then
    vim.notify('[atob] ' .. err, vim.log.levels.ERROR)
    return
  end

  local short_name = vim.fn.fnamemodify(path, ':t')
  local title = operation .. ': ' .. short_name
  require('atob.picker').show_float(title, output or '', {
    filetype = FILETYPES[operation],
  })
end

--- Pick an operation from the mini-picker, then run it.
---@param path string
local function pick_and_run(path)
  vim.ui.select(OPERATIONS, {
    prompt = 'atob — binary operation:',
    format_item = format_op,
  }, function(choice)
    if not choice then return end
    run_and_show(path, choice.label)
  end)
end

--- Validate that path exists and is readable.
---@param path string
---@return string|nil  error message, or nil if ok
local function check_readable(path)
  if path == '' then
    return 'current buffer has no file'
  end
  if vim.fn.filereadable(path) == 0 then
    return 'file not readable: ' .. path
  end
  return nil
end

--- Inspect the file currently open in the active buffer.
--- If operation is given, run it directly. Otherwise open the operation picker.
---@param operation? string  "inspect" | "hexdump" | "strings" | nil
function M.inspect_current_buffer(operation)
  local path = vim.api.nvim_buf_get_name(0)
  local err = check_readable(path)
  if err then
    vim.notify('[atob] ' .. err, vim.log.levels.ERROR)
    return
  end

  if operation and operation ~= '' then
    run_and_show(path, operation)
  else
    pick_and_run(path)
  end
end

--- Grab the current visual selection as a file path, resolve it, then inspect.
function M.inspect_path_from_selection()
  -- Exit visual mode so '< '> marks are set correctly.
  local esc = vim.api.nvim_replace_termcodes('<Esc>', true, false, true)
  vim.api.nvim_feedkeys(esc, 'x', false)

  local s_row = vim.fn.line("'<") - 1
  local s_col = vim.fn.col("'<") - 1
  local e_row = vim.fn.line("'>") - 1
  local e_col = vim.fn.col("'>")

  local lines = vim.api.nvim_buf_get_text(0, s_row, s_col, e_row, e_col, {})
  local raw = vim.trim(table.concat(lines, ''))

  if raw == '' then
    vim.notify('[atob] selection is empty', vim.log.levels.ERROR)
    return
  end

  -- Expand ~ and resolve relative paths against the buffer's directory.
  local path = vim.fn.expand(raw)
  if not vim.fn.fnamemodify(path, ':p'):find('^/') then
    -- still relative — resolve against cwd
    path = vim.fn.getcwd() .. '/' .. path
  end
  path = vim.fn.fnamemodify(path, ':p') -- absolute + normalised

  local err = check_readable(path)
  if err then
    vim.notify('[atob] ' .. err, vim.log.levels.ERROR)
    return
  end

  pick_and_run(path)
end

return M
