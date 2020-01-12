###############################################################################

### GLOBAL SETTINGS ###########################################################

# Uncomment the following line to use case-sensitive completion.
CASE_SENSITIVE="true"

# Uncomment to enable automatic upgrades
#DISABLE_UPDATE_PROMPT=true

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
export EDITOR='vim'

# Set AUTO_CD
setopt AUTO_CD

###############################################################################

### GLOBAL PATH ###############################################################

typeset -U path
path=(~/bin /usr/local/sbin $path[@])

###############################################################################

### COMPLETIONS ###############################################################

# Enable Homebrew Completion
[[ $(type brew &>/dev/null) ]] && FPATH=$(brew --prefix)/share/zsh/site-functions:${FPATH}

##############################################################################

### SERVICES ##################################################################

# Start keychain ssh-agent
[[ $(type keychain &>/dev/null) ]] && eval $(keychain --eval --quiet)

###############################################################################

### PLUGINS ###################################################################

[[ -f ${HOME}/.zsh/plugins.zsh ]] && . ${HOME}/.zsh/plugins.zsh

###############################################################################

### ALIASES (last) ############################################################

#alias ls='ls --color=auto'
alias la='ls -halF'
alias ll='ls -hAlF'
alias lr='ls -hAlFR'
alias lt='ls -hAlFt'

### DO NOT DELETE ###
# automatically run git against dotfiles bare repo
alias dfconf="git --git-dir=${HOME}/.dfbare/ --work-tree=${HOME}"
### END ###

###############################################################################
