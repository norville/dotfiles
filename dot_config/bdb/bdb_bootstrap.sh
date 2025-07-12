#!/usr/bin/env bash
# ensure new process is started

### BDF BOOT - bootstrap Bassa's Dot Files

# Escape sequences for colored output (ANSI C quoting)
RST_COL=$'\033[39;49;00m'   # reset
RED_COL=$'\033[31;01m'      # red
GRN_COL=$'\033[32;01m'      # green
BLU_COL=$'\033[34;01m'      # blue
YLW_COL=$'\033[33;01m'      # yellow
CYN_COL=$'\033[36;01m'      # cyan
MGN_COL=$'\033[35;01m'      # magenta
WHT_COL=$'\033[97;01m'      # white

# --- Output helper functions ---

# Print success message (green)
bdb_success() {
    printf "\n%s|vvv| SUCCESS %s. %s" "${GRN_COL}" "${1:-*** UNKNOWN ***}" "${RST_COL}"
}

# Print error message (red)
bdb_error() {
    printf "\n%s|xxx| ERROR %s %s" "${RED_COL}" "${1:-*** UNKNOWN ***}" "${RST_COL}"
}

# Print alert message (yellow)
bdb_alert() {
    printf "\n%s|!!!| %s %s" "${YLW_COL}" "$1" "${RST_COL}"
}

# Print info message - begin (white)
bdb_info_in() {
    printf "%s\n|BDB| +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++\n|BDB|\n|BDB| %s.\n|BDB|%s" "${WHT_COL}" "${1:-*** UNKNOWN ***}" "${RST_COL}"
}

# Print info message (white)
bdb_info() {
    printf "%s\n|BDB|\n|BDB| %s.\n|BDB|%s" "${WHT_COL}" "${1:-*** UNKNOWN ***}" "${RST_COL}"
}

# Print info message - end (white)
bdb_info_out() {
    printf "%s\n|BDB|\n|BDB| %s.\n|BDB|\n|BDB| ---------------------------------------------------------------------------------%s" "${WHT_COL}" "${1:-*** UNKNOWN ***}" "${RST_COL}"
}

# Print run message (blue)
bdb_run() {
    printf "\n%s|###| %s...%s" "${BLU_COL}" "${1:-*** UNKNOWN ***}" "${RST_COL}"
}

# Print outcome message (cyan)
bdb_outcome() {
    printf " %s%s.%s" "${CYN_COL}" "${1:-*** UNKNOWN ***}" "${RST_COL}"
}

# Print message before command (cyan)
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
    local err_value="$?"         # Last command exit value
    local err_command="$BASH_COMMAND" # Last command string
    local err_message="${1:-UNKNOWN}" # Optional error message
    bdb_error "Command: <${err_command}>"
    bdb_error "Value: [${err_value}]"
    bdb_error "Message: '${err_message}'"
    bdb_error "Exiting now!"
    printf "\n"
    exit "${err_value}"
}

# Define main function to ensure download of entire script
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

# Ensure strict error handling
# -e: exit on error
# -u: treat unset variables as an error
# -o pipefail: return the exit status of the last command in the pipeline that failed
# -x: print commands and their arguments as they are executed (for debugging)
set -euo pipefail

# Trap errors and call handler
trap 'bdb_handle_error' ERR

# --- Start bootstrap ---
bdb_bootstrap
