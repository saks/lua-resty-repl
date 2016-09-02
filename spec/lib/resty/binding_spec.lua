local repl_binding = require 'resty.repl.binding'

describe('resty repl binding', function()
  local caller_info
  local repl_code
  local eval_result
  local binding

  local eval_with_binding = function()
    binding = repl_binding.new(caller_info)
    eval_result = binding:eval(repl_code)
  end

  local outer_function = function(outer_arg)
    local outer_local = 'outer_local'
    local invisible_outer_local = 'invisible_outer_local'

    local caller_function = function(caller_arg)
      local caller_local = 'caller_local'

      caller_info = debug.getinfo(1)

      eval_with_binding()

      return {
        caller_local = caller_local,
        caller_arg   = caller_arg,
        outer_local  = outer_local,
        outer_arg    = outer_arg,
      }
    end

    local result = caller_function('caller_arg_value')
    result.invisible_outer_local = invisible_outer_local

    return result
  end

  local run = function(code)
    repl_code = code
    local outer_func_ret = outer_function 'outer_arg'
    return eval_result, outer_func_ret
  end

  it('should calculate simple expression', function()
    local result = run '1 + 1'
    assert.are_same({ true, 2, n = 2 }, result)
  end)

  it('should return locals', function()
    local _, outer_func_ret = run 'caller_local'
    assert.are_equal('caller_local', outer_func_ret.caller_local)
  end)

  it('should return local arg', function()
    local result, outer_func_ret = run 'caller_arg'

    assert.are_same({ true, 'caller_arg_value', n = 2 }, result)
    assert.are_equal('caller_arg_value', outer_func_ret.caller_arg)
  end)

  it('should return upvalue', function()
    local result, outer_func_ret = run 'outer_local'

    assert.are_same({ true, 'outer_local', n = 2 }, result)
    assert.are_equal('outer_local', outer_func_ret.outer_local)
  end)

  it('should return upvalue arg', function()
    local result, outer_func_ret = run 'outer_arg'

    assert.are_same({ true, 'outer_arg', n = 2 }, result)
    assert.are_equal('outer_arg', outer_func_ret.outer_arg)
  end)

  it('should update locals', function()
    local result, outer_func_ret = run 'caller_local = 123'

    assert.are_same({ true, n = 1 }, result) -- no ret value
    assert.are_equal(123, outer_func_ret.caller_local)
  end)

  it('should update local args', function()
    local result, outer_func_ret = run 'caller_arg = "123"; return caller_arg'

    assert.are_same({ true, '123', n = 2 }, result)
    assert.are_equal('123', outer_func_ret.caller_arg)
  end)

  it('should update upvalues', function()
    local result, outer_func_ret = run 'outer_local = 123'

    assert.are_same({ true, n = 1 }, result) -- no ret value
    assert.are_equal(123, outer_func_ret.outer_local)
  end)

  it('should update upvalues with return', function()
    local result, outer_func_ret = run 'outer_local = 123; return outer_local'

    assert.are_same({ true, 123, n = 2 }, result)
    assert.are_equal(123, outer_func_ret.outer_local)
  end)

  it('should update upvalues with ret value nil', function()
    local result, outer_func_ret = run 'outer_local = 123; return nil'

    assert.are_same({ true, nil, n = 2 }, result)
    assert.are_equal(123, outer_func_ret.outer_local)
  end)

  it('should update upargs', function()
    local result, outer_func_ret = run 'outer_arg = 123'

    assert.are_same({ true, n = 1 }, result) -- no ret value
    assert.are_equal(123, outer_func_ret.outer_arg)
  end)

  it('should read from fenv', function()
    local result = run 'foo'
    assert.are_same({ true, nil, n = 2 }, result)

    binding.env.foo = 'foo'

    result = run 'foo'
    assert.are_same({ true, 'foo', n = 2 }, result)
  end)

  it('should update last return value into `_`', function()
    local result = run '_'
    assert.are_same({ true, nil, n = 2 }, result)

    run '123'

    result = run '_'
    assert.are_same({ true, 123, n = 2 }, result)
  end)

  it('should remember vars between runs', function()
    local result = run 'a'
    assert.are_same({ true, nil, n = 2 }, result)

    run 'a = 123'

    result = run 'a'
    assert.are_same({ true, 123, n = 2 }, result)
  end)

  it('should compile more complicated expressions', function()
    local result = run 'f=function() return 123 end; return f()'
    assert.are_same({ true, 123, n = 2 }, result)
  end)

  context('eval result', function()
    context('success', function()
      it('should be success', function()
        local res = repl_binding.eval_result.new { true, n = 1 }
        assert.is_true(res:is_success())
      end)

      it('should have value', function()
        local res = repl_binding.eval_result.new { true, 'foo', n = 2 }
        assert.are_equal('foo', res:value())
      end)

      it('should have no value', function()
        local res = repl_binding.eval_result.new { true, n = 1 }
        assert.is_nil(res:value())
      end)

      it('should have no return values', function()
        local res = repl_binding.eval_result.new { true, n = 1 }
        assert.is_false(res:has_return_value())
      end)

      it('should have no error because success with no ret value', function()
        local res = repl_binding.eval_result.new { true, n = 1 }
        assert.is_nil(res:err())
      end)

      it('should have no error because success with ret value', function()
        local res = repl_binding.eval_result.new { true, 'foo', n = 2 }
        assert.is_nil(res:err())
      end)

      it('should have no error because success with ret value', function()
        local res = repl_binding.eval_result.new { true, 'foo', n = 2 }
        assert.is_nil(res:err())
      end)

      it('should have table value if table returned', function()
        local res = repl_binding.eval_result.new { true, { 1, 2 }, n = 2 }
        assert.are_same({ 1, 2 }, res:value())
      end)

      it('should have table value if more returned', function()
        local res = repl_binding.eval_result.new { true, 1, 2, n = 3 }
        assert.are_same({ 1, 2 }, res:value())
      end)

      it('should have table value if many tables returned', function()
        local res = repl_binding.eval_result.new {
          true,
          { 1, 2 },
          { 3, 4 },
          n = 3
        }
        assert.are_same({ { 1, 2 }, { 3, 4 } }, res:value())
      end)
    end)

    context('not success', function()
      it('should not be success', function()
        local res = repl_binding.eval_result.new { false, n = 1 }
        assert.is_false(res:is_success())
      end)

      it('should have no value with error without ret value', function()
        local res = repl_binding.eval_result.new { false, n = 1 }
        assert.is_nil(res:value())
      end)

      it('should have no value with error', function()
        local res = repl_binding.eval_result.new { false, 'foo', n = 2 }
        assert.is_nil(res:value())
      end)

      it('should have no error without error specified', function()
        local res = repl_binding.eval_result.new { false, n = 1 }
        assert.is_nil(res:err())
      end)

      it('should have error', function()
        local res = repl_binding.eval_result.new { false, 'foo', n = 2 }
        assert.are_equal('foo', res:err())
      end)

      it('should have no return values', function()
        local res = repl_binding.eval_result.new { false, n = 1 }
        assert.is_false(res:has_return_value())
      end)

      it('should have return values with error', function()
        local res = repl_binding.eval_result.new { false, 'foo', n = 2 }
        assert.is_true(res:has_return_value())
      end)
    end)
  end)
end)
