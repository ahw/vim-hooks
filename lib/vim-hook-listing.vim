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

    let text = "Press...\n"
    let text = self.joinWithNewline(text, '      "j" to move down')
    let text = self.joinWithNewline(text, '      "k" to move up')
    let text = self.joinWithNewline(text, '      "x" to enable/disable a VimHook')
    let text = self.joinWithNewline(text, '      "<ESC> or <ENTER>" to save selections and exit')
    let text = self.joinWithNewline(text, "")

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
                    let text = self.joinWithNewline(text, (self.lowestLine == currentLineNumber ? '> ' : '  ') . (vimHook.isEnabled ? checkedbox : uncheckedbox) . ' ' . self.pad(betterPattern, 10) . ' ' . vimHook.event . ': ' . vimHook.path)
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

function! s:VimHookListing.handleKeys()
    let done = 0
    while !done
        redraw!
        let key = nr2char(getchar())
        let done = self.handleKeyPress(key)
    endwhile
    execute "q!"
endfunction

function! s:VimHookListing.handleKeyPress(key)
    let lnum = line('.')
    if a:key == 'j'
        let nnum = min([lnum + 1, self.highestLine])
        let line = getline(lnum)
        let nline = getline(nnum)

        call setline(lnum, substitute(line, '\v^.', ' ', ''))
        call cursor(nnum, 1) " Put cursor on next line
        call setline(nnum, substitute(nline, '\v^.', '>', ''))

    elseif a:key == 'k'
        let pnum = max([lnum - 1, self.lowestLine])
        let line = getline(lnum)
        let pline = getline(pnum)

        call setline(lnum, substitute(line, '\v^.', ' ', ''))
        call cursor(pnum, 1) "Put cursor on previous line
        call setline(pnum, substitute(pline, '\v^.', '>', ''))

    elseif a:key == nr2char(27) || a:key == "\r" || a:key == "\n"
        "enter, ctrl-j, escape
        return 1
    elseif a:key == 'x'
        let line = getline(lnum)
        echom line
        if line =~ '\v^.\s\[.\]'
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
    endif

    return 0
endfunction
