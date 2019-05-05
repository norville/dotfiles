#!/bin/bash

### Define variables and functions

REPO_URL=https://github.com/norville/dotfiles.git   # URL to remote repo
BARE_DIR=.dfbare                                    # git dir for bare repo
BKP_DIR=$HOME/.dfbackup                             # backup dir for pre-existing dotfiles

# Check last exit status and print message
function exit_status() {

    if [[ $? != 0 ]]; then
        # Print error message and exit
        echo "Error $1"
        exit 2
    else
        # Print success message
        echo "Done $1"
    fi

}

# Automatically run git against the bare repo in $HOME
function dfconf {

    # /usr/bin/git --git-dir=<git-bare-dir> --work-tree=<dotfiles-dir>
    /usr/bin/git --git-dir=$BARE_DIR --work-tree=$HOME $@

}

# Ensure bare repo is configured
function prep_repo {

    # Check bare repo dir
    cd $HOME
    if [[ ! -d $BARE_DIR ]]; then
        # Create directory for bare repository
        mkdir -p $BARE_DIR
    fi

    # Check bare repo status
    cd $BARE_DIR
    if [[ ! $(git rev-parse --is-bare-repository) ]]; then

        # Clone remote repo into the bare repo inside $HOME
        # git clone --bare <git-repo-url> <git-bare-dir>
        cd $HOME
        git clone --bare $REPO_URL $BARE_DIR
        exit_status "cloning bare repo into $BARE_DIR"

        # Checkout bare repo
        dfconf checkout
        # If checkout fails
        if [[ $? != 0 ]]; then
            # Create backup dir
            mkdir -p $BKP_DIR
            # Move pre-existing dotfiles to $BKP_DIR
            dfconf checkout 2>&1 | egrep "\s+\." | awk {'print $1'} | xargs -I{} mv {} $BKP_DIR/{}
            dfconf checkout
        fi

        # Config bare repo to ignore untracked files
        dfconf config status.showUntrackedFiles no

    fi

    # Ensure current dir is $HOME
    cd $HOME

}

### Bootstrap begin

#set -e

# Get admin privileges
sudo -v

### Prepare bare repo and install/update required software

### Detect system
if [[ $(uname -s) == 'Linux' ]]; then

    ### If system is Linux

    # Update APT repos
    sudo apt-get update
    exit_status "updating APT repos"

    # Ensure git is installed
    sudo apt-get install git -y
    exit_status "installing git"

    # Prepare bare repo before continuing
    prep_repo

    # Install required packages
    APT_PKGS=~/.dfconf/apt-packages
    xargs -a $APT_PKGS sudo apt-get install -y
    exit_status "installing required packages in $APT_PKGS"

    # Cleanup
    sudo apt autoremove
    sudo apt autoclean

elif [[ $(uname -s) == 'Darwin' ]]; then

    ### If system is macOS

    # Prepare bare repo before continuing
    prep_repo

    # Load required packages
    BREW_PKGS=~/.dfconf/Brewfile

    # Check for Homebrew
    if [[ ! $(which brew) ]]; then

        # Install Homebrew and all required packages

        BREW_URL='https://raw.githubusercontent.com/Homebrew/install/master/install'
        /usr/bin/ruby -e "$(curl -fsSL $BREW_URL)"
        exit_status "installing Homebrew"

        brew bundle -v --file=$BREW_PKGS
        exit_status "installing required packages"

    else

        # Update Homebrew and all required packages

        # Check for extra packages
        if [[ $(brew bundle cleanup --file=$BREW_PKGS) ]]; then
            read -r -p "Do you want to uninstall all extra formulae? [y|n] " response
            if [[ $response =~ (yes|y|Y) ]]; then
                # Remove extra packages
                brew bundle cleanup --file=$BREW_PKGS --force
                exit_status "removing extra packages"
            fi
        fi

        brew update --force
        exit_status "updating Homebrew"

        brew upgrade
        exit_status "upgrading Homebrew formulae"

        brew cask upgrade #--greedy
        exit_status "upgrading Homebrew caks"

    fi

    # Cleanup
    brew cleanup
    brew doctor

    # Update PIP base packages
    pip3 install -U pip setuptools wheel
    exit_status "updating PIP packages"

    # TODO
    # - install apps via Mac App Store
    # - restore preferences (Mackup / Mathias)

fi

### Configure environment

### Shell and plugins

# Ensure ZSH is the login shell
ZSH_PATH=$(which zsh)
if [[ $SHELL != $ZSH_PATH ]]; then

    # Set ZSH as login shell
    echo $ZSH_PATH | sudo tee -a /etc/shells
    sudo chsh -s $ZSH_PATH $(whoami)
    exit_status "setting ZSH as login shell"

else

    # Already set!
    exit_status "checking login shell (ZSH)"

fi

# Antigen
# TODO mv antigen dir inside ~/.zsh

# ZSH Completions

### Editor and plugins

# Vundle

# TODO
# - mv bin/bootstrap.sh bin/dfbstrap.sh
# - .basrc and .profile ?
# - .ssh/{config,known_hosts}
# - colorize exit_status
# - install nerd font
# - set gruvbox theme for terminal (mac/linux)

### Bootstrap end

