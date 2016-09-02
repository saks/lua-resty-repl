#!/usr/bin/env lua

local success, ffi = pcall(function() return require('ffi') end)
if not success then
  return require 'resty.repl.readline_stub'
end

ffi.cdef[[
  /* libc definitions */
  void* malloc(size_t bytes);
  void free(void *);

  typedef void rl_vcpfunc_t (char *);

  char *readline (const char *prompt);

  /* basic history handling */
  void add_history(const char *line);
  int write_history (const char *filename);
  int append_history (int nelements, const char *filename);
  int read_history_range (const char *filename, int from, int to);

  /* completion */
  typedef char **rl_completion_func_t (const char *, int, int);
  typedef char *rl_compentry_func_t (const char *, int);

  char **rl_completion_matches (const char *, rl_compentry_func_t *);

  const char *rl_basic_word_break_characters;
  rl_completion_func_t *rl_attempted_completion_function;
  char *rl_line_buffer;
  int rl_completion_append_character;
  int rl_attempted_completion_over;

  void rl_callback_handler_install (const char *prompt, rl_vcpfunc_t *lhandler);
  void rl_callback_read_char (void);
  void rl_callback_handler_remove (void);

  void* rl_outstream;
  size_t fwrite(const void *, size_t, size_t, void*);

  int rl_set_prompt (const char *prompt);
  int rl_clear_message (void);
  void rl_replace_line (const char *text);
  int rl_message (const char *);
  int rl_delete_text (int start, int end);
  int rl_insert_text (const char *);
  int rl_forced_update_display (void);
  void rl_redisplay (void);
  int rl_point;
]]

local libreadline = ffi.load 'libreadline.so.6'

local history_file_name = '/root/.resty_history'

-- read history from file
libreadline.read_history_range(history_file_name, 0, -1)

local add_to_history = function(text)
  libreadline.add_history(text)
  -- FIXME: sync to the history file from nginx
  -- assert(0 == libreadline.write_history(history_file_name))
end

local teardown = function()
  libreadline.rl_callback_handler_remove()
end

local write = function(text)
  return libreadline.fwrite(text, #text, 1, libreadline.rl_outstream)
end

local puts = function(text)
  if nil == text then
    text = ''
  else
    text = tostring(text)
  end

  return write(text .. '\n')
end

local function set_attempted_completion_function(callback)
  function libreadline.rl_attempted_completion_function(word)
    local strword = ffi.string(word)
    local buffer = ffi.string(libreadline.rl_line_buffer)

    local matches = callback(strword, buffer)

    if not matches then return nil end

    -- if matches is an empty array, tell readline to not call default completion (file)
    libreadline.rl_attempted_completion_over = 1

    -- translate matches table to C strings
    -- (there is probably more efficient ways to do it)
    return libreadline.rl_completion_matches(word, function(_, i)
      local match = matches[i + 1]

      if match then
        -- readline will free the C string by itself, so create copies of them
        local buf = ffi.C.malloc(#match + 1)
        ffi.copy(buf, match, #match + 1)
        return buf
      else
        return ffi.new('void*', nil)
      end
    end)
  end
end

local chars_to_string = function(chars)
  local result = ffi.string(chars)
  ffi.C.free(chars)
  return result
end

local readline = function(...)
  local chars = libreadline.readline(...)
  local line

  if chars ~= nil then
    line = chars_to_string(chars)
    add_to_history(line)
  end

  return line
end

local _M = setmetatable({
  teardown = teardown,
  puts = puts,
  set_attempted_completion_function = set_attempted_completion_function,
}, { __call = function(_, ...) return readline(...) end })

return _M
