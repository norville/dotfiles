#!/bin/bash

### BDF BOOT - bootstrap Bassa's Dot Files

### Define global environment

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

## Global variables

### Define functions

## Print success message
bdb_success() {

    echo -en "\n${GRN_COL}|vvv| SUCCESS ${1:-"*** UNKNOWN ***"} ${RST_COL}"

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
    echo -en "\n|BDB| ${1:-"*** UNKNOWN ***"}"
    echo -en "\n|BDB|"
    echo -en "${RST_COL}"

}

## Print info message - end
bdb_info_out() {

    echo -en "${WHT_COL}"
    echo -en "\n|BDB|"
    echo -en "\n|BDB| ${1:-"*** UNKNOWN ***"}"
    echo -en "\n|BDB|"
    echo -en "\n|BDB| ---------------------------------------------------------------------------------"
    echo -en "${RST_COL}"

}

## Print run message
bdb_run() {

    echo -en "\n${BLU_COL}|###| ${1:-"*** UNKNOWN ***"} ...${RST_COL}"

}

## Print outcome message
bdb_outcome() {

    echo -en "${CYN_COL} ${1:-"*** UNKNOWN ***"} ${RST_COL}"

}

## Print message before command
bdb_command() {

    echo -e "\n${CYN_COL}|>>>| ${1:-"*** UNKNOWN ***"} ${RST_COL}"

}

## Ask user yes/no, return 0 for yes (default: no)
bdb_ask() {

    # Print prompt
    echo -en "${MGN_COL}"
    echo -en "\n|???|"
    echo -en "\n|???| ${1:-"*** UNKNOWN ***"}? [y|N] >"
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

## Print help message and exit
bdb_usage() {

    # Print error message if passed
    [[ "$2" ]] && {
        bdb_alert "error: $2"
        bdb_alert ""
    }
    bdb_alert "usage: ${PROGNAME} [<option> ...]"
    bdb_alert ""
    bdb_alert "       ${PROGNAME} [-h]"
    bdb_alert "       ${PROGNAME} [-f] [-s|-v] [-l <logfile>]"
    bdb_alert "       ${PROGNAME} [-r|-a|-e|-u] [-s|-v] [-l <logfile>]"
    bdb_alert ""
    bdb_alert "options: -h           : Print this message and exit"
    bdb_alert "         -f           : Full bootstrap"
    bdb_alert "         -r           : Bootstrap dotfiles repository"
    bdb_alert "         -a           : Bootstrap required applications"
    bdb_alert "         -e           : Bootstrap user environment"
    bdb_alert "         -u           : Upgrade local system"
    bdb_alert "         -s           : Silence all terminal output"
    bdb_alert "         -v           : Send all output terminal"
    bdb_alert "         -l <logfile> : Send all output to <logfile>"
    bdb_alert "                        (default: ${LOGFILE})"

    # Exit with passed value
    exit "$1"

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

## Check the system and prepare for bootstrap
bdb_do_sys() {

    bdb_info_in "[SYS] detect local system and prepare for bootstrap"

    # Get admin privileges
    bdb_run "Getting admin privileges"
    #TODO no newline after password input
    sudo -v

    # Detect local system
    bdb_run "Detecting local system"
    # Path to Linux Standard Base infos
    lsb_path="/etc/os-release"
    # If LSB file exists
    if [[ -f "${lsb_path}" ]]; then

        # LSB found, get Linux name
        SYSTEM="$(grep -e '^ID=' ${lsb_path} | cut -d '=' -f 2)"

    else

        # LSB not found, assume macOS
        SYSTEM="macos"

    fi
    bdb_outcome "${SYSTEM}"

    bdb_run "Preparing to bootstrap"
    case "${SYSTEM}" in
    ubuntu | debian | raspbian) DISTRO="debian" ;;
    manjaro* | arch) DISTRO="arch" ;;
    macos) DISTRO="darwin" ;;
    *) DISTRO="unknown" ;;
    esac
    bdb_outcome "${DISTRO}"

    # Prepare local system
    case "${DISTRO}" in
    arch)   # System is Arch
        bdb_command "Updating Pacman"
        sudo pacman -Syy
        bdb_success "updating Pacman"
        ;;

    darwin) # System is macOS
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
            # on 10.9+, we can leverage SUS to get the latest CLI tools
            # create the placeholder file that's checked by CLI updates' .dist code
            # in Apple's SUS catalog
            touch /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress
            # find the CLI Tools update
            clt_package="$(softwareupdate -l | grep '.*Command Line' | awk -F ":" '{print $2}' | sed -e 's/^ *//' | tr -d '\n')"
            # install it
            softwareupdate -i "${clt_package}"
            bdb_success "installing CLT"

        fi

        # brew check
        bdb_run "Checking Homebrew"
        # If brew is missing
        if ! type brew &>/dev/null; then

            # Install homebrew
            bdb_outcome "missing"
            brew_url="https://raw.githubusercontent.com/Homebrew/install/master/install.sh"
            bdb_command "Installing Homebrew"
            CI=1 /bin/bash -c "$(curl -fsSL ${brew_url})" # bot mode: CI=1
            bdb_success "installing Homebrew"

        else

            # Update homebrew
            bdb_outcome "installed"
            bdb_command "Updating Homebrew"
            brew update
            bdb_success "updating Homebrew"

        fi

        # Mac App Store login
        if ! type mas &>/dev/null; then
            brew install mas
        fi
        bdb_command "Signing in Mac App Store"
        mas signin bassanimarco79@gmail.com
        bdb_success "signing in Mac App Store"

        ;;

    debian) # System is Debian
        bdb_command "Updating APT"
        sudo apt-get update
        bdb_success "updating APT"

        bdb_run "Checking git"
        # If git is missing
        if ! type git &>/dev/null; then

            #Install git
            bdb_outcome "missing"
            bdb_command "Installing git"
            sudo apt-get install -y git
            bdb_success "installing git"

        else

            bdb_outcome "installed"

        fi
        ;;

    *) # System is UNKNOWN
        bdb_handle_error "[SYS] Cannot detect local system"
        ;;
    esac

    bdb_info_out "[SYS] system ready"

}

## Check dotfiles repo
bdb_do_repo() {

    bdb_info_in "[REPO] detect dotfiles or clone remote repository"

    bdb_run "Checking dotfiles repository"
    # Set bare repo dir
    repo_path="${HOME}/.bdf.git"
    mkdir -p "${repo_path}"
    # If bare repo is missing
    if ! git --git-dir="${repo_path}" rev-parse --is-bare-repository &>/dev/null; then

        bdb_outcome "missing"
        # Fresh system
        _FRESH_="true"

        # Clone remote repo into bare repo
        bdb_command "Cloning dotfiles into a bare repo"
        git clone --bare "${REPO_URL_HTTPS}" "${repo_path}"               # Clone main branch
        #git clone --bare -b <git-branch> ${repo_url} ${repo_path}  # Clone specifc branch
        bdb_success "cloning dotfiles into <${repo_path}>"

        # Backup existing dotfiles
        #trap "" ERR # disable ERR handling
        # checkout repo and save file names of existing dotfiles
        backup_list=$(
            git --git-dir="${repo_path}" --work-tree="${HOME}" checkout 2>&1 | grep -E "\s+\." | awk {'print $1'}
        )
        trap - ERR  # reset ERR handling
        if [[ ${backup_list} ]]; then
            bdb_command "Backing up existing dotfiles"
            backup_path="${HOME}/.bdf.bak"
            mkdir -p "${backup_path}"
            mv ${backup_list} "${backup_path}"/     # NO QUOTES PLEASE - ensure variable expansion
            bdb_success "backing up existing dotfiles"
        fi

        bdb_command "Checking out repository"
        git --git-dir="${repo_path}" --work-tree="${HOME}" checkout -f
        bdb_success "checking out repository"

        # Configure repo
        bdb_command "Configuring repository"
        # Set remote url
        #git --git-dir="${repo_path}" --work-tree="${HOME}" config remote.origin.url "${repo_url}"
        #git --git-dir="${repo_path}" --work-tree="${HOME}" config remote.origin.pushurl "${repo_url}"
        # Show all untracked files
        git --git-dir="${repo_path}" --work-tree="${HOME}" config status.showUntrackedFiles all
        bdb_success "configuring repository"

    else

        # Repo ok
        #TODO sync with remote, handle local changes
        bdb_outcome "ready"

    fi

    bdb_info_out "[REPO] dotfiles ready"

}

## Install or update packages
bdb_do_apps() {

    bdb_info_in "[APPS] bootstrap applications"

    # Detect system
    [[ "${SYSTEM}" != "macos" ]] && pkgs="$(xargs -a <(awk '! /^ *(#|$)/' "${CONF_DIR}/pkgfile") -r)" || pkgs=""
    case "${DISTRO}" in

    arch) # System is Arch

        # Install or update required packages via Pacman
        bdb_command "Installing Arch packages: <${pkgs}>"
        sudo pacman --noconfirm --needed -S ${pkgs} # NO QUOTES PLEASE - ensure variable expansion
        bdb_success "installing Arch packages"

        # Cleanup
        bdb_command "Cleaning Pacman cache"
        sudo pacman --noconfirm -Scc
        bdb_success "cleaning Pacman cache"

        ;;

    darwin) # System is macOS

        # Install brew bundles
        brewfile_path="${CONF_DIR}/brewfile"
        bdb_command "Installing required formulae from <${brewfile_path}>"
        brew bundle install --file="${brewfile_path}"
        bdb_success "installing required formulae"

        bdb_run "Looking for formulas already installed"
        # If extra formulae are installed
        if [[ "$(brew bundle cleanup --file="${brewfile_path}")" ]]; then

            bdb_outcome "found"
            (bdb_ask "uninstall extra formulae" && { # Yes (true)

                # Delete extra formulae
                bdb_command "Removing extra formulae"
                brew bundle cleanup --file="${brewfile_path}" --force
                bdb_success "removing extra formulae"

            }) || { # No (false)

                # Upgrade all formulae
                bdb_command "Upgrading all formulae"
                brew upgrade
                bdb_success "upgrading all formulae"

            }

        else

            bdb_outcome "not found"

        fi

        # Cleanup
        bdb_command "Cleaning Homebrew"
        brew cleanup
        bdb_success "cleaning Homebrew"

        ;;

    debian) # System is Debian

        # Install or update required packages via APT
        bdb_command "Installing APT packages: <${pkgs}>"
        sudo apt-get install -y ${pkgs} # NO QUOTES PLEASE - ensure variable expansion
        bdb_success "installing APT packages"

        # Cleanup
        bdb_command "Cleaning APT cache"
        sudo apt autoremove
        sudo apt autoclean
        bdb_success "cleaning APT cache"

        ;;

    *) # System is UNKNOWN
        bdb_handle_error "[APPS] Unknown system <${DISTRO}>"
        ;;

    esac

    bdb_info_out "[APPS] applications ready"

}

## Upgrade local system
bdb_do_upgrade() {

    bdb_info_in "Upgrade local system"

    case "${DISTRO}" in

    arch) # System is Arch
        bdb_command "Upgrading Arch system"
        sudo pacman --noconfirm -Syu
        bdb_success "upgrading Arch system"
        ;;
    darwin) # System is macOS
        bdb_command "Upgrading macOS system"
        sudo softwareupdate -ia
        bdb_success "upgrading macOS system"
        ;;
    debian) # System is Debian
        bdb_command "Upgrading Debian system"
        sudo apt upgrade -y
        bdb_success "upgrading Debian system"
        ;;

    *) # System is UNKNOWN
        bdb_handle_error "[UPGRADE] Unknown system <${DISTRO}>"
        ;;

    esac

    bdb_info_out "System upgraded."

}

## Configure user environment
bdb_do_env() {

    #TODO rewrite all function

    bdb_info_in "[ENV] configure user environment"

    bdb_run "Checking ZSH as your login shell"
    zsh_path="$(which zsh)"
    # If zsh is not the login shell
    if [[ "${SHELL}" != "${zsh_path}" ]]; then

        bdb_outcome "not set"
        # Set zsh as login shell
        bdb_command "Switching to ZSH"
        echo "${zsh_path}" | sudo tee -a /etc/shells
        sudo chsh -s "${zsh_path}" "${USER}"
        bdb_success "switching to ZSH"

    else

        # Zsh is the login shell
        bdb_outcome "set"

    fi

    #TOD move to upgrade
    # Delete Antigen dir to force cloning
    bdb_run "Checking Antigen as ZSH plugin manager"
    antigen_dir="${HOME}/.antigen"
    if [[ -d "${antigen_dir}" ]]; then

        bdb_outcome "ready"
        rm -rf "${antigen_dir}"

    else

        bdb_outcome "missing"

    fi

    #TOD move to upgrade
    # Delete Vundle dir to force cloning
    bdb_run "Checking Vundle as VIM plugin manager"
    vundle_path="${HOME}/.vim/bundle"
    if [[ -d "${vundle_path}/Vundle.vim" ]]; then

        bdb_outcome "ready"
        rm -rf "${vundle_path}"

    else

        bdb_outcome "missing"

    fi

    #Restore user preferences
    case "${DISTRO}" in
    arch) # System is Arch

        # # Install nerd fonts for p10k
        # # Set variables
        # font_path="${HOME}/.local/share/fonts"
        # fura_name="Fura Mono Regular Nerd Font.otf"
        # meslo_name="Meslo LG S Regular Nerd Font.ttf"
        # fura_url="https://github.com/ryanoasis/nerd-fonts/raw/master/patched-fonts/FiraMono/Regular/complete/Fura%20Mono%20Regular%20Nerd%20Font%20Complete.otf"
        # meslo_url="https://github.com/ryanoasis/nerd-fonts/raw/master/patched-fonts/Meslo/S/Regular/complete/Meslo%20LG%20S%20Regular%20Nerd%20Font%20Complete.ttf"

        # # Download fonts
        # mkdir -p "${font_path}"
        # bdb_command "Installing ${fura_name}"
        # curl -fLo "${font_path}/${fura_name}" "${fura_url}"
        # bdb_success "installing ${fura_name}"
        # bdb_command "Installing ${meslo_name}"
        # curl -fLo "${font_path}/${meslo_name}" "${meslo_url}"
        # bdb_success "installing ${meslo_name}"

        # # Update fonts cach
        # bdb_command "Updating fonts cache"
        # fc-cache -f
        # bdb_success "updating fonts cache"

        # # Install Gruvbox theme for Tilix
        # bdb_command "Installing Gruvbox theme"
        # # Clone custom tilix-gruvbox repo
        # git clone https://github.com/MichaelThessel/tilix-gruvbox.git
        # cd tilix-gruvbox
        # sudo cp gruvbox-* /usr/share/tilix/schemes
        # cd ..
        # rm -rf tilix-gruvbox
        # bdb_success "installing Gruvbox theme"

        # # Restore Tilix preferences
        # bdb_command "Loading dconf profile"
        # dconf load /com/gexperts/Tilix/ <"${CONF_DIR}/tilix.dconf"
        # bdb_success "loading dconf profile"

        #TODO GNU Stow or mackup

        ;;

    darwin) # System is macOS

        # # If this is a fresh system
        # if [[ "${_FRESH_}" ]]; then

        #     # Set macos defaults
        #     bdb_command "Restoring macOS preferences"
        #     #macos_prefs="${HOME}/bin/macos_defaults"
        #     #[[ -f "${macos_prefs}" ]] || bdb_handle_error "Invalid file: ${macos_prefs}"
        #     source "${HOME}/bin/macos_defaults"
        #     bdb_success "restoring macOS preferences"

        #     # Restore preferences via mackup
        #     bdb_command "Restoring App preferences"
        #     #type mackup &>/dev/null || bdb_handle_error "Invalid command: <mackup>"
        #     mackup restore
        #     bdb_success "restoring App preferences"

        # fi

        # # Restore VSCode extensions
        # bdb_run "Checking VSCode extensions"
        # ext_path="${CONF_DIR}/vscode-ext"
        # # If no extensions installed and extensions file exists
        # if [[ ! "$(code --list-extensions)" && -f "${ext_path}" ]]; then

        #     bdb_outcome "missing"
        #     bdb_command "Installing VSCode extensions"
        #     cat "${ext_path}" | xargs -n 1 code --install-extension
        #     bdb_success "installing VSCode extensions"

        # else

        #     bdb_outcome "ready"

        # fi

        ;;

    debian) # System is Debian
        ;;

    *) # System is UNKNOWN

        bdb_handle_error "[ENV] Unknown system <${DISTRO}>"
        ;;

    esac

    bdb_info_out "[ENV] user environment ready"

}

### Define set builtins and signals to trap

# Catch error signals
trap "bdb_handle_error" ERR

set -o errtrace # (-E) Catch any ERR trap
set -o errexit  # (-e) Exit immediatly if last command returns non-zero
set -o nounset  # (-u) Exit immediatly if expanding unset variable
set -o pipefail # Exit if a pipeline's commands returns non-zero
