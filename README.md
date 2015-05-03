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

Installation
============
If you don't have a preferred installation method, I recommend
installing [pathogen.vim](https://github.com/tpope/vim-pathogen), and
then simply copy and paste:

    cd ~/.vim/bundle
    git clone https://github.com/ahw/vim-hooks.git

How it works
============
When some event **E** is fired from a Vim buffer named **F** (i.e., the
filename), VimHooks looks through the list of all hook scripts in the
current working directory and `~/.vimhooks/`, and executes those
hooks whose **event** property is **E** and whose **matching suffix**
property matches **F**.<sup>1</sup> These and other properties are embedded
in the hook script filename itself and follow a specific naming pattern so
that the plugin can parse them out. This pattern is described below.
<!-- The **matching suffix** matches **F** when **F** ends in **matching suffix**.-->

VimHook naming pattern
----------------------
![VimHook Naming Structure](https://s3.amazonaws.com/pd93f014/vimhook-naming-diagram.svg?v=4)

Property                       | Description
---                            | ---
**leading dot** (optional)     | Doesn't matter whether the file is hidden or not.
**sort key** (optional)        | There can be multiple VimHooks set to trigger on the same `autocmd` event, and they are executed in lexicographical order. If it is important that certain hooks execute in a specific order, you can add one or more digits in this space to ensure the ordering is correct.
**matching suffix** (optional) | Assuming the **event** property has matched, a VimHook will trigger for all files ending with this matching suffix. If **matching suffix** is "js", the hook wil trigger for all files ending in "js". When matching suffix is "main.js" the hook will trigger for all files ending in "main.js" (including "main.js" itself). If there is no matching suffix the hook becomes global: it will trigger for all files. The matching suffix can contain dots.
**event**                      | The name of the `autocmd` event the hook is triggered on. Case insensitive.
**"vimhook"**                  | Identifies this as a VimHook script. Nothing after "vimhook" is parsed out by the plugin.

Note that in general, each component of the pattern is separated by a "." from
the other components, though the **matching suffix** can itself contains dots
and VimHooks knows how to accommodate these. When you leave off one of the
optional pattern components (e.g., **sort key**) you do not need to include the
dot marking its place. Thus, `bufwritepost.vimhook.sh`,
`js.bufwritepost.vimhook.rb`, and `.001.foo.bar.py.bufwritepost.vimhook.js`
are all valid VimHook filenames.

Arguments provided to a hook script
-----------------------------------
Each script is passed (1) the name of the current buffer and (2) the triggered event
name as command-line arguments, in that order. So in a Bash shell script you
could, for example, use `$1` and `$2` to access these values.

VimHook Options
===============
As of release [1.4.1](https://github.com/ahw/vim-hooks/releases/tag/1.4.1),
VimHook supports additional functionality that is exposed by setting various
VimHook _options_. Option flags are set either (1) _in the source code_ of a hook
script or (2) globally, via global variables in your `~/.vimrc`.

### Available options

Option Key                  | Global Variable                | Behavior
---                         | ---                            | ---
vimhook.bufferoutput        | g:vimhooks_bufferoutput        | When true, dump the stdout from this hook script into a new scratch buffer, opened automatically in a new window. If the buffer already exists, overwrite it and refresh the window. When false, VimHook scripts are executed silently, though stderr is still reported when scripts exit with a non-zero exit code. **Default: false**
vimhook.bufferoutput.vsplit | g:vimhooks_bufferoutput_vsplit | When true, open the buffer output window in a vertical split instead of the default horizontal. When false or omitted, buffer output window is opened in a horizontal split. This option is only relevant when `vimhook.bufferoutput` is `true`. **Default: false**
vimhook.async               | g:vimhooks_async               | When true, execute this hook in a forked process. The exit code, stdout, and stderr will all be lost to the ether ("fire and forget"). **Default: false**
vimhook.debounce.wait: N    | g:vimhooks_debounce_wait       | You can set the `vimhook.debounce.wait: N` option in a hook script to execute the script in a forked process after _N_ seconds have elapsed since the last trigger of this particular hook. Debounced hooks are implicitly async, so the disclaimers described for that option hold for debounced hooks too. **Default: unset**
_(Not applicable)_          | g:vimhooks_list_enabled_first  | When explicitly set to false, `:ListVimHooks` will stop grouping enabled hooks first and disabled hooks second. Instead, all hooks are listed in lexicographical order. **Default: true**

Note that global option settings are applied first
and overridden on a per-hook basis wherever they are used. For example, if your
`~/.vimrc` contains

```vim
let g:vimhooks_bufferoutput_vsplit = 1
```

then buffer output windows will always open in a vertical split unless there is
a `vimhook.bufferoutput.vsplit = 0` option setting in some particular hook
script. In that case, that particular script will open its buffer output window
in a horizontal split.

### How to set options
To set an option
flag and value in your VimHook script, add a line anywhere in the file that
follows the convention `vimhook.myOptionKey = myOptionValue`. The line can
begin with anything you want (like a comment character) but should not have
anything after the `myOptionValue` part. Whitespace around the `=` sign is
irrelevant. You can use a `:` instead of an `=` sign if you prefer.

![VimHook Options Grammar](https://pd93f014.s3.amazonaws.com/vimhook-option-grammar-1.svg)

_The full grammar of a VimHook option line. Source: [www.regexper.com](http://www.regexper.com/#vimhook%5C.%28%5B%5Cw%5C.%5D%2B%29%5Cs%2A%5B%3A%3D%5D%3F%5Cs%2A%28%5Cw%2A%29%2524)_
![CC BY License](https://licensebuttons.net/l/by/3.0/80x15.png)

For example, the following lines are all equivalent ways of setting the
option `bufferoutput` to `true`. Notice (in the last line) that you are not
forced to set an option value. If you only provide an option key, the value
will be automatically set to `true`.

```
# vimhook.bufferoutput = true
// vimhook.bufferoutput : true
-- vimhook.bufferoutput:1
// foo bar baz vimhook.bufferoutput
```

The following are all equivalent ways of setting the `bufferoutput` key to
`false`.
```
# vimhook.bufferoutput = false
>>> vimhook.bufferoutput : false
" vimhook.bufferoutput:0
```

For the sake of showing an example of a non-boolean option, these are all
equivalent ways of setting the option `debounce.wait` to 2 seconds.

```
# vimhook.debounce.wait = 2
// vimhook.debounce.wait: 2
-- vimhook.debounce.wait : 2
```

Commands
========
ListVimHooks
------------
The `:ListVimHooks` command takes zero arguments. It opens a new
unmodifiable buffer in a horizontal split which lists all of the VimHook
script files the plugin has found after scanning the current working
directory as well as the `~/.vimhooks/` directory. The enabled hook scripts
are listed before the disabled ones. Helpfully, within each of these
groupings, the _relative order of the hook scripts matches their order of
execution._

There are two sections in this buffer: the **Mappings** section which shows
a "cheat sheet" of the buffer-local mappings and the **Hooks** section
which, for each VimHook script, shows a checkbox indicating the
enabled/disabled state of the script (checked means enabled), the matching
suffix (where `*` represents a UNIX-style blob), the `autocommand` event which
triggers the script, and the path to the script.  The `x` mapping is
particularly useful as it allows you to quickly toggle on and off individual
VimHook scripts as you move between projects that require different hooks.

Pressing `s`, `i`, `o`, or `<CR>` will open the hook file for editing in one
way or another. If you make changes to a hook file and save it, the plugin
will automatically pick up those changes. Isn't that nice? It does this by
listening for `BufWritePost` events on `*vimhook*`-patterned filenames and
re-running `:FindHookFiles` for you.

![ListVimHooks GIF](http://g.recordit.co/o3mon5FhWu.gif)

_Note: this gif is slightly out of date. The :ListVimHooks command has since
been modified to always list active VimHook scripts first at the top of the
**Hooks** section before listing the inactive ones._

The buffer-local mappings are inspired from NERDTree:
- `x` Toggles the enabled/disabled state of a VimHook script (this only has an effect when the cursor is on one of the lines in the "Hooks" section.
- `d` delete a VimHook (runs `rm -i` so you will be prompted to confirm)
- `r` run a VimHook manually in "debug" mode (it runs `:!VIMHOOK_PATH CONTENT_OF_#_REGISTER VIMHOOK_EVENTNAME` so all output is echoed to screen)
- `s` Opens a VimHook script in a vertical split
- `i` Opens a VimHook script in a horizontal split
- `o` Opens a VimHook script in the previous window. (If not possible, it will open in a vertical split.)
- `<CR>` Opens a VimHook script in the current window

FindHookFiles
-------------
The `:FindHookFiles` command re-runs the same initializing logic VimHooks
runs when you start Vim with the plugin installed. It will "forget" any VimHook
scripts it may have previously found and re-scan the current working directory
as well as the `~/.vimhooks/` directory. Use this command if you have created a
new VimHook script and want to start using it without closing and re-opening
your entire Vim session.

ExecuteHookFiles
----------------
The `:ExecuteHookFiles` command takes a single argument which is the name of
a Vim `autocmd` you would like to manually "trigger." The event name can be
tab-completed. For example, if you would like to verify the VimHook scripts
listening for the `VimEnter` event are functioning correctly you can manually
fire them off by running `:ExecuteHookFiles VimEnter`.

StopExecutingHooks
------------------
The `:StopExecutingHooks` command will temporarily disable triggering of all VimHook scripts.

StartExecutingHooks
-------------------
The `:StartExecutingHooks` command turns VimHook script triggering back on.

Permissions
============
Ensure that your VimHook scripts have the "execute" bit set. For example,

```
$ chmod u+x .bufwritepost.vimhook.sh
```

If they do not, VimHooks will ask if you want to set the executable bit
before running a script for the first time. If you type `y`, it will run the
above shell command and then execute the hook script. If you type `n`, it
will leave the permissions as-is and then *ignore that script for the
duration of your Vim session.*

![Set Permissions GIF](http://g.recordit.co/I4hxwkypZo.gif)

Which autocmd events are exposed by Vim Hooks?
==============================================
Currently, VimHooks responds to

- `BufAdd`
- `BufNew`
- `VimEnter`
- `VimLeave`
- `BufEnter`
- `BufLeave`
- `BufDelete`
- `BufUnload`
- `BufWinLeave`
- `BufReadPost`
- `BufWritePost`

Adding others is not difficult, but I thought there could be a negative
performance impact if VimHooks was setting up listeners for _every_ Vim
`autocmd` event. I haven't actually tested whether or not this is true because
so far my use cases are covered with the few events listed above.

For reference, the full list of all available `autocmd` events and a
description of what triggers each event is available [in the Vim
documentation](http://vimdoc.sourceforge.net/htmldoc/autocmd.html#autocmd-events)
or by running `:help autocmd-events`. If you want to include other events
manually you can tweak the plugin by just following the example of what is
already in place for `BufWritePost`, `CursorHold`, and the other events listed
above (you'll find them easily by grepping the code). You can also raise an issue
or pull request.

Example Usage
=============
- [Restart your Jekyll preview server on file write](https://github.com/ahw/vim-hooks/blob/master/examples/090.bufwritepost.vimhook.restart-jekyll-server.sh)
- [Reload Chrome tabs on file write](https://github.com/ahw/vim-hooks/blob/master/examples/100.bufwritepost.vimhook.chrome-reloader.sh)
- [Reload Chrome, Firefox, and Safari on file write](https://github.com/ahw/vim-hooks/blob/master/examples/bufwritepost.vimhook.reload-browsers.applescript)
- [Recompile Sass files on file write](https://github.com/ahw/vim-hooks/blob/master/examples/scss.bufwritepost.vimhook.recompile-sass.sh)
- [Execute SQL via sqlite3 on file write](https://github.com/ahw/vim-hooks/blob/master/examples/sql.bufwritepost.vimhook.sh)
- [Dump stdout from a hook into a scratch buffer](https://github.com/ahw/vim-hooks/blob/master/examples/test.js.bufwritepost.vimhook.buffer-output.sh)

Footnotes
=========
<sup>1</sup> Actually, VimHooks only iterates over all the hook files for the
very first trigger of some new filename/event combination. It then populates a cache
which is accessed whenever that same filename/event combination is fired
again.
