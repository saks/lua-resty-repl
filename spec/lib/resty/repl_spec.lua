local repl = require 'resty.repl'

describe('resty repl', function()
  it('should work', function()
    assert.are_equal('function', type(repl.start))
  end)
end)
