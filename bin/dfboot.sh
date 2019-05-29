#!/bin/bash

### Define variables and functions

# Local paths
BARE_DIR=.dfbare                                    # git dir for bare repo
BKP_DIR=$HOME/.dfbackup                             # backup dir for pre-existing dotfiles
APT_PKGS=$HOME/.dfconf/apt-packages
FONT_DIR=$HOME/.local/share/fonts
BREW_PKGS=$HOME/.dfconf/Brewfile

# Remote URLs
REPO_URL='https://github.com/norville/dotfiles.git'   # URL to remote repo
FONT_URL='https://github.com/ryanoasis/nerd-fonts/blob/master/patched-fonts/SourceCodePro/Regular/complete/Sauce%20Code%20Pro%20Nerd%20Font%20Complete%20Mono.ttf'
FONT_NAME='Sauce Code Pro Nerd Font Complete Mono.ttf'
BREW_URL='https://raw.githubusercontent.com/Homebrew/install/master/install'

# Check local paths

# Check remote URLs

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

# Clone dotfiles into a local bare repo
function prep_repo {

    # If system is Linux ensure git is installed
    if [[ $(uname -s) == 'Linux' ]]; then

        sudo apt-get install git -y
        exit_status "installing git"

    fi

    # Check bare repo dir
    cd $HOME
    if [[ ! -d $BARE_DIR ]]; then
        # Create directory for bare repository
        mkdir -p $BARE_DIR
    fi

    # Check bare repo status
    cd $BARE_DIR
    if [[ ! $(git rev-parse --is-bare-repository) ]]; then

        cd $HOME
        # Clone remote repo into the bare repo inside $HOME
        #git clone --bare <git-repo-url> <git-bare-dir>
        #git clone --bare $REPO_URL $BARE_DIR
        # Clone specifc branch
        git clone --bare -b bare $REPO_URL $BARE_DIR
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

# Install or update required packages
function apps() {

    # Detect system
    if [[ $(uname -s) == 'Linux' ]]; then

        # If system is Linux

        # Install required packages
        xargs -a $APT_PKGS sudo apt-get install -y
        exit_status "installing required packages in $APT_PKGS"

        # Cleanup
        sudo apt autoremove
        sudo apt autoclean

        # Install Nerd-Fonts
        # Ensure FONT_DIR exists
        if [[ ! -d $FONT_DIR ]]; then
            mkdir -p $FONT_DIR
        fi
        cd $FONT_DIR
        # Download nerd-font
        curl -fLo $FONT_NAME $FONT_URL
        exit_status "downloading $FONT_NAME in $FONT_DIR"
        cd -

        # TODO
        # - make it distro indipendent: support yum and arch pkgs
        # - set gruvbox theme for terminal
        # - restore preferences

    elif [[ $(uname -s) == 'Darwin' ]]; then

        # If system is macOS

        # Check for Homebrew
        if [[ ! $(which brew) ]]; then

            # Install Homebrew and all required packages

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

}

# Configure the environment
function env() {

    # Ensure ZSH is the login shell
    ZSH_PATH=$(which zsh)
    if [[ $SHELL != $ZSH_PATH ]]; then

        # Set ZSH as login shell
        echo $ZSH_PATH | sudo tee -a /etc/shells
        sudo chsh -s $ZSH_PATH $USER
        exit_status "setting ZSH as login shell"

    else

        # Already set!
        exit_status "checking login shell (ZSH)"

    fi

    # Always get last version of Antigen
    ANT_URL='https://raw.githubusercontent.com/zsh-users/antigen/master/bin/antigen.zsh'
    ANT_DIR=$HOME/.zsh/antigen
    if [[ -d $ANT_DIR ]]; then

        # Delete existing version
        rm -rf $ANT_DIR
        exit_status "removing current version of Antigen"

    fi
    mkdir -p $ANT_DIR
    # Download last version
    curl -sL $ANT_URL > $ANT_DIR/antigen.zsh
    exit_status "installing Antigen"

    # Install ZSH Completions
    #COMP_DIR=$HOME/.zsh/completions
    #if [[ ! -d $COMP_DIR ]]; then
        #mkdir -p $COMP_DIR
    #fi

    ### Editor and plugins

    # Install or update Vundle and required plugins
    VDL_URL='https://github.com/VundleVim/Vundle.vim.git'
    VDL_DIR=$HOME/.vim/bundle
    if [[ ! -d $VDL_DIR/Vundle.vim ]]; then

        # Download Vundle
        git clone $VDL_URL $VDL_DIR/Vundle.vim
        exit_status "installing Vundle"

    fi
    # Update Vundle and required plugins
    vim -i NONE -c VundleUpdate -c quitall > /dev/null 2>&1
    exit_status "updating Vundle plugins"

}

### Bootstrap begin

#set -e

# Get admin privileges
sudo -v

### Prepare bare repo
prep_repo

### Install or update required software
apps

### Configure environment
env

# TODO
# - !!! check what runs first: clone or dfbstrap?
# - .bashrc and .profile ?
# - .ssh/{config,known_hosts}
# - colorize exit_status
# - case system detection
# - break into IDEMPOTENT functions - respect ORDER:
# - • sudo -v
#   • prep (repo)
#   • apps (min sw)
#   • env (shell, plugins, editor)
#   • code (dev frameworks)

### Bootstrap end

# TODO countdown to reboot

