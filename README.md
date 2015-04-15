VimHooks
========
**Note: exhaustive documentation is available on the project's wiki:**
[https://github.com/ahw/vim-hooks/wiki](https://github.com/ahw/vim-hooks/wiki).

Overview
========
![VimHooks Flow](https://s3.amazonaws.com/pd93f014/vim-hooks-drawing.svg?=1)

This is a Vim plugin that lets you automatically execute arbitrary shell
scripts after specific `autocmd` events are fired while editing certain files.
It does this by looking for specially-named scripts  in your current working
directory (as well as `~/.vimhooks/`) that have names like
`.bufwritepost.vimhook.rb` or `.cursorhold.vimhook.sh` and executes those
scripts whenever &ndash; in this example &ndash; Vim fires the `BufWritePost`
and `CursorHold` `autocmd` events, respectively.


VimHook scripts, which I refer to as "hook scripts," or just "hooks"
throughout this document, can live at the project level or at a global level
in `~/.vimhooks/`.  Hooks can be **synchronous** (the default) or
**asynchronous** (in a fire-and-forget sort of way). The `autocmd` triggers
can be **debounced** so hooks are only executed once within a specified
window of time. The **stdout produced by hook scripts can be buffered** into a
split window that **refreshes automatically** every time the hook is executed.
Hooks **report stderr** when they
exit with a non-zero exit code. Finally, the `:ListVimHooks` command
provides a listing of all enabled and disabled hook scripts available in a
particular session. They are listed in the order they would (synchronously)
execute and can be **toggled on and off interactively.** You can make edits to
hook scripts on the fly and the changes will be reflected the next time they
are run.

Naming Pattern
==============
![VimHook Naming Structure](https://s3.amazonaws.com/pd93f014/vimhook-naming-diagram.svg?v=4)

Commands
========
- `:ListVimHooks`
- `:FindHookFiles`
- `:ExecuteHookFiles`
- `:StopExecutingHooks`
- `:StartExecutingHooks`

Example Usage
=============
- [Restart your Jekyll preview server on file write](https://github.com/ahw/vim-hooks/blob/master/examples/090.bufwritepost.vimhook.restart-jekyll-server.sh)
- [Reload Chrome tabs on file write](https://github.com/ahw/vim-hooks/blob/master/examples/100.bufwritepost.vimhook.chrome-reloader.sh)
- [Reload Chrome, Firefox, and Safari on file write](https://github.com/ahw/vim-hooks/blob/master/examples/bufwritepost.vimhook.reload-browsers.applescript)
- [Recompile Sass files on file write](https://github.com/ahw/vim-hooks/blob/master/examples/scss.bufwritepost.vimhook.recompile-sass.sh)
- [Execute SQL via sqlite3 on file write](https://github.com/ahw/vim-hooks/blob/master/examples/sql.bufwritepost.vimhook.sh)
- [Dump stdout from a hook into a scratch buffer](https://github.com/ahw/vim-hooks/blob/master/examples/test.js.bufwritepost.vimhook.buffer-output.sh)

Demos
=====

Sass Recompilation and Browser Reload
-------------------------------------
_Recompile a Sass file and then reload Chrome, Firefox, and Safari using
AppleScript._

![VimHooks Reload GIF](http://g.recordit.co/CITvKXJOFe.gif)

Vim as REPL
-----------
_Execute whatever code you're currently editing and see the result from
stdout opened in a new window._

![VimHooks Buffer Output GIF](https://s3.amazonaws.com/pd93f014/buffer-output-2.gif)
