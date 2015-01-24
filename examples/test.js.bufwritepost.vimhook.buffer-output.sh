#!/bin/sh

# This VimHook just runs Node with whatever file triggered the BufWritePost
# event. The hook will fire for any file ending with "test.js", which
# probably only be test.js itself.

# vimhook.bufferoutput

node $1
