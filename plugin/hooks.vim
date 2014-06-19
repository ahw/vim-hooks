let s:globalHookFiles = {}
let s:extensionSpecificHookFiles = {}
let s:filenameSpecificHookFiles = {}

function! ClearHookFiles()
    let s:globalHookFiles = {}
    let s:extensionSpecificHookFiles = {}
    let s:filenameSpecificHookFiles = {}
endfunction

" function! AddHookFile(dict, eventname, filename)
"     if !has_key(dict, eventname)
"         let dict[eventname] = [filename]
"     else
"         " Make sure the list stays sorted
"         call sort(add(dict[eventname], filename))
"     endif
" endfunction

function! FindHookFiles()
    " Clear out the old dictionaries of hook files if they exist.
    call ClearHookFiles()

    let files = split(glob("*") . "\n" . glob(".*") . "\n" . glob("~/.vimhooks/*") . "\n" . glob("~/.vimhooks/.*"), "\n")
    for hookfile in files
        " Matches filenames that end with .vimhook. Uses a very-magic regex.
        " See :help magic.
        if hookfile =~ '\v\.vimhook$'
            if hookfile =~ '\v^\.'
                " Hidden file case
                "   .bufwritepost.vimhook
                "   .123.bufwritepost.vimhook
                "   .bufwritepost.scss.vimhook
                "
                " This regex matches [.sortkey].eventname[.ext].vimhook.  This
                " match will put the entire hookfile in the 0th position,
                " "sortkey" in the 1st position, "eventname" in the 2nd
                " position, "ext" in the 3rd position.
                let hiddenFileMatches =  matchlist(hookfile, '\v^\.?(\d*)\.(\a+)\.?(.*)\.vimhook')
                " Do not actually need this: let sortkey = get(hiddenFileMatches, 1, "")
                let eventname = get(hiddenFileMatches, 2, "")
                let ext = get(hiddenFileMatches, 3, "")

                if len(ext)
                    if !has_key(s:extensionSpecificHookFiles, ext)
                        let s:extensionSpecificHookFiles[ext] = {}
                    endif

                    if !has_key(s:extensionSpecificHookFiles[ext], eventname)
                        let s:extensionSpecificHookFiles[ext][eventname] = []
                    endif

                    " Make sure the list stays sorted
                    call sort(add(s:extensionSpecificHookFiles[ext][eventname], hookfile))

                else
                    if !has_key(s:globalHookFiles, eventname)
                        let s:globalHookFiles[eventname] = []
                    endif

                    " Make sure the list stays sorted
                    call sort(add(s:globalHookFiles[eventname], hookfile))
                endif

            elseif hookfile =~ '\vvimhook$'
                " Normal file case. Intended for one user wants to only
                " react to events associated with a single file.
                "   styles.scss.bufwritepost.vimhook
                "   app.coffee.bufwritepost.vimhook
                "   index.html.bufwritepost.vimhook
                "
                " This regex matches [filename.ext].eventname.vimhook. The match
                " will put the entire hookfile in the 0th position, the
                " desired filename to react to in the 1st position and
                " "eventname" in the 2nd position.
                let singleFileMatches = matchlist(hookfile, '\v^(.+)\.(\a+)\.vimhook')
                let filename = get(singleFileMatches, 1, "")
                let eventname = get(singleFileMatches, 2, "")

                if !has_key(s:filenameSpecificHookFiles, filename)
                    let s:filenameSpecificHookFiles[filename] = {}
                endif

                if !has_key(s:filenameSpecificHookFiles[filename], eventname)
                    let s:filenameSpecificHookFiles[filename][eventname] = []
                endif

                " Make sure the list stays sorted
                call sort(add(s:filenameSpecificHookFiles[filename][eventname], hookfile))

            endif

        endif

    endfor

    echo s:extensionSpecificHookFiles
endfunction

function! ExecuteHookFiles(eventname)
    let eventname = tolower(a:eventname)
    if has_key(s:globalHookFiles, eventname)
        for filename in s:globalHookFiles[eventname]
            if getfperm(filename) =~ '\v^..x'
                echom "[vim-hooks] Executing " . filename . " for event " . eventname
                execute 'silent !./' . filename . ' ' . shellescape(getreg('%')) . ' ' . shellescape(eventname)
                redraw!
            else
                echohl WarningMsg
                echom "[vim-hooks] Could not execute script " . filename . " because it does not have \"execute\" permissions"
                echo  "[vim-hooks] Could not execute script " . filename . " because it does not have \"execute\" permissions"
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
    au CursorHold * call ExecuteHookFiles('CursorHold')
    au BufWritePost * call ExecuteHookFiles('BufWritePost')
    " au CursorMoved * call ExecuteHookFiles('CursorMoved')
aug END

" Immediately run the FindHookFiles function.
call FindHookFiles()
