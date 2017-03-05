#!/bin/bash

brew update
brew upgrade

pip3 install --upgrade pip wheel setuptools powerline-status
npm update -g

LATEST_RUBY=`egrep "^\s+\d\.\d\.\d+$" <(rbenv install -l) | tail -1`
GLOBAL_RUBY=$(rbenv global)

if [ $LATEST_RUBY==$GLOBAL_RUBY ]
then
	echo "Ruby is already up to date."
else
	rbenv install $LATEST_RUBY
	rbenv init
	rbenv rehash
	rbenv global $LATEST_RUBY
fi

