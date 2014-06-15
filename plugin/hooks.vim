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
            " "eventname" in the 1th position. Use the get function to avoid
            " invalid index errors and to return "" by default.
            let eventName = tolower(get(matchlist(filename, '\v(\a+)\.vimhook$'), 1, ""))
            if !has_key(s:hookFiles, eventName)
                let s:hookFiles[eventName] = [filename]
            else
                " Make sure the list stays sorted
                call sort(add(s:hookFiles[eventName], filename))
            endif
        endif
    endfor
endfunction

function! ExecuteHookFiles(eventName)
    let eventName = tolower(a:eventName)
    if has_key(s:hookFiles, eventName)
        for filename in s:hookFiles[eventName]
            if getfperm(filename) =~ '\v^..x'
                echom "[vim-hooks] Executing " . filename . " for event " . eventName
                execute 'silent !./' . filename
                redraw!
            else
                echohl WarningMsg | echo "[vim-hooks] Could not execute script " . filename . " because it does not have \"execute\" permissions"
            endif
        endfor
    endif
endfunction

"Create an autocmd group
aug HookGroup
    "Clear the augroup. Otherwise Vim will combine them.
    au!
    au VimEnter * call ExecuteHookFiles('VimEnter')
    au VimLeave * call ExecuteHookFiles('VimLeave')
    au BufEnter * call ExecuteHookFiles('BufEnter')
    au BufLeave * call ExecuteHookFiles('BufLeave')
    au CursorHold * call ExecuteHookFiles('CursorHold')
    au BufWritePost * call ExecuteHookFiles('BufWritePost')
    " au CursorMoved * call ExecuteHookFiles('CursorMoved')
aug END

" Immediately run the FindHookFiles function.
call FindHookFiles()
