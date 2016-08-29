local _M = {}

local InstanceMethods = {}

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

function InstanceMethods:local_var(name, ...)
  local func = self.info.func
  if 'function' ~= type(func) then return end

  local index = get_function_index(func) - 1 -- FIXME: why "-1" ???
  local i = 1

  local all_names = {}

  while true do
    local var_name, var_value = debug.getlocal(index, i)
    if not var_name then
      if name then return else return all_names end
    end

    if name then
      if name == var_name then
        if 1 == select('#', ...) then
          local new_value = select(1, ...)
          debug.setlocal(index, i, new_value)
          return true
        else
          return var_value
        end
      end
    else
      table.insert(all_names, var_name)
    end

    i = i + 1
  end
end

function InstanceMethods:upvalue(name, ...)
  local func = self.info.func

  if 'function' ~= type(func) then return end

  local i = 1

  local all_names = {}

  while true do
    local var_name, var_value = debug.getupvalue(func, i)
    if not var_name then
      if name then return else return all_names end
    end

    if name then
      if name == var_name then
        if 1 == select('#', ...) then
          local new_value = select(1, ...)
          debug.setupvalue(func, i, new_value)
          return true
        else
          return var_value
        end
      end
    else
      table.insert(all_names, var_name)
    end

    i = i + 1
  end
end

function InstanceMethods:get_fenv(last_return_value)
  return setmetatable({}, {
    __index = function(_, key)
      return self:local_var(key) or self:upvalue(key) or self.env[key]
    end,
    __newindex = function(_, key, value)
      local set_local = self:local_var(key, value)
      local set_upvalue

      self.env._ = last_return_value

      if not set_local   then set_upvalue   = self:upvalue(key, value) end
      if not set_upvalue then self.env[key] = value                    end

      return value
    end
  })
end

function _M.new(caller_info)
  local binding = { info = caller_info, env = getfenv(caller_info.func) }

  return setmetatable(binding, { __index = InstanceMethods })
end

return _M
