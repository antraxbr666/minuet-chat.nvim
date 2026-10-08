if vim.g.loaded_minuet_chat then
  return
end

local min_version = '0.10.0'
if vim.fn.has('nvim-' .. min_version) ~= 1 then
  vim.notify_once(('minuet-chat.nvim requires Neovim >= %s'):format(min_version), vim.log.levels.ERROR)
  return
end

local group = vim.api.nvim_create_augroup('MinuetChat', {})

-- Setup highlights
local function setup_highlights()
  vim.api.nvim_set_hl(0, 'MinuetChatHeader', { link = '@markup.heading.2.markdown', default = true })
  vim.api.nvim_set_hl(0, 'MinuetChatSeparator', { link = '@punctuation.special.markdown', default = true })
  vim.api.nvim_set_hl(0, 'MinuetChatSelection', { link = 'Visual', default = true })
  vim.api.nvim_set_hl(0, 'MinuetChatStatus', { link = 'DiagnosticHint', default = true })
  vim.api.nvim_set_hl(0, 'MinuetChatHelp', { link = 'DiagnosticInfo', default = true })
  vim.api.nvim_set_hl(0, 'MinuetChatResource', { link = 'Constant', default = true })
  vim.api.nvim_set_hl(0, 'MinuetChatTool', { link = 'Function', default = true })
  vim.api.nvim_set_hl(0, 'MinuetChatPrompt', { link = 'Statement', default = true })
  vim.api.nvim_set_hl(0, 'MinuetChatModel', { link = 'Type', default = true })
  vim.api.nvim_set_hl(0, 'MinuetChatUri', { link = 'Underlined', default = true })

  vim.api.nvim_set_hl(0, 'MinuetChatAnnotation', { link = 'ColorColumn', default = true })
  local fg = vim.api.nvim_get_hl(0, { name = 'MinuetChatStatus', link = false }).fg
  local bg = vim.api.nvim_get_hl(0, { name = 'MinuetChatAnnotation', link = false }).bg
  vim.api.nvim_set_hl(0, 'MinuetChatAnnotationHeader', { fg = fg, bg = bg })
end
vim.api.nvim_create_autocmd('ColorScheme', {
  group = group,
  callback = function()
    setup_highlights()
  end,
})
setup_highlights()

vim.api.nvim_create_autocmd('FileType', {
  pattern = 'minuet-chat',
  group = group,
  callback = function()
    local bufnr = vim.api.nvim_get_current_buf()
    vim.schedule(function()
      -- nvim_get_option_value workaround
      if bufnr ~= vim.api.nvim_get_current_buf() then
        return
      end

      vim.cmd.syntax('match MinuetChatResource "#\\S\\+"')
      vim.cmd.syntax('match MinuetChatTool "@\\S\\+"')
      vim.cmd.syntax('match MinuetChatPrompt "/\\S\\+"')
      vim.cmd.syntax('match MinuetChatModel "\\$\\S\\+"')
      vim.cmd.syntax('match MinuetChatUri "##\\S\\+"')
    end)
  end,
})

-- Setup commands
vim.api.nvim_create_user_command('MinuetChat', function(args)
  local chat = require('MinuetChat')
  local input = args.args
  if input and vim.trim(input) ~= '' then
    chat.ask(input)
  else
    chat.open()
  end
end, {
  nargs = '*',
  force = true,
  range = true,
})
vim.api.nvim_create_user_command('MinuetChatPrompts', function()
  local chat = require('MinuetChat')
  chat.select_prompt()
end, { force = true, range = true })
vim.api.nvim_create_user_command('MinuetChatModels', function()
  local chat = require('MinuetChat')
  chat.select_model()
end, { force = true })
vim.api.nvim_create_user_command('MinuetChatOpen', function()
  local chat = require('MinuetChat')
  chat.open()
end, { force = true })
vim.api.nvim_create_user_command('MinuetChatClose', function()
  local chat = require('MinuetChat')
  chat.close()
end, { force = true })
vim.api.nvim_create_user_command('MinuetChatToggle', function()
  local chat = require('MinuetChat')
  chat.toggle()
end, { force = true })
vim.api.nvim_create_user_command('MinuetChatStop', function()
  local chat = require('MinuetChat')
  chat.stop()
end, { force = true })
vim.api.nvim_create_user_command('MinuetChatReset', function()
  local chat = require('MinuetChat')
  chat.reset()
end, { force = true })

local function complete_load()
  local chat = require('MinuetChat')
  local options = vim.tbl_map(function(file)
    return vim.fn.fnamemodify(file, ':t:r')
  end, vim.fn.glob(chat.config.history_path .. '/*', true, true))

  if not vim.tbl_contains(options, 'default') then
    table.insert(options, 1, 'default')
  end

  return options
end
vim.api.nvim_create_user_command('MinuetChatSave', function(args)
  local chat = require('MinuetChat')
  chat.save(args.args)
end, { nargs = '*', force = true, complete = complete_load })
vim.api.nvim_create_user_command('MinuetChatLoad', function(args)
  local chat = require('MinuetChat')
  chat.load(args.args)
end, { nargs = '*', force = true, complete = complete_load })

-- Store the current directory to window when directory changes
-- I dont think there is a better way to do this that functions
-- with "rooter" plugins, LSP and stuff as vim.fn.getcwd() when
-- i pass window number inside doesnt work
vim.api.nvim_create_autocmd({ 'VimEnter', 'WinEnter', 'DirChanged' }, {
  group = group,
  callback = function()
    vim.w.cchat_cwd = vim.fn.getcwd()
  end,
})

-- Setup treesitter
vim.treesitter.language.register('markdown', 'minuet-chat')

vim.g.loaded_minuet_chat = true
