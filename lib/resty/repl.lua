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

local new_binding = require('resty.repl.binding').new
local new_ui      = require('resty.repl.ui').new
local formatter   = require 'resty.repl.formatter'

local running = false
local binding, ui

local function stop()
  running = false
end

local function exit(exit_code)
  stop()
  return os.exit(exit_code or 0)
end

local function handle_input(input)
  if input.exit then exit(0)       end
  if input.stop then return stop() end

  if input.code then
    local result = binding:eval(input.code)
    formatter.print(result, #input.code)
    return result
  end
end

local function start()
  running = true

  local caller_info = debug.getinfo(2)

  binding = new_binding(caller_info)
  ui      = new_ui(binding)

  while running do
    local input = ui:readline()
    local result = handle_input(input)

    if result then
      ui:add_to_history(input.code)
    end
  end
end

return {
  _VERSION     = '0.1',
  start        = start,
  stop         = stop,
  handle_input = handle_input,
  running      = running,
  ui           = ui,
  binding      = binding,
}
