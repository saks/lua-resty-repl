local new_binding = require('resty.repl.binding').new
local new_completer = require('resty.repl.completer').new
local binding, completer, result, word

local test_completer = function()
  local info = debug.getinfo(2)
  binding = new_binding(info)
  completer = new_completer(binding)
  result = completer:find_matches(word)
end

local example_function = function(local_arg)
  assert(local_arg)
  assert(new_binding)
  assert(new_completer)

  local myngx = {
    req = {
      get_body_data = function() end,
      get_body_file = function() end,
    }
  }

  test_completer()

  return myngx
end

local complete = function(t_word)
  word = t_word
  example_function(123)
  return result
end

describe('repl completer', function()
  it('should complete local vars', function()
    assert.are_same({ 'myngx' }, complete 'myn')
    assert.are_same({ 'myngx.req' }, complete 'myngx.')
    assert.are_same({ 'myngx.req' }, complete 'myngx.re')
    assert.are_same({ 'myngx.req.get_body_file', 'myngx.req.get_body_data' },
      complete 'myngx.req.get_')
    assert.are_same({ 'myngx.req.get_body_data()' },
      complete 'myngx.req.get_body_d')
  end)

  -- FIXME:
  -- it('should complete local args', function()
  --   assert.are_same({ 'local_arg', complete 'loca' })
  -- end)

  it('should complete upvalues', function()
    assert.are_same({ 'new_binding', 'new_completer' }, complete 'new_')
    assert.are_same({ 'new_binding()' }, complete 'new_b')
  end)

  it('should complete globals', function()
    assert.are_same({ 'debug.getlocal()' }, complete 'debug.getl')
  end)

  it('should complete globals', function()
    assert.are_same({ 'debug.getlocal()' }, complete 'debug.getl')
  end)
end)
