let s:globalHookFiles = {}
let s:extensionSpecificHookFiles = {}
let s:fileSpecificHookFiles = {}
let s:shouldEnableHooks = 1

function! s:stopExecutingHooks()
    let s:shouldEnableHooks = 0
endfunction

function! s:startExecutingHooks()
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

let s:ignoreableFilesRegexList = ['\vswp$', '\v^/\.\.?$']

function! s:isIgnoreable(name)
    " This function expects the name argument to be the base name of a file.
    " It will not work correctly if we pass in an absolute path to a file.
    for regex in s:ignoreableFilesRegexList
        if a:name =~ regex
            return 1
        endif
    endfor
    return 0
endfunction

function! s:clearHookFiles()
    let s:globalHookFiles = {}
    let s:extensionSpecificHookFiles = {}
    let s:fileSpecificHookFiles = {}
endfunction

function! s:addHookFile(dict, eventname, primaryKey, hookfile)
    if len(a:primaryKey)
        if !has_key(a:dict, a:primaryKey)
            " Add to the dictionary of file-specific hooks
            let a:dict[a:primaryKey] = {}
        endif

        if !has_key(a:dict[a:primaryKey], a:eventname)
            " Add to the dictionary of extension-specific hooks
            let a:dict[a:primaryKey][a:eventname] = []
        endif

        " Make sure the list stays sorted
        call sort(add(a:dict[a:primaryKey][a:eventname], a:hookfile))
    else
        if !has_key(a:dict, a:eventname)
            " Add to the dictionary of global hooks
            let a:dict[a:eventname] = []
        endif

        " Make sure the list stays sorted
        call sort(add(a:dict[a:eventname], a:hookfile))
    endif
endfunction

function! s:findHookFiles()
    " Clear out the old dictionaries of hook files if they exist.
    call s:clearHookFiles()

    let files = split(glob("*") . "\n" . glob(".*") . "\n" . glob("~/.vimhooks/*") . "\n" . glob("~/.vimhooks/.*"), "\n")
    for hookfile in files
        let baseName = get(matchlist(hookfile, '\v[^/]+$'), 0, "")
        " Matches filenames that have the ".vimhook" string anywhere inside
        " them, except for those that match the "ignoreable" regex (i.e.,
        " *.swp files). Uses a very-magic regex. See :help magic.
        if baseName =~ '\v\.vimhook' && !s:isIgnoreable(baseName)
            if baseName =~ '\v^\.'
                " Hidden file case
                "   .bufwritepost.vimhook
                "   .123.bufwritepost.vimhook.sh
                "   .bufwritepost.scss.vimhook.sh
                "
                " This regex matches
                " [.sortkey].eventname[.ext].vimhook[.trailing.chars].  This
                " match will put the entire hookfile in the 0th position,
                " "sortkey" in the 1st position, "eventname" in the 2nd
                " position, and "ext" in the 3rd position.
                let hiddenFileMatches =  matchlist(baseName, '\v^\.?(\d*)\.(\a+)\.?(.*)\.vimhook')

                let eventname = get(hiddenFileMatches, 2, "")
                let ext = get(hiddenFileMatches, 3, "")

                if len(ext)
                    call s:addHookFile(s:extensionSpecificHookFiles, eventname, ext, hookfile)
                else
                    " If the empty string is passed, this will become a
                    " global hook, which is what we want.
                    call s:addHookFile(s:globalHookFiles, eventname, "", hookfile)
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
                " the desired filename to react to in the 1st position, and
                " the eventname in the 2nd position.
                let singleFileMatches = matchlist(baseName, '\v^(.+)\.(\a+)\.vimhook')
                let filename = get(singleFileMatches, 1, "")
                let eventname = get(singleFileMatches, 2, "")

                call s:addHookFile(s:fileSpecificHookFiles, eventname, filename, hookfile)
            endif
        endif
    endfor
endfunction

function! s:executeHookFiles(...)
    if !s:shouldExecuteHooks()
        " Return early if hooks have been manually disabled via :StopExecutingHooks
        return
    endif
    " Accepts a variable number of event names and executes the hook files
    " corresponding to each. This will typically be called with a single
    " event, unless the user manually calls :ExecuteHookFiles Event1, Event2.
    " As a reminder, 
    " a:0 => number of extra args
    " a:1 => first extra arg
    " a:2 => second extra arg
    " a:000 => all the extra args in a List

    for eventname in a:000
        let eventname = tolower(eventname)
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
    endfor
endfunction

function! s:executeHookFilesByEvent(dict, eventname)
    if has_key(a:dict, a:eventname)
        for hookfile in a:dict[a:eventname]
            if getfperm(hookfile) =~ '\v^..x'
                echom "[vim-hooks] Executing hookfile " . hookfile . " after event " . a:eventname
                if hookfile !~ '\v^/'
                    " If the hookfile is in the current working directory
                    " then prepend a ./ to it to allow execution. If the
                    " hookfile name starts with a leading slash then do
                    " nothing.
                    let hookfile = './' . hookfile
                endif

                execute 'silent !' . hookfile . ' ' . shellescape(getreg('%')) . ' ' . shellescape(a:eventname)
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

" Define commands
" Find all hook files in the current working directory
command! -nargs=0 FindHookFiles call <SID>findHookFiles()
" Manually execute hook files corresponding to whichever events are given as
" the arguments to this function. Will autocomplete event names. Example:
" :ExecuteHookFiles BufWritePost VimLeave. Currently only executes the
" global hook files.
command! -nargs=+ -complete=event ExecuteHookFiles call <SID>executeHookFiles(<f-args>)

command! -nargs=0 StopExecutingHooks call <SID>stopExecutingHooks()
command! -nargs=0 StartExecutingHooks call <SID>startExecutingHooks()
