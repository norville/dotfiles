#!/bin/bash

set -e

# Update Homebrew
brew doctor
brew update
brew upgrade
brew cleanup

# Update PyPI
pip install --upgrade pip wheel setuptools powerline-status

# Update NPM
npm update -g

# Update VIM Plugins
vim +PluginInstall +qall

