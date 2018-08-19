#!/usr/bin/zsh

# Check for zplug
if [[ ! -d ~/.zplug ]]; then
	ZPLUG_URL="https://raw.githubusercontent.com/zplug/installer/master/installer.zsh"
	curl -sL --proto-redir -all,https $ZPLUG_URL | zsh
fi

# Update zplug
source ~/.zplug/init.zsh
if ! zplug check --verbose; then
	zplug install
fi
zplug update
zplug clean --force
zplug clear --force
zplug load --verbose

# Install Vundle plugins
if [[ ! -d ~/.vim/bundle/Vundle.vim ]]; then
	git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim
fi
vim -i NONE -c VundleUpdate -c quitall

