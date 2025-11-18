#!/usr/bin/env bash
# =============================================================================
# BDB Bootstrap - Bassa's Dotfiles Bootstrapper
# =============================================================================
# Automated setup script for installing chezmoi and syncing dotfiles
# across different machines and operating systems
#
# Supported Systems:
# - macOS (Intel and Apple Silicon)
# - Linux: Arch, Manjaro, Debian, Ubuntu, Fedora, RHEL
#
# Features:
# - Auto-detection of OS and distribution
# - Installation of required dependencies
# - Chezmoi installation and configuration
# - Automatic dotfile synchronization
# - Comprehensive logging
#
# Usage:
#   bash <(curl -fsSL https://raw.githubusercontent.com/norville/dotfiles/main/path/to/bdb_bootstrap.sh)
#   or
#   ./bdb_bootstrap.sh
#
# Repository: https://github.com/norville/dotfiles
# Last updated: 2025
# =============================================================================

# =============================================================================
# GLOBAL CONFIGURATION
# =============================================================================

# GitHub repository configuration
readonly GITHUB_USER="norville"                     # GitHub username
readonly GITHUB_REPO="dotfiles"                     # Repository name
readonly CHEZMOI_BRANCH="main"                      # Branch to use for initialization

# Script paths and URLs
readonly BDB_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly BDB_HELPERS="${BDB_SCRIPT_DIR}/bdb_helpers.sh"
readonly BDB_HELPERS_URL="https://raw.githubusercontent.com/${GITHUB_USER}/${GITHUB_REPO}/main/dot_config/bdb/bdb_helpers.sh"

# Logging configuration
readonly BDB_LOG_FILE="${BDB_SCRIPT_DIR}/bdb_log_$(date +%Y%m%d_%H%M%S).txt"

# System detection paths
readonly LSB_RELEASE_PATH="/etc/os-release"         # Standard Linux OS info

# =============================================================================
# HELPER FUNCTION LOADING
# =============================================================================

# -----------------------------------------------------------------------------
# Download and Source Helper Functions
# -----------------------------------------------------------------------------
# Download helper functions from GitHub if not available locally
# Supports both curl and wget for portability
load_helpers() {
    local helpers_exist=false
    
    # Check if helpers exist locally
    if [[ -f "${BDB_HELPERS}" ]]; then
        helpers_exist=true
        echo "[INFO] Using local helper functions from ${BDB_HELPERS}"
    else
        echo "[INFO] Downloading helper functions from ${BDB_HELPERS_URL}"
        
        # Try to download helpers
        if command -v curl >/dev/null 2>&1; then
            if curl -fsSL "${BDB_HELPERS_URL}" -o "${BDB_HELPERS}"; then
                helpers_exist=true
            fi
        elif command -v wget >/dev/null 2>&1; then
            if wget -qO "${BDB_HELPERS}" "${BDB_HELPERS_URL}"; then
                helpers_exist=true
            fi
        else
            echo "[ERROR] Neither curl nor wget is available. Cannot download helpers." >&2
            exit 1
        fi
    fi
    
    # Verify download success
    if [[ "$helpers_exist" != true ]] || [[ ! -f "${BDB_HELPERS}" ]]; then
        echo "[ERROR] Failed to obtain helper functions from ${BDB_HELPERS_URL}" >&2
        exit 1
    fi
    
    # Source the helper functions
    # shellcheck disable=SC1090,SC1091
    source "${BDB_HELPERS}"
}

# Load helpers first thing
load_helpers

# =============================================================================
# SYSTEM DETECTION FUNCTIONS
# =============================================================================

# -----------------------------------------------------------------------------
# Detect Operating System
# -----------------------------------------------------------------------------
# Identify OS type (Darwin/Linux) and distribution
# Sets: PLATFORM, DISTRO
# Returns: 0 on success, 1 on failure
detect_os() {
    local platform distro
    
    bdb_run "Detecting operating system"
    
    platform="$(uname -s)"
    
    case "${platform}" in
        Darwin)
            distro="macos"
            ;;
        Linux)
            if [[ -f "${LSB_RELEASE_PATH}" ]]; then
                # Extract ID field from os-release, normalize to lowercase
                distro="$(grep -E '^ID=' "${LSB_RELEASE_PATH}" | cut -d'=' -f2 | tr -d '"' | tr '[:upper:]' '[:lower:]')"
                
                # Handle ID_LIKE for derivatives (e.g., Pop!_OS -> ubuntu)
                if [[ -z "${distro}" ]]; then
                    distro="$(grep -E '^ID_LIKE=' "${LSB_RELEASE_PATH}" | cut -d'=' -f2 | tr -d '"' | awk '{print $1}' | tr '[:upper:]' '[:lower:]')"
                fi
            else
                distro="unknown"
            fi
            ;;
        *)
            bdb_error "Unsupported operating system: ${platform}"
            return 1
            ;;
    esac
    
    bdb_outcome "${platform}/${distro}"
    
    export PLATFORM="${platform}"
    export DISTRO="${distro}"
    return 0
}

# =============================================================================
# SYSTEM UPDATE FUNCTIONS
# =============================================================================

# -----------------------------------------------------------------------------
# Update Arch/Manjaro System
# -----------------------------------------------------------------------------
update_arch() {
    bdb_command "Updating Arch/Manjaro system"
    
    sudo pacman -Syu --noconfirm
    
    # Remove orphaned packages if any exist
    local orphans
    orphans="$(pacman -Qdtq 2>/dev/null || true)"
    if [[ -n "${orphans}" ]]; then
        echo "${orphans}" | sudo pacman -Rns --noconfirm -
    fi
    
    # Clean package cache
    sudo pacman -Scc --noconfirm
}

# -----------------------------------------------------------------------------
# Update Debian/Ubuntu System
# -----------------------------------------------------------------------------
update_debian() {
    bdb_command "Updating Debian/Ubuntu system"
    
    sudo apt-get update
    sudo apt-get full-upgrade -y
    sudo apt-get autoremove --purge -y
    sudo apt-get clean
}

# -----------------------------------------------------------------------------
# Update Fedora/RHEL System
# -----------------------------------------------------------------------------
update_fedora() {
    bdb_command "Updating Fedora/RHEL system"
    
    sudo dnf upgrade -y
    sudo dnf autoremove -y
    sudo dnf clean all
}

# -----------------------------------------------------------------------------
# Setup macOS Development Environment
# -----------------------------------------------------------------------------
# Install Xcode Command Line Tools and Homebrew
setup_macos() {
    # Check and install Xcode Command Line Tools
    bdb_run "Checking Xcode Command Line Tools"
    
    if xcode-select -p &>/dev/null; then
        bdb_outcome "already installed"
    else
        bdb_outcome "not installed"
        bdb_command "Installing Xcode Command Line Tools"
        
        # Trigger installation prompt
        xcode-select --install &>/dev/null || true
        
        # Wait for installation to complete
        until xcode-select -p &>/dev/null; do
            sleep 5
        done
        
        bdb_success "Xcode Command Line Tools installed"
    fi
    
    # Check and install Homebrew
    bdb_run "Checking Homebrew"
    
    if command -v brew >/dev/null 2>&1; then
        bdb_outcome "already installed"
        bdb_command "Updating Homebrew"
        brew update && brew upgrade
        bdb_success "Homebrew updated"
    else
        bdb_outcome "not installed"
        bdb_command "Installing Homebrew"
        
        # Non-interactive installation
        NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        
        # Add Homebrew to PATH for current session
        if [[ -x "/opt/homebrew/bin/brew" ]]; then
            eval "$(/opt/homebrew/bin/brew shellenv)"
        elif [[ -x "/usr/local/bin/brew" ]]; then
            eval "$(/usr/local/bin/brew shellenv)"
        fi
        
        bdb_success "Homebrew installed"
    fi
}

# -----------------------------------------------------------------------------
# Update System
# -----------------------------------------------------------------------------
# Update the system based on detected distribution
update_system() {
    if ! bdb_ask "Update the system now"; then
        bdb_alert "Skipping system update"
        return 0
    fi
    
    case "${DISTRO}" in
        arch|manjaro)
            update_arch
            ;;
        debian|ubuntu|pop)
            update_debian
            ;;
        fedora|rhel|centos)
            update_fedora
            ;;
        macos)
            setup_macos
            ;;
        *)
            bdb_error "Unsupported distribution for system update: ${DISTRO}"
            return 1
            ;;
    esac
    
    bdb_success "System updated successfully"
}

# =============================================================================
# DEPENDENCY INSTALLATION FUNCTIONS
# =============================================================================

# -----------------------------------------------------------------------------
# Install Dependencies on Arch/Manjaro
# -----------------------------------------------------------------------------
install_deps_arch() {
    bdb_command "Installing dependencies (Arch/Manjaro)"
    sudo pacman -S --needed --noconfirm git chezmoi
}

# -----------------------------------------------------------------------------
# Install Dependencies on Debian
# -----------------------------------------------------------------------------
install_deps_debian() {
    bdb_command "Installing dependencies (Debian)"
    sudo apt-get install -y curl git
    
    # Install chezmoi if not already present
    if ! command -v chezmoi >/dev/null 2>&1; then
        bdb_run "Installing chezmoi"
        sudo sh -c "$(curl -fsLS https://get.chezmoi.io)" -- -b /usr/local/bin
        bdb_outcome "chezmoi installed"
    fi
}

# -----------------------------------------------------------------------------
# Install Dependencies on Ubuntu
# -----------------------------------------------------------------------------
install_deps_ubuntu() {
    bdb_command "Installing dependencies (Ubuntu)"
    sudo apt-get install -y git snapd
    
    # Install chezmoi via snap if not already present
    if ! command -v chezmoi >/dev/null 2>&1; then
        bdb_run "Installing chezmoi via snap"
        sudo snap install chezmoi --classic
        bdb_outcome "chezmoi installed"
    fi
}

# -----------------------------------------------------------------------------
# Install Dependencies on Fedora/RHEL
# -----------------------------------------------------------------------------
install_deps_fedora() {
    bdb_command "Installing dependencies (Fedora/RHEL)"
    sudo dnf install -y git
    
    # Install chezmoi if not already present
    if ! command -v chezmoi >/dev/null 2>&1; then
        bdb_run "Installing chezmoi"
        sudo sh -c "$(curl -fsLS https://get.chezmoi.io)" -- -b /usr/local/bin
        bdb_outcome "chezmoi installed"
    fi
}

# -----------------------------------------------------------------------------
# Install Dependencies on macOS
# -----------------------------------------------------------------------------
install_deps_macos() {
    bdb_command "Installing dependencies (macOS)"
    brew install chezmoi
}

# -----------------------------------------------------------------------------
# Install Required Dependencies
# -----------------------------------------------------------------------------
# Install git and chezmoi based on detected distribution
install_dependencies() {
    bdb_info "Installing chezmoi and dependencies"
    
    case "${DISTRO}" in
        arch|manjaro)
            install_deps_arch
            ;;
        debian)
            install_deps_debian
            ;;
        ubuntu|pop)
            install_deps_ubuntu
            ;;
        fedora|rhel|centos)
            install_deps_fedora
            ;;
        macos)
            install_deps_macos
            ;;
        *)
            bdb_error "Unsupported distribution for dependency installation: ${DISTRO}"
            return 1
            ;;
    esac
    
    # Verify chezmoi installation
    if ! command -v chezmoi >/dev/null 2>&1; then
        bdb_error "Chezmoi installation failed"
        return 1
    fi
    
    bdb_success "Dependencies installed successfully"
}

# =============================================================================
# DOTFILES INITIALIZATION
# =============================================================================

# -----------------------------------------------------------------------------
# Initialize and Apply Dotfiles
# -----------------------------------------------------------------------------
# Clone dotfiles repository and apply configuration using chezmoi
init_dotfiles() {
    bdb_info "Ready to clone dotfiles and apply configuration"
    
    if ! bdb_ask "Clone dotfiles from ${GITHUB_USER}/${GITHUB_REPO} and apply now"; then
        bdb_alert "Dotfile initialization skipped"
        bdb_info "Run this command when ready:"
        bdb_info "  chezmoi init --branch ${CHEZMOI_BRANCH} --apply ${GITHUB_USER}"
        return 0
    fi
    
    bdb_command "Initializing chezmoi with dotfiles"
    
    # Initialize and apply in one command
    if chezmoi init --branch "${CHEZMOI_BRANCH}" --apply "${GITHUB_USER}"; then
        bdb_success "Dotfiles cloned and applied successfully"
    else
        bdb_error "Failed to initialize dotfiles"
        bdb_info "You can try manually with:"
        bdb_info "  chezmoi init --branch ${CHEZMOI_BRANCH} ${GITHUB_USER}"
        bdb_info "  chezmoi apply"
        return 1
    fi
}

# =============================================================================
# MAIN BOOTSTRAP FUNCTION
# =============================================================================

# -----------------------------------------------------------------------------
# Bootstrap Main Function
# -----------------------------------------------------------------------------
# Orchestrate the complete bootstrap process
bdb_bootstrap() {
    # Welcome message
    bdb_info_in "Welcome to Bassa's Dotfiles Bootstrapper (BDB)"
    bdb_info "This script will set up your system with dotfiles from GitHub"
    bdb_info "Repository: https://github.com/${GITHUB_USER}/${GITHUB_REPO}"
    
    # Get admin privileges early
    bdb_run "Requesting administrator privileges"
    if command -v sudo >/dev/null 2>&1; then
        sudo -v
        bdb_outcome "sudo access granted"
        
        # Keep sudo alive in background
        while true; do
            sudo -n true
            sleep 60
            kill -0 "$$" 2>/dev/null || exit
        done 2>/dev/null &
    else
        bdb_alert "sudo not available, some operations may fail"
    fi
    
    # Detect system information
    detect_os || exit 1
    
    # Update system packages
    update_system || exit 1
    
    # Install required dependencies
    install_dependencies || exit 1
    
    # Initialize dotfiles
    init_dotfiles || exit 1
    
    # Completion message
    bdb_info "Bootstrap process completed successfully"
    bdb_info "Log file saved to: ${BDB_LOG_FILE}"
    bdb_info_out "Please log out and log back in to load your dotfiles"
    
    return 0
}

# =============================================================================
# SCRIPT INITIALIZATION
# =============================================================================

# -----------------------------------------------------------------------------
# Setup Error Handling
# -----------------------------------------------------------------------------
# Enable strict error handling and automatic cleanup
# -e: Exit immediately if a command exits with non-zero status
# -u: Treat unset variables as errors
# -o pipefail: Return exit status of last failed command in pipeline
set -euo pipefail

# -----------------------------------------------------------------------------
# Setup Traps
# -----------------------------------------------------------------------------
# Register cleanup and error handlers
trap 'bdb_handle_error' ERR      # Handle errors automatically
trap 'bdb_cleanup' EXIT          # Cleanup on script exit
trap 'bdb_timestamp' DEBUG       # Add timestamps to log entries

# -----------------------------------------------------------------------------
# Setup Logging
# -----------------------------------------------------------------------------
# Redirect stdout/stderr to log file, preserve FD3 for user output
exec 3>&1                        # Save original stdout to FD3
exec 1>"${BDB_LOG_FILE}"         # Redirect stdout to log file
exec 2>&1                        # Redirect stderr to stdout (log file)

# Enable command tracing in log file
set -x

# =============================================================================
# START BOOTSTRAP
# =============================================================================

bdb_bootstrap

exit 0
