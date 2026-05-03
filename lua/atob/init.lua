-- atob.nvim — Neovim wrapper for the atob CLI conversion tool
-- https://github.com/wingitman/atob.nvim
--
-- require('atob').setup({
--   binary         = 'atob',        -- path/name of the atob binary
--   keymap         = '<leader>ab',  -- visual mode: convert selected text
--   inspect_keymap = '<leader>ai',  -- visual mode: inspect file at selected path
-- })

local M = {}

--- Default configuration
M.config = {
  binary         = 'atob',
  keymap         = '<leader>ab',
  inspect_keymap = '<leader>ai',
}

--- Merge user config over defaults and wire up commands/keymaps.
---@param opts? table
function M.setup(opts)
  M.config = vim.tbl_deep_extend('force', M.config, opts or {})

  -- Verify binary is reachable
  if vim.fn.executable(M.config.binary) == 0 then
    vim.notify(
      string.format(
        '[atob] binary %q not found in PATH. Set binary= in setup() or install atob.',
        M.config.binary
      ),
      vim.log.levels.WARN
    )
  end

  -- :Atob — text conversion picker (normal mode: prompt for input)
  vim.api.nvim_create_user_command('Atob', function()
    require('atob.picker').prompt_convert()
  end, { desc = 'atob: convert text via picker' })

  -- :AtobInspect [operation] — inspect the current buffer's file
  -- operation is optional: inspect | hexdump | strings
  -- With no argument an operation picker is shown.
  vim.api.nvim_create_user_command('AtobInspect', function(cmd_opts)
    local op = vim.trim(cmd_opts.args)
    require('atob.binary').inspect_current_buffer(op ~= '' and op or nil)
  end, {
    nargs    = '?',
    complete = function() return { 'inspect', 'hexdump', 'strings' } end,
    desc     = 'atob: inspect current file (inspect / hexdump / strings)',
  })

  -- Visual keymap: convert selected text in-place
  if M.config.keymap then
    vim.keymap.set('v', M.config.keymap, function()
      require('atob.visual').convert_selection()
    end, { desc = 'atob: convert visual selection', silent = true })
  end

  -- Visual keymap: treat selected text as a file path and inspect it
  if M.config.inspect_keymap then
    vim.keymap.set('v', M.config.inspect_keymap, function()
      require('atob.binary').inspect_path_from_selection()
    end, { desc = 'atob: inspect file at selected path', silent = true })
  end
end

return M
