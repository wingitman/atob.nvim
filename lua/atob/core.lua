-- atob.nvim core — low-level binary invocation helpers
local M = {}

local function binary()
  return require('atob').config.binary
end

--- Run `atob list --json` and return a list of converter info tables.
--- Returns nil and an error string on failure.
---@return table[]|nil, string|nil
function M.list_converters()
  local cmd = { binary(), 'list', '--json' }
  local result = vim.system(cmd, { text = true }):wait()
  if result.code ~= 0 then
    return nil, result.stderr or 'atob list failed'
  end
  local ok, data = pcall(vim.json.decode, result.stdout)
  if not ok or type(data) ~= 'table' then
    return nil, 'could not parse atob list --json output'
  end
  return data, nil
end

--- Run a text-based converter with the given input string.
--- Returns (output_string, nil) on success, (nil, error_string) on failure.
---@param converter_name string
---@param input string
---@return string|nil, string|nil
function M.convert(converter_name, input)
  local cmd = { binary(), converter_name }
  local result = vim.system(cmd, { text = true, stdin = input }):wait()
  if result.code ~= 0 then
    local err = (result.stderr and result.stderr ~= '') and result.stderr or 'conversion failed'
    return nil, vim.trim(err)
  end
  return result.stdout, nil
end

--- Run a file-based converter.
--- Returns (nil, nil) on success, (nil, error_string) on failure.
---@param converter_name string
---@param input_path string
---@param output_path string
---@return nil, string|nil
function M.convert_file(converter_name, input_path, output_path)
  local cmd = { binary(), converter_name, input_path, output_path }
  local result = vim.system(cmd, { text = true }):wait()
  if result.code ~= 0 then
    local err = (result.stderr and result.stderr ~= '') and result.stderr or 'conversion failed'
    return nil, vim.trim(err)
  end
  return nil, nil
end

return M
