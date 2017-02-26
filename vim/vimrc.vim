""" ENABLE PATHOGEN
set nocompatible              " be iMproved, required
filetype off                  " required

" set the runtime path to include Vundle and initialize
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()
" alternatively, pass a path where Vundle should install plugins
"call vundle#begin('~/some/path/here')

" let Vundle manage Vundle, required
Plugin 'VundleVim/Vundle.vim'
Plugin 'altercation/vim-colors-solarized'
Plugin 'tpope/vim-fugitive'
Plugin 'scrooloose/nerdtree'
Plugin 'scrooloose/syntastic'

" All of your Plugins must be added before the following line
call vundle#end()            " required
filetype plugin indent on    " required
" To ignore plugin indent changes, instead use:
"filetype plugin on
"
" Brief help
" :PluginList       - lists configured plugins
" :PluginInstall    - installs plugins; append `!` to update or just :PluginUpdate
" :PluginSearch foo - searches for foo; append `!` to refresh local cache
" :PluginClean      - confirms removal of unused plugins; append `!` to auto-approve removal
" %vim +PluginInstall +qall    - to install from command line
"
" see :h vundle for more details or wiki for FAQ
" Put your non-Plugin stuff after this line
" 
""" INDENT
set tabstop=4
set softtabstop=4
set shiftwidth=4
set noexpandtab
set smarttab
set backspace=indent,eol,start
if has("autocmd")
    autocmd FileType text setlocal textwidth=80
    autocmd FileType html setlocal ts=2 sts=2 sw=2 expandtab
    autocmd FileType css setlocal ts=2 sts=2 sw=2 expandtab
	autocmd FileType javascript setlocal ts=4 sts=4 sw=4 noexpandtab
	autocmd BufNewFile,BufRead *.rss,*.atom setfiletype xml
else
    set autoindent
    set smartindent
endif

""" WINDOW
set encoding=utf-8
set number
set ruler
set showcmd
set list
set listchars=tab:▸\ ,eol:¬,trail:•,extends:…,precedes:…,nbsp: 
set scrolloff=3
set cursorline
set laststatus=2
set showtabline=2
set noshowmode
set background=dark
colorscheme solarized

""" POWERLINE
python3 from powerline.vim import setup as powerline_setup
python3 powerline_setup()
python3 del powerline_setup

""" STATUSLINE
"if has('statusline')
"    set statusline=%#Question#                                              " set highlighting
"    set statusline=%02.02n\.                                                " buffer number
"    set statusline+=%Y%H%M%R%W\ %t\                                         " file name and flags
"    set statusline+=[%{strlen(&ft)?&ft:'none'}\,                            " file type
"    set statusline+=%{(&fenc==\"\"?&enc:&fenc)}\,                           " encoding
"    set statusline+=%{&fileformat}\,                                        " file format
"    set statusline+=%{&spelllang}                                           " language of spelling checker
"    set statusline+=%{((exists(\"+bomb\")\ &&\ &bomb)?\",BOM\":\"\")}]\     " BOM
"    set statusline+=[%{strftime(\"%F,%a,%T\",getftime(expand(\"%:p\")))}]   " time of last modification
"    set statusline+=%=                                                      " ident to the right
""    set statusline+=[%{SyntaxItem()}]\                                      " syntax highlight group under cursor
"    set statusline+=[0x%03.B\ @\ 0x%03.O]\                                  " byte value @ byte position (hex)
"    set statusline+=[%03.v\,%03.l\ %03.p%%]                                 " cursor position
"endif

""" BUFFERS
set hidden

""" HIGHLIGHT AND SEARCH
syntax enable
set incsearch
set showmatch
if has("mouse")
    set mouse=a
endif
if &t_Co > 2 || has("gui_running")
    syntax on
    set hlsearch
endif

""" FUNCTIONS
function! <SID>StripTrailingWhitespaces()
    let _s=@/
    let l=line(".")
    let c=col(".")
    %s/\s\+$//e
    let @/=_s
    call cursor(l,c)
endfunction

"function! SyntaxItem()
"   return synIDattr(synID(line("."),col("."),1),"name")
"endfunction

function! TabsToWhites()
	set noexpandtab
	retab!
	set expandtab
	retab!
endfunction

function! WhitesToTabs()
	set expandtab
	retab!
	set noexpandtab
	retab!
endfunction

""" MAPPINGS
nnoremap <silent> <F5> :call <SID>StripTrailingWhitespaces()<CR>
nnoremap <silent> <F6> g/^$/d<CR> "delete empty lines
nmap <D-[> <<
nmap <D-]> >>
vmap <D-[> <gv
vmap <D-]> >gv
