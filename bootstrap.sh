#!/bin/bash

set -e

DF_DIR=~/dev/dotfiles	# Dotfiles dir full path
DF_BKP=~/.dotfiles_bkp	# Backup dir for existing dotfiles
DF_LNK=.dotfiles	# Dotfiles shortcut. For correct expansion DO NOT prepend '~/'

# List of dotfiles to be symlinked
files=(
	"gitcfg"
	"gitconfig"
	"tmux"
	"tmux.conf"
	"vim"
	"vimrc"
	"zsh"
	"zshrc"
)

# Change dir to dotfiles dir
if [ "$PWD" != "$DF_DIR" ]; then
	cd $DF_DIR
fi

# Check for shortcut
if [ ! -L ~/$DF_LNK ]; then

	# Link dir to shortcut
	ln -s $DF_DIR ~/$DF_LNK
fi

# Create symlinks
for file in ${files[@]}; do

	# Set dotfile path
	dotfile=~/.$file

	# Check for existing dotfiles
	if [ ! -L $dotfile ]; then

		# Check for regular files
		if [ -f $dotfile ]; then

			# Make a backup
			mkdir -p $DF_BKP
			mv $dotfile $DF_BKP/.$file
		fi

		# Link dotfile
		ln -s $DF_LNK/$file $dotfile
	fi
done

# Install software and config system
./bin/dotfiles_run.sh

