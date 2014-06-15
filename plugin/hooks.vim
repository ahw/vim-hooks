function! FindHookFiles(...)
    let numEventNames = a:0
    let eventNames = a:000
    let files = split(glob("*") . "\n" . glob(".*"), "\n")
    let hookFiles = []
    for filename in files
        for eventName in eventNames
            if filename =~ "." . tolower(eventName) . ".vimhook"
                call add(hookFiles, filename)
            endif
        endfor
    endfor
    echo hookFiles
    return hookFiles
endfunction

function! SimpleEcho(name)
    echo 'Hi there ' . a:name
endfunction

"Create an autocmd group
aug HookGroup
    "Clear the RefreshGroup augroup. Otherwise Vim will combine them.
    au!
    au BufWritePost * call FindHookFiles('BufWritePost')
    " au CursorMoved * call SimpleEcho('CursorMoved')
    " au CursorHold * call SimpleEcho('CursorHold')
aug END
