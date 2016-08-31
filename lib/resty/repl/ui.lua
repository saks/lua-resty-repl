local ffi = require 'ffi'
local readline = require 'resty.repl.readline'
-- local find_matches = require('resty.repl.completor').find_matches

local find_matches = function()
  return {}
end

local context = function()
  if _G.ngx and _G.ngx.get_phase then
    return 'ngx(' .. _G.ngx.get_phase() .. ')'
  else
    return 'lua(main)'
  end
end

local chars_to_string = function(chars)
  local result = ffi.string(chars)
  ffi.C.free(chars)
  return result
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
      ffi.copy(buf, match, #match + 1)
      return buf
    else
      return ffi.new('void*', nil)
    end
  end)
end

local InstanceMethods = {}
function InstanceMethods:readline()
  local chars = readline(self:prompt_line())
  local input = {}
  local code

  if chars ~= nil then
    code = chars_to_string(chars)
    readline.add_to_history(code)
    input.code = code
  end

  if nil == code or 'exit' == code then
    readline.teardown()
    readline.puts()
    input.stop = true
  end

  if 'exit!' == code then
    input.exit = true
    readline.teardown()
  end

  return input
end

function InstanceMethods:prompt_line()
  local res = '[' .. self.line_count .. '] ' .. context() .. '> '
  self.line_count = self.line_count + 1
  return res
end

local mt = { __index = InstanceMethods }

local function new(binding)
  return setmetatable({ binding = binding, line_count = 1 }, mt)
end

return { new = new }
