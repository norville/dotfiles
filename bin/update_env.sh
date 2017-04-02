#!/bin/sh

set -e

# Update Homebrew
brew doctor
brew update
brew upgrade
brew cleanup

# Update PyPI
pip install --upgrade pip wheel setuptools
pip-review --auto

# Update NPM
npm update -g

# Update VIM Plugins
vim +PluginUpdate +qall

# Update Antigen bundles
antigen update
antigen cleanup

