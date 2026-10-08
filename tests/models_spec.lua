describe('MinuetChat openai provider models', function()
  local providers = require('MinuetChat.config.providers')

  before_each(function()
    providers.openai.api_key = 'test-key'
    providers.openai.base_url = 'https://api.openai.com/v1'
    providers.openai.models = {
      {
        id = 'gpt-4o',
        name = 'GPT-4o',
        max_input_tokens = 128000,
        max_output_tokens = 16384,
        streaming = true,
        tools = true,
      },
      {
        id = 'gpt-4o-mini',
        name = 'GPT-4o mini',
        max_input_tokens = 128000,
        max_output_tokens = 16384,
        streaming = true,
        tools = true,
      },
    }
  end)

  it('returns the configured models with provider set', function()
    local models = providers.openai.get_models({})

    assert.equals(2, #models)
    assert.equals('gpt-4o', models[1].id)
    assert.equals('GPT-4o', models[1].name)
    assert.equals('openai', models[1].provider)
    assert.equals('gpt-4o-mini', models[2].id)
    assert.equals('openai', models[2].provider)
  end)

  it('returns models with correct metadata', function()
    local models = providers.openai.get_models({})

    assert.equals(128000, models[1].max_input_tokens)
    assert.equals(16384, models[1].max_output_tokens)
    assert.is_true(models[1].streaming)
    assert.is_true(models[1].tools)
  end)

  it('returns empty list when no models configured', function()
    providers.openai.models = nil

    local models = providers.openai.get_models({})

    assert.equals(0, #models)
  end)

  it('get_headers returns authorization header with api key', function()
    local headers = providers.openai.get_headers()

    assert.equals('Bearer test-key', headers['Authorization'])
  end)

  it('get_headers throws error when api key is missing', function()
    providers.openai.api_key = nil

    local ok, err = pcall(providers.openai.get_headers)
    assert.is_false(ok)
    assert.truthy(string.find(err, 'API key'))
  end)

  it('get_url returns correct chat completions endpoint', function()
    local url = providers.openai.get_url()

    assert.equals('https://api.openai.com/v1/chat/completions', url)
  end)

  it('get_url uses custom base_url when configured', function()
    providers.openai.base_url = 'http://localhost:11434/v1'

    local url = providers.openai.get_url()

    assert.equals('http://localhost:11434/v1/chat/completions', url)
  end)

  it('prepare_input creates valid chat completions request', function()
    local inputs = {
      { role = 'system', content = 'You are a helpful assistant.' },
      { role = 'user', content = 'Hello!' },
    }
    local opts = {
      model = { id = 'gpt-4o', streaming = true },
      temperature = 0.1,
    }

    local request = providers.openai.prepare_input(inputs, opts)

    assert.equals('gpt-4o', request.model)
    assert.is_true(request.stream)
    assert.equals(0.1, request.temperature)
    assert.equals(2, #request.messages)
    assert.equals('system', request.messages[1].role)
    assert.equals('user', request.messages[2].role)
  end)

  it('prepare_input includes tools when provided', function()
    local inputs = {
      { role = 'user', content = 'What is the weather?' },
    }
    local opts = {
      model = { id = 'gpt-4o', streaming = true, tools = true },
      temperature = 0.1,
      tools = {
        {
          name = 'get_weather',
          description = 'Get the weather',
          schema = { type = 'object', properties = {} },
        },
      },
    }

    local request = providers.openai.prepare_input(inputs, opts)

    assert.is_not_nil(request.tools)
    assert.equals(1, #request.tools)
    assert.equals('get_weather', request.tools[1]['function'].name)
  end)

  it('prepare_output parses non-streaming response correctly', function()
    local output = {
      choices = {
        {
          message = {
            role = 'assistant',
            content = 'Hello! How can I help you?',
          },
          finish_reason = 'stop',
        },
      },
      usage = {
        total_tokens = 15,
      },
    }

    local result = providers.openai.prepare_output(output, {})

    assert.equals('Hello! How can I help you?', result.content)
    assert.equals('stop', result.finish_reason)
    assert.equals(15, result.total_tokens)
  end)

  it('prepare_output parses streaming response correctly', function()
    local output = {
      choices = {
        {
          delta = {
            content = 'Hello',
          },
        },
      },
    }

    local result = providers.openai.prepare_output(output, {})

    assert.equals('Hello', result.content)
  end)

  it('prepare_output parses tool calls correctly', function()
    local output = {
      choices = {
        {
          message = {
            role = 'assistant',
            content = '',
            tool_calls = {
              {
                id = 'call_123',
                type = 'function',
                ['function'] = {
                  name = 'get_weather',
                  arguments = '{"location":"Paris"}',
                },
              },
            },
          },
          finish_reason = 'tool_calls',
        },
      },
    }

    local result = providers.openai.prepare_output(output, {})

    assert.equals(1, #result.tool_calls)
    assert.equals('get_weather', result.tool_calls[1].name)
    assert.equals('{"location":"Paris"}', result.tool_calls[1].arguments)
  end)

  it('prepare_output parses reasoning content when available', function()
    local output = {
      choices = {
        {
          message = {
            role = 'assistant',
            content = 'Let me think...',
            reasoning_content = 'I should consider the problem carefully.',
          },
        },
      },
    }

    local result = providers.openai.prepare_output(output, {})

    assert.equals('Let me think...', result.content)
    assert.equals('I should consider the problem carefully.', result.reasoning)
  end)
end)
