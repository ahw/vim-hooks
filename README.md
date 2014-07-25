Vim Hooks
=========
This is a Vim plugin that looks for scripts in `~/.vimhooks/`, and your
current working directory, that have names like `.bufwritepost.vimhook.rb`
or `.cursorhold.vimhook.sh` and executes those scripts whenever &ndash; in
this example &ndash; Vim fires the `BufWritePost` and `CursorHold` `autocmd`
events, respectively. I wrote this plugin specifically to ease the
write-save-switch-reload pain of web development, and my most salient use
case so far is the ability to auto-reload Chrome, Firefox, and Safari tabs
after a single file save (`:w`) in Vim, though I have a feeling there are a
lot of other interesting use cases out there. If you've ever wanted an easy
way of hooking arbitrary shell scripts into Vim events, this is for you.

In the next sections I'll describe how to install the **vim-hooks** plugin,
give a bit of background on `autocommands` and events in Vim, and then explain
in detail how to use **vim-hooks**.

Installation
------------
If you don't have a preferred installation method, I recommend
installing [pathogen.vim](https://github.com/tpope/vim-pathogen), and
then simply copy and paste:

    cd ~/.vim/bundle
    git clone https://github.com/ahw/vim-hooks.git

Background: What is an autocommand?
-----------------------------------
> You can specify commands to be executed automatically when reading or
> writing a file, when entering or leaving a buffer or window, and when
> exiting Vim.  For example, you can create an autocommand to set the
> 'cindent' option for files matching \*.c.  You can also use autocommands
> to implement advanced features, such as editing compressed files (see
> |gzip-example|).  The usual place to put autocommands is in your .vimrc or
> .exrc file.
>
> Source: `:help autocommands`

How to name VimHook scripts
---------------------------
The **vim-hooks** plugin relies on specific filename patterns in order to
figure out which scripts to execute after a given `autocmd` event. I'll try to
refer to these scripts consistently as "VimHook" scripts throughout. There are
three flavors of VimHook scripts:

1. VimHook scripts that are **global**, meaning they are executed every time the
   appropriate event is triggered in Vim, regardless of what file you're
   editing.
2. VimHook scripts that are **extension-specific**, meaning they are executed
   every time the appropriate event is triggered in Vim _and_ the filename
   of the current buffer has an extension corresponding to that which is
   specified in the VimHook filename. For example, you could create a VimHook
   script which is executed only when `*.js` files are changed.
3. VimHook scripts that are **file-specific**. These are executed only when the
   appropriate event is fired in Vim _and_ the filename of the current
   buffer is exactly that which is specified in the VimHook filename. For
   example, you could create a VimHook script which is executed only when
   `some-special-file.html` changes.

Each script is passed the name of the current buffer and the triggered event
name as command-line arguments. So in a Bash shell script you could, for
example, use `$1` and `$2` to access these values (see [example
usage](/#example-usage)). Currently this plugin only supports synchronous
execution of the `*.vimhook` scripts, but I hope to implement asynchronous
execution later.
   
Global VimHooks
---------------
_A note on notation: I'm using the UNIX-style convention of enclosing
optional parts of a pattern in square brackets and representing "blobs" with
`*`. The `.` should be taken literally._

The format of global VimHook filenames is `[.sortkey].eventname.vimhook[.*]`,
where `sortkey` is optional and can be whatever integer you want and
`eventname` is any valid Vim `autocmd` event (case-insensitive). You are
free to add any arbitrary stuff to the end of the filename, though I think
it looks clean if you simply add the normal extension corresponding to the
language your script is in and leave it at that.

If you would like to have multiple scripts reacting to the same `eventname`
simply name the files using a different `sortkey` for each. When there are
multiple VimHook scripts with the same `eventname` they will be executed
serially according to the lexographic ordering of their filenames.  Thus,
you can choose your `sortkey`s strategically if you have several scripts
which need to run in a specific order (for example,
`000.bufwritepost.vimhook.sh`, `100.bufwritepost.vimhook.sh`).

Extension-specific VimHooks
--------------------------
The format of extension-specific VimHook filenames is
`[.sortkey].eventname.ext.vimhook[.*]`, where `sortkey` is optional and can be
whatever integer you want, `eventname` is any valid Vim `autocmd` event
(case-insensitive), and `ext` is whatever filename extension you want to
react to. For example, `.bufwritepost.scss.vimhook` will only be executed
when the `BufWritePost` event is fired on `*.scss` files.

File-specific VimHooks
--------------------------
The format of file-specific VimHook filenames is
`filename.eventname.vimhook[.*]`, where `filename` is the full name you want to
react to and `eventname` is any valid Vim `autocmd` event
(case-insensitive). In other words, you simply need to append
`eventname.vimhook[.*]` to whatever file you want the hook to be associated
with. For example, the VimHook named `README.md.bufwritepost.vimhook.py` will
only be executed when the `BufWritePost` event is fired from the `README.md`
buffer; the VimHook named `app.js.bufenter.vimhook.py`  will only be executed
when the `BufEnter` evente is fired from the `app.js` buffer.


What autocmd events are exposed in by Vim Hooks?
------------------------------------------------
Currently, **vim-hooks** responds to
- `VimEnter`
- `VimLeave`
- `BufEnter`
- `BufLeave`
- `CursorHold`
- `BufWritePost`
- `CursorMoved`

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

Example usage
-------------
As mentioned previously, this plugin was motivated by the pain of the
save-switch-reload cycle between editor and browser that eats up so much time
in web development. The examples that follow show off how quickly you can
exploit this plugin to speed up that iteration time. I have found a number of
editors which are able to "live preview" raw CSS changes or HTML changes, but
how about when you need to minify and closure-compile your JavaScript? And
compile and minify your Sass files? And you're working off a remote server? And
you'd really like to see the results updated in more than just Chrome? All of
that is now possible, and I have to say, it's pretty awesome.

### Recompile Sass files on save
This shows an example working tree and the contents of a two-line shell script,
`.234.bufwritepost.vimhook.sh` which calls the `sass` compiler.  Remember that
the ".234" part of the VimHook script can be number you want, or left off
entirely.

```
.
├── style.scss
├── style.css
├── _colors.scss
└── .234.bufwritepost.vimhook.sh
```

> **.234.bufwritepost.vimhook.sh**
>
> ```sh
> #!/bin/sh
> sass style.scss style.css
> ```

### Reload Chrome tabs after recompiling Sass files
Install the [chrome-stay-fresh](https://github.com/ahw/chrome-stay-fresh)
Chrome extension. It requires some manual fiddling to get it up and running,
but once you do, any `GET /reload HTTP/1.1` requests to `localhost:7700` will
trigger a reload of whatever tabs you've selected with the extension. If you
want a solution that doesn't involve installing a Chrome extension but only
works on Mac OSX, see the examples using AppleScript further on down.

An example working tree:
```
.
├── .bufwritepost.vimhook.sh
├── _colors.scss
├── src
│   ├── app.js
│   ├── models.js
│   └── views.js
├── style.css
└── style.scss
```

> **.bufwritepost.vimhook.sh**
>
> ```sh
> #!/bin/sh
> sass style.scss style.css
> curl "localhost:7700/reload"
> ```

### Reload Chrome tabs after recompiling Sass files on a remote machine
This leverages a powerful feature of SSH called **port forwarding**, which
allows you to &ndash; among other things &ndash; forward data from your remote machine back
to your client machine, through an SSH tunnel. Here we will set things up such
that requests made to port 7700 on the remote machine are forwarded to port
7700 on the client machine. Remember that this is the port
[chrome-stay-fresh](https://github.com/ahw/chrome-stay-fresh) is listening on
to know when to reload your selected tabs in the browser.

The first part of the setup is the same as before:
> Install the [chrome-stay-fresh](https://github.com/ahw/chrome-stay-fresh)
> Chrome extension.  It requires some manual fiddling to get it up and running,
> but once you do, any `GET /reload HTTP/1.1` requests to `localhost:7700` will
> trigger a reload of whatever tabs you've selected with the extension.

Now, `ssh` into the remote host with remote port forwarding configured as
follows:

```sh
ssh remote-host -R 7700:localhost:7700 # forwards requests on 7700 to your client's 7700
```

Create this `bufwritepost.vimhook.sh` file which will recompile `style.scss`
and then &ndash; via SSH port forwarding &ndash; make an HTTP request to
your **client** machine listening on port 7700 to reload Chrome tabs.

> **.bufwritepost.vimhook.sh** (on the **remote-host**)
>
> ```sh
> #!/bin/sh
> sass style.scss style.css
> curl "localhost:7700/reload"
> ```

### Reload Chrome tabs and the active Safari tab in Mac OSX after recompiling Sass files on remote machine
This makes use of the above port-forwarding along with a piece of slightly
hacky Applescript to reload the active tab in Safari.

> **.bufwritepost.vimhook.sh** (on the **remote-host**)
>
> ```sh
> #!/bin/sh
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

### Reload Chrome tabs and the active Safari tab and the active Firefox tab in Mac OSX after recompiling Sass files on remote machine

One file save, three browser reloads. Great stuff. It's a little hacky in that
assumes you only want to refresh a single tab in each browser and that this tab
is your current active tab in each browser. In this example I am using the
same piece of Applescript functionality to reload each browser tab:

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

I then simply configure `bufwritepost.vimhook.sh` to run this script over SSH:

> **.bufwritepost.vimhook.sh** on the **remote-host** host
>
> ```sh
> #!/bin/sh
> # Note: assumes you have mac-laptop set up in your ~/.ssh/config file.
> # Obviously it helps if you have password-less access configured with SSH
> # certificates.
> ssh mac-laptop 'osascript ~/refresh_all_browsers.applescript'
> ```

### Log editing events for future analytics

My only non-webdev example. I don't know, maybe you're into collecting data.
This will log out timestamps each time you enter and exit a new buffer in
Vim. Your working tree is below. Note that `.bufleave.vimhook.sh` is sym-linked
to `.bufenter.vimhook.sh` so the same script is used to handle two events.

```
.
├── .bufenter.vimhook.sh
├── .bufleave.vimhook.sh -> .bufenter.vimhook.sh # this is a symlink
├── _colors.scss
├── src
│   ├── app.js
│   ├── models.js
│   └── views.js
├── style.css
└── style.scss
```

> **.bufenter.vimhook.sh**
>
> ```sh
> #!/bin/sh
> FILENAME=$1
> EVENTNAME=$2
> echo "${EVENTNAME} for file ${FILENAME} on `date`" >> /tmp/vim-buffer-log.log
> ```

Sample content of the log file:
```
bufenter for file app.js on Sun Jun 15 19:09:13 PDT 2014
bufenter for file views.js on Sun Jun 15 19:09:16 PDT 2014
bufleave for file views.js on Sun Jun 15 19:09:16 PDT 2014
bufenter for file views.js on Sun Jun 15 19:09:16 PDT 2014
bufenter for file app.js on Sun Jun 15 19:09:16 PDT 2014
bufenter for file models.js on Sun Jun 15 19:09:19 PDT 2014
bufleave for file models.js on Sun Jun 15 19:09:20 PDT 2014
bufenter for file app.js on Sun Jun 15 19:09:20 PDT 2014
bufleave for file models.js on Sun Jun 15 19:09:21 PDT 2014
bufenter for file style.scss on Sun Jun 15 19:09:21 PDT 2014
bufleave for file style.scss on Sun Jun 15 19:09:22 PDT 2014
bufenter for file app.js on Sun Jun 15 19:09:22 PDT 2014
bufleave for file style.scss on Sun Jun 15 19:09:23 PDT 2014
bufenter for file _colors.scss on Sun Jun 15 19:09:23 PDT 2014
bufleave for file _colors.scss on Sun Jun 15 19:10:04 PDT 2014
bufenter for file app.js on Sun Jun 15 19:10:04 PDT 2014
bufleave for file app.js on Sun Jun 15 19:10:05 PDT 2014
bufenter for file _colors.scss on Sun Jun 15 19:10:05 PDT 2014
```

Upcoming features
-----------------
- Support wildcard event names so that we don't have to symlink the vim-hook
  scripts.
- Come up with a way to write files without triggering the VimHook scripts.
  Like sometimes you're just editing the README of your project and don't really
  want to trigger all those hooks.
- Asynchronous execution of hook files.
- ~~Allow VimHook scripts to end in arbitrary extensions so that users can
  easily get the syntax highlighting, etc. that they expect when editing
  files in different languages.~~
- Documentation.
