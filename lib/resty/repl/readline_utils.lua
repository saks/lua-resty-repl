local _M = {}

_M.history_fn = function()
  local home = os.getenv('HOME') or os.getenv('USERPROFILE')

  if nil == home and 'table' == type(_G.ngx) then
    home = _G.ngx.config.nginx_configure():match('--prefix=([^%s]+)')
  end

  if nil == home then home = '/tmp' end

  return home .. '/.luahistory'
end

return _M
