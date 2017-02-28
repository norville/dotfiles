#!/bin/bash

ZSH_PATH=$(which zsh)

# Add ZSH to /etc/shells
if [ ! grep $ZSH_PATH /etc/shells ]; then
	sudo echo $ZSH_PATH >> /etc/shells
fi

# Chanhe login shell
if [ ! $SHELL == $ZSH_PATH ]; then
	chsh -s $ZSH_PATH
fi

# Load ZSH
export ~/.zshrc

