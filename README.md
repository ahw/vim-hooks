Vim Hooks
=========

Looks for specially-named scripts like `.bufwritepost.vimhook` or
`.000.bufwritepost.vimhook` and executes those scripts whenever &ndash; in
this example &ndash; Vim fires the `BufWritePost` event. The general format
of these filenames is `[.sortkey].eventname.vimhook`, where `sortkey` is
optional and can be whatever you want and `eventname` is any valid Vim
`autocmd` event (case-insensitive). The filename must end in `.vimhook`. If
you would like to have multiple scripts reacting to the same `eventname`
simply name the files using a different `sortkey` for each. When there are
multiple scripts with the same `eventname` they will be executed serially
according to the lexographic ordering of their filenames. Thus, you can
choose your `sortkey`s strategically if you have several scripts which need
to run in a specific order (for example, `000.bufwritepost.vimhook`,
`100.bufwritepost.vimhook`). Currently this plugin only supports synchronous
execution of the `*.vimhook` scripts.


What is an autocommand?
-----------------------
> You can specify commands to be executed automatically when reading or
> writing a file, when entering or leaving a buffer or window, and when
> exiting Vim.  For example, you can create an autocommand to set the
> 'cindent' option for files matching \*.c.  You can also use autocommands
> to implement advanced features, such as editing compressed files (see
> |gzip-example|).  The usual place to put autocommands is in your .vimrc or
> .exrc file.
>
> *Source:* `:help autocommands`

What autocmd events are available to hook into?
-----------------------------------------------
**BufWritePost** and **CursorHold** are the only events **vim-hooks**
responds to. Adding others is not difficult, but I figured there would be a
negative performance impact if **vim-hooks** was setting up listeners for
_every_ Vim `autocmd` event, though I haven't actually tested whether or not
this is true.

For reference, the full list of all available `autocmd` events and a
description of what triggers each event is available [in the Vim
documentation](http://vimdoc.sourceforge.net/htmldoc/autocmd.html#autocmd-events)
or by running `:help autocmd-events`. If you want to include other events
manually you can tweak the plugin by just following the example of what is
already in place for `BufWritePost` and `CursorHold` (you'll find it easily
by grepping the code).

A few examples
--------------

## Recompile Sass files on save
Your working tree:
```
.
├── style.scss
├── style.css
├── _colors.scss
└── .recompile-styles.bufwritepost.vimhook
```

Contents of `.recompile-styles.bufwritepost.vimhook`
```sh
#!/bin/sh
sass style.scss style.css
```

## Log editing analytics
> TODO

Your working tree:
```
.
├── .vimenter.vimhook
├── _colors.scss
├── src
│   ├── app.js
│   ├── models.js
│   └── views.js
├── style.css
└── style.scss
```
