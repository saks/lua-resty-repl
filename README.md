# Welcome to Resty Repl

## Features

Resty Repl is a powerful alternative to the standard [luajit](http://luajit.org/) shell ispired by [pry](https://github.com/pry/pry). It is written from scratch to provide a number of advanced features, including:
* Full read/write access to locals, upvalues and global variables
* Pretty print for objects
* A Powerful and flexible command system
* Ability to view and replay history
* Runtime invocation (use Resty Repl as a developer console or debugger)
* Tab completion
* Simple and easy way to debug lua running in the nginx ([openresty](http://openresty.org/en/))

## Runtime invocation

First install luarock
```bash
luarocks install lua-resty-repl
```

Then just drop this snippet anywhere in your code:

```lua
require('resty.repl').start()
```

or run as cli:
```bash
resty-repl
```

## Openresty debugger
But what makes it really nice is that now you can debug your [openresty](http://openresty.org/en/) code right from running nginx!

```nginx
master_process off;
error_log stderr notice;
daemon off;

events {
  worker_connections 1024;
}

http {
  server {
    listen 8080;
    lua_code_cache off;

    location / {
      content_by_lua_block {
        require('resty.repl').start()
      }
    }
  }
}
```

and start debugging:
```bash
$ curl -H X-Header:buz 172.17.0.2:8080?foo=bar

```

```
nginx -c /tmp/ngx.conf
2016/09/19 16:39:19 [alert] 639#0: lua_code_cache is off; this will hurt performance in /tmp/ngx.conf:12
nginx: [alert] lua_code_cache is off; this will hurt performance in /tmp/ngx.conf:12
2016/09/19 16:39:19 [notice] 639#0: using the "epoll" event method
2016/09/19 16:39:19 [notice] 639#0: openresty/1.11.2.1
2016/09/19 16:39:19 [notice] 639#0: built by gcc 4.9.2 (Debian 4.9.2-10)
2016/09/19 16:39:19 [notice] 639#0: OS: Linux 4.4.0-38-generic
2016/09/19 16:39:19 [notice] 639#0: getrlimit(RLIMIT_NOFILE): 65536:65536
[1] ngx(content)> ngx.req.get_headers()
=> {
  accept = "*/*",
  host = "172.17.0.2:8080",
  ["user-agent"] = "curl/7.47.0",
  ["x-header"] = "buz",
  <metatable> = {
    __index = <function 1>
  }
}
[2] ngx(content)> ngx.req.get_uri_args()
=> {
  foo = "bar"
}
[3] ngx(content)> ngx.say 'it works!'
=> 1
[4] ngx(content)> ngx.exit(ngx.OK)
172.17.0.1 - - [19/Sep/2016:16:39:30 +0000] "GET /?foo=bar HTTP/1.1" 200 20 "-" "curl/7.47.0"
```

## Compatibility
Right now it's only compatible with:
- luajit
- lua5.1 (no readline)

## Os Support
Only GNU/Linux for now.

## Roadmap
- colorized output
- smarter completion
- full readline support for lua (no ffi environments)
- remote debugger
- command for showing function source
- show context and source of the place in code from where repl was started
- test suite with [resty-cli](https://github.com/openresty/resty-cli), [luajit](http://luajit.org/) and different versions of lua
- better inspect library

## Code Status

[![Build Status](https://travis-ci.org/saks/lua-resty-repl.svg?branch=master)](https://travis-ci.org/saks/lua-resty-repl)

## License

resty-repl is released under the [MIT License](http://www.opensource.org/licenses/MIT).
