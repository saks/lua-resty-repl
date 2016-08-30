local source = 'stdin'

local function compile(code)
  if not code then code = '' end

  -- first, try to load function that returns value
  local code_function, err = loadstring('return ' .. code, source)

  -- if failed, load function that returns nil
  if not code_function then
    code_function, err = loadstring(code, source)
  end

  return code_function, err
end


return { compile = compile }
