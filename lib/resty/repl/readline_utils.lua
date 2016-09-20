local _M = {}

local function find_home_dir()
  local home = os.getenv('HOME') or os.getenv('USERPROFILE')

  if nil == home and 'table' == type(_G.ngx) then
    home = _G.ngx.config.nginx_configure():match('--prefix=([^%s]+)')
  end

  if nil == home then home = '/tmp' end

  return home
end

_M.home_dir = find_home_dir()
_M.history_file_name = '/.luahistory'

_M.history_fn = function()
  return _M.home_dir .. _M.history_file_name
end

return _M
