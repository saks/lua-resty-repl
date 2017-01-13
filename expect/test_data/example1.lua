local y = 1
local b = 2

assert(y ~= b)

local function f(x)
	require('resty.repl').start()
	print('x arg: ' .. tostring(x))
end

f(123)
