#!/usr/bin/env bash
# ensure new process is started

### BDF BOOT - bootstrap Bassa's Dot Files

{ # ensure download of entire script

    ### Include vars and functions
    #shellcheck source=include.sh
    source include.sh

    ## Global variables
    PLATFORM="" # OS type
    DISTRO=""   # OS name

    ### Define set builtins and signals to trap

    # Catch error signals
    trap "bdb_handle_error" ERR

    set -o errtrace # (-E) Catch any ERR trap
    set -o errexit  # (-e) Exit immediatly if last command returns non-zero
    set -o nounset  # (-u) Exit immediatly if expanding unset variable
    set -o pipefail # Exit if a pipeline's commands returns non-zero

    ### Bootstrap begin
    bdb_info_in "Welcome to Bassa Dotfiles Bootstrapper (BDB)"

    # Check the system and install requirements
    bdb_info_in "This script will detect the operating system and install all requirements to clone your dotfiles"

    # Get admin privileges
    bdb_run "Getting admin privileges"
    #TODO no newline after password input
    sudo -v

    # Detect OS
    bdb_run "Detecting operating system"
    # OS type check
    PLATFORM="$(uname)"
    case "${PLATFORM}" in
    Darwin)
        DISTRO="macos"
        ;;
    Linux)
        # LSB check
        lsb_path="/etc/os-release"
        if [[ -f "${lsb_path}" ]]; then
            # If LSB file exists, get distro name
            DISTRO="$(grep -e '^ID=' ${lsb_path} | cut -d '=' -f 2)"
        fi
        ;;
    *)
        bdb_handle_error "Cannot detect OS type"
        ;;
    esac
    bdb_outcome "${DISTRO}/${PLATFORM}"

    # Install requirements
    case "${DISTRO}" in

    arch)

        # Update package list
        bdb_command "Updating Pacman"
        sudo pacman -Syy
        bdb_success "updating Pacman"

        #TODO install chezmoi

        ;;

    macos)

        # CLT check
        bdb_run "Checking Xcode Command Line Tools"
        if type xcode-select &>/dev/null &&
            clt_path="$(xcode-select --print-path &>/dev/null)" &&
            test -d "${clt_path}" &&
            test -x "${clt_path}"; then
            # CLT installed
            bdb_outcome "installed"
        else
            # CLT not installed
            bdb_outcome "missing"
            bdb_command "Installing CLT"
            # Download CLT
            touch /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress
            # shellcheck disable=SC2063
            clt_package="$(softwareupdate -l | grep '*.*Command Line' | awk -F ":" '{print $2}' | sed -e 's/^ *//' | tr -d '\n')"
            # Install CLT
            softwareupdate -i "${clt_package}"
            bdb_success "installing CLT"
        fi

        # Homebrew check
        bdb_run "Checking Homebrew"
        if ! type brew &>/dev/null; then
            # Install homebrew
            bdb_outcome "missing"
            bdb_command "Installing Homebrew"
            NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL ${BREW_URL})"
            bdb_success "installing Homebrew"
        else
            # Update Homebrew
            bdb_outcome "installed"
            bdb_command "Updating Homebrew"
            brew update
            bdb_success "updating Homebrew"
        fi

        # Install Chezmoi
        bdb_command "Installing Chezmoi"
        brew install chezmoi
        bdb_success "installing Chezmoi"

        ;;

    debian)

        # Update APT package list
        bdb_command "Updating APT"
        sudo apt update
        bdb_success "updating APT"

        # Git check
        bdb_run "Checking git"
        if ! type git &>/dev/null; then
            # Install git
            bdb_outcome "missing"
            bdb_command "Installing git"
            sudo apt install -y git
            bdb_success "installing git"
        else
            bdb_outcome "installed"
        fi

        # Install Chezmoi
        bdb_command "Installing Chezmoi"
        sudo sh -c "$(wget -qO- get.chezmoi.io)" -- -b /usr/local/bin
        bdb_success "installing Chezmoi"

        ;;

    fedora)

        # Update RPM package list
        bdb_command "Updating RPM"
        sudo dnf -y upgrade --refresh
        bdb_success "updating RPM"

        #TODO install chezmoi

        ;;

    *)
        bdb_handle_error "Cannot detect OS type"
        ;;

    esac

    # System ready
    bdb_info_out "All requirements installed, ready to clone your dotfiles"

    # SSH keys alert
    bdb_alert ""
    bdb_alert "Before cloning remeber to setup your SSH identities:"
    bdb_alert "1. upload/generate keys (e.g.: ssh-keygen -t ed25519 [-N 'passphrase'] [-C 'comment'] -f ~/.ssh/<id_file>)"
    bdb_alert "2. copy identities (e.g.: ssh-copy-id [-p <port_num>] -i <id_file> [user@]host)"
    bdb_alert ""

    # Clone dotfiles now?
    if bdb_ask "Do you want to clone the dotfiles now"; then

        # Clone dotfiles via Chezmoi
        bdb_command "Cloning dotfiles"
        chezmoi init --apply norville
        bdb_success "cloning dotfiles"

    else

        # Do not clone dotfiles
        bdb_info_in "Clone your dotfiles anytime with command 'chezmoi init --apply <github_username>'"

    fi

    ### Bootstrap end

    # Close this session
    bdb_info_out "Please logout and log back in to load your dotfiles"
    printf -- "\n"
    exit 0

} # ensure download of entire script
