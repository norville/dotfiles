""" Configure Airline
let g:airline_powerline_fonts = 1
let g:airline#extensions#tabline#enabled = 1
let g:airline#extensions#tabline#left_sep = ' '
let g:airline#extensions#tabline#left_alt_sep = '|'
let g:airline#extensions#tabline#formatter = 'unique_tail' "default | jsformatter | unique_tail | unique_tail_improved

""" Enable Indent Guides
let g:indent_guides_enable_on_vim_startup = 1

"if has('macunix')
	let g:airline_theme='gruvbox'
"	set guifont=Sauce\ Code\ Pro\ Nerd\ Font\ Complete:h12
	if (has("termguicolors"))
		set termguicolors
	endif
	silent! colorscheme gruvbox
	
	" Enable italic support
	"set term=xterm-256color-italic
	"let g:gruvbox_italic=1
	"highlight Comment cterm=italic
"else
"	let g:airline_theme='solarized'
"	let g:airline_solarized_bg='dark'
"	silent! colorscheme solarized
"endif

