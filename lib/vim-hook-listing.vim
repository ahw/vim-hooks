"CLASS: VimHookListing

let s:VimHookListing = {}
let g:VimHookListing = s:VimHookListing

let s:VimHookListing.lineNumbersToVimHooks = {}
let s:VimHookListing.lowestLine = 0
let s:VimHookListing.highestLine = 0

function! s:VimHookListing.pad(s, amt)
    return a:s . repeat(' ', a:amt - len(a:s))
endfunction

function! s:VimHookListing.joinWithNewline(lines, anotherLine)
    return a:lines . "\n" . a:anotherLine
endfunction

function! s:VimHookListing.getVimHookListingText(patternBasedVimHooks)
    let checkedbox = '[x]'
    let uncheckedbox = '[ ]'

    let text = 'Mappings'
    let text = self.joinWithNewline(text, '--------')
    let text = self.joinWithNewline(text, 'x     : enable/disable a VimHook')
    let text = self.joinWithNewline(text, 'q     : save selections and exit')
    let text = self.joinWithNewline(text, '<ESC> : save selections and exit (duplicate mapping)')
    let text = self.joinWithNewline(text, '<CR>  : save selections and exit (duplicate mapping)')
    let text = self.joinWithNewline(text, '')
    let text = self.joinWithNewline(text, 'Hooks')
    let text = self.joinWithNewline(text, '-----')

    let currentLineNumber = len(split(text, "\n")) + 2
    let self.lowestLine = currentLineNumber
    let self.highestLine = currentLineNumber

    if len(keys(a:patternBasedVimHooks))
        for event in keys(a:patternBasedVimHooks)
            for pattern in keys(a:patternBasedVimHooks[event])
                for vimHookId in keys(a:patternBasedVimHooks[event][pattern])
                    let vimHook = a:patternBasedVimHooks[event][pattern][vimHookId]
                    " This is amazing. Trying to make these regex patterns
                    " look like UNIX-style glob patterns.
                    let betterPattern = substitute(vimHook.pattern, '\v\\v', '', '')
                    let betterPattern = substitute(betterPattern, '\v\^', '', '')
                    let betterPattern = substitute(betterPattern, '\v\$', '', '')
                    let betterPattern = substitute(betterPattern, '\v\.\*', '*', '')
                    let betterPattern = substitute(betterPattern, '\v\\\.', '.', '')
                    let text = self.joinWithNewline(text, '  ' . (vimHook.isEnabled ? checkedbox : uncheckedbox) . ' ' . self.pad(betterPattern, 10) . ' ' . vimHook.event . ': ' . vimHook.path)
                    let self.lineNumbersToVimHooks[currentLineNumber] = vimHook
                    let currentLineNumber += 1
                    let self.highestLine += 1
                endfor
            endfor
        endfor
    else
        let text = self.joinWithNewline(text, "New hook files found!")
    endif
    let self.highestLine -= 1 " Since the last increment doesn't count

    return text
endfunction

function! s:VimHookListing.toggleLine()
    setlocal modifiable
    let lnum = line('.')

    let line = getline(lnum)
    if line =~ '\v\[.\]'
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

function! s:VimHookListing.exitBuffer()
    execute "q!"
endfunction
