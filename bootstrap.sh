#!/bin/bash

set -e

DF_DIR=$HOME/dev/dotfiles
DF_LNK=.dotfiles

if [ $PWD != $DF_DIR ]; then
	echo "Error: Dotfiles must be in $DF_DIR."
	exit 1
fi
if [ ! -d $HOME/$DF_LNK ]; then
	ln -sf $PWD $HOME/$DF_LNK
fi

files=(
	".gitconfig"
	".tmux.conf"
	".vim"
	".vimrc"
	".zshrc"
)

for file in ${files[@]}; do
	ln -sf $DF_LNK/$file $HOME/$file
done

./bin/dotfiles_run

