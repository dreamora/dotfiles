# Style & Conventions

## General
- Line endings: LF, Encoding: UTF-8, Indent: 2 spaces, Max line: 150, Trim trailing whitespace, Final newline

## Shell Scripts
- Shebang: `#!/usr/bin/env bash`
- Source helpers at top: `source ./lib_sh/echos.sh` etc.
- Use colorized output: bot, running, ok, action, warn, error
- Use require_* helpers for idempotent installs
- Error handling: check $? or ${PIPESTATUS[0]}
- Files: snake_case.sh, Functions: snake_case, Variables: UPPER_CASE exports, lower_case locals

## Lua (stylua.toml)
- Indent: 2 spaces, Line width: 120, Quotes: single (forced), Parentheses: always

## Commit Messages
- Conventional commits format
