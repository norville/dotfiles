#!/usr/bin/env bash
# ensure new process is started

### BDF BOOT - bootstrap Bassa's Dot Files

#  --- Define global variables ---
BDB_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"                                              # Get current directory of this script
BDB_HELPERS="${BDB_SCRIPT_DIR}/bdb_helpers.sh"                                                              # Path to helper functions
BDB_HELPERS_URL="https://raw.githubusercontent.com/norville/dotfiles/main/dot_config/bdb/bdb_helpers.sh"    # URL to download helper functions
BDB_LOG_FILE="./bdb_log.txt"                                                                                # log file path

#  --- Source helper functions (portable, works regardless of current directory) ---
if command -v curl >/dev/null 2>&1; then
    curl -fsSL "${BDB_HELPERS_URL}" -o "${BDB_HELPERS}"
elif command -v wget >/dev/null 2>&1; then
    wget -qO "${BDB_HELPERS}" "${BDB_HELPERS_URL}"
else
    echo "Error: curl or wget is required to download helper script." >&2
    exit 1
fi
if [[ ! -f "${BDB_HELPERS}" ]]; then
    echo "Error: Failed to download helper script from ${BDB_HELPERS_URL}" >&2
    exit 1
fi
# shellcheck disable=SC1091
# shellcheck disable=SC1090
source "${BDB_HELPERS}"

# --- Define main function ---
bdb_bootstrap() {

    # --- Define local variables ---
    GITHUB_USER="norville"                              # GitHub username for dotfiles repo
    CHEZMOI_BRANCH="main"                               # Branch to use for chezmoi init
    PLATFORM="$(uname)"                                 # OS type (Darwin/Linux)
    DISTRO="Unknown"                                    # OS distribution name
    LSB_PATH="/etc/os-release"                          # Path to lsb-release file (Linux)
    VENDOR_X86="/sys/devices/virtual/dmi/id/sys_vendor" # x86/x86_64 vendor info
    VENDOR_ARM="/sys/firmware/devicetree/base/model"    # ARM vendor info
    PC_VENDOR="Unknown"                                 # Machine vendor - exported to be used in 'chezmoi.toml'

    # --- Print welcome message ---
    bdb_info_in "Welcome to Bassa Dotfiles Bootstrapper (BDB)"
    bdb_info "This script will detect the operating system and install all requirements to clone your dotfiles"

    # --- Get admin privileges (sudo) ---
    bdb_run "Getting admin privileges"
    if command -v sudo >/dev/null 2>&1; then
        sudo -v
        bdb_outcome "sudo OK"
    fi

    # --- Detect machine vendor (for info) ---
    bdb_run "Detecting machine vendor"
    if [[ -f "${VENDOR_X86}" ]]; then
        PC_VENDOR="$(cat ${VENDOR_X86})"
    elif [[ -f "${VENDOR_ARM}" ]]; then
        PC_VENDOR="$(cat ${VENDOR_ARM})"
    fi
    bdb_outcome "${PC_VENDOR}"
    export PC_VENDOR  # Export vendor for use in chezmoi.toml

    # --- Detect OS type and distribution ---
    bdb_run "Detecting operating system"
    case "${PLATFORM}" in
        Darwin)
            DISTRO="macos"
            ;;
        Linux)
            if [[ -f "${LSB_PATH}" ]]; then
                DISTRO="$(grep -e '^ID=' "${LSB_PATH}" | cut -d '=' -f 2 | tr '[:upper:]' '[:lower:]')"
            fi
            ;;
        *)
            bdb_handle_error "Cannot detect operating system"
            ;;
    esac
    bdb_outcome "${PLATFORM}/${DISTRO}"

    # --- Install Chezmoi requirements ---
    bdb_command "Installing Chezmoi and its dependencies"
    case "${DISTRO}" in
        arch|manjaro)
            sudo pacman -S --noconfirm git chezmoi
            ;;
        debian)
            sudo apt update && sudo apt install -y curl git
            if ! command -v chezmoi >/dev/null 2>&1; then
                sudo sh -c "$(curl -fsLS get.chezmoi.io)" -- -b /usr/local/bin
            fi
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
            sudo apt update && sudo apt install -y git snapd
            if ! command -v chezmoi >/dev/null 2>&1; then
                sudo snap install chezmoi --classic
            fi
            ;;
        *)
            bdb_handle_error "Cannot install Chezmoi or its dependencies"
            ;;
    esac
    bdb_success "installing Chezmoi and its dependencies"

    # --- Chezmoi installed, ready to clone dotfiles ---
    bdb_info "All requirements installed, you may now configure your environment"
    if bdb_ask "Clone dotfiles and apply configuration now"; then
        bdb_command "Cloning dotfiles and applying configuration"
        chezmoi init --branch "${CHEZMOI_BRANCH}" --apply "${GITHUB_USER}"
        bdb_success "cloning dotfiles and applying configuration"
    else
        bdb_alert "Cloning skipped. Use command 'chezmoi init --apply ${GITHUB_USER}' when ready"
    fi

    # --- Print completion message ---
    bdb_info "Bootstrap complete, check the log file at <${LOGFILE}> for details"
    bdb_info_out "Please logout and log back in to load your dotfiles"
}

# --- Setup error handling ---
# -e: exit on error
# -u: treat unset variables as an error
# -o pipefail: return the exit status of the last command in the pipeline that failed
set -euo pipefail

# --- Setup traps ---
trap 'bdb_handle_error' ERR # Call handler on error
trap 'bdb_cleanup' EXIT     # Call cleanup on exit (normal or error)
trap 'bdb_timestamp' DEBUG  # Print timestamp before command execution

# --- Setup logging and output redirection ---
exec 3>&1 1>"${BDB_LOG_FILE}" 2>&1   # create FD for user messages, redirect stdout and stderr to log file
set -x                          # enable command tracing: print commands and their arguments as they are executed

# --- Start bootstrap ---
bdb_bootstrap

exit 0
