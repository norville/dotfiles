# Configure ZPLUG
source ~/.zplug/init.zsh

zplug "zplug/zplug", hook-build:'zplug --self-manage'
zplug "zsh-users/zsh-completions"
zplug "zsh-users/zsh-syntax-highlighting"
zplug "zsh-users/zsh-history-substring-search"
zplug vasyharan/zsh-brew-services, if:"[[ $OSTYPE == *darwin* ]]"
#zplug trapd00r/zsh-syntax-highlighting-filetypes
zplug srijanshetty/zsh-pip-completion

zplug "plugins/common-aliases", from:oh-my-zsh
zplug "plugins/colorize", from:oh-my-zsh
zplug "plugins/extract", from:oh-my-zsh
zplug "plugins/tmux", from:oh-my-zsh
#zplug "plugins/vi-mode", from:oh-my-zsh
zplug "plugins/vundle", from:oh-my-zsh
zplug "plugins/docker", from:oh-my-zsh
zplug "plugins/docker-compose", from:oh-my-zsh
zplug "plugins/git", from:oh-my-zsh
zplug "plugins/brew", from:oh-my-zsh, if:"[[ $OSTYPE == *darwin* ]]"
zplug "plugins/osx", from:oh-my-zsh, if:"[[ $OSTYPE == *darwin* ]]"
#zplug "plugins/zsh-dircolors-solarized", from:oh-my-zsh, if:"[[ $OSTYPE == *linux* ]]"

zplug "bhilburn/powerlevel9k", use:powerlevel9k.zsh-theme, if:"[[ $OSTYPE == *darwin* ]]"
zplug nojhan/liquidprompt, if:"[[ $OSTYPE == *linux* ]]"

if ! zplug check; then
	zplug install
fi

zplug load

