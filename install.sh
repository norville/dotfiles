#!/bin/bash

set -e

# Include customised echo functions
#source ./install.d/echoes.sh

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

#bot "### DOTFILES INSTALLER ###"
#bot "This script will install your dotfiles, necessary apps and configure your system."

# Change dir to dotfiles dir
if [[ "$PWD" != "$DF_DIR" ]]; then
	cd $DF_DIR
fi

# Check for shortcut
#bot "Check dotfiles default directory..."
if [[ ! -L ~/$DF_LNK ]]; then
#	running "Creating shortcut to home"
#	action "ln -s $DF_DIR ~/$DF_LNK"
	ln -s $DF_DIR ~/$DF_LNK
#	try "Cannot create shortcut to home."
#else
#	finish
fi

# Create symlinks
#bot "Link dotfiles to home directory..."
for file in ${files[@]}; do
	# Set dotfile path
	dotfile=~/.$file
	# Check for existing dotfiles
	if [[ ! -L $dotfile ]]; then
		# Check for regular files
		if [[ -f $dotfile ]]; then
			# Make a backup
#			warn "'$dotfile' already exixts."
			read -r -p "Make a backup of '$dotfile'? [y|n]" response
			if [[ $response =~ (yes|y|Y) ]]; then
#				running "Backing up $dotfile"
				mkdir -p $DF_BKP
#				action "mv $dotfile $DF_BKP/.$file"
				mv $dotfile $DF_BKP/.$file
#				try "Cannot backup '$dotfile'."
			fi
		fi
		# Link dotfile
#		running "Linking '$file'"
#		action "ln -s $DF_LNK/$file $dotfile"
		ln -s $DF_LNK/$file $dotfile
#		try "Cannot link '$file'."
	fi
done
#finish

# Ask for the administrator password upfront
#bot "Ready to setup your system, enter admin password:"
sudo -v

# /etc/hosts
hostfile=/etc/hosts
#bot "Configure '$hostfile'..."
read -r -p "Overwrite $hostfile with someonewhocares.org's hosts file? [y|n] " response
if [[ $response =~ (yes|y|Y) ]]; then
#	running "Backing up $hostfile"
#	action "cp $hostfile $hostfile.bkp"
	sudo cp $hostfile $hostfile.bkp
#	try "Cannot backup '$hostfile'."
#	running "Overwriting $hostfile"
#	action "curl -sL https://someonewhocares.org/hosts/hosts > $hostfile"
	sudo curl -sL https://someonewhocares.org/hosts/hosts > $hostfile
#	try "Cannot overwrite '$hostfile'."
fi
#finish

#bot "Detect system..."
# If system is macOS
if [[ $(uname -s) == 'Darwin' ]]; then
#	bot "macOS detected!"

	BREWFILE=~/dev/dotfiles/macos/Brewfile

	# Check for Homebrew and install if we don't have it, else update it
#	bot "Setup Homebrew..."
	if [[ ! $(which brew) ]]; then
#		running "Installing Homebrew"
#		action "/usr/bin/ruby -e \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)\""
		/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
#		try "Cannot install Homebrew."
#		running "Installing required formulae"
#		action "brew bundle -v --file=$BREWFILE"
		brew bundle -v --file=$BREWFILE
#		try "Cannot install Homebrew formulae."
	else
#		running "Updating Homebrew"
		if [[ $(brew bundle cleanup --file=$BREWFILE) ]]; then
#			warn "Extra formulae already installed."
			read -r -p "Do you want to uninstall all extra formulae? [y|n] " response
			if [[ $response =~ (yes|y|Y) ]]; then
#				running "Uninstalling extra formulae"
#				action "brew bundle cleanup --file=$BREWFILE --force"
				brew bundle cleanup --file=$BREWFILE --force
#				try "Cannot uninstall extra formulae."
			fi
		fi
#		action "brew update --force"
		brew update --force
#		ok
#		action "brew upgrade"
		brew upgrade
#		ok
#		action "brew cask upgrade"
		brew cask upgrade #--greedy
#		ok
	fi
#	running "Cleaning Homebrew leftovers:"
#	action "brew cleanup"
	brew cleanup
#	ok
#	action "brew doctor"
	brew doctor
#	ok

	# Install MS Office
#	bot "Setup Microsoft Office..."
	#TODO install via Mac App Store
	#macos/officemac.sh
#	ok

# If system is Linux
elif [[ $(uname -s) == 'Linux' ]]; then
#	bot "Linux detected!"

	APT_FILE=~/dev/dotfiles/install.d/apt-packages

	# Install rquired apps
#	running "Installing/updating required packages via APT:"
#	action "sudo apt-get update"
	sudo apt-get update
#	ok
#	action "xargs -a $APT_FILE sudo apt-get install -y"
	xargs -a $APT_FILE sudo apt-get install -y
	if [[ $? != 0 ]]; then
#		error "Unable to install APT packages. Exiting"
		exit 2
	fi
#	ok

	# Cleanup
#	action "sudo apt autoremove"
	sudo apt autoremove
#	ok
#	action "sudo apt autoclean"
	sudo apt autoclean
#	ok
fi

# Set ZSH as login shell
#bot "Setup ZSH as login shell..."
ZSH_PATH=$(which zsh)
if [[ $SHELL != $ZSH_PATH ]]; then
#	running "Changing login shell to ZSH..."
#	action "echo $ZSH_PATH | sudo tee -a /etc/shells"
	echo $ZSH_PATH | sudo tee -a /etc/shells
#	ok
#	action "sudo chsh -s $ZSH_PATH $USR"
	sudo chsh -s $ZSH_PATH $USR
#	ok
#else
#	bot "ZSH is already your login shell."
fi

# Install Antigen
#bot "Setup Antigen as ZSH plugin manager..."
if [[ -d ~/.antigen ]]; then
#	running "Resetting Antigen plugins:"
#	action "rm -rf ~/.antigen"
	rm -rf ~/.antigen
#	ok
fi
mkdir -p ~/.antigen
#action "curl -sL git.io/antigen > ~/.antigen/antigen.zsh"
curl -sL git.io/antigen > ~/.antigen/antigen.zsh
#ok

# Download Docker Completion file
#bot "Setup Docker completion:"
if [[ ! -d ~/.zsh_completion ]]; then
#	running "Downloading Docker completion files:"
	mkdir -p ~/.zsh_completion
#	action "curl -sL https://raw.githubusercontent.com/docker/machine/v0.14.0/contrib/completion/zsh/_docker-machine > ~/.zsh_completion/_docker-machine"
	curl -sL https://raw.githubusercontent.com/docker/machine/v0.14.0/contrib/completion/zsh/_docker-machine > ~/.zsh_completion/_docker-machine
fi
#ok

# Install Vundle plugins
#bot "Setup Vundle as VIM plugin manager.."
if [[ ! -d ~/.vim/bundle/Vundle.vim ]]; then
#	running "Downloading Vundle:"
#	action "git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim"
	git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim
#	ok
fi
#running "Install or update VIM plugins:"
#action "vim -i NONE -c VundleUpdate -c quitall > /dev/null 2>&1"
vim -i NONE -c VundleUpdate -c quitall > /dev/null 2>&1
#ok

#bot "All done! Close this session and log in again."

