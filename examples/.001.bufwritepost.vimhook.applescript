#!/usr/bin/osascript
#
tell application "Safari"
    activate
    tell application "System Events" to keystroke "r" using command down
end tell

tell application "Firefox"
    activate
    tell application "System Events" to keystroke "r" using command down
end tell

# tell application "Chrome"
#     activate
#     tell application "System Events" to keystroke "r" using command down
# end tell

tell application "iTerm"
    activate
end tell
