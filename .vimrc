set nocompatible
filetype off

"vundle
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()
Plugin 'git@github.com:VundleVim/Vundle.vim'
Plugin 'git@github.com:blueshirts/darcula'
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

" powerline
let powerline_dir = "0"
if isdirectory("/usr/local/lib/python2.7/site-packages/powerline/bindings/vim")
    let powerline_dir = "/usr/local/lib/python2.7/site-packages/powerline/bindings/vim"
elseif isdirectory("/usr/local/lib/python2.7/dist-packages/powerline/bindings/vim")
    let powerline_dir = "/usr/local/lib/python2.7/dist-packages/powerline/bindings/vim"
endif
 
if powerline_dir != "0"
    set rtp+=powerline_dir
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
endif
