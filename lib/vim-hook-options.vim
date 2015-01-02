let s:VimHookOptions = {
    \     'BUFFER_OUTPUT': {
    \         'keyName': 'bufferoutput',
    \         'globalVariableName': 'g:vimhooks_bufferoutput'
    \     },
    \     'BUFFER_OUTPUT_VSPLIT': {
    \         'keyName': 'bufferoutput.vsplit',
    \         'globalVariableName': 'g:vimhooks_bufferoutput_vsplit'
    \     },
    \ }

let g:VimHookOptions = s:VimHookOptions
