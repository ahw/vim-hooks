runtime lib/vim-hook.vim
runtime lib/vim-hook-listing.vim
runtime lib/vim-hook-options.vim
let s:plugindir = expand('<sfile>:p:h:h')

let s:allVimHooks = []
let s:nextGlobalHookIndex = 0
let s:nextExtensionHookIndex = 0
let s:nextFilenameHookIndex = 0
let s:vimHooksByFilename = {}

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

function! s:isAnExecutableFile(filename)
    return getfperm(a:filename) =~ '\v^..x'
endfunction

function! s:clearHookFiles()
    let s:allVimHooks = []
    let s:vimHooksByFilename = {}
    let s:nextGlobalHookIndex = 0
    let s:nextExtensionHookIndex = 0
    let s:nextFilenameHookIndex = 0
endfunction

function! s:addHookFile(vimHook, ...)
    call g:VimHookListing.updateColumnWidths(a:vimHook)
    call sort(add(s:allVimHooks, a:vimHook), "s:compareVimHooks")
endfunction

function! s:findHookFiles()
    " Clear out the old dictionaries of hook files if they exist.
    call s:clearHookFiles()

    let files = split(glob("*") . "\n" . glob(".*") . "\n" . glob("~/.vimhooks/*") . "\n" . glob("~/.vimhooks/.*"), "\n")
    for hookfile in files
        let baseName = get(matchlist(hookfile, '\v[^/]+$'), 0, "")
        " Matches filenames that have the "vimhook" string anywhere inside
        " them, except for those that match the "ignoreable" regex (i.e.,
        " *.swp files).
        if baseName =~ 'vimhook' && !s:isIgnoreable(baseName)

            " This regex matches .[sortkey.][suffix.][eventname].vimhook,
            " where the leading ".", "sortkey.", and "suffix." are all
            " optional. After matching we will strip off the trailing "."
            " from sortkey and suffix.
            let matches = matchlist(baseName, '\v^\.?(\d+\.)?(.+\.)?(\w+)\.vimhook')
            let sortkey = substitute(get(matches, 1, ""), '\v\.$', '', '') " Remove trailing .
            let suffix = substitute(get(matches, 2, ""), '\v\.$', '', '') " Remove trailing .
            let eventname = get(matches, 3, "")
            call s:addHookFile(g:VimHook.New(hookfile, eventname, '\v.*' . suffix . '$'))

        endif
    endfor
endfunction

function! s:compareVimHooks(first, second)
    " From :help sort()
    " When {func} is a |Funcref| or a function name, this function is called
    " to compare items.  The function is invoked with two items as argument
    " and must return zero if they are equal, 1 or bigger if the first one
    " sorts after the second one, -1 or smaller if the first one sorts
    " before the second one.
    if a:first.baseName == a:second.baseName
        return 0
    elseif a:first.baseName < a:second.baseName
        return -1
    else
        return 1
endfunction

function! s:printErrorMessage(msg)
    echohl WarningMsg
    echo a:msg
    echohl None
endfunction

" Accepts a variable number of event names and executes the hook files
" corresponding to each. This will typically be called with a single
" event, unless the user manually calls :ExecuteHookFiles Event1, Event2.
" As a reminder, 
" a:0 => number of extra args
" a:1 => first extra arg
" a:2 => second extra arg
" a:000 => all the extra args in a List
function! s:executeHookFiles(...)
    let errorMessages = ""

    if !s:shouldExecuteHooks()
        " Return early if hooks have been manually disabled via :StopExecutingHooks
        return
    endif

    " The base filename. /path/to/some/file.txt => file.txt
    let filename = get(matchlist(getreg('%'), '\v([^/]+)$'), 1, "")
    if filename == ""
        " Return early if the filename is empty (e.g. when just running
        " "vim" without any arguments)
        return
    endif

    " If we do not yet have an associated list of VimHooks with this
    " filename, then create one by iterating through all the known VimHooks
    " and adding any of them whose pattern matches against this filename.
    if !has_key(s:vimHooksByFilename, filename)
        let s:vimHooksByFilename[filename] = []
        for vimHook in s:allVimHooks
            if filename =~ vimHook.pattern
                " Add this VimHook to the dictionary of vimhooks by
                " filename. This dictionary contains a key for each
                " unique filename (base name) we encounter and an
                " associated list of VimHooks. The list is kept in
                " sorted order according to the s:compareVimHooks
                " function, which just sorts them by their baseName
                " property.
                call sort(add(s:vimHooksByFilename[filename], vimHook), "s:compareVimHooks")
            endif
        endfor
    endif

    for eventname in a:000
        let eventname = tolower(eventname)
        let originalBufferName = getreg("%")
        let head = expand("%:h")
        let tail = expand("%:t")
        for vimHook in s:vimHooksByFilename[filename]
            if eventname ==? vimHook.event
                let errorMessages = errorMessages . s:executeVimHook(vimHook, originalBufferName, head, tail)
            endif
        endfor
    endfor

    if len(errorMessages)
        " Chop off the last newline character in the error messages
        let errorMessages = strpart(errorMessages, 0, len(errorMessages)-1)
        call s:printErrorMessage(errorMessages)
    endif
endfunction

function! s:executeVimHook(vimHook, originalBufferName, filenameHead, filenameTail)
    " filenameHead and filenameTail are the result of expand("%:h") and
    " expand("%:t"). They remove the last path component and then return the
    " last path component, respectively. See :help expand().

    let errorMessages = ""
    let tailWithoutExtension = get(matchlist(a:filenameTail, '\v^[^\.]+'), 0, "")
    let fullPathWithoutExtension = a:filenameHead . "/" . tailWithoutExtension
    let cmd = a:vimHook.path . ' ' . shellescape(a:originalBufferName) . ' ' . shellescape(a:vimHook.event) . ' ' . shellescape(fullPathWithoutExtension)
    if s:isAnExecutableFile(a:vimHook.path) && !a:vimHook.isIgnoreable && a:vimHook.isEnabled
        echom "[vim-hooks] Executing hookfile " . a:vimHook.baseName . " after event " . a:vimHook.event

        if a:vimHook.getOptionValue(g:VimHookOptions.BUFFER_OUTPUT.keyName)
            " Buffer output case. Dump stdout into a scratch buffer.

            let splitCommand = a:vimHook.getOptionValue(g:VimHookOptions.BUFFER_OUTPUT_VSPLIT.keyName) ? 'vnew' : 'new'
            let bufferFiletype = a:vimHook.getOptionValue(g:VimHookOptions.BUFFER_OUTPUT_FILETYPE.keyName)
            let bufferWrapMode =  a:vimHook.getOptionValue(g:VimHookOptions.BUFFER_OUTPUT_WRAP_MODE.keyName)
            let feedKeys = a:vimHook.getOptionValue(g:VimHookOptions.BUFFER_OUTPUT_FEEDKEYS.keyName)
            let winnr = bufwinnr('^' . a:vimHook.outputBufferName . '$')
            " If window doesn't exist, create a new one using
            " botright. If it does exist, just go to that
            " window number using :[n] wincmd w, which would
            " go to window n.
            execute winnr < 0 ? 'botright ' . splitCommand . ' ' . a:vimHook.outputBufferName : winnr . 'wincmd w'
            setlocal buftype=nowrite
            setlocal bufhidden=wipe
            setlocal nobuflisted
            setlocal noswapfile
            setlocal nowrap
            setlocal number
            if len(bufferFiletype)
                echom "[vim-hooks] output buffer setlocal filetype=" . bufferFiletype
                execute 'setlocal filetype=' . bufferFiletype
            endif

            " This logic controls calling "set wrap" or "set nowrap". SHould
            " probably be generalized to support setting arbitrary buffer
            " options.
            if len(bufferWrapMode)
                echom "[vim-hooks] output buffer setlocal " . bufferWrapMode
                if bufferWrapMode == 'wrap'
                    execute 'setlocal wrap'
                elseif bufferWrapMode == 'nowrap'
                    execute 'setlocal nowrap'
                endif
            endif

            execute 'silent %!' . cmd

            " Press some keys to get rid of the Press ENTER prompt
            call feedkeys('lh')

            if type(feedKeys) == type("") && len(feedKeys)
                let originalBufferWindow = bufwinnr(a:originalBufferName)
                let outputBufferWindow = bufwinnr(a:vimHook.outputBufferName)
                execute outputBufferWindow . 'wincmd w'
                echom "[vim-hooks] sending keys in Normal mode to output buffer: " . feedKeys
                execute "normal  " . feedKeys
                execute originalBufferWindow . 'wincmd w'
            else
            endif

        else
            let async = a:vimHook.getOptionValue(g:VimHookOptions.ASYNC.keyName)
            let wait = a:vimHook.getOptionValue(g:VimHookOptions.DEBOUNCE_WAIT.keyName)

            if async
                let cmd = cmd . ' &'
            elseif wait
                let cmd = s:plugindir . '/bin/debounce ' . wait . ' ' . cmd . ' &'
            endif

            let stdOutErr = system(cmd)
            if (v:shell_error != 0)
                let errorMessages = errorMessages . "[vim-hooks] Script " . a:vimHook.baseName . " exited with error code " . v:shell_error . "\n"
                let errorMessages = errorMessages . "[vim-hooks] Printing stdout and stderr below:\n"
                let errorMessages = errorMessages . join(map(split(stdOutErr, "\n"), '"> " . v:val'), "\n") . "\n\n"
            endif
            redraw!
        endif
    elseif !a:vimHook.isIgnoreable && a:vimHook.isEnabled
        " Assert: hookfile is not executable, but also not
        " ignoreable. Prompt user to set executable bit or to
        " start ignoring.
        echohl WarningMsg
        echo "[vim-hooks] Could not execute script " . a:vimHook.path . " because it does not have \"execute\" permissions.\nSet executable bit (chmod u+x) [yn]? "
        let key = nr2char(getchar())
        if key ==# 'y'
            echom "[vim-hooks] Running chmod u+x " . a:vimHook.path
            execute "!chmod u+x " . a:vimHook.path
        elseif key ==# 'n'
            call a:vimHook.ignore()
        endif
        echohl None

        " Now call this function again. Hopefully we don't mess up the logic
        " here or it will loop infinitely.
        call s:executeVimHook(a:vimHook, a:originalBufferName, a:filenameHead, a:filenameTail)
    else
        " Assert: we're ignoring this file.
    endif
    return errorMessages
endfunction

function! s:listVimHooks()
    let windowNumber = bufwinnr("VimHooks Listing")
    if bufwinnr("VimHooks Listing") == -1
        call s:openVimHookListingBuffer()
    else
        echo "VimHooks Listing buffer already open! Doing nothing."
    endif
endfunction

function! s:openVimHookListingBuffer(...)
    let width = 50
    if a:0 == 1 && type(a:1) == type(0)
        " If number of extra args is 1 and the first extra arg is a Number
        let width = a:1
    endif
    execute 'new VimHooks\ Listing'
    setlocal buftype=nowrite
    setlocal bufhidden=delete
    setlocal noswapfile
    setlocal nobuflisted
    setlocal nospell
    setlocal modifiable
    set nowrap
    setfiletype hooks

    let @t = g:VimHookListing.getVimHookListingText(s:allVimHooks)
    silent put t
    execute "0"
    execute "delete"
    execute g:VimHookListing.lowestLine
    call feedkeys('0')
    setlocal nomodifiable

    "call g:VimHookListing.handleKeys()
endfunction

function! s:createBlankVimHook(eventname, ...)
    " Get the base filename (strip leading path part)
    let filename = get(matchlist(getreg("%"), '\v[^/]+$'), 0, "")
    let newHookName = filename . "." . tolower(a:eventname) . ".vimhook.sh"
    let splitCommand = "vsp"

    " Default the pattern to the filename
    let pattern = filename
    if a:0 == 1 && type(a:1) == type("")
        " If number of extra args is 1 and the first extra arg is a String
        let pattern = a:1
    endif

    execute 'botright ' . splitCommand . ' ' . newHookName
    " Manually add this hook file
    call s:addHookFile(g:VimHook.New(newHookName, a:eventname, '\v^' . pattern . '$'))
endfunction

function! s:createSelfHook(eventname, ...)
    " Get the base filename (strip leading path part)
    let filename = get(matchlist(getreg("%"), '\v[^/]+$'), 0, "")
    let splitCommand = "vsp"

    " Default the pattern to the filename
    let pattern = filename
    if a:0 == 1 && type(a:1) == type("")
        " If number of extra args is 1 and the first extra arg is a String
        let pattern = a:1
    endif

    let newVimHook = g:VimHook.New(filename, a:eventname, '\v^' . pattern . '$')
    call s:addHookFile(newVimHook)
    call sort(add(s:vimHooksByFilename[filename], newVimHook), "s:compareVimHooks")
endfunction


"Create an autocmd group
aug VimHookGroup
    "Clear the augroup. Otherwise Vim will combine them.
    au!
    au BufAdd * call s:executeHookFiles('BufAdd')
    au BufNew * call s:executeHookFiles('BufNew')
    au VimEnter * call s:executeHookFiles('VimEnter')
    au VimLeave * call s:executeHookFiles('VimLeave')
    au BufEnter * call s:executeHookFiles('BufEnter')
    au BufLeave * call s:executeHookFiles('BufLeave')
    au BufDelete * call s:executeHookFiles('BufDelete')
    au BufUnload * call s:executeHookFiles('BufUnload')
    au BufWinLeave * call s:executeHookFiles('BufWinLeave')
    au BufWritePost * call s:executeHookFiles('BufWritePost')
    au BufReadPost * call s:executeHookFiles('BufReadPost')
    " au CursorHold * call s:executeHookFiles('CursorHold')
    " au CursorMoved * call s:executeHookFiles('CursorMoved')
aug END

" Set up key mappings specifically for the :ListVimHooks buffer
aug VimHookListingGroup
    au!
    au FileType hooks nnoremap <silent> <buffer> x    :call g:VimHookListing.toggleLine()<cr>
    au FileType hooks nnoremap <silent> <buffer> i    :call g:VimHookListing.openLineInHorizontalSplit()<cr>
    au FileType hooks nnoremap <silent> <buffer> s    :call g:VimHookListing.openLineInVerticalSplit()<cr>
    au FileType hooks nnoremap <silent> <buffer> o    :call g:VimHookListing.openLineInPreviousWindow()<cr>
    au FileType hooks nnoremap <silent> <buffer> d    :call g:VimHookListing.deleteLine()<cr>
    au FileType hooks nnoremap <silent> <buffer> r    :call g:VimHookListing.runLineSynchronously()<cr>
    au FileType hooks nnoremap <silent> <buffer> <cr> :call g:VimHookListing.openLineInCurrentWindow()<cr>
    " These existed in early version of the plugin
    " au FileType hooks nnoremap <silent> <buffer> q :call g:VimHookListing.exitBuffer()<cr>
    " au FileType hooks nnoremap <silent> <buffer> <esc> :call g:VimHookListing.exitBuffer()<cr>
aug END

" Immediately run the s:findHookFiles function.
call <SID>findHookFiles()
" Re-run s:findHookFiles whenever *vimhook* files are written.
augroup vimhooks
    au!
    au BufWritePost *vimhook* call <SID>findHookFiles()
augroup END


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

command! -nargs=+ -complete=event CreateNewVimHook call <SID>createBlankVimHook(<f-args>)
command! -nargs=+ -complete=event CreateSelfHook call <SID>createSelfHook(<f-args>)
