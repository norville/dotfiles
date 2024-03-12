# shellcheck shell=bash

### Define vars and functions

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
BREW_URL="https://raw.githubusercontent.com/Homebrew/install/master/install.sh"


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
