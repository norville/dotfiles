#!/usr/bin/env bash
# =============================================================================
# BDB Helper Functions
# =============================================================================
# Utility functions for Bassa's Dotfiles Bootstrapper.
# Provides colored terminal output, comprehensive logging, and command helpers.
#
# All user-facing output goes to FD3; stdout/stderr are redirected to the log
# file by bdb_init_logging so command output never leaks to the terminal.
# =============================================================================

# shellcheck disable=SC2148

# =============================================================================
# COLOR DEFINITIONS
# =============================================================================
# ANSI escape sequences. Format: \033[<style>;<color>m
#   Style: 1=bold   Color: 31=red, 32=green, 33=yellow, 35=magenta, 36=cyan, 97=bright white

readonly C_RST=$'\033[0m'      # Reset
readonly C_RED=$'\033[31;1m'   # Red Bold
readonly C_GRN=$'\033[32;1m'   # Green Bold
readonly C_YLW=$'\033[33;1m'   # Yellow Bold
readonly C_MAG=$'\033[35;1m'   # Magenta Bold
readonly C_CYN=$'\033[36;1m'   # Cyan Bold
readonly C_WHT=$'\033[97;1m'   # Bright White Bold

readonly ICON_OK="✓"
readonly ICON_ERR="✗"
readonly ICON_WARN="!"
readonly ICON_INFO="•"
readonly ICON_PROMPT="?"
readonly ICON_ARROW="→"

# =============================================================================
# LOGGING FUNCTIONS
# =============================================================================

# Used with DEBUG trap. Toggle set -x around the timestamp write to prevent
# the trap from recursively logging itself.
_bdb_log_timestamp() {
    { set +x; } 2>/dev/null
    printf "[%s] " "$(date '+%Y-%m-%d %H:%M:%S')" >&1
    set -x 2>/dev/null
}

# Timestamps on section markers and key events only; other lines get [LOG] prefix.
_bdb_log() {
    local message="$*"
    if [[ "$message" =~ ^===+$ ]] || \
       [[ "$message" =~ SECTION:|Script:|Action:|SUCCESS:|ERROR:|Command: ]]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] [LOG] $message" >&1
    else
        echo "[LOG] $message" >&1
    fi
}

_bdb_log_cmd() {
    local desc="$1"
    shift
    _bdb_log "Running: $*"
    _bdb_log "Description: ${desc}"
    if "$@" >&1 2>&1; then
        _bdb_log "Command completed successfully"
        return 0
    else
        local exit_code=$?
        _bdb_log "Command failed with exit code: ${exit_code}"
        return ${exit_code}
    fi
}

# =============================================================================
# TERMINAL OUTPUT FUNCTIONS
# =============================================================================
# All output goes to FD3 (terminal), not stdout (log file).

bdb_action() {
    printf "%s%s %s%s\n" "${C_CYN}" "${ICON_ARROW}" "$*" "${C_RST}" >&3
    _bdb_log "Action: $*"
}

bdb_success() {
    printf "%s%s %s%s\n" "${C_GRN}" "${ICON_OK}" "$*" "${C_RST}" >&3
    _bdb_log "SUCCESS: $*"
}

bdb_error() {
    printf "%s%s %s%s\n" "${C_RED}" "${ICON_ERR}" "$*" "${C_RST}" >&3
    _bdb_log "ERROR: $*"
}

bdb_warn() {
    printf "%s%s %s%s\n" "${C_YLW}" "${ICON_WARN}" "$*" "${C_RST}" >&3
    _bdb_log "WARN: $*"
}

bdb_info() {
    printf "%s%s %s%s\n" "${C_WHT}" "${ICON_INFO}" "$*" "${C_RST}" >&3
    _bdb_log "INFO: $*"
}

bdb_header() {
    local text="$*"
    local width=80
    local padding=$(( (width - ${#text} - 2) / 2 ))

    printf "\n%s" "${C_WHT}" >&3
    printf "═%.0s" {1..80} >&3
    printf "\n" >&3
    printf "%*s%s%*s\n" ${padding} "" "${text}" ${padding} "" >&3
    printf "═%.0s" {1..80} >&3
    printf "%s\n\n" "${C_RST}" >&3
}

bdb_footer() {
    printf "\n%s" "${C_WHT}" >&3
    printf "─%.0s" {1..80} >&3
    printf "%s\n\n" "${C_RST}" >&3
}

# =============================================================================
# USER INTERACTION FUNCTIONS
# =============================================================================
# Prompts read from /dev/tty so they work even when stdin is redirected.

# Default: No — user must type y/Y to confirm
bdb_ask() {
    local response
    printf "%s%s %s [y/N]: %s" "${C_MAG}" "${ICON_PROMPT}" "$*" "${C_RST}" >&3
    read -r response < /dev/tty
    _bdb_log "User prompt: $* - Response: ${response:-N}"
    [[ "${response}" =~ ^[yY]$ ]]
}

# Default: Yes — user must type n/N to decline
bdb_ask_yes() {
    local response
    printf "%s%s %s [Y/n]: %s" "${C_MAG}" "${ICON_PROMPT}" "$*" "${C_RST}" >&3
    read -r response < /dev/tty
    _bdb_log "User prompt: $* - Response: ${response:-Y}"
    [[ ! "${response}" =~ ^[nN]$ ]]
}

bdb_input() {
    local response
    printf "%s%s %s: %s" "${C_MAG}" "${ICON_PROMPT}" "$*" "${C_RST}" >&3
    read -r response < /dev/tty
    _bdb_log "User input: $* - Response: ${response}"
    echo "${response}"
}

# =============================================================================
# COMMAND EXECUTION FUNCTIONS
# =============================================================================

# Show action, run command, report success or failure
bdb_exec() {
    local description="$1"
    shift
    bdb_action "${description}"
    _bdb_log "========================================="
    _bdb_log "Action: ${description}"
    _bdb_log "Command: $*"
    _bdb_log "========================================="
    if "$@" >&1 2>&1; then
        bdb_success "${description}"
        _bdb_log "Success: ${description}"
        return 0
    else
        local exit_code=$?
        bdb_error "${description} (exit code: ${exit_code})"
        _bdb_log "Error: ${description} failed with exit code ${exit_code}"
        return ${exit_code}
    fi
}

# Run command silently; show only the final result (not the action first)
bdb_run() {
    local description="$1"
    shift
    _bdb_log "========================================="
    _bdb_log "Check: ${description}"
    _bdb_log "Command: $*"
    _bdb_log "========================================="
    if "$@" >&1 2>&1; then
        bdb_success "${description}"
        _bdb_log "Success: ${description}"
        return 0
    else
        local exit_code=$?
        bdb_error "${description}"
        _bdb_log "Failed: ${description} (exit code: ${exit_code})"
        return ${exit_code}
    fi
}

# Show info (not success/error) since this is a test, not an operation
bdb_test_cmd() {
    local cmd="$1"
    if command -v "${cmd}" >/dev/null 2>&1; then
        bdb_info "Found: ${cmd}"
        _bdb_log "Command exists: ${cmd}"
        return 0
    else
        bdb_info "Not found: ${cmd}"
        _bdb_log "Command not found: ${cmd}"
        return 1
    fi
}

bdb_test_path() {
    local path="$1"
    if [[ -e "${path}" ]]; then
        if [[ -f "${path}" ]]; then
            bdb_info "File exists: ${path}"
            _bdb_log "File exists: ${path}"
        elif [[ -d "${path}" ]]; then
            bdb_info "Directory exists: ${path}"
            _bdb_log "Directory exists: ${path}"
        else
            bdb_info "Path exists: ${path}"
            _bdb_log "Path exists: ${path}"
        fi
        return 0
    else
        bdb_info "Not found: ${path}"
        _bdb_log "Path not found: ${path}"
        return 1
    fi
}

bdb_var() {
    local name="$1"
    local value="$2"
    bdb_info "${name}: ${value}"
    _bdb_log "Variable: ${name}=${value}"
}

# =============================================================================
# UTILITY FUNCTIONS
# =============================================================================

bdb_mkdir() {
    local dir="$1"
    local error_msg="${2:-Failed to create directory: ${dir}}"
    if [[ -d "${dir}" ]]; then
        _bdb_log "Directory already exists: ${dir}"
        return 0
    fi
    _bdb_log "Creating directory: ${dir}"
    if mkdir -p "${dir}" 2>&1 | tee -a /dev/fd/1 >/dev/null; then
        _bdb_log "Directory created: ${dir}"
        return 0
    else
        bdb_error "${error_msg}"
        _bdb_log "Failed to create directory: ${dir}"
        return 1
    fi
}

# Try curl first, fall back to wget
bdb_download() {
    local url="$1"
    local output="$2"
    _bdb_log "Downloading: ${url} -> ${output}"
    if command -v curl >/dev/null 2>&1; then
        _bdb_log "Using curl"
        if curl -fsSL "${url}" -o "${output}" 2>&1 | tee -a /dev/fd/1 >/dev/null; then
            _bdb_log "Download successful"
            return 0
        fi
    elif command -v wget >/dev/null 2>&1; then
        _bdb_log "Using wget"
        if wget -qO "${output}" "${url}" 2>&1 | tee -a /dev/fd/1 >/dev/null; then
            _bdb_log "Download successful"
            return 0
        fi
    else
        bdb_error "Neither curl nor wget available"
        _bdb_log "Error: No download tool available"
        return 1
    fi
    bdb_error "Download failed: ${url}"
    _bdb_log "Error: Download failed"
    return 1
}

# Silent command check — use bdb_test_cmd when user-visible feedback is needed
bdb_has_cmd() {
    command -v "$1" >/dev/null 2>&1
}

bdb_require() {
    local cmd="$1"
    local msg="${2:-Command required but not found: ${cmd}}"
    if ! bdb_has_cmd "${cmd}"; then
        bdb_error "${msg}"
        _bdb_log "Fatal: Required command not found: ${cmd}"
        exit 1
    fi
}

# =============================================================================
# ERROR HANDLING
# =============================================================================
# bdb_handle_error registered via: trap 'bdb_handle_error' ERR
# bdb_cleanup      registered via: trap 'bdb_cleanup'      EXIT

bdb_handle_error() {
    local exit_code=$?
    local cmd="${BASH_COMMAND}"
    { set +x; } 2>/dev/null
    _bdb_log "========================================="
    _bdb_log "ERROR OCCURRED"
    _bdb_log "Exit code: ${exit_code}"
    _bdb_log "Command: ${cmd}"
    _bdb_log "Line: ${BASH_LINENO[0]}"
    _bdb_log "========================================="
    bdb_error "Script failed (exit code: ${exit_code})"
    bdb_info "Check log file for details: ${BDB_LOG_FILE:-bdb.log}"
    exit "${exit_code}"
}

bdb_cleanup() {
    { set +x; } 2>/dev/null
    _bdb_log "========================================="
    _bdb_log "Cleanup started"
    _bdb_log "========================================="

    if [[ -n "${BDB_TEMP_FILES:-}" ]]; then
        for file in ${BDB_TEMP_FILES}; do
            if [[ -f "${file}" ]]; then
                rm -f "${file}" 2>/dev/null || true
                _bdb_log "Removed temporary file: ${file}"
            fi
        done
    fi

    # unset -v handles readonly variables gracefully (2>/dev/null || true)
    {
        unset -v BDB_HELPERS_URL 2>/dev/null || true
        unset -v BDB_HELPERS 2>/dev/null || true
        unset -v BDB_SCRIPT_DIR 2>/dev/null || true
        unset -v BDB_LOG_FILE 2>/dev/null || true
        unset -v BDB_TEMP_FILES 2>/dev/null || true
    } 2>/dev/null

    set +euo pipefail 2>/dev/null

    if [[ -t 3 ]]; then
        exec 1>&3 2>&1
        exec 3>&-
    fi

    _bdb_log "Cleanup complete"
}

# =============================================================================
# SECTION HELPERS
# =============================================================================

bdb_begin_section() {
    bdb_header "$*"
    _bdb_log "========================================="
    _bdb_log "SECTION: $*"
    _bdb_log "========================================="
}

bdb_end_section() {
    bdb_footer
    _bdb_log "========================================="
    _bdb_log "SECTION END"
    _bdb_log "========================================="
}

bdb_progress() {
    local current="$1"
    local total="$2"
    local description="$3"
    printf "%s[%d/%d] %s%s\n" "${C_CYN}" "${current}" "${total}" "${description}" "${C_RST}" >&3
    _bdb_log "Progress: [${current}/${total}] ${description}"
}

# =============================================================================
# INITIALIZATION
# =============================================================================

# Initialize the dual-output logging system. Must be called before any other
# bdb_* function. Idempotent: if BDB_LOG_FILE is already set and FD3 is open
# (a parent bootstrap script already called this), re-initialization is skipped
# so chezmoi scripts can share the bootstrap's log session.
bdb_init_logging() {
    if [[ -n "${BDB_LOG_FILE:-}" ]] && [[ -t 3 ]]; then
        _bdb_log "========================================="
        _bdb_log "BDB Logging already initialized"
        _bdb_log "Existing log file: ${BDB_LOG_FILE}"
        _bdb_log "Continuing with parent logging setup"
        _bdb_log "========================================="
        return 0
    fi

    local log_file="${1:-${BDB_LOG_FILE:-$(date +%Y%m%d_%H%M%S)_bdb.log}}"
    export BDB_LOG_FILE="${log_file}"

    touch "${BDB_LOG_FILE}" 2>/dev/null || {
        echo "Error: Cannot create log file: ${BDB_LOG_FILE}" >&2
        exit 1
    }

    if [[ ! -t 3 ]]; then
        exec 3>&1
    fi

    exec 1>>"${BDB_LOG_FILE}"
    exec 2>&1

    # set -x is intentionally NOT enabled here: we want command OUTPUT logged,
    # not the commands themselves. _bdb_log calls already document each operation.

    _bdb_log "========================================="
    _bdb_log "BDB Bootstrap Log"
    _bdb_log "Started: $(date '+%Y-%m-%d %H:%M:%S')"
    _bdb_log "Log file: ${BDB_LOG_FILE}"
    _bdb_log "========================================="
}
