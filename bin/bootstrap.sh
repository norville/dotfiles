#!/bin/bash

set -e

# Define variables
REPO_URL=https://github.com/norville/dotfiles.git   # URL to remote repo
BARE_DIR=.dfbare                                    # git dir for bare repo
BKP_DIR=$HOME/.dfbackup                             # backup dir for pre-existing dotfiles

# Define function to automatically run git against the bare repo in $HOME
function dfconf {
    # /usr/bin/git --git-dir=<git-bare-dir> --work-tree=<dotfiles-dir>
    /usr/bin/git --git-dir=$BARE_DIR --work-tree=$HOME $@
}

# Get admin privileges
sudo -v

# If system is Linux, ensure git is installed
if [[ $(uname -s) == 'Linux' ]]; then
    sudo apt-get update
    sudo apt-get install git -y
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

    # Clone remote repo into the bare repo inside $HOME
    # git clone --bare <git-repo-url> <git-bare-dir>
    cd $HOME
    git clone --bare $REPO_URL $BARE_DIR

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

# TODO continue bootstrap

# TODO
# - install nerd font
# - set gruvbox theme for terminal (mac/linux)
