"CLASS: VimHookListing

let s:VimHookListing = {}
let g:VimHookListing = s:VimHookListing

let s:VimHookListing.lineNumbersToVimHooks = {}
let s:VimHookListing.lowestLine = 0
let s:VimHookListing.highestLine = 0
let s:VimHookListing.columnWidths = { 'pattern': 0, 'event': 0, 'path': 0 }

function! s:VimHookListing.pad(s, amt)
    return a:s . repeat(' ', a:amt - len(a:s))
endfunction

function! s:VimHookListing.joinWithNewline(lines, anotherLine)
    return a:lines . "\n" . a:anotherLine
endfunction

function! s:VimHookListing.updateColumnWidths(vimHook)
    let self.columnWidths['pattern'] = max([len(a:vimHook.unixStylePattern), self.columnWidths['pattern']])
    let self.columnWidths['event'] = max([len(a:vimHook.event), self.columnWidths['event']])
    let self.columnWidths['path'] = max([len(a:vimHook.path), self.columnWidths['path']])
endfunction

function! s:VimHookListing.isCheckboxLine(num)
    let line = getline(a:num)
    if line =~ '\v\[.\]'
        return 1
    else
        return 0
    endif
endfunction

function! s:VimHookListing.getVimHookListingText(allVimHooks)
    let checkedbox = '[x]'
    let uncheckedbox = '[ ]'

    let text = 'Mappings'
    let text = self.joinWithNewline(text, '--------')
    let text = self.joinWithNewline(text, 'x     : enable/disable a VimHook')
    let text = self.joinWithNewline(text, 'q     : save selections and exit')
    let text = self.joinWithNewline(text, '<ESC> : save selections and exit (duplicate mapping)')
    let text = self.joinWithNewline(text, 'i     : open VimHook script in split')
    let text = self.joinWithNewline(text, 's     : open VimHook script in vertical split')
    let text = self.joinWithNewline(text, 'o     : open VimHook script in prev window')
    let text = self.joinWithNewline(text, '<CR>  : open VimHook script in prev window (duplicate mapping)')
    let text = self.joinWithNewline(text, '')
    let text = self.joinWithNewline(text, 'Hooks')
    let text = self.joinWithNewline(text, '-----')

    let currentLineNumber = len(split(text, "\n")) + 1
    let self.lowestLine = currentLineNumber
    let self.highestLine = currentLineNumber

    if len(a:allVimHooks)
        for vimHook in a:allVimHooks
            let text = self.joinWithNewline(text, '  ' . (vimHook.isEnabled ? checkedbox : uncheckedbox) . ' ' . self.pad(vimHook.unixStylePattern, self.columnWidths.pattern + 2) . self.pad(vimHook.event, self.columnWidths.event + 2) . vimHook.path)
            let self.lineNumbersToVimHooks[currentLineNumber] = vimHook
            let currentLineNumber += 1
            let self.highestLine += 1
        endfor
    else
        let text = self.joinWithNewline(text, " No hook files found!")
        let text = self.joinWithNewline(text, " See :help vim-hook-examples. Or visit https://github.com/ahw/vim-hooks#example-usage")
    endif
    let self.highestLine -= 1 " Since the last increment doesn't count

    return text
endfunction

function! s:VimHookListing.toggleLine()
    setlocal modifiable
    let lnum = line('.')

    let line = getline(lnum)
    if self.isCheckboxLine(lnum)
        " If this is a line beginning with checkbox, then toggle it by
        " calling the toggleIsEnabled() function on the appropriate
        " VimHook and then changing the text to match.

        call self.lineNumbersToVimHooks[lnum].toggleIsEnabled()

        let checked = get(matchlist(line, '\v\[(.)\]'), 1, "") == " " ? 0 : 1
        let toggledLine = ""
        if checked
            let toggledLine = substitute(line, '\v\[.\]', '[ ]', "") . ".disabled"
        else
            let toggledLine = substitute(line, '\v\[.\]', '[x]', "")
            let toggledLine = substitute(toggledLine, '\v\.disabled$', '', "")
        endif
        call setline(lnum, toggledLine)
    endif

    redraw!
    setlocal nomodifiable
endfunction

function! s:VimHookListing.openLineInSplit(splitCommand)
    let lnum = line('.')
    if self.isCheckboxLine(lnum)
        let hookFilename = self.lineNumbersToVimHooks[lnum].path
        execute a:splitCommand . " " . hookFilename
    endif
endfunction

function! s:VimHookListing.openLineInVerticalSplit()
    call self.openLineInSplit('vsp')
endfunction

function! s:VimHookListing.openLineInHorizontalSplit()
    call self.openLineInSplit('sp')
endfunction

function! s:VimHookListing.openLineInPreviousWindow()
    call self._tryToOpenInPreviousWindow()
endfunction

function! s:VimHookListing.exitBuffer()
    execute "q!"
endfunction

"FUNCTION: VimHookListing._tryToOpenInPreviousWindow()
"[STOLEN FROM NERDTREE.VIM]
function! s:VimHookListing._tryToOpenInPreviousWindow()
    let lnum = line('.')
    if self.isCheckboxLine(lnum)
        let hookFilename = self.lineNumbersToVimHooks[lnum].path

        if !hooks#isWindowUsable(winnr("#")) && hooks#firstUsableWindow() ==# -1
            " If we can't use the previous window and we don't have a usable
            " window at all, then just open in a vertical split
            call self.openLineInVerticalSplit() " TODO: Use vertical or horizontal
        else
            try
                if !hooks#isWindowUsable(winnr("#"))
                    " If we can't use the previous window then use the first
                    " usable window (which we know is available due to the above
                    " conditional)
                    execute hooks#firstUsableWindow() . "wincmd w"
                    execute "e" . " " . hookFilename
                else
                    " Else go to the previous window. TODO: Not sure what will
                    " happen here.
                    execute "wincmd p"
                    execute "e" . " " . hookFilename
                endif
            catch /^Vim\%((\a\+)\)\=:E37/
                " TODO Not sure how we get into this case.
                echom "ListVimHooks: Exception case 1"
                " call nerdtree#putCursorInTreeWin() " TODO
                throw "VimHooks.FileAlreadyOpenAndModifiedError: ". self._path.str() ." is already open and modified."
            catch /^Vim\%((\a\+)\)\=:/
                " TODO Not sure how we get into this case.
                echom "ListVimHooks: Exception case 2"
                echo v:exception
            endtry
        endif
    endif
endfunction
