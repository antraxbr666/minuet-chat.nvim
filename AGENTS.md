# AGENTS.md

## Overview

Neovim plugin (pure Lua) providing AI chat for any OpenAI-compatible API (OpenAI, DeepSeek, Ollama, etc.). Requires Neovim 0.10.0+, curl 8.0.0+, plenary.nvim.

## Commands

```bash
# Run tests (headless Neovim + plenary test harness)
make test

# Format check
stylua --check .
```

`make test` runs `nvim --headless --clean -u ./scripts/test.lua`, which clones plenary.nvim into `.dependencies/` on first run, then executes all `tests/*_spec.lua` files via plenary's busted-style harness.

## Project layout

```
plugin/MinuetChat.lua    — Neovim plugin entry: commands, highlights, autocmds
lua/MinuetChat/
  init.lua                — Main module: setup(), ask(), open/close/toggle, save/load
  client.lua              — OpenAI-compatible API client (headers, streaming, tool calls)
  config.lua              — Default configuration schema
  config/                 — Sub-configs: functions, mappings, prompts, providers
  constants.lua           — Shared constants (roles, etc.)
  completion.lua          — Completion source
  functions.lua           — Built-in functions/tools exposed to the LLM
  prompts.lua             — Built-in prompt definitions
  resources.lua           — Resource handling
  select.lua              — Selection strategies (visual, buffer, diagnostics, git diff)
  tiktoken.lua            — Token counting via native tiktoken lib
  health.lua              — :checkhealth integration
  notify.lua              — Notification utilities
  instructions/           — System prompt templates injected into LLM conversations (not agent guidance)
  ui/                     — Chat window, overlay, spinner
  utils.lua               — General utilities
  utils/                  — Utility modules: class, curl, diff, files, orderedmap, stringbuffer
queries/                  — Treesitter queries for minuet-chat filetype
tests/                    — Plenary busted-style specs (*_spec.lua)
scripts/
  test.lua                — Test runner bootstrap (sets up plenary)
  minimal.lua             — Minimal reproduction config
doc/MinuetChat.txt       — Vimdoc generated from README by panvimdoc (`make docs`); do NOT edit by hand
```

## Style and formatting

- **Lua formatter:** StyLua — 2-space indent, 120 column width, single quotes preferred, Unix line endings. Config in `.stylua.toml`.
- **Formatting:** run `stylua --check .` before committing. LazyVim formats Lua with StyLua on save using `.stylua.toml`.
- **No linter** (no luacheck/selene configured).
- Type annotations use EmmyLua/LuaCATS `---@class`, `---@param`, `---@return` style.

## Testing

- Framework: plenary.nvim busted-style (`describe`, `it`, `before_each`, `after_each`, `assert`).
- Test files live in `tests/` and must be named `*_spec.lua`.
- Tests are unit-level (class, diff, utils, orderedmap, stringbuffer, functions, init). No integration tests requiring a real API key.

## Docs and releases

- No CI is configured yet. Run `make test` and `stylua --check .` locally before pushing.
- Regenerate `doc/MinuetChat.txt` with `make docs` after changing `README.md` (needs `pandoc`).
- Record user-facing changes in `CHANGELOG.md`. Versions are git tags.

## Key gotchas

- The module is loaded as `require('MinuetChat')` (capital C's) — this matches the `lua/MinuetChat/` directory name. Case matters.
- `init.lua` uses lazy self-initialization via `__index` metamethod — accessing any field triggers `setup()` if not already called.
- `.dependencies/` is gitignored and auto-populated by the test runner (plenary clone).
- `build/` is gitignored and holds downloaded tiktoken native libraries.
