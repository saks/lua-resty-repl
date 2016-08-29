package = 'lua-resty-repl'
version = '0.0.1-0'
source = {
  url = 'git://github.com/saks/lua-resty-repl',
  tag = 'v0.0.1'
}
description = {
  summary = 'repl for openresty.',
  detailed = [[
    Repl with locals, upvalue and global env access, can be started from
    anywhere with require('resty.repl').start(). It depends on
    https://github.com/kikito/inspect.lua library.
  ]],
  homepage = 'https://github.com/saks/lua-resty-repl',
  license = 'GNU General Public License Version 2'
}
dependencies = {
  'lua >= 5.1'
}
build = {
  type = 'builtin',
  modules = {
    ['resty.repl'] = 'lib/resty/repl.lua',
    ['resty.repl.binding'] = 'lib/resty/repl/binding.lua',
    ['resty.repl.readline'] = 'lib/resty/repl/readline.lua',
    ['inspect'] = 'vendor/inspect.lua'
  }
}
