#!/bin/bash

set -e

# Define variables
USR=$(whoami)
DF_DIR=~/dev/dotfiles	# Dotfiles dir full path
DF_BKP=~/.dotfiles_bkp	# Backup dir for existing dotfiles
DF_LNK=.dotfiles		# Dotfiles shortcut. For correct expansion DO NOT prepend '~/'

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

# Validate current user as admin
sudo -v

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

# If system is macOS
if [ $(uname -s) == 'Darwin' ]; then

	# Install dependencies (XCode, etc.)

	# Check for Homebrew and install if we don't have it, else update it
	if test ! $(which brew); then
		/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
	else
		brew update --force
		brew upgrade --cleanup
	fi

	# Install all our dependencies with bundle (See Brewfile)
	brew tap homebrew/bundle
	brew bundle -v --file=../macos/Brewfile
	brew cask outdated
	brew cask upgrade
	brew cleanup

# If system is Linux
elif [ $(uname -s) == 'Linux' ]; then
	# Install rquired apps
	sudo apt update && sudo apt install -y \
		zsh

	# Cleanup
	sudo apt autoremove
	sudo apt autoclean
fi

# Set ZSH as login shell
ZSH_PATH=$(which zsh)
if [ $SHELL == $ZSH_PATH ]; then
	echo "ZSH is already the login shell."
else
	echo "Changing login shell to ZSH..."
	echo $ZSH_PATH | sudo tee -a /etc/shells
	sudo chsh -s $ZSH_PATH $USR
fi

# Install Antigen
if [[ ! -f ~/.antigen/antigen.zsh ]]; then
	curl -L git.io/antigen > ~/.antigen/antigen.zsh
fi

# Install Vundle plugins
if [[ ! -d ~/.vim/bundle/Vundle.vim ]]; then
	git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim
fi
vim -i NONE -c VundleUpdate -c quitall

