#!/bin/zsh
# =============================================================================
# ZSH Plugin Manager Configuration (Antigen)
# =============================================================================
# This file manages ZSH plugins using Antigen, a plugin manager for ZSH
# Antigen provides simple plugin management with automatic installation
#
# Documentation: https://github.com/zsh-users/antigen
#
# Plugin loading order matters:
# 1. Oh-My-ZSH framework plugins
# 2. Utility plugins (completions, tools)
# 3. UI enhancement plugins (autosuggestions, syntax highlighting) - loaded last
#
# Last updated: 2025
# =============================================================================

# =============================================================================
# ANTIGEN PLUGIN MANAGER SETUP
# =============================================================================

# -----------------------------------------------------------------------------
# Antigen Installation Directory
# -----------------------------------------------------------------------------
# Store Antigen in XDG data directory
export ADOTDIR="${XDG_DATA_HOME:-${HOME}/.local/share}/antigen"
ANTIGEN="${ADOTDIR}/antigen.zsh"

# -----------------------------------------------------------------------------
# Auto-Install Antigen if Missing
# -----------------------------------------------------------------------------
# Automatically clone Antigen from GitHub if it's not already installed
# Using git clone (not curl) to support 'antigen selfupdate' command
if [[ ! -f "${ANTIGEN}" ]]; then
    echo "Antigen not found. Installing to ${ADOTDIR}..."

    # Reset any existing incomplete installation
    [[ -d "${ADOTDIR}" ]] && rm -rf "${ADOTDIR}"
    mkdir -p "${ADOTDIR}"

    # Check if git is available
    if ! command -v git >/dev/null 2>&1; then
        echo "Error: git is required to install Antigen. Please install git first."
        return 1
    fi

    # Clone Antigen repository (enables selfupdate functionality)
    if git clone --depth=1 https://github.com/zsh-users/antigen.git "${ADOTDIR}"; then
        echo "Antigen installed successfully!"
    else
        echo "Error: Failed to clone Antigen repository."
        echo "Please check your internet connection and try again."
        return 1
    fi

    # Create default log file to prevents warnings
    touch "${ADOTDIR}/debug.log"

fi

# -----------------------------------------------------------------------------
# Load Antigen Plugin Manager
# -----------------------------------------------------------------------------
# Source the Antigen script to enable plugin management
if [[ -f "${ANTIGEN}" ]]; then
    source "${ANTIGEN}"
else
    echo "Error: Antigen installation incomplete. Please remove ${ADOTDIR} and restart your shell."
    return 1
fi

# =============================================================================
# PLUGIN CONFIGURATION
# =============================================================================

# -----------------------------------------------------------------------------
# Set up Oh-My-ZSH Framework
# -----------------------------------------------------------------------------
# Set up cache directory to avoid polluting home directory
export ZSH_CACHE_DIR="${XDG_CACHE_HOME:-${HOME}/.cache}/oh-my-zsh"

# Create cache and completions directories
mkdir -p "${ZSH_CACHE_DIR}/completions"

# Load Oh-My-ZSH as the base framework
antigen use oh-my-zsh

# -----------------------------------------------------------------------------
# Utility Plugins
# -----------------------------------------------------------------------------
antigen bundle 1password                    # 1Password CLI integration
antigen bundle akash329d/zsh-alias-finder   # Find useful aliases
antigen bundle aliases                      # Provides 'acs' command to search aliases
antigen bundle Aloxaf/fzf-tab               # Fuzzy autocomplete for ZSH using fzf
antigen bundle archlinux                    # Arch Linux shortcuts and aliases
antigen bundle chezmoi                      # Chezmoi shortcuts
antigen bundle colorize                     # Colorize command output
antigen bundle eza                          # Enhanced ls command
antigen bundle git                          # Git shortcuts and aliases
antigen bundle kitty                        # Kitty terminal shortcuts
antigen bundle ssh                          # SSH shortcuts and completions

# -----------------------------------------------------------------------------
# Coding Plugins
# -----------------------------------------------------------------------------
antigen bundle ansible          # Ansible shortcuts and completions
antigen bundle docker           # Docker completion and aliases
antigen bundle docker-compose   # Docker Compose completion
#antigen bundle python           # Python shortcuts
#antigen bundle pip              # Pip completion
#antigen bundle kubectl          # Kubernetes shortcuts
#antigen bundle npm              # NPM completion
#antigen bundle node             # Node.js shortcuts

# -----------------------------------------------------------------------------
# Interactive Enhancement Plugins
# -----------------------------------------------------------------------------
# CRITICAL: These MUST be loaded last for proper functionality

# Additional completions for hundreds of CLI tools
# IMPORTANT: Must be loaded before syntax-highlighting
antigen bundle zsh-users/zsh-completions

# Autosuggestions: suggests commands as you type based on history
# Press → to accept, Ctrl+→ to accept one word
antigen bundle zsh-users/zsh-autosuggestions

# Syntax highlighting: real-time command syntax highlighting
# Green = valid command, Red = invalid command
# MUST load after autosuggestions, before history-substring-search
antigen bundle zsh-users/zsh-syntax-highlighting

# History substring search: search history with up/down arrows
# Type partial command and press ↑/↓ to search
# MUST be loaded LAST
antigen bundle zsh-users/zsh-history-substring-search

# -----------------------------------------------------------------------------
# Apply Configuration
# -----------------------------------------------------------------------------
antigen apply

# =============================================================================
# POST-PLUGIN CONFIGURATION
# =============================================================================

# -----------------------------------------------------------------------------
# Autosuggestions Configuration
# -----------------------------------------------------------------------------
# Customize autosuggestion behavior and appearance
if [[ -n "$ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE" ]] || type _zsh_autosuggest_start >/dev/null 2>&1; then
    # Suggestion color (subtle gray - Tokyo Night Moon comment color)
    ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=#636da6'

    # Suggestion strategy: try history first, then completion
    ZSH_AUTOSUGGEST_STRATEGY=(history completion)

    # Buffer size limit for suggestions
    ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=20

    # Accept suggestion with Ctrl+Space (in addition to →)
    bindkey '^ ' autosuggest-accept
fi

# -----------------------------------------------------------------------------
# Syntax Highlighting Configuration (Tokyo Night Moon)
# -----------------------------------------------------------------------------
# Customize syntax highlighting colors to match Tokyo Night Moon theme
# Color palette: https://github.com/folke/tokyonight.nvim/blob/main/extras/lua/tokyonight_moon.lua
#
# Tokyo Night Moon Colors:
# - Background: #222436
# - Foreground: #c8d3f5
# - Blue:       #82aaff
# - Cyan:       #86e1fc
# - Green:      #c3e88d
# - Yellow:     #ffc777
# - Orange:     #ff966c
# - Red:        #ff757f
# - Magenta:    #c099ff
# - Comment:    #636da6

if type _zsh_highlight >/dev/null 2>&1; then
    # Customize colors for different command types
    typeset -A ZSH_HIGHLIGHT_STYLES

    # Main highlighter styles
    ZSH_HIGHLIGHT_STYLES[unknown-token]='fg=#ff757f,bold'               # Red - invalid/unknown tokens
    ZSH_HIGHLIGHT_STYLES[reserved-word]='fg=#c099ff,bold'               # Magenta - reserved words (if, then, else, etc)
    ZSH_HIGHLIGHT_STYLES[suffix-alias]='fg=#86e1fc,underline'           # Cyan underlined - suffix aliases
    ZSH_HIGHLIGHT_STYLES[global-alias]='fg=#86e1fc'                     # Cyan - global aliases
    ZSH_HIGHLIGHT_STYLES[precommand]='fg=#c3e88d,italic'                # Green italic - precommands (sudo, nohup, etc)
    ZSH_HIGHLIGHT_STYLES[commandseparator]='fg=#c099ff'                 # Magenta - command separators (;, &&, ||)
    ZSH_HIGHLIGHT_STYLES[autodirectory]='fg=#86e1fc,underline'          # Cyan underlined - auto cd to directory
    ZSH_HIGHLIGHT_STYLES[path]='fg=#c8d3f5,underline'                   # Foreground underlined - paths
    ZSH_HIGHLIGHT_STYLES[path_pathseparator]='fg=#636da6'               # Comment color - path separators
    ZSH_HIGHLIGHT_STYLES[path_prefix_pathseparator]='fg=#636da6'        # Comment color - path prefix separators
    ZSH_HIGHLIGHT_STYLES[globbing]='fg=#ffc777'                         # Yellow - glob patterns (*, ?, [])
    ZSH_HIGHLIGHT_STYLES[history-expansion]='fg=#82aaff,bold'           # Blue bold - history expansion (!!)
    ZSH_HIGHLIGHT_STYLES[command-substitution]='fg=#c8d3f5'             # Foreground - command substitution
    ZSH_HIGHLIGHT_STYLES[command-substitution-delimiter]='fg=#c099ff'   # Magenta - $() delimiters
    ZSH_HIGHLIGHT_STYLES[process-substitution]='fg=#c8d3f5'             # Foreground - process substitution
    ZSH_HIGHLIGHT_STYLES[process-substitution-delimiter]='fg=#c099ff'   # Magenta - <() >() delimiters
    ZSH_HIGHLIGHT_STYLES[single-hyphen-option]='fg=#ffc777'             # Yellow - single dash options (-h)
    ZSH_HIGHLIGHT_STYLES[double-hyphen-option]='fg=#ffc777'             # Yellow - double dash options (--help)
    ZSH_HIGHLIGHT_STYLES[back-quoted-argument]='fg=#c8d3f5'             # Foreground - backticks
    ZSH_HIGHLIGHT_STYLES[back-quoted-argument-delimiter]='fg=#c099ff'   # Magenta - backtick delimiters
    ZSH_HIGHLIGHT_STYLES[single-quoted-argument]='fg=#c3e88d'           # Green - single quoted strings
    ZSH_HIGHLIGHT_STYLES[double-quoted-argument]='fg=#c3e88d'           # Green - double quoted strings
    ZSH_HIGHLIGHT_STYLES[dollar-quoted-argument]='fg=#c3e88d'           # Green - $'...' quoted strings
    ZSH_HIGHLIGHT_STYLES[rc-quote]='fg=#86e1fc'                         # Cyan - RC quotes
    ZSH_HIGHLIGHT_STYLES[dollar-double-quoted-argument]='fg=#86e1fc'    # Cyan - variables in strings
    ZSH_HIGHLIGHT_STYLES[back-double-quoted-argument]='fg=#86e1fc'      # Cyan - escaped chars in strings
    ZSH_HIGHLIGHT_STYLES[back-dollar-quoted-argument]='fg=#86e1fc'      # Cyan - escaped chars in $'...'
    ZSH_HIGHLIGHT_STYLES[assign]='fg=#c8d3f5'                           # Foreground - assignments (VAR=value)
    ZSH_HIGHLIGHT_STYLES[redirection]='fg=#c099ff,bold'                 # Magenta bold - redirections (>, <, |)
    ZSH_HIGHLIGHT_STYLES[comment]='fg=#636da6,italic'                   # Comment color italic - comments
    ZSH_HIGHLIGHT_STYLES[named-fd]='fg=#c8d3f5'                         # Foreground - named file descriptors
    ZSH_HIGHLIGHT_STYLES[numeric-fd]='fg=#ffc777'                       # Yellow - numeric file descriptors
    ZSH_HIGHLIGHT_STYLES[arg0]='fg=#82aaff,bold'                        # Blue bold - command names

    # Command types - these are the most important for visual feedback
    ZSH_HIGHLIGHT_STYLES[command]='fg=#c3e88d,bold'         # Green bold - valid commands
    ZSH_HIGHLIGHT_STYLES[hashed-command]='fg=#c3e88d,bold'  # Green bold - hashed commands
    ZSH_HIGHLIGHT_STYLES[builtin]='fg=#ffc777,bold'         # Yellow bold - shell builtins
    ZSH_HIGHLIGHT_STYLES[function]='fg=#82aaff,bold'        # Blue bold - functions
    ZSH_HIGHLIGHT_STYLES[alias]='fg=#86e1fc,bold'           # Cyan bold - aliases

    # Default argument style
    ZSH_HIGHLIGHT_STYLES[default]='fg=#c8d3f5'  # Foreground - default text
fi

# -----------------------------------------------------------------------------
# History Substring Search Configuration (Tokyo Night Moon)
# -----------------------------------------------------------------------------
# Configure history search behavior and key bindings with Tokyo Night colors
if type history-substring-search-up >/dev/null 2>&1; then
    # Ensure unique results
    HISTORY_SUBSTRING_SEARCH_ENSURE_UNIQUE=1

    # Highlight colors for search results (Tokyo Night Moon)
    HISTORY_SUBSTRING_SEARCH_HIGHLIGHT_FOUND='bg=#82aaff,fg=#222436,bold'      # Blue background
    HISTORY_SUBSTRING_SEARCH_HIGHLIGHT_NOT_FOUND='bg=#ff757f,fg=#222436,bold'  # Red background

    # Bind arrow keys to history substring search
    # Using terminfo for portability across different terminals
    if [[ -n "${terminfo[kcuu1]}" && -n "${terminfo[kcud1]}" ]]; then
        bindkey "${terminfo[kcuu1]}" history-substring-search-up
        bindkey "${terminfo[kcud1]}" history-substring-search-down
    else
        # Fallback to standard arrow key codes
        bindkey '^[[A' history-substring-search-up
        bindkey '^[[B' history-substring-search-down
    fi

    # Vi mode bindings (if vi mode is enabled)
    bindkey -M vicmd 'k' history-substring-search-up
    bindkey -M vicmd 'j' history-substring-search-down
fi

# =============================================================================
# USAGE NOTES
# =============================================================================
# Useful commands for managing Antigen and plugins:
#
# antigen update         - Update all plugins
# antigen selfupdate     - Update Antigen itself
# antigen list           - List loaded plugins
# antigen purge <repo>   - Remove a specific plugin
# antigen reset          - Clear cache and reload
#
# To add a new plugin:
# 1. Edit this file (~/.zsh/antigen.zsh)
# 2. Add: antigen bundle user/repo
# 3. Run: antigen reset
# 4. Restart your shell
# =============================================================================

# =============================================================================
# END OF ANTIGEN CONFIGURATION
# =============================================================================