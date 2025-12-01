#!/bin/zsh
# =============================================================================
# Shell Aliases Configuration
# =============================================================================
# This file contains shell aliases for improved command-line experience
# Aliases are only created if the required tools are installed
#
# Organization:
# - Modern replacements for classic Unix tools
# - Enhanced output and formatting
# - Safety improvements for destructive commands
# - Utility shortcuts
#
# Last updated: 2025
# =============================================================================

# =============================================================================
# MODERN TOOL REPLACEMENTS
# =============================================================================

# -----------------------------------------------------------------------------
# SSH: Kitty Terminal Integration
# -----------------------------------------------------------------------------
# Kitten SSH: Enhanced SSH with terminal integration features
# Provides automatic terminfo setup and improved performance in Kitty terminal
# Documentation: https://sw.kovidgoyal.net/kitty/kittens/ssh/
if command -v kitty >/dev/null 2>&1; then
    alias ksh='kitten ssh'
fi

# -----------------------------------------------------------------------------
# Text Editor: Neovim
# -----------------------------------------------------------------------------
# Neovim: Hyperextensible Vim-based text editor
# Drop-in replacement for vim with better performance and extensibility
# Documentation: https://neovim.io
if command -v nvim >/dev/null 2>&1; then
    alias nv='nvim'
    alias vimdiff='nvim -d'
fi

# -----------------------------------------------------------------------------
# File Listing: eza (modern ls replacement)
# -----------------------------------------------------------------------------
# eza: Modern replacement for ls with colors, git integration, and icons
# Features: colors by default, git status, tree view, extended attributes
# Documentation: https://github.com/eza-community/eza
if command -v eza >/dev/null 2>&1; then
    # Basic ls replacement
    alias ls='eza --group-directories-first'

    # Show only directories
    alias lsd='eza --oneline --only-dirs'

    # Show fiule tree
    alias lt='eza --all --tree'

    # Show file tree with git status
    alias ltg='eza --tree --level=2 --git-ignore'

    # Long format, no info
    alias ll='eza --all --long --no-permissions --no-filesize --no-user --no-time'

    # Long format, all info
    alias la="eza --all --long --no-permissions --octal-permissions --group --smart-group --time-style=+'%Y-%m-%d %H:%M'"

    # Sort by modification time (newest first)
    alias lr='eza --all --long --no-permissions --no-filesize --no-user --time-style=relative --changed --sort=modified --reverse'

    # Sort by size (largest first)
    alias lz='eza --all --long --no-permissions --no-user --no-time --only-files  --sort=size --reverse'
else
    # Fallback to standard ls with colors if eza is not available
    if ls --color=auto &>/dev/null; then
        # GNU ls (Linux)
        alias ls='ls --color=auto --group-directories-first'
        alias ll='ls -lh'
        alias la='ls -lAh'
        alias lt='ls -lth'
        alias lz='ls -lSh'
    else
        # BSD ls (macOS)
        alias ls='ls -G'
        alias ll='ls -lh'
        alias la='ls -lAh'
        alias lt='ls -lth'
        alias lz='ls -lSh'
    fi
fi

# -----------------------------------------------------------------------------
# File Viewing: bat (modern cat replacement)
# -----------------------------------------------------------------------------
# bat: Cat clone with syntax highlighting and git integration
# Features: syntax highlighting, line numbers, git diff markers, paging
# Documentation: https://github.com/sharkdp/bat

# Handle different package names (batcat on Debian/Ubuntu, bat elsewhere)
if command -v batcat >/dev/null 2>&1; then
    alias bat='batcat'
fi

if command -v bat >/dev/null 2>&1; then
    # Plain cat replacement (no line numbers, no decorations)
    alias cat='bat --style=plain --paging=never'

    # Full bat with line numbers and decorations
    alias catt='bat --style=full'

    # Colorize system information commands
    # lsblk: Block device information with syntax highlighting
    alias lsblk='lsblk | bat --language=conf --style=plain --paging=never'

    # free: Memory usage with syntax highlighting
    alias free='free -h | bat --language=cpuinfo --style=plain --paging=never'

    # sensors: Hardware sensor information (requires lm-sensors)
    if command -v sensors >/dev/null 2>&1; then
        alias sensors='sensors | bat --language=cpuinfo --style=plain --paging=never'
    fi
fi

# =============================================================================
# ENHANCED SYSTEM COMMANDS
# =============================================================================

# -----------------------------------------------------------------------------
# Search: grep with Colors
# -----------------------------------------------------------------------------
# Enable colored output for grep and related commands
# Makes search results easier to read by highlighting matches
alias grep='grep --color=auto'
alias egrep='egrep --color=auto'
alias fgrep='fgrep --color=auto'

# -----------------------------------------------------------------------------
# File Operations: Safety and Verbosity
# -----------------------------------------------------------------------------
# Add safety checks and human-readable output to destructive commands

# Move: Interactive mode (prompt before overwrite), verbose output
alias mv='mv -iv'

# Remove: Interactive for 3+ files, verbose output
# -I: Prompt once before removing more than 3 files or recursively
# -v: Verbose (show what's being removed)
alias rm='rm -Iv'

# Copy: Interactive mode, preserve attributes, verbose
alias cp='cp -iv'

# Create parent directories as needed
alias mkdir='mkdir -pv'

# -----------------------------------------------------------------------------
# Disk Usage: Human-Readable Formats
# -----------------------------------------------------------------------------
# Display sizes in human-readable format (KB, MB, GB)

# df: Disk space usage of filesystems
alias df='df -h'

# du: Disk usage of directories (1 level deep)
alias du='du -h -d 1'

# Show disk usage sorted by size (largest first)
alias duh='du -h -d 1 | sort -hr'

# =============================================================================
# PROCESS MANAGEMENT
# =============================================================================

# -----------------------------------------------------------------------------
# Process Viewing: Enhanced ps and top
# -----------------------------------------------------------------------------
# Human-friendly process listings

# Show all processes in tree format
alias pstree='ps auxf'

# Show processes sorted by CPU usage
alias pscpu='ps auxf | sort -nr -k 3 | head -10'

# Show processes sorted by memory usage
alias psmem='ps auxf | sort -nr -k 4 | head -10'

# Interactive process viewer (use htop if available)
if command -v btop >/dev/null 2>&1; then
    alias top='btop'
fi

# =============================================================================
# DEVELOPMENT SHORTCUTS
# =============================================================================

# -----------------------------------------------------------------------------
# Git Shortcuts
# -----------------------------------------------------------------------------
# Common git operations (only create if git is installed)
if command -v git >/dev/null 2>&1; then
    alias g='git'
    alias gs='git status'
    alias ga='git add'
    alias gc='git commit'
    alias gp='git push'
    alias gl='git pull'
    alias gd='git diff'
    alias gco='git checkout'
    alias gb='git branch'
    alias glog='git log --oneline --decorate --graph'
fi

# -----------------------------------------------------------------------------
# Python Environment
# -----------------------------------------------------------------------------
# Virtual environment and Python utilities
if command -v python3 >/dev/null 2>&1; then
    alias py='python3'
    alias pip='python3 -m pip'
    alias venv='python3 -m venv'
    alias activate='source ./venv/bin/activate 2>/dev/null || source ./env/bin/activate'
fi

# =============================================================================
# SYSTEM MAINTENANCE
# =============================================================================

# -----------------------------------------------------------------------------
# Package Management Updates
# -----------------------------------------------------------------------------
# Quick update commands for different package managers

# Homebrew (macOS/Linux)
if command -v brew >/dev/null 2>&1; then
    alias brewup='brew update && brew upgrade && brew cleanup'
fi

# APT (Debian/Ubuntu)
if command -v apt >/dev/null 2>&1; then
    alias aptup='sudo apt update && sudo apt upgrade -y && sudo apt autoremove -y'
fi

# DNF (Fedora/RHEL)
if command -v dnf >/dev/null 2>&1; then
    alias dnfup='sudo dnf upgrade -y && sudo dnf autoremove -y'
fi

# -----------------------------------------------------------------------------
# System Information
# -----------------------------------------------------------------------------
# Quick system status commands

# Reload shell configuration
alias reload='source ~/.zshrc'

# Clear screen properly
alias cls='clear'
alias c='clear'

# Show PATH in readable format
alias path='echo $PATH | tr ":" "\n"'

# Show all aliases
alias aliases='alias | bat -l bash -p 2>/dev/null || alias'

# =============================================================================
# END OF ALIASES
# =============================================================================
