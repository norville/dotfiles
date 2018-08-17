#!/bin/bash

set -e

# Validate current user as admin
USR=$(whoami)
sudo -v

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
	brew cleanup

# If system is Linux
elif [ $(uname -s) == 'Linux' ]; then

	# Install rquired apps
	sudo apt update && sudo apt install -y \
		zsh \
		zsh-syntax-highlighting

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

# Install ZPLUG
./dotfiles_zplug.sh

# Install Vundle plugins
if [ ! -d ~/.vim/bundle/Vundle.vim ]; then
	git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim
fi
vim -i NONE -c VundleUpdate -c quitall

