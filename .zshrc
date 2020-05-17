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
export VISUAL='vim'

# Set AUTO_CD
setopt AUTO_CD

###############################################################################

### GLOBAL PATH ###############################################################

typeset -U path
path=(~/bin /usr/local/sbin $path[@])

###############################################################################

### COMPLETIONS ###############################################################

# Enable Homebrew Completion
if type brew &>/dev/null; then
    FPATH=$(brew --prefix)/share/zsh/site-functions:${FPATH}
fi

##############################################################################

### SERVICES ##################################################################

# Start keychain ssh-agent
if type keychain &>/dev/null; then

    eval `keychain --eval --nogui -Q -q bassa_key`

fi

# Enable VTE for Tilix
if [[ -f /etc/profile.d/vte.sh ]]; then

    if [[ ${TILIX_ID} || ${VTE_VERSION} ]]; then

        source /etc/profile.d/vte.sh

    fi
fi

###############################################################################

### PLUGINS ###################################################################

[[ -f ${HOME}/.zsh/plugins.zsh ]] && . ${HOME}/.zsh/plugins.zsh

###############################################################################

### ALIASES (last) ############################################################

# set time format when listing
timestyle='--time-style="+%Y-%m-%d %H:%M:%S"'

# detect OS
if [[ -f /etc/os-release ]]; then

    # OS is linux
    alias ls='ls -v --color=auto'

else

    # OS is macOS
    alias ls='gls -v --color=auto'

fi

alias la="ls -halF ${timestyle}"
alias ll="ls -hAlF ${timestyle}"
alias lr="ls -hAlFR ${timestyle}"
alias lt="ls -hAlFt ${timestyle}"

### DO NOT DELETE ###
# automatically run git against dotfiles bare repo
alias dfconf="git --git-dir=${HOME}/.dfbare/ --work-tree=${HOME}"
### END ###

###############################################################################
