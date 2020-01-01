#
# ~/.bashrc
#

# On linux
if [[ $(uname -s) == 'Linux' ]]; then

    # If not running interactively, don't do anything
    [[ $- != *i* ]] && return

    alias ls='ls --color=auto'
    PS1='[\u@\h \W]\$ '

fi

# Start keychain ssh-agent
[[ type keychain &>/dev/null ]] && eval $(keychain --eval --quiet)

### DO NOT DELETE ###
# Alias for dfbare repo management
alias dfconf='git --git-dir=${HOME}/.dfbare/ --work-tree=${HOME} $@'
###       END     ###
