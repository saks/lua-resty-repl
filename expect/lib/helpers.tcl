#!/usr/bin/env tclsh

set timeout 1

set force_conservative 0  ;# set to 1 to force conservative mode even if
			  ;# script wasn't run conservatively originally
if {$force_conservative} {
	set send_slow {1 .1}
	proc send {ignore arg} {
		sleep .1
		exp_send -s -- $arg
	}
}

# Hit Enter key
proc press_enter_key {} {
  send -- "\r"
}

# Exit with code 1 if expactation failed with timeout.
proc expect_or_fail {expectation} {
  expect {
    timeout { exit 1 }
    $expectation
  }
}

# Send text and hit Enter key.
proc input {text} {
  send -- $text
  press_enter_key
}

# Send UP_ARROW key
proc press_up_arrow_key {{times 1}} {
  for {set x 0} {$x<$times} {incr x} {
    send -- "\033OA"
  }
}

proc expect_prompt_line {line_number} {
  expect_or_fail "\\\[$line_number] lua(main)> "
}

proc exit_repl {} {
  input "exit"
  expect_or_fail eof
}
