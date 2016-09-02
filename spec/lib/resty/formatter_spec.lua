local readline = require 'resty.repl.readline'
local formatter = require 'resty.repl.formatter'
local eval_result = require('resty.repl.binding').eval_result

describe('formatter', function()
  local debug = false

  before_each(function()
    stub(readline, 'puts', function(text)
      if debug then print(text) end
    end)
  end)

  after_each(function()
    readline.puts:revert()
    debug = false
  end)

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
    local _G_ngx = _G.ngx
    local ngx

    if _G_ngx then
      ngx = _G_ngx
    else
      ngx = { null = {} }
      _G.ngx = ngx
    end

    formatter.print(eval_result.new { true, ngx.null, n = 2 }, 10)

    assert.stub(readline.puts).was_called(1)
    assert.stub(readline.puts).was_called_with '=> <ngx.null>'

    _G.ngx = _G_ngx
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

  it('should print nil in the table', function()
    formatter.print(eval_result.new { true, { nil, 'err' }, n = 2 }, 10)

    assert.stub(readline.puts).was_called(1)
    assert.stub(readline.puts).was_called_with('=> {\n  [2] = "err"\n}')
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
