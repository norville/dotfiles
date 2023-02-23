"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
""" VIM-PLUG
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

""" Install vim-plug if not found
let data_dir = has('nvim') ? stdpath('data') . '/site' : '~/.vim'
if empty(glob(data_dir . '/autoload/plug.vim'))
  silent execute '!curl -fLo '.data_dir.'/autoload/plug.vim --create-dirs  https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

""" Run PlugInstall if there are missing plugins
autocmd VimEnter * if len(filter(values(g:plugs), '!isdirectory(v:val.dir)'))
  \| PlugInstall --sync | source $MYVIMRC
\| endif

""" Init vim-plug
call plug#begin()

""" Plugins list
Plug 'altercation/vim-colors-solarized'
Plug 'nathanaelkane/vim-indent-guides'
#Plug 'morhetz/gruvbox'
Plug 'cormacrelf/vim-colors-github'
Plug 'terryma/vim-multiple-cursors'
Plug 'airblade/vim-gitgutter'
Plug 'tpope/vim-surround'
Plug 'tpope/vim-fugitive'
Plug 'tpope/vim-sensible'
Plug 'scrooloose/nerdtree'
Plug 'scrooloose/syntastic'
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'

""" Last plugin to load
Plug 'ryanoasis/vim-devicons'

call plug#end()
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
