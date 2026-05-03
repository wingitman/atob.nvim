-- atob.nvim — auto-loaded plugin entry point
-- This file is loaded automatically by Neovim's plugin system.
-- Call require('atob').setup() in your init.lua to configure and activate.
--
-- If you are using a plugin manager with lazy-loading, the setup call is enough;
-- you do not need to load this file manually.

-- Guard: only run once
if vim.g.loaded_atob then return end
vim.g.loaded_atob = true

-- Provide a default :Atob command even before setup() is called, so users
-- who forget to call setup() still get a helpful message.
vim.api.nvim_create_user_command('Atob', function()
  vim.notify(
    "[atob] Please call require('atob').setup() in your init.lua first.",
    vim.log.levels.WARN
  )
end, { desc = 'atob: convert text (run setup() first)' })
