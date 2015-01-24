#!/bin/sh

# This depends on having the Chrome Stay Fresh extension installed. See
# https://github.com/ahw/chrome-stay-fresh. Here's the first paragraph of
# the README for that repository:
# 
# Chrome Stay Fresh
# -----------------
# A Chrome extension for auto-reloading various tabs in the Chrome browser. It
# relies on the presence of a native messaging host which accepts HTTP
# requests on port 7700 and notifies the Chrome extension when those requests
# are made. The extension itself maintains a list of "listening" tabs which
# are automatically reloaded (i.e., "refreshed") whenever the native messaging
# host receives a GET /reload HTTP/1.1 request.

curl localhost:7700/reload
