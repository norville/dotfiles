#!/bin/bash

set -e

# Include customised echo functions
source ./install.d/echoes.sh

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

###############################################################################
#
###############################################################################

bot "### DOTFILES INSTALLER ###"
bot "This script will install your dotfiles, necessary apps and configure your system."

# Change dir to dotfiles dir
if [[ "$PWD" != "$DF_DIR" ]]; then
	cd $DF_DIR
fi

# Check for shortcut
bot "Set dotfiles default directory ($DF_DIR => ~/$DF_LNK):"
if [[ ! -L ~/$DF_LNK ]]; then
	running "Creating shortcut to home:"
	action "ln -s $DF_DIR ~/$DF_LNK"
	ln -s $DF_DIR ~/$DF_LNK
fi
ok

# Create symlinks
bot "Link dotfiles to home directory:"
for file in ${files[@]}; do
	# Set dotfile path
	dotfile=~/.$file
	running "Linking $dotfile:"
	# Check for existing dotfiles
	if [[ ! -L $dotfile ]]; then
		# Check for regular files
		if [[ -f $dotfile ]]; then
			# Make a backup
			running "Backing up existing version of $dotfile:"
			mkdir -p $DF_BKP
			action "mv $dotfile $DF_BKP/.$file"
			mv $dotfile $DF_BKP/.$file
			ok
		fi
		# Link dotfile
		action "ln -s $DF_LNK/$file $dotfile"
		ln -s $DF_LNK/$file $dotfile
		ok
	fi
done

# Ask for the administrator password upfront
bot "Ready to setup your system, enter admin password:"
sudo -v

# /etc/hosts
bot "Configure /etc/hosts..."
read -r -p "Overwrite /etc/hosts with the ad-blocking hosts file from someonewhocares.org? [y|n] " response
if [[ $response =~ (yes|y|Y) ]]; then
	action "cp /etc/hosts /etc/hosts.bkp"
	sudo cp /etc/hosts /etc/hosts.bkp
	ok
	action "curl -sL https://someonewhocares.org/hosts/hosts > /etc/hosts"
	sudo curl -sL https://someonewhocares.org/hosts/hosts > /etc/hosts
	ok
	bot "Your /etc/hosts file has been updated. Last version is saved in /etc/hosts.backup ."
fi

bot "Detect system..."
# If system is macOS
if [[ $(uname -s) == 'Darwin' ]]; then
	bot "macOS detected!"

	BREWFILE=~/dev/dotfiles/macos/Brewfile

	# Check for Homebrew and install if we don't have it, else update it
	bot "Setup Homebrew..."
	if [[ ! $(which brew) ]]; then
		running "Homebrew is not installed, let's do it now:"
		action "/usr/bin/ruby -e \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)\""
		/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
		if [[ $? != 0 ]]; then
			error "Unable to install Homebrew. Exiting"
			exit 2
		fi
		ok
		action "brew bundle -v --file=$BREWFILE"
		brew bundle -v --file=$BREWFILE
		if [[ $? != 0 ]]; then
			error "Unable to install Homebrew formulae. Exiting"
			exit 2
		fi
		ok
	else
		running "Homebrew is already installed, let's update everything:"
		if [[ $(brew bundle cleanup --file=$BREWFILE) ]]; then
			warn "Found unused formulae!"
			read -r -p "Do you want to uninstall all unused formulae? [y|n] " response
			if [[ $response =~ (yes|y|Y) ]]; then
				action "brew bundle cleanup --file=$BREWFILE --force"
				brew bundle cleanup --file=$BREWFILE --force
				ok
			fi
		fi
		action "brew update --force"
		brew update --force
		ok
		action "brew upgrade --cleanup"
		brew upgrade --cleanup
		ok
		action "brew cask upgrade"
		brew cask upgrade #--greedy
		ok
	fi
	running "Cleaning Homebrew leftovers:"
	action "brew cleanup"
	brew cleanup
	ok
	action "brew doctor"
	brew doctor
	ok

	# Install MS Office
	bot "Setup Microsoft Office..."
	macos/officemac.sh
	ok

# If system is Linux
elif [[ $(uname -s) == 'Linux' ]]; then
	bot "Linux detected!"

	APT_FILE=~/dev/dotfiles/install.d/apt-packages

	# Install rquired apps
	running "Installing/updating required packages via APT:"
	action "sudo apt-get update"
	sudo apt-get update
	ok
	action "xargs -a $APT_FILE sudo apt-get install -y"
	xargs -a $APT_FILE sudo apt-get install -y
	if [[ $? != 0 ]]; then
		error "Unable to install APT packages. Exiting"
		exit 2
	fi
	ok

	# Cleanup
	action "sudo apt autoremove"
	sudo apt autoremove
	ok
	action "sudo apt autoclean"
	sudo apt autoclean
	ok
fi

# Set ZSH as login shell
bot "Setup ZSH as login shell..."
ZSH_PATH=$(which zsh)
if [[ $SHELL == $ZSH_PATH ]]; then
	bot "ZSH is already your login shell."
else
	running "Changing login shell to ZSH..."
	action "echo $ZSH_PATH | sudo tee -a /etc/shells"
	echo $ZSH_PATH | sudo tee -a /etc/shells
	ok
	action "sudo chsh -s $ZSH_PATH $USR"
	sudo chsh -s $ZSH_PATH $USR
	ok
fi

# Install Antigen
bot "Setup Antigen as ZSH plugin manager..."
if [[ -d ~/.antigen ]]; then
	running "Resetting Antigen plugins:"
	action "rm -rf ~/.antigen"
	rm -rf ~/.antigen
	ok
fi
mkdir -p ~/.antigen
action "curl -sL git.io/antigen > ~/.antigen/antigen.zsh"
curl -sL git.io/antigen > ~/.antigen/antigen.zsh
ok

# Download Docker Completion file
bot "Setup Docker completion:"
if [[ ! -d ~/.zsh_completion ]]; then
	running "Downloading Docker completion files:"
	mkdir -p ~/.zsh_completion
	action "curl -sL https://raw.githubusercontent.com/docker/machine/v0.14.0/contrib/completion/zsh/_docker-machine > ~/.zsh_completion/_docker-machine"
	curl -sL https://raw.githubusercontent.com/docker/machine/v0.14.0/contrib/completion/zsh/_docker-machine > ~/.zsh_completion/_docker-machine
fi
ok

# Install Vundle plugins
bot "Setup Vundle as VIM plugin manager.."
if [[ ! -d ~/.vim/bundle/Vundle.vim ]]; then
	running "Downloading Vundle:"
	action "git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim"
	git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim
	ok
fi
running "Install or update VIM plugins:"
action "vim -i NONE -c VundleUpdate -c quitall > /dev/null 2>&1"
vim -i NONE -c VundleUpdate -c quitall > /dev/null 2>&1
ok

bot "All done! Close this session and log in again."

