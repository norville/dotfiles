#!/bin/bash

set -e

DF_DIR=~/dev/dotfiles	# Full path of dotfiles dir
DF_LNK=~/.dotfiles		# Link dotfiles dir to ~/.dotfile
DF_BKP=~/.dotfiles_bkp	# Backup dir for existing dotfiles

links=(
	".gitconfig"
	".tmux.conf"
	".vim"
	".vimrc"
	".zshrc"
)

cd $DF_DIR

# Create ~/.dotfile shortcut
if [ ! -L $DF_LNK ]; then
	ln -s $DF_DIR $DF_LNK
fi

# Create symlinks
for l in ${links[@]}; do
	if [ ! -L ~/$l ]; then

		# If dotfile already exists then make a backup
		if [ -f ~/$l ]; then
			mkdir -p $DF_BKP
			mv ~/$l $DF_BKP/$l
		else
			ln -s $DF_LNK/$l ~/$l
		fi
	fi
done

#./bin/dotfiles_run

