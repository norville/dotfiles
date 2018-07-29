#unalias run-help
#autoload run-help
#HELPDIR=/usr/local/share/zsh/help

# Enable ZSH Completions
fpath=(/usr/local/share/zsh-completions $fpath)

# Enable syntax highlightning
#source /usr/local/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# Uncomment the following line to use case-sensitive completion.
CASE_SENSITIVE="true"

# Uncomment the following line to disable bi-weekly auto-update checks.
#DISABLE_AUTO_UPDATE="true"

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
export PATH="~/.dotfiles/bin:/usr/local/sbin:$PATH"

# OMZ-Theme powerlevel9k settings
#POWERLEVEL9K_MODE='nerdfont-complete'
#DEFAULT_USER=$USER
#POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(context root_indicator dir vcs)
#POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(status background_jobs ram load)

#POWERLEVEL9K_SHORTEN_DIR_LENGTH=1
#POWERLEVEL9K_SHORTEN_DELIMITER=""
#POWERLEVEL9K_SHORTEN_STRATEGY="truncate_from_right"

#POWERLEVEL9K_DIR_HOME_BACKGROUND='24'
#POWERLEVEL9K_DIR_HOME_FOREGROUND='250'
#POWERLEVEL9K_DIR_HOME_SUBFOLDER_BACKGROUND='109'
#POWERLEVEL9K_DIR_HOME_SUBFOLDER_FOREGROUND='235'
#POWERLEVEL9K_DIR_DEFAULT_BACKGROUND='66'
#POWERLEVEL9K_DIR_DEFAULT_FOREGROUND='235'

#POWERLEVEL9K_VCS_CLEAN_BACKGROUND='142'
#POWERLEVEL9K_VCS_CLEAN_FOREGROUND='236'
#POWERLEVEL9K_VCS_UNTRACKED_BACKGROUND='167'
#POWERLEVEL9K_VCS_UNTRACKED_FOREGROUND='236'
#POWERLEVEL9K_VCS_MODIFIED_BACKGROUND='214'
#POWERLEVEL9K_VCS_MODIFIED_FOREGROUND='236'

#POWERLEVEL9K_RAM_ELEMENTS="ram-free"
#POWERLEVEL9K_RAM_BACKGROUND='208'

#POWERLEVEL9K_LOAD_NORMAL_BACKGROUND='72'
#POWERLEVEL9K_LOAD_WARNING_BACKGROUND='172'
#POWERLEVEL9K_LOAD_CRITICAL_BACKGROUND='124'

#POWERLEVEL9K_INSTALLATION_PATH=$ANTIGEN_BUNDLES/bhilburn/powerlevel9k/powerlevel9k.zsh-theme


# Check if this is an SSH session
#if [[ -n $SSH_CONNECTION ]]; then
	# if not
#else
	# if yes
#fi

# Configure ZPLUG
source ~/.zplug/init.zsh

zplug 'zplug/zplug', hook-build:'zplug --self-manage'
zplug zsh-users/zsh-syntax-highlighting
zplug zsh-users/zsh-completions
#zplug vasyharan/zsh-brew-services

#zplug "bhilburn/powerlevel9k", use:powerlevel9k.zsh-theme
zplug nojhan/liquidprompt

if ! zplug check; then
	zplug install
fi

zplug load

