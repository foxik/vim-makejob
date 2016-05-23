# Neovim MakeJob
I've used [other](/scrooloose/syntastic) [build
solutions](/neomake/neomake) to lint my files, and while they've
worked as advertized, they're not what I  would call minimal. Even Tim
Pope's venerable [dispatch.vim](/tpope/vim-dispatch) suffers from
features that I can't seem to figure out. Plus, I've moved to
[Neovim](/neovim/neovim) as my primary editor, and dispatch.vim is
designed with classic [Vim](/vim/vim) in mind. To wit, Neovim offers
asynchronous jobs out of the box, so tpope's clever dispatch methods are
no longer necessary.

With minimalism as a goal, I've done my best with _MakeJob_ to implement
asynchronous `:make` and `:lmake` for Neovim. That's all _MakeJob_ does,
and that's all I intend for it to do. It will not configure compiler
settings for you. Neovim (like Vim before it) already gives you
everything you need to do that work automatically (i.e. `autocmd`).

## Goals
1. Implement a minimal solution for asynchronous `:make` and `:lmake`.
   No unnecessary features.
2. Let Neovim be Neovim. Use compiler plugins to configure our builders.

## TODO - Installation
Pathogen
Vundle

Most other plugin managers will resemble one of these two.

## Usage
### The Short Version
Neovim has `:make` and `:lmake`. Replace those calls with `:MakeJob` and
`:LmakeJob`. Call it a day.

### The Less Short Version
With no prior configuration, `:make` will run the `make` program with no
arguments, and populate the Quickfix list with any errors the process
encounters. It's possible to change that behavior in one of two ways.
The hard way is to manually use `:set makeprg` to change the program to
something else, and _then_ use `:set errorformat` to configure the
format of the errors to look for. This gets pretty hairy, and so
everyone is better off trying to avoid this in favor of the easy way:
compiler plugins.

__TODO - Describe Compilers__

## Automatic Configuration
I alluded earlier to the possibility of using `autocmd` to set your
compiler automatically. Just for the sake of completeness, an example of
that trick would like like this:

`autocmd! FileType python compiler pylint`

Add that line to your `init.vim` and you're good to go for Python files
(assuming you have a pylint compiler which hey, if you need one I've
[got you covered](/djmoch/vim-compiler)).

## Neovim Documentation
If any of what I discuss above doesn't make sense, then take a look at
the help documentation in Neovim. Of particular interest will probably
be the following:

1. `:h make`
2. `:h makeprg`
3. `:h errorformat`
4. `:h compiler`
5. `:h quickfix`
