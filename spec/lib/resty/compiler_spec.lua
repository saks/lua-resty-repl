local compile = require('resty.repl.compiler').compile

describe('compiler', function()
  it('should compile simple expression', function()
    assert.are_equal(compile('1 + 1')(), 2)
  end)

  it('should compile expression with return', function()
    assert.are_equal(compile('a = 1; return a')(), 1)
  end)

  it('should compile expression without return', function()
    assert.are_equal(compile('a = 1')(), nil)
  end)

  it('should compile expression with function', function()
    local res = compile('function() end')()
    assert.are_equal('function', type(res))
  end)

  it('should compile expression with table', function()
    local res = compile('setmetatable({}, { __index = { a = 1 } })')()
    assert.are_equal(1, res.a)
  end)

  it('should handle empty string', function()
    assert.is_nil(compile('')())
  end)

  it('should handle nil', function()
    assert.is_nil(compile(nil)())
  end)

  it('should handle no args', function()
    assert.is_nil(compile()())
  end)
end)
