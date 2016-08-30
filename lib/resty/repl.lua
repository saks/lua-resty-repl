#!/usr/bin/env resty

-- USAGE:
-- PUT INTO CODE:
-- require('resty.repl').start()
--
-- OR:
-- run: resty -e "require('resty.repl').start()"
--
-- TODO: better completion
-- TODO: color output
-- TODO: add specs

local ffi = require 'ffi'

local repl_binding = require 'resty.repl.binding'
local readline = require 'resty.repl.readline'
local formatter = require 'resty.repl.formatter'

local _M = { _VERSION = '0.1' }

local context = function()
  if _G.ngx and _G.ngx.get_phase then
    return 'ngx(' .. _G.ngx.get_phase() .. ')'
  else
    return 'lua(main)'
  end
end

local prompt_line = function()
  local res = '[' .. _M.line_count .. '] ' .. context() .. '> '
  _M.line_count = _M.line_count + 1
  return res
end

_M.exit = function(exit_code)
  os.exit(exit_code)
end

_M.chars_to_string = function(chars)
  local result = ffi.string(chars)
  ffi.C.free(chars)
  return result
end

_M.callback_line_handler = function(chars)
  local code

  if chars ~= nil then
    code = _M.chars_to_string(chars)
    readline.add_to_history(code)
  end

  if nil == code or code == 'exit' then
    _M.running = false
    readline.teardown()
    readline.puts()
    return
  end

  if 'exit!' == code then
    _M.running = false
    readline.teardown()
    _M.exit(0)
  end

  assert(code, 'nothing to eval!')

  local result = _M.binding:eval(code)
  formatter.print(result, #code)
end

local function eval(text)
  local func = loadstring('return ' .. tostring(text))
  if not func then return end

  setfenv(func, _M.binding:get_fenv())
  local ok, result = pcall(func)
  if ok then return result end
end

local smart_completion = function(result)
  if #result > 1 then
    return result
  else
    result = result[1]
  end

  local prop      = eval(result)
  local prop_type = type(prop)

  if 'function' == prop_type then
    if debug.getinfo(prop).nparams > 0 then
      readline.libreadline.rl_replace_line(result .. '()')
      readline.libreadline.rl_point = #result + 1
    else
      return { result .. '()' }
    end
  elseif 'table' == prop_type then
    readline.libreadline.rl_replace_line(result .. '.')
    readline.libreadline.rl_point = #result + 1
  else
    return { result }
  end
end

local function find_matches_var(word)
  local result = {}

  -- locals
  for _, k in ipairs(_M.binding:local_var()) do
    if k:match('^' .. word) then table.insert(result, k) end
  end

  -- upvalues
  for _, k in ipairs(_M.binding:upvalue()) do
    if k:match('^' .. word) then table.insert(result, k) end
  end

  -- fenv
  for k, _ in pairs(_M.binding.env) do
    if k:match('^' .. word) then table.insert(result, k) end
  end

  return smart_completion(result)
end

local function find_matches_prop(word, prop_prefix)
  if word:match('^(.+)%.$') then
    local base_obj_str = word:match('^(.+)%.$')
    local base_obj = eval(base_obj_str)
    if not base_obj then return end

    if 'function' == type(base_obj) then
      readline.libreadline.rl_replace_line(base_obj_str .. '()')
      readline.libreadline.rl_point = #base_obj_str + 1
      return
    end

    local result = {}

    for k, _ in pairs(base_obj) do
      if prop_prefix then
        if k:match('^' .. prop_prefix) then
          table.insert(result, word .. k)
        end
      else
        table.insert(result, word .. k)
      end
    end

    return smart_completion(result)
  else
    local already_good_obj = eval(word)
    if already_good_obj then
      return smart_completion({ word })
    else
      local object, prop = word:match('(.+)%.(.+)$')
      if (not object) or (not prop) then return end
      return find_matches_prop(object .. '.', prop)
    end
  end
end

local function find_matches(word)
  -- don't compete from the function: some_func(<cursor>)
  if word:match('^[()]+$') then return end

  if word == '' or word:match('^[^.]+$') then
    return find_matches_var(word)
  else
    return find_matches_prop(word)
  end
end

function readline.libreadline.rl_attempted_completion_function(word)
  local strword = ffi.string(word)
  -- local buffer = ffi.string(readline.libreadline.rl_line_buffer)

  local matches = find_matches(strword)

  if not matches then return nil end

  -- if matches is an empty array, tell readline to not call default completion (file)
  readline.libreadline.rl_attempted_completion_over = 1

  -- translate matches table to C strings
  -- (there is probably more efficient ways to do it)
  return readline.libreadline.rl_completion_matches(word, function(_, i)
    local match = matches[i + 1]

    if match then
      -- readline will free the C string by itself, so create copies of them
      local buf = ffi.C.malloc(#match + 1)
      ffi.copy(buf, match, #match+1)
      return buf
    else
      return ffi.new("void*", nil)
    end
  end)
end

_M.start = function()
  local caller_info = debug.getinfo(2)

  _M.running = true
  _M.line_count = 1
  _M.binding = repl_binding.new(caller_info)

  while _M.running do
    _M.callback_line_handler(readline(prompt_line()))
  end
end

return _M
