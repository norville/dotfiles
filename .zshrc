# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block, everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

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
#export EDITOR='vim'

# OS-related settings
if [[ $(uname -s) == 'Darwin' ]]; then

    export MACOS=true

    # Enable Homebrew Completion
    if type brew &>/dev/null; then
        FPATH=$(brew --prefix)/share/zsh/site-functions:$FPATH
    fi

fi

# Set PATH
typeset -U path
path=(~/bin /usr/local/sbin $path[@])

# Add custom completion dir
if [[ -d ~/zsh/completions ]]; then
    FPATH=~/.zsh/completions:$FPATH
fi

# Set AUTO_CD
setopt AUTO_CD

# Aliases
### DO NOT DELETE ###
# automatically run git against dotfiles bare repo
alias dfconf='/usr/bin/git --git-dir=$HOME/.dfbare/ --work-tree=$HOME'
### END ###

#alias ls='ls --color=auto'
alias ll='ls -halF'
alias la='ls -hAlF'
alias lr='ls -hAlFR'
alias lt='ls -hAlFt'

### Load plugins via zgen

# Set Zgen path
ZGEN_DIR="$HOME/.zgen"

# If zgen is installed
if [[ -f $ZGEN_DIR/zgen.zsh ]]; then

    # Load main script
    source $ZGEN_DIR/zgen.zsh

    # If no init script
    if ! zgen saved; then

        # Load theme plugin
        zgen load romkatv/powerlevel10k powerlevel10k

        # Load OH-MY-ZSH
        zgen oh-my-zsh

        # Load default plugins
        zgen oh-my-zsh plugins/sudo
        zgen oh-my-zsh plugins/command-not-found
        zgen oh-my-zsh plugins/git
        zgen oh-my-zsh plugins/git-extras
        zgen oh-my-zsh plugins/common-aliases
        zgen oh-my-zsh plugins/colorize
        zgen oh-my-zsh plugins/extract
        zgen oh-my-zsh plugins/vundle
        zgen oh-my-zsh plugins/tmux
        zgen oh-my-zsh plugins/python
        zgen oh-my-zsh plugins/docker
        zgen oh-my-zsh plugins/docker-compose

        # Load optional bundles
        #zgen load vasyharan/zsh-brew-services
        #zgen load srijanshetty/zsh-pip-completion
        #zgen oh-my-zsh pipenv
        #zgen oh-my-zsh npm
        #zgen oh-my-zsh rbenv
        #zgen oh-my-zsh gem
        #zgen oh-my-zsh rails

        # Last plugins to load
        zgen load zsh-users/zsh-completions
        zgen load zsh-users/zsh-syntax-highlighting
        zgen load zsh-users/zsh-history-substring-search

        # Generate init script
        zgen save

    fi

else

    # Zgen not installed
    #echo -e "Zgen not installed!\nRun dotfiles bootstrapper to install it and update the system."
    git clone https://github.com/tarjoilija/zgen.git $ZGEN_DIR

fi

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
