# Contributing to minuet-chat.nvim

## Where do I go from here?

If you've noticed a bug or have a feature request, make sure to check our
[Issues](https://github.com/antraxbr666/minuet-chat.nvim/issues) page to see
if someone else in the community has already created a ticket. If not, go ahead
and make one!

## Fork & create a branch

If this is something you think you can fix, then fork minuet-chat.nvim and
create a branch with a descriptive name.

A good branch name would be (where issue #325 is the ticket you're working on):

```bash
git checkout -b 325-add-japanese-localization
```

Make sure to check [Structure](#structure) first to understand the project structure.

## Implement your fix or feature

At this point, you're ready to make your changes! Feel free to ask for help;
everyone is a beginner at first. Open an [issue](https://github.com/antraxbr666/minuet-chat.nvim/issues) if you get stuck.

## Make a Pull Request

At this point, you should switch back to your main branch and make sure it's
up to date with minuet-chat.nvim's main branch:

```bash
git remote add upstream git@github.com:antraxbr666/minuet-chat.nvim.git
git checkout main
git pull upstream main
```

Then update your feature branch from your local copy of master and push your branch to your GitHub account:

```bash
git checkout 325-add-japanese-localization
git rebase main
git push --set-upstream origin 325-add-japanese-localization
```

Go to the minuet-chat.nvim in your GitHub account, select your branch, and click the "Pull Request" button.

## Structure

### Core

- [init.lua](/lua/MinuetChat/init.lua): Main module. Plugin initialization
  (`setup()`), chat lifecycle (`ask()`, `open()`, `close()`, `toggle()`,
  `reset()`), save/load, and sticky prompt processing.

- [client.lua](/lua/MinuetChat/client.lua): OpenAI-compatible API client.
  Handles request headers, model listing, streaming requests, and tool call execution.

- [config.lua](/lua/MinuetChat/config.lua): Default configuration schema.

- [config/](/lua/MinuetChat/config/): Sub-configs for
  [functions](/lua/MinuetChat/config/functions.lua),
  [mappings](/lua/MinuetChat/config/mappings.lua),
  [prompts](/lua/MinuetChat/config/prompts.lua), and
  [providers](/lua/MinuetChat/config/providers.lua).

- [constants.lua](/lua/MinuetChat/constants.lua): Shared constants (plugin
  name, roles).

### Chat and UI

- [ui/chat.lua](/lua/MinuetChat/ui/chat.lua): Chat window management.
  Creating, appending to, clearing, opening, closing, and focusing the chat
  window. Handles fold expressions and section parsing.

- [ui/overlay.lua](/lua/MinuetChat/ui/overlay.lua): Overlay buffer used for
  displaying diff previews and other transient content.

- [ui/spinner.lua](/lua/MinuetChat/ui/spinner.lua): Loading spinner indicator
  for the chat window.

### Features

- [prompts.lua](/lua/MinuetChat/prompts.lua): Prompt resolution, custom
  instruction loading, system prompt building, and sticky/resource/tool
  parsing from user input.

- [functions.lua](/lua/MinuetChat/functions.lua): Built-in functions/tools
  exposed to the LLM (e.g., file editing, searching).

- [resources.lua](/lua/MinuetChat/resources.lua): Resource handling for file
  and URL content retrieval with caching.

- [completion.lua](/lua/MinuetChat/completion.lua): Completion source for the
  chat window (`@tools`, `/prompts`, `#resources`, `$models`).

- [select.lua](/lua/MinuetChat/select.lua): Selection strategies for providing
  context (visual selection, buffer, diagnostics, git diff, etc.).

- [tiktoken.lua](/lua/MinuetChat/tiktoken.lua): Token counting via native
  tiktoken library.

- [instructions/](/lua/MinuetChat/instructions/): System prompt templates
  injected into LLM conversations (edit formats, tool use instructions, custom
  instructions wrapper).

### Utilities

- [utils.lua](/lua/MinuetChat/utils.lua): General utility functions.

- [utils/](/lua/MinuetChat/utils/): Utility modules
  [class.lua](/lua/MinuetChat/utils/class.lua) (OOP helper),
  [curl.lua](/lua/MinuetChat/utils/curl.lua) (HTTP requests),
  [diff.lua](/lua/MinuetChat/utils/diff.lua) (unified diff parsing and application),
  [files.lua](/lua/MinuetChat/utils/files.lua) (file I/O and filetype detection),
  [notify.lua](/lua/MinuetChat/utils/notify.lua) (pub/sub notification system for status and message events)
  [orderedmap.lua](/lua/MinuetChat/utils/orderedmap.lua) (insertion-ordered map),
  [stringbuffer.lua](/lua/MinuetChat/utils/stringbuffer.lua) (efficient string concatenation).

### Other

- [health.lua](/lua/MinuetChat/health.lua): `:checkhealth` integration.
  Verifies commands, libraries, and Treesitter parsers.
