#!/usr/bin/env bash
# =============================================================================
# BDB Helper Functions
# =============================================================================
# Utility functions for Bassa's Dotfiles Bootstrapper
# Provides colored output, user interaction, and error handling
#
# This file is sourced by bdb_bootstrap.sh and should not be executed directly
#
# Features:
# - ANSI colored output for different message types
# - User interaction helpers (prompts, confirmations)
# - Error handling and cleanup functions
# - Logging and timestamp utilities
#
# Last updated: 2025
# =============================================================================

# Disable shellcheck warning about missing shebang (this file is sourced)
# shellcheck disable=SC2148

# =============================================================================
# COLOR DEFINITIONS
# =============================================================================
# ANSI escape sequences for colored terminal output
# Using ANSI C quoting ($'...') for portability across shells

# Reset all attributes
readonly RST_COL=$'\033[0m'

# Regular colors (bright/bold variants)
readonly RED_COL=$'\033[31;01m'      # Red - errors
readonly GRN_COL=$'\033[32;01m'      # Green - success
readonly YLW_COL=$'\033[33;01m'      # Yellow - warnings/alerts
readonly BLU_COL=$'\033[34;01m'      # Blue - running operations
readonly MGN_COL=$'\033[35;01m'      # Magenta - questions
readonly CYN_COL=$'\033[36;01m'      # Cyan - outcomes/commands
readonly WHT_COL=$'\033[97;01m'      # White - info messages

# =============================================================================
# OUTPUT HELPER FUNCTIONS
# =============================================================================
# All output functions write to file descriptor 3 (FD3)
# FD3 is reserved for user-facing messages while stdout/stderr go to log file

# -----------------------------------------------------------------------------
# Success Message (Green)
# -----------------------------------------------------------------------------
# Display a success message with checkmark visual indicator
# Usage: bdb_success "operation completed successfully"
# Arguments:
#   $1 - Success message (default: "*** UNKNOWN ***")
bdb_success() {
    printf "\n%s[✓] SUCCESS: %s%s\n" \
        "${GRN_COL}" \
        "${1:-*** UNKNOWN ***}" \
        "${RST_COL}" >&3
}

# -----------------------------------------------------------------------------
# Error Message (Red)
# -----------------------------------------------------------------------------
# Display an error message with X visual indicator
# Usage: bdb_error "operation failed"
# Arguments:
#   $1 - Error message (default: "*** UNKNOWN ***")
bdb_error() {
    printf "\n%s[✗] ERROR: %s%s\n" \
        "${RED_COL}" \
        "${1:-*** UNKNOWN ***}" \
        "${RST_COL}" >&3
}

# -----------------------------------------------------------------------------
# Alert/Warning Message (Yellow)
# -----------------------------------------------------------------------------
# Display a warning or alert message
# Usage: bdb_alert "this action may take a while"
# Arguments:
#   $1 - Alert message
bdb_alert() {
    printf "\n%s[!] %s%s\n" \
        "${YLW_COL}" \
        "${1:-*** UNKNOWN ***}" \
        "${RST_COL}" >&3
}

# -----------------------------------------------------------------------------
# Info Message - Section Start (White)
# -----------------------------------------------------------------------------
# Display an informational message marking the start of a major section
# Usage: bdb_info_in "Starting system configuration"
# Arguments:
#   $1 - Info message (default: "*** UNKNOWN ***")
bdb_info_in() {
    printf "%s\n" "${WHT_COL}" >&3
    printf "╔════════════════════════════════════════════════════════════════════════════════╗\n" >&3
    printf "║                                                                                ║\n" >&3
    printf "║ %s\n" "${1:-*** UNKNOWN ***}" >&3
    printf "║                                                                                ║\n" >&3
    printf "%s\n" "${RST_COL}" >&3
}

# -----------------------------------------------------------------------------
# Info Message - Middle (White)
# -----------------------------------------------------------------------------
# Display a standard informational message
# Usage: bdb_info "checking system requirements"
# Arguments:
#   $1 - Info message (default: "*** UNKNOWN ***")
bdb_info() {
    printf "%s[i] %s%s\n" \
        "${WHT_COL}" \
        "${1:-*** UNKNOWN ***}" \
        "${RST_COL}" >&3
}

# -----------------------------------------------------------------------------
# Info Message - Section End (White)
# -----------------------------------------------------------------------------
# Display an informational message marking the end of a major section
# Usage: bdb_info_out "System configuration complete"
# Arguments:
#   $1 - Info message (default: "*** UNKNOWN ***")
bdb_info_out() {
    printf "%s\n" "${WHT_COL}" >&3
    printf "║                                                                                ║\n" >&3
    printf "║ %s\n" "${1:-*** UNKNOWN ***}" >&3
    printf "║                                                                                ║\n" >&3
    printf "╚════════════════════════════════════════════════════════════════════════════════╝\n" >&3
    printf "%s\n" "${RST_COL}" >&3
}

# -----------------------------------------------------------------------------
# Running Operation Message (Blue)
# -----------------------------------------------------------------------------
# Display a message indicating an operation is starting
# Usage: bdb_run "Installing packages"
# Arguments:
#   $1 - Operation description (default: "*** UNKNOWN ***")
bdb_run() {
    printf "\n%s[→] %s...%s" \
        "${BLU_COL}" \
        "${1:-*** UNKNOWN ***}" \
        "${RST_COL}" >&3
}

# -----------------------------------------------------------------------------
# Outcome Message (Cyan)
# -----------------------------------------------------------------------------
# Display the outcome/result of an operation (typically follows bdb_run)
# Usage: bdb_outcome "completed in 2.5s"
# Arguments:
#   $1 - Outcome description (default: "*** UNKNOWN ***")
bdb_outcome() {
    printf " %s%s%s\n" \
        "${CYN_COL}" \
        "${1:-*** UNKNOWN ***}" \
        "${RST_COL}" >&3
}

# -----------------------------------------------------------------------------
# Command Message (Cyan)
# -----------------------------------------------------------------------------
# Display a command that is about to be executed
# Usage: bdb_command "apt-get update"
# Arguments:
#   $1 - Command description (default: "*** UNKNOWN ***")
bdb_command() {
    printf "\n%s[»] Running: %s%s\n" \
        "${CYN_COL}" \
        "${1:-*** UNKNOWN ***}" \
        "${RST_COL}" >&3
}

# =============================================================================
# USER INTERACTION FUNCTIONS
# =============================================================================

# -----------------------------------------------------------------------------
# Yes/No Confirmation Prompt
# -----------------------------------------------------------------------------
# Ask user a yes/no question with default to "no"
# Usage: if bdb_ask "Continue with installation"; then ...; fi
# Arguments:
#   $1 - Question to ask (default: "*** UNKNOWN ***")
# Returns:
#   0 - User answered yes (y/Y)
#   1 - User answered no (n/N or Enter)
bdb_ask() {
    local response
    
    printf "%s\n[?] %s [y/N] > %s" \
        "${MGN_COL}" \
        "${1:-*** UNKNOWN ***}" \
        "${RST_COL}" >&3
    
    # Read single character from terminal
    # -r: disable backslash escapes
    # -n 1: read only 1 character
    read -r -n 1 response < /dev/tty
    printf "\n" >&3  # Add newline after input
    
    # Check if response is y or Y
    if [[ "${response:-}" =~ ^[yY]$ ]]; then
        return 0
    fi
    
    return 1
}

# -----------------------------------------------------------------------------
# Yes/No Confirmation with Default Yes
# -----------------------------------------------------------------------------
# Ask user a yes/no question with default to "yes"
# Usage: if bdb_ask_default_yes "Apply changes"; then ...; fi
# Arguments:
#   $1 - Question to ask (default: "*** UNKNOWN ***")
# Returns:
#   0 - User answered yes (y/Y or Enter)
#   1 - User answered no (n/N)
bdb_ask_default_yes() {
    local response
    
    printf "%s\n[?] %s [Y/n] > %s" \
        "${MGN_COL}" \
        "${1:-*** UNKNOWN ***}" \
        "${RST_COL}" >&3
    
    read -r -n 1 response < /dev/tty
    printf "\n" >&3
    
    # Default to yes if empty, only no if explicitly n/N
    if [[ "${response:-}" =~ ^[nN]$ ]]; then
        return 1
    fi
    
    return 0
}

# =============================================================================
# LOGGING AND DEBUGGING FUNCTIONS
# =============================================================================

# -----------------------------------------------------------------------------
# Timestamp for Log Entries
# -----------------------------------------------------------------------------
# Print timestamp for command logging (used with DEBUG trap)
# This function temporarily disables command tracing to avoid recursion
# Format: [YYYY-MM-DD HH:MM:SS]
bdb_timestamp() {
    { set +x; } 2>/dev/null  # Disable tracing temporarily
    printf "\n[%s] " "$(date '+%Y-%m-%d %H:%M:%S')"
    set -x 2>/dev/null  # Re-enable tracing
}

# =============================================================================
# CLEANUP AND ERROR HANDLING
# =============================================================================

# -----------------------------------------------------------------------------
# Cleanup Function
# -----------------------------------------------------------------------------
# Clean up temporary files and reset environment
# Called automatically on script exit via EXIT trap
# This ensures a clean state even if the script fails
bdb_cleanup() {
    # Disable tracing for cleanup to reduce noise
    { set +x; } 2>/dev/null
    
    bdb_info "Cleaning up temporary files and resetting environment"

    # Remove temporary helper file if it exists
    if [[ -n "${BDB_HELPERS:-}" ]] && [[ -f "${BDB_HELPERS}" ]]; then
        bdb_run "Removing temporary file"
        if rm -f "${BDB_HELPERS}" 2>/dev/null; then
            bdb_outcome "removed: ${BDB_HELPERS}"
        else
            bdb_alert "Failed to remove: ${BDB_HELPERS}"
        fi
    fi

    # Unset environment variables to avoid pollution
    unset BDB_HELPERS_URL
    unset BDB_HELPERS
    unset BDB_SCRIPT_DIR
    unset BDB_LOG_FILE

    # Disable strict error handling
    set +euo pipefail 2>/dev/null

    # Restore original file descriptors
    # Redirect stdout and stderr back to original destinations
    if [[ -t 3 ]]; then
        exec 1>&3 2>&1  # Restore stdout to FD3, stderr to stdout
        exec 3>&-       # Close FD3
    fi

    printf "\n" >&3 2>/dev/null || printf "\n"
}

# -----------------------------------------------------------------------------
# Error Handler
# -----------------------------------------------------------------------------
# Handle errors, display diagnostic information, and exit
# Called automatically via ERR trap when any command fails
# Arguments:
#   $1 - Optional error message (default: "UNKNOWN")
# Global Variables Used:
#   $? - Exit status of failed command
#   $BASH_COMMAND - Command that triggered the error
bdb_handle_error() {
    local err_value="$?"                    # Capture exit status
    local err_command="${BASH_COMMAND}"     # Capture failed command
    local err_message="${1:-UNKNOWN}"       # Custom error message
    
    # Disable tracing for error output
    { set +x; } 2>/dev/null
    
    # Display error information
    bdb_error "Command failed: ${err_command}"
    bdb_error "Exit code: ${err_value}"
    bdb_error "Message: ${err_message}"
    
    # Exit with the original error code
    exit "${err_value}"
}

# -----------------------------------------------------------------------------
# Command Existence Check
# -----------------------------------------------------------------------------
# Check if a command exists in PATH
# Usage: if bdb_command_exists "git"; then ...; fi
# Arguments:
#   $1 - Command name to check
# Returns:
#   0 - Command exists
#   1 - Command not found
bdb_command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# -----------------------------------------------------------------------------
# Require Command
# -----------------------------------------------------------------------------
# Check if a required command exists, exit if not found
# Usage: bdb_require_command "git" "Git is required for this operation"
# Arguments:
#   $1 - Command name to check
#   $2 - Optional error message
bdb_require_command() {
    local cmd="$1"
    local msg="${2:-Command '$cmd' is required but not found}"
    
    if ! bdb_command_exists "$cmd"; then
        bdb_error "$msg"
        exit 1
    fi
}

# =============================================================================
# UTILITY FUNCTIONS
# =============================================================================

# -----------------------------------------------------------------------------
# Safe Directory Creation
# -----------------------------------------------------------------------------
# Create directory with error handling
# Usage: bdb_mkdir "/path/to/directory" "Failed to create config directory"
# Arguments:
#   $1 - Directory path to create
#   $2 - Optional error message
# Returns:
#   0 - Directory created or already exists
#   1 - Failed to create directory
bdb_mkdir() {
    local dir="$1"
    local err_msg="${2:-Failed to create directory: $dir}"
    
    if [[ ! -d "$dir" ]]; then
        if ! mkdir -p "$dir" 2>/dev/null; then
            bdb_error "$err_msg"
            return 1
        fi
    fi
    
    return 0
}

# -----------------------------------------------------------------------------
# Download File
# -----------------------------------------------------------------------------
# Download a file using curl or wget (whichever is available)
# Usage: bdb_download "https://example.com/file" "/path/to/output"
# Arguments:
#   $1 - URL to download from
#   $2 - Output file path
# Returns:
#   0 - Download successful
#   1 - Download failed or no tool available
bdb_download() {
    local url="$1"
    local output="$2"
    
    if bdb_command_exists curl; then
        curl -fsSL "$url" -o "$output" 2>/dev/null
    elif bdb_command_exists wget; then
        wget -qO "$output" "$url" 2>/dev/null
    else
        bdb_error "Neither curl nor wget is available for downloading"
        return 1
    fi
}

# =============================================================================
# END OF HELPER FUNCTIONS
# =============================================================================
