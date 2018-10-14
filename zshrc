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

# Set PATH
typeset -U path
path=(~/.dotfiles/bin /usr/local/sbin $path[@])

# Enable Completions
if type brew &>/dev/null; then
  FPATH=$(brew --prefix)/share/zsh/site-functions:$FPATH
fi

# Set AUTO_CD
setopt AUTO_CD

# Aliases
source ~/.zsh/aliases.zsh

# Load theme settings
source ~/.zsh/theme.zsh

# Load plugins
source ~/.zsh/plugins.zsh

