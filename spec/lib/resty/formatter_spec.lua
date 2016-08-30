local readline = require 'resty.repl.readline'
local formatter = require 'resty.repl.formatter'
local eval_result = require('resty.repl.binding').eval_result

describe('formatter', function()
  before_each(function() stub(readline, 'puts') end)

  after_each(function() readline.puts:revert() end)

  it('should print string', function()
    formatter.print(eval_result.new { true, 'foo', n = 2 }, 10)

    assert.stub(readline.puts).was_called(1)
    assert.stub(readline.puts).was_called_with '=> foo'
  end)

  it('should print number', function()
    formatter.print(eval_result.new { true, 123, n = 2 }, 10)

    assert.stub(readline.puts).was_called(1)
    assert.stub(readline.puts).was_called_with '=> 123'
  end)

  it('should print ngx.null', function()
    local ngx = _G.ngx
    formatter.print(eval_result.new { true, ngx.null, n = 2 }, 10)

    assert.stub(readline.puts).was_called(1)
    assert.stub(readline.puts).was_called_with '=> <ngx.null>'
  end)

  it('should print table', function()
    formatter.print(eval_result.new { true, { 1, 2, a = 1 }, n = 2 }, 10)

    assert.stub(readline.puts).was_called(1)
    assert.stub(readline.puts).was_called_with '=> { 1, 2,\n  a = 1\n}'
  end)

  it('should print nil', function()
    formatter.print(eval_result.new { true, nil, n = 2 }, 10)

    assert.stub(readline.puts).was_called(1)
    assert.stub(readline.puts).was_called_with('=> nil')
  end)

  it('should print nothing if no args', function()
    formatter.print(eval_result.new { true, n = 1 }, 0)

    assert.stub(readline.puts).was_not_called()
  end)

  it('should print error', function()
    formatter.print(eval_result.new { false, 'foo', n = 1 }, 10)

    assert.stub(readline.puts).was_called(1)
    assert.stub(readline.puts).was_called_with 'ERROR: foo'
  end)
end)
