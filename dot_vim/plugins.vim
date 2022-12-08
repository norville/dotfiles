"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
""" VUNDLE
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

""" Verify Vundle
let g:vundle_plug_install = 0
if !isdirectory(expand('~/.vim/bundle/Vundle.vim'))
    let g:vundle_plug_install = 1
    silent !mkdir -p ~/.vim/bundle
    silent !git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim
endif

""" Required by Vundle
filetype off
set nocompatible
set rtp+=~/.vim/bundle/Vundle.vim
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
Plugin 'tpope/vim-sensible'
Plugin 'scrooloose/nerdtree'
Plugin 'scrooloose/syntastic'
Plugin 'vim-airline/vim-airline'
Plugin 'vim-airline/vim-airline-themes'
""" End plugin list

""" Last plugin to load
Plugin 'ryanoasis/vim-devicons'

""" Install plugins if needed
if g:vundle_plug_install == 1
    :PluginInstall
    """ TODO - hide installer
endif

""" Required by Vundle
call vundle#end()
filetype plugin indent on

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""