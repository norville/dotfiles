# shellcheck disable=SC2148

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
    printf "\n%s|vvv| SUCCESS %s. %s" "${GRN_COL}" "${1:-*** UNKNOWN ***}" "${RST_COL}" >&3
}

# Print error message (red)
bdb_error() {
    printf "\n%s|xxx| ERROR %s %s" "${RED_COL}" "${1:-*** UNKNOWN ***}" "${RST_COL}" >&3
}

# Print alert message (yellow)
bdb_alert() {
    printf "\n%s|!!!| %s %s" "${YLW_COL}" "$1" "${RST_COL}" >&3
}

# Print info message - begin (white)
bdb_info_in() {
    printf "%s\n|BDB| +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++\n|BDB|\n|BDB| %s.\n|BDB|%s" "${WHT_COL}" "${1:-*** UNKNOWN ***}" "${RST_COL}" >&3
}

# Print info message (white)
bdb_info() {
    printf "%s\n|BDB|\n|BDB| %s.\n|BDB|%s" "${WHT_COL}" "${1:-*** UNKNOWN ***}" "${RST_COL}" >&3
}

# Print info message - end (white)
bdb_info_out() {
    printf "%s\n|BDB|\n|BDB| %s.\n|BDB|\n|BDB| ---------------------------------------------------------------------------------%s\n" "${WHT_COL}" "${1:-*** UNKNOWN ***}" "${RST_COL}" >&3
}

# Print run message (blue)
bdb_run() {
    printf "\n%s|###| %s...%s" "${BLU_COL}" "${1:-*** UNKNOWN ***}" "${RST_COL}" >&3
}

# Print outcome message (cyan)
bdb_outcome() {
    printf " %s%s.%s" "${CYN_COL}" "${1:-*** UNKNOWN ***}" "${RST_COL}" >&3
}

# Print message before command (cyan)
bdb_command() {
    printf "\n%s|>>>| %s:%s" "${CYN_COL}" "${1:-*** UNKNOWN ***}" "${RST_COL}" >&3
}

# Ask user yes/no, return 0 for yes (default: no)
bdb_ask() {
    printf "%s\n|???|\n|???| %s ? [y|N] >\n|???| %s" "${MGN_COL}" "${1:-*** UNKNOWN ***}" "${RST_COL}" >&3
    read -s -r -n 1 response < /dev/tty
    if [[ "${response:-}" =~ (y|Y) ]]; then
        return 0
    fi
    return 1
}

# Print timestamp (for logging)
bdb_timestamp() {
    { set +x; } 2>/dev/null
    printf "\n[%s] " "$(date '+%Y-%m-%d %H:%M:%S')"
    set -x
}

# Clean up temporary files and reset environment
bdb_cleanup() {
    bdb_info "Cleaning up temporary files and resetting environment"

    # Remove temporary files
    if [[ -f "${BDB_HELPERS}" ]]; then
        bdb_run "Removing temp file"
        rm -f "${BDB_HELPERS}"
        bdb_outcome "${BDB_HELPERS}"
    fi

    # Reset environment variables if needed
    unset BDB_HELPERS_URL
    unset BDB_HELPERS
    unset CURRENT_DIR
    unset LOGFILE

    # Disable command tracing and error handling
    set +xeuo pipefail

    # Reset stdout and stderr to original state
    exec 1>&3 2>&1  # Redirect stdout and stderr back to original
    exec 3>&-       # Close FD 3

    printf "\n"
}

# Handle errors, clean up and exit
bdb_handle_error() {
    local err_value="$?"                    # Last command exit value
    local err_command="$BASH_COMMAND"       # Last command string
    local err_message="${1:-UNKNOWN}"       # Optional error message
    bdb_error "Command: <${err_command}>"
    bdb_error "Value:   [${err_value}]"
    bdb_error "Message: '${err_message}'"
    exit "${err_value}"
}
