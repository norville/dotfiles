"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
""" VUNDLE
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

let vundle_plug_install = 0
let vundle_dir = expand('~/.vim/bundle/Vundle.vim')

""" Verify Vundle
if !isdirectory(vundle_dir)
    echo "Installing Vundle..."
    echo ""
    silent !mkdir -p ~/.vim/bundle
    silent !git clone https://github.com/VundleVim/Vundle.vim.git vundle_dir
    let vundle_plug_install = 1
endif

""" Required by Vundle
filetype off
set nocompatible
set rtp+=vundle_dir
call vundle#begin()
Plugin 'VundleVim/Vundle.vim'

""" Begin plugin list
Plugin 'morhetz/gruvbox'
Plugin 'altercation/vim-colors-solarized'
Plugin 'nathanaelkane/vim-indent-guides'
Plugin 'terryma/vim-multiple-cursors'
Plugin 'airblade/vim-gitgutter'
Plugin 'tpope/vim-surround'
Plugin 'tpope/vim-fugitive'
Plugin 'scrooloose/nerdtree'
Plugin 'scrooloose/syntastic'
Plugin 'vim-airline/vim-airline'
Plugin 'vim-airline/vim-airline-themes'
""" End plugin list

""" Install plugins if needed
if vundle_plug_install = 1
    :PluginInstall
endif

""" Required by Vundle
call vundle#end()
filetype plugin indent on

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
