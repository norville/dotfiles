#!/usr/bin/env bash
# ensure new process is started

### BDF BOOT - bootstrap Bassa's Dot Files

{ # ensure download of entire script

    ## Define global variables

    PLATFORM="" # OS type
    DISTRO=""   # OS name
    ## Escape sequences for colored output
    ESC_SEQ="\x1b["
    RST_COL="${ESC_SEQ}39;49;00m" # reset
    RED_COL="${ESC_SEQ}31;01m"    # red
    GRN_COL="${ESC_SEQ}32;01m"    # green
    BLU_COL="${ESC_SEQ}34;01m"    # blue
    YLW_COL="${ESC_SEQ}33;01m"    # yellow
    CYN_COL="${ESC_SEQ}36;01m"    # cyan
    MGN_COL="${ESC_SEQ}35;01m"    # magenta
    WHT_COL="${ESC_SEQ}97;01m"    # white

    ## Define global functions

    ## Print success message
    bdb_success() {

        echo -en "\n${GRN_COL}|vvv| SUCCESS ${1:-"*** UNKNOWN ***"}. ${RST_COL}"

    }

    ## Print error message
    bdb_error() {

        echo -en "\n${RED_COL}|xxx| ERROR ${1:-"*** UNKNOWN ***"} ${RST_COL}"

    }

    ## Print alert message
    bdb_alert() {

        echo -en "\n${YLW_COL}|!!!| ${1} ${RST_COL}"

    }

    ## Print info message - begin
    bdb_info_in() {

        echo -en "${WHT_COL}"
        echo -en "\n|BDB| +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
        echo -en "\n|BDB|"
        echo -en "\n|BDB| ${1:-"*** UNKNOWN ***"}."
        echo -en "\n|BDB|"
        echo -en "${RST_COL}"

    }

    ## Print info message - end
    bdb_info_out() {

        echo -en "${WHT_COL}"
        echo -en "\n|BDB|"
        echo -en "\n|BDB| ${1:-"*** UNKNOWN ***"}."
        echo -en "\n|BDB|"
        echo -en "\n|BDB| ---------------------------------------------------------------------------------"
        echo -en "${RST_COL}"

    }

    ## Print run message
    bdb_run() {

        echo -en "\n${BLU_COL}|###| ${1:-"*** UNKNOWN ***"}...${RST_COL}"

    }

    ## Print outcome message
    bdb_outcome() {

        echo -en "${CYN_COL} ${1:-"*** UNKNOWN ***"}.${RST_COL}"

    }

    ## Print message before command
    bdb_command() {

        echo -e "\n${CYN_COL}|>>>| ${1:-"*** UNKNOWN ***"}:${RST_COL}"

    }

    ## Ask user yes/no, return 0 for yes (default: no)
    bdb_ask() {

        # Print prompt
        echo -en "${MGN_COL}"
        echo -en "\n|???|"
        echo -en "\n|???| ${1:-"*** UNKNOWN ***"} ? [y|N] >"
        echo -en "\n|???| "
        echo -en "${RST_COL}"

        # Read user input: suppress output, read 1 char
        read -s -r -n 1 response

        # If input = y/Y
        if [[ ${response} =~ (y|Y) ]]; then

            # Return success
            return 0

        fi

        # Default: return error
        return 1

    }

    ## Handle errors, clean up and exit
    bdb_handle_error() {

        err_value="${?}"
        err_command="${BASH_COMMAND}" # Last command string
        err_message="${1:-"UNKNOWN"}" # Message to print when manually invoked

        # TODO - cleanup: delete bare repo, tracked files and restore back up

        # Print error message and exit
        bdb_error "Command: <${err_command}>"
        bdb_error "Value: [${err_value}]"
        bdb_error "Message: '${err_message}'"
        bdb_error "Exiting now!"

        printf -- "\n"
        exit "${err_value}"

    }

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
    bdb_outcome "${PLATFORM}/${DISTRO}"

    # Install requirements
    case "${DISTRO}" in

    arch)

        # Update package list
        bdb_command "Installing Chezmoi"
        sudo pacman -Syu --noconfirm chezmoi
        bdb_success "installing Chezmoi"

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
            NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
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

    debian | ubuntu)

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

        # Chezmoi check
        bdb_command "Checking Chezmoi"
        if ! type snapd &>/dev/null; then
            # Install snapd
            bdb_outcome "Snap is missing"
            bdb_command "Installing Snap"
            sudo apt install -y snapd
            bdb_success "installing Snap"
        elif ! type chezmoi &>/dev/null; then
            # Install Chezmoi
            bdb_outcome "Chezmoi is missing"
            bdb_command "Installing Chezmoi"
            sudo snap install chezmoi --classic
            bdb_success "installing Chezmoi"
        else
            bdb_outcome "installed"
        fi

        ;;

    fedora)

        # Update RPM package list
        bdb_command "Updating RPM"
        sudo dnf -y upgrade --refresh
        bdb_success "updating RPM"

        # Chezmoi check
        bdb_command "Checking Chezmoi"
        if ! type snapd &>/dev/null; then
            # Install snapd
            bdb_outcome "Snap is missing"
            bdb_command "Installing Snap"
            sudo dnf -y install snapd
            sudo ln -s /var/lib/snapd/snap /snap
            bdb_success "installing Snap"
        elif ! type chezmoi &>/dev/null; then
            # Install Chezmoi
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

    # System ready
    bdb_info_out "All requirements installed, ready to clone your dotfiles"

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
