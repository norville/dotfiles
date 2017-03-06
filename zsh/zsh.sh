#!/bin/bash

ZSH_PATH=$(which zsh)

if [ $SHELL == $ZSH_PATH ]
then
	echo "ZSH is already the login shell."
else
	echo "Changing login shell to ZSH..."
	echo $ZSH_PATH | sudo tee -a /etc/shells
	chsh -s $ZSH_PATH
fi

