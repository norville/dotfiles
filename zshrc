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

# Set language
#export LC_ALL=en_US.UTF-8
#export LANG=en_US.UTF-8

# Set default editor
#export EDITOR='vim'

# Load theme settings
source ~/.zsh/theme.zsh

# Load plugins
source ~/.zsh/plugins.zsh

# Aliases
alias ls='ls --color=auto'
alias ll='ls -halF'
alias la='ls -hAlF'
alias lr='ls -hAlFR'
alias lt='ls -hAlFt'

# Set PATH
typeset -U path
path=(~/.dotfiles/bin $path[@])

# Set AUTO_CD
setopt AUTO_CD

# Enable Completions
#autoload -Uz compinit && compinit -i

