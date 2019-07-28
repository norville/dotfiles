# Set Antigen path
if [[ $(uname -s) == 'Darwin' ]]; then
    ANTIGEN='/usr/local/share/antigen/antigen.zsh'
    MACOS=true
else
    ANTIGEN='/usr/share/zsh-antigen/antigen.zsh'
fi

# Check for Antigen
if [[ -f $ANTIGEN ]]; then

    # Load main script
    source $ANTIGEN

    # Load OH-MY-ZSH
    antigen use oh-my-zsh

    # Load theme settings
    source ~/.zsh/theme.zsh

    # Load default bundles
    antigen bundle git
    antigen bundle git-extras
    antigen bundle common-aliases
    antigen bundle colorize
    antigen bundle extract
    antigen bundle vundle
    antigen bundle tmux
    antigen bundle python
    #antigen bundle pipenv
    antigen bundle docker
    antigen bundle docker-compose

    # Load optional bundles
    #antigen bundle vasyharan/zsh-brew-services
    #antigen bundle srijanshetty/zsh-pip-completion
    #antigen bundle npm
    #antigen bundle rbenv
    #antigen bundle gem
    #antigen bundle rails

    # Load macOS bundles
    if [[ $MACOS ]]; then
        antigen bundle osx
    fi

    # Last bundles to load
    antigen bundle zsh-users/zsh-completions
    antigen bundle zsh-users/zsh-syntax-highlighting
    antigen bundle zsh-users/zsh-history-substring-search

    # Apply config
    antigen apply

else

    # Antigen not installed
    echo -e "Antigen not installed!\nRun dotfiles bootstrapper to install it and update the system."

fi

