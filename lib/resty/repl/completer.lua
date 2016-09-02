local _M = {}

function _M:eval(text)
  local result = self.binding:eval(text)

  if result:is_success() then
    return result:value()
  end
end

function _M:smart_completion(result)
  if #result > 1 then
    return result
  else
    result = result[1]
  end

  local prop      = self:eval(result)
  local prop_type = type(prop)

  if 'function' == prop_type then
    return { result .. '()' }
  else
    return { result }
  end
end

function _M:find_matches_var(word)
  local result = {}

  -- locals
  for _, k in ipairs(self.binding:local_var()) do
    if k:match('^' .. word) then table.insert(result, k) end
  end

  -- upvalues
  for _, k in ipairs(self.binding:upvalue()) do
    if k:match('^' .. word) then table.insert(result, k) end
  end

  -- fenv
  for k, _ in pairs(self.binding.env) do
    if k:match('^' .. word) then table.insert(result, k) end
  end

  return self:smart_completion(result)
end

function _M:find_matches_prop(word, prop_prefix)
  if word:match('^(.+)%.$') then
    local base_obj_str = word:match('^(.+)%.$')
    local base_obj = self:eval(base_obj_str)
    if not base_obj then return end

    if 'function' == type(base_obj) then
      return { base_obj_str .. '()' }
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

    return self:smart_completion(result)
  else
    local already_good_obj = self:eval(word)
    if already_good_obj then
      return self:smart_completion({ word })
    else
      local object, prop = word:match('(.+)%.(.+)$')
      if (not object) or (not prop) then return end
      return self:find_matches_prop(object .. '.', prop)
    end
  end
end

function _M:find_matches(word)
  -- don't compete from the function: some_func(<cursor>)
  if word:match('^[()]+$') then return end

  if word == '' or word:match('^[^.]+$') then
    return self:find_matches_var(word)
  else
    return self:find_matches_prop(word)
  end
end

function _M.new(binding)
  return setmetatable({ binding = binding }, { __index = _M })
end

return _M
