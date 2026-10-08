local constants = require('MinuetChat.constants')

--- Prepare input for Chat Completions API
---@param inputs MinuetChat.client.Message[]
---@param opts MinuetChat.config.providers.Options
---@return table
local function prepare_chat_input(inputs, opts)
  local is_o1 = vim.startswith(opts.model.id, 'o1')
  local is_codex = opts.model.id:find('codex') ~= nil

  inputs = vim.tbl_map(function(input)
    local output = {
      role = (is_o1 and input.role == constants.ROLE.SYSTEM) and constants.ROLE.USER or input.role,
      content = input.content,
    }

    if input.tool_call_id then
      output.tool_call_id = input.tool_call_id
    end

    if input.tool_calls then
      output.tool_calls = vim.tbl_map(function(tool_call)
        return {
          id = tool_call.id,
          type = 'function',
          ['function'] = {
            name = tool_call.name,
            arguments = tool_call.arguments or nil,
          },
        }
      end, input.tool_calls)
    end

    return output
  end, inputs)

  local out = {
    messages = inputs,
    model = opts.model.id,
    stream = opts.model.streaming or false,
  }

  if opts.tools and opts.model.tools then
    out.tools = vim.tbl_map(function(tool)
      return {
        type = 'function',
        ['function'] = {
          name = tool.name,
          description = tool.description,
          parameters = tool.schema,
        },
      }
    end, opts.tools)
  end

  if not is_o1 and not is_codex then
    out.n = 1
    out.top_p = 1
    out.temperature = opts.temperature
  end

  if opts.model.max_output_tokens then
    out.max_tokens = opts.model.max_output_tokens
  end

  return out
end

--- Parse Chat Completions API output (both streaming and non-streaming)
---@param output table Raw API response
---@return MinuetChat.config.providers.Output
local function prepare_chat_output(output)
  local tool_calls = {}

  local choice
  if output.choices and #output.choices > 0 then
    for _, c in ipairs(output.choices) do
      local message = c.message or c.delta
      if message and message.tool_calls then
        for i, tool_call in ipairs(message.tool_calls) do
          local fn = tool_call['function']
          if fn then
            table.insert(tool_calls, {
              id = tool_call.id,
              index = tool_call.index or i,
              name = fn.name,
              arguments = fn.arguments or '',
            })
          end
        end
      end
    end
    choice = output.choices[1]
  else
    choice = output
  end

  local message = choice.message or choice.delta
  local content = message and message.content
  local reasoning = message and (message.reasoning or message.reasoning_content)
  local usage = choice.usage and choice.usage.total_tokens or output.usage and output.usage.total_tokens
  local finish_reason = choice.finish_reason or choice.done_reason or output.finish_reason or output.done_reason
  local model = choice.model or output.model

  return {
    content = content,
    reasoning = reasoning,
    finish_reason = finish_reason,
    total_tokens = usage,
    tool_calls = tool_calls,
    model = model,
  }
end

---@class MinuetChat.config.providers.Options
---@field model MinuetChat.client.Model
---@field temperature number?
---@field tools table<MinuetChat.client.Tool>?

---@class MinuetChat.config.providers.Output
---@field content string
---@field reasoning string?
---@field finish_reason string?
---@field total_tokens number?
---@field tool_calls table<MinuetChat.client.ToolCall>
---@field model string?

---@class MinuetChat.config.providers.Provider
---@field disabled nil|boolean
---@field get_headers nil|fun():table<string, string>,number?
---@field get_info nil|fun(headers:table):string[]
---@field get_models nil|fun(headers:table):table<MinuetChat.client.Model>
---@field resolve_model nil|fun(headers:table, model: string):string,table?
---@field prepare_input nil|fun(inputs:MinuetChat.client.Message[], opts:MinuetChat.config.providers.Options):table,table?
---@field prepare_output nil|fun(output:table, opts:MinuetChat.config.providers.Options):MinuetChat.config.providers.Output
---@field get_url nil|fun(opts:MinuetChat.config.providers.Options):string

---@type table<string, MinuetChat.config.providers.Provider>
local M = {}

M.openai = {
  get_headers = function(opts)
    local api_key = opts and opts.api_key or M.openai.api_key
    if not api_key or api_key == '' then
      error('OpenAI API key is not configured. Set providers.openai.api_key in your config.')
    end
    return {
      ['Authorization'] = 'Bearer ' .. api_key,
    }
  end,

  get_models = function(opts)
    local models = (opts and opts.models) or M.openai.models or {}
    return vim.tbl_map(function(model)
      return vim.tbl_extend('force', model, {
        provider = 'openai',
      })
    end, models)
  end,

  prepare_input = prepare_chat_input,
  prepare_output = prepare_chat_output,

  get_url = function(opts)
    local base_url = (opts and opts.base_url) or M.openai.base_url or 'https://api.openai.com/v1'
    return base_url .. '/chat/completions'
  end,
}

return M
