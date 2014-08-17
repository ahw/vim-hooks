"CLASS: VimHook

let s:VimHook = {}
let g:VimHook = s:VimHook

function! s:VimHook.New(path, event, scope, ...)
    let newVimHook = copy(self)
    let newVimHook.path = a:path
    if a:path !~ '\v^/'
        " If path does not begin with a leading slash, add a "./" to make it
        " executable
        let newVimHook.path = "./" . a:path
    endif

    let newVimHook.isEnabled = 1
    if newVimHook.path =~ '\v\.disabled$'
        let newVimHook.isEnabled = 0
    endif

    let newVimHook.event = a:event
    let newVimHook.scope = a:scope
    if newVimHook.scope !=? 'global'
        " If this isn't a "global" scope VimHook then set the scopeKey
        " attribute to the final (optional) argument
        let newVimHook.scopeKey = a:1
    endif

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
