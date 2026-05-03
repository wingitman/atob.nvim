-- atob.nvim — Neovim wrapper for the atob CLI conversion tool
-- https://github.com/wingitman/atob.nvim
--
-- require('atob').setup({
--   binary  = 'atob',        -- path/name of the atob binary
--   keymap  = '<leader>ab',  -- visual mode keymap; set to false to disable
-- })

local M = {}

--- Default configuration
M.config = {
  binary = 'atob',
  keymap = '<leader>ab',
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

  -- Normal-mode command: prompt + pick + show result in float
  vim.api.nvim_create_user_command('Atob', function()
    require('atob.picker').prompt_convert()
  end, { desc = 'atob: convert text via picker' })

  -- Visual-mode keymap: replace selection with converted output
  if M.config.keymap then
    vim.keymap.set('v', M.config.keymap, function()
      require('atob.visual').convert_selection()
    end, { desc = 'atob: convert visual selection', silent = true })
  end
end

return M
