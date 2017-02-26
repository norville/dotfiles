#!/bin/bash

# Check for Homebrew and install if we don't have it
if test ! $(which brew); then
  /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
fi

# Update Homebrew recipes
brew update --force
brew upgrade --cleanup

# Install all our dependencies with bundle (See Brewfile)
brew tap homebrew/bundle
brew bundle -v --file=brew/Brewfile
brew cleanup
