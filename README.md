# Vim MakeJob

There are plenty of [other build
solutions](http://github.com/scrooloose/syntastic) for
[Vim](http://github.com/vim/vim), many of them offering feature sets
that overlap with those the editor already offers. With minimalism as a
goal, _MakeJob_ implements asynchronous `:make` and `:lmake` for Vim in
just over 100 lines of Vimscript.

## Goals
1. Implement a minimal solution for asynchronous `:make` and `:lmake`.
   No unnecessary features.
2. Let Vim be Vim. Use compiler plugins to configure `makeprg` and
   `errorformat`. Use the Quickfix or Location List window to view
   findings.
3. Complete feature parity with `:make` and `:lmake` per the steps
   outlined in `:help make`. `autowrite`, `QuickFixCmdPre` and
   `QuickFixCmdPost`, and `!` work as expected.

## Requirements
Vim 8 minimum compiled with `+job` and `+channel`.

## Installation
### Pathogen
`cd ~/.vim/bundle`   
`git clone https://github.com/djmoch/vim-makejob.git`

### Plug.vim
`Plug 'djmoch/vim-makejob'`

Most other plugin managers will resemble one of these two.

## Usage
### The Short Version
Vim has `:make` and `:lmake`. Replace those calls with `:MakeJob` and
`:LmakeJob`. A buffer will open showing the command output, which will
be parsed into the Quickfix or LocationList window when the job
completes. Bask in your newfound freedom to do as you please in Vim
while MakeJob runs.

If `:MakeJob` reports findings, use `:copen` to view the QuickFix window
(in the case of MakeJob), and likewise `:lopen` to open the LocationList
for `:LmakeJob`.

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
extendable, and many are already included in Vim. _MakeJob_ uses
compilers.

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
