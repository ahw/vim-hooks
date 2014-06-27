let s:globalHookFiles = {}
let s:extensionSpecificHookFiles = {}
let s:fileSpecificHookFiles = {}

function! ClearHookFiles()
    let s:globalHookFiles = {}
    let s:extensionSpecificHookFiles = {}
    let s:fileSpecificHookFiles = {}
endfunction

function! AddHookFile(dict, eventname, primaryKey, hookfile)
    if len(a:primaryKey)
        if !has_key(a:dict, a:primaryKey)
            let a:dict[a:primaryKey] = {}
        endif

        if !has_key(a:dict[a:primaryKey], a:eventname)
            let a:dict[a:primaryKey][a:eventname] = []
        endif

        " Make sure the list stays sorted
        call sort(add(a:dict[a:primaryKey][a:eventname], a:hookfile))
    else
        if !has_key(a:dict, a:eventname)
            let a:dict[a:eventname] = []
        endif

        " Make sure the list stays sorted
        call sort(add(a:dict[a:eventname], a:hookfile))
    endif
endfunction

function! FindHookFiles()
    " Clear out the old dictionaries of hook files if they exist.
    call ClearHookFiles()

    let files = split(glob("*") . "\n" . glob(".*") . "\n" . glob("~/.vimhooks/*") . "\n" . glob("~/.vimhooks/.*"), "\n")
    for hookfile in files
        " Matches filenames that have the ".vimhook" string anywhere inside
        " them.  Uses a very-magic regex. See :help magic.
        if hookfile =~ '\v\.vimhook'
            if hookfile =~ '\v^\.'
                " Hidden file case
                "   .bufwritepost.vimhook
                "   .123.bufwritepost.vimhook.sh
                "   .bufwritepost.scss.vimhook.sh
                "
                " This regex matches
                " [.sortkey].eventname[.ext].vimhook[.trailing.chars].  This
                " match will put the entire hookfile in the 0th position,
                " "sortkey" in the 1st position, "eventname" in the 2nd
                " position, "ext" in the 3rd position, and whatever follows
                " "vimhook" (the trailing characters) in the 4th position.
                let hiddenFileMatches =  matchlist(hookfile, '\v^\.?(\d*)\.(\a+)\.?(.*)\.vimhook(.*)')

                let eventname = get(hiddenFileMatches, 2, "")
                let ext = get(hiddenFileMatches, 3, "")
                let trailingChars = get(hiddenFileMatches, 4, "")

                if len(ext)
                    call AddHookFile(s:extensionSpecificHookFiles, eventname, ext, hookfile)
                else
                    " If the empty string is passed, this will become a
                    " global hook, which is what we want.
                    call AddHookFile(s:globalHookFiles, eventname, "", hookfile)
                endif

            else
                " Normal (i.e., not hidden) file case. Intended for when
                " user wants to only react to events associated with a
                " single file.
                "   styles.scss.bufwritepost.vimhook
                "   app.coffee.bufwritepost.vimhook
                "   index.html.bufwritepost.vimhook
                "
                " This regex matches
                " [filename.ext].eventname.vimhook[.trailing.chars]. The
                " match will put the entire hookfile in the 0th position,
                " the desired filename to react to in the 1st position, the
                " eventname in the 2nd position, and whatever is left over
                " in the 3rd position
                let singleFileMatches = matchlist(hookfile, '\v^(.+)\.(\a+)\.vimhook')
                let filename = get(singleFileMatches, 1, "")
                let eventname = get(singleFileMatches, 2, "")
                let trailingChars = get(singleFileMatches, 3, "")

                call AddHookFile(s:fileSpecificHookFiles, eventname, filename, hookfile)
            endif
        endif
    endfor
endfunction

function! ExecuteHookFiles(eventname)
    let eventname = tolower(a:eventname)
    " Get the filename without all the path stuff
    let filename = get(matchlist(getreg('%'), '\v([^/]+)$'), 1, "")
    let ext =  get(matchlist(filename, '\v\.(\a+)$'), 1, "")

    if has_key(s:fileSpecificHookFiles, filename)
        call ExecuteHookFilesByEvent(s:fileSpecificHookFiles[filename], eventname)
    endif

    if has_key(s:extensionSpecificHookFiles, ext)
        call ExecuteHookFilesByEvent(s:extensionSpecificHookFiles[ext], eventname)
    endif

    call ExecuteHookFilesByEvent(s:globalHookFiles, eventname)
endfunction

function! ExecuteHookFilesByEvent(dict, eventname)
    if has_key(a:dict, a:eventname)
        for hookfile in a:dict[a:eventname]
            if getfperm(hookfile) =~ '\v^..x'
                echom "[vim-hooks] Executing hookfile " . hookfile . " after event " . a:eventname
                execute 'silent !./' . hookfile . ' ' . shellescape(getreg('%')) . ' ' . shellescape(a:eventname)
                redraw!
            else
                echohl WarningMsg
                echom "[vim-hooks] Could not execute script " . hookfile . " because it does not have \"execute\" permissions"
                echo  "[vim-hooks] Could not execute script " . hookfile . " because it does not have \"execute\" permissions"
                echohl None
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
    au BufWritePost * call ExecuteHookFiles('BufWritePost')
    " au CursorHold * call ExecuteHookFiles('CursorHold')
    " au CursorMoved * call ExecuteHookFiles('CursorMoved')
aug END

" Immediately run the FindHookFiles function.
call FindHookFiles()
