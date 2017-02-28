#!/bin/bash

brew upgrade
brew update

pip3 install --upgrade pip wheel setuptools powerline-status
npm update -g

LATEST_RUBY=`egrep "^\s+\d\.\d\.\d+$" <(rbenv install -l) | tail -1`
rbenv install $LATEST_RUBY
rbenv init
rbenv rehash
rbenv global $LATEST_RUBY
