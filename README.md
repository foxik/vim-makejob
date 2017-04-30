# Vim MakeJob

This is a plugin for folks who think that Vim's quickfix feature is
great, but who don't like how calls to `:make` and `:grep` freeze the
editor. _MakeJob_ implements asynchronous versions of the builtin
commands in just over 150 lines of Vimscript.

## Goals
1. Implement a minimal solution for asynchronous `:make` and `:grep`.
   No unnecessary features.
2. Let Vim be Vim. Use `makeprg` and `errorformat` to configure
   `:MakeJob` and the analogous grep options for `:GrepJob`. Use the
   Quickfix or Location List window to view findings.
3. Complete feature parity with `:make` and `:grep` per the steps
   outlined in `:help quickfix`. `autowrite`, `QuickFixCmdPre` and
   `QuickFixCmdPost`, and the bang operator work as expected.

## Requirements
Vim compiled with `+job`, `+channel`, and of course `+quickfix`.

## Installation
### Pathogen
`cd ~/.vim/bundle`   
`git clone https://github.com/djmoch/vim-makejob.git`

### Plug.vim
`Plug 'djmoch/vim-makejob'`

Most other plugin managers will resemble one of these two.

## Usage
### The Short Version
Vim has `:make` and `:grep`. Replace those calls with `:MakeJob` and
`:GrepJob`. A buffer will open showing the command output, which will
be parsed into the Quickfix or LocationList window when the job
completes. Bask in your newfound freedom to do as you please in Vim
while _MakeJob_ runs.

If _MakeJob_ reports findings, use `:copen` to view the Quickfix window
(in the case of `:MakeJob`), and likewise `:lopen` to open the LocationList
for `:LmakeJob`. There's also `:MakeJobStop` to stop a running MakeJob.

Speaking of `:LmakeJob`, all of the LocationList complements to the
Quickfix commands are there with _MakeJob_, bringing the full list of
commands to:

- `:MakeJob`
- `:MakeJobStop`
- `:LmakeJob`
- `:GrepJob`
- `:LgrepJob`
- `:GrepaddJob`
- `:LgrepaddJob`

All of which work like their builtin counterparts. Those last two are
admittedly a bit longer than we would probably like, but if you grep a
lot you'll probably want to set a mapping for it anyway (see below).

### The Less Short Version
Users of Syntastic may not be aware that Vim offers many of the same
features out of the box. Here's a brief rundown.

With no prior configuration, `:make` will run the `make` program with no
arguments, and populate the Quickfix list with any errors the process
encounters. It's possible to change that behavior in one of two ways.
The hard way is to manually use `:set makeprg` to change the program 
something else, and _then_ use `:set errorformat` to configure the
format of the errors to look for. This gets pretty hairy, and so
we're all better off trying to avoid this in favor of the easy way:
compiler plugins. Using a compiler plugin easy (ex: `:compiler javac`),
they abstract away the work of remembering the `errorformat`, they're
extendable, and many are already included in Vim. _MakeJob_ uses the
same compiler plugins users of Vim will be familiar with.

It's also possible to use the`after/ftplugin` folder to automatically
configure compilers on a per-file-type basis. An example of that trick
would be to add the following to `~/.vim/after/ftplugin/python.vim`:

`compiler pylint`

Add that and you're good to go for Python files (assuming you have a
pylint compiler which hey, if you need one I've [got you
covered](http://github.com/djmoch/vim-compiler)).

Additionally, if you'd like _MakeJob_ to run a linter automatically when
you write a file, then something like the following in your `.vimrc`
will to the trick.

`autocmd! BufWritePost * :LmakeJob! %<CR>`

For more granular control, you can set this trigger on a per-file-type
basis with something like the following:

`autocmd! BufWritePost *.py :LmakeJob! %<CR>`

Grep is a powerful way to search through a directory structure for a
keyword. I use it all the time, which is why I've added the following
mapping to my `.vimrc`:

`nnoremap <Leader>g :GrepJob!<Space>`

Finally, if you find the preview windows distracting or otherwise
disruptive to your workflow, you can hide it with the following, global
setting:

`let g:makejob_hide_preview_window = 1`

## Gotchas
1. If `grepprg` is set to `'internal'`, then Vim uses its own builtin grep
   command. This still works when you call `:GrepJob`, but not
   asynchronously.
2. For simplicity, only one instance of a given executable can run at
   once. You can run `make` and `pylint`, but you can't run two
   instances of `make` simultaneously.

## Vim Documentation
Part of the goal of _MakeJob_ is to minimize the size of the plugin by
using features Vim already offers whenever possible. To that end, if
any of what foregoing discussion doesn't make sense, then take a look at
the help documentation in Vim. Of particular interest will probably
be the following:

1. `:h make`
2. `:h makeprg`
3. `:h errorformat`
4. `:h compiler`
5. `:h quickfix`

## License
MIT - See the [LICENSE](/LICENSE) file for more information
