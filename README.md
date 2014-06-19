Vim Hooks
=========
This is a Vim plugin that looks for specially-named scripts in your current
working directory like `.bufwritepost.vimhook` or `.cursorhold.vimhook` and
executes those scripts whenever &ndash; in this example &ndash; Vim fires the
`BufWritePost` and `CursorHold` events, respectively. I wrote this plugin
specifically to ease the write-save-switch-reload pain of web development, and
my examples for auto-reloading Chrome, Firefox, and Safari after each file
write are given below. I have a feeling there are a lot of other interesting
use cases out there. If you've ever wanted an easy way of hooking arbitrary
stuff into Vim events, this is for you.

Now, some more details on these "specially-named scripts." I'll try to refer
to them consistently as "vimhook" scripts throughout. There are three
flavors of these vimhook scripts:
1. VimHook scripts that are global, meaning they are executed every time the
   appropriate event is triggered in Vim.
2. VimHook scripts that are extension-specific, meaning they are executed
   every time the appropriate event is triggered in Vim _and_ the filename
   of the current buffer has an extension matching that specific in the
   VimHook filename.
3. VimHook scripts that are filename-specific. These are executed _only_
   when the appropriate event is fired in Vim _and_ the filename of the
   current buffer is exactly that specified in the VimHook filename.
   
Global VimHooks
---------------
The general format of global vimhook filenames is
`[.sortkey].eventname.vimhook`, where `sortkey` is optional and can be
whatever integer you want and `eventname` is any valid Vim `autocmd` event
(case-insensitive). The filename must end in `.vimhook` (for now anyway; I'm
considering changing the naming convention to accomodate some other use
cases).  If you would like to have multiple scripts reacting to the same
`eventname` simply name the files using a different `sortkey` for each. When
there are multiple vimhook scripts with the same `eventname` they will be
executed serially according to the lexographic ordering of their filenames.
Thus, you can choose your `sortkey`s strategically if you have several
scripts which need to run in a specific order (for example,
`000.bufwritepost.vimhook`, `100.bufwritepost.vimhook`).

Extension-specific VimHooks
--------------------------

> TODO

Filename-specific VimHooks
--------------------------

> TODO

Each script is passed the name of the current buffer and the triggered event
name as command-line arguments. So in a Bash shell script you could, for
example, use `$1` and `$2` to access these values (see [example
usage](/#example-usage). Currently this plugin only supports synchronous
execution of the `*.vimhook` scripts.

Installation
------------
If you don't have a preferred installation method, I recommend
installing [pathogen.vim](https://github.com/tpope/vim-pathogen), and
then simply copy and paste:

    cd ~/.vim/bundle
    git clone https://github.com/ahw/vim-hooks.git

Background: what is an autocommand?
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
above (you'll find it easily by grepping the code). You can also raise an issue
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
that is now possible, and I have to say, I it's pretty awesome.

### Recompile Sass files on save
This shows an example working tree and the contents of a two-line shell script,
`.recompile-styles.bufwritepost.vimhook` which calls the `sass` compiler.
Remember that the ".234" part of the vimhook script can be number you want,
or left off entirely.

```
.
├── style.scss
├── style.css
├── _colors.scss
└── .234.bufwritepost.vimhook
```

> **.234.bufwritepost.vimhook**
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
├── .bufwritepost.vimhook
├── _colors.scss
├── src
│   ├── app.js
│   ├── models.js
│   └── views.js
├── style.css
└── style.scss
```

> **.bufwritepost.vimhook**
>
> ```sh
> #!/bin/sh
> sass style.scss style.css
> curl "localhost:7700/reload"
> ```

### Reload Chrome tabs after recompiling Sass files on a remote machine
Same as the above:
> Install the [chrome-stay-fresh](https://github.com/ahw/chrome-stay-fresh)
> Chrome extension.  It requires some manual fiddling to get it up and running,
> but once you do, any `GET /reload HTTP/1.1` requests to `localhost:7700` will
> trigger a reload of whatever tabs you've selected with the extension.

Now, `ssh` into the remote host with remote port forwarding configured as
follows:

```sh
ssh remote-host -R 7700:localhost:7700 # forwards requests on 7700 to your client's 7700
```

> **.bufwritepost.vimhook**
>
> ```sh
> #!/bin/sh
> sass style.scss style.css
> curl "localhost:7700/reload"
> ```

### Reload Chrome tabs and the active Safari tab in Mac OSX after recompiling Sass files on remote machine
This leverages a powerful feature of SSH called **port forwarding**, which
allows you to &ndash; among other things &ndash; forward data from your remote machine back
to your client machine, through an SSH tunnel. Here we will set things up such
that requests made to port 7700 on the remote machine are forwarded to port
7700 on the client machine. Remember that this is the port
[chrome-stay-fresh](https://github.com/ahw/chrome-stay-fresh) is listening on
to know when to reload your selected tabs in the browser.

> **.bufwritepost.vimhook** on the **remote-host** host
>
> ```sh
> #!/bin/sh
> # Note: assumes you have mac-laptop set up in your ~/.ssh/config file.
> # Obviously it helps if you have password-less access configured with SSH
> # certificates.
> ssh mac-laptop 'osascript ~/refresh_safari.applescript'
> ```
 
&nbsp;
> **refresh_safari.applescript** on the **mac-laptop** host
> ```applescript
> tell application "Safari"
>     set sameURL to URL of current tab of front window
>     set URL of current tab of front window to sameURL
> end tell
> ```
> Source: [thelowlypeon, refresh_safari.applescript](https://github.com/thelowlypeon/refresh-safari/blob/master/refresh_safari.applescript)

### Reload Chrome tabs and the active Safari tab and the active Firefox tab in Mac OSX after recompiling Sass files on remote machine
Welcome to a place that must be very close to webdev Nirvana.  It is a _little_
slow, but it's hell of a lot better than anything else I've seen.

It relies on AppleScript just like the above example. Just replace
`refresh_safari.applescript` with `refresh_all_browsers.applescript`, which
looks like the following. **Note: if you don't want to bother fiddling around
with the [chrome-stay-fresh](https://github.com/ahw/chrome-stay-fresh)
extension you can create a similar block in your AppleScript file for Chrome as
well.**

> **refresh_all_browsers.applescript**
>
> ```applescript
> tell application "Safari"
>     activate
>     tell application "System Events" to keystroke "r" using command down
> end tell
> 
> tell application "Firefox"
>     activate
>     tell application "System Events" to keystroke "r" using command down
> end tell
> ```

### Log editing events for future analytics
My only non-webdev example. I don't know, maybe you're into collecting data.
This will log out timestamps each time you enter and exit a new buffer in
Vim. Your working tree is below. Note that `.bufleave.vimhook` is sym-linked
to `.bufenter.vimhook` so the same script is used to handle two events.

```
.
├── .bufenter.vimhook
├── .bufleave.vimhook -> .bufenter.vimhook # this is a symlink
├── _colors.scss
├── src
│   ├── app.js
│   ├── models.js
│   └── views.js
├── style.css
└── style.scss
```

> **.bufenter.vimhook**
>
> ```bash
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
- Support filtering the hook scripts by filename extension or entire
  filename. Might want to modify the hook script naming scheme. For example,
  `.bufwritepost.scss.vimhook` would only be executed when `*.scss` files
  are changed. `styles.scss.bufwritepost.vimhook` or `.styles.scss.vimhook` would only be
  executed when `BufWritePost` was fired while editing `styles.scss`.
- Support wildcard event names so that we don't have to symlink the vim-hook
  scripts.
- Come up with a way to write files without triggering the vimhook scripts.
  Like sometimes you're just editing the README of your project and don't really
  want to trigger all those hooks.
- Always search a global vimhook script location in addition to the current
  working directory (e.g., `~/.vimhooks/`)
