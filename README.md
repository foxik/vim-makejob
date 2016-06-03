# Neovim MakeJob
There are plenty of [other](/scrooloose/syntastic) [build
solutions](/neomake/neomake) for [Vim](/vim/vim) and
[Neovim](/neovim/neovim), many of them offering feature sets that
overlap with those the editor already offers. With minimalism as a goal,
_MakeJob_ implements asynchronous `:make` and `:lmake` for Neovim in
just over 100 lines of Vimscript.

## Goals
1. Implement a minimal solution for asynchronous `:make` and `:lmake`.
   No unnecessary features.
2. Let Neovim be Neovim. Use compiler plugins to configure `makeprg` and
   `errorformat`. Use the Quickfix or Location List window to view
   findings.
3. Complete feature parity with `:make` and `:lmake` per the steps
   outlined in `:help make`. Still todo are `autowrite`,
   `QuickFixCmdPre` and `QuickFixCmdPost`.

## Installation
### Pathogen
`cd ~/.config/nvim/bundle`   
`git clone https://github.com/djmoch/nvim-makejob.git`

### Plug.vim
`Plug 'djmoch/nvim-makejob'`

Most other plugin managers will resemble one of these two.

## Usage
### The Short Version
Neovim has `:make` and `:lmake`. Replace those calls with `:MakeJob` and
`:LmakeJob`. Call it a day. If `:MakeJob` reports findings, use `:copen`
to view them, and likewise `:lopen` for `:LmakeJob`.

### The Less Short Version
Users of Syntastic and Neomake may not be aware that Neovim offers many
of their features out of the box. Here's a brief rundown.

With no prior configuration, `:make` will run the `make` program with no
arguments, and populate the Quickfix list with any errors the process
encounters. It's possible to change that behavior in one of two ways.
The hard way is to manually use `:set makeprg` to change the program 
something else, and _then_ use `:set errorformat` to configure the
format of the errors to look for. This gets pretty hairy, and so
we're all better off trying to avoid this in favor of the easy way:
compiler plugins. Using a compiler plugin easy (ex: `:compiler javac`),
they abstract away the work of remembering the `errorformat`, they're
extendable, and many are already included in Neovim. _MakeJob_ uses
compilers.

Also, it's possible to use `autocmd` to set the compiler of your choice
 automatically. Just for the sake of completeness, an example of that
 trick would like like this:

`autocmd! FileType python compiler pylint`

Add that line to your `init.vim` and you're good to go for Python files
(assuming you have a pylint compiler which hey, if you need one I've
[got you covered](/djmoch/vim-compiler)).

Additionally, if you'd like _MakeJob_ to run a linter automatically when
you write a file, then something like the following will to the trick.

`autocmd BufWritePost * :LmakeJob<CR>`

For more granular control, you can set this trigger on a file-type basis
with something like the following:

`autocmd BufWritePost *.py :LmakeJob<CR>`

## Neovim Documentation
Part of the goal of _MakeJob_ is to minimize the size of the plugin by
using features Neovim already offers whenever possible. To that end, if
any of what foregoing discussion doesn't make sense, then take a look at
the help documentation in Neovim. Of particular interest will probably
be the following:

1. `:h make`
2. `:h makeprg`
3. `:h errorformat`
4. `:h compiler`
5. `:h quickfix`

## License
MIT - See the LICENSE file for more information
