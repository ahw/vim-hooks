![VimHooks](https://pd93f014.s3.amazonaws.com/vim-hooks.svg?v=1)

- [Introduction](#introduction)
- [Demos](#demos)
    - [Sass Recompilation and Browser Reload](#sass-recompilation-and-browser-reload)
    - [**New!** Vim as REPL](#vim-as-repl)
- [Installation](#installation)
- [How it works](#how-it-works)
    - [**New!** VimHook naming pattern](#vimhook-naming-pattern)
    - [Arguments provided to a hook script](#arguments-provided-to-a-hook-script)
- [**New!** VimHook Options](#vimhook-options)
    - [How to set options](#how-to-set-options)
    - [Available options](#available-options)
    - [Set options globally](#set-options-globally)
- [Commands](#commands)
    - [ListVimHooks (useful!)](#listvimhooks)
    - [FindHookFiles](#findhookfiles)
    - [ExecuteHookFiles](#executehookfiles)
    - [StopExecutingHooks](#stopexecutinghooks)
    - [StartExecutingHooks](#startexecutinghooks)
- [Permissions](#permissions)
- [Which autocmd events are exposed by vim-hooks?](#which-autocmd-events-are-exposed-by-vim-hooks)
- [Example usage](#example-usage)
    - [Recompile Sass files on save](#recompile-sass-files-on-save)
    - [Reload Chrome tabs after recompiling Sass files](#reload-chrome-tabs-after-recompiling-sass-files)
    - [Reload Chrome tabs after recompiling Sass files on remote machine](#reload-chrome-tabs-after-recompiling-sass-files-on-a-remote-machine)
    - [Reload Chrome tabs and the active Safari tab in Mac OSX after recompiling Sass files on remote machine](#reload-chrome-tabs-and-the-active-safari-tab-in-mac-osx-after-recompiling-sass-files-on-remote-machine)
    - [Reload Chrome tabs and the active Safari tab and the active Firefox tab in Mac OSX after recompiling Sass files on remote machine](#reload-chrome-tabs-and-the-active-safari-tab-and-the-active-firefox-tab-in-mac-osx-after-recompiling-sass-files-on-remote-machine)
    - [**New!** Dump standard output of hook script into scratch buffer](#dump-standard-output-of-hook-script-into-scratch-buffer)

Introduction
============
This is a Vim plugin that lets you automatically execute arbitrary shell
scripts after specific `autocmd` events are fired while editing certain files.
It does this by looking for specially-named scripts  in your current working
directory (as well as `~/.vimhooks/`) that have names like
`.bufwritepost.vimhook.rb` or `.cursorhold.vimhook.sh` and executes those
scripts whenever &ndash; in this example &ndash; Vim fires the `BufWritePost`
and `CursorHold` `autocmd` events, respectively.

VimHook scripts, which I refer to as "hook scripts," or just "hooks" throughout
this document, can live at the project level or at a global level in
`~/.vimhooks/`. They can be disabled by appending ".disabled" to the filename.
Finally, although I'm getting a little ahead of myself here, the
`:ListVimHooks` command provides a listing of all enabled and disabled hook
scripts available in a particular session and from there, each hook can easily be
toggled on and off interactively.

I wrote this plugin specifically to ease the write-save-switch-reload pain of
web development, and although my most salient use case so far is the ability to
auto-reload Chrome, Firefox, and Safari tabs after a single file save (`:w`) in
Vim (see obnoxious flashing gif below), I have a feeling there are a lot of
other interesting use cases out there. Recently I've added the ability to use
Vim as a sort of REPL. If you've ever wanted an easy way of hooking arbitrary
shell scripts into Vim events, this plugin is for you.

In the next sections I'll describe how to install the **vim-hooks** plugin,
give a bit of background on `autocommands` and events in Vim, and then explain
in detail how to use **vim-hooks**, what additional options are available,
and what commands the plugin exposes. If you are not familiar with
`autocommand`s in Vim, run `:help autocommand` for an overview.

Demos
=====
Here is your obligatory set of live-demo gifs. The first is the original
example I have used since creating this plugin, and the second is one I
created recently, which makes use of the new "buffer output" feature.

### Sass Recompilation and Browser Reload
_Recompile a Sass file and then reload Chrome, Firefox, and Safari using
AppleScript._

![VimHooks Reload GIF](http://g.recordit.co/CITvKXJOFe.gif)

### Vim as REPL
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
filename), VimHooks looks through the list of all hook scripts in the current
working directory and `~/.vimhooks/`, and executes those hooks whose **event**
property is **E** and whose **matching suffix** matches **F**.
These and other properties are embedded in the hook script filename itself and
follow a specific naming pattern so that the plugin can parse them out. This pattern
is described in the next section.
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
dot marking its place.

Arguments provided to a hook script
-----------------------------------
Each script is passed the name of the current buffer and the triggered event
name as command-line arguments. So in a Bash shell script you could, for
example, use `$1` and `$2` to access these values. The plugin only supports
synchronous execution of VimHook scripts.

VimHook Options
===============
As of release [1.4.1](https://github.com/ahw/vim-hooks/releases/tag/1.4.1),
VimHook supports additional functionality that is exposed by setting various
VimHook _options_. The option flags are set _in the source code_ of the hook
script itself (as opposed to a config file &mdash; I am trying to keep the
overhead of this plugin as minimal as possible).

### How to set options
During initialization, **vim-hooks** scans through the contents of each
VimHook script and parses out any option flags it finds, and then applies
them to that hook script for the duration of the session. To set an option
flag and value in your VimHook script, add a line anywhere in the file that
follows the convention `vimhook.myOptionKey = myOptionValue`. The line can
begin with anything you want (like a comment character) but should not have
anything after the `myOptionValue` part. Whitespace around the `=` sign is
irrelevant. You can use a `:` instead of an `=` sign if you prefer.

![VimHook Options Grammar](https://pd93f014.s3.amazonaws.com/vimhook-option-grammar-1.svg)

_The full grammar of a VimHook option line. Source: [www.regexper.com](http://www.regexper.com/#vimhook%5C.%28%5B%5Cw%5C.%5D%2B%29%5Cs%2A%5B%3A%3D%5D%3F%5Cs%2A%28%5Cw%2A%29%2524)_
![CC BY License](https://licensebuttons.net/l/by/3.0/80x15.png)

For example, the following lines are all equivalent ways of setting the
option `myOption` to `true`. Notice (in the last line) that you are not
forced to set an option value. If you only provide an option key, the value
will be automatically set to `true`.

```
# vimhook.myOption = true
// vimhook.myOption : true
-- vimhook.myOption:1
// foo bar baz vimhook.myOption
```

The following are all equivalent ways of setting the `myOption` key to
`false`.
```
# vimhook.myOption = false
>>> vimhook.myOption : false
" vimhook.myOption:0
```
### Available options

Option Key                  | Behavior
---                         | ---
vimhook.bufferoutput        | When true, dump the stdout from this hook script into a new scratch buffer, opened automatically in a new window. If the buffer already exists, overwrite it and refresh the window. When false, VimHook scripts are executed silently. (Default: false.)
vimhook.bufferoutput.vsplit | When true, open the buffer output window in a vertical split instead of the default horizontal. When false or omitted, buffer output window is opened in a horizontal split. This option is only relevant when `vimhook.bufferoutput` is `true`. (Default: false.)

### Set options globally

All of the options listed above can be overridden on a global level in your
`~/.vimrc` file. Each option key has a corresponding global variable name
that **vim-hooks** will check for and use if it exists. These are documented in the table below.

Option Key                  | Global variable name used for overriding
---                         | ---
vimhook.bufferoutput        | g:vimhooks\_bufferoutput
vimhook.bufferoutput.vsplit | g:vimhooks\_bufferoutput\_vsplit

Global option settings are applied first and overridden on a per-hook basis
wherever they are used. For example, if your `~/.vimrc` contains

```vim
let g:vimhooks_bufferoutput_vsplit = 1
```

then buffer output windows will always open in a vertical split unless there
is a `vimhook.bufferoutput.vsplit = 0` option setting in some particular hook
script.

Commands
========
ListVimHooks
------------
The `:ListVimHooks` command takes zero arguments. It opens a new
unmodifiable buffer in a horizontal split which lists all of the VimHook script
files the plugin has found after scanning the current working directory as
well as the `~/.vimhooks/` directory. The buffer has a few buffer-only key
mappings that allow you to interactively disable and re-enable VimHook scripts
as well as open them in a new window. Below is a screenshot of the
`:ListVimHooks` buffer demonstrating this functionality.

Note there are two sections in this buffer: the **Mappings** section which shows
a "cheat sheet" of the buffer-local mappings and the **Hooks** section which, for
each VimHook script, shows a checkbox indicating enabled/disabled state of the
script, the matching pattern associated with that script (where `*` represents
a UNIX-style blob), the event associated with that script, and the path to the
script. The `x` mapping is particularly useful as it allows you to quickly
toggle on and off individual VimHook scripts as you move between projects that
require different hooks.

![ListVimHooks GIF](http://g.recordit.co/o3mon5FhWu.gif)

_Note: this gif is slightly out of date. The :ListVimHooks command has since
been modified to always list active VimHook scripts first at the top of the
**Hooks** section before listing the inactive ones._

The buffer-local mappings are inspired from NERDTree:
- `x` Toggles the enabled/disabled state of a VimHook script (this only has
  an effect when on one of the lines in the "Hooks" section.
- `s` Opens a VimHook script in a vertical split
- `i` Opens a VimHook script in a horizontal split
- `o`, `<CR>` Opens a VimHook script in the previous window. (If not possible, it
  will open in a vertical split.)
- `q`, `<ESC>` Closes the buffer

FindHookFiles
-------------
The `:FindHookFiles` command re-runs the same initializing logic **vim-hooks**
runs when you start Vim with the plugin installed. It will "forget" any VimHook
scripts it may have previously found and re-scan the current working directory
as well as the `~/.vimhooks/` directory. Use this command if you have created a
new VimHook script and want to start using it without closing and re-opening
your entire Vim session. If you've set any new VimHook options in your
scripts since starting Vim you'll need to run this command to pick those up
too.

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
Currently, **vim-hooks** responds to

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
performance impact if **vim-hooks** was setting up listeners for _every_ Vim
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
As mentioned previously, this plugin was motivated by the pain of the
save-switch-reload cycle between editor and browser that eats up so much time
in web development. The examples that follow show off how quickly you can
exploit this plugin to speed up that iteration time. While I have found a
number of editors which are able to "live preview" raw CSS changes or HTML
changes, their capabilities almost always end there. How about when you need to
minify and closure-compile your JavaScript? And compile and minify your Sass
files? Maybe you need to copy them to another place in the filesystem.

Recently I've also added the ability to use Vim as a sort of REPL by passing in
the `vimhook.bufferoutput` option flag in the source of any VimHook script.
With that option flag set, VimHooks will dump the stdout from the hook script
into its own Vim buffer which opens automatically in a new window.  When the
hook script is run again, that buffer is automatically refreshed. Now you can
start writing code and see the results immediately without leaving Vim. I find
it insanely useful in particular when trying to hammer out some new code and
can only half remember the API of some library I'm using.

**Jump to Individual Examples**

- [Recompile Sass files on save](#recompile-sass-files-on-save)
- [Reload Chrome tabs after recompiling Sass files](#reload-chrome-tabs-after-recompiling-sass-files)
- [Reload Chrome tabs after recompiling Sass files on remote machine](#reload-chrome-tabs-after-recompiling-sass-files-on-a-remote-machine)
- [Reload Chrome tabs and the active Safari tab in Mac OSX after recompiling Sass files on remote machine](#reload-chrome-tabs-and-the-active-safari-tab-in-mac-osx-after-recompiling-sass-files-on-remote-machine)
- [Reload Chrome tabs and the active Safari tab and the active Firefox tab in Mac OSX after recompiling Sass files on remote machine](#reload-chrome-tabs-and-the-active-safari-tab-and-the-active-firefox-tab-in-mac-osx-after-recompiling-sass-files-on-remote-machine)
- [**New!** Dump standard output of hook script into scratch buffer](#dump-standard-output-of-hook-script-into-scratch-buffer)

Recompile Sass files on save
----------------------------
Here is a two-line shell script, `.234.bufwritepost.vimhook.sh` which calls
the `sass` compiler after each `BufWritePost` event on `*.scss` files.
Remember that the ".234" part of the VimHook script can be number you want,
or left off entirely.

> **.234.bufwritepost.scss.vimhook.sh**
>
> ```sh
> #!/bin/sh
> sass style.scss style.css
> ```

Reload Chrome tabs after recompiling Sass files
-----------------------------------------------
Install the [chrome-stay-fresh](https://github.com/ahw/chrome-stay-fresh)
Chrome extension. It requires some manual fiddling to get it up and running,
but once you do, any `GET /reload HTTP/1.1` requests to `localhost:7700` will
trigger a reload of whatever tabs you've selected with the extension. If you
want a solution that doesn't involve installing a Chrome extension but only
works on Mac OSX, see the examples using AppleScript further on down.

> **.bufwritepost.scss.vimhook.sh**
>
> ```sh
> #!/bin/sh
>
> sass style.scss style.css
>
> # In a nutshell, the Chrome extension mentioned above listens for these
> # requests and reloads the appropriate tabs when they occur.
> curl "localhost:7700/reload"
> ```

Reload Chrome tabs after recompiling Sass files on a remote machine
-------------------------------------------------------------------
This leverages a powerful feature of SSH called **port forwarding**, which
allows you to forward data from your remote machine back to your client
machine, through an SSH tunnel. Here we will set things up such that
requests made to port 7700 on the remote machine are forwarded to port 7700
on the client machine. Remember that this is the port
[chrome-stay-fresh](https://github.com/ahw/chrome-stay-fresh) is listening
on to know when to reload your selected tabs in the browser.

The first part of the setup is the same as before:
> Install the [chrome-stay-fresh](https://github.com/ahw/chrome-stay-fresh)
> Chrome extension.  It requires some manual fiddling to get it up and running,
> but once you do, any `GET /reload HTTP/1.1` requests to `localhost:7700` will
> trigger a reload of whatever tabs you've selected with the extension.

Now, `ssh` into the remote host with remote port forwarding configured as
follows:

```sh
ssh your-remote-host -R 7700:localhost:7700 # forwards requests on 7700 to your client's 7700
```

Create this `bufwritepost.vimhook.sh` file which will recompile `style.scss`
and then, via SSH port forwarding, make an HTTP request to
your **client** machine listening on port 7700 to reload Chrome tabs.

> **.bufwritepost.vimhook.sh** (on **your-remote-host**)
>
> ```sh
> #!/bin/sh
>
> sass style.scss style.css
>
> curl "localhost:7700/reload"
> ```

Reload Chrome tabs and the active Safari tab in Mac OSX after recompiling Sass files on remote machine
------------------------------------------------------------------------------------------------------
This makes use of the above port-forwarding along with a piece of slightly
hacky Applescript to reload the active tab in Safari.

> **.bufwritepost.vimhook.sh** (on the **remote-host**)
>
> ```sh
> #!/bin/sh
>
> sass style.scss style.css
>
> # Note: assumes you have mac-laptop set up in your ~/.ssh/config file.
> # Obviously it helps if you have password-less access configured with SSH
> # certificates.
> curl "localhost:7700/reload"
> ssh mac-laptop 'osascript ~/refresh_safari.applescript'
> ```
 
&nbsp;
> **refresh_safari.applescript** (on the **mac-laptop** host)
> ```applescript
> tell application "Safari"
>     set sameURL to URL of current tab of front window
>     set URL of current tab of front window to sameURL
> end tell
> ```
> Source: [thelowlypeon, refresh_safari.applescript](https://github.com/thelowlypeon/refresh-safari/blob/master/refresh_safari.applescript)

Reload Chrome tabs and the active Safari tab and the active Firefox tab in Mac OSX after recompiling Sass files on remote machine
---------------------------------------------------------------------------------------------------------------------------------
One file save, three browser reloads. Great stuff. It's a little hacky in that
assumes you only want to refresh a single tab in each browser and that this tab
is your current active tab in each browser. In this example I am using the
same piece of Applescript functionality to reload each browser tab.

> **.bufwritepost.vimhook.sh** on the **remote-host** host
>
> ```sh
> #!/bin/sh
>
> sass style.scss style.css
>
> # Note: assumes you have mac-laptop set up in your ~/.ssh/config file.
> # Obviously it helps if you have password-less access configured with SSH
> # certificates.
> ssh mac-laptop 'osascript ~/refresh_all_browsers.applescript'
> ```

&nbsp;
> **refresh_all_browsers.applescript**
>
> ```applescript
> tell application "Safari"
>     activate
>     tell application "System Events" to keystroke "r" using command down
> end tell
> 
> tell application "Chrome"
>     activate
>     tell application "System Events" to keystroke "r" using command down
> end tell
> 
> tell application "Firefox"
>     activate
>     tell application "System Events" to keystroke "r" using command down
> end tell
> ```

Dump standard output of hook script into scratch buffer
-------------------------------------------------------

![VimHooks Buffer SQL Output GIF](http://pd93f014.s3.amazonaws.com/test-out-4.gif)

> **demo.sql**
>
> ```sql
> .mode column
> .width 5 19 50
> .headers ON
> 
> SELECT
>     handle.ROWID,
>     datetime(message.date + 978307200, 'unixepoch', 'localtime') AS 'time',
>     message.text
> FROM message JOIN handle ON (message.handle_id = handle.ROWID)
> WHERE
>     time > DATE('2011-08-01')
> ORDER BY message.date ASC LIMIT 30;
> 
> .exit
> ```

&nbsp;
> **demo.sql.bufwritepost.vimhook.002.sh**
>
> ```sh
> #!/bin/sh
>
> vimhook.bufferoutput
> vimhook.bufferoutput.vsplit = false
>
> sqlite3 sms_database < $1
> ```
