package = 'lua-resty-repl'
version = 'scm-0'
source = {
  url = 'git://github.com/saks/lua-resty-repl',
  branch = 'master'
}
description = {
  summary = 'repl for openresty.',
  detailed = [[
    Repl with locals, upvalue and global env access, can be started from
    anywhere with require('resty.repl').start(). It depends on
    https://github.com/kikito/inspect.lua library.
  ]],
  homepage = 'https://github.com/saks/lua-resty-repl',
  license = 'MIT <http://opensource.org/licenses/MIT>'
}
dependencies = {
  'lua >= 5.1'
}
build = {
  type = 'builtin',
  modules = {
    ['resty.repl']               = 'lib/resty/repl.lua',
    ['resty.repl.binding']       = 'lib/resty/repl/binding.lua',
    ['resty.repl.readline']      = 'lib/resty/repl/readline.lua',
    ['resty.repl.readline_stub'] = 'lib/resty/repl/readline_stub.lua',
    ['resty.repl.compiler']      = 'lib/resty/repl/compiler.lua',
    ['resty.repl.formatter']     = 'lib/resty/repl/formatter.lua',
    ['resty.repl.ui']            = 'lib/resty/repl/ui.lua',
    ['resty.repl.completer']     = 'lib/resty/repl/completer.lua',
    ['inspect']                  = 'vendor/inspect.lua'
  },
  install = {
    bin = {
      ['resty-repl'] = 'bin/resty-repl'
    }
  }
}
