if exists("b:current_syntax")
    finish
endif

syntax match VimHooksHeader /\v^.+\n[-=]+$/
syntax match VimHooksCheckbox /\v^\[.\]/

highlight link VimHooksHeader Title
highlight link VimHooksCheckbox Identifier

let b:current_syntax = "hooks"
