-- Centralized comprehensive list of tools for mason-tool-installer. Update as needed!
return {
  ensure_installed = {
    -- LSP Server Names
    lsp = {
      'marksman',
      'ast_grep',
      'ts_ls',
      'html',
      'lua_ls',
      'cssls',
      'tailwindcss',
      'jsonls',
      'yamlls',
      'vimls',
      'pyright',
      'dockerls',
      'ruff',
      'stylelint_lsp',
      'gradle_ls',
      -- 'cucumber_language_server',
      -- 'graphql',
      'eslint',
      -- 'kotlin_language_server',
      -- 'vtsls',
      'omnisharp',
      'lemminx', -- XML LS
      'volar',
      'pylsp',
      -- 'astro',
      'docker_compose_language_service',
    },
    -- LSP Servers
    -- lsp = {
    --   'ast-grep',
    --   'typescript-language-server',
    --   'html-lsp',
    --   'lua-language-server',
    --   'css-lsp',
    --   'tailwindcss-language-server',
    --   'json-lsp',
    --   'yaml-language-server',
    --   'vim-language-server',
    --   'bash-language-server',
    --   'dockerfile-language-server',
    --   'docker-compose-language-service',
    --   'stylelint-lsp',
    --   'astro-language-server',
    --   'gradle-language-server',
    --   'copilot-language-server',
    --   'cucumber-language-server',
    --   'graphql-language-service-cli',
    --   'vtsls',
    --   'stylelint-lsp',
    --   'eslint-lsp',
    --   -- Python alternative LSP
    --   'python-lsp-server',
    --   'pyright',
    --   'ruff',
    --   -- Kotlin
    --   'kotlin-language-server',
    --   -- Markdown
    --   'marksman',
    --   -- Misc
    --   'llm-ls',
    --   'lemminx',
    --   'vue-language-server',
    -- },
    -- Formatters, Linters, DAP, Extras
    other = {
      -- Formatters
      'prettierd',
      'stylua',
      'shfmt',
      'isort',
      'black',
      'reformat-gherkin',
      'mdformat',
      -- 'prettier',
      -- Linters
      -- 'ansible-lint',
      'csharpier',
      'hadolint', -- Docker lint
      'eslint_d',
      'shellcheck',
      'flake8',
      'jsonlint',
      'yamllint',
      'stylelint',
      'markman-toc2',
      'markdownlint-cli2',
      -- 'tflint', -- terraform linter
      'isort',
      -- DAP / Debuggers
      'chrome-debug-adapter',
      'debugpy',
      'bash-debug-adapter',
      'netcoredbg',
      -- Extra tools
      -- 'ast-grep',
      'yq',
      'jq',
    },
  },
}
