"CLASS: VimHook

let s:VimHook = {}
let g:VimHook = s:VimHook

function! s:VimHook.New(path, event, pattern)
    let newVimHook = copy(self)
    let newVimHook.path = a:path
    if a:path !~ '\v^/'
        " If path does not begin with a leading slash, add a "./" to make it
        " executable
        let newVimHook.path = "./" . a:path
    endif
    " Create a unique id for this VimHook. For now we'll assume the path to
    " the hook file is unique, even if we chop off the ".disabled" part,
    " which may or may not exist.
    let newVimHook.id = substitute(newVimHook.path, '\v.disabled$', "", "")
    let newVimHook.baseName = get(matchlist(newVimHook.path, '\v[^/]+$'), 0, "")

    let newVimHook.isEnabled = 1
    if newVimHook.path =~ '\v\.disabled$'
        let newVimHook.isEnabled = 0
    endif

    " Create a UNIX-style glob version of the pattern.
    let unixStylePattern = substitute(a:pattern, '\v\\v', '', '')
    let unixStylePattern = substitute(unixStylePattern, '\v\^', '', '')
    let unixStylePattern = substitute(unixStylePattern, '\v\$', '', '')
    let unixStylePattern = substitute(unixStylePattern, '\v\.\*', '*', '')
    let unixStylePattern = substitute(unixStylePattern, '\v\\\.', '.', '')
    let newVimHook.unixStylePattern = unixStylePattern

    let newVimHook.event = a:event
    let newVimHook.pattern = a:pattern
    let newVimHook.isIgnoreable = 0

    return newVimHook
endfunction

function! s:VimHook.toggleIsEnabled()
    if self.isEnabled
        call self.disable()
    else
        call self.enable()
    endif
endfunction

function! s:VimHook.disable()
    " mv /some/hook.sh /some/hook.sh.disabled
    let newPath = self.path . ".disabled"
    execute "silent !mv " . self.path . " " . newPath
    let self.path = newPath
    let self.isEnabled = 0
endfunction

function! s:VimHook.enable()
    " Remove the .disabled from the end
    let newPath = substitute(self.path, '\v\.disabled$', "", "")
    execute "silent !mv " . self.path . " " . newPath
    let self.path = newPath
    " Set the execute bit
    execute "silent !chmod u+x " . self.path
    let self.isEnabled = 1
endfunction

function! s:VimHook.ignore()
    let self.isIgnoreable = 1
endfunction

function! s:VimHook.toString()
    return self.unixStylePattern . " " . self.event . " (" . self.path . ")"
endfunction
