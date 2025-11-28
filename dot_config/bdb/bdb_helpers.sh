#!/usr/bin/env bash
# =============================================================================
# BDB Helper Functions - Rewritten
# =============================================================================
# Utility functions for Bassa's Dotfiles Bootstrapper
# Provides minimal terminal output with comprehensive logging
#
# Design Principles:
# - Minimal terminal output for clean user experience
# - All command output logged with timestamps
# - Clear color-coded status indicators
# - Separation between user-facing (FD3) and log (stdout/stderr) output
#
# Color Scheme:
# - Red: Errors
# - Green: Success
# - Yellow: Warnings/Alerts
# - Magenta: User prompts
# - White: Information/Variables/Test results
# - Cyan: Upcoming actions
#
# Last updated: 2025
# =============================================================================

# Disable shellcheck warning about missing shebang (this file is sourced)
# shellcheck disable=SC2148

# =============================================================================
# COLOR DEFINITIONS
# =============================================================================
# ANSI escape sequences for colored terminal output
# These colors follow the design specification:
# - Red: Command errors and failures
# - Green: Successful operations
# - Yellow: Warnings and alerts
# - Magenta: User input prompts and questions
# - Cyan: Upcoming actions and operations
# - White: Informational messages, variables, and test results
#
# Format: \033[<style>;<color>m where:
#   Style: 0=normal, 1=bold
#   Color: 31=red, 32=green, 33=yellow, 35=magenta, 36=cyan, 97=bright white

readonly C_RST=$'\033[0m'      # Reset - Clear all formatting
readonly C_RED=$'\033[31;1m'   # Red Bold - Errors and failures
readonly C_GRN=$'\033[32;1m'   # Green Bold - Success messages
readonly C_YLW=$'\033[33;1m'   # Yellow Bold - Warnings and alerts
readonly C_MAG=$'\033[35;1m'   # Magenta Bold - User prompts
readonly C_CYN=$'\033[36;1m'   # Cyan Bold - Upcoming actions
readonly C_WHT=$'\033[97;1m'   # White Bold - Info/variables/results

# Visual indicators - Unicode symbols for status messages
# These provide quick visual feedback alongside color coding
readonly ICON_OK="✓"           # Success checkmark
readonly ICON_ERR="✗"          # Error cross
readonly ICON_WARN="!"         # Warning exclamation
readonly ICON_INFO="•"         # Information bullet
readonly ICON_PROMPT="?"       # Question mark for prompts
readonly ICON_ARROW="→"        # Arrow for actions

# =============================================================================
# LOGGING FUNCTIONS
# =============================================================================
# Internal functions for managing log file output
# All log entries are written to stdout (which is redirected to log file)
# These functions are prefixed with _ to indicate internal use only

# -----------------------------------------------------------------------------
# Add Timestamp to Log Entry
# -----------------------------------------------------------------------------
# Internal function called by DEBUG trap to add timestamps to log file
# Temporarily disables command tracing (set +x) to prevent infinite recursion
# Each log entry starts with [YYYY-MM-DD HH:MM:SS] format
#
# This function is called automatically before each command when DEBUG trap is set
# Do not call directly - it's managed by the trap system
_bdb_log_timestamp() {
    # Disable command tracing temporarily to avoid logging this function's commands
    { set +x; } 2>/dev/null

    # Write timestamp to stdout (which goes to log file)
    printf "[%s] " "$(date '+%Y-%m-%d %H:%M:%S')" >&1

    # Re-enable command tracing for subsequent commands
    set -x 2>/dev/null
}

# -----------------------------------------------------------------------------
# Log to File Only
# -----------------------------------------------------------------------------
# Write a message directly to the log file without any terminal output
# Adds timestamps to section markers and important events
#
# Usage: _bdb_log "Starting initialization phase"
# Arguments:
#   $* - All arguments are concatenated and written to log
# Output:
#   Writes "[TIMESTAMP] [LOG] <message>" for sections/important events
#   Writes "[LOG] <message>" for regular log entries
# Behavior:
#   Timestamps are added to:
#   - Lines starting with "========" (section separators)
#   - Lines containing "SECTION:" (section headers)
#   - Lines containing "Script:" (script identifiers)
#   - Lines containing "Action:" (important actions)
#   - Lines containing "SUCCESS:" (completion markers)
_bdb_log() {
    local message="$*"

    # Check if this is an important marker that should get a timestamp
    if [[ "$message" =~ ^===+$ ]] || \
       [[ "$message" =~ SECTION:|Script:|Action:|SUCCESS:|ERROR:|Command: ]]; then
        # Add timestamp for important markers
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] [LOG] $message" >&1
    else
        # Regular log entry without timestamp
        echo "[LOG] $message" >&1
    fi
}

# -----------------------------------------------------------------------------
# Log Command Output
# -----------------------------------------------------------------------------
# Execute a command and capture all output to log file with description
# This is an internal function - use bdb_exec() for normal command execution
#
# Usage: _bdb_log_cmd "Installing git" apt-get install -y git
# Arguments:
#   $1 - Description of the command for logging purposes
#   $@ - The command and its arguments to execute
# Returns:
#   Exit code of the executed command
# Output:
#   All stdout/stderr goes to log file with description header
_bdb_log_cmd() {
    local desc="$1"
    shift

    # Log the command details before execution
    _bdb_log "Running: $*"
    _bdb_log "Description: ${desc}"

    # Execute command, redirecting all output to log file
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
# All terminal output goes to FD3 (file descriptor 3) for clean separation
# from log file output (which goes to stdout/stderr redirected to log)
#
# This dual-output system ensures:
# - Users see clean, minimal status messages on their terminal
# - Complete command output and details are captured in the log file
# - Output doesn't get mixed or duplicated
#
# File Descriptor Setup:
#   FD1 (stdout) → Log file (verbose, complete output)
#   FD2 (stderr) → Log file (errors and debugging)
#   FD3 (custom) → Terminal (user-facing, colored, minimal)

# -----------------------------------------------------------------------------
# Print Action (Cyan)
# -----------------------------------------------------------------------------
# Display an upcoming action or operation in cyan with arrow indicator
# Use this before starting a potentially long-running operation
#
# Usage: bdb_action "Installing packages"
# Arguments:
#   $* - Action description (all arguments concatenated)
# Output:
#   Terminal: → Installing packages (in cyan)
#   Log: Action is logged separately by calling function
# Example:
#   bdb_action "Downloading file from server"
#   # Terminal shows: → Downloading file from server
bdb_action() {
    printf "%s%s %s%s\n" \
        "${C_CYN}" \
        "${ICON_ARROW}" \
        "$*" \
        "${C_RST}" >&3
}

# -----------------------------------------------------------------------------
# Print Success (Green)
# -----------------------------------------------------------------------------
# Display a success message in green with checkmark indicator
# Use this after an operation completes successfully
#
# Usage: bdb_success "Installation complete"
# Arguments:
#   $* - Success message (all arguments concatenated)
# Output:
#   Terminal: ✓ Installation complete (in green)
#   Log: Success is logged separately by calling function
# Example:
#   bdb_success "All packages installed successfully"
#   # Terminal shows: ✓ All packages installed successfully
bdb_success() {
    printf "%s%s %s%s\n" \
        "${C_GRN}" \
        "${ICON_OK}" \
        "$*" \
        "${C_RST}" >&3
}

# -----------------------------------------------------------------------------
# Print Error (Red)
# -----------------------------------------------------------------------------
# Display an error message in red with cross indicator
# Use this when an operation fails or encounters an error
#
# Usage: bdb_error "Failed to install package"
# Arguments:
#   $* - Error message (all arguments concatenated)
# Output:
#   Terminal: ✗ Failed to install package (in red)
#   Log: Error details logged separately
# Example:
#   bdb_error "Package not found in repository"
#   # Terminal shows: ✗ Package not found in repository
bdb_error() {
    printf "%s%s %s%s\n" \
        "${C_RED}" \
        "${ICON_ERR}" \
        "$*" \
        "${C_RST}" >&3
}

# -----------------------------------------------------------------------------
# Print Warning (Yellow)
# -----------------------------------------------------------------------------
# Display a warning or alert message in yellow with exclamation indicator
# Use this for non-critical issues or important notices
#
# Usage: bdb_warn "This operation may take a while"
# Arguments:
#   $* - Warning message (all arguments concatenated)
# Output:
#   Terminal: ! This operation may take a while (in yellow)
#   Log: Warning logged separately
# Example:
#   bdb_warn "Skipping optional component"
#   # Terminal shows: ! Skipping optional component
bdb_warn() {
    printf "%s%s %s%s\n" \
        "${C_YLW}" \
        "${ICON_WARN}" \
        "$*" \
        "${C_RST}" >&3
}

# -----------------------------------------------------------------------------
# Print Info (White)
# -----------------------------------------------------------------------------
# Display informational message in white with bullet indicator
# Use this for general information, variable values, or test results
#
# Usage: bdb_info "Detected OS: Ubuntu 22.04"
# Arguments:
#   $* - Information message (all arguments concatenated)
# Output:
#   Terminal: • Detected OS: Ubuntu 22.04 (in white)
#   Log: Info logged separately
# Example:
#   bdb_info "Found 5 packages to install"
#   # Terminal shows: • Found 5 packages to install
bdb_info() {
    printf "%s%s %s%s\n" \
        "${C_WHT}" \
        "${ICON_INFO}" \
        "$*" \
        "${C_RST}" >&3
}

# -----------------------------------------------------------------------------
# Print Header
# -----------------------------------------------------------------------------
# Display a section header with decorative border for visual separation
# Use this to mark the beginning of major sections in your script
#
# Usage: bdb_header "System Configuration"
# Arguments:
#   $* - Header text (all arguments concatenated)
# Output:
#   Terminal:
#   ════════════════════════════════════════
#            System Configuration
#   ════════════════════════════════════════
#   (in white)
# Example:
#   bdb_header "Installing Dependencies"
bdb_header() {
    local text="$*"
    local width=80
    # Calculate padding to center the text
    local padding=$(( (width - ${#text} - 2) / 2 ))

    printf "\n%s" "${C_WHT}" >&3
    printf "═%.0s" {1..80} >&3
    printf "\n" >&3
    printf "%*s%s%*s\n" ${padding} "" "${text}" ${padding} "" >&3
    printf "═%.0s" {1..80} >&3
    printf "%s\n\n" "${C_RST}" >&3
}

# -----------------------------------------------------------------------------
# Print Footer
# -----------------------------------------------------------------------------
# Display a section footer with lighter border for visual separation
# Use this to mark the end of major sections
#
# Usage: bdb_footer
# Arguments: None
# Output:
#   Terminal:
#   ────────────────────────────────────────
#   (in white)
# Example:
#   bdb_footer
bdb_footer() {
    printf "\n%s" "${C_WHT}" >&3
    printf "─%.0s" {1..80} >&3
    printf "%s\n\n" "${C_RST}" >&3
}

# =============================================================================
# USER INTERACTION FUNCTIONS
# =============================================================================
# Functions for prompting users and gathering input
# All prompts are displayed in magenta and read from /dev/tty to ensure
# they work correctly even when stdin/stdout are redirected
#
# Response Handling:
# - Input is read directly from terminal (/dev/tty) not stdin
# - Responses are logged for audit trail
# - Functions return proper exit codes for use in conditionals

# -----------------------------------------------------------------------------
# Ask Yes/No Question (Default: No)
# -----------------------------------------------------------------------------
# Prompt user with a yes/no question where default answer is NO
# User must explicitly type 'y' or 'Y' to get a yes response
# Pressing Enter or any other key results in NO
#
# Usage:
#   if bdb_ask "Continue with installation"; then
#       # User answered yes
#   else
#       # User answered no (or pressed Enter)
#   fi
#
# Arguments:
#   $* - Question to ask (all arguments concatenated)
# Returns:
#   0 - User answered yes (typed y or Y)
#   1 - User answered no (typed n/N or pressed Enter)
# Output:
#   Terminal: ? Continue with installation [y/N]: (in magenta)
#   Log: User prompt and response recorded
# Example:
#   if bdb_ask "Delete all temporary files"; then
#       rm -rf /tmp/*
#   fi
bdb_ask() {
    local response

    # Display prompt to terminal with magenta color
    printf "%s%s %s [y/N]: %s" \
        "${C_MAG}" \
        "${ICON_PROMPT}" \
        "$*" \
        "${C_RST}" >&3

    # Read response directly from terminal (not stdin)
    read -r response < /dev/tty

    # Log the interaction for audit trail
    _bdb_log "User prompt: $* - Response: ${response:-N}"

    # Return 0 (true) only if response is y or Y
    [[ "${response}" =~ ^[yY]$ ]]
}

# -----------------------------------------------------------------------------
# Ask Yes/No Question (Default: Yes)
# -----------------------------------------------------------------------------
# Prompt user with a yes/no question where default answer is YES
# User must explicitly type 'n' or 'N' to get a no response
# Pressing Enter or any other key results in YES
#
# Usage:
#   if bdb_ask_yes "Apply configuration changes"; then
#       # User answered yes (or pressed Enter)
#   else
#       # User explicitly answered no
#   fi
#
# Arguments:
#   $* - Question to ask (all arguments concatenated)
# Returns:
#   0 - User answered yes (typed y/Y or pressed Enter)
#   1 - User answered no (typed n or N)
# Output:
#   Terminal: ? Apply configuration changes [Y/n]: (in magenta)
#   Log: User prompt and response recorded
# Example:
#   if bdb_ask_yes "Save configuration"; then
#       save_config
#   fi
bdb_ask_yes() {
    local response

    # Display prompt to terminal with magenta color
    printf "%s%s %s [Y/n]: %s" \
        "${C_MAG}" \
        "${ICON_PROMPT}" \
        "$*" \
        "${C_RST}" >&3

    # Read response directly from terminal (not stdin)
    read -r response < /dev/tty

    # Log the interaction for audit trail
    _bdb_log "User prompt: $* - Response: ${response:-Y}"

    # Return 1 (false) only if response is n or N
    [[ ! "${response}" =~ ^[nN]$ ]]
}

# -----------------------------------------------------------------------------
# Get User Input
# -----------------------------------------------------------------------------
# Prompt user for text input and return the entered value
# Use this when you need more than just yes/no response
#
# Usage:
#   username=$(bdb_input "Enter your username")
#   email=$(bdb_input "Enter your email address")
#
# Arguments:
#   $* - Prompt text (all arguments concatenated)
# Returns:
#   Always returns 0
# Output:
#   Terminal: ? Enter your username: (in magenta)
#   Log: User prompt and response recorded
#   stdout: The text entered by user
# Example:
#   hostname=$(bdb_input "Enter hostname for this server")
#   echo "Setting hostname to: ${hostname}"
bdb_input() {
    local response

    # Display prompt to terminal with magenta color
    printf "%s%s %s: %s" \
        "${C_MAG}" \
        "${ICON_PROMPT}" \
        "$*" \
        "${C_RST}" >&3

    # Read response directly from terminal (not stdin)
    read -r response < /dev/tty

    # Log the interaction for audit trail
    _bdb_log "User input: $* - Response: ${response}"

    # Output the response to stdout for capture
    echo "${response}"
}

# =============================================================================
# COMMAND EXECUTION FUNCTIONS
# =============================================================================
# Functions for executing commands with automatic status reporting and logging
# These functions handle the dual-output system:
# - Terminal: Shows clean status messages (action → result)
# - Log file: Captures complete command output with timestamps
#
# All command output (stdout/stderr) is automatically captured in the log file
# Exit codes are preserved and returned to the caller

# -----------------------------------------------------------------------------
# Execute Command with Status
# -----------------------------------------------------------------------------
# Execute a command showing action first, then result (success/failure)
# This is the primary function for running operations with user feedback
#
# Usage: bdb_exec "Installing git" sudo apt-get install -y git
#
# Arguments:
#   $1 - Description of the operation (for terminal and log)
#   $@ - Command and its arguments to execute
# Returns:
#   Exit code of the executed command
# Output:
#   Terminal: → Installing git
#             ✓ Installing git (or ✗ with error if failed)
#   Log: Complete command output with timestamps and description
# Behavior:
#   - Shows action message immediately (cyan)
#   - Executes command with all output to log
#   - Shows success (green) or error (red) with exit code
# Example:
#   bdb_exec "Updating package lists" sudo apt-get update
#   bdb_exec "Installing dependencies" npm install
bdb_exec() {
    local description="$1"
    shift

    # Show action to user (what we're about to do)
    bdb_action "${description}"

    # Log detailed information about the operation
    _bdb_log "========================================="
    _bdb_log "Action: ${description}"
    _bdb_log "Command: $*"
    _bdb_log "========================================="

    # Execute the command with output to log file
    if "$@" >&1 2>&1; then
        # Command succeeded - show success and log it
        bdb_success "${description}"
        _bdb_log "Success: ${description}"
        return 0
    else
        # Command failed - show error with exit code and log it
        local exit_code=$?
        bdb_error "${description} (exit code: ${exit_code})"
        _bdb_log "Error: ${description} failed with exit code ${exit_code}"
        return ${exit_code}
    fi
}

# -----------------------------------------------------------------------------
# Execute Command Silently (Only Show Result)
# -----------------------------------------------------------------------------
# Execute a command without showing action first, only the final result
# Useful for checks/tests where you only care about success/failure
#
# Usage: bdb_run "Checking git installation" command -v git
#
# Arguments:
#   $1 - Description of what's being checked/tested
#   $@ - Command and its arguments to execute
# Returns:
#   Exit code of the executed command
# Output:
#   Terminal: ✓ Checking git installation (or ✗ if failed)
#   Log: Complete command output with timestamps
# Behavior:
#   - Does NOT show action message first (unlike bdb_exec)
#   - Executes command silently with output to log only
#   - Shows only final result (success or failure)
# Example:
#   bdb_run "Verifying Python 3 is installed" python3 --version
#   bdb_run "Testing network connectivity" ping -c 1 google.com
bdb_run() {
    local description="$1"
    shift

    # Log detailed information (no terminal output yet)
    _bdb_log "========================================="
    _bdb_log "Check: ${description}"
    _bdb_log "Command: $*"
    _bdb_log "========================================="

    # Execute the command with output to log file
    if "$@" >&1 2>&1; then
        # Command succeeded - show success
        bdb_success "${description}"
        _bdb_log "Success: ${description}"
        return 0
    else
        # Command failed - show error
        local exit_code=$?
        bdb_error "${description}"
        _bdb_log "Failed: ${description} (exit code: ${exit_code})"
        return ${exit_code}
    fi
}

# -----------------------------------------------------------------------------
# Test Command Existence
# -----------------------------------------------------------------------------
# Check if a command exists in PATH and report the result
# Shows informational message (not success/error) since this is a test
#
# Usage:
#   if bdb_test_cmd "git"; then
#       # git is available
#   fi
#
# Arguments:
#   $1 - Command name to test
# Returns:
#   0 - Command exists
#   1 - Command not found
# Output:
#   Terminal: • Found: git (or • Not found: git)
#   Log: Test result recorded
# Example:
#   bdb_test_cmd "docker"
#   bdb_test_cmd "npm"
bdb_test_cmd() {
    local cmd="$1"

    # Check if command exists in PATH
    if command -v "${cmd}" >/dev/null 2>&1; then
        # Command found - show info message (not success)
        bdb_info "Found: ${cmd}"
        _bdb_log "Command exists: ${cmd}"
        return 0
    else
        # Command not found - show info message (not error)
        bdb_info "Not found: ${cmd}"
        _bdb_log "Command not found: ${cmd}"
        return 1
    fi
}

# -----------------------------------------------------------------------------
# Test File/Directory Existence
# -----------------------------------------------------------------------------
# Check if a file or directory exists and report the result with type
# Shows informational message since this is a test, not an operation
#
# Usage:
#   if bdb_test_path "/etc/os-release"; then
#       # file exists
#   fi
#
# Arguments:
#   $1 - Path to test (file or directory)
# Returns:
#   0 - Path exists
#   1 - Path not found
# Output:
#   Terminal: • File exists: /path/to/file
#             • Directory exists: /path/to/dir
#             • Not found: /path
#   Log: Test result with path type
# Example:
#   bdb_test_path "/usr/local/bin/chezmoi"
#   bdb_test_path "/home/user/.config"
bdb_test_path() {
    local path="$1"

    # Check if path exists and determine its type
    if [[ -e "${path}" ]]; then
        if [[ -f "${path}" ]]; then
            # It's a regular file
            bdb_info "File exists: ${path}"
            _bdb_log "File exists: ${path}"
        elif [[ -d "${path}" ]]; then
            # It's a directory
            bdb_info "Directory exists: ${path}"
            _bdb_log "Directory exists: ${path}"
        else
            # Some other type (symlink, socket, etc.)
            bdb_info "Path exists: ${path}"
            _bdb_log "Path exists: ${path}"
        fi
        return 0
    else
        # Path doesn't exist
        bdb_info "Not found: ${path}"
        _bdb_log "Path not found: ${path}"
        return 1
    fi
}

# -----------------------------------------------------------------------------
# Display Variable Value
# -----------------------------------------------------------------------------
# Show a variable name and its value as informational message
# Use this to display configuration values, detected settings, etc.
#
# Usage: bdb_var "OS" "Ubuntu 22.04"
#
# Arguments:
#   $1 - Variable name or label
#   $2 - Variable value
# Returns:
#   Always returns 0
# Output:
#   Terminal: • OS: Ubuntu 22.04 (in white)
#   Log: Variable name and value recorded
# Example:
#   bdb_var "Architecture" "x86_64"
#   bdb_var "Home Directory" "/home/user"
#   bdb_var "Package Manager" "apt"
bdb_var() {
    local name="$1"
    local value="$2"

    # Display variable in name: value format
    bdb_info "${name}: ${value}"
    _bdb_log "Variable: ${name}=${value}"
}

# =============================================================================
# UTILITY FUNCTIONS
# =============================================================================
# Helper functions for common operations like creating directories,
# downloading files, and checking dependencies
#
# These functions combine error handling with logging and provide
# consistent behavior across the bootstrap process

# -----------------------------------------------------------------------------
# Create Directory with Logging
# -----------------------------------------------------------------------------
# Create a directory (and parent directories) if it doesn't already exist
# Provides error handling and logging for directory creation operations
#
# Usage: bdb_mkdir "/path/to/directory" "Optional custom error message"
#
# Arguments:
#   $1 - Directory path to create
#   $2 - Optional custom error message (default: generic message)
# Returns:
#   0 - Directory created or already exists
#   1 - Failed to create directory
# Output:
#   Log: Directory creation attempt and result
#   Terminal: Error message if creation fails (via bdb_error)
# Example:
#   bdb_mkdir "/var/log/myapp"
#   bdb_mkdir "$HOME/.config/app" "Failed to create config directory"
bdb_mkdir() {
    local dir="$1"
    local error_msg="${2:-Failed to create directory: ${dir}}"

    # Check if directory already exists
    if [[ -d "${dir}" ]]; then
        _bdb_log "Directory already exists: ${dir}"
        return 0
    fi

    # Attempt to create directory with parents (-p)
    _bdb_log "Creating directory: ${dir}"
    if mkdir -p "${dir}" 2>&1 | tee -a /dev/fd/1 >/dev/null; then
        _bdb_log "Directory created: ${dir}"
        return 0
    else
        # Creation failed - show error and log
        bdb_error "${error_msg}"
        _bdb_log "Failed to create directory: ${dir}"
        return 1
    fi
}

# -----------------------------------------------------------------------------
# Download File
# -----------------------------------------------------------------------------
# Download a file from URL using curl or wget (whichever is available)
# Automatically detects and uses the best available download tool
#
# Usage: bdb_download "https://example.com/file.tar.gz" "/tmp/file.tar.gz"
#
# Arguments:
#   $1 - URL to download from
#   $2 - Local path to save file to
# Returns:
#   0 - Download successful
#   1 - Download failed or no tool available
# Output:
#   Log: Download attempt with tool used and result
#   Terminal: Error message if download fails or no tool found
# Behavior:
#   - Tries curl first (with -fsSL for silent, follow redirects)
#   - Falls back to wget if curl not available
#   - Shows error if neither tool is available
# Example:
#   bdb_download "https://get.chezmoi.io/chezmoi" "/usr/local/bin/chezmoi"
#   bdb_download "https://github.com/user/repo/archive/main.tar.gz" "/tmp/repo.tar.gz"
bdb_download() {
    local url="$1"
    local output="$2"

    _bdb_log "Downloading: ${url} -> ${output}"

    # Try curl first (preferred)
    if command -v curl >/dev/null 2>&1; then
        _bdb_log "Using curl"
        if curl -fsSL "${url}" -o "${output}" 2>&1 | tee -a /dev/fd/1 >/dev/null; then
            _bdb_log "Download successful"
            return 0
        fi
    # Fall back to wget if curl not available
    elif command -v wget >/dev/null 2>&1; then
        _bdb_log "Using wget"
        if wget -qO "${output}" "${url}" 2>&1 | tee -a /dev/fd/1 >/dev/null; then
            _bdb_log "Download successful"
            return 0
        fi
    else
        # Neither tool available
        bdb_error "Neither curl nor wget available"
        _bdb_log "Error: No download tool available"
        return 1
    fi

    # Download failed
    bdb_error "Download failed: ${url}"
    _bdb_log "Error: Download failed"
    return 1
}

# -----------------------------------------------------------------------------
# Check Command Exists (Silent)
# -----------------------------------------------------------------------------
# Silently check if a command exists in PATH without any output
# This is a convenience wrapper for use in conditionals
#
# Usage:
#   if bdb_has_cmd "git"; then
#       echo "Git is available"
#   fi
#
# Arguments:
#   $1 - Command name to check
# Returns:
#   0 - Command exists
#   1 - Command not found
# Output:
#   None - completely silent (no terminal or log output)
# Note:
#   For checks that need user feedback, use bdb_test_cmd instead
# Example:
#   if bdb_has_cmd "docker"; then
#       docker_available=true
#   fi
bdb_has_cmd() {
    command -v "$1" >/dev/null 2>&1
}

# -----------------------------------------------------------------------------
# Require Command (Exit if Missing)
# -----------------------------------------------------------------------------
# Check if a required command exists, exit script with error if not found
# Use this at the start of scripts for hard dependencies
#
# Usage: bdb_require "git" "Git is required for this script"
#
# Arguments:
#   $1 - Command name to require
#   $2 - Optional custom error message (default: generic message)
# Returns:
#   0 - Command exists (script continues)
#   Never returns if command not found (exits with code 1)
# Output:
#   Terminal: Error message if command not found
#   Log: Fatal error recorded before exit
# Behavior:
#   - Checks for command existence
#   - If found: returns silently, script continues
#   - If not found: shows error, logs fatal error, exits script
# Example:
#   bdb_require "curl" "curl is required to download files"
#   bdb_require "git"  # Uses default error message
bdb_require() {
    local cmd="$1"
    local msg="${2:-Command required but not found: ${cmd}}"

    # Check if command exists
    if ! bdb_has_cmd "${cmd}"; then
        # Command not found - show error, log, and exit
        bdb_error "${msg}"
        _bdb_log "Fatal: Required command not found: ${cmd}"
        exit 1
    fi

    # Command exists - return silently
}

# =============================================================================
# ERROR HANDLING
# =============================================================================
# Functions for handling errors and cleaning up resources
# These are typically called automatically via trap handlers
#
# Trap System:
#   ERR trap  → bdb_handle_error (on any command failure)
#   EXIT trap → bdb_cleanup (on script exit, success or failure)

# -----------------------------------------------------------------------------
# Handle Error
# -----------------------------------------------------------------------------
# Error handler called automatically when a command fails (via ERR trap)
# Captures error context, logs details, and exits with original error code
#
# Usage: trap 'bdb_handle_error' ERR
#
# This function is called automatically - do not call directly
#
# Arguments:
#   None - uses global variables set by bash:
#     $? - Exit code of failed command
#     $BASH_COMMAND - The command that failed
#     $BASH_LINENO - Line number where error occurred
# Returns:
#   Never returns - exits script with original error code
# Output:
#   Terminal: Error message with exit code
#             Log file location for debugging
#   Log: Detailed error information (command, exit code, line number)
# Behavior:
#   1. Disables command tracing to avoid noise
#   2. Captures error details (exit code, command, line)
#   3. Logs comprehensive error information
#   4. Shows user-friendly error message
#   5. Exits with original error code
# Example trap setup:
#   set -e  # Exit on error
#   trap 'bdb_handle_error' ERR
bdb_handle_error() {
    local exit_code=$?
    local cmd="${BASH_COMMAND}"

    # Disable command tracing for cleaner error output
    { set +x; } 2>/dev/null

    # Log comprehensive error details
    _bdb_log "========================================="
    _bdb_log "ERROR OCCURRED"
    _bdb_log "Exit code: ${exit_code}"
    _bdb_log "Command: ${cmd}"
    _bdb_log "Line: ${BASH_LINENO[0]}"
    _bdb_log "========================================="

    # Show user-friendly error message
    bdb_error "Script failed (exit code: ${exit_code})"
    bdb_info "Check log file for details: ${BDB_LOG_FILE:-bdb.log}"

    # Exit with original error code
    exit "${exit_code}"
}

# -----------------------------------------------------------------------------
# Cleanup
# -----------------------------------------------------------------------------
# Cleanup handler called automatically on script exit (via EXIT trap)
# Removes temporary files and restores environment to clean state
#
# Usage: trap 'bdb_cleanup' EXIT
#
# This function is called automatically - do not call directly
#
# Arguments:
#   None - uses global variables:
#     $BDB_TEMP_FILES - Space-separated list of temp files to remove
#     $BDB_HELPERS_URL, etc. - Environment variables to unset
# Returns:
#   Always returns 0
# Output:
#   Log: Cleanup operations recorded
#   Terminal: None (cleanup is silent)
# Behavior:
#   1. Disables command tracing
#   2. Removes temporary files (if any)
#   3. Unsets environment variables
#   4. Disables strict error handling
#   5. Restores file descriptors
# Example trap setup:
#   trap 'bdb_cleanup' EXIT
#   # Script automatically cleaned up on exit
bdb_cleanup() {
    # Disable command tracing for cleaner cleanup
    { set +x; } 2>/dev/null

    _bdb_log "========================================="
    _bdb_log "Cleanup started"
    _bdb_log "========================================="

    # Remove temporary files if any were created
    if [[ -n "${BDB_TEMP_FILES:-}" ]]; then
        for file in ${BDB_TEMP_FILES}; do
            if [[ -f "${file}" ]]; then
                rm -f "${file}" 2>/dev/null || true
                _bdb_log "Removed temporary file: ${file}"
            fi
        done
    fi

    # Clean up environment variables to avoid pollution
    unset BDB_HELPERS_URL BDB_HELPERS BDB_SCRIPT_DIR BDB_LOG_FILE BDB_TEMP_FILES

    # Disable strict error handling (safe for cleanup)
    set +euo pipefail 2>/dev/null

    # Restore file descriptors if they were redirected
    if [[ -t 3 ]]; then
        exec 1>&3 2>&1  # Restore stdout to FD3, stderr to stdout
        exec 3>&-       # Close FD3
    fi

    _bdb_log "Cleanup complete"
}

# =============================================================================
# SECTION HELPERS
# =============================================================================
# Functions for organizing script output into visual sections
# Use these to create clear separation between major phases of operation

# -----------------------------------------------------------------------------
# Begin Section
# -----------------------------------------------------------------------------
# Start a new section with a header and visual separator
# Use this to mark the beginning of major operations or phases
#
# Usage: bdb_begin_section "System Configuration"
#
# Arguments:
#   $* - Section title (all arguments concatenated)
# Returns:
#   Always returns 0
# Output:
#   Terminal:
#     ════════════════════════════════════════
#              System Configuration
#     ════════════════════════════════════════
#   Log: Section start marker with title
# Example:
#   bdb_begin_section "Installing Dependencies"
#   # ... installation operations ...
#   bdb_end_section
bdb_begin_section() {
    bdb_header "$*"
    _bdb_log "========================================="
    _bdb_log "SECTION: $*"
    _bdb_log "========================================="
}

# -----------------------------------------------------------------------------
# End Section
# -----------------------------------------------------------------------------
# End the current section with a footer and visual separator
# Use this to mark the completion of major operations or phases
#
# Usage: bdb_end_section
#
# Arguments:
#   None
# Returns:
#   Always returns 0
# Output:
#   Terminal:
#     ────────────────────────────────────────
#   Log: Section end marker
# Example:
#   bdb_begin_section "System Update"
#   # ... update operations ...
#   bdb_end_section
bdb_end_section() {
    bdb_footer
    _bdb_log "========================================="
    _bdb_log "SECTION END"
    _bdb_log "========================================="
}

# -----------------------------------------------------------------------------
# Progress Indicator
# -----------------------------------------------------------------------------
# Show progress through a multi-step process (step X of Y)
# Use this for operations that have multiple discrete steps
#
# Usage: bdb_progress 2 5 "Installing packages"
#
# Arguments:
#   $1 - Current step number
#   $2 - Total number of steps
#   $3 - Description of current step
# Returns:
#   Always returns 0
# Output:
#   Terminal: [2/5] Installing packages (in cyan)
#   Log: Progress information recorded
# Example:
#   total=3
#   bdb_progress 1 $total "Downloading files"
#   # ... download ...
#   bdb_progress 2 $total "Extracting archives"
#   # ... extract ...
#   bdb_progress 3 $total "Installing files"
#   # ... install ...
bdb_progress() {
    local current="$1"
    local total="$2"
    local description="$3"

    # Display progress in [current/total] format
    printf "%s[%d/%d] %s%s\n" \
        "${C_CYN}" \
        "${current}" \
        "${total}" \
        "${description}" \
        "${C_RST}" >&3

    _bdb_log "Progress: [${current}/${total}] ${description}"
}

# =============================================================================
# INITIALIZATION
# =============================================================================
# Setup function for initializing the logging system
# Must be called before using any other BDB helper functions

# -----------------------------------------------------------------------------
# Setup Logging
# -----------------------------------------------------------------------------
# Initialize the dual-output logging system
# This MUST be called at the start of your script before any other BDB functions
#
# IMPORTANT: This function is idempotent and context-aware
# - If logging is already initialized (e.g., by a parent bootstrap script),
#   it will detect this and skip re-initialization
# - This allows chezmoi scripts to work both standalone and under bootstrap
#
# Detection Logic:
#   1. Checks if BDB_LOG_FILE is already set
#   2. Checks if FD3 is already configured
#   3. If both are true, continues with existing logging setup
#   4. Otherwise, initializes new logging
#
# Logging Strategy:
#   - Commands are NOT logged (no 'set -x')
#   - Only command OUTPUT is logged
#   - Timestamps added to important markers (sections, actions, results)
#   - This keeps logs clean and focused on actual results
#
# Usage: bdb_init_logging "/path/to/logfile.log"
#        bdb_init_logging  # Uses BDB_LOG_FILE if set, or generates default
#
# Arguments:
#   $1 - Optional log file path
#        If not provided, uses these in order of precedence:
#        1. Existing BDB_LOG_FILE variable (if set by caller)
#        2. Generated default: bdb_YYYYMMDD_HHMMSS.log
# Returns:
#   0 - Always returns success (exits on error)
# Output:
#   Creates log file and sets up file descriptors (if not already initialized)
# Behavior:
#   If already initialized:
#     - Logs a marker indicating continuation with existing setup
#     - Returns without modifying file descriptors
#   If not initialized:
#     1. Determines log file path (argument > existing var > default)
#     2. Exports BDB_LOG_FILE for use by other functions
#     3. Creates or opens log file
#     4. Sets up FD3 for terminal output (if not already set)
#     5. Redirects stdout (FD1) to log file
#     6. Redirects stderr (FD2) to log file
#     7. Enables command tracing (set -x) in log
#     8. Writes initialization header to log
# Side Effects:
#   - Sets/updates global variable: BDB_LOG_FILE
#   - Redirects stdout/stderr to log file (if not already redirected)
#   - All subsequent command output goes to log
#   - Terminal output must use FD3 (>&3)
# Example:
#   # Option 1: Standalone script with explicit path
#   bdb_init_logging "/var/log/myapp/setup.log"
#
#   # Option 2: Pre-set variable (common in bootstrap scripts)
#   BDB_LOG_FILE="${HOME}/setup_$(date +%Y%m%d).log"
#   bdb_init_logging "${BDB_LOG_FILE}"
#
#   # Option 3: Chezmoi script (auto-detects if running under bootstrap)
#   SCRIPT_LOG_FILE="${HOME}/.cache/chezmoi/myscript.log"
#   bdb_init_logging "${SCRIPT_LOG_FILE}"
#   # If under bootstrap: continues with bootstrap log
#   # If standalone: creates myscript.log
#
#   # Option 4: Use default generated name
#   bdb_init_logging
#   # Creates: bdb_20250115_143022.log
bdb_init_logging() {
    # Check if logging is already initialized (BDB_LOG_FILE is set and FD3 exists)
    if [[ -n "${BDB_LOG_FILE:-}" ]] && [[ -t 3 ]]; then
        # Logging already initialized (probably by parent bootstrap script)
        # Just log that we're continuing with existing setup
        _bdb_log "========================================="
        _bdb_log "BDB Logging already initialized"
        _bdb_log "Existing log file: ${BDB_LOG_FILE}"
        _bdb_log "Continuing with parent logging setup"
        _bdb_log "========================================="
        return 0
    fi

    # Use provided argument, or fall back to already-set BDB_LOG_FILE,
    # or generate default filename
    local log_file="${1:-${BDB_LOG_FILE:-bdb_$(date +%Y%m%d_%H%M%S).log}}"

    # Export log file path for use by other functions
    # This will update BDB_LOG_FILE if it was already set in calling script
    export BDB_LOG_FILE="${log_file}"

    # Attempt to create log file
    touch "${BDB_LOG_FILE}" 2>/dev/null || {
        echo "Error: Cannot create log file: ${BDB_LOG_FILE}" >&2
        exit 1
    }

    # Setup file descriptor 3 for terminal output if not already set
    # FD3 will be used for all user-facing messages
    if [[ ! -t 3 ]]; then
        exec 3>&1  # Save current stdout to FD3
    fi

    # Redirect stdout and stderr to log file
    # All command output will now go to the log
    exec 1>>"${BDB_LOG_FILE}"  # Append stdout to log file
    exec 2>&1                   # Redirect stderr to stdout (log file)

    # Note: We do NOT enable 'set -x' (command tracing) here
    # This prevents every bash command from being logged with '+'
    # We only want to log command OUTPUT, not the commands themselves
    # Commands are already documented via _bdb_log calls

    # Write initialization header to log
    _bdb_log "========================================="
    _bdb_log "BDB Bootstrap Log"
    _bdb_log "Started: $(date '+%Y-%m-%d %H:%M:%S')"
    _bdb_log "Log file: ${BDB_LOG_FILE}"
    _bdb_log "========================================="
}

# =============================================================================
# USAGE EXAMPLES
# =============================================================================
#
# Complete example showing proper initialization and usage:
#
# #!/usr/bin/env bash
#
# # Source the helper functions
# source /path/to/bdb_helpers.sh
#
# # Initialize logging FIRST
# bdb_init_logging "/var/log/myapp/install.log"
#
# # Setup error handling (recommended)
# set -euo pipefail                   # Exit on error, undefined vars, pipe failures
# trap 'bdb_handle_error' ERR         # Handle errors automatically
# trap 'bdb_cleanup' EXIT             # Cleanup on exit
# trap '_bdb_log_timestamp' DEBUG     # Add timestamps to log entries
#
# # Start your script
# bdb_begin_section "System Setup"
#
# # Show what you're about to do
# bdb_action "Detecting operating system"
# OS=$(uname -s)
# bdb_var "Operating System" "${OS}"
#
# # Execute commands with automatic status reporting
# bdb_exec "Installing git" sudo apt-get install -y git
#
# # Test for command existence
# if bdb_test_cmd "git"; then
#     bdb_success "Git is available"
# else
#     bdb_error "Git installation failed"
#     exit 1
# fi
#
# # Ask user for confirmation
# if bdb_ask "Continue with installation"; then
#     bdb_action "Starting installation process"
#
#     # Show progress through multi-step process
#     bdb_progress 1 3 "Downloading files"
#     # ... download code ...
#
#     bdb_progress 2 3 "Extracting files"
#     # ... extraction code ...
#
#     bdb_progress 3 3 "Installing files"
#     # ... installation code ...
#
#     bdb_success "Installation complete"
# else
#     bdb_warn "Installation cancelled by user"
#     exit 0
# fi
#
# # End section
# bdb_end_section
#
# # Script automatically cleaned up on exit via trap
#
# =============================================================================
# FUNCTION QUICK REFERENCE
# =============================================================================
#
# Terminal Output:
#   bdb_action "message"      - Show upcoming action (cyan)
#   bdb_success "message"     - Show success (green)
#   bdb_error "message"       - Show error (red)
#   bdb_warn "message"        - Show warning (yellow)
#   bdb_info "message"        - Show info (white)
#   bdb_var "name" "value"    - Show variable (white)
#
# Command Execution:
#   bdb_exec "desc" command   - Execute with action → result
#   bdb_run "desc" command    - Execute, show only result
#   bdb_test_cmd "command"    - Test if command exists
#   bdb_test_path "/path"     - Test if path exists
#
# User Interaction:
#   bdb_ask "question"        - Yes/no prompt (default: no)
#   bdb_ask_yes "question"    - Yes/no prompt (default: yes)
#   bdb_input "prompt"        - Get text input
#
# Utilities:
#   bdb_mkdir "/path"         - Create directory
#   bdb_download "url" "path" - Download file
#   bdb_has_cmd "command"     - Silent command check
#   bdb_require "command"     - Require command or exit
#
# Sections:
#   bdb_begin_section "title" - Start section
#   bdb_end_section           - End section
#   bdb_progress 1 5 "desc"   - Show progress
#
# Initialization:
#   bdb_init_logging "file"   - Initialize logging (call first!)
#
# =============================================================================
# END OF HELPER FUNCTIONS
# =============================================================================