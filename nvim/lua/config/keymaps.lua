-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

local wk = require('which-key')
wk.add({
  { '<leader>p', group = 'Project management' },
})

vim.keymap.set('n', '<leader>ps', vim.cmd.ProjectRoot, { desc = 'Set project root' })

-- Copilot Keymaps

vim.keymap.set('n', '<leader>ac', ':CopilotChatModels<CR>', { desc = 'Chat Models' })

-- Developer
vim.opt.completeopt = { 'menuone', 'noselect', 'popup' }

-- vim.api.nvim_create_autocmd('LspAttach', {
--   callback = function(args)
--     local bufnr = args.buf
--     local client = vim.lsp.get_client_by_id(args.data.client_id)
--     -- Enable LSP autocompletion (if not already default)
--     if vim.lsp.completion and vim.lsp.completion.enable then
--       vim.lsp.completion.enable(true, client.id, bufnr, { autotrigger = true })
--     end
--     -- Set <C-Space> to trigger LSP completion in insert mode
--     vim.keymap.set('i', '<C-Space>', function()
--       if vim.lsp.completion and vim.lsp.completion.get then
--         vim.lsp.completion.get()
--       end
--     end, { buffer = bufnr, desc = 'trigger LSP autocompletion' })
--   end,
-- })
-- vim.keymap.set('n', '<c-space>', vim.lsp.completion.get, { desc = 'Autocomplete' })

-- Navbuddy
