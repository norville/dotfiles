### Manage ZSH plugins via Antigen

# Define plugins dir
ATGN_DIR="${HOME}/.antigen"

# If Antigen is missing
if [[ ! -f "${ATGN_DIR}"/antigen.zsh ]]; then

    # Create plugins dir
    mkdir -p "${ATGN_DIR}"
    # Clone remote repo
    git clone https://github.com/zsh-users/antigen.git "${ATGN_DIR}"

fi

# Load Antigen
source "${ATGN_DIR}"/antigen.zsh

# Load Oh-My-ZSH
antigen use oh-my-zsh

# Load prompt
[[ ! -f "${HOME}"/.zsh/p10k_lean.zsh ]] || source "${HOME}"/.zsh/p10k_lean.zsh

# Load theme
antigen theme romkatv/powerlevel10k powerlevel10k

# Load plugins
antigen bundle aliases
antigen bundle akash329d/zsh-alias-finder               # help finding aliases

# Load LAST
antigen bundle zsh-users/zsh-autosuggestions
antigen bundle zsh-users/zsh-completions
antigen bundle zsh-users/zsh-syntax-highlighting
antigen bundle zsh-users/zsh-history-substring-search

# Apply configuration
antigen apply
