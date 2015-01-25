let s:VimHookOptions = {
    \     'BUFFER_OUTPUT': {
    \         'keyName': 'bufferoutput',
    \         'globalVariableName': 'g:vimhooks_bufferoutput'
    \     },
    \     'BUFFER_OUTPUT_VSPLIT': {
    \         'keyName': 'bufferoutput.vsplit',
    \         'globalVariableName': 'g:vimhooks_bufferoutput_vsplit'
    \     },
    \     'BUFFER_OUTPUT_FILETYPE': {
    \         'keyName': 'bufferoutput.filetype',
    \         'globalVariableName': 'g:vimhooks_bufferoutput_filetype'
    \     },
    \ }

let g:VimHookOptions = s:VimHookOptions
