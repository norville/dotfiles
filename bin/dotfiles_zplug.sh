#!/usr/bin/zsh

# Check if zplug is installed
if [[ ! -d ~/.zplug ]]; then
	url="https://raw.githubusercontent.com/zplug/installer/master/installer.zsh"
	curl -sL --proto-redir -all,https $url | zsh
	source ~/.zplug/init.zsh && zplug update --self
fi

# Init zplug
source ~/.zplug/init.zsh

# Install packages that have not been installed yet
if ! zplug check --verbose; then
	zplug install
fi

zplug load

