""" Set background, colors and theme
set background=dark
if (has("termguicolors"))
    set termguicolors
endif
let g:tokyonight_style = 'night'            " available: night, storm
let g:tokyonight_transparent_background = 1 " enable transparent background
let g:tokyonight_enable_italic = 1
silent colorscheme tokyonight

""" Configure Airline
let g:airline_theme = "tokyonight"
let g:airline_powerline_fonts = 1
let g:airline#extensions#tabline#enabled = 1
let g:airline#extensions#tabline#left_sep = ' '
let g:airline#extensions#tabline#left_alt_sep = '|'
let g:airline#extensions#tabline#formatter = 'unique_tail_improved'
