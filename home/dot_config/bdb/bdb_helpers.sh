#!/usr/bin/env bash
# =============================================================================
# BDB Helper Functions
# =============================================================================
# Utility functions for Bassa's Dotfiles Bootstrapper.
# Provides colored terminal output, structured logging, and command helpers.
#
# Output model:
#   - FD3 → terminal: short, color-coded status lines for the watching user.
#   - FD1/FD2 → log file (redirected by bdb_init_logging): structured records,
#     exactly one line per event, every line timestamped:
#
#         [2026-06-11 10:38:41] [LEVEL  ] message
#
#     Levels: START END SECTION ACTION CMD OUT OK FAIL INFO WARN ERROR ASK
#
#     Command output is recorded as [OUT] lines between the opening [CMD]
#     record (description + command line) and the closing [OK]/[FAIL] record
#     (exit code + duration), so every output line is attributable to the
#     command that produced it. ANSI escape codes and progress-bar redraws
#     are stripped from captured output.
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
# LOGGING CORE
# =============================================================================

# Write one structured log record: _bdb_log LEVEL message...
# bash >= 4.2 formats the timestamp via the printf builtin (no fork per line);
# older bash (macOS ships 3.2) falls back to date(1).
if printf -v _BDB_TS_PROBE '%(%s)T' -1 2>/dev/null; then
    _bdb_log() {
        local level="$1" ts
        shift
        printf -v ts '%(%Y-%m-%d %H:%M:%S)T' -1
        printf '[%s] [%-7s] %s\n' "${ts}" "${level}" "$*"
    }
else
    _bdb_log() {
        local level="$1"
        shift
        printf '[%s] [%-7s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "${level}" "$*"
    }
fi
unset -v _BDB_TS_PROBE

# Line-buffered sed flag, so [OUT] records are timestamped when the command
# produces them, not when a 4KB block flushes: GNU sed uses -u, BSD sed -l.
if echo | sed -u '' >/dev/null 2>&1; then
    _BDB_SED_UNBUF="-u"
elif echo | sed -l '' >/dev/null 2>&1; then
    _BDB_SED_UNBUF="-l"
else
    _BDB_SED_UNBUF=""
fi

# Capture command output for the log: strip ANSI escapes (CSI, OSC, and
# two-char sequences), collapse carriage-return redraws to their final state,
# drop blank lines and progress-bar spam, and tag each line as [OUT].
_bdb_log_output() {
    local line
    # shellcheck disable=SC2086
    sed ${_BDB_SED_UNBUF} -E $'s/\x1b\\[[0-9;?]*[a-zA-Z]//g; s/\x1b\\][^\x07]*\x07//g; s/\x1b[@-_]//g' \
        | while IFS= read -r line || [[ -n "${line}" ]]; do
            line="${line%$'\r'}"      # CRLF line endings
            line="${line##*$'\r'}"    # progress redraws: keep what remains visible
            [[ -z "${line//[[:space:]]/}" ]] && continue
            [[ "${line}" == *'####'* ]] && continue
            _bdb_log OUT "${line}"
        done
}

# =============================================================================
# TERMINAL OUTPUT FUNCTIONS
# =============================================================================
# Status lines go to FD3 (terminal); each function also writes exactly one
# log record so terminal and log stay in sync without duplication.

# Internal: colored status line on the terminal only.
_bdb_term() {
    local color="$1" icon="$2"
    shift 2
    printf "%s%s %s%s\n" "${color}" "${icon}" "$*" "${C_RST}" >&3
}

bdb_action() {
    _bdb_term "${C_CYN}" "${ICON_ARROW}" "$*"
    _bdb_log ACTION "$*"
}

bdb_success() {
    _bdb_term "${C_GRN}" "${ICON_OK}" "$*"
    _bdb_log OK "$*"
}

bdb_error() {
    _bdb_term "${C_RED}" "${ICON_ERR}" "$*"
    _bdb_log ERROR "$*"
}

bdb_warn() {
    _bdb_term "${C_YLW}" "${ICON_WARN}" "$*"
    _bdb_log WARN "$*"
}

bdb_info() {
    _bdb_term "${C_WHT}" "${ICON_INFO}" "$*"
    _bdb_log INFO "$*"
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
    local response=""
    printf "%s%s %s [y/N]: %s" "${C_MAG}" "${ICON_PROMPT}" "$*" "${C_RST}" >&3
    read -r response < /dev/tty
    _bdb_log ASK "$* → ${response:-N}"
    [[ "${response}" =~ ^[yY]$ ]]
}

# =============================================================================
# COMMAND EXECUTION FUNCTIONS
# =============================================================================

# Show action on the terminal, run the command with its output captured as
# [OUT] records, close with [OK]/[FAIL] carrying exit code and duration.
bdb_exec() {
    local description="$1"
    shift
    local exit_code=0
    local start=${SECONDS}

    _bdb_term "${C_CYN}" "${ICON_ARROW}" "${description}"
    _bdb_log CMD "${description}"
    _bdb_log CMD "\$ $*"

    # if-guard keeps errexit from firing before we log the result;
    # PIPESTATUS[0] is the command's own status regardless of pipefail.
    if "$@" 2>&1 | _bdb_log_output; then
        exit_code=${PIPESTATUS[0]}
    else
        exit_code=${PIPESTATUS[0]}
    fi

    if (( exit_code == 0 )); then
        _bdb_term "${C_GRN}" "${ICON_OK}" "${description}"
        _bdb_log OK "${description} (exit 0, $(( SECONDS - start ))s)"
        return 0
    else
        _bdb_term "${C_RED}" "${ICON_ERR}" "${description} (exit code: ${exit_code})"
        _bdb_log FAIL "${description} (exit ${exit_code}, $(( SECONDS - start ))s)"
        return "${exit_code}"
    fi
}

# Show info (not success/error) since this is a test, not an operation
bdb_test_cmd() {
    local cmd="$1"
    if command -v "${cmd}" >/dev/null 2>&1; then
        bdb_info "Found: ${cmd}"
        return 0
    else
        bdb_info "Not found: ${cmd}"
        return 1
    fi
}

bdb_var() {
    local name="$1"
    local value="$2"
    bdb_info "${name}: ${value}"
}

# =============================================================================
# UTILITY FUNCTIONS
# =============================================================================

bdb_mkdir() {
    local dir="$1"
    local error_msg="${2:-Failed to create directory: ${dir}}"
    [[ -d "${dir}" ]] && return 0
    if mkdir -p "${dir}"; then
        _bdb_log INFO "Created directory: ${dir}"
        return 0
    else
        bdb_error "${error_msg}"
        return 1
    fi
}

# Silent command check — use bdb_test_cmd when user-visible feedback is needed
bdb_has_cmd() {
    command -v "$1" >/dev/null 2>&1
}

# =============================================================================
# SYSTEM UPDATE
# =============================================================================
# Single implementation of the system package update, shared by
# bdb_bootstrap.sh (pre-chezmoi) and ~/.config/bdb/bdb_update.sh (the
# chezmoi update hook). The package manager is detected at runtime so the
# same code runs in both contexts.

bdb_update_packages() {
    if bdb_has_cmd "brew"; then
        # macOS — brew upgrade covers formulae and casks
        bdb_exec "Updating Homebrew" brew update
        bdb_exec "Upgrading Homebrew packages" brew upgrade
        bdb_success "Homebrew packages updated"

    elif bdb_has_cmd "pacman"; then
        # Arch / CachyOS — once yay is installed it replaces pacman entirely
        # (drop-in CLI, also updates AUR packages, invokes sudo itself).
        # During bootstrap yay does not exist yet, so plain pacman is used.
        local pac=(sudo pacman)
        local pac_scope="system"
        if bdb_has_cmd "yay"; then
            pac=(yay)
            pac_scope="system and AUR"
        fi

        bdb_exec "Updating ${pac_scope} packages" "${pac[@]}" -Syu --noconfirm

        # Orphan removal always goes through pacman: once installed, AUR
        # packages are regular local packages, so -Rns gains nothing from yay.
        local orphans
        orphans="$(pacman -Qdtq 2>/dev/null || true)"
        if [[ -n "${orphans}" ]]; then
            bdb_exec "Removing orphaned packages" bash -c "echo '${orphans}' | sudo pacman -Rns --noconfirm -"
        fi

        # yay -Scc additionally clears the AUR build cache
        bdb_exec "Cleaning package cache" "${pac[@]}" -Scc --noconfirm
        bdb_success "System packages updated"

    elif bdb_has_cmd "apt-get"; then
        # Debian / Ubuntu
        bdb_exec "Updating package lists" sudo apt-get update
        bdb_exec "Upgrading packages" sudo apt-get full-upgrade -y
        bdb_exec "Removing unused packages" sudo apt-get autoremove --purge -y
        bdb_exec "Cleaning package cache" sudo apt-get clean
        bdb_success "APT packages updated"

        if bdb_has_cmd "snap"; then
            bdb_exec "Updating Snap packages" sudo snap refresh
            bdb_success "Snap packages updated"
        fi

    elif bdb_has_cmd "dnf"; then
        # Fedora / Rocky
        bdb_exec "Upgrading packages" sudo dnf upgrade --refresh -y
        bdb_exec "Removing unused packages" sudo dnf autoremove -y
        bdb_exec "Cleaning package cache" sudo dnf clean all
        bdb_success "DNF packages updated"

        if bdb_has_cmd "flatpak"; then
            bdb_exec "Updating Flatpak packages" flatpak update -y
            bdb_success "Flatpak packages updated"
        fi

    else
        bdb_warn "No supported package manager found — skipping system update"
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
    _bdb_log ERROR "exit=${exit_code} line=${BASH_LINENO[0]} cmd: ${cmd}"
    bdb_error "Script failed (exit code: ${exit_code})"
    bdb_info "Check log file for details: ${BDB_LOG_FILE:-bdb.log}"
    exit "${exit_code}"
}

bdb_cleanup() {
    { set +x; } 2>/dev/null

    if [[ -n "${BDB_TEMP_FILES:-}" ]]; then
        for file in ${BDB_TEMP_FILES}; do
            if [[ -f "${file}" ]]; then
                rm -f "${file}" 2>/dev/null || true
                _bdb_log INFO "Removed temporary file: ${file}"
            fi
        done
    fi

    _bdb_log END "Log session closed"

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
}

# =============================================================================
# SECTION HELPERS
# =============================================================================

bdb_begin_section() {
    _BDB_SECTION="$*"
    bdb_header "$*"
    _bdb_log SECTION ">>> $*"
}

bdb_end_section() {
    bdb_footer
    _bdb_log SECTION "<<< ${_BDB_SECTION:-}"
    _BDB_SECTION=""
}

# =============================================================================
# SCRIPT LIFECYCLE
# =============================================================================
# Shared preamble/epilogue for chezmoi scripts — keeps the per-script
# boilerplate down to two lines (source + bdb_script_init).

# Per-run log file, dual-output logging, strict mode, and traps.
# Call immediately after sourcing this file: bdb_script_init "${BASH_SOURCE[0]}"
bdb_script_init() {
    local script_name
    script_name="$(basename "$1" .tmpl)"
    # chezmoi runs scripts from a temp copy named "<random digits>.<name>" —
    # strip the prefix so log files carry the real script name.
    if [[ "${script_name}" =~ ^[0-9]+\.(.+)$ ]]; then
        script_name="${BASH_REMATCH[1]}"
    fi
    mkdir -p "${HOME}/.cache/chezmoi" 2>/dev/null || true
    bdb_init_logging "${HOME}/.cache/chezmoi/$(date +%Y%m%d_%H%M%S)_${script_name}.log"

    _bdb_log START "Script: ${script_name}"

    set -euo pipefail
    trap 'bdb_handle_error' ERR
    trap 'bdb_cleanup' EXIT
}

# Final success message, log file pointer, and section close.
bdb_script_end() {
    bdb_success "$1"
    if [[ -n "${BDB_LOG_FILE:-}" ]]; then
        bdb_var "Log file" "${BDB_LOG_FILE}"
    fi
    bdb_end_section
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
        _bdb_log INFO "Logging already initialized — appending to ${BDB_LOG_FILE}"
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
    # not the commands themselves. The [CMD]/[OUT] records already document
    # each operation.

    _bdb_log START "Log session: ${BDB_LOG_FILE}"
}
