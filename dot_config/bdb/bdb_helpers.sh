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
    printf "\n%s|vvv| SUCCESS %s. %s" "${GRN_COL}" "${1:-*** UNKNOWN ***}" "${RST_COL}" | tee -a "$LOGFILE" > /dev/tty
}

# Print error message (red)
bdb_error() {
    printf "\n%s|xxx| ERROR %s %s" "${RED_COL}" "${1:-*** UNKNOWN ***}" "${RST_COL}" | tee -a "$LOGFILE" > /dev/tty
}

# Print alert message (yellow)
bdb_alert() {
    printf "\n%s|!!!| %s %s" "${YLW_COL}" "$1" "${RST_COL}" | tee -a "$LOGFILE" > /dev/tty
}

# Print info message - begin (white)
bdb_info_in() {
    printf "%s\n|BDB| +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++\n|BDB|\n|BDB| %s.\n|BDB|%s" "${WHT_COL}" "${1:-*** UNKNOWN ***}" "${RST_COL}" | tee -a "$LOGFILE" > /dev/tty
}

# Print info message (white)
bdb_info() {
    printf "%s\n|BDB|\n|BDB| %s.\n|BDB|%s" "${WHT_COL}" "${1:-*** UNKNOWN ***}" "${RST_COL}" | tee -a "$LOGFILE" > /dev/tty
}

# Print info message - end (white)
bdb_info_out() {
    printf "%s\n|BDB|\n|BDB| %s.\n|BDB|\n|BDB| ---------------------------------------------------------------------------------%s\n" "${WHT_COL}" "${1:-*** UNKNOWN ***}" "${RST_COL}" | tee -a "$LOGFILE" > /dev/tty
}

# Print run message (blue)
bdb_run() {
    printf "\n%s|###| %s...%s" "${BLU_COL}" "${1:-*** UNKNOWN ***}" "${RST_COL}" | tee -a "$LOGFILE" > /dev/tty
}

# Print outcome message (cyan)
bdb_outcome() {
    printf " %s%s.%s" "${CYN_COL}" "${1:-*** UNKNOWN ***}" "${RST_COL}" | tee -a "$LOGFILE" > /dev/tty
}

# Print message before command (cyan)
bdb_command() {
    printf "\n%s|>>>| %s:%s" "${CYN_COL}" "${1:-*** UNKNOWN ***}" "${RST_COL}" | tee -a "$LOGFILE" > /dev/tty
}

# Ask user yes/no, return 0 for yes (default: no)
bdb_ask() {
    printf "%s\n|???|\n|???| %s ? [y|N] >\n|???| %s" "${MGN_COL}" "${1:-*** UNKNOWN ***}" "${RST_COL}" | tee -a "$LOGFILE" > /dev/tty
    read -s -r -n 1 response < /dev/tty
    if [[ "${response:-}" =~ (y|Y) ]]; then
        return 0
    fi
    return 1
}

# Clean up temporary files and reset environment
bdb_cleanup() {
    bdb_info_in "Cleaning up temporary files and resetting environment"

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

    bdb_info_out "Cleanup complete, exiting now"
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
