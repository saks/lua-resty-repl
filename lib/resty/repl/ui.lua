local readline = require 'resty.repl.readline'
local new_completer = require('resty.repl.completer').new

local context = function()
  if _G.ngx and _G.ngx.get_phase then
    return 'ngx(' .. _G.ngx.get_phase() .. ')'
  else
    return 'lua(main)'
  end
end

local InstanceMethods = {}
function InstanceMethods:readline()
  local code = readline(self:prompt_line())
  local input = { code = code }

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

function InstanceMethods.add_to_history(_, text)
  readline.add_to_history(text)
end

local mt = { __index = InstanceMethods }

local function new(binding)
  local completer = new_completer(binding)
  local ui = setmetatable({ completer = completer, line_count = 1 }, mt)

  readline.set_attempted_completion_function(function(word)
    return completer:find_matches(word)
  end)

  return ui
end

return { new = new }
