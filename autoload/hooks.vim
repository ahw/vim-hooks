"FUNCTION: hooks#isWindowUsable(winnumber)
"[STOLEN FROM NERDTREE]
"Returns 0 if opening a file from the tree in the given window requires it to
"be split, 1 otherwise
"
"Args:
"winnumber: the number of the window in question
function! hooks#isWindowUsable(winnumber)
    "gotta split if theres only one window
    if winnr("$") ==# 1
        return 0
    endif

    let oldwinnr = winnr()
    execute a:winnumber . "wincmd p"
    let specialWindow = getbufvar("%", '&buftype') != '' || getwinvar('%', '&previewwindow')
    let modified = &modified
    execute oldwinnr . "wincmd p"

    " if its a special window e.g. quickfix or another explorer plugin then
    " we have to split
    if specialWindow
        return 0
    endif

    if &hidden
        return 1
    endif

    " If the bufer has not been modified or it's open in more than one
    " window then this window is safe to take over.
    return !modified || hooks#bufInWindows(winbufnr(a:winnumber)) >= 2
endfunction

"FUNCTION: hooks#firstUsableWindow()
"[STOLEN FROM NERDTREE]
"Find the window number of the first normal window
function! hooks#firstUsableWindow()
    let i = 1
    while i <= winnr("$")
        let bnum = winbufnr(i)
        if bnum != -1 && getbufvar(bnum, '&buftype') ==# ''
                    \ && !getwinvar(i, '&previewwindow')
                    \ && (!getbufvar(bnum, '&modified') || &hidden)
            return i
        endif

        let i += 1
    endwhile
    return -1
endfunction

"FUNCTION: hooks#bufInWindows(bnum)
"[STOLEN FROM NERDTREE WHICH STOLE FROM VTREEEXPLORER.VIM]
"Determine the number of windows open to this buffer number.
"Care of Yegappan Lakshman. Thanks!
"
"Args:
"bnum: the subject buffers buffer number
function! hooks#bufInWindows(bnum)
    let cnt = 0
    let winnum = 1
    while 1
        let bufnum = winbufnr(winnum)
        if bufnum < 0
            break
        endif
        if bufnum ==# a:bnum
            let cnt = cnt + 1
        endif
        let winnum = winnum + 1
    endwhile

    return cnt
endfunction
