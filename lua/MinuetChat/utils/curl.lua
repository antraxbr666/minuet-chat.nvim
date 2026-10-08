local async = require('plenary.async')
local curl = require('plenary.curl')
local log = require('plenary.log')
local utils = require('MinuetChat.utils')

local M = {}

M.args = {
  timeout = 30000,
  raw = {
    '--retry',
    '2',
    '--retry-delay',
    '1',
    '--keepalive-time',
    '60',
    '--no-compressed',
    '--connect-timeout',
    '10',
    '--tcp-nodelay',
    '--no-buffer',
  },
}

--- Store curl global arguments
---@param args table The arguments
---@return table
function M.store_args(args)
  M.args = vim.tbl_deep_extend('force', M.args, args)
  return M.args
end

--- Send curl get request
---@param url string The url
---@param opts table? The options
---@async
M.get = async.wrap(function(url, opts, callback)
  log.debug('GET request:', url, opts)
  local args = {
    on_error = function(err)
      log.debug('GET error:', err)
      callback(nil, err and err.stderr or err)
    end,
  }

  args = vim.tbl_deep_extend('force', M.args, args)
  args = vim.tbl_deep_extend('force', args, opts or {})

  args.callback = function(response)
    log.debug('GET response:', response)
    -- HTTP status codes: 1xx (informational), 2xx (success)
    -- Status 100 (Continue) is common with streaming responses
    local status_str = tostring(response.status)
    if response and not vim.startswith(status_str, '1') and not vim.startswith(status_str, '20') then
      callback(response, response.body)
      return
    end

    if not args.json_response then
      callback(response)
      return
    end

    local body, err = utils.json_decode(tostring(response.body))
    if err then
      callback(response, err)
    else
      response.body = body
      callback(response)
    end
  end

  curl.get(url, args)
end, 3)

--- Send curl post request
---@param url string The url
---@param opts table? The options
---@async
M.post = async.wrap(function(url, opts, callback)
  log.debug('POST request:', url, opts)
  local args = {
    on_error = function(err)
      log.debug('POST error:', err)
      callback(nil, err and err.stderr or err)
    end,
  }

  args = vim.tbl_deep_extend('force', M.args, args)
  args = vim.tbl_deep_extend('force', args, opts or {})

  local temp_file_path = nil

  args.callback = function(response)
    log.debug('POST response:', url, response)
    if temp_file_path then
      local ok, err = pcall(os.remove, temp_file_path)
      if not ok then
        log.debug('Failed to remove temp file:', temp_file_path, err)
      end
    end
    -- HTTP status codes: 1xx (informational), 2xx (success)
    -- Status 100 (Continue) is common with streaming responses
    local status_str = tostring(response.status)
    if response and not vim.startswith(status_str, '1') and not vim.startswith(status_str, '20') then
      callback(response, response.body)
      return
    end

    if not args.json_response then
      callback(response)
      return
    end

    local body, err = utils.json_decode(tostring(response.body))
    if err then
      callback(response, err)
    else
      response.body = body
      callback(response)
    end
  end

  if args.json_response then
    args.headers = vim.tbl_deep_extend('force', args.headers or {}, {
      Accept = 'application/json',
    })
  end

  if args.json_request then
    args.headers = vim.tbl_deep_extend('force', args.headers or {}, {
      ['Content-Type'] = 'application/json',
    })

    temp_file_path = os.tmpname()
    local f = io.open(temp_file_path, 'w+')
    if f == nil then
      error('Could not open file: ' .. temp_file_path)
    end
    f:write(vim.json.encode(args.body))
    f:close()
    args.body = temp_file_path
  end

  curl.post(url, args)
end, 3)

--- Send synchronous curl get request (for headless mode)
---@param url string The url
---@param opts table? The options
---@return table response, string? err
function M.get_sync(url, opts)
  log.debug('GET sync request:', url, opts)
  opts = opts or {}

  local args = { url }

  if opts.headers then
    for k, v in pairs(opts.headers) do
      table.insert(args, '-H')
      table.insert(args, k .. ': ' .. v)
    end
  end

  if opts.raw then
    for _, v in ipairs(opts.raw) do
      table.insert(args, v)
    end
  end

  table.insert(args, '--max-time')
  table.insert(args, tostring(opts.timeout or M.args.timeout / 1000))

  local result = vim.system({ 'curl', unpack(args) }, { text = true }):wait()

  if result.code ~= 0 then
    return nil, result.stderr
  end

  local response = {
    status = 200,
    body = result.stdout,
  }

  if opts.json_response then
    local body, err = utils.json_decode(response.body)
    if err then
      return response, err
    end
    response.body = body
  end

  return response, nil
end

--- Send synchronous curl post request (for headless mode)
---@param url string The url
---@param opts table? The options
---@return table response, string? err
function M.post_sync(url, opts)
  log.debug('POST sync request:', url, opts)
  opts = opts or {}

  local args = { url, '-X', 'POST' }

  local temp_file_path = nil

  if opts.headers then
    for k, v in pairs(opts.headers) do
      table.insert(args, '-H')
      table.insert(args, k .. ': ' .. v)
    end
  end

  if opts.json_response then
    table.insert(args, '-H')
    table.insert(args, 'Accept: application/json')
  end

  if opts.json_request then
    table.insert(args, '-H')
    table.insert(args, 'Content-Type: application/json')

    temp_file_path = os.tmpname()
    local f = io.open(temp_file_path, 'w+')
    if f == nil then
      return nil, 'Could not open file: ' .. temp_file_path
    end
    f:write(vim.json.encode(opts.body))
    f:close()
    table.insert(args, '-d')
    table.insert(args, '@' .. temp_file_path)
  elseif opts.body then
    table.insert(args, '-d')
    table.insert(args, opts.body)
  end

  if opts.raw then
    for _, v in ipairs(opts.raw) do
      table.insert(args, v)
    end
  end

  table.insert(args, '--max-time')
  table.insert(args, tostring(opts.timeout or M.args.timeout / 1000))

  local result = vim.system({ 'curl', unpack(args) }, { text = true }):wait()

  if temp_file_path then
    pcall(os.remove, temp_file_path)
  end

  if result.code ~= 0 then
    return nil, result.stderr
  end

  local response = {
    status = 200,
    body = result.stdout,
  }

  if opts.json_response then
    local body, err = utils.json_decode(response.body)
    if err then
      return response, err
    end
    response.body = body
  end

  return response, nil
end

return M
