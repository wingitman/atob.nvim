-- atob.nvim core — low-level binary invocation helpers
local M = {}

local function binary()
  return require('atob').config.binary
end

--- Run `atob list --picker` and return a list of picker entry tables.
--- Each entry has: from, to, label, description, file_based.
--- Returns nil and an error string on failure.
---@return table[]|nil, string|nil
function M.list_converters()
  local cmd = { binary(), 'list', '--picker' }
  local result = vim.system(cmd, { text = true }):wait()
  if result.code ~= 0 then
    return nil, result.stderr or 'atob list failed'
  end
  local ok, data = pcall(vim.json.decode, result.stdout)
  if not ok or type(data) ~= 'table' then
    return nil, 'could not parse atob list --picker output'
  end
  return data, nil
end

--- Run a text-based conversion.
--- Calls: atob <from> <to>  with stdin = input
--- Returns (output_string, nil) on success, (nil, error_string) on failure.
---@param from string  canonical type name, e.g. "json" or "any"
---@param to   string  canonical type name, e.g. "yaml"
---@param input string text to convert
---@return string|nil, string|nil
function M.convert(from, to, input)
  -- "any → <case>" entries use "text" as the actual from type
  local actual_from = (from == 'any') and 'text' or from
  local cmd = { binary(), actual_from, to }
  local result = vim.system(cmd, { text = true, stdin = input }):wait()
  if result.code ~= 0 then
    local err = (result.stderr and result.stderr ~= '') and result.stderr or 'conversion failed'
    return nil, vim.trim(err)
  end
  return result.stdout, nil
end

--- Run a file-based conversion.
--- Calls: atob <from> <to> <input_path> <output_path>
--- Returns (nil, nil) on success, (nil, error_string) on failure.
---@param from        string
---@param to          string
---@param input_path  string
---@param output_path string
---@return nil, string|nil
function M.convert_file(from, to, input_path, output_path)
  local cmd = { binary(), from, to, input_path, output_path }
  local result = vim.system(cmd, { text = true }):wait()
  if result.code ~= 0 then
    local err = (result.stderr and result.stderr ~= '') and result.stderr or 'conversion failed'
    return nil, vim.trim(err)
  end
  return nil, nil
end

--- Run a binary inspection operation on a file path.
--- Calls: atob <filepath> <operation>
--- Returns (output_string, nil) on success, (nil, error_string) on failure.
---@param filepath  string  absolute path to the file
---@param operation string  "inspect", "hexdump", or "strings"
---@return string|nil, string|nil
function M.inspect_file(filepath, operation)
  local cmd = { binary(), filepath, operation }
  local result = vim.system(cmd, { text = true }):wait()
  if result.code ~= 0 then
    local err = (result.stderr and result.stderr ~= '') and result.stderr or 'inspection failed'
    return nil, vim.trim(err)
  end
  return result.stdout, nil
end

return M
