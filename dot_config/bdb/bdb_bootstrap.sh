#!/usr/bin/env bash
# =============================================================================
# BDB Bootstrap — Bassa's Dotfiles Bootstrapper
# =============================================================================
# Installs chezmoi and syncs dotfiles across machines and operating systems.
#
# Supported Systems:
# - macOS (Intel and Apple Silicon)
# - Linux: Arch, CachyOS, Manjaro, Debian, Ubuntu, Fedora, RHEL
#
# Usage:
#   bash -c "$(curl -fsSL https://raw.githubusercontent.com/norville/dotfiles/main/dot_config/bdb/bdb_bootstrap.sh)"
#   bash -c "$(wget -qO- https://raw.githubusercontent.com/norville/dotfiles/main/dot_config/bdb/bdb_bootstrap.sh)"
#   ./bdb_bootstrap.sh
#
# Repository: https://github.com/norville/dotfiles
# =============================================================================

# =============================================================================
# GLOBAL CONFIGURATION
# =============================================================================

readonly GITHUB_USER="norville"
readonly GITHUB_REPO="dotfiles"
readonly CHEZMOI_BRANCH="main"

# Not readonly — must be unset-able during cleanup (bdb_cleanup uses unset -v)
BDB_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BDB_HELPERS="${BDB_SCRIPT_DIR}/bdb_helpers.sh"
BDB_HELPERS_URL="https://raw.githubusercontent.com/${GITHUB_USER}/${GITHUB_REPO}/${CHEZMOI_BRANCH}/dot_config/bdb/bdb_helpers.sh"

# Not readonly — bdb_init_logging re-exports it; .txt distinguishes bootstrap
# logs from chezmoi script logs (.log)
BDB_LOG_FILE="${BDB_SCRIPT_DIR}/bdb_log_$(date +%Y%m%d_%H%M%S).txt"

BDB_TEMP_FILES=""

readonly LSB_RELEASE_PATH="/etc/os-release"

# =============================================================================
# HELPER FUNCTION LOADING
# =============================================================================

# Load bdb_helpers.sh from the local repo or download it from GitHub.
# Must succeed before any bdb_* function is called.
load_helpers() {
    local helpers_exist=false
    local was_downloaded=false

    if [[ -f "${BDB_HELPERS}" ]]; then
        helpers_exist=true
        echo "[INFO] Using local helper functions from ${BDB_HELPERS}"
    else
        echo "[INFO] Downloading helper functions from ${BDB_HELPERS_URL}"

        if command -v curl >/dev/null 2>&1; then
            if curl -fsSL "${BDB_HELPERS_URL}" -o "${BDB_HELPERS}"; then
                helpers_exist=true
                was_downloaded=true
            fi
        elif command -v wget >/dev/null 2>&1; then
            if wget -qO "${BDB_HELPERS}" "${BDB_HELPERS_URL}"; then
                helpers_exist=true
                was_downloaded=true
            fi
        else
            echo "[ERROR] Neither curl nor wget is available. Cannot download helpers." >&2
            exit 1
        fi

        if [[ "$was_downloaded" == true ]]; then
            BDB_TEMP_FILES="${BDB_TEMP_FILES} ${BDB_HELPERS}"
            echo "[INFO] Helper file will be removed on exit"
        fi
    fi

    if [[ "$helpers_exist" != true ]] || [[ ! -f "${BDB_HELPERS}" ]]; then
        echo "[ERROR] Failed to obtain helper functions from ${BDB_HELPERS_URL}" >&2
        exit 1
    fi

    # shellcheck disable=SC1090,SC1091
    source "${BDB_HELPERS}"
}

load_helpers

# =============================================================================
# SYSTEM DETECTION FUNCTIONS
# =============================================================================

detect_os() {
    local platform distro

    bdb_action "Detecting operating system"

    platform="$(uname -s)"

    case "${platform}" in
    Darwin)
        distro="macos"
        ;;
    Linux)
        if [[ -f "${LSB_RELEASE_PATH}" ]]; then
            distro="$(grep -E '^ID=' "${LSB_RELEASE_PATH}" | cut -d'=' -f2 | tr -d '"' | tr '[:upper:]' '[:lower:]')"

            # Fall back to ID_LIKE for derivatives (e.g. Pop!_OS has ID_LIKE=ubuntu)
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

    bdb_var "Platform" "${platform}"
    bdb_var "Distribution" "${distro}"

    export PLATFORM="${platform}"
    export DISTRO="${distro}"
    return 0
}

# =============================================================================
# SYSTEM UPDATE FUNCTIONS
# =============================================================================

# -----------------------------------------------------------------------------
# Arch / CachyOS / Manjaro
# -----------------------------------------------------------------------------
update_arch() {
    bdb_exec "Updating system packages" sudo pacman -Syu --noconfirm

    local orphans
    orphans="$(pacman -Qdtq 2>/dev/null || true)"
    if [[ -n "${orphans}" ]]; then
        bdb_exec "Removing orphaned packages" bash -c "echo '${orphans}' | sudo pacman -Rns --noconfirm -"
    fi

    bdb_exec "Cleaning package cache" sudo pacman -Scc --noconfirm

    if bdb_test_cmd "yay"; then
        bdb_exec "Updating AUR packages" yay -Syu --noconfirm
        bdb_success "AUR packages updated"
    fi
}

# -----------------------------------------------------------------------------
# Debian / Ubuntu
# -----------------------------------------------------------------------------
update_debian() {
    bdb_exec "Updating package lists" sudo apt-get update
    bdb_exec "Upgrading packages" sudo apt-get full-upgrade -y
    bdb_exec "Removing unused packages" sudo apt-get autoremove --purge -y
    bdb_exec "Cleaning package cache" sudo apt-get clean

    if bdb_test_cmd "snap"; then
        bdb_exec "Updating Snap packages" sudo snap refresh
        bdb_success "Snap packages updated"
    fi
}

# -----------------------------------------------------------------------------
# Fedora / RHEL
# -----------------------------------------------------------------------------
update_fedora() {
    bdb_exec "Upgrading system packages" sudo dnf upgrade -y
    bdb_exec "Removing unused packages" sudo dnf autoremove -y
    bdb_exec "Cleaning package cache" sudo dnf clean all

    if bdb_test_cmd "flatpak"; then
        bdb_exec "Updating Flatpak packages" flatpak update -y
        bdb_success "Flatpak packages updated"
    fi
}

# -----------------------------------------------------------------------------
# macOS
# -----------------------------------------------------------------------------
update_macos() {
    bdb_exec "Updating macOS system" sudo softwareupdate --install --recommended
}

update_system() {
    if ! bdb_ask "Update the system now"; then
        bdb_warn "Skipping system update"
        return 0
    fi

    case "${DISTRO}" in
    arch | cachyos | manjaro)
        update_arch
        ;;
    debian | ubuntu | pop)
        update_debian
        ;;
    fedora | rhel | centos)
        update_fedora
        ;;
    macos)
        update_macos
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
# Arch / CachyOS / Manjaro
# -----------------------------------------------------------------------------
install_deps_arch() {
    local packages_to_install=()

    if bdb_test_cmd "git"; then
        bdb_success "Git already installed"
    else
        packages_to_install+=("git")
    fi

    if bdb_test_cmd "chezmoi"; then
        bdb_success "Chezmoi already installed"
    else
        packages_to_install+=("chezmoi")
    fi

    if [[ ${#packages_to_install[@]} -gt 0 ]]; then
        # --needed: skip reinstall if already up to date
        bdb_exec "Installing dependencies (Arch/CachyOS/Manjaro)" sudo pacman -S --needed --noconfirm "${packages_to_install[@]}"
    fi
}

# -----------------------------------------------------------------------------
# Debian
# -----------------------------------------------------------------------------
# chezmoi installed via snap (--classic) to match Ubuntu and avoid piping a
# remote script into a shell. Follows the official Debian snap guide:
# https://snapcraft.io/docs/tutorials/install-the-daemon/debian/
install_deps_debian() {
    local packages_to_install=()
    local snapd_freshly_installed=false

    if bdb_test_cmd "git"; then
        bdb_success "Git already installed"
    else
        packages_to_install+=("git")
    fi

    if bdb_test_cmd "snap"; then
        bdb_success "Snapd already installed"
    else
        packages_to_install+=("snapd")
        snapd_freshly_installed=true
    fi

    if [[ ${#packages_to_install[@]} -gt 0 ]]; then
        bdb_exec "Installing dependencies" sudo apt-get install -y "${packages_to_install[@]}"
    fi

    # After a fresh snapd install on Debian, snap core must be installed to
    # bring the snapd daemon to its latest version before other snaps are added
    if [[ "${snapd_freshly_installed}" == true ]]; then
        bdb_exec "Installing snap core" sudo snap install core
    fi

    if bdb_test_cmd "chezmoi"; then
        bdb_success "Chezmoi already installed"
    else
        bdb_exec "Installing chezmoi via snap" sudo snap install chezmoi --classic
    fi
}

# -----------------------------------------------------------------------------
# Ubuntu
# -----------------------------------------------------------------------------
install_deps_ubuntu() {
    local packages_to_install=()

    if bdb_test_cmd "git"; then
        bdb_success "Git already installed"
    else
        packages_to_install+=("git")
    fi

    if ! command -v snap >/dev/null 2>&1; then
        packages_to_install+=("snapd")
    else
        bdb_success "Snapd already installed"
    fi

    if [[ ${#packages_to_install[@]} -gt 0 ]]; then
        bdb_exec "Installing dependencies (Ubuntu)" sudo apt-get install -y "${packages_to_install[@]}"
    fi

    if bdb_test_cmd "chezmoi"; then
        bdb_success "Chezmoi already installed"
    else
        bdb_exec "Installing chezmoi via snap" sudo snap install chezmoi --classic
    fi
}

# -----------------------------------------------------------------------------
# Fedora / RHEL
# -----------------------------------------------------------------------------
install_deps_fedora() {
    local packages_to_install=()

    if bdb_test_cmd "git"; then
        bdb_success "Git already installed"
    else
        packages_to_install+=("git")
    fi

    if bdb_test_cmd "chezmoi"; then
        bdb_success "Chezmoi already installed"
    else
        packages_to_install+=("chezmoi")
    fi

    if [[ ${#packages_to_install[@]} -gt 0 ]]; then
        bdb_exec "Installing dependencies (Fedora/RHEL)" sudo dnf install -y "${packages_to_install[@]}"
    fi
}

# -----------------------------------------------------------------------------
# macOS
# -----------------------------------------------------------------------------
install_deps_macos() {
    # --- Step 1: Xcode Command Line Tools ---
    # Provides gcc, make, git, etc. — required before Homebrew can be installed.

    bdb_action "Checking Xcode Command Line Tools"

    if xcode-select -p &>/dev/null; then
        bdb_success "Xcode Command Line Tools already installed"
    else
        bdb_warn "Xcode Command Line Tools not installed"
        bdb_exec "Installing Xcode Command Line Tools" xcode-select --install

        # xcode-select --install returns immediately; installation runs in the background
        bdb_action "Waiting for Xcode installation to complete"
        until xcode-select -p &>/dev/null; do
            sleep 5
        done

        bdb_success "Xcode Command Line Tools installed"
    fi

    # --- Step 2: Homebrew ---

    bdb_action "Checking Homebrew"

    if command -v brew >/dev/null 2>&1; then
        bdb_success "Homebrew already installed"
        bdb_exec "Updating Homebrew" brew update
        bdb_exec "Upgrading Homebrew packages" brew upgrade
    else
        bdb_warn "Homebrew not installed"
        bdb_exec "Installing Homebrew" /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

        # Homebrew path differs between Apple Silicon (/opt/homebrew) and Intel (/usr/local)
        if [[ -x "/opt/homebrew/bin/brew" ]]; then
            eval "$(/opt/homebrew/bin/brew shellenv)"
        elif [[ -x "/usr/local/bin/brew" ]]; then
            eval "$(/usr/local/bin/brew shellenv)"
        fi

        bdb_success "Homebrew installed"
    fi

    # --- Step 3: Git ---

    if bdb_test_cmd "git"; then
        bdb_success "Git already installed"
    else
        bdb_exec "Installing git via Homebrew" brew install git
    fi

    # --- Step 4: Chezmoi ---

    if bdb_test_cmd "chezmoi"; then
        bdb_success "Chezmoi already installed"
    else
        bdb_exec "Installing chezmoi via Homebrew" brew install chezmoi
    fi
}

install_dependencies() {
    case "${DISTRO}" in
    arch | cachyos | manjaro)
        install_deps_arch
        ;;
    debian)
        install_deps_debian
        ;;
    ubuntu | pop)
        install_deps_ubuntu
        ;;
    fedora | rhel | centos)
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

    if ! bdb_test_cmd "chezmoi"; then
        bdb_error "Chezmoi installation failed"
        return 1
    fi

    bdb_success "Dependencies installed successfully"
}

# =============================================================================
# DOTFILES INITIALIZATION
# =============================================================================

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

bdb_bootstrap() {
    # --- Welcome ---

    bdb_begin_section "Bassa's Dotfiles Bootstrapper (BDB)"
    bdb_info "This script will set up your system with dotfiles from GitHub"
    bdb_var "Repository" "https://github.com/${GITHUB_USER}/${GITHUB_REPO}"
    bdb_end_section

    # --- Sudo Privileges ---
    # Request early and keep alive so the password is only prompted once.

    bdb_action "Requesting administrator privileges"
    if command -v sudo >/dev/null 2>&1; then
        sudo -v
        bdb_success "Administrator privileges granted"

        # Background loop refreshes sudo timestamp every 60 seconds.
        # kill -0 "$$" exits automatically when the parent script ends.
        while true; do
            sudo -n true
            sleep 60
            kill -0 "$$" 2>/dev/null || exit
        done 2>/dev/null &
    else
        bdb_warn "sudo not available, some operations may fail"
    fi

    # --- System Detection ---

    bdb_begin_section "System Detection"
    detect_os || exit 1
    bdb_end_section

    # --- System Update ---

    bdb_begin_section "System Update"
    update_system || exit 1
    bdb_end_section

    # --- Dependency Installation ---

    bdb_begin_section "Installing Dependencies"
    install_dependencies || exit 1
    bdb_end_section

    # --- Dotfiles ---

    init_dotfiles || exit 1

    # --- Done ---

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

set -euo pipefail

trap 'bdb_handle_error' ERR
trap 'bdb_cleanup' EXIT

bdb_init_logging "${BDB_LOG_FILE}"

# =============================================================================
# START BOOTSTRAP
# =============================================================================

bdb_bootstrap

exit 0
