local inspect = require 'inspect'
local readline = require 'resty.repl.readline'

local function output(result, code_len)
  local value = result:value()

  -- print an error if not success
  if not result:is_success() then
    readline.puts('ERROR: ' .. result:err())
    return
  end

  -- don't print anything if there is just <CR>
  if not result:has_return_value() and 0 == code_len then return end

  if _G.ngx and (_G.ngx.null == value) then
    value = '<ngx.null>'
  elseif 'table' == type(value) then
    value = inspect(value)
  end

  readline.puts('=> ' .. tostring(value))
end

return { print = output }
