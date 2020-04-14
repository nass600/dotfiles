set nocompatible
filetype off

"vundle
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()
Plugin 'VundleVim/Vundle.vim'
Plugin 'vim-airline/vim-airline'
Plugin 'vim-airline/vim-airline-themes'
Plugin 'blueshirts/darcula'
call vundle#end()

syntax enable
set nu
syntax on
filetype on
filetype plugin indent on
set tabstop=4
set shiftwidth=4
set expandtab

try
    colorscheme darcula
catch /^Vim\%((\a\+)\)\=:E185/
    " deal with it
endtry

let g:airline_powerline_fonts = 1
let g:airline_theme = 'powerlineish'
