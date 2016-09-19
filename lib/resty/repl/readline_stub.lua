local function teardown()
end

local function puts(text)
  if nil == text then
    text = ''
  else
    text = tostring(text)
  end

  return print(text)
end

local function set_attempted_completion_function()
end

local function add_to_history()
end

local function readline(prompt)
  io.write(prompt)
  io.stdout:flush()
  io.input(io.stdin)
  return io.read()
end

local _M = setmetatable({
  teardown = teardown,
  puts = puts,
  set_attempted_completion_function = set_attempted_completion_function,
  add_to_history = add_to_history,
}, { __call = function(_, ...) return readline(...) end })

return _M
