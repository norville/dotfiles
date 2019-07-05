""" Set background, colors and theme
set background=dark
if (has("termguicolors"))
    set termguicolors
endif
silent! colorscheme gruvbox

""" Configure Airline
let g:airline_powerline_fonts = 1
let g:airline#extensions#tabline#enabled = 1
let g:airline#extensions#tabline#left_sep = ' '
let g:airline#extensions#tabline#left_alt_sep = '|'
let g:airline#extensions#tabline#formatter = 'unique_tail' "default | jsformatter | unique_tail | unique_tail_improved
" Enable Indent Guides
let g:indent_guides_enable_on_vim_startup = 1
" Theme settings
if g:colors_name == 'gruvbox'
    let g:airline_theme='gruvbox'
endif

""" If system is macOS
"if has('macunix')
    """
"else
    """ If OS is Linux
    "let g:airline_theme='solarized'
    "let g:airline_solarized_bg='dark'
    "silent! colorscheme solarized
"endif

