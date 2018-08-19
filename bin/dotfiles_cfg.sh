#!/usr/bin/zsh

# Check if zplug is installed
if [[ ! -d ~/.zplug ]]; then
	ZPLUG_URL="https://raw.githubusercontent.com/zplug/installer/master/installer.zsh"
	curl -sL --proto-redir -all,https $ZPLUG_URL | zsh
	source ~/.zplug/init.zsh && zplug update --self
fi

# Init zplug
source ~/.zplug/init.zsh

# Install packages that have not been installed yet
if ! zplug check --verbose; then
	zplug install
fi

# Load zplug
zplug load

# Install ZSH completions
COMP_DIR="$HOME/.zsh/completion"
DCC='https://raw.githubusercontent.com/docker/compose/1.22.0/contrib/completion/zsh/_docker-compose'
if [[ ! -f $COMP_DIR/_docker-compose ]]; then
	curl -L $DCC > $COMP_DIR/_docker-compose
fi

# Install Vundle plugins
if [[ ! -d ~/.vim/bundle/Vundle.vim ]]; then
	git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim
fi
vim -i NONE -c VundleUpdate -c quitall

