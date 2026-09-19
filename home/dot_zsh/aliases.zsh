#!/bin/zsh
# =============================================================================
# Shell Aliases
# =============================================================================
# Grouped as: modern tool replacements, enhanced system commands, process
# management, development shortcuts, and system maintenance.
# Every alias is guarded — only defined when the underlying tool is installed.
# =============================================================================

# =============================================================================
# MODERN TOOL REPLACEMENTS
# =============================================================================

# SSH via Kitty's ssh kitten is provided by the OMZ kitty plugin as `kssh`
# (`kitty +kitten ssh`) — see plugins.zsh — so no alias is defined here.

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
    # Basic listing
    alias ls='eza'

    # Show only directories
    alias lsd='eza --oneline --only-dirs --group-directories-first'

    # Show file tree (. and .. in every node would be noisy — single --all)
    alias lt='eza --all --tree'

    # Show file tree with git status
    alias ltg='eza --tree --level=2 --git-ignore'

    # Long format, no info (does not show . / ..)
    alias ll='eza --all --long --no-permissions --no-filesize --no-user --no-time'

    # Long format, all info (shows hidden files AND . / ..)
    alias la="eza --all --all --long --no-permissions --octal-permissions --group --smart-group --time-style=+'%Y-%m-%d %H:%M'"

    # Sort by modification time (newest first — does not show . / ..)
    alias lr='eza --all --long --no-permissions --no-filesize --no-user --time-style=relative --changed --sort=modified --reverse'

    # Sort by size (largest first — files only, does not show . / ..)
    alias lz='eza --all --long --no-permissions --no-user --no-time --only-files --sort=size --reverse'
else
    # Fallback to standard ls with colors if eza is not available
    if ls --color=auto &>/dev/null; then
        alias ls='ls --color=auto --group-directories-first'
    else
        alias ls='ls -G'
    fi
    alias ll='ls -lah'
    alias la='ls -lah'
    alias lt='ls -lth'
    alias lz='ls -lSh'
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

# Copy: Interactive mode (prompt before overwrite), verbose output
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
# (no `pstree` alias — the real psmisc `pstree` draws a proper tree; `ps auxf`
#  is only a flat forest, so shadowing it lost functionality)

# Show processes sorted by CPU usage
alias pscpu='ps auxf | sort -nr -k 3 | head -10'

# Show processes sorted by memory usage
alias psmem='ps auxf | sort -nr -k 4 | head -10'

# Interactive process viewer — btop replaces top when installed
if command -v btop >/dev/null 2>&1; then
    alias top='btop'
fi

# =============================================================================
# DEVELOPMENT SHORTCUTS
# =============================================================================

# Git shortcuts come from the OMZ git plugin (loaded in plugins.zsh): g, ga, gc
# (`git commit --verbose`), gp, gl, gd, gco, gb, glog, plus `gst` for status and
# ~250 more. No hand-rolled git aliases here — they only duplicated the plugin.

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

# Arch / AUR (paru)
# The OMZ archlinux plugin defines AUR aliases for aura/pacaur/trizen/yay but
# NOT paru, so we define paru's here as a `pu*` set with mnemonic names (paru is
# yay-syntax-compatible). paru drives both the official repos and the AUR, so
# `puupg` is a full system + AUR upgrade. Commented-out entries are kept as
# ready-to-enable extras.
if command -v paru >/dev/null 2>&1; then
    #alias puinsl='paru -U'              # install from a local package file
    #alias puinsd='paru -S --asdeps'     # install as a dependency
    #alias pusu='paru -Syu --noconfirm'  # unattended full upgrade
    alias puclean='paru -Sc'            # remove cached uninstalled packages
    alias puclear='paru -Scc'           # clear all cache (incl. AUR build cache)
    alias puconf='paru -Pg'             # print paru config
    alias puinfo='paru -Si'             # show package info (repo/AUR)
    alias puins='paru -S'               # install repo/AUR package
    alias puinst='paru -Qe'             # list explicitly-installed packages
    alias pulist='paru -Qi'             # show installed-package info
    alias pulook='paru -Ss'             # search repos + AUR
    alias pumir='paru -Syy'             # force-refresh package databases
    alias puorph='paru -Qtd'            # list orphaned packages
    alias pupurge='paru -Rns'           # remove package + deps + config
    alias purm='paru -R'                # remove package
    alias pusearch='paru -Qs'           # search installed packages
    alias puupd='paru -Sy'              # refresh package databases
    alias puupg='paru -Syu'             # full system + AUR upgrade
fi

# -----------------------------------------------------------------------------
# System Information
# -----------------------------------------------------------------------------
# Quick system status commands

# Reload shell configuration — exec replaces the process, so all state
# (env, options, completions) is rebuilt from scratch
alias reload='exec zsh'

alias cls='clear'

# Show PATH in readable format
alias path='echo $PATH | tr ":" "\n"'

# (no `aliases` alias — the OMZ aliases plugin's `als` prints a grouped
#  cheatsheet of aliases, e.g. `als` or `als git`; see plugins.zsh)

# =============================================================================
# END OF ALIASES
# =============================================================================
