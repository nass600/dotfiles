set nocompatible
filetype off

"vundle
set rtp+=/Users/nass600/.vim/bundle/Vundle.vim
call vundle#begin()
Plugin 'git@github.com:gmarik/vundle'
Plugin 'git@github.com:blueshirts/darcula'
call vundle#end()

syntax enable
colorscheme darcula
set nu
syntax on
filetype on
filetype plugin indent on
set tabstop=4
set shiftwidth=4
set expandtab

" powerline
set rtp+=/usr/local/lib/python2.7/site-packages/powerline/bindings/vim
python from powerline.vim import setup as powerline_setup
python powerline_setup()
python del powerline_setup
set laststatus=2
set noshowmode
"update powerline quicker when leaving insert mode
if ! has('gui_running')
    set ttimeoutlen=10
    augroup FastEscape
        autocmd!
        au InsertEnter * set timeoutlen=0
        au InsertLeave * set timeoutlen=1000
    augroup END
endif
