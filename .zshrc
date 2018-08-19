# Uncomment the following line to use case-sensitive completion.
CASE_SENSITIVE="true"

# Uncomment to enable automatic upgrades
DISABLE_UPDATE_PROMPT=true

# Uncomment the following line to enable command auto-correction.
ENABLE_CORRECTION="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# The optional three formats: "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
HIST_STAMPS="dd/mm/yyyy"

# Uncomment the following line to change how often to auto-update (in days).
export UPDATE_ZSH_DAYS=7

# Set language
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8

# Set default editor
export EDITOR='vim'

# Set PATH
export PATH="~/.dotfiles/bin:/usr/local/sbin:$PATH"

# Set AUTO_CD
setopt AUTO_CD

# OMZ-Theme powerlevel9k settings
#POWERLEVEL9K_MODE='nerdfont-complete'
#DEFAULT_USER=$USER
#POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(context root_indicator dir vcs)
#POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(status background_jobs ram load)

#POWERLEVEL9K_SHORTEN_DIR_LENGTH=1
#POWERLEVEL9K_SHORTEN_DELIMITER=""
#POWERLEVEL9K_SHORTEN_STRATEGY="truncate_from_right"

#POWERLEVEL9K_DIR_HOME_BACKGROUND='24'
#POWERLEVEL9K_DIR_HOME_FOREGROUND='250'
#POWERLEVEL9K_DIR_HOME_SUBFOLDER_BACKGROUND='109'
#POWERLEVEL9K_DIR_HOME_SUBFOLDER_FOREGROUND='235'
#POWERLEVEL9K_DIR_DEFAULT_BACKGROUND='66'
#POWERLEVEL9K_DIR_DEFAULT_FOREGROUND='235'

#POWERLEVEL9K_VCS_CLEAN_BACKGROUND='142'
#POWERLEVEL9K_VCS_CLEAN_FOREGROUND='236'
#POWERLEVEL9K_VCS_UNTRACKED_BACKGROUND='167'
#POWERLEVEL9K_VCS_UNTRACKED_FOREGROUND='236'
#POWERLEVEL9K_VCS_MODIFIED_BACKGROUND='214'
#POWERLEVEL9K_VCS_MODIFIED_FOREGROUND='236'

#POWERLEVEL9K_RAM_ELEMENTS="ram-free"
#POWERLEVEL9K_RAM_BACKGROUND='208'

#POWERLEVEL9K_LOAD_NORMAL_BACKGROUND='72'
#POWERLEVEL9K_LOAD_WARNING_BACKGROUND='172'
#POWERLEVEL9K_LOAD_CRITICAL_BACKGROUND='124'

#POWERLEVEL9K_INSTALLATION_PATH=$ANTIGEN_BUNDLES/bhilburn/powerlevel9k/powerlevel9k.zsh-theme


# Check if this is an SSH session
#if [[ -n $SSH_CONNECTION ]]; then
	# if not
#else
	# if yes
#fi

# Configure ZPLUG
source ~/.zplug/init.zsh

zplug 'zplug/zplug', hook-build:'zplug --self-manage'
zplug zsh-users/zsh-syntax-highlighting
zplug zsh-users/zsh-completions
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
zplug "plugins/git", from:oh-my-zsh
zplug "plugins/brew", from:oh-my-zsh, if:"[[ $OSTYPE == *darwin* ]]"
zplug "plugins/osx", from:oh-my-zsh, if:"[[ $OSTYPE == *darwin* ]]"
zplug "plugins/zsh-dircolors-solarized", from:oh-my-zsh, if:"[[ $OSTYPE == *linux* ]]"

zplug "bhilburn/powerlevel9k", use:powerlevel9k.zsh-theme, if:"[[ $OSTYPE == *darwin* ]]"
zplug nojhan/liquidprompt, if:"[[ $OSTYPE == *linux* ]]"

if ! zplug check; then
	zplug install
fi

zplug load

# Set list colors theme
#git clone https://github.com/seebi/dircolors-solarized
#eval `dircolors /path/to/dircolorsdb`

# Enable Docker Completions
#url='https://raw.githubusercontent.com/docker/compose/1.22.0/contrib/completion/zsh/_docker-compose'
#> ~/.zsh/completion/_docker-compose

# Aliases
alias ls='ls --color=auto'
alias ll='ls -halF'
alias la='ls -hAlF'

# Load compinit
autoload -Uz compinit && compinit -i

