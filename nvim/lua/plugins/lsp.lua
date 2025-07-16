return {
  -- LSP Configuration & Plugins
  {
    'mason-org/mason-lspconfig.nvim',
    opts = {},
    dependencies = {
      { 'mason-org/mason.nvim', opts = {} },
      'neovim/nvim-lspconfig',
    },
  },
  {
    'neovim/nvim-lspconfig',
    dependencies = {
      -- Automatically install LSPs and formatters
      'mason-org/mason.nvim',
      'mason-org/mason-lspconfig.nvim',
      'WhoIsSethDaniel/mason-tool-installer.nvim',
      { 'j-hui/fidget.nvim', opts = {} },
      -- { "nvimtools/none-ls.nvim" },
    },
    config = function()
      vim.diagnostic.config({
        virtual_text = true,
        signs = true,
        underline = true,
        update_in_insert = false,
        severity_sort = true,
      })
      local signs = { Error = ' ', Warn = ' ', Hint = ' ', Info = ' ' }
      for type, icon in pairs(signs) do
        local hl = 'DiagnosticSign' .. type
        vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = '' })
      end
      local on_attach = function(client, bufnr)
        local nmap = function(keys, func, desc)
          if func then
            if desc then
              desc = 'LSP: ' .. desc
            end
            vim.keymap.set('n', keys, func, { buffer = bufnr, noremap = true, silent = true, desc = desc })
          end
        end
        -- vim.api.nvim_buf_create_user_command(bufnr, 'OrganizeImports', function()
        --   vim.lsp.buf.code_action()
        -- end, { desc = 'Organize Imports' })
        nmap('<leader>ca', vim.lsp.buf.code_action, 'Code Action')
        nmap('<leader>rn', vim.lsp.buf.rename, 'Rename')
        nmap('gd', vim.lsp.buf.definition, 'Go to Definition')
        nmap('gr', vim.lsp.buf.references, 'Go to References')
        nmap('gI', vim.lsp.buf.implementation, 'Go to Implementation')
        nmap('<leader>D', vim.lsp.buf.type_definition, 'Type Definition')
        nmap('K', vim.lsp.buf.hover, 'Hover')
        nmap('<C-k>', vim.lsp.buf.signature_help, 'Signature Help')
        nmap('<leader>cd', vim.lsp.buf.document_symbol, 'Document Symbols')
        -- nmap('<leader>co', vim.lsp.buf.organizeImports, 'Organize Imports')
      end
      require('lspconfig').lua_ls.setup({
        on_attach = on_attach,
        settings = {
          Lua = {
            runtime = { version = 'LuaJIT' },
            diagnostics = { globals = { 'vim' } },
            workspace = {
              library = vim.api.nvim_get_runtime_file('', true),
              checkThirdParty = false,
            },
            telemetry = { enable = false },
          },
        },
      })
      local capabilities = require('cmp_nvim_lsp').default_capabilities()
      local ensure_installed = require('helper.tool-installer-config').ensure_installed

      require('mason-lspconfig').setup({
        ensure_installed = ensure_installed.lsp,
      })

      local lspconfig = require('lspconfig')
      -- local registry = require('mason-registry')
      -- for k, v in pairs(registry.get_installed_packages()) do
      --   if v['spec']['neovim'] ~= nil then
      --     local server_name = v['spec']['neovim']['lspconfig']
      --     if lspconfig[server_name] then
      --       lspconfig[server_name].setup({
      --         on_attach = on_attach,
      --         capabilities = capabilities,
      --       })
      --     end
      --   end
      -- end

      for _, server_name in ipairs(ensure_installed.lsp) do
        if lspconfig[server_name] and server_name ~= 'lua_ls' then
          -- print('Setting up LSP server: ' .. server_name)
          lspconfig[server_name].setup({
            on_attach = on_attach,
            capabilities = capabilities,
          })
        end
      end
      -- Extra explicit LSP setups required by tool-installer-config.lua
      -- if lspconfig['astro'] then
      --   lspconfig['astro'].setup({ on_attach = on_attach, capabilities = capabilities })
      -- end
      -- if lspconfig['copilot'] then
      --   lspconfig['copilot'].setup({ on_attach = on_attach, capabilities = capabilities })
      -- end
      -- if lspconfig['docker_compose_language_service'] then
      --   lspconfig['docker_compose_language_service'].setup({ on_attach = on_attach, capabilities = capabilities })
      -- end
      -- if lspconfig['dockerfile_language_server'] then
      --   lspconfig['dockerfile_language_server'].setup({ on_attach = on_attach, capabilities = capabilities })
      -- end
      -- if lspconfig['cucumber_language_server'] then
      --   lspconfig['cucumber_language_server'].setup({ on_attach = on_attach, capabilities = capabilities })
      -- end
      -- if lspconfig['vtsls'] then
      --   lspconfig['vtsls'].setup({ on_attach = on_attach, capabilities = capabilities })
      -- end
      -- if lspconfig['ruby_ls'] then
      --   lspconfig['ruby_ls'].setup({ on_attach = on_attach, capabilities = capabilities })
      -- end

      if lspconfig['omnisharp'] then
        lspconfig['omnisharp'].setup({
          on_attach = vim.lsp.on_attach,
          capabilities = vim.lsp.capabilities,
          cmd = {
            'dotnet',
            vim.fn.stdpath('data') .. '/mason/packages/omnisharp/OmniSharp.dll',
          },
          settings = {
            FormattingOptions = {
              EnableEditorConfigSupport = false,
              OrganizeImports = true,
            },
            Sdk = {
              IncludePrereleases = true,
            },
          },
        })
      end

      -- TODO: Can I really remove this? if not, how can I get null-ls back?
      local null_ls = require('null-ls')
      local formatting = null_ls.builtins.formatting
      local diagnostics = null_ls.builtins.diagnostics
      null_ls.setup({
        sources = {
          formatting.prettier.with({
            filetypes = { 'html', 'json', 'yaml', 'markdown', 'javascript', 'typescript', 'css', 'scss' },
          }),
          formatting.stylua,
          formatting.black,
          formatting.isort,
          formatting.shfmt,
          formatting.mdformat,
          -- formatting.reformat_gherkin,
          formatting.csharpier,
          -- diagnostics.eslint,
          -- diagnostics.shellcheck,
          diagnostics.markdownlint,
          -- diagnostics.ast_grep,
        },
      })
    end,
  },
}
