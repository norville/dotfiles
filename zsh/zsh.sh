#!/bin/bash

ZSH_PATH=$(which zsh)

if [ $SHELL == $ZSH_PATH ]
then
	echo "ZSH is already the login shell."
else
	echo "Changing login shell to ZSH..."
	sudo echo $ZSH_PATH >> /etc/shells
	chsh -s $ZSH_PATH
#	export ~/.zshrc
fi

