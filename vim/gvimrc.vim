set lines=50
set columns=100

" For powerline font in MacVim
set encoding=utf-8
set guifont=Roboto\ Mono\ for\ Powerline:h12

if has("gui_running")
	set background=dark
    if has("gui_macvim")
        set backupcopy=yes
        set guioptions-=T
        set transparency=5
    elseif has("gui_win32")
        set guifont=Consolas:h12
    elseif has("gui_gnome")
        set guifont=Bitstream_Vera_Sans_Mono:h12
    endif
endif

