-- atob.nvim picker — vim.ui.select-based converter chooser
local M = {}
local core = require('atob.core')

--- Format a picker entry for display.
--- Each entry has: from, to, label, description, file_based.
---@param c table  pickerEntry from atob list --picker
---@return string
local function format_item(c)
  local suffix = c.file_based and '  [file]' or ''
  return string.format('%-25s %s%s', c.label, c.description, suffix)
end

--- Open a picker, let the user choose a conversion, then:
---   • Text conversions: prompt for input → show result in a floating window.
---   • File conversions: prompt for input/output paths → run conversion.
function M.prompt_convert()
  local converters, err = core.list_converters()
  if not converters then
    vim.notify('[atob] ' .. (err or 'unknown error'), vim.log.levels.ERROR)
    return
  end

  vim.ui.select(converters, {
    prompt = 'atob — choose converter:',
    format_item = format_item,
  }, function(choice)
    if not choice then return end

    if choice.file_based then
      vim.ui.input({ prompt = 'Input file path: ' }, function(input_path)
        if not input_path or input_path == '' then return end
        vim.ui.input({ prompt = 'Output file path: ' }, function(output_path)
          if not output_path or output_path == '' then return end
          local _, ferr = core.convert_file(choice.from, choice.to, input_path, output_path)
          if ferr then
            vim.notify('[atob] ' .. ferr, vim.log.levels.ERROR)
          else
            vim.notify(string.format('[atob] %s → %s (done)', input_path, output_path))
          end
        end)
      end)
      return
    end

    -- Text-based: prompt for input then show result in float.
    vim.ui.input({
      prompt = string.format('%s: ', choice.label),
    }, function(input)
      if input == nil then return end
      local output, cerr = core.convert(choice.from, choice.to, input)
      if cerr then
        vim.notify('[atob] ' .. cerr, vim.log.levels.ERROR)
        return
      end
      M.show_float(choice.label, output or '')
    end)
  end)
end

--- Display a conversion result in a centred floating window.
--- Keymaps: q/<Esc>/<CR> to close, y to copy to clipboard.
---@param title   string
---@param content string
function M.show_float(title, content)
  local lines = vim.split(content, '\n', { plain = true })
  -- trim trailing blank line that atob always appends
  if lines[#lines] == '' then table.remove(lines) end

  local max_col = math.floor(vim.o.columns * 0.8)
  local width = math.min(math.max(40, #title + 4), max_col)
  for _, l in ipairs(lines) do
    width = math.max(width, math.min(#l, max_col))
  end
  local height = math.min(math.max(1, #lines), math.floor(vim.o.lines * 0.6))

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
  vim.bo[buf].bufhidden = 'wipe'

  local win = vim.api.nvim_open_win(buf, true, {
    relative  = 'editor',
    style     = 'minimal',
    border    = 'rounded',
    title     = ' ' .. title .. ' ',
    title_pos = 'center',
    width     = width,
    height    = height,
    row       = math.floor((vim.o.lines - height) / 2),
    col       = math.floor((vim.o.columns - width) / 2),
  })

  local function close()
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
  end

  for _, key in ipairs({ 'q', '<Esc>', '<CR>' }) do
    vim.keymap.set('n', key, close, { buffer = buf, nowait = true, silent = true })
  end

  vim.keymap.set('n', 'y', function()
    vim.fn.setreg('+', table.concat(lines, '\n'))
    vim.notify('[atob] copied to clipboard')
    close()
  end, { buffer = buf, nowait = true, silent = true })
end

return M
