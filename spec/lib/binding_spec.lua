local repl = require 'resty.repl'
local repl_readline = require 'resty.repl.readline'
local repl_binding = require 'resty.repl.binding'

describe('resty repl binding', function()
  local caller_info
  local binding
  local repl_code
  local readline_puts_result

  before_each(function()
    stub(repl, 'chars_to_string', function(str) return str end)
    stub(repl_readline, 'puts', function(str)
      readline_puts_result = str
    end)
  end)

  after_each(function()
    repl.chars_to_string:revert()
    repl_readline.puts:revert()
  end)

  local execute_repl_code = function()
    binding = repl_binding.new(caller_info)
    repl.binding = binding
    repl.callback_line_handler(repl_code)
  end

  local outer_function = function(outer_arg)
    local outer_local = 'outer_local'
    local invisible_outer_local = 'invisible_outer_local'

    local caller_function = function(caller_arg)
      local caller_local = 'caller_local'

      caller_info = debug.getinfo(1)

      execute_repl_code()

      return {
        caller_local = caller_local,
        caller_arg   = caller_arg,
        outer_local  = outer_local,
        outer_arg    = outer_arg,
      }
    end

    local result = caller_function('caller_arg')
    result.invisible_outer_local = invisible_outer_local

    return result
  end

  local run = function(code)
    repl_code = code
    return outer_function 'outer_arg'
  end

  it('should calculate simple expression', function()
    run '1 + 1'
    assert.are_equal('=> 2', readline_puts_result)
  end)

  it('should return locals', function()
    run 'caller_local'
    assert.are_equal('=> caller_local', readline_puts_result)
  end)

  it('should return local arg', function()
    run 'caller_arg'
    assert.are_equal('=> caller_arg', readline_puts_result)
  end)

  it('should return upvalue', function()
    run 'outer_local'
    assert.are_equal('=> outer_local', readline_puts_result)
  end)

  it('should return upvalue arg', function()
    run 'outer_arg'
    assert.are_equal('=> outer_arg', readline_puts_result)
  end)

  it('should update locals', function()
    local result = run 'caller_local = 123'
    assert.are_equal(123, result.caller_local)
  end)

  -- FIXME: update local function args
  -- it('should update local args', function()
  --   local result = run 'caller_arg = "123"'
  --   assert.are_equal('123', result.caller_local)
  -- end)

  it('should update upvalues', function()
    local result = run 'outer_local = 123'
    assert.are_equal(123, result.outer_local)
  end)

  it('should update upargs', function()
    local result = run 'outer_arg = 123'
    assert.are_equal(123, result.outer_arg)
  end)

  it('should read from fenv', function()
    run 'foo'
    assert.are_equal('=> nil', readline_puts_result)

    repl.binding.env.foo = 'foo'

    run 'foo'
    assert.are_equal('=> foo', readline_puts_result)
  end)

  it('should update last return value into `_`', function()
    run '_'
    assert.are_equal('=> nil', readline_puts_result)

    run '123'

    run '_'
    assert.are_equal('=> 123', readline_puts_result)
  end)

  it('should remember vars between runs', function()
    run 'a'
    assert.are_equal('=> nil', readline_puts_result)

    run 'a = 123'

    run 'a'
    assert.are_equal('=> 123', readline_puts_result)
  end)

  it('should compile more complicated expressions 1', function()
    run 'a = 123; return a'
    assert.are_equal('=> 123', readline_puts_result)
  end)

  it('should compile more complicated expressions 2', function()
    run 'f=function() return 123 end; return f()'
    assert.are_equal('=> 123', readline_puts_result)
  end)
end)
