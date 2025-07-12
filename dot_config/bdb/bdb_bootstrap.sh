#!/usr/bin/env bash
# ensure new process is started

### BDF BOOT - bootstrap Bassa's Dot Files

# Source helper functions (portable, works regardless of current directory)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/bdb_helpers.sh"

# Ensure strict error handling
# -e: exit on error
# -u: treat unset variables as an error
# -o pipefail: return the exit status of the last command in the pipeline that failed
# -x: print commands and their arguments as they are executed (for debugging)
set -euo pipefail

# Trap errors and call handler
trap 'bdb_handle_error' ERR

# Define function to ensure download of entire script
bdb_bootstrap() {

    # Define variables
    GITHUB_USER="norville"  # GitHub username for dotfiles repo
    PLATFORM=""             # OS type (Darwin/Linux)
    DISTRO=""               # OS distribution name

    # --- Bootstrap process ---

    bdb_info_in "Welcome to Bassa Dotfiles Bootstrapper (BDB)"
    bdb_info "This script will detect the operating system and install all requirements to clone your dotfiles"

    # Get admin privileges (sudo)
    bdb_run "Getting admin privileges"
    if command -v sudo >/dev/null 2>&1; then
        sudo -v
        bdb_outcome "sudo OK"
    fi

    # Detect machine manufacturer (for info)
    bdb_run "Detecting machine manufacturer"
    manufacturer="$(cat /sys/devices/virtual/dmi/id/sys_vendor 2>/dev/null || echo 'Unknown')"
    bdb_outcome "${manufacturer}"

    # Detect OS type and distribution
    bdb_run "Detecting operating system"
    PLATFORM="$(uname)"
    case "${PLATFORM}" in
        Darwin)
            DISTRO="macos"
            ;;
        Linux)
            lsb_path="/etc/os-release"
            if [[ -f "${lsb_path}" ]]; then
                DISTRO="$(grep -e '^ID=' "${lsb_path}" | cut -d '=' -f 2 | tr '[:upper:]' '[:lower:]')"
            else
                DISTRO="linux"
            fi
            ;;
        *)
            bdb_handle_error "Cannot detect OS type"
            ;;
    esac
    bdb_outcome "${PLATFORM}/${DISTRO}"

    # --- Install requirements based on OS ---
    case "${DISTRO}" in
        arch|manjaro)
            bdb_command "Installing Chezmoi"
            sudo pacman -Syu --noconfirm chezmoi
            bdb_success "installing Chezmoi"
            ;;
        macos)
            # macOS: Xcode CLT and Homebrew
            bdb_run "Checking Xcode Command Line Tools"
            if command -v xcode-select >/dev/null 2>&1 && \
                clt_path="$(xcode-select --print-path 2>/dev/null)" && \
                [ -d "${clt_path}" ] && [ -x "${clt_path}" ]; then
                bdb_outcome "installed"
            else
                bdb_outcome "missing"
                bdb_command "Installing CLT"
                touch /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress
                clt_package="$(softwareupdate -l | grep '.*Command Line' | awk -F ":" '{print $2}' | sed -e 's/^ *//' | tr -d '\n')"
                softwareupdate -i "${clt_package}"
                bdb_success "installing CLT"
            fi
            bdb_run "Checking Homebrew"
            if ! command -v brew >/dev/null 2>&1; then
                bdb_outcome "missing"
                bdb_command "Installing Homebrew"
                NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
                bdb_success "installing Homebrew"
            else
                bdb_outcome "installed"
                bdb_command "Updating Homebrew"
                brew update
                bdb_success "updating Homebrew"
            fi
            bdb_command "Installing Chezmoi"
            brew install chezmoi
            bdb_success "installing Chezmoi"
            ;;
        ubuntu)
            # Ubuntu: APT, git, snapd, chezmoi
            bdb_command "Updating APT"
            sudo apt update
            bdb_success "updating APT"
            bdb_run "Checking git"
            if ! command -v git >/dev/null 2>&1; then
                bdb_outcome "missing"
                bdb_command "Installing git"
                sudo apt install -y git
                bdb_success "installing git"
            else
                bdb_outcome "installed"
            fi
            bdb_run "Checking Snap"
            if ! command -v snap >/dev/null 2>&1; then
                bdb_outcome "missing"
                bdb_command "Installing Snap"
                sudo apt install -y snapd
                bdb_success "installing Snap"
            else
                bdb_outcome "installed"
            fi
            bdb_run "Checking Chezmoi"
            if ! command -v chezmoi >/dev/null 2>&1; then
                bdb_outcome "missing"
                bdb_command "Installing Chezmoi"
                sudo snap install chezmoi --classic
                bdb_success "installing Chezmoi"
            else
                bdb_outcome "installed"
            fi
            ;;
        *)
            bdb_handle_error "Cannot detect OS type"
            ;;
    esac

    # --- Final user prompt and info ---
    bdb_info "All requirements installed, you may now configure your environment"
    if bdb_ask "Clone dotfiles and apply configuration now"; then
        bdb_command "Cloning dotfiles and applying configuration"
        chezmoi init --apply ${GITHUB_USER}
        bdb_success "cloning dotfiles and applying configuration"
    else
        bdb_alert "Cloning skipped. Use command 'chezmoi init --apply ${GITHUB_USER}' when ready"
    fi

    bdb_info_out "Bootstrap complete, please logout and log back in to load your dotfiles"
    printf "\n"
    exit 0
}

# --- Start bootstrap ---
bdb_bootstrap
