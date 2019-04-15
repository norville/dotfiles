
### Bootstrap script

# TODO install git

REPO_URL=https://github.com/norville/dotfiles.git   # URL to remote repo
BARE_DIR=.dfbare                                    # git dir for bare repo
BKP_DIR=$HOME/.dfbackup                             # backup dir for pre-existing dotfiles

# Define function to automatically run git against the bare repo in $HOME
function dfconf {
    # /usr/bin/git --git-dir=<git-bare-dir> --work-tree=<dotfiles-dir>'
    /usr/bin/git --git-dir=$BARE_DIR --work-tree=$HOME $@
}

# Clone remote repo into the bare repo inside $HOME
# git clone --bare <git-repo-url> <git-bare-dir>
cd $HOME && git clone --bare $REPO_URL $BARE_DIR

# Checkout bare repo
dfconf checkout

# If checkout fails
# TODO fix if condition
if $?; then
    # Create backup dir
    mkdir -p $BKP_DIR
    # Move pre-existing dotfiles to $BKP_DIR
    dfconf checkout 2>&1 | egrep "\s+\." | awk {'print $1'} | xargs -I{} mv {} $BKP_DIR/{}
    dfconf checkout
fi;

# Config bare repo to ignore untracked files
dfconf config status.showUntrackedFiles no

# TODO continue bootstrap

# TODO
# - install nerd font
# - set gruvbox theme for terminal (mac/linux)
#!/bin/bash

set -e

# Include customised echo functions
#source ./install.d/echoes.sh

# Define variables
USR=$(whoami)

# Ask for the administrator password upfront
sudo -v

# If system is macOS
if [[ $(uname -s) == 'Darwin' ]]; then

    BREWFILE=~/dev/dotfiles/macos/Brewfile

    # Check for Homebrew and install if we don't have it, else update it
    if [[ ! $(which brew) ]]; then
        /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
        try "Cannot install Homebrew."
        brew bundle -v --file=$BREWFILE
    else
        if [[ $(brew bundle cleanup --file=$BREWFILE) ]]; then
            read -r -p "Do you want to uninstall all extra formulae? [y|n] " response
            if [[ $response =~ (yes|y|Y) ]]; then
                brew bundle cleanup --file=$BREWFILE --force
            fi
        fi
        brew update --force
        brew upgrade
        brew cask upgrade #--greedy
    fi
    brew cleanup
    brew doctor

    # Update PIP base packages
    pip3 install -U pip setuptools wheel

    #TODO install apps via Mac App Store

# If system is Linux
elif [[ $(uname -s) == 'Linux' ]]; then

    APT_FILE=~/dev/dotfiles/install.d/apt-packages

    # Install rquired apps
    sudo apt-get update
    xargs -a $APT_FILE sudo apt-get install -y
    if [[ $? != 0 ]]; then
        exit 2
    fi

    # Cleanup
    sudo apt autoremove
    sudo apt autoclean
fi

# Set ZSH as login shell
ZSH_PATH=$(which zsh)
if [[ $SHELL != $ZSH_PATH ]]; then
    echo $ZSH_PATH | sudo tee -a /etc/shells
    sudo chsh -s $ZSH_PATH $USR
#else
    #bot "ZSH is already your login shell."
fi

# Install Antigen
if [[ -d ~/.antigen ]]; then
    rm -rf ~/.antigen
fi
mkdir -p ~/.antigen
curl -sL git.io/antigen > ~/.antigen/antigen.zsh

# Download Docker Completion file
if [[ ! -d ~/.zsh_completion ]]; then
    mkdir -p ~/.zsh_completion
    curl -sL https://raw.githubusercontent.com/docker/machine/v0.14.0/contrib/completion/zsh/_docker-machine > ~/.zsh_completion/_docker-machine
fi

# Install Vundle plugins
if [[ ! -d ~/.vim/bundle/Vundle.vim ]]; then
    git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim
fi
vim -i NONE -c VundleUpdate -c quitall > /dev/null 2>&1

# Install required Python packages
#pip3 install -r install.d/requirements.txt
