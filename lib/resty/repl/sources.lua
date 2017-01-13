local _M = {}

local show_n_lines = 5

local function get_source(info)
  local defined_in_file = 1 == info.source:find '@'
  if not defined_in_file then return '\n' end

  local from_no    = info.currentline - show_n_lines
  local to_no      = info.currentline + show_n_lines
  local number_len = #tostring(to_no)
  local result     = { '\n' }

  local line_number = 1
  for line in io.lines(info.source:sub(2)) do
    if line_number >= from_no and line_number <= to_no then
      local prefix = string.rep(' ', 4)
      local line_number_s = string.format('%' .. number_len .. 'd', line_number)

      if line_number == info.currentline then prefix = ' => ' end

      table.insert(result, prefix .. line_number_s .. ': ' .. line)
    end
    line_number = line_number + 1
  end

  return table.concat(result, '\n') .. '\n'
end

function _M:whereami()
  local info = self.binding.info

  -- Don't show context of executable resty-repl started
  if info.short_src:find('bin/resty%-repl') then return end

  local heading = '\n' ..
    'From: ' .. info.short_src .. ' @ line ' .. info.currentline

  return heading .. get_source(info)
end

function _M.new(binding)
  return setmetatable({ binding = binding }, { __index = _M })
end

return _M
