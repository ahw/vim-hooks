runtime lib/vim-hook.vim
runtime lib/vim-hook-listing.vim

let s:patternBasedVimHooks = {}

" Flag to toggle hook execution globally
let s:shouldEnableHooks = 1

" Ignore swap files, the . and .. entries, and the ~/.vimhooks/ directory
let s:ignoreableFilesRegexList = ['\vswp$', '\v^/\.\.?$', '\v\.vimhooks']

" Keep a set of ignoreable hook files
let s:ignoreableHookFiles = {}

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

function! s:isIgnoreable(baseName)
    " This function expects the baseName argument to be the base name of a file.
    " It will not work correctly if we pass in an absolute path to a file.
    for regex in s:ignoreableFilesRegexList
        if a:baseName =~ regex
            return 1
        endif
    endfor
    return 0
endfunction

function! s:addIgnoreableHookFile(hookfile)
    let s:ignoreableHookFiles[a:hookfile] = 1
endfunction

function! s:isIgnoreableHookFile(hookfile)
    if has_key(s:ignoreableHookFiles, a:hookfile)
        return 1
    else
        return 0
    endif
endfunction

function! s:isAnExecutableFile(filename)
    return getfperm(a:filename) =~ '\v^..x'
endfunction

function! s:clearHookFiles()
    let s:globalHookFiles = {}
    let s:extensionSpecificHookFiles = {}
    let s:fileSpecificHookFiles = {}
endfunction

function! s:addHookFile(vimHook)
    if !has_key(s:patternBasedVimHooks, a:vimHook.event)
        let s:patternBasedVimHooks[a:vimHook.event] = {}
    endif

    if !has_key(s:patternBasedVimHooks[a:vimHook.event], a:vimHook.pattern)
        let s:patternBasedVimHooks[a:vimHook.event][a:vimHook.pattern] = {}
    endif

    let s:patternBasedVimHooks[a:vimHook.event][a:vimHook.pattern][a:vimHook.id] = a:vimHook
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
                    call s:addHookFile(g:VimHook.New(hookfile, eventname, '\v.*\.' . ext))
                else
                    " If the empty string is passed, this will become a
                    " global hook, which is what we want.
                    call s:addHookFile(g:VimHook.New(hookfile, eventname, '\v.*'))
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

                call s:addHookFile(g:VimHook.New(hookfile, eventname, '\v^' . filename . '$'))
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

        if has_key(s:patternBasedVimHooks, eventname)
            for pattern in keys(s:patternBasedVimHooks[eventname])
                if filename =~ pattern
                    for vimHookId in keys(s:patternBasedVimHooks[eventname][pattern])
                        let vimHook = s:patternBasedVimHooks[eventname][pattern][vimHookId]
                        if s:isAnExecutableFile(vimHook.path) && !s:isIgnoreableHookFile(vimHook.path) && vimHook.isEnabled
                            echom "[vim-hooks] Executing hookfile " . vimHook.path . " after event " . vimHook.event
                            execute 'silent !' . vimHook.path . ' ' . shellescape(getreg('%')) . ' ' . shellescape(vimHook.event)
                            redraw!
                        elseif !s:isIgnoreableHookFile(vimHook.path) && vimHook.isEnabled
                            " Assert: hookfile is not executable, but also not
                            " ignoreable. Prompt user to set executable bit or to start
                            " ignoring.
                            echohl WarningMsg
                            echo "[vim-hooks] Could not execute script " . vimHook.path . " because it does not have \"execute\" permissions.\nSet executable bit (chmod u+x) [yn]? "
                            let key = nr2char(getchar())
                            if key ==# 'y'
                                echom "Running chmod u+x " . vimHook.path
                                execute "!chmod u+x " . vimHook.path
                            elseif key ==# 'n'
                                call s:addIgnoreableHookFile(vimHook.path)
                            endif
                            echohl None
                        else
                            " Assert: we must be ignoring this file or it is permanently
                            " disabled. Do nothing.
                        endif
                    endfor
                endif
            endfor
        endif
    endfor
endfunction


function! s:listVimHooks()
    call s:openVimHookListingBuffer()
endfunction

function! s:createMarkdownHeaderText(header, level)
    let underline = ""
    if a:level == 1
        let underline = "="
    elseif a:level == 2
        let underline = "-"
    endif

    return a:header . "\n" . repeat(underline, len(a:header))
endfunction

function! s:openVimHookListingBuffer(...)
    let width = 50
    if a:0 == 1 && type(a:1) == type(0)
        " If number of extra args is 1 and the first extra arg is a Number
        let width = a:1
    endif
    execute "new"
    execute "setlocal buftype=nowrite"
    execute "setlocal bufhidden=delete"
    execute "setlocal noswapfile"
    execute "setlocal nobuflisted"
    execute "set nowrap"
    setfiletype hooks

    let @t = g:VimHookListing.getVimHookListingText(s:patternBasedVimHooks)
    silent put t
    execute "0"
    execute "delete"
    execute g:VimHookListing.lowestLine

    call g:VimHookListing.handleKeys()
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
    au CursorHold * call s:executeHookFiles('CursorHold')
    " au CursorMoved * call s:executeHookFiles('CursorMoved')
aug END

" Immediately run the s:findHookFiles function.
call <SID>findHookFiles()

" Find all hook files in the current working directory
command! -nargs=0 FindHookFiles call <SID>findHookFiles()

" Manually execute hook files corresponding to whichever events are given as
" the arguments to this function. Will autocomplete event names. Example:
" :ExecuteHookFiles BufWritePost VimLeave. Currently only executes the
" global hook files.
command! -nargs=+ -complete=event ExecuteHookFiles call <SID>executeHookFiles(<f-args>)

" Manually start and stop executing hooks
command! -nargs=0 StopExecutingHooks call <SID>stopExecutingHooks()
command! -nargs=0 StartExecutingHooks call <SID>startExecutingHooks()

" Pretty-print a list of all the vimhook dictionaries for debugging
command! -nargs=0 ListVimHooks call <SID>listVimHooks()
