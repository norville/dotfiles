""" Set background, colors and theme
set background=dark
if (has("termguicolors"))
    set termguicolors
endif
silent! colorscheme gruvbox

""" Enable Indent Guides
let g:indent_guides_enable_on_vim_startup = 1

""" Configure Airline
let g:airline_powerline_fonts = 1
let g:airline#extensions#tabline#enabled = 1
let g:airline#extensions#tabline#left_sep = ' '
let g:airline#extensions#tabline#left_alt_sep = '|'
let g:airline#extensions#tabline#formatter = 'unique_tail' "default | jsformatter | unique_tail | unique_tail_improved
if g:colors_name == 'gruvbox'
    let g:airline_theme='gruvbox'
endif

