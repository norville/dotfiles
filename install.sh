#!/bin/bash

BASEDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Setting up your Mac..."

xcode-select --install

sudo echo "/usr/local/bin/zsh" >> /etc/shells

# Check for Homebrew and install if we don't have it
if test ! $(which brew); then
  /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
fi

# Update Homebrew recipes
brew update

# Install all our dependencies with bundle (See Brewfile)
brew tap homebrew/bundle
brew bundle
brew cleanup

# Link files
ln -sfv ${BASEDIR}/shell/zshrc ~/.zshrc
ln -sfv ${BASEDIR}/shell/tmux.conf ~/.tmux.conf
ln -sfv ${BASEDIR}/oh-my-zsh ~/.oh-my-zsh
ln -sfv ${BASEDIR}/git/gitconfig ~/.gitconfig
ln -sfv ${BASEDIR}/vim ~/.vim
ln -sfv ${BASEDIR}/vim/vimrc.vim ~/.vimrc
ln -sfv ${BASEDIR}/vim/gvimrc.vim ~/.gvimrc
ln -sfv ${BASEDIR}/atom ~/.atom

# Load ZSH
export ~/.zshrc

# Install Oh-my-Zsh
sh -c "$(wget https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh -O -)"

# Make ZSH the default shell environment
chsh -s $(which zsh)

# Install Pathogen
mkdir -p ~/.vim/autoload ~/.vim/bundle
curl -LSso ~/.vim/autoload/pathogen.vim https://tpo.pe/pathogen.vim

# Install Solarized colorscheme for Vim
git clone git://github.com/altercation/vim-colors-solarized.git ~/.vim/bundle/vim-colors-solarized

# Install powerlevel9k OMZ-theme
git clone https://github.com/bhilburn/powerlevel9k.git ~/.oh-my-zsh/custom/themes/powerlevel9k

# Set macOS preferences
# We will run this last because this will reload the shell
#source macos/macos.sh

# Install Atom Sync Settings and restore configuration
#apm install sync-settings
