vimdir.vim
==========

Manage files and directories in vim

Inspired by vidir by Joey Hess (https://joeyh.name/code/moreutils/)

## Installation

### Vundle

    Bundle 'c0r73x/vimdir.vim'

### NeoBundle

    NeoBundle 'c0r73x/vimdir.vim'

### Manual

    Download the plugin and paste it into your plugin directory.

## Usage

To list files and folders
```
:Vimdir [directory]
```

To list files and folders recursive
```
:VimdirR [directory]
```

If no directory is specified Vimdir will use the current path

Changes will be applyed when you save the vimdir buffer. If you want to cancel
just close the buffer without saving.

## Colors

vimdir.vim doesn't come with highlighting support but using the [vidir-ls.vim](https://github.com/trapd00r/vim-syntax-vidir-ls) plugin works perfectly.

## Configuration

To show hidden files and folders set this in your vimrc

```
let g:vimdir_show_hidden = 1
```

## bin/vimdir

You can use the bin/vimdir script to execute vimdir directly from the terminal.
Just place it in your path and run vimdir.

## Todo

- Fix file swapping (a => b, b => a)
- Add support to expand folders
