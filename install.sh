#!/bin/bash

set -e

# Include customised echo functions
#source ./install.d/echoes.sh

# Define variables
USR=$(whoami)
DF_FULL_DIR=~/dev/dotfiles          # Dotfiles full path
DF_SHORT_DIR=.dotfiles              # Dotfiles short path. For correct expansion DO NOT prepend '~/'
DF_LINK_DIR=$DF_SHORT_DIR/link      # Direcotry containing files to be linked
DF_INST_DIR=$DF_FULL_DIR/install.d  # Directory containing files for installation script
DF_BKP_DIR=~/.dotfiles_bkp          # Backup dir for existing dotfiles

echo -e "\n"
echo "################################################################################"
echo "## DOTFILES INSTALLER                                                         ##"
echo "## Sync dotfiles, install or update required apps, configure the environment. ##"
echo "################################################################################"

echo -e "\n[# 1] Sync dotfiles\n"

# Change to dotfiles dir
echo -en "\n[iii] Ensure current directory is '$DF_FULL_DIR' : "
if [[ "$PWD" != "$DF_FULL_DIR" ]]; then
    echo -en "\n[>>>] Changing to '$DF_FULL_DIR'..."
    cd $DF_FULL_DIR
fi
echo "OK"

# Check for shortcut
echo -en "\n[iii] Ensure '~/$DF_SHORT_DIR' exists : "
if [[ ! -L ~/$DF_SHORT_DIR ]]; then
    echo -en "\n[>>>] Creating shortcut to dotfiles..."
    ln -s $DF_FULL_DIR ~/$DF_SHORT_DIR
fi
echo "OK"

# Create symlinks
echo -en "\n[iii] Link dotfiles to home directory : "
for file in $(ls ~/$DF_LINK_DIR); do
    # Set dotfile path
    dotfile=~/.$file
    echo -en "\n[>>>] Linking '$DF_LINK_DIR/$file' to '$dotfile'..."
    # Check for existing dotfiles
    if [[ -e $dotfile || -d $dotfile ]]; then
        #TODO add argument to confirm/decline all backups
        echo "'$dotfile' already exixts!"
        # Ask for backup
        read -r -p "[???] Make a backup of '$dotfile'? [y|n] " response
        if [[ $response =~ (yes|y|Y) ]]; then
            # Make a backup
            echo -n "[>>>] Backing up '$dotfile'..."
            mkdir -p $DF_BKP_DIR
            cp $dotfile $DF_BKP_DIR/.$file
            echo "DONE"
        fi
    fi
    # Force new symlink
    ln -sf $DF_LINK_DIR/$file $dotfile
done

echo -e "\n[# 2] Install or update required apps\n"

# Ask for the administrator password upfront
echo "[iii] Need admin privileges to go on..."
sudo -v

# If system is macOS
if [[ $(uname -s) == 'Darwin' ]]; then
    echo "[iii] macOS detected!"

    # Check for Homebrew
    #TODO check if Brewfile exists
    echo "[iii] Check Homebrew instance :"
    if [[ ! $(which brew) ]]; then
        echo "[>>>] Installing Homebrew and required formulae..."
        /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
        brew bundle -v --file=$DF_INST_DIR/Brewfile
    else
        echo -n "[>>>] Updating Homebrew and required formulae..."
        if [[ $(brew bundle cleanup --file=$DF_INST_DIR/Brewfile) ]]; then
            echo "found extra formulae already installed!"
            read -r -p "[???] Do you want to uninstall all extra formulae? [y|n] " response
            if [[ $response =~ (yes|y|Y) ]]; then
                echo "[>>>] Uninstalling extra formulae..."
                brew bundle cleanup --file=$DF_INST_DIR/Brewfile --force
            fi
        fi
        brew update --force
        brew upgrade
        brew cask upgrade #--greedy
    fi
    # Cleaning Homebrew leftovers"
    brew cleanup
    brew doctor

    # Update PIP base packages
    echo "[iii] Check Python packages :"
    pip3 install -U pip setuptools wheel

    #TODO install apps via Mac App Store

# If system is Linux
elif [[ $(uname -s) == 'Linux' ]]; then
    echo "[iii] Linux detected!"

    # Install required apps
    echo "[iii] Install or update required packages via APT :"
    sudo apt-get update
    xargs -a $DF_INST_DIR/apt-packages sudo apt-get install -y
    if [[ $? != 0 ]]; then
        echo "[!!!] Unable to install APT packages! Exiting"
        exit 2
    fi
    sudo apt autoremove
    sudo apt autoclean
fi

echo -e "\n[# 3] Configure the environment\n"

# Set ZSH as login shell
echo -en "\n[iii] Setup ZSH as login shell : "
ZSH_PATH=$(which zsh)
if [[ $SHELL != $ZSH_PATH ]]; then
    echo -en "\n[>>>] Changing login shell to ZSH..."
    echo $ZSH_PATH | sudo tee -a /etc/shells
    sudo chsh -s $ZSH_PATH $USR
fi
echo "OK"

# Install Antigen
echo -en "\n[iii] Setup Antigen as ZSH plugin manager : "
# Check if already configured
if [[ -d ~/.antigen ]]; then
    # Remove current config
    echo -en "\n[>>>] Resetting Antigen plugins..."
    rm -rf ~/.antigen
    echo -n "OK"
fi
# Download Antigen
echo -en "\n[>>>] Downloading Antigen : "
mkdir -p ~/.antigen
curl -sL git.io/antigen > ~/.antigen/antigen.zsh
echo "DONE"

# Download Docker Completion file
echo -en "\n[iii] Setup Docker completion : "
if [[ ! -d ~/.zsh_completion ]]; then
    echo -en "\n[>>>] Downloading Docker completion files..."
    mkdir -p ~/.zsh_completion
    curl -sL https://raw.githubusercontent.com/docker/machine/v0.14.0/contrib/completion/zsh/_docker-machine > ~/.zsh_completion/_docker-machine
fi
echo "DONE"

# Install Vundle plugins
echo -en "\n[iii] Setup Vundle as VIM plugin manager : "
if [[ ! -d ~/.vim/bundle/Vundle.vim ]]; then
    echo -en "\n[>>>] Downloading Vundle..."
    git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim
    echo "OK"
fi
echo -en "\n[>>>] Updating Vundle plugins : "
vim -i NONE -c VundleUpdate -c quitall > /dev/null 2>&1
echo "DONE"

# Install required Python packages
#pip3 install -r install.d/requirements.txt

echo -e "\n[###] All done! Close this session and log in again.\n"
