return {
  -- Python language server and diagnostics
  {
    'neovim/nvim-lspconfig',
    opts = {
      servers = {
        pyright = {
          settings = {
            python = {
              analysis = {
                autoImportCompletions = true,
                typeCheckingMode = 'basic',
                diagnosticMode = 'workspace',
              },
            },
          },
        },
      },
    },
  },

  -- Ruff integration (linter + formatter)
  {
    'stevearc/conform.nvim',
    opts = {
      formatters_by_ft = {
        python = { 'ruff_format' },
      },
      formatters = {
        ruff_format = {
          command = 'ruff',
          args = { 'format', '--stdin-filename', '$FILENAME' },
          stdin = true,
        },
      },
    },
  },

  -- Ruff linting via none-ls (nvim-lint alternative)
  {
    'nvimtools/none-ls.nvim',
    dependencies = {
      'nvim-lua/plenary.nvim',
    },
    config = function()
      local null_ls = require('null-ls')

      null_ls.setup({
        sources = {
          -- Ruff linting
          null_ls.builtins.diagnostics.ruff.with({
            extra_args = { '--select', 'E,W,F,I' }, -- Enable specific rules
          }),

          -- MyPy type checking
          null_ls.builtins.diagnostics.mypy.with({
            extra_args = {
              '--follow-imports=silent',
              '--ignore-missing-imports',
              '--no-implicit-optional',
            },
          }),

          -- Bandit security scanning
          null_ls.builtins.diagnostics.bandit.with({
            extra_args = { '-ll' }, -- Only report medium and high severity
          }),

          -- Code formatting with Ruff
          null_ls.builtins.formatting.ruff.with({
            extra_args = { '--line-length', '88' },
          }),

          -- Additional imports sorting
          null_ls.builtins.formatting.isort,
        },
        -- Update diagnostics on save
        on_attach = function(client, bufnr)
          if client.supports_method('textDocument/formatting') then
            vim.api.nvim_create_autocmd('BufWritePre', {
              group = vim.api.nvim_create_augroup('Format', { clear = true }),
              buffer = bufnr,
              callback = function()
                vim.lsp.buf.format({ async = false })
              end,
            })
          end
        end,
      })

      -- Keybindings for Python linting/diagnostics
      local wk = require('which-key')
      wk.add({
        { '<leader>p', group = 'Python' },
        { '<leader>pl', '<cmd>lua vim.diagnostic.open_float()<CR>', desc = 'Show line diagnostics' },
        { '<leader>pd', '<cmd>lua vim.lsp.buf.definition()<CR>', desc = 'Go to definition' },
        { '<leader>ph', '<cmd>lua vim.lsp.buf.hover()<CR>', desc = 'Hover documentation' },
        { '<leader>pr', '<cmd>lua vim.lsp.buf.references()<CR>', desc = 'Find references' },
        { '<leader>pf', '<cmd>lua vim.lsp.buf.format()<CR>', desc = 'Format buffer' },
      })
    end,
  },

  -- Ensure Python tools are installed via mason
  {
    'WhoIsSethDaniel/mason-tool-installer.nvim',
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, {
        'ruff',
        'mypy',
        'bandit',
        'pyright',
        'black',
        'isort',
        'debugpy',
      })
      return opts
    end,
  },
}
