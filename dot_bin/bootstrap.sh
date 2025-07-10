#!/usr/bin/env bash
# ensure new process is started

### BDF BOOT - bootstrap Bassa's Dot Files

set -euo pipefail

# Ensure download of entire script
global_bootstrap() {
    # Define global variables
    PLATFORM=""
    DISTRO=""
    # Escape sequences for colored output
    ESC_SEQ="\x1b["
    RST_COL="${ESC_SEQ}39;49;00m" # reset
    RED_COL="${ESC_SEQ}31;01m"    # red
    GRN_COL="${ESC_SEQ}32;01m"    # green
    BLU_COL="${ESC_SEQ}34;01m"    # blue
    YLW_COL="${ESC_SEQ}33;01m"    # yellow
    CYN_COL="${ESC_SEQ}36;01m"    # cyan
    MGN_COL="${ESC_SEQ}35;01m"    # magenta
    WHT_COL="${ESC_SEQ}97;01m"    # white

    # Print success message
    bdb_success() {
        printf "\n%s|vvv| SUCCESS %s. %s" "${GRN_COL}" "${1:-*** UNKNOWN ***}" "${RST_COL}"
    }

    # Print error message
    bdb_error() {
        printf "\n%s|xxx| ERROR %s %s" "${RED_COL}" "${1:-*** UNKNOWN ***}" "${RST_COL}"
    }

    # Print alert message
    bdb_alert() {
        printf "\n%s|!!!| %s %s" "${YLW_COL}" "$1" "${RST_COL}"
    }

    # Print info message - begin
    bdb_info_in() {
        printf "%s\n|BDB| +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++\n|BDB|\n|BDB| %s.\n|BDB|\n%s" "${WHT_COL}" "${1:-*** UNKNOWN ***}" "${RST_COL}"
    }

    # Print info message - end
    bdb_info_out() {
        printf "%s\n|BDB|\n|BDB| %s.\n|BDB|\n|BDB| ---------------------------------------------------------------------------------%s" "${WHT_COL}" "${1:-*** UNKNOWN ***}" "${RST_COL}"
    }

    # Print run message
    bdb_run() {
        printf "\n%s|###| %s...%s" "${BLU_COL}" "${1:-*** UNKNOWN ***}" "${RST_COL}"
    }

    # Print outcome message
    bdb_outcome() {
        printf " %s%s.%s" "${CYN_COL}" "${1:-*** UNKNOWN ***}" "${RST_COL}"
    }

    # Print message before command
    bdb_command() {
        printf "\n%s|>>>| %s:%s" "${CYN_COL}" "${1:-*** UNKNOWN ***}" "${RST_COL}"
    }

    # Ask user yes/no, return 0 for yes (default: no)
    bdb_ask() {
        printf "%s\n|???|\n|???| %s ? [y|N] >\n|???| %s" "${MGN_COL}" "${1:-*** UNKNOWN ***}" "${RST_COL}"
        read -s -r -n 1 response
        if [[ ${response:-} =~ (y|Y) ]]; then
            return 0
        fi
        return 1
    }

    # Handle errors, clean up and exit
    bdb_handle_error() {
        local err_value="$?"
        local err_command="$BASH_COMMAND"
        local err_message="${1:-UNKNOWN}"
        bdb_error "Command: <${err_command}>"
        bdb_error "Value: [${err_value}]"
        bdb_error "Message: '${err_message}'"
        bdb_error "Exiting now!"
        printf "\n"
        exit "${err_value}"
    }

    trap 'bdb_handle_error' ERR

    # Bootstrap begin
    bdb_info_in "Welcome to Bassa Dotfiles Bootstrapper (BDB)"
    bdb_info_in "This script will detect the operating system and install all requirements to clone your dotfiles"

    # Get admin privileges
    bdb_run "Getting admin privileges"
    if command -v sudo >/dev/null 2>&1; then
        sudo -v
    fi

    # Detect machine manufacturer
    bdb_run "Detecting machine manufacturer"
    manufacturer="$(cat /sys/devices/virtual/dmi/id/sys_vendor 2>/dev/null || echo Unknown)"
    bdb_outcome "${manufacturer}"

    # Detect OS
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

    # Install requirements
    case "${DISTRO}" in
        arch|manjaro)
            bdb_command "Installing Chezmoi"
            sudo pacman -Syu --noconfirm chezmoi
            bdb_success "installing Chezmoi"
            ;;
        macos)
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
            if ! command -v snapd >/dev/null 2>&1; then
                bdb_outcome "Snap is missing"
                bdb_command "Installing Snap"
                sudo apt install -y snapd
                bdb_success "installing Snap"
            fi
            bdb_run "Checking Chezmoi"
            if ! command -v chezmoi >/dev/null 2>&1; then
                bdb_outcome "Chezmoi is missing"
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

    bdb_info_out "All requirements installed, ready to clone your dotfiles"

    if bdb_ask "Do you want to clone the dotfiles now"; then
        bdb_command "Cloning dotfiles"
        chezmoi init --apply norville
        bdb_success "cloning dotfiles"
    else
        bdb_info_in "Clone your dotfiles anytime with command 'chezmoi init --apply <github_username>'"
    fi

    bdb_info_out "Please logout and log back in to load your dotfiles"
    printf "\n"
    exit 0
}

global_bootstrap
