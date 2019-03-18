# Activate Antigen
source ~/.antigen/antigen.zsh

# Load OH-MY-ZSH
antigen use oh-my-zsh

# Load theme settings
source ~/.zsh/theme.zsh

if [[ $(uname -s) == 'Darwin' ]]; then

	# Load macOS theme
	antigen theme bhilburn/powerlevel9k powerlevel9k

	# Load macOS bundles
	antigen bundle osx

elif [[ $(uname -s) == 'Linux' ]]; then

	# Load Linux theme
	antigen theme nojhan/liquidprompt

	# Load Linux bundles

fi

# Load default bundles
antigen bundle tmux
antigen bundle git
antigen bundle git-extras
antigen bundle common-aliases
antigen bundle colorize
antigen bundle extract
antigen bundle vundle

# Load optional bundles
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

# Last bundles to load
antigen bundle zsh-users/zsh-completions
antigen bundle zsh-users/zsh-syntax-highlighting
antigen bundle zsh-users/zsh-history-substring-search

# Apply config
antigen apply

