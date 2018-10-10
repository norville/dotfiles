## Configure ZPLUG
#source ~/.zplug/init.zsh

#zplug "zplug/zplug", hook-build:'zplug --self-manage'
#zplug "zsh-users/zsh-completions"
#zplug "zsh-users/zsh-syntax-highlighting"
#zplug "zsh-users/zsh-history-substring-search"
#zplug trapd00r/zsh-syntax-highlighting-filetypes
#zplug srijanshetty/zsh-pip-completion

#zplug "plugins/common-aliases", from:oh-my-zsh
#zplug "plugins/colorize", from:oh-my-zsh
#zplug "plugins/extract", from:oh-my-zsh
#zplug "plugins/tmux", from:oh-my-zsh
#zplug "plugins/vi-mode", from:oh-my-zsh
#zplug "plugins/vundle", from:oh-my-zsh
#zplug "plugins/docker", from:oh-my-zsh
#zplug "plugins/docker-compose", from:oh-my-zsh
#zplug "plugins/git", from:oh-my-zsh
#zplug "plugins/brew", from:oh-my-zsh, if:"[[ $OSTYPE == *darwin* ]]"
#zplug "plugins/osx", from:oh-my-zsh, if:"[[ $OSTYPE == *darwin* ]]"
#zplug "plugins/zsh-dircolors-solarized", from:oh-my-zsh, if:"[[ $OSTYPE == *linux* ]]"

#zplug "bhilburn/powerlevel9k", use:powerlevel9k.zsh-theme, if:"[[ $OSTYPE == *darwin* ]]"
#zplug nojhan/liquidprompt, if:"[[ $OSTYPE == *linux* ]]"

#if ! zplug check; then
#	zplug install
#fi

#zplug load

# Activate Antigen
source /usr/share/zsh-antigen/antigen.zsh

# Load OH-MY-ZSH
antigen use oh-my-zsh

# Load bundles
antigen bundle zsh-users/zsh-completions
antigen bundle zsh-users/zsh-syntax-highlighting
antigen bundle zsh-users/zsh-history-substring-search
antigen bundle trapd00r/zsh-syntax-highlighting-filetypes
antigen bundle tmux
antigen bundle git
antigen bundle git-extras
antigen bundle common-aliases
antigen bundle colorize
antigen bundle extract
antigen bundle vundle
#antigen bundle osx
#antigen bundle vasyharan/zsh-brew-services
#antigen bundle python
#antigen bundle pip
#antigen bundle srijanshetty/zsh-pip-completion
#antigen bundle npm
#antigen bundle rbenv
#antigen bundle gem
#antigen bundle rails
#antigen bundle docker
#antigen bundle docker-compose

# Load theme
antigen theme nojhan/liquidprompt

# Apply config
antigen apply

