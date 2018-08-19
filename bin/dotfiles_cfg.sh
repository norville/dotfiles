#!/usr/bin/zsh

# Check for zplug and update it
if [[ ! -d ~/.zplug ]]; then
	ZPLUG_URL="https://raw.githubusercontent.com/zplug/installer/master/installer.zsh"
	curl -sL --proto-redir -all,https $ZPLUG_URL | zsh
else
	zplug update
	zplug clean --force
	zplug clear
fi

# Install Vundle plugins
if [[ ! -d ~/.vim/bundle/Vundle.vim ]]; then
	git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim
fi
vim -i NONE -c VundleUpdate -c quitall

