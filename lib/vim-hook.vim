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
    let newVimHook.outputBufferName = substitute(newVimHook.baseName, '\v.disabled$', "", "") . ".output"

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

    " First set any options that were set via global variables
    for key in keys(g:VimHookOptions)
        let keyName = g:VimHookOptions[key].keyName
        let globalVariableName = g:VimHookOptions[key].globalVariableName

        if exists(globalVariableName)
            call newVimHook.setOptionValue(keyName, eval(globalVariableName))
        endif
    endfor

    " Now scrape for options
    if (filereadable(newVimHook.path))
        " The scrapeForOptions function goes through each line in the file
        " and tries to parse out option values.
        call newVimHook.scrapeForOptions()
    endif

    return newVimHook
endfunction

function! VimHook.scrapeForOptions()
    let vimHookLines = readfile(self.path)
    let optionDeclarationRegExp = '\vvimhook\.([A-Za-z0-9_\.]+)\s*[:=]?\s*(\w*)$'
    for line in vimHookLines
        if line =~ optionDeclarationRegExp
            " echom "> Found line \"" . line . "\""
            " let matches =  matchlist(line, '\vvimhook\.([0-9A-Za-z\.]+)\s*[:=]?\s*(\w*)$')
            let matches =  matchlist(line, optionDeclarationRegExp)
            let key = get(matches, 1, "")
            let value = get(matches, 2, "")
            " echom "> key <" . key . "> value <" . value . ">"
            " If no value was provided, set it to a true value.
            if key == ""
                " If our regexp didn't work, just break early
                break
            elseif value == ""
                " If no value was provided then it is implicitly true.
                "
                " Input       | Result
                " -----       | ------
                " vimhook.foo | self.optional.foo = 1
                call self.setOptionValue(key, 1)
            else
                " If a value was provided, try to convert things that look
                " like booleans to Vim-suitable to true/false values. If
                " that doesn't work, the parseOptionValue function will just
                " echo back the same string value it received.
                "
                " Input              | Result
                " -----              | ------
                " vimhook.foo = true | self.optional.foo = 1
                " vimhook.bar = 1    | self.optional.bar = 1
                " vimhook.baz = hi   | self.optional.baz = "hi"
                call self.setOptionValue(key, value)
            endif
        endif
    endfor
endfunction

function! s:parseOptionValue(value)
    " Return 1 if the value matches the string 'true' case insensitive or
    " '1'. Return 0 if the value matches the string 'false case insensitive
    " or '0'. Else, just echo back the string value itself.
    if type(a:value) == type("")
        if a:value =~? "true"
            return 1
        elseif a:value =~? "1"
            return 1
        elseif a:value =~? "false"
            return 0
        elseif a:value =~? "0"
            return 0
        else
            return a:value
        endif
    else
        " Assert: value is probably just a Number
        return a:value
    endif
endfunction

function! s:VimHook.toggleIsEnabled()
    if self.isEnabled
        call self.disable()
    else
        call self.enable()
    endif
endfunction

function! s:VimHook.setOptionValue(key, value)
    if !exists('self.optional')
        let self.optional = {}
    endif

    let self.optional[a:key] = s:parseOptionValue(a:value)
endfunction

function! s:VimHook.getOptionValue(key)
    if !exists('self.optional')
        let self.optional = {}
    endif

    if has_key(self.optional, a:key)
        return self.optional[a:key]
    else
        return 0
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
