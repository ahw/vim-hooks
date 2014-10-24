"CLASS: VimHookListing

let s:VimHookListing = {}
let g:VimHookListing = s:VimHookListing

let s:VimHookListing.vimHooksByListingIndex = []
let s:VimHookListing.lowestLine = 0
" let s:VimHookListing.highestLine = 0
" Set some defaults just in case.
let s:VimHookListing.columnWidths = { 'pattern': 25, 'event': 15, 'path': 0 }

function! s:VimHookListing.pad(s, amt)
    return a:s . repeat(' ', a:amt - len(a:s))
endfunction

function! s:joinWithNewline(lines, anotherLine)
    return a:lines . "\n" . a:anotherLine
endfunction

function! s:VimHookListing.getVimHookIndexByLineNum(lnum)
    return a:lnum - self.listingIndexOffset
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
    let text = s:joinWithNewline(text, '--------')
    let text = s:joinWithNewline(text, 'x     : enable/disable a VimHook')
    let text = s:joinWithNewline(text, 'q     : save selections and exit')
    let text = s:joinWithNewline(text, '<ESC> : save selections and exit (duplicate mapping)')
    let text = s:joinWithNewline(text, 'i     : open VimHook script in split')
    let text = s:joinWithNewline(text, 's     : open VimHook script in vertical split')
    let text = s:joinWithNewline(text, 'o     : open VimHook script in prev window')
    let text = s:joinWithNewline(text, '<CR>  : open VimHook script in prev window (duplicate mapping)')
    let text = s:joinWithNewline(text, '')
    let text = s:joinWithNewline(text, 'Hooks')
    let text = s:joinWithNewline(text, '-----')

    let self.lowestLine = len(split(text, "\n")) + 1
    let enabledHooksIndex = 0
    let disabledHooksIndex = 0
    let self.listingIndexOffset = self.lowestLine
    " let self.highestLine = currentLineNumber

    let enabledHooksText = ""
    let disabledHooksText = ""
    if len(a:allVimHooks)
        for vimHook in a:allVimHooks
            let line = (vimHook.isEnabled ? checkedbox : uncheckedbox) . ' ' . self.pad(vimHook.unixStylePattern, self.columnWidths.pattern + 2) . self.pad(vimHook.event, self.columnWidths.event + 2) . vimHook.path
            if vimHook.isEnabled
                let enabledHooksText = s:joinWithNewline(enabledHooksText, line)
                call insert(self.vimHooksByListingIndex, vimHook, enabledHooksIndex)
                let enabledHooksIndex += 1
                let disabledHooksIndex += 1
            else
                let disabledHooksText = s:joinWithNewline(disabledHooksText, line)
                call insert(self.vimHooksByListingIndex, vimHook, disabledHooksIndex)
                let disabledHooksIndex += 1
            endif
            " let self.vimHooksByListingIndex[currentLineNumber] = vimHook
            " let currentLineNumber += 1
            " let self.highestLine += 1
        endfor
        " The blocks of text listing enabled and disabled hooks already has
        " newlines in the right places. Just concatenate.
        let text = text . enabledHooksText . disabledHooksText
    else
        let text = s:joinWithNewline(text, " No hook files found!")
        let text = s:joinWithNewline(text, " See :help vim-hook-examples. Or visit https://github.com/ahw/vim-hooks#example-usage")
    endif
    " let self.highestLine -= 1 " Since the last increment doesn't count

    return text
endfunction

function! s:VimHookListing.toggleLine()
    setlocal modifiable
    let lnum = line('.')
    let line = getline(lnum)
    let index = self.getVimHookIndexByLineNum(lnum)

    if self.isCheckboxLine(lnum)
        " If this is a line beginning with checkbox, then toggle it by
        " calling the toggleIsEnabled() function on the appropriate
        " VimHook and then changing the text to match.

        echom ">>> toggling vimhook at index " . index . " which is " . self.vimHooksByListingIndex[index].toString()
        call self.vimHooksByListingIndex[index].toggleIsEnabled()

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
    let index = self.getVimHookIndexByLineNum(lnum)
    if self.isCheckboxLine(lnum)
        let hookFilename = self.vimHooksByListingIndex[index].path
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
        let hookFilename = self.vimHooksByListingIndex[lnum].path

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
