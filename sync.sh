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
if [[ "$PWD" != "$DF_DIR" ]]; then
	cd $DF_DIR
fi

# Check for shortcut
if [[ ! -L ~/$DF_LNK ]]; then
	# Link dir to shortcut
	ln -s $DF_DIR ~/$DF_LNK
fi

# Create symlinks
for file in ${files[[@]]}; do
	# Set dotfile path
	dotfile=~/.$file
	# Check for existing dotfiles
	if [[ ! -L $dotfile ]]; then
		# Check for regular files
		if [[ -f $dotfile ]]; then
			# Make a backup
			mkdir -p $DF_BKP
			mv $dotfile $DF_BKP/.$file
		fi
		# Link dotfile
		ln -s $DF_LNK/$file $dotfile
	fi
done

# If system is macOS
if [[ $(uname -s) == 'Darwin' ]]; then

	# Check for XCode CLT and install it if not
	if [[ ! $(xcode-select -p) ]]; then
		echo "CLT missing, install them with 'xcode-select --install'. Exiting."
		exit 1
	fi

	# Check for Homebrew and install if we don't have it, else update it
	if [[ ! $(which brew)]]; then
		/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
	else
		brew update --force
		brew upgrade --cleanup
	fi
	brew bundle -v --file=./macos/Brewfile
	brew cleanup

	# Install MS Office
	#TODO call ./macos/officemac.sh

# If system is Linux
elif [[ $(uname -s) == 'Linux' ]]; then
	# Install rquired apps
	sudo apt update && sudo apt install -y \
		zsh

	# Cleanup
	sudo apt autoremove
	sudo apt autoclean
fi

# Set ZSH as login shell
ZSH_PATH=$(which zsh)
if [[ $SHELL == $ZSH_PATH ]]; then
	echo "ZSH is already the login shell."
else
	echo "Changing login shell to ZSH..."
	echo $ZSH_PATH | sudo tee -a /etc/shells
	sudo chsh -s $ZSH_PATH $USR
fi

# Install Antigen
if [[ -d ~/.antigen ]]; then
	rm -rf ~/.antigen
fi
mkdir -p ~/.antigen
curl -L git.io/antigen > ~/.antigen/antigen.zsh

# Download Docker Completion file
if [[ ! -d ~/.zsh_completion ]]; then
	mkdir -p ~/.zsh_completion
	curl -L https://raw.githubusercontent.com/docker/machine/v0.14.0/contrib/completion/zsh/_docker-machine > ~/.zsh_completion/_docker-machine
fi

# Install Vundle plugins
if [[ ! -d ~/.vim/bundle/Vundle.vim ]]; then
	git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim
fi
vim -i NONE -c VundleUpdate -c quitall

