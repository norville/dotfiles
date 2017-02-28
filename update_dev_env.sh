#!/bin/bash

pip3 install --upgrade pip wheel setuptools
npm update -g

LATEST_RUBY=`egrep "^\s+\d\.\d\.\d+$" <(rbenv install -l) | tail -1`
#rbenv install $LATEST_RUBY
echo $LATEST_RUBY
