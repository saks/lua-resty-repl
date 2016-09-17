local _M = {}

local property_re = '^(.+)[:.]$'

local function safe_match(str, re)
  local ok, res = pcall(function()
    return string.match(str, re)
  end)

  return ok and res
end

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
  local re = '^' .. word

  -- locals
  for _, k in ipairs(self.binding:find_local_var(re, true)) do
    if safe_match(k, re) then table.insert(result, k) end
  end

  -- upvalues
  for _, k in ipairs(self.binding:find_upvalue(re, true)) do
    if safe_match(k, re) then table.insert(result, k) end
  end

  -- fenv
  for k, _ in pairs(self.binding.env) do
    if safe_match(k, re) then table.insert(result, k) end
  end

  -- _G
  for k, _ in pairs(_G) do
    if safe_match(k, re) then table.insert(result, k) end
  end

  -- _G metatable
  local _G_mt = getmetatable(_G)
  if 'table' == type(_G_mt) and 'table' == type(_G_mt.__index) then
    for k, _ in pairs(_G_mt.__index) do
      if safe_match(k, re) then table.insert(result, k) end
    end
  end

  return self:smart_completion(result)
end

function _M.find_prop_in_object(object, options)
  local prop_prefix = options.prop_prefix
  local word        = options.word
  local result = {}

  -- search for own methods
  for k, v in pairs(object) do
    local v_type = type(v)
    if 'function' == v_type then k = k .. '()' end
    if 'table'    == v_type then k = k .. '.' end
    table.insert(result, { k, type(v) })
  end

  -- search for meta methods
  local mt = getmetatable(object)
  if mt and 'table' == type(mt.__index) then
    for k, v in pairs(mt.__index) do
      local v_type = type(v)
      if 'function' == v_type then k = k .. '()' end
      if 'table'    == v_type then k = k .. '.' end
      table.insert(result, { k, v_type })
    end
  end

  -- filter by property prefix
  if prop_prefix then
    local not_filterd = result
    result = {}
    for _, key_value_pair in ipairs(not_filterd) do
      if safe_match(key_value_pair[1], '^' .. prop_prefix) then
        table.insert(result, key_value_pair)
      end
    end
  end

  -- filter by value type
  if word:match ':$' then -- completing method name
    local not_filterd = result
    result = {}
    for _, key_value_pair in ipairs(not_filterd) do
      if key_value_pair[2] == 'function' then
        table.insert(result, key_value_pair)
      end
    end
  end

  -- prepend with word
  for i, key_value_pair in ipairs(result) do
    result[i] = word .. key_value_pair[1]
  end

  return result
end

function _M:find_matches_prop(word, prop_prefix)
  if safe_match(word, property_re) then
    local base_obj_str = safe_match(word, property_re)
    local base_obj = self:eval(base_obj_str)
    if not base_obj then return end

    if 'function' == type(base_obj) then return { base_obj_str .. '()' } end

    -- we're trying to complete property name, so if base object
    -- is not a table, we just return it.
    if 'table' ~= type(base_obj) then return { base_obj_str } end

    local result = self.find_prop_in_object(base_obj, {
      prop_prefix = prop_prefix,
      word        = word,
    })

    return self:smart_completion(result)
  else
    local already_good_obj = self:eval(word)
    if already_good_obj then
      return self:smart_completion({ word })
    else
      local object, dot, prop = word:match('(.+)([.:])(.+)$')
      if (not object) or (not prop) then return end
      return self:find_matches_prop(object .. dot, prop)
    end
  end
end

function _M:find_matches(word)
  -- don't compete from the function: some_func(<cursor>)
  if word:match('^[()]+$') then return end

  if word == '' or word:match('^[^.:]+$') then
    return self:find_matches_var(word)
  else
    return self:find_matches_prop(word)
  end
end

function _M.new(binding)
  return setmetatable({ binding = binding }, { __index = _M })
end

return _M
