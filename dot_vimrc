
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" PLUGINS
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
source ~/.vim/plugins.vim

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" GUI
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" Line numbers relative to cursorline
set number relativenumber
" Toggle relative line numbers in insert mode
augroup numbertoggle
    autocmd!
    autocmd BufEnter,FocusGained,InsertLeave * set relativenumber
    autocmd BufLeave,FocusLost,InsertEnter   * set norelativenumber
augroup END

set encoding=utf-8
set termencoding=utf-8
set ruler
set showcmd
set list
set listchars=tab:▸\ ,eol:¬,trail:•,extends:…,precedes:…,nbsp: 
set fillchars+=stl:\ ,stlnc:\
set scrolloff=3
set cursorline
set laststatus=2
set showtabline=2
set noshowmode
set t_Co=256
set term=xterm-256color

source ~/.vim/gui.vim

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" HIGHLIGHT AND SEARCH
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
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

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" BUFFERS
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
set hidden

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" INDENT
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
set tabstop=4
set softtabstop=4
set shiftwidth=4
set expandtab
set smarttab
set backspace=indent,eol,start
if has("autocmd")
    autocmd FileType text setlocal textwidth=80
    autocmd FileType html setlocal ts=2 sts=2 sw=2 expandtab
    autocmd FileType css setlocal ts=2 sts=2 sw=2 expandtab
    autocmd FileType cfg setlocal ts=2 sts=2 sw=2 expandtab
    autocmd FileType yaml setlocal ts=2 sts=2 sw=2 expandtab
    autocmd FileType javascript setlocal ts=4 sts=4 sw=4 expandtab
    autocmd BufNewFile,BufRead *.rss,*.atom setfiletype xml
else
    set autoindent
    set smartindent
endif

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" FUNCTIONS
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
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

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" MAPPINGS
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
nnoremap <silent> <F5> :call <SID>StripTrailingWhitespaces()<CR>
nnoremap <silent> <F6> g/^$/d<CR> "delete empty lines
nmap <D-[> <<
nmap <D-]> >>
vmap <D-[> <gv
vmap <D-]> >gv
map <C-e> :NERDTreeToggle<CR>" POWERLINE