# Set Antigen path
ANTIGEN="$HOME/.antigen/antigen.zsh"

if [[ $(uname -s) == 'Darwin' ]]; then
    MACOS=true
else
    MACOS=false
fi

# Check for Antigen
if [[ -f $ANTIGEN ]]; then

    # Load main script
    source $ANTIGEN

    # Load OH-MY-ZSH
    antigen use oh-my-zsh

    if [[ $MACOS ]]; then

        # Load macOS theme settings
        source ~/.zsh/theme.zsh

        # Load macOS bundles
        antigen bundle osx

    else

        #Load Linux theme
        antigen bundle mafredri/zsh-async
        antigen bundle sindresorhus/pure

    fi

    # Load default bundles
    antigen bundle git
    antigen bundle git-extras
    antigen bundle common-aliases
    antigen bundle colorize
    antigen bundle extract
    antigen bundle vundle
    antigen bundle tmux
    antigen bundle python
    antigen bundle docker
    antigen bundle docker-compose

    # Load optional bundles
    #antigen bundle vasyharan/zsh-brew-services
    #antigen bundle srijanshetty/zsh-pip-completion
    #antigen bundle pipenv
    #antigen bundle npm
    #antigen bundle rbenv
    #antigen bundle gem
    #antigen bundle rails

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

