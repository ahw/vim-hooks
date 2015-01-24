#!/bin/sh

# This VimHook 
PID=`ps aux | grep "jekyll serve" | grep ruby | egrep -o "^${USER}\s+(\d+)" | egrep -o "\d+"`
echo "Killing pid ${PID}"
kill $PID
jekyll serve &> /dev/null &
# Give the server time to get up and running, assuming you have a Chrome
# reloader hook following this one (otherwise you might reload your page
# before the server is ready to respond).
sleep 3
