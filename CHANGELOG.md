# Changelog

All notable changes to minuet-chat.nvim are documented here.

## Unreleased

### Features

- Works with any OpenAI-compatible API (OpenAI, DeepSeek, Ollama, etc.) through the built-in `openai` provider, configured with `api_key`, `base_url` and `models`.
- Default model is now `gpt-6-luna`.

### Bug Fixes

- Restore async `schedule_main` and redact auth headers in logs.
- The assistant now identifies itself as "Minuet" instead of "Copilot".

### Documentation

- Badges, links and examples now point to this repository.
- New LazyVim setup section with a which-key group for `<leader>a`.
- Updated OpenAI and DeepSeek provider examples to current models.
- Removed the migration guide and contributor list inherited from the original project.

### Chores

- Removed tooling inherited from the original project that this fork does not use: pre-commit, Prettier, cspell, Renovate, EditorConfig, EmmyLua config, the docsify site and `version.txt`.
- Trimmed `.gitignore` to the paths the plugin actually creates.

## Before the fork

minuet-chat.nvim started from [CopilotChat.nvim v4.7.4](https://github.com/CopilotC-Nvim/CopilotChat.nvim/releases/tag/v4.7.4). For earlier history, see the [CopilotChat.nvim changelog](https://github.com/CopilotC-Nvim/CopilotChat.nvim/blob/main/CHANGELOG.md).
