#!/bin/sh

# The hook will fire for any file ending with "test.js", which
# probably only be test.js itself. It will simple run node with that
# filename as an argument. Stdout is dumped to a scratch buffer that
# automatically opens in a split window. If the scratch buffer already
# exists it will be updated.

# Dump stdout to scratch buffer
# vimhook.bufferoutput

# Whether or not to open in a vertical split (default horizontal)
# vimhook.bufferoutput.vsplit = false

node $1
