local _M = {}

local compile = require('resty.repl.compiler').compile
local InstanceMethods = {}

local table_pack = function(...)
  return { n = select('#', ...), ... }
end

-- FIXME: DRY
local function safe_match(str, re)
  local ok, res = pcall(function()
    return string.match(str, re)
  end)

  return ok and res
end

local result_mt = {}
function result_mt:is_success()
  return true == self[1]
end

function result_mt:value()
  if not self:is_success() then return end

  if 3 > self.n then return self[2] end

  local res = {}
  for i = 2, self.n do
    table.insert(res, self[i])
  end

  return res
end

function result_mt:err()
  if not self:is_success() then return self[2] end
end

function result_mt:has_return_value()
  return self.n > 1
end

_M.eval_result = {
  new = function (t) return setmetatable(t, { __index = result_mt }) end
}

local get_function_index = function(func)
  local caller_index = 1
  local i = caller_index

  while true do
    local info = debug.getinfo(i)
    if not info then break end

    if info.func == func then return i end

    i = i + 1
  end
end

function InstanceMethods:eval(code)
  local func, err = compile(code)

  local result

  if func and 'function' == type(func) then
    setfenv(func, self:get_fenv())
    result = _M.eval_result.new(table_pack(pcall(func)))

    if result:is_success() then
      self.env._ = result:value() -- update last return result
    end
  else
    result = _M.eval_result.new { false, err, n = 2 }
  end

  return result
end

--- Local Vars:
function InstanceMethods:find_local_var(name, match)
  local func = self.info.func
  if 'function' ~= type(func) then return end

  local index = get_function_index(func) - 1
  local i = 1
  local all_names = {}

  while true do
    local var_name, var_value = debug.getlocal(index, i)
    if not var_name then break end

    if match and safe_match(var_name, name) then
      table.insert(all_names, var_name)
    elseif name == var_name then
      -- "index - 1" is because stack will become deeper for a caller
      return true, var_name, var_value, index - 1, i
    end

    i = i + 1
  end

  if match then return all_names end
end

function InstanceMethods:set_local_var(name, value)
  local ok, _, _, index, var_index = self:find_local_var(name)

  if ok then
    debug.setlocal(index, var_index, value)
    return true
  end
end

--- Upvalues:
function InstanceMethods:find_upvalue(name, match)
  local func = self.info.func
  if 'function' ~= type(func) then return end

  local i = 1
  local all_names = {}

  while true do
    local var_name, var_value = debug.getupvalue(func, i)
    if not var_name then break end

    if match and safe_match(var_name, name) then
      table.insert(all_names, var_name)
    elseif name == var_name then
      return true, var_name, var_value, i
    end

    i = i + 1
  end

  if match then return all_names end
end

function InstanceMethods:set_upvalue(name, new_value)
  local func = self.info.func
  local ok, _, _, var_index = self:find_upvalue(name)

  if ok then
    debug.setupvalue(func, var_index, new_value)
    return true
  end
end

function InstanceMethods:get_fenv()
  return setmetatable({}, {
    __index = function(_, key)
      local found_local, _, local_value = self:find_local_var(key)
      if found_local then return local_value end

      local found_upvalue, _, upvalue_value = self:find_upvalue(key)
      if found_upvalue then return upvalue_value end

      return self.env[key]
    end,
    __newindex = function(_, key, value)
      local set_local = self:set_local_var(key, value)
      if set_local then return value end

      local set_upvalue = self:set_upvalue(key, value)
      if set_upvalue then return value end

      self.env[key] = value

      return value
    end
  })
end

function _M.new(caller_info)
  local binding = { info = caller_info, env = getfenv(caller_info.func) }

  return setmetatable(binding, { __index = InstanceMethods })
end

return _M
