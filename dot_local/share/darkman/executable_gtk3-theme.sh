#!/bin/sh

case "$1" in
dark) COLORSCHEME=prefer-dark ;;
light) COLORSCHEME=prefer-light ;;
default) exit 1 ;;
esac

gsettings set org.gnome.desktop.interface color-scheme '$COLORSCHEME'
