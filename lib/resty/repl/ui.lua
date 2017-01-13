local readline = require 'resty.repl.readline'
local new_completer = require('resty.repl.completer').new
local new_sources = require('resty.repl.sources').new

local context = function()
  if _G.ngx and _G.ngx.get_phase then
    return 'ngx(' .. _G.ngx.get_phase() .. ')'
  else
    return 'lua(main)'
  end
end

local commands = {}

commands[{nil, 'exit'}] = function(_, input)
  readline.teardown()
  readline.puts()
  input.stop = true
end

commands[{'exit!'}] = function(_, input)
  input.exit = true
  readline.teardown()
end

commands[{'whereami'}] = function(self, input)
  self:whereami()
  input.code = nil
end

local command_codes = {}
for all_codes, _ in pairs(commands) do
  local codes_len = select('#', unpack(all_codes))
  for i = 1, codes_len do
    local code = all_codes[i]
    if code then table.insert(command_codes, code) end
  end
end

local InstanceMethods = {}
function InstanceMethods:readline()
  local input = { code = readline(self:prompt_line()) }

  for all_command_codes, command_handler in pairs(commands) do
    local codes_len = select('#', unpack(all_command_codes))
    for i = 1, codes_len do
      if input.code == all_command_codes[i] then
        command_handler(self, input)
        return input
      end
    end
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

function InstanceMethods:whereami()
  local ctx = self.sources:whereami()
  if ctx then readline.puts(ctx) end
end

local mt = { __index = InstanceMethods }

local function new(binding)
  local ui = setmetatable({
    completer = new_completer(binding, command_codes),
    sources   = new_sources(binding),
    line_count = 1,
  }, mt)

  readline.set_attempted_completion_function(function(word)
    return ui.completer:find_matches(word)
  end)

  readline.set_startup_hook(function()
    if 2 == ui.line_count then ui:whereami() end
  end)

  return ui
end

return { new = new }
