#!/bin/zsh
# =============================================================================
# ZSH Plugin Manager Configuration (Zinit)
# =============================================================================
# This file manages ZSH plugins using Zinit, a flexible and fast plugin manager.
# Documentation: https://github.com/zdharma-continuum/zinit
#
# Plugin loading order matters — see comments in the PLUGIN CONFIGURATION
# section for the exact constraints.
#
# Last updated: 2026
# =============================================================================

# =============================================================================
# ZINIT PLUGIN MANAGER SETUP
# =============================================================================

# Store Zinit in XDG data directory to keep $HOME clean
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"

# Auto-install Zinit if missing
if [[ ! -d "${ZINIT_HOME}/.git" ]]; then
    echo "Zinit not found. Installing to ${ZINIT_HOME}..."
    mkdir -p "$(dirname "${ZINIT_HOME}")"

    if ! command -v git >/dev/null 2>&1; then
        echo "Error: git is required to install Zinit. Please install git first."
        return 1
    fi

    if git clone --depth=1 https://github.com/zdharma-continuum/zinit.git "${ZINIT_HOME}"; then
        echo "Zinit installed successfully!"
    else
        echo "Error: Failed to clone Zinit repository."
        echo "Please check your internet connection and try again."
        return 1
    fi
fi

# Load Zinit — this also registers zinit completions automatically
source "${ZINIT_HOME}/zinit.zsh"

# =============================================================================
# PLUGIN CONFIGURATION
# =============================================================================

# -----------------------------------------------------------------------------
# Oh-My-ZSH Snippet Plugins
# -----------------------------------------------------------------------------
# `zinit snippet OMZP::name` downloads and sources only that plugin file —
# the full OMZ framework is never loaded. Snippets are cached locally after
# the first download so subsequent shell starts are fast.

zinit snippet OMZP::1password               # 1Password CLI completion and shortcuts
zinit snippet OMZP::aliases                 # 'acs' command to search defined aliases
[[ -f /etc/arch-release ]] && \
    zinit snippet OMZP::archlinux           # Arch-specific aliases (pacman, yay, etc.)
zinit snippet OMZP::chezmoi                 # Chezmoi shortcuts and completions
zinit snippet OMZP::git                     # Git aliases and shortcuts (g, gst, gco, …)
zinit snippet OMZP::kitty                   # Kitty terminal shortcuts and icat helper
zinit snippet OMZP::sudo                    # ESC+ESC prepends 'sudo' to current command
zinit snippet OMZP::extract                 # 'x' command extracts any archive format
zinit snippet OMZP::ansible                 # Ansible completion and shortcuts
zinit snippet OMZP::docker                  # Docker completion and aliases
zinit snippet OMZP::docker-compose          # Docker Compose completion

# -----------------------------------------------------------------------------
# Interactive Enhancement Plugins
# -----------------------------------------------------------------------------
# Loading order is critical — do not reorder these five plugins.
#
# 1. zsh-completions       additional completion definitions; must precede
#                          syntax-highlighting to ensure completions are
#                          registered before the highlighter inspects them
#
# 2. zsh-autosuggestions   history-based ghost text; must come before fzf-tab
#                          because fzf-tab hooks into the same completion
#                          widget and will break autosuggestions if loaded first
#
# 3. fzf-tab               replaces the default completion menu with an fzf
#                          picker; MUST load after zsh-autosuggestions
#
# 4. zsh-syntax-highlighting  real-time command highlighting; must load after
#                          autosuggestions (its widgets wrap the line editor)
#
# 5. zsh-history-substring-search  binds ↑/↓ for history search; MUST be
#                          loaded last or its key bindings get overwritten

# Additional completions for hundreds of CLI tools
zinit light zsh-users/zsh-completions

# Autosuggestions: suggests commands as you type based on history
# Press → to accept, Ctrl+→ to accept one word
zinit light zsh-users/zsh-autosuggestions

# Fuzzy tab completion — MUST load after zsh-autosuggestions
zinit light Aloxaf/fzf-tab

# Syntax highlighting: colours commands as you type
# Valid command → green, invalid → red
zinit light zsh-users/zsh-syntax-highlighting

# History substring search: ↑/↓ search history by typed prefix
# MUST be loaded last
zinit light zsh-users/zsh-history-substring-search

# =============================================================================
# POST-PLUGIN CONFIGURATION
# =============================================================================

# Tell fzf-tab to use fzf explicitly; prevents widget conflicts when other
# tools (e.g. a system fzf wrapper) shadow the fzf binary name
zstyle ':fzf-tab:*' fzf-command fzf

# fzf-tab: pass FZF_DEFAULT_OPTS through so Tokyo Night Moon colors apply
zstyle ':fzf-tab:*' use-fzf-default-opts yes

# -----------------------------------------------------------------------------
# Autosuggestions Configuration
# -----------------------------------------------------------------------------
if type _zsh_autosuggest_start >/dev/null 2>&1; then
    # Suggestion colour — Tokyo Night Moon comment colour (subtle, unobtrusive)
    ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=#636da6'

    # Strategy: prefer history matches; fall back to completion if none found
    ZSH_AUTOSUGGEST_STRATEGY=(history completion)

    # Ignore suggestions for very long commands (avoids lag on slow machines)
    ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=20

    # Accept the full suggestion with Ctrl+Space (→ still works too)
    bindkey '^ ' autosuggest-accept
fi

# -----------------------------------------------------------------------------
# Syntax Highlighting Configuration (Tokyo Night Moon)
# -----------------------------------------------------------------------------
# Colour palette: https://github.com/folke/tokyonight.nvim/blob/main/extras/lua/tokyonight_moon.lua
#
# bg #222436 | fg #c8d3f5 | blue #82aaff | cyan #86e1fc | green #c3e88d
# yellow #ffc777 | orange #ff966c | red #ff757f | magenta #c099ff | comment #636da6

if type _zsh_highlight >/dev/null 2>&1; then
    typeset -A ZSH_HIGHLIGHT_STYLES

    # --- Token types ---
    ZSH_HIGHLIGHT_STYLES[unknown-token]='fg=#ff757f,bold'               # red   — invalid/unknown
    ZSH_HIGHLIGHT_STYLES[reserved-word]='fg=#c099ff,bold'               # magenta — if/then/else/…
    ZSH_HIGHLIGHT_STYLES[suffix-alias]='fg=#86e1fc,underline'           # cyan  — suffix aliases
    ZSH_HIGHLIGHT_STYLES[global-alias]='fg=#86e1fc'                     # cyan  — global aliases
    ZSH_HIGHLIGHT_STYLES[precommand]='fg=#c3e88d,italic'                # green — sudo, nohup, …
    ZSH_HIGHLIGHT_STYLES[commandseparator]='fg=#c099ff'                 # magenta — ; && ||
    ZSH_HIGHLIGHT_STYLES[autodirectory]='fg=#86e1fc,underline'          # cyan  — auto-cd directories
    ZSH_HIGHLIGHT_STYLES[path]='fg=#c8d3f5,underline'                   # fg    — file paths
    ZSH_HIGHLIGHT_STYLES[path_pathseparator]='fg=#636da6'               # comment — /
    ZSH_HIGHLIGHT_STYLES[path_prefix_pathseparator]='fg=#636da6'        # comment — / (prefix)
    ZSH_HIGHLIGHT_STYLES[globbing]='fg=#ffc777'                         # yellow — * ? []
    ZSH_HIGHLIGHT_STYLES[history-expansion]='fg=#82aaff,bold'           # blue  — !!
    ZSH_HIGHLIGHT_STYLES[command-substitution]='fg=#c8d3f5'             # fg    — $(…)
    ZSH_HIGHLIGHT_STYLES[command-substitution-delimiter]='fg=#c099ff'   # magenta — $( )
    ZSH_HIGHLIGHT_STYLES[process-substitution]='fg=#c8d3f5'             # fg    — <(…) >(…)
    ZSH_HIGHLIGHT_STYLES[process-substitution-delimiter]='fg=#c099ff'   # magenta — <( )
    ZSH_HIGHLIGHT_STYLES[single-hyphen-option]='fg=#ffc777'             # yellow — -h
    ZSH_HIGHLIGHT_STYLES[double-hyphen-option]='fg=#ffc777'             # yellow — --help
    ZSH_HIGHLIGHT_STYLES[back-quoted-argument]='fg=#c8d3f5'             # fg    — `…`
    ZSH_HIGHLIGHT_STYLES[back-quoted-argument-delimiter]='fg=#c099ff'   # magenta — ` `
    ZSH_HIGHLIGHT_STYLES[single-quoted-argument]='fg=#c3e88d'           # green — '…'
    ZSH_HIGHLIGHT_STYLES[double-quoted-argument]='fg=#c3e88d'           # green — "…"
    ZSH_HIGHLIGHT_STYLES[dollar-quoted-argument]='fg=#c3e88d'           # green — $'…'
    ZSH_HIGHLIGHT_STYLES[rc-quote]='fg=#86e1fc'                         # cyan  — rc quotes
    ZSH_HIGHLIGHT_STYLES[dollar-double-quoted-argument]='fg=#86e1fc'    # cyan  — $var inside "…"
    ZSH_HIGHLIGHT_STYLES[back-double-quoted-argument]='fg=#86e1fc'      # cyan  — escaped chars in "…"
    ZSH_HIGHLIGHT_STYLES[back-dollar-quoted-argument]='fg=#86e1fc'      # cyan  — escaped in $'…'
    ZSH_HIGHLIGHT_STYLES[assign]='fg=#c8d3f5'                           # fg    — VAR=value
    ZSH_HIGHLIGHT_STYLES[redirection]='fg=#c099ff,bold'                 # magenta — > < |
    ZSH_HIGHLIGHT_STYLES[comment]='fg=#636da6,italic'                   # comment — # …
    ZSH_HIGHLIGHT_STYLES[named-fd]='fg=#c8d3f5'                         # fg    — named file descriptors
    ZSH_HIGHLIGHT_STYLES[numeric-fd]='fg=#ffc777'                       # yellow — numeric fds
    ZSH_HIGHLIGHT_STYLES[arg0]='fg=#82aaff,bold'                        # blue  — command name token

    # --- Command types (most visible) ---
    ZSH_HIGHLIGHT_STYLES[command]='fg=#c3e88d,bold'         # green  — valid external commands
    ZSH_HIGHLIGHT_STYLES[hashed-command]='fg=#c3e88d,bold'  # green  — hashed commands
    ZSH_HIGHLIGHT_STYLES[builtin]='fg=#ffc777,bold'         # yellow — shell builtins (cd, echo, …)
    ZSH_HIGHLIGHT_STYLES[function]='fg=#82aaff,bold'        # blue   — shell functions
    ZSH_HIGHLIGHT_STYLES[alias]='fg=#86e1fc,bold'           # cyan   — aliases
    ZSH_HIGHLIGHT_STYLES[default]='fg=#c8d3f5'              # fg     — everything else
fi

# -----------------------------------------------------------------------------
# History Substring Search Configuration (Tokyo Night Moon)
# -----------------------------------------------------------------------------
if type history-substring-search-up >/dev/null 2>&1; then
    # Only show unique results when cycling through matches
    HISTORY_SUBSTRING_SEARCH_ENSURE_UNIQUE=1

    # Highlight colours for found / not-found results
    HISTORY_SUBSTRING_SEARCH_HIGHLIGHT_FOUND='bg=#82aaff,fg=#222436,bold'      # blue background
    HISTORY_SUBSTRING_SEARCH_HIGHLIGHT_NOT_FOUND='bg=#ff757f,fg=#222436,bold'  # red background

    # Bind ↑/↓ using terminfo entries for portability across terminals
    if [[ -n "${terminfo[kcuu1]}" && -n "${terminfo[kcud1]}" ]]; then
        bindkey "${terminfo[kcuu1]}" history-substring-search-up
        bindkey "${terminfo[kcud1]}" history-substring-search-down
    else
        # Fallback for terminals that don't export terminfo
        bindkey '^[[A' history-substring-search-up
        bindkey '^[[B' history-substring-search-down
    fi

    # Vi mode bindings
    bindkey -M vicmd 'k' history-substring-search-up
    bindkey -M vicmd 'j' history-substring-search-down
fi

# =============================================================================
# USAGE NOTES
# =============================================================================
#
# zinit update --all        Update all plugins and Zinit itself
# zinit self-update         Update only Zinit
# zinit list                List loaded plugins and snippets
# zinit delete <plugin>     Remove a plugin and its files
# zinit times               Show load times for each plugin (profiling)
#
# To add a new plugin:
# 1. Edit this file (~/.zsh/plugins.zsh)
# 2. Add: zinit snippet OMZP::name   (for OMZ plugins)
#    or:  zinit light user/repo      (for GitHub plugins)
# 3. Restart your shell or run: exec zsh
#
# =============================================================================
