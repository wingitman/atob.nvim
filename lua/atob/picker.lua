-- atob.nvim picker — vim.ui.select-based converter chooser
local M = {}
local core = require('atob.core')

--- Format a converter entry for display in the picker.
---@param c table ConverterInfo from atob list --json
---@return string
local function format_item(c)
  local suffix = c.file_based and ' [file]' or ''
  return string.format('%-30s %s%s', c.name, c.description, suffix)
end

--- Open a picker, let the user choose a converter, then either:
---   • For text converters: prompt for input → show result in a floating window.
---   • For file converters: prompt for input/output paths → run conversion.
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
      -- File-based: ask for paths
      vim.ui.input({ prompt = 'Input file path: ' }, function(input_path)
        if not input_path or input_path == '' then return end
        vim.ui.input({ prompt = 'Output file path: ' }, function(output_path)
          if not output_path or output_path == '' then return end
          local _, ferr = core.convert_file(choice.name, input_path, output_path)
          if ferr then
            vim.notify('[atob] ' .. ferr, vim.log.levels.ERROR)
          else
            vim.notify(string.format('[atob] %s → %s (done)', input_path, output_path))
          end
        end)
      end)
      return
    end

    -- Text-based: prompt for input
    vim.ui.input({ prompt = string.format('Input for %s: ', choice.name) }, function(input)
      if input == nil then return end
      local output, cerr = core.convert(choice.name, input)
      if cerr then
        vim.notify('[atob] ' .. cerr, vim.log.levels.ERROR)
        return
      end
      M.show_float(choice.name, output or '')
    end)
  end)
end

--- Display result in a centred floating window.
---@param title string
---@param content string
function M.show_float(title, content)
  local lines = vim.split(content, '\n', { plain = true })
  -- trim trailing empty line added by atob
  if lines[#lines] == '' then table.remove(lines) end

  local width = math.min(math.max(40, #title + 4), math.floor(vim.o.columns * 0.8))
  for _, l in ipairs(lines) do
    width = math.max(width, math.min(#l, math.floor(vim.o.columns * 0.8)))
  end
  local height = math.min(#lines + 2, math.floor(vim.o.lines * 0.6))

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
  vim.bo[buf].bufhidden = 'wipe'

  local win = vim.api.nvim_open_win(buf, true, {
    relative = 'editor',
    style    = 'minimal',
    border   = 'rounded',
    title    = ' ' .. title .. ' ',
    title_pos = 'center',
    width    = width,
    height   = height,
    row      = math.floor((vim.o.lines - height) / 2),
    col      = math.floor((vim.o.columns - width) / 2),
  })

  -- q or <Esc> closes the float
  for _, key in ipairs({ 'q', '<Esc>', '<CR>' }) do
    vim.keymap.set('n', key, function()
      if vim.api.nvim_win_is_valid(win) then
        vim.api.nvim_win_close(win, true)
      end
    end, { buffer = buf, nowait = true, silent = true })
  end

  -- y copies the whole content to the clipboard and closes
  vim.keymap.set('n', 'y', function()
    vim.fn.setreg('+', table.concat(lines, '\n'))
    vim.notify('[atob] copied to clipboard')
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
  end, { buffer = buf, nowait = true, silent = true })
end

return M
