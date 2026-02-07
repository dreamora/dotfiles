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

  -- Diagnostics via none-ls
  {
    'nvimtools/none-ls.nvim',
    dependencies = {
      'nvim-lua/plenary.nvim',
      'nvimtools/none-ls-extras.nvim',
    },
    opts = function(_, opts)
      local null_ls = require('null-ls')
      opts.sources = opts.sources or {}

      vim.list_extend(opts.sources, {
        -- Ruff linting (moved to none-ls-extras)
        require('none-ls.diagnostics.ruff').with({
          extra_args = { '--select', 'E,W,F,I' },
        }),

        -- MyPy type checking
        null_ls.builtins.diagnostics.mypy.with({
          extra_args = {
            '--follow-imports=silent',
            '--ignore-missing-imports',
            '--no-implicit-optional',
          },
        }),

      })
      return opts
    end,
  },

  -- Keybindings for Python linting/diagnostics
  {
    'folke/which-key.nvim',
    config = function()
      local wk = require('which-key')
      wk.add({
        { '<leader>p', group = 'Python' },
        { '<leader>pl', '<cmd>lua vim.diagnostic.open_float()<CR>', desc = 'Show line diagnostics' },
        { '<leader>pL', '<cmd>lua require("lint").try_lint()<CR>', desc = 'Run linters' },
        { '<leader>pd', '<cmd>lua vim.lsp.buf.definition()<CR>', desc = 'Go to definition' },
        { '<leader>ph', '<cmd>lua vim.lsp.buf.hover()<CR>', desc = 'Hover documentation' },
        { '<leader>pr', '<cmd>lua vim.lsp.buf.references()<CR>', desc = 'Find references' },
        { '<leader>pf', '<cmd>lua vim.lsp.buf.format()<CR>', desc = 'Format buffer' },
      })
    end
  },

  -- Python linting via nvim-lint (LazyVim default)
  {
    'mfussenegger/nvim-lint',
    opts = function(_, opts)
      opts.linters_by_ft = opts.linters_by_ft or {}
      local python_linters = opts.linters_by_ft.python or {}

      for _, linter in ipairs({ 'ruff', 'mypy', 'bandit' }) do
        if not vim.tbl_contains(python_linters, linter) then
          table.insert(python_linters, linter)
        end
      end

      opts.linters_by_ft.python = python_linters
      return opts
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
