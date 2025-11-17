#!/bin/zsh
# =============================================================================
# ZSH Plugin Manager Configuration (Antidote)
# =============================================================================
# This file manages ZSH plugins using Antidote, a modern plugin manager for ZSH
# Antidote generates ultra-fast static loading scripts for optimal performance
#
# Documentation: https://github.com/mattmc3/antidote
#
# Plugin loading order matters:
# 1. Oh-My-ZSH framework plugins
# 2. Utility plugins (completions, tools)
# 3. UI enhancement plugins (autosuggestions, syntax highlighting) - loaded last
#
# Last updated: 2025
# =============================================================================

# =============================================================================
# ANTIDOTE PLUGIN MANAGER SETUP
# =============================================================================

# -----------------------------------------------------------------------------
# Antidote Installation Directory
# -----------------------------------------------------------------------------
# Store Antidote in XDG data directory
ANTIDOTE_DIR="${XDG_DATA_HOME:-${HOME}/.local/share}/antidote"

# -----------------------------------------------------------------------------
# Auto-Install Antidote if Missing
# -----------------------------------------------------------------------------
# Automatically clone Antidote from GitHub if it's not already installed
# This ensures the configuration works on fresh systems without manual setup
if [[ ! -d "$ANTIDOTE_DIR" ]]; then
    echo "Antidote not found. Installing to ${ANTIDOTE_DIR}..."

    # Check if git is available
    if ! command -v git >/dev/null 2>&1; then
        echo "Error: git is required to install Antidote. Please install git first."
        return 1
    fi

    # Clone Antidote repository
    if git clone --quiet --depth=1 https://github.com/mattmc3/antidote.git "$ANTIDOTE_DIR"; then
        echo "Antidote installed successfully!"
    else
        echo "Error: Failed to clone Antidote repository."
        echo "Please check your internet connection and try again."
        return 1
    fi
fi

# -----------------------------------------------------------------------------
# Load Antidote Plugin Manager
# -----------------------------------------------------------------------------
# Source the Antidote script to enable plugin management
if [[ -f "$ANTIDOTE_DIR/antidote.zsh" ]]; then
    source "$ANTIDOTE_DIR/antidote.zsh"
else
    echo "Error: Antidote installation incomplete. Please remove ${ANTIDOTE_DIR} and restart your shell."
    return 1
fi

# =============================================================================
# PLUGIN CONFIGURATION FILE
# =============================================================================

# -----------------------------------------------------------------------------
# Plugin List Location
# -----------------------------------------------------------------------------
# Antidote uses a simple text file to list plugins (one per line)
# This file will be created if it doesn't exist
ANTIDOTE_PLUGINS="${ZDOTDIR:-$HOME}/.zsh/zsh_plugins_list.txt"

# -----------------------------------------------------------------------------
# Create Default Plugin List
# -----------------------------------------------------------------------------
# Generate a default plugin configuration if none exists
if [[ ! -f "$ANTIDOTE_PLUGINS" ]]; then
    echo "Creating default plugin list at ${ANTIDOTE_PLUGINS}..."

    cat > "$ANTIDOTE_PLUGINS" <<'EOF'
# =============================================================================
# Antidote Plugin List
# =============================================================================
# Each line specifies a plugin to load
# Format: user/repo [branch] [options]
#
# Options:
#   kind:zsh        - Load as ZSH plugin
#   kind:path       - Add to PATH only
#   kind:fpath      - Add to fpath only
#   kind:clone      - Clone but don't load
#   kind:defer      - Defer loading (faster startup)
#   path:subdir     - Load from subdirectory
#   conditional:cmd - Only load if command exists
#
# Documentation: https://getantidote.github.io/
# =============================================================================

# -----------------------------------------------------------------------------
# Oh-My-ZSH Library
# -----------------------------------------------------------------------------
# Load Oh-My-ZSH's core library for framework functions
ohmyzsh/ohmyzsh path:lib

# -----------------------------------------------------------------------------
# Oh-My-ZSH Plugins
# -----------------------------------------------------------------------------
# Load specific Oh-My-ZSH plugins
# Aliases plugin: provides 'acs' command to search aliases
ohmyzsh/ohmyzsh path:plugins/aliases

# Uncomment additional Oh-My-ZSH plugins as needed:
ohmyzsh/ohmyzsh path:plugins/git
ohmyzsh/ohmyzsh path:plugins/docker
ohmyzsh/ohmyzsh path:plugins/docker-compose
# ohmyzsh/ohmyzsh path:plugins/kubectl
# ohmyzsh/ohmyzsh path:plugins/npm
# ohmyzsh/ohmyzsh path:plugins/node
ohmyzsh/ohmyzsh path:plugins/python
ohmyzsh/ohmyzsh path:plugins/pip

# -----------------------------------------------------------------------------
# Utility Plugins
# -----------------------------------------------------------------------------
# Alias finder: suggests aliases when you type commands
akash329d/zsh-alias-finder

# -----------------------------------------------------------------------------
# Completion Enhancements
# -----------------------------------------------------------------------------
# Additional completion definitions for hundreds of CLI tools
# IMPORTANT: Must be loaded before syntax-highlighting
zsh-users/zsh-completions path:src kind:fpath

# =============================================================================
# Optional Plugins (Uncomment to Enable)
# =============================================================================

# Zoxide: smarter cd command that learns your habits
# ajeetdsouza/zoxide kind:defer

# FZF tab completion: replace default completion with FZF
# Aloxaf/fzf-tab

# -----------------------------------------------------------------------------
# Interactive Enhancement Plugins
# -----------------------------------------------------------------------------
# CRITICAL: These MUST be loaded last for proper functionality

# Autosuggestions: suggests commands as you type based on history
# Press → to accept, Ctrl+→ to accept one word
zsh-users/zsh-autosuggestions

# Syntax highlighting: real-time command syntax highlighting
# Green = valid command, Red = invalid command
# MUST load after autosuggestions, before history-substring-search
zsh-users/zsh-syntax-highlighting

# History substring search: search history with up/down arrows
# Type partial command and press ↑/↓ to search
# MUST be loaded LAST
zsh-users/zsh-history-substring-search

# =============================================================================
# End of Antidote Plugin List
# =============================================================================
EOF

    echo "Default plugin list created successfully!"
fi

# =============================================================================
# STATIC LOADING FOR PERFORMANCE
# =============================================================================

# -----------------------------------------------------------------------------
# Generate and Load Static Plugin File
# -----------------------------------------------------------------------------
# Antidote generates a static file for ultra-fast loading
# This file is regenerated when .zsh_plugins.txt changes

# Location for the generated static plugin file
ANTIDOTE_STATIC="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/.zsh_plugins.zsh"

# Ensure cache directory exists
[[ -d "${ANTIDOTE_STATIC:h}" ]] || mkdir -p "${ANTIDOTE_STATIC:h}"

# Generate static file if it doesn't exist or plugin list is newer
if [[ ! -f "$ANTIDOTE_STATIC" ]] || [[ "$ANTIDOTE_PLUGINS" -nt "$ANTIDOTE_STATIC" ]]; then
    echo "Generating static plugin file..."
    antidote bundle < "$ANTIDOTE_PLUGINS" > "$ANTIDOTE_STATIC"
fi

# Load the static plugin file (this is very fast)
source "$ANTIDOTE_STATIC"

# =============================================================================
# POST-PLUGIN CONFIGURATION
# =============================================================================

# -----------------------------------------------------------------------------
# Autosuggestions Configuration
# -----------------------------------------------------------------------------
# Customize autosuggestion behavior and appearance
if [[ -n "$ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE" ]] || type _zsh_autosuggest_start >/dev/null 2>&1; then
    # Suggestion color (subtle gray)
    ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=8'
    
    # Suggestion strategy: try history first, then completion
    ZSH_AUTOSUGGEST_STRATEGY=(history completion)
    
    # Buffer size limit for suggestions
    ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=20
    
    # Accept suggestion with Ctrl+Space (in addition to →)
    bindkey '^ ' autosuggest-accept
fi

# -----------------------------------------------------------------------------
# Syntax Highlighting Configuration
# -----------------------------------------------------------------------------
# Customize syntax highlighting colors
if type _zsh_highlight >/dev/null 2>&1; then
    # Customize colors for different command types
    typeset -A ZSH_HIGHLIGHT_STYLES
    ZSH_HIGHLIGHT_STYLES[command]='fg=green,bold'
    ZSH_HIGHLIGHT_STYLES[alias]='fg=cyan,bold'
    ZSH_HIGHLIGHT_STYLES[builtin]='fg=yellow,bold'
    ZSH_HIGHLIGHT_STYLES[function]='fg=blue,bold'
    ZSH_HIGHLIGHT_STYLES[path]='underline'
    ZSH_HIGHLIGHT_STYLES[unknown-token]='fg=red,bold'
fi

# -----------------------------------------------------------------------------
# History Substring Search Configuration
# -----------------------------------------------------------------------------
# Configure history search behavior and key bindings
if type history-substring-search-up >/dev/null 2>&1; then
    # Ensure unique results
    HISTORY_SUBSTRING_SEARCH_ENSURE_UNIQUE=1
    
    # Highlight colors for search results
    HISTORY_SUBSTRING_SEARCH_HIGHLIGHT_FOUND='bg=blue,fg=white,bold'
    HISTORY_SUBSTRING_SEARCH_HIGHLIGHT_NOT_FOUND='bg=red,fg=white,bold'
    
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

# -----------------------------------------------------------------------------
# Completions System Final Setup
# -----------------------------------------------------------------------------
# Rebuild completion cache if zsh-completions was loaded
if [[ -d "${ANTIDOTE_DIR}/https-COLON--SLASH--SLASH-github.com-SLASH-zsh-users-SLASH-zsh-completions" ]]; then
    # Force rebuild of completion cache
    autoload -Uz compinit
    compinit -i
fi

# =============================================================================
# ALIAS-FINDER CONFIGURATION
# =============================================================================
# Configure how alias-finder suggests aliases
if type alias-finder >/dev/null 2>&1; then
    # Show suggestions automatically (optional)
    zstyle ':omz:plugins:alias-finder' autoload yes
    
    # Show longer commands even if alias is longer
    # zstyle ':omz:plugins:alias-finder' longer yes
    
    # Only show exact matches
    # zstyle ':omz:plugins:alias-finder' exact yes
    
    # Don't show aliases for these commands
    # zstyle ':omz:plugins:alias-finder' ignored-commands '(cd|ls|rm|mv)'
fi

# =============================================================================
# MAINTENANCE AND UTILITY FUNCTIONS
# =============================================================================

# -----------------------------------------------------------------------------
# Plugin Management Functions
# -----------------------------------------------------------------------------
# Convenient functions for managing plugins

# Update all plugins and Antidote itself
zsh-update-plugins() {
    echo "Updating Antidote..."
    (cd "$ANTIDOTE_DIR" && git pull --quiet)
    
    echo "Updating plugins..."
    antidote update
    
    echo "Regenerating static plugin files..."
    rm -f "$ANTIDOTE_STATIC"
    antidote bundle < "$ANTIDOTE_PLUGINS" > "$ANTIDOTE_STATIC"
    
    echo "Plugin update complete! Restart your shell to apply changes."
}

# List all loaded plugins
zsh-list-plugins() {
    antidote list
}

# Clean plugin cache and regenerate
zsh-clean-plugins() {
    echo "Cleaning plugin cache..."
    rm -f "$ANTIDOTE_STATIC"
    [[ -f "${_local_static:-}" ]] && rm -f "$_local_static"
    
    echo "Regenerating static plugin files..."
    antidote bundle < "$ANTIDOTE_PLUGINS" > "$ANTIDOTE_STATIC"
    
    echo "Cache cleaned! Restart your shell to reload plugins."
}

# Edit plugin configuration
zsh-edit-plugins() {
    ${EDITOR:-vim} "$ANTIDOTE_PLUGINS"
    echo "Regenerating static plugin file..."
    antidote bundle < "$ANTIDOTE_PLUGINS" > "$ANTIDOTE_STATIC"
    echo "Plugin list updated! Restart your shell to apply changes."
}

# =============================================================================
# USAGE NOTES
# =============================================================================
# Useful commands for managing Antidote and plugins:
#
# zsh-update-plugins     - Update all plugins and Antidote
# zsh-list-plugins       - Show all loaded plugins
# zsh-clean-plugins      - Clean cache and regenerate
# zsh-edit-plugins       - Edit plugin list and regenerate
#
# antidote update        - Update all plugins
# antidote list          - List loaded plugins
# antidote purge <repo>  - Remove a specific plugin
# antidote home          - Show Antidote installation directory
#
# To add a new plugin:
# 1. Edit ~/.zsh_plugins.txt
# 2. Add the plugin (e.g., user/repo)
# 3. Restart your shell or run: source ~/.zshrc
# =============================================================================

# =============================================================================
# END OF ANTIDOTE CONFIGURATION
# =============================================================================
