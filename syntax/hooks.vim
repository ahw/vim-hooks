if exists("b:current_syntax")
    finish
endif

syntax case ignore
syntax keyword VimHooksEvent BufNewFile
syntax keyword VimHooksEvent BufReadPre
syntax keyword VimHooksEvent BufRead
syntax keyword VimHooksEvent BufReadPost
syntax keyword VimHooksEvent BufReadCmd
syntax keyword VimHooksEvent FileReadPre
syntax keyword VimHooksEvent FileReadPost
syntax keyword VimHooksEvent FileReadCmd
syntax keyword VimHooksEvent FilterReadPre
syntax keyword VimHooksEvent FilterReadPost
syntax keyword VimHooksEvent StdinReadPre
syntax keyword VimHooksEvent StdinReadPost
syntax keyword VimHooksEvent BufWrite
syntax keyword VimHooksEvent BufWritePre
syntax keyword VimHooksEvent BufWritePost
syntax keyword VimHooksEvent BufWriteCmd
syntax keyword VimHooksEvent FileWritePre
syntax keyword VimHooksEvent FileWritePost
syntax keyword VimHooksEvent FileWriteCmd
syntax keyword VimHooksEvent FileAppendPre
syntax keyword VimHooksEvent FileAppendPost
syntax keyword VimHooksEvent FileAppendCmd
syntax keyword VimHooksEvent FilterWritePre
syntax keyword VimHooksEvent FilterWritePost
syntax keyword VimHooksEvent BufAdd
syntax keyword VimHooksEvent BufCreate
syntax keyword VimHooksEvent BufDelete
syntax keyword VimHooksEvent BufWipeout
syntax keyword VimHooksEvent BufFilePre
syntax keyword VimHooksEvent BufFilePost
syntax keyword VimHooksEvent BufEnter
syntax keyword VimHooksEvent BufLeave
syntax keyword VimHooksEvent BufWinEnter
syntax keyword VimHooksEvent BufWinLeave
syntax keyword VimHooksEvent BufUnload
syntax keyword VimHooksEvent BufHidden
syntax keyword VimHooksEvent BufNew
syntax keyword VimHooksEvent SwapExists
syntax keyword VimHooksEvent FileType
syntax keyword VimHooksEvent Syntax
syntax keyword VimHooksEvent EncodingChanged
syntax keyword VimHooksEvent TermChanged
syntax keyword VimHooksEvent VimEnter
syntax keyword VimHooksEvent GUIEnter
syntax keyword VimHooksEvent TermResponse
syntax keyword VimHooksEvent VimLeavePre
syntax keyword VimHooksEvent VimLeave
syntax keyword VimHooksEvent FileChangedShell
syntax keyword VimHooksEvent FileChangedShellPost
syntax keyword VimHooksEvent FileChangedRO
syntax keyword VimHooksEvent ShellCmdPost
syntax keyword VimHooksEvent ShellFilterPost
syntax keyword VimHooksEvent FuncUndefined
syntax keyword VimHooksEvent SpellFileMissing
syntax keyword VimHooksEvent SourcePre
syntax keyword VimHooksEvent SourceCmd
syntax keyword VimHooksEvent VimResized
syntax keyword VimHooksEvent FocusGained
syntax keyword VimHooksEvent FocusLost
syntax keyword VimHooksEvent CursorHold
syntax keyword VimHooksEvent CursorHoldI
syntax keyword VimHooksEvent CursorMoved
syntax keyword VimHooksEvent CursorMovedI
syntax keyword VimHooksEvent WinEnter
syntax keyword VimHooksEvent WinLeave
syntax keyword VimHooksEvent TabEnter
syntax keyword VimHooksEvent TabLeave
syntax keyword VimHooksEvent CmdwinEnter
syntax keyword VimHooksEvent CmdwinLeave
syntax keyword VimHooksEvent InsertEnter
syntax keyword VimHooksEvent InsertChange
syntax keyword VimHooksEvent InsertLeave
syntax keyword VimHooksEvent ColorScheme
syntax keyword VimHooksEvent RemoteReply
syntax keyword VimHooksEvent QuickFixCmdPre
syntax keyword VimHooksEvent QuickFixCmdPost
syntax keyword VimHooksEvent SessionLoadPost
syntax keyword VimHooksEvent MenuPopup
syntax keyword VimHooksEvent User

syntax match VimHooksMapKey /\v^[<>a-z]+/
syntax match VimHooksDisabledCheckbox /\v\[\s\].+/
syntax match VimHooksEnabledCheckbox /\v\[x\]/
syntax match VimHooksCursor /\v^\>/
syntax match VimHooksHeader /\v^\a+$/
syntax match VimHooksHeader /\v^-+$/

highlight link VimHooksHeader Special
highlight link VimHooksDisabledCheckbox Comment
highlight link VimHooksEnabledCheckbox Identifier
highlight link VimHooksCursor Normal
highlight link VimHooksMapKey Identifier

" syntax match VimHooksLine /\v^.*$/ contains=VimHooksEnabledCheckbox
" syntax match VimHooksCurrentLine /\v^\>.*/
" highlight link VimHooksCurrentLine Special
" highlight link VimHooksEvent Comment


let b:current_syntax = "hooks"
