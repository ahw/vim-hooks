#!/bin/sh

# This VimHook responds to BufWritePost events from files ending in "sql".
# It just feeds the file to sqlite3 which will run whatever SQL you've
# written. The stdout from sqlite3 is loaded into a scratch buffer that will
# open in a horizontal split window, so if you're playing around with a
# SELECT statement you can see the output update automatically with each new
# tweak you make.

# vimhook.bufferoutput
# vimhook.bufferoutput.vsplit = false

sqlite3 sms_database < $1
