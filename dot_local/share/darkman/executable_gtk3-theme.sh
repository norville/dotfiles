#!/bin/sh
# darkman switch script — called with "dark" or "light" on mode change.
# Sets the GNOME color-scheme preference so GTK apps follow the mode.

case "$1" in
dark) COLORSCHEME=prefer-dark ;;
light) COLORSCHEME=prefer-light ;;
*) exit 1 ;;
esac

gsettings set org.gnome.desktop.interface color-scheme "$COLORSCHEME"
