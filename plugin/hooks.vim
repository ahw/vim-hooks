let s:hookFiles = {}

function! FindHookFiles()
    " Clear out the old dictionary of hook files if it exists.
    let s:hookFiles = {}
    let files = split(glob("*") . "\n" . glob(".*"), "\n")
    for filename in files
        " Matches filenames that start with "." and are of the form
        " [.sortkey].eventname.vimhook. Use a very-magic regex. See :help magic.
        if filename =~ '\v^\..+\.vimhook'
            " This match will put filename in the 0th position, "sortkey" in
            " the 1th position if it exists and "eventname" in the 2nd
            " position.
            " let matches =  matchlist(filename, '\v\.?(.*)\.(.+)\.vimhook')

            " This match will put the filename in the 0th position and
            " "eventname" in the 1th position
            let eventName = matchlist(filename, '\v(\a+)\.vimhook$')[1]
            let eventName = tolower(eventName)

            if !has_key(s:hookFiles, eventName)
                let s:hookFiles[eventName] = [filename]
            else
                call add(s:hookFiles[eventName], filename)
            endif
            " let s:hookFiles[eventName] = filename
        endif
    endfor
endfunction

function! ExecuteHookFiles(eventName)
    let eventName = tolower(a:eventName)
    if has_key(s:hookFiles, eventName)
        for filename in s:hookFiles[eventName]
            echo "> Executing " . filename . " for event " . eventName
            " execute 'silent !./' . filename
        endfor
    endif
endfunction

"Create an autocmd group
aug HookGroup
    "Clear the RefreshGroup augroup. Otherwise Vim will combine them.
    au!
    au BufWritePost * call ExecuteHookFiles('BufWritePost')
    au CursorHold * call ExecuteHookFiles('CursorHold')
    " au CursorMoved * call ExecuteHookFiles('CursorMoved')
aug END

" Immediately run the FindHookFiles function.
call FindHookFiles()
