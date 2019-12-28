#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls --color=auto'
PS1='[\u@\h \W]\$ '

### DO NOT DELETE ###
# Alias for dfbare repo management
alias dfconf='git --git-dir=${HOME}/.dfbare/ --work-tree=${HOME} $@'
###       END     ###

# Start Keychain ssh-agent
eval $(keychain --eval --quiet)
