### Manage ZSH plugins via Antigen

ATGN_DIR="${HOME}/.antigen"     # Define plugins dir

# If Antigen is missing
if [[ ! -f ${ATGN_DIR}/antigen.zsh ]]; then

    # Create plugins dir
    mkdir -p ${ATGN_DIR}
    # Clone remote repo
    git clone https://github.com/zsh-users/antigen.git ${ATGN_DIR}

fi

# Load Antigen
source ${ATGN_DIR}/antigen.zsh

# Load Oh-My-ZSH
antigen use oh-my-zsh

# Load ZSH theme if config file ready
[[ ! -f ${HOME}/.zsh/p10k.zsh ]] || source ${HOME}/.zsh/p10k.zsh
# Load theme plugin
antigen theme romkatv/powerlevel10k powerlevel10k

# Load default plugins
antigen bundle sudo
antigen bundle command-not-found
antigen bundle git
antigen bundle git-extras
antigen bundle common-aliases
antigen bundle colorize
antigen bundle extract
antigen bundle vundle
antigen bundle python
antigen bundle docker
antigen bundle docker-compose

# Load optional plugins
#antigen bundle vasyharan/zsh-brew-services
#antigen bundle srijanshetty/zsh-pip-completion
#antigen bundle pipenv
#antigen bundle npm
#antigen bundle rbenv
#antigen bundle gem
#antigen bundle rails
#antigen bundle tmux

# Last plugins to load
antigen bundle zsh-users/zsh-completions
antigen bundle zsh-users/zsh-syntax-highlighting
antigen bundle zsh-users/zsh-history-substring-search

# Apply configuration
antigen apply
