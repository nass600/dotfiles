set nocompatible
filetype off

"vundle
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()
Plugin 'VundleVim/Vundle.vim'
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

"powerline
python from powerline.vim import setup as powerline_setup
python powerline_setup()
python del powerline_setup
set laststatus=2
set noshowmode

if ! has('gui_running')
    set ttimeoutlen=10
    augroup FastEscape
        autocmd!
        au InsertEnter * set timeoutlen=0
        au InsertLeave * set timeoutlen=1000
    augroup END
endif
