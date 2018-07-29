#!/bin/bash

set -e

DF_DIR=~/dev/dotfiles	# Full path of dotfiles dir
DF_BKP=~/.dotfiles_bkp	# Backup dir for existing dotfiles
DF_LNK=.dotfiles		# Shortcut to dotfiles

links=(
	".gitconfig"
	".tmux.conf"
	".vim"
	".vimrc"
	".zshrc"
)

# Create ~/.dotfile shortcut
cd $DF_DIR
if [ ! -L ~/$DF_LNK ]; then
	ln -s $DF_DIR ~/$DF_LNK
fi

# Create symlinks
cd ~/$DF_LNK
for l in ${links[@]}; do
	if [ ! -L ~/$l ]; then

		# If dotfile already exists then make a backup
		if [ -f ~/$l ]; then
			mkdir -p $DF_BKP
			mv ~/$l $DF_BKP/$l
		else
			# Source must be the shortcut without '~', or it will expand to full path
			ln -s $DF_LNK/$l ~/$l
		fi
	fi
done

# Install software and config system
./bin/dotfiles_run.sh
