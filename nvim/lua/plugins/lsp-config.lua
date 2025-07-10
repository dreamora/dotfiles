-- This file now only contains the configuration for mason-tool-installer

return {
  {
    'WhoIsSethDaniel/mason-tool-installer.nvim',
    config = function()
      local ensure_installed_config = require('helper.tool-installer-config').ensure_installed
      local combined_tools = {}
      for _, tool in ipairs(ensure_installed_config.lsp) do
        table.insert(combined_tools, tool)
      end
      for _, tool in ipairs(ensure_installed_config.other) do
        table.insert(combined_tools, tool)
      end

      require('mason-tool-installer').setup({
        ensure_installed = combined_tools,
        run_on_start = true,
        start_delay = 3000,
        debounce_hours = 5,
      })

      vim.api.nvim_create_autocmd('User', {
        pattern = 'MasonToolsStartingInstall',
        callback = function()
          vim.schedule(function()
            print('mason-tool-installer is starting')
          end)
        end,
      })
      vim.api.nvim_create_autocmd('User', {
        pattern = 'MasonToolsUpdateCompleted',
        callback = function(e)
          vim.schedule(function()
            print('mason-tool-installer updated:\n' .. vim.inspect(e.data))
          end)
        end,
      })
    end,
  },
}
