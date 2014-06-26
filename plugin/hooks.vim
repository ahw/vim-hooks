let s:globalHookFiles = {}
let s:extensionSpecificHookFiles = {}
let s:fileSpecificHookFiles = {}
let s:shouldEnableHooks = 1

function! StopExecutingHooks()
    let s:shouldEnableHooks = 0
endfunction

function! StartExecutingHooks()
    let s:shouldEnableHooks = 1
endfunction

function! s:shouldExecuteHooks()
    " &diff is the value of the diff/nodiff option (1 or 0, respectively)
    let isInDiffMode = &diff
    if s:shouldEnableHooks && !isInDiffMode
        return 1
    else
        return 0
    endif
endfunction

function! s:clearHookFiles()
    let s:globalHookFiles = {}
    let s:extensionSpecificHookFiles = {}
    let s:fileSpecificHookFiles = {}
endfunction

function! s:addHookFile(dict, eventname, primaryKey, hookfile)
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

function! s:findHookFiles()
    let cwd = fnamemodify('.', ':p')
    " Clear out the old dictionaries of hook files if they exist.
    call s:clearHookFiles()

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
                    call s:addHookFile(s:extensionSpecificHookFiles, eventname, ext, hookfile)
                else
                    " If the empty string is passed, this will become a
                    " global hook, which is what we want.
                    call s:addHookFile(s:globalHookFiles, eventname, "", hookfile)
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

                call s:addHookFile(s:fileSpecificHookFiles, eventname, filename, hookfile)
            endif
        endif
    endfor
endfunction

function! s:executeHookFiles(eventname)
    if !s:shouldExecuteHooks()
        " Return early
        return
    endif

    let eventname = tolower(a:eventname)
    " Get the filename without all the path stuff
    let filename = get(matchlist(getreg('%'), '\v([^/]+)$'), 1, "")
    let ext =  get(matchlist(filename, '\v\.(\a+)$'), 1, "")

    if has_key(s:fileSpecificHookFiles, filename)
        call s:executeHookFilesByEvent(s:fileSpecificHookFiles[filename], eventname)
    endif

    if has_key(s:extensionSpecificHookFiles, ext)
        call s:executeHookFilesByEvent(s:extensionSpecificHookFiles[ext], eventname)
    endif

    call s:executeHookFilesByEvent(s:globalHookFiles, eventname)
endfunction

function! s:executeHookFilesByEvent(dict, eventname)
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
    au VimEnter * call s:executeHookFiles('VimEnter')
    au VimLeave * call s:executeHookFiles('VimLeave')
    au BufEnter * call s:executeHookFiles('BufEnter')
    au BufLeave * call s:executeHookFiles('BufLeave')
    au BufDelete * call s:executeHookFiles('BufDelete')
    au BufUnload * call s:executeHookFiles('BufUnload')
    au BufWinLeave * call s:executeHookFiles('BufWinLeave')
    au BufWritePost * call s:executeHookFiles('BufWritePost')
    " au CursorHold * call s:executeHookFiles('CursorHold')
    " au CursorMoved * call s:executeHookFiles('CursorMoved')
aug END

" Immediately run the s:findHookFiles function.
call s:findHookFiles()
