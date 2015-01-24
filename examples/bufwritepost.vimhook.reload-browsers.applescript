#!/usr/bin/osascript

# This VimHook uses a really crude bit of AppleScript to get Safari and
# Firefox to reload the current active tab. It responds to BufWritePost
# events from all files.

tell application "Safari"
    activate
    tell application "System Events" to keystroke "r" using command down
end tell

tell application "Firefox"
    activate
    tell application "System Events" to keystroke "r" using command down
end tell

# I have a separate Chrome extension for auto-reloading tabs. It's a little
# more involved to set up, but well worth it in my opinion. Nevertheless, if
# you just want something quick and dirty you can uncomment this section.
# Chrome Stay Fresh: https://github.com/ahw/chrome-stay-fresh
#
# tell application "Chrome"
#     activate
#     tell application "System Events" to keystroke "r" using command down
# end tell

tell application "iTerm"
    activate
end tell
