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

# Uncomment the following line to change how often to auto-update (in days).
export UPDATE_ZSH_DAYS=7

# Set language
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8

# Set default editor
export EDITOR='vim'

# Set PATH
export PATH="$HOME/.dotfiles/bin:/usr/local/sbin:$PATH"

# Set AUTO_CD
setopt AUTO_CD

# Load theme settings
source ~/.zsh/theme.zsh

# Load plugins
source ~/.zsh/plugins.zsh

# Enable syntax highlightning
#source /usr/local/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# Set list colors theme
DCS="$HOME/.zsh/dircolors-solarized"
if [[ $OSTYPE == *linux* && -d $DCS ]]; then
	eval `dircolors $DCS/dircolors.256dark`
fi

# Aliases
alias ls='ls --color=auto'
alias ll='ls -halF'
alias la='ls -hAlF'
alias lr='ls -hAlFR'
alias lt='ls -hAlFt'

# Enable Completions
#fpath=(~/.zsh/completion $fpath)
#fpath=(/usr/local/share/zsh-completions $fpath)
autoload -Uz compinit && compinit -i

# Check if this is an SSH session
#if [[ -n $SSH_CONNECTION ]]; then
	# if not
#else
	# if yes
#fi

