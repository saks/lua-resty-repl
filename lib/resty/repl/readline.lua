#!/usr/bin/env lua

local ffi = require 'ffi'

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

local read = function()
  libreadline.rl_callback_read_char()
end

local setup = function(prompt, line_handler_callback)
  libreadline.rl_callback_handler_install(prompt, line_handler_callback)
end

local teardown = function()
  libreadline.rl_callback_handler_remove()
end

local puts = function(text)
  if text then
    text = tostring(text) .. '\n'
  else
    text = '\n'
  end

  return libreadline.fwrite(text, #text, 1, libreadline.rl_outstream)
end

local _M = setmetatable({
  libreadline = libreadline,
  add_to_history = add_to_history,
  read = read,
  setup = setup,
  teardown = teardown,
  puts = puts,
  set_prompt = libreadline.rl_set_prompt,
}, { __call = function(_, ...) return libreadline.readline(...) end })

return _M
