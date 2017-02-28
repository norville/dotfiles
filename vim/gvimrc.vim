set lines=50
set columns=100
set encoding=utf-8
if has("gui_running")
    set background=dark
    if has("gui_macvim")
        set backupcopy=yes
        set guioptions-=T
"        set transparency=5
        set guifont=Roboto\ Mono\ for\ Powerline:h12
    elseif has("gui_win32")
        set guifont=Consolas:h12
    elseif has("gui_gnome")
        set guifont=Bitstream_Vera_Sans_Mono:h12
    endif
endif

