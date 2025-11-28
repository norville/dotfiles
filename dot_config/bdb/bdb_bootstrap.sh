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
#   bash -c "$(curl -fsSL https://raw.githubusercontent.com/norville/dotfiles/main/dot_config/bdb/bdb_bootstrap.sh)"
#   or
#   bash -c "$(wget -qO- https://raw.githubusercontent.com/norville/dotfiles/main/dot_config/bdb/bdb_bootstrap.sh)"
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
readonly GITHUB_USER="norville"
readonly GITHUB_REPO="dotfiles"
readonly CHEZMOI_BRANCH="main"

# Script paths and URLs
readonly BDB_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly BDB_HELPERS="${BDB_SCRIPT_DIR}/bdb_helpers.sh"
readonly BDB_HELPERS_URL="https://raw.githubusercontent.com/${GITHUB_USER}/${GITHUB_REPO}/${CHEZMOI_BRANCH}/dot_config/bdb/bdb_helpers.sh"

# Logging configuration
# Set log file path with timestamp for unique logs per bootstrap run
# Note: Not readonly because bdb_init_logging will export it after sourcing helpers
# The .txt extension is used to distinguish from helper's default .log extension
# This ensures bootstrap logs are easily identifiable
BDB_LOG_FILE="${BDB_SCRIPT_DIR}/bdb_log_$(date +%Y%m%d_%H%M%S).txt"

# System detection paths
readonly LSB_RELEASE_PATH="/etc/os-release"

# =============================================================================
# HELPER FUNCTION LOADING
# =============================================================================
# Download and source the BDB helper functions
# This section handles obtaining the helper functions either from local file
# or by downloading from GitHub, then sourcing them into the current script

# -----------------------------------------------------------------------------
# Download and Source Helper Functions
# -----------------------------------------------------------------------------
# Attempts to load helper functions from local file first, downloads if needed
# This allows the bootstrap to work both as a standalone script and when
# running from a local clone of the dotfiles repository
#
# Process:
#   1. Check if helpers exist locally at ${BDB_HELPERS}
#   2. If not, download from GitHub using curl or wget
#   3. Verify the file exists and is readable
#   4. Source the helper functions into current script
#
# Exit Conditions:
#   - Exits if neither curl nor wget is available
#   - Exits if download fails
#   - Exits if sourcing fails
#
# This function must complete successfully before any other operations
load_helpers() {
    local helpers_exist=false

    # Check if helpers exist locally (common when running from repo)
    if [[ -f "${BDB_HELPERS}" ]]; then
        helpers_exist=true
        echo "[INFO] Using local helper functions from ${BDB_HELPERS}"
    else
        # Helpers not local - need to download from GitHub
        echo "[INFO] Downloading helper functions from ${BDB_HELPERS_URL}"

        # Try curl first (most common on modern systems)
        if command -v curl >/dev/null 2>&1; then
            if curl -fsSL "${BDB_HELPERS_URL}" -o "${BDB_HELPERS}"; then
                helpers_exist=true
            fi
        # Fall back to wget if curl not available
        elif command -v wget >/dev/null 2>&1; then
            if wget -qO "${BDB_HELPERS}" "${BDB_HELPERS_URL}"; then
                helpers_exist=true
            fi
        else
            # Neither download tool available - cannot proceed
            echo "[ERROR] Neither curl nor wget is available. Cannot download helpers." >&2
            exit 1
        fi
    fi

    # Verify helper file exists before attempting to source
    if [[ "$helpers_exist" != true ]] || [[ ! -f "${BDB_HELPERS}" ]]; then
        echo "[ERROR] Failed to obtain helper functions from ${BDB_HELPERS_URL}" >&2
        exit 1
    fi

    # Source the helper functions into the current script
    # This makes all BDB functions (bdb_exec, bdb_success, etc.) available
    # shellcheck disable=SC1090,SC1091
    source "${BDB_HELPERS}"
}

# Load helpers before proceeding with bootstrap
# This must happen first, before any BDB functions are called
load_helpers

# =============================================================================
# SYSTEM DETECTION FUNCTIONS
# =============================================================================
# Functions for detecting the operating system and distribution
# This information is used to determine which package manager and
# installation commands to use throughout the bootstrap process

# -----------------------------------------------------------------------------
# Detect Operating System
# -----------------------------------------------------------------------------
# Identifies the operating system (Darwin/Linux) and specific distribution
# Sets global variables PLATFORM and DISTRO for use by other functions
#
# Detection Logic:
#   1. Uses uname -s to determine platform (Darwin = macOS, Linux = Linux)
#   2. For macOS: Sets distro to "macos"
#   3. For Linux: Reads /etc/os-release to identify distribution
#      - First tries ID field (e.g., "ubuntu", "fedora", "arch")
#      - Falls back to ID_LIKE if ID is empty (handles derivatives)
#      - Normalizes to lowercase for consistent matching
#
# Global Variables Set:
#   PLATFORM - Operating system type (Darwin or Linux)
#   DISTRO   - Distribution identifier (macos, ubuntu, fedora, arch, etc.)
#
# Returns:
#   0 - Success, system detected
#   1 - Unsupported or unknown system
#
# Example Output:
#   • Platform: Linux
#   • Distribution: ubuntu
detect_os() {
    local platform distro

    # Inform user we're detecting system
    bdb_action "Detecting operating system"

    # Get platform name from uname
    platform="$(uname -s)"

    case "${platform}" in
        Darwin)
            # macOS system
            distro="macos"
            ;;
        Linux)
            # Linux system - need to identify distribution
            if [[ -f "${LSB_RELEASE_PATH}" ]]; then
                # Extract distribution ID from /etc/os-release
                # Format: ID=ubuntu or ID="ubuntu"
                distro="$(grep -E '^ID=' "${LSB_RELEASE_PATH}" | cut -d'=' -f2 | tr -d '"' | tr '[:upper:]' '[:lower:]')"

                # If ID is empty, try ID_LIKE (for derivatives like Pop!_OS)
                if [[ -z "${distro}" ]]; then
                    distro="$(grep -E '^ID_LIKE=' "${LSB_RELEASE_PATH}" | cut -d'=' -f2 | tr -d '"' | awk '{print $1}' | tr '[:upper:]' '[:lower:]')"
                fi
            else
                # No /etc/os-release file found
                distro="unknown"
            fi
            ;;
        *)
            # Unsupported platform
            bdb_error "Unsupported operating system: ${platform}"
            return 1
            ;;
    esac

    # Display detected system information
    bdb_var "Platform" "${platform}"
    bdb_var "Distribution" "${distro}"

    # Export variables for use by other functions
    export PLATFORM="${platform}"
    export DISTRO="${distro}"
    return 0
}

# =============================================================================
# SYSTEM UPDATE FUNCTIONS
# =============================================================================
# Functions for updating system packages on different distributions
# Each function handles the specific package manager and update commands
# for its target distribution

# -----------------------------------------------------------------------------
# Update Arch/Manjaro System
# -----------------------------------------------------------------------------
# Updates system packages using pacman package manager
# Also cleans up orphaned packages and package cache
#
# Operations performed:
#   1. Update system packages (pacman -Syu)
#   2. Remove orphaned packages (if any)
#   3. Clean package cache
#
# Package Manager: pacman (Arch Linux package manager)
# Requires: sudo privileges
update_arch() {
    # Update all installed packages to latest versions
    bdb_exec "Updating system packages" sudo pacman -Syu --noconfirm

    # Find and remove orphaned packages (installed as dependencies but no longer needed)
    local orphans
    orphans="$(pacman -Qdtq 2>/dev/null || true)"
    if [[ -n "${orphans}" ]]; then
        # Orphans found - remove them
        bdb_exec "Removing orphaned packages" bash -c "echo '${orphans}' | sudo pacman -Rns --noconfirm -"
    fi

    # Clean the package cache to free up disk space
    bdb_exec "Cleaning package cache" sudo pacman -Scc --noconfirm
}

# -----------------------------------------------------------------------------
# Update Debian/Ubuntu System
# -----------------------------------------------------------------------------
# Updates system packages using APT package manager
# Performs full upgrade and cleanup
#
# Operations performed:
#   1. Update package lists (apt-get update)
#   2. Upgrade all packages (full-upgrade)
#   3. Remove unused packages (autoremove)
#   4. Clean package cache
#
# Package Manager: APT (Advanced Package Tool)
# Requires: sudo privileges
update_debian() {
    # Fetch latest package information from repositories
    bdb_exec "Updating package lists" sudo apt-get update

    # Upgrade all packages, handling dependency changes intelligently
    bdb_exec "Upgrading packages" sudo apt-get full-upgrade -y

    # Remove packages that were installed as dependencies but are no longer needed
    bdb_exec "Removing unused packages" sudo apt-get autoremove --purge -y

    # Remove downloaded package files to free up disk space
    bdb_exec "Cleaning package cache" sudo apt-get clean
}

# -----------------------------------------------------------------------------
# Update Fedora/RHEL System
# -----------------------------------------------------------------------------
# Updates system packages using DNF package manager
# Performs upgrade and cleanup
#
# Operations performed:
#   1. Upgrade all packages (dnf upgrade)
#   2. Remove unused packages (autoremove)
#   3. Clean package cache
#
# Package Manager: DNF (Dandified YUM)
# Requires: sudo privileges
update_fedora() {
    # Upgrade all installed packages to latest versions
    bdb_exec "Upgrading system packages" sudo dnf upgrade -y

    # Remove packages that are no longer required by any installed packages
    bdb_exec "Removing unused packages" sudo dnf autoremove -y

    # Clean package cache and temporary files
    bdb_exec "Cleaning package cache" sudo dnf clean all
}

# -----------------------------------------------------------------------------
# Update macOS System
# -----------------------------------------------------------------------------
# Updates macOS system using softwareupdate command
# Installs recommended system updates
#
# Operations performed:
#   1. Install recommended macOS updates
#
# Update Tool: softwareupdate (built-in macOS updater)
# Requires: sudo privileges
#
# Note: This installs recommended updates only, not all available updates
update_macos() {
    # Install recommended system updates (excludes optional updates)
    bdb_exec "Updating macOS system" sudo softwareupdate --install --recommended
}

# -----------------------------------------------------------------------------
# Update System (Distribution Dispatcher)
# -----------------------------------------------------------------------------
# Main update function that routes to distribution-specific updater
# Asks user for confirmation before proceeding with updates
#
# Process:
#   1. Ask user if they want to update now
#   2. If yes, call appropriate update function based on DISTRO
#   3. If no, skip and return
#
# Returns:
#   0 - Update completed successfully or skipped by user
#   1 - Unsupported distribution
#
# Global Variables Used:
#   DISTRO - Distribution identifier set by detect_os()
update_system() {
    # Ask user if they want to update the system now
    if ! bdb_ask "Update the system now"; then
        bdb_warn "Skipping system update"
        return 0
    fi

    # Route to appropriate update function based on distribution
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
            update_macos
            ;;
        *)
            # Unknown or unsupported distribution
            bdb_error "Unsupported distribution for system update: ${DISTRO}"
            return 1
            ;;
    esac

    # All updates completed successfully
    bdb_success "System updated successfully"
}

# =============================================================================
# DEPENDENCY INSTALLATION FUNCTIONS
# =============================================================================
# Functions for installing required dependencies (git and chezmoi) on different
# distributions. Each function checks if tools are already installed before
# attempting installation to avoid unnecessary operations.
#
# Common Pattern:
#   1. Check if each dependency already exists
#   2. Build list of packages that need installation
#   3. Install only missing packages
#   4. Verify installation succeeded
#
# Required Dependencies:
#   - git: Version control system (required for chezmoi)
#   - chezmoi: Dotfiles management tool (core requirement)

# -----------------------------------------------------------------------------
# Install Dependencies on Arch/Manjaro
# -----------------------------------------------------------------------------
# Installs git and chezmoi using pacman package manager
# Only installs packages that are not already present
#
# Package Manager: pacman (Arch Linux)
# Installation Method: Official repositories
#
# Process:
#   1. Check if git exists, add to install list if not
#   2. Check if chezmoi exists, add to install list if not
#   3. Install only the missing packages
#
# Requires: sudo privileges
install_deps_arch() {
    local packages_to_install=()

    # Check if git is already installed
    if bdb_test_cmd "git"; then
        bdb_success "Git already installed"
    else
        # Git not found - add to installation list
        packages_to_install+=("git")
    fi

    # Check if chezmoi is already installed
    if bdb_test_cmd "chezmoi"; then
        bdb_success "Chezmoi already installed"
    else
        # Chezmoi not found - add to installation list
        packages_to_install+=("chezmoi")
    fi

    # Install any missing packages
    # --needed: Skip reinstall if package is up to date
    # --noconfirm: Don't prompt for confirmation
    if [[ ${#packages_to_install[@]} -gt 0 ]]; then
        bdb_exec "Installing dependencies (Arch/Manjaro)" sudo pacman -S --needed --noconfirm "${packages_to_install[@]}"
    fi
}

# -----------------------------------------------------------------------------
# Install Dependencies on Debian
# -----------------------------------------------------------------------------
install_deps_debian() {
    local packages_to_install=()

    # Check curl
    if ! bdb_test_cmd "curl"; then
        packages_to_install+=("curl")
    else
        bdb_success "Curl already installed"
    fi

    # Check git
    if bdb_test_cmd "git"; then
        bdb_success "Git already installed"
    else
        packages_to_install+=("git")
    fi

    # Install missing packages
    if [[ ${#packages_to_install[@]} -gt 0 ]]; then
        bdb_exec "Installing dependencies" sudo apt-get install -y "${packages_to_install[@]}"
    fi

    # Install chezmoi if not already present
    if bdb_test_cmd "chezmoi"; then
        bdb_success "Chezmoi already installed"
    else
        bdb_exec "Installing chezmoi" sudo sh -c "\$(curl -fsLS https://get.chezmoi.io)" -- -b /usr/local/bin
    fi
}

# -----------------------------------------------------------------------------
# Install Dependencies on Ubuntu
# -----------------------------------------------------------------------------
install_deps_ubuntu() {
    local packages_to_install=()

    # Check git
    if bdb_test_cmd "git"; then
        bdb_success "Git already installed"
    else
        packages_to_install+=("git")
    fi

    # Check snapd
    if ! command -v snap >/dev/null 2>&1; then
        packages_to_install+=("snapd")
    else
        bdb_success "Snapd already installed"
    fi

    # Install missing packages
    if [[ ${#packages_to_install[@]} -gt 0 ]]; then
        bdb_exec "Installing dependencies (Ubuntu)" sudo apt-get install -y "${packages_to_install[@]}"
    fi

    # Install chezmoi via snap if not already present
    if bdb_test_cmd "chezmoi"; then
        bdb_success "Chezmoi already installed"
    else
        bdb_exec "Installing chezmoi via snap" sudo snap install chezmoi --classic
    fi
}

# -----------------------------------------------------------------------------
# Install Dependencies on Fedora/RHEL
# -----------------------------------------------------------------------------
install_deps_fedora() {
    # Check and install git
    if bdb_test_cmd "git"; then
        bdb_success "Git already installed"
    else
        bdb_exec "Installing git" sudo dnf install -y git
    fi

    # Install chezmoi if not already present
    if bdb_test_cmd "chezmoi"; then
        bdb_success "Chezmoi already installed"
    else
        bdb_exec "Installing chezmoi" sudo sh -c "\$(curl -fsLS https://get.chezmoi.io)" -- -b /usr/local/bin
    fi
}

# -----------------------------------------------------------------------------
# Install Dependencies on macOS
# -----------------------------------------------------------------------------
# Comprehensive setup for macOS including Xcode Command Line Tools, Homebrew,
# git, and chezmoi. This is the most complex installation function because
# macOS requires special setup steps before packages can be installed.
#
# Installation Steps:
#   1. Install Xcode Command Line Tools (compiler, make, git, etc.)
#   2. Install Homebrew package manager
#   3. Install/verify git
#   4. Install/verify chezmoi
#
# Package Manager: Homebrew (macOS package manager)
# Prerequisites: Xcode Command Line Tools
#
# Notes:
#   - Xcode CLT installation may prompt GUI dialog requiring user interaction
#   - Homebrew installation location differs between Intel and Apple Silicon
#   - First Homebrew install updates all packages automatically
#
# Requires: sudo privileges for some operations
install_deps_macos() {
    # --- Step 1: Xcode Command Line Tools ---
    # These provide essential development tools (gcc, make, git, etc.)
    # Required before Homebrew or other development tools can be installed

    bdb_action "Checking Xcode Command Line Tools"

    if xcode-select -p &>/dev/null; then
        # Xcode CLT already installed
        bdb_success "Xcode Command Line Tools already installed"
    else
        # Not installed - trigger installation
        bdb_warn "Xcode Command Line Tools not installed"
        bdb_exec "Installing Xcode Command Line Tools" xcode-select --install

        # Wait for installation to complete
        # The install command returns immediately but installation happens in background
        bdb_action "Waiting for Xcode installation to complete"
        until xcode-select -p &>/dev/null; do
            sleep 5  # Check every 5 seconds
        done

        bdb_success "Xcode Command Line Tools installed"
    fi

    # --- Step 2: Homebrew Package Manager ---
    # Homebrew is required to install most development tools on macOS

    bdb_action "Checking Homebrew"

    if command -v brew >/dev/null 2>&1; then
        # Homebrew already installed - update it
        bdb_success "Homebrew already installed"
        bdb_exec "Updating Homebrew" brew update
        bdb_exec "Upgrading Homebrew packages" brew upgrade
    else
        # Install Homebrew
        bdb_warn "Homebrew not installed"
        bdb_exec "Installing Homebrew" /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

        # Add Homebrew to PATH for current session
        # Location differs between Intel and Apple Silicon Macs
        if [[ -x "/opt/homebrew/bin/brew" ]]; then
            # Apple Silicon Mac (M1/M2/M3)
            eval "$(/opt/homebrew/bin/brew shellenv)"
        elif [[ -x "/usr/local/bin/brew" ]]; then
            # Intel Mac
            eval "$(/usr/local/bin/brew shellenv)"
        fi

        bdb_success "Homebrew installed"
    fi

    # --- Step 3: Git ---
    # Check and install git if needed
    # (May already be installed with Xcode CLT)

    if bdb_test_cmd "git"; then
        bdb_success "Git already installed"
    else
        bdb_exec "Installing git via Homebrew" brew install git
    fi

    # --- Step 4: Chezmoi ---
    # Check and install chezmoi if needed

    if bdb_test_cmd "chezmoi"; then
        bdb_success "Chezmoi already installed"
    else
        bdb_exec "Installing chezmoi via Homebrew" brew install chezmoi
    fi
}

# -----------------------------------------------------------------------------
# Install Required Dependencies
# -----------------------------------------------------------------------------
install_dependencies() {
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
    if ! bdb_test_cmd "chezmoi"; then
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
init_dotfiles() {
    bdb_begin_section "Dotfiles Installation"

    bdb_info "Ready to clone dotfiles and apply configuration"
    bdb_var "Repository" "${GITHUB_USER}/${GITHUB_REPO}"
    bdb_var "Branch" "${CHEZMOI_BRANCH}"

    if ! bdb_ask "Clone dotfiles from ${GITHUB_USER}/${GITHUB_REPO} and apply now"; then
        bdb_warn "Dotfile initialization skipped"
        bdb_info "Run this command when ready:"
        bdb_info "  chezmoi init --branch ${CHEZMOI_BRANCH} --apply ${GITHUB_USER}"
        bdb_end_section
        return 0
    fi

    # Initialize and apply in one command
    if bdb_exec "Initializing chezmoi with dotfiles" chezmoi init --branch "${CHEZMOI_BRANCH}" --apply "${GITHUB_USER}"; then
        bdb_success "Dotfiles cloned and applied successfully"
    else
        bdb_error "Failed to initialize dotfiles"
        bdb_info "You can try manually with:"
        bdb_info "  chezmoi init --branch ${CHEZMOI_BRANCH} ${GITHUB_USER}"
        bdb_info "  chezmoi apply"
        bdb_end_section
        return 1
    fi

    bdb_end_section
}

# =============================================================================
# MAIN BOOTSTRAP FUNCTION
# =============================================================================
# The main orchestration function that coordinates the entire bootstrap process
# This function calls all other functions in the correct order

# -----------------------------------------------------------------------------
# Bootstrap Main Function
# -----------------------------------------------------------------------------
# Orchestrates the complete bootstrap process from start to finish
#
# Bootstrap Process Flow:
#   1. Display welcome message
#   2. Obtain sudo privileges (and keep them alive)
#   3. Detect operating system and distribution
#   4. Update system packages (with user confirmation)
#   5. Install required dependencies (git, chezmoi)
#   6. Initialize dotfiles with chezmoi
#   7. Display completion message
#
# Exit Conditions:
#   - Exits on any error (set -e is enabled)
#   - Exits if OS detection fails
#   - Continues if system update is skipped by user
#   - Continues if dotfile init is skipped by user
#
# Returns:
#   0 - Bootstrap completed successfully
#   Non-zero - Bootstrap failed (via error handler)
#
# Global Variables Used:
#   GITHUB_USER - GitHub username for dotfiles repo
#   GITHUB_REPO - Repository name
#   BDB_LOG_FILE - Path to log file
bdb_bootstrap() {
    # --- Welcome and Information ---
    # Display welcome message and repository information

    bdb_begin_section "Bassa's Dotfiles Bootstrapper (BDB)"
    bdb_info "This script will set up your system with dotfiles from GitHub"
    bdb_var "Repository" "https://github.com/${GITHUB_USER}/${GITHUB_REPO}"
    bdb_end_section

    # --- Sudo Privileges Setup ---
    # Request sudo access early and keep it alive for the entire bootstrap
    # This prevents repeated password prompts during the process

    bdb_action "Requesting administrator privileges"
    if command -v sudo >/dev/null 2>&1; then
        # Request sudo access (prompts for password if needed)
        sudo -v
        bdb_success "Administrator privileges granted"

        # Start background process to keep sudo alive
        # This refreshes sudo timestamp every 60 seconds
        # Exits when the main script exits (kill -0 "$$" checks if parent exists)
        while true; do
            sudo -n true          # Refresh sudo timestamp
            sleep 60              # Wait 60 seconds
            kill -0 "$$" 2>/dev/null || exit  # Exit if parent script ended
        done 2>/dev/null &
    else
        # sudo not available - warn but continue
        # Some operations may fail without sudo
        bdb_warn "sudo not available, some operations may fail"
    fi

    # --- System Detection ---
    # Detect OS and distribution to determine installation methods

    bdb_begin_section "System Detection"
    detect_os || exit 1  # Exit if detection fails
    bdb_end_section

    # --- System Update ---
    # Update system packages (user can skip this step)

    bdb_begin_section "System Update"
    update_system || exit 1  # Exit if update fails
    bdb_end_section

    # --- Dependency Installation ---
    # Install git and chezmoi (required for dotfiles)

    bdb_begin_section "Installing Dependencies"
    install_dependencies || exit 1  # Exit if installation fails
    bdb_end_section

    # --- Dotfiles Initialization ---
    # Clone and apply dotfiles using chezmoi

    init_dotfiles || exit 1  # Exit if initialization fails

    # --- Completion ---
    # Show success message and next steps

    bdb_begin_section "Bootstrap Complete"
    bdb_success "Bootstrap process completed successfully"
    bdb_var "Log file" "${BDB_LOG_FILE}"
    bdb_info "Please log out and log back in to load your dotfiles"
    bdb_end_section

    return 0
}

# =============================================================================
# SCRIPT INITIALIZATION
# =============================================================================
# Critical setup that must happen before the bootstrap process begins
# This section configures error handling, trap handlers, and logging

# -----------------------------------------------------------------------------
# Setup Error Handling
# -----------------------------------------------------------------------------
# Enable strict error handling for robust script execution
#
# Bash Options Enabled:
#   -e (errexit)      - Exit immediately if any command exits with non-zero status
#   -u (nounset)      - Treat unset variables as errors
#   -o pipefail       - Return exit status of last failed command in pipeline
#
# These options ensure that errors are caught early and don't silently propagate
# Without these, the script could continue after failures leading to unpredictable state
set -euo pipefail

# -----------------------------------------------------------------------------
# Setup Traps
# -----------------------------------------------------------------------------
# Register signal handlers for automatic error handling and cleanup
#
# Traps Registered:
#   ERR trap   - Calls bdb_handle_error when any command fails
#                Captures error context (command, exit code, line number)
#                Displays error to user and exits with original exit code
#
#   EXIT trap  - Calls bdb_cleanup when script exits (success or failure)
#                Removes temporary files, unsets variables, restores FDs
#                Ensures clean state even if script is interrupted
#
# Note: We deliberately do NOT use DEBUG trap for timestamps
#       DEBUG trap runs before EVERY command, creating excessive log noise
#       Instead, timestamps are added only to important markers via _bdb_log
#
# Trap Order Matters:
#   - ERR runs first on command failure
#   - EXIT always runs last, even after ERR
trap 'bdb_handle_error' ERR     # Handle command failures
trap 'bdb_cleanup' EXIT         # Cleanup on exit

# -----------------------------------------------------------------------------
# Setup Logging
# -----------------------------------------------------------------------------
# Initialize the dual-output logging system
# MUST be done before any BDB functions are called
#
# Logging System Setup:
#   1. Creates log file at ${BDB_LOG_FILE}
#   2. Sets up FD3 for terminal output (user-facing messages)
#   3. Redirects FD1 (stdout) to log file (command output)
#   4. Redirects FD2 (stderr) to log file (errors)
#   5. Enables command tracing (set -x) in log
#
# After this setup:
#   - All command output goes to log file
#   - User sees only status messages (via FD3)
#   - Log contains complete audit trail with timestamps
#
# The log file path was set earlier in GLOBAL CONFIGURATION section
# Note: bdb_init_logging handles FD3 setup internally, no need to do it here
bdb_init_logging "${BDB_LOG_FILE}"

# =============================================================================
# START BOOTSTRAP
# =============================================================================
# Everything is now initialized - begin the bootstrap process
# All errors will be caught by traps, all output will be logged

bdb_bootstrap

# Exit with success status
# Cleanup trap will run automatically after this
exit 0