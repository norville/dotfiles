""" Set background, colors and theme
set background=dark
if (has("termguicolors"))
    set termguicolors
endif
silent! colorscheme gruvbox

""" Enable Indent Guides
if exists("g:loaded_indent_guides")
    let g:indent_guides_enable_on_vim_startup = 1
endif

""" Configure Airline
if exists("g:loaded_airline")
    let g:airline_powerline_fonts = 1   """TODO - requires nerdfonts!!!
    let g:airline#extensions#tabline#enabled = 1
    let g:airline#extensions#tabline#left_sep = ' '
    let g:airline#extensions#tabline#left_alt_sep = '|'
    let g:airline#extensions#tabline#formatter = 'unique_tail' "default | jsformatter | unique_tail | unique_tail_improved
    if g:colors_name == 'gruvbox'
        let g:airline_theme='gruvbox'
    endif
endif

