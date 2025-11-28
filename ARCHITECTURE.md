# Dotfiles System Architecture

## Overview

BDB (Bassa's Dotfiles Bootstrapper) is a comprehensive, multi-phase dotfiles management system built on [Chezmoi](https://www.chezmoi.io/). The system provides automated installation, configuration, and maintenance of development environments across multiple operating systems and architectures.

### Design Philosophy

1. **Separation of Concerns** - Bootstrap handles installation, Chezmoi handles configuration
2. **Idempotent Operations** - All scripts can run multiple times safely
3. **Progressive Enhancement** - Core → Optional → Configuration → Updates
4. **Platform Abstraction** - OS-specific logic isolated in templates
5. **User-Centric Design** - Clear feedback, sensible defaults, optional prompts

## System Components

### 1. Bootstrap Phase (bdb_bootstrap.sh)

**Purpose**: Install Chezmoi and dependencies on fresh systems

**Location**: `dot_config/bdb/bdb_bootstrap.sh`

**Responsibilities**:
- Detect operating system and distribution
- Update system packages (with user confirmation)
- Install git and chezmoi
- Initialize dotfiles repository
- Set up logging system

**Entry Points**:
```bash
# Remote execution
bash -c "$(curl -fsSL https://raw.githubusercontent.com/norville/dotfiles/main/dot_config/bdb/bdb_bootstrap.sh)"

# Local execution
./dot_config/bdb/bdb_bootstrap.sh
```

**Does NOT**:
- Install application packages (handled by chezmoi scripts)
- Configure shell or applications (handled by chezmoi)
- Manage dotfile updates (handled by chezmoi update)

### 2. Helper Functions Library (bdb_helpers.sh)

**Purpose**: Provide consistent UI, logging, and utility functions

**Location**: `dot_config/bdb/bdb_helpers.sh`

**Key Features**:
- Dual-output logging (terminal + file)
- Color-coded status messages
- User interaction helpers
- Command execution wrappers
- Error handling and cleanup

**Design Pattern**: Sourced by both bootstrap and chezmoi scripts

### 3. Chezmoi Configuration (.chezmoi.toml.tmpl)

**Purpose**: Configure chezmoi behavior and define template variables

**Location**: `.chezmoi.toml.tmpl`

**Key Responsibilities**:
- OS and distribution detection
- CPU architecture detection
- Package manager identification
- Template variable definition
- Script environment setup

**Generated Variables** (available in all `.tmpl` files):
- `osid` - OS identifier (darwin, linux-ubuntu, linux-fedora, etc.)
- `packageManager` - Package manager (brew, apt, dnf, pacman)
- `cpuArch` - CPU architecture (amd64, arm64, x86_64, aarch64)
- `isARM`, `isIntel`, `isAppleSilicon` - Architecture flags
- `email`, `name` - User information

### 4. Installation Scripts (.chezmoiscripts/)

**Purpose**: Install and configure packages and environment

**Location**: `.chezmoiscripts/`

**Execution**: Automatic during `chezmoi apply`

**Scripts** (executed in order):

#### 00-required-packages.sh.tmpl
- **When**: Runs when file changes (`onchange`)
- **Purpose**: Install essential tools
- **Installs**: git, zsh, neovim, bat, eza, fzf, ripgrep, lazygit, kitty, starship
- **Platform-specific**: Different package sets per OS/distribution

#### 01-optional-packages.sh.tmpl
- **When**: Runs when file changes (`onchange`)
- **Purpose**: Prompt for optional software
- **Prompts for**: 1Password, Docker, VS Code, Ansible
- **User control**: Each package requires explicit confirmation

#### 02-env-setup.sh.tmpl
- **When**: Runs when file changes (`onchange`)
- **Purpose**: Configure environment and applications
- **Actions**: Set ZSH as default, configure themes, verify installations

#### 03-env-update.sh.tmpl
- **When**: Runs after `chezmoi update` only (not on regular apply)
- **Purpose**: Update packages and tools
- **Actions**: Update system packages, update ZSH plugins, rebuild caches

## Execution Flow

### Initial Installation

```
┌─────────────────────────────────────────────────────────────┐
│                    User Runs Bootstrap                      │
│  bash -c "$(curl -fsSL https://.../bdb_bootstrap.sh)"       │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│               Bootstrap Phase (bdb_bootstrap.sh)            │
├─────────────────────────────────────────────────────────────┤
│  1. Detect OS & Distribution (detect_os)                    │
│     • Sets: PLATFORM (Darwin/Linux)                         │
│     • Sets: DISTRO (macos/ubuntu/fedora/arch/etc)           │
│  2. Update System (update_system)                           │
│     • Prompts user for confirmation                         │
│     • Calls OS-specific update function                     │
│  3. Install Dependencies (install_dependencies)             │
│     • Installs git (if missing)                             │
│     • Installs chezmoi (package manager or script)          │
│  4. Initialize Dotfiles (init_dotfiles)                     │
│     • Runs: chezmoi init --branch main --apply norville     │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│            Chezmoi Initialization & Apply                   │
├─────────────────────────────────────────────────────────────┤
│  1. Clone Repository                                        │
│     • git clone https://github.com/norville/dotfiles        │
│     • Store in: ~/.local/share/chezmoi                      │
│  2. Process Templates (.chezmoi.toml.tmpl)                  │
│     • Generate: ~/.config/chezmoi/chezmoi.toml              │
│     • Define template variables (osid, packageManager, etc) │
│  3. Apply Dotfiles                                          │
│     • Copy/template files to home directory                 │
│     • Download external resources (.chezmoiexternal)        │
│  4. Execute Scripts (.chezmoiscripts/)                      │
│     • Run in alphanumeric order                             │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│          00-required-packages.sh.tmpl                       │
├─────────────────────────────────────────────────────────────┤
│  • Update package cache                                     │
│  • Install core packages:                                   │
│    - Shell: zsh                                             │
│    - Editor: neovim, vim                                    │
│    - Tools: bat, eza, fzf, ripgrep, fd                      │
│    - Terminal: kitty                                        │
│    - Git UI: lazygit                                        │
│    - Prompt: starship                                       │
│  • Install fonts (JetBrains Mono Nerd Font)                 │
│  • OS-specific package installation                         │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│          01-optional-packages.sh.tmpl                       │
├─────────────────────────────────────────────────────────────┤
│  For each optional package:                                 │
│    1. Prompt: "Do you want to install X?"                   │
│    2. If yes: Install using appropriate method              │
│    3. If no: Skip and continue                              │
│                                                             │
│  Optional Packages:                                         │
│  • 1Password (password manager + SSH agent)                 │
│    - macOS: Homebrew cask                                   │
│    - Linux ARM: .tar.gz installation                        │
│    - Linux x86: Official repositories                       │
│  • Docker (container platform)                              │
│    - Official Docker repositories                           │
│    - Add user to docker group                               │
│  • Visual Studio Code (editor)                              │
│    - Microsoft repositories                                 │
│  • Ansible (automation platform)                            │
│    - Ubuntu LTS: PPA (ppa:ansible/ansible)                  │
│    - Ubuntu Interim: pipx                                   │
│    - Other distros: Official repos                          │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│          02-env-setup.sh.tmpl                               │
├─────────────────────────────────────────────────────────────┤
│  • Configure Applications:                                  │
│    - Build bat theme cache                                  │
│    - Verify eza theme installation                          │
│    - Configure btop theme                                   │
│  • Set ZSH as Default Shell (Linux):                        │
│    - Add to /etc/shells if needed                           │
│    - Run: chsh -s $(which zsh)                              │
│  • Font Configuration (Linux):                              │
│    - Verify font installation                               │
│    - Update font cache (fc-cache)                           │
│  • Verify Configurations:                                   │
│    - Check kitty config exists                              │
│    - Verify all themes loaded                               │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│                   Installation Complete!                    │
│                                                             │
│  User must log out and back in to:                          │
│  • Load ZSH as default shell                                │
│  • Apply group memberships (docker, etc)                    │
│  • Ensure all environment variables loaded                  │
└─────────────────────────────────────────────────────────────┘
```

### Update Flow

```
┌─────────────────────────────────────────────────────────────┐
│                 User Runs: chezmoi update                   │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│                 Chezmoi Update Process                      │
├─────────────────────────────────────────────────────────────┤
│  1. Pull latest changes from repository                     │
│  2. Apply any configuration updates                         │
│  3. Run update scripts only (run_after_* scripts)           │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│             03-env-update.sh.tmpl                           │
├─────────────────────────────────────────────────────────────┤
│  • Update System Packages:                                  │
│    - macOS: brew update && brew upgrade                     │
│    - Ubuntu/Debian: apt-get update && upgrade               │
│    - Fedora/RHEL: dnf upgrade                               │
│    - Arch/Manjaro: pacman -Syu                              │
│  • Update Additional Package Managers:                      │
│    - Snap (Ubuntu)                                          │
│    - Flatpak (Fedora)                                       │
│    - AUR/yay (Arch)                                         │
│  • Update ZSH Plugins:                                      │
│    - Update Antidote itself                                 │
│    - Run: antidote update                                   │
│  • Rebuild Caches:                                          │
│    - bat cache --build                                      │
│    - fc-cache (font cache on Linux)                         │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│                    Update Complete!                         │
│  All packages, plugins, and caches are now current          │
└─────────────────────────────────────────────────────────────┘
```

## Variable Scopes and Lifecycles

### Bootstrap-Only Variables

**Scope**: Only available in `bdb_bootstrap.sh`

| Variable | Type | Example Values | Purpose |
|----------|------|----------------|---------|
| `PLATFORM` | String | `Darwin`, `Linux` | OS type from `uname -s` |
| `DISTRO` | String | `macos`, `ubuntu`, `fedora`, `arch` | Distribution identifier |
| `BDB_LOG_FILE` | Path | `bdb_log_20250128_143022.txt` | Bootstrap log file location |
| `BDB_HELPERS` | Path | `/path/to/bdb_helpers.sh` | Helper functions location |
| `BDB_TEMP_FILES` | String | Space-separated file list | Temp files to clean up |

**Note**: These variables are NOT exported to chezmoi scripts. Bootstrap provides minimal OS detection just to install chezmoi. Detailed detection happens in chezmoi templates.

### Chezmoi Template Variables

**Scope**: Available in ALL `.tmpl` files (configs and scripts)

**Defined in**: `.chezmoi.toml.tmpl`

| Variable | Type | Example Values | Purpose |
|----------|------|----------------|---------|
| `.osid` | String | `darwin`, `linux-ubuntu`, `linux-fedora` | Full OS identifier |
| `.packageManager` | String | `brew`, `apt`, `dnf`, `pacman` | Primary package manager |
| `.cpuArch` | String | `amd64`, `arm64`, `x86_64`, `aarch64` | CPU architecture |
| `.isARM` | Boolean | `true`, `false` | Is ARM-based CPU |
| `.isIntel` | Boolean | `true`, `false` | Is Intel/AMD x86_64 CPU |
| `.isAppleSilicon` | Boolean | `true`, `false` | Is Apple Silicon (M1/M2/M3) |
| `.email` | String | `user@example.com` | User email address |
| `.name` | String | `User Name` | User full name |

**Access in Templates**:
```bash
{{- if eq .osid "linux-ubuntu" }}
  # Ubuntu-specific code
{{- end }}

{{- if .isAppleSilicon }}
  # Apple Silicon specific code
{{- end }}
```

### Script Environment Variables

**Scope**: Available in ALL chezmoi scripts (`.chezmoiscripts/`)

**Defined in**: `.chezmoi.toml.tmpl` → `[scriptEnv]` section

| Variable | Type | Example Value | Purpose |
|----------|------|---------------|---------|
| `HELPERS` | Path | `/home/user/.config/bdb/bdb_helpers.sh` | Path to helper functions |

**Usage in Scripts**:
```bash
# All chezmoi scripts start with:
source "${HELPERS}"
```

## Logging System

### Dual-Output Architecture

The logging system uses a dual-output design to provide clean terminal output while maintaining comprehensive logs.

```
┌──────────────────────────────────────────────────────────┐
│                    Command Execution                     │
│            (e.g., sudo apt-get install git)              │
└────────────┬─────────────────────────┬───────────────────┘
             │                         │
             │                         │
    ┌────────▼────────┐       ┌────────▼────────┐
    │   STDOUT (FD1)  │       │   STDERR (FD2)  │
    │  Command output │       │  Error messages │
    └────────┬────────┘       └────────┬────────┘
             │                         │
             │                         │
             └──────────┬──────────────┘
                        │
                        ▼
            ┌───────────────────────┐
            │      Log File         │
            │  (Complete audit)     │
            │  • Timestamps         │
            │  • All output         │
            │  • Command results    │
            └───────────────────────┘


┌──────────────────────────────────────────────────────────┐
│              User-Facing Messages                        │
│         (bdb_action, bdb_success, etc.)                  │
└────────────┬─────────────────────────────────────────────┘
             │
             ▼
    ┌────────────────┐
    │   FD3 (custom) │
    │  Terminal only │
    │  • Color coded │
    │  • Clean       │
    │  • Minimal     │
    └────────────────┘
```

### File Descriptor Setup

**FD1 (stdout)** → Log file (verbose, all command output)
**FD2 (stderr)** → Log file (errors and diagnostics)
**FD3 (custom)** → Terminal (user-facing, clean, colored)

**Setup in Bootstrap**:
```bash
# In bdb_init_logging()
exec 3>&1                    # Save stdout to FD3
exec 1>>"${BDB_LOG_FILE}"    # Redirect stdout to log
exec 2>&1                    # Redirect stderr to stdout (log)
```

**Setup in Chezmoi Scripts**:
```bash
# Scripts check if already initialized by bootstrap
if [[ -n "${BDB_LOG_FILE:-}" ]] && [[ -t 3 ]]; then
    # Already initialized - continue with existing setup
else
    # Not initialized - set up new logging
    bdb_init_logging "${SCRIPT_LOG_FILE}"
fi
```

### Logging Behavior

**What Gets Logged**:
- ✅ Command output (stdout/stderr)
- ✅ Timestamps for important events
- ✅ Section markers
- ✅ Success/failure results
- ✅ User responses to prompts

**What Does NOT Get Logged**:
- ❌ Every bash command (no `set -x`)
- ❌ Helper function internals
- ❌ Color codes (logs are plain text)

**Rationale**: Logs focus on **what happened** (results), not **how it happened** (commands). This keeps logs clean and useful for debugging.

### Log File Locations

**Bootstrap Log**:
```
Location: Same directory as bdb_bootstrap.sh
Format: bdb_log_YYYYMMDD_HHMMSS.txt
Example: bdb_log_20250128_143022.txt
When: Created at bootstrap start
```

**Chezmoi Script Logs** (when run standalone):
```
Location: ~/.cache/chezmoi/
Format: scriptname_YYYYMMDD_HHMMSS.log
Example: run_onchange_after_00-required-packages_20250128_150034.log
When: Created when script runs outside bootstrap
```

**Unified Logging** (during bootstrap):
All chezmoi scripts detect the existing `BDB_LOG_FILE` and append to the bootstrap log instead of creating separate files. This provides a complete audit trail in a single file.

## Helper Functions (bdb_helpers.sh)

### Function Categories

#### Terminal Output Functions
```bash
# Show upcoming action (cyan with arrow)
bdb_action "Installing packages"

# Show success (green with checkmark)
bdb_success "Installation complete"

# Show error (red with X)
bdb_error "Installation failed"

# Show warning (yellow with !)
bdb_warn "Package not available"

# Show information (white with bullet)
bdb_info "Using default configuration"

# Display variable value
bdb_var "OS Version" "Ubuntu 24.04"
```

#### Command Execution Functions
```bash
# Execute command with full status reporting
# Shows: → action ... then ✓ success or ✗ error
bdb_exec "Installing git" sudo apt-get install -y git

# Execute command, show only final result
# Shows only: ✓ result or ✗ error
bdb_run "Checking git installation" command -v git

# Test if command exists (returns 0/1, shows info message)
if bdb_test_cmd "git"; then
    # git exists
fi

# Test if path exists (returns 0/1, shows info message)
if bdb_test_path "/usr/bin/git"; then
    # path exists
fi
```

#### User Interaction Functions
```bash
# Ask yes/no question (default: no)
if bdb_ask "Continue with installation"; then
    # User said yes
fi

# Ask yes/no question (default: yes)
if bdb_ask_yes "Apply configuration"; then
    # User said yes or pressed Enter
fi

# Get text input from user
username=$(bdb_input "Enter your username")
```

#### Section Organization Functions
```bash
# Start major section (shows header with border)
bdb_begin_section "System Configuration"

# End major section (shows footer)
bdb_end_section

# Show progress through multi-step process
bdb_progress 2 5 "Installing packages"  # Shows: [2/5] Installing packages
```

#### Utility Functions
```bash
# Create directory (with error handling)
bdb_mkdir "/var/log/myapp" "Failed to create log directory"

# Download file (tries curl, falls back to wget)
bdb_download "https://example.com/file" "/tmp/file"

# Check if command exists (silent, returns 0/1)
if bdb_has_cmd "git"; then
    # git exists
fi

# Require command or exit script
bdb_require "git" "Git is required for this script"
```

#### Initialization Function
```bash
# Initialize logging system (call at start of every script)
bdb_init_logging "/path/to/logfile.log"

# Context-aware: detects if already initialized by bootstrap
# If yes: continues with existing logging
# If no: sets up new logging
```

### Color Scheme

All terminal output uses consistent color coding:

| Color | Purpose | Example Usage |
|-------|---------|---------------|
| **Cyan** (→) | Upcoming actions | `bdb_action "Installing..."` |
| **Green** (✓) | Success messages | `bdb_success "Complete"` |
| **Red** (✗) | Errors/failures | `bdb_error "Failed"` |
| **Yellow** (!) | Warnings/alerts | `bdb_warn "Skipping..."` |
| **White** (•) | Information/variables | `bdb_info "Using..."` |
| **Magenta** (?) | User prompts | `bdb_ask "Continue?"` |

## Platform-Specific Logic

### OS Detection Strategy

**Bootstrap** (minimal detection):
```bash
# Detects just enough to install chezmoi
PLATFORM=$(uname -s)  # Darwin or Linux
DISTRO=$(grep ID /etc/os-release ...)  # ubuntu, fedora, arch, etc
```

**Chezmoi** (comprehensive detection):
```go
// In .chezmoi.toml.tmpl
osid = "linux-ubuntu"  // Combines OS + distribution
packageManager = "apt"  // Determines installation method
cpuArch = "arm64"      // Hardware architecture
isARM = true           // Boolean flags for easy checks
```

### Conditional Execution Patterns

#### Pattern 1: OS-Specific Blocks
```bash
{{- if eq .chezmoi.os "darwin" }}
  # macOS-only code
  brew install package
{{- else if eq .chezmoi.os "linux" }}
  # Linux-only code
  sudo apt-get install package
{{- end }}
```

#### Pattern 2: Distribution-Specific Blocks
```bash
{{- if eq .osid "linux-ubuntu" }}
  # Ubuntu-specific
{{- else if eq .osid "linux-fedora" }}
  # Fedora-specific
{{- else if eq .osid "linux-arch" }}
  # Arch-specific
{{- end }}
```

#### Pattern 3: Package Manager Routing
```bash
{{- if eq .packageManager "apt" }}
  sudo apt-get install -y package
{{- else if eq .packageManager "dnf" }}
  sudo dnf install -y package
{{- else if eq .packageManager "pacman" }}
  sudo pacman -S --noconfirm package
{{- else if eq .packageManager "brew" }}
  brew install package
{{- end }}
```

#### Pattern 4: Architecture-Specific
```bash
{{- if .isARM }}
  # ARM-specific installation (e.g., 1Password .tar.gz)
{{- else if .isIntel }}
  # x86_64 installation (e.g., standard repositories)
{{- end }}

{{- if .isAppleSilicon }}
  # Apple Silicon specific (e.g., /opt/homebrew paths)
{{- end }}
```

### Supported Platforms

| Platform | Distribution | Package Manager | Notes |
|----------|--------------|-----------------|-------|
| **macOS** | Darwin | Homebrew | Intel and Apple Silicon |
| **Ubuntu** | linux-ubuntu | APT + Snap | LTS and interim releases |
| **Debian** | linux-debian | APT | Stable, testing, unstable |
| **Fedora** | linux-fedora | DNF + Flatpak | Current releases |
| **RHEL** | linux-rhel | DNF | Enterprise Linux |
| **Arch** | linux-arch | Pacman + AUR | Rolling release |
| **Manjaro** | linux-manjaro | Pacman + AUR | Arch-based |

## External Resources

### Chezmoi External Files (.chezmoiexternal.toml.tmpl)

Manages external resources that aren't version-controlled in the dotfiles repo.

**Examples**:
- Tokyo Night themes (bat, eza, btop)
- JetBrains Mono Nerd Font (Linux only)
- Third-party configurations

**Refresh Strategy**:
- Weekly (168h): Themes and frequently updated resources
- Monthly (720h): Fonts and stable resources

**Management**:
```bash
# Download all external resources
chezmoi apply

# Force update external resources
chezmoi update

# Check external resource status
chezmoi verify
```

## Error Handling

### Trap System

**Bootstrap and all chezmoi scripts use**:
```bash
set -euo pipefail              # Strict error handling
trap 'bdb_handle_error' ERR    # Auto error handling
trap 'bdb_cleanup' EXIT        # Auto cleanup
```

### Error Handler (bdb_handle_error)

**Triggered**: Automatically when any command fails

**Actions**:
1. Captures exit code and failed command
2. Logs comprehensive error details
3. Shows user-friendly error message
4. Exits with original error code

**Example Output**:
```
Terminal: ✗ Script failed (exit code: 1)
          • Check log file for details: bdb_log_20250128_143022.txt

Log File: =========================================
          ERROR OCCURRED
          Exit code: 1
          Command: apt-get install nonexistent-package
          Line: 42
          =========================================
```

### Cleanup Handler (bdb_cleanup)

**Triggered**: Automatically on script exit (success or failure)

**Actions**:
1. Removes temporary files (from `BDB_TEMP_FILES`)
2. Attempts to unset environment variables (gracefully handles readonly)
3. Disables strict error handling
4. Restores file descriptors

**Design**: Cleanup always succeeds - errors are suppressed to ensure clean exit

## File Organization

### Repository Structure

```
dotfiles/
├── .chezmoi.toml.tmpl              # Chezmoi configuration
├── .chezmoiexternal.toml.tmpl      # External resources
├── .chezmoiignore                  # Files to exclude
├── .chezmoiscripts/                # Installation scripts
│   ├── run_onchange_after_00-required-packages.sh.tmpl
│   ├── run_onchange_after_01-optional-packages.sh.tmpl
│   ├── run_onchange_after_02-env-setup.sh.tmpl
│   └── run_after_03-env-update.sh.tmpl
├── dot_config/                     # Configuration files
│   ├── bdb/                        # Bootstrap system
│   │   ├── bdb_bootstrap.sh        # Bootstrap script
│   │   └── bdb_helpers.sh          # Helper functions
│   ├── bat/                        # Bat configuration
│   ├── kitty/                      # Kitty terminal config
│   ├── nvim/                       # Neovim configuration
│   ├── git/                        # Git configuration
│   ├── homebrew/                   # Homebrew bundle (macOS)
│   └── starship/                   # Starship prompt config
├── dot_zsh/                        # ZSH configurations
│   ├── aliases.zsh                 # Shell aliases
│   └── antidote.zsh                # Plugin manager
├── dot_zshrc.tmpl                  # Main ZSH config
├── dot_ssh/                        # SSH configuration
├── README.md                       # User documentation
└── ARCHITECTURE.md                 # This file
```

### Naming Conventions

**Chezmoi Templates**:
- `.tmpl` extension = Template file (variables substituted)
- `dot_` prefix = Creates file starting with `.` (e.g., `dot_zshrc` → `.zshrc`)

**Chezmoi Scripts**:
- `run_onchange_` = Runs when file content changes
- `run_after_` = Runs after other scripts
- Number prefix = Execution order (00, 01, 02, 03)

## Design Decisions

### Why Separate Bootstrap and Chezmoi?

**Bootstrap** handles the "chicken and egg" problem:
- Fresh system doesn't have chezmoi
- Can't use chezmoi without installing it first
- Bootstrap is the minimal installer

**Chezmoi** handles everything else:
- Much more powerful templating
- Built-in update mechanism
- Native cross-platform support
- Proper state management

### Why Dual Logging?

**Terminal** (FD3):
- Users want clean, readable output
- Color-coded for quick scanning
- Minimal, just status updates

**Log File** (FD1/FD2):
- Developers/troubleshooters need details
- Complete command output
- Timestamps for debugging
- Permanent audit trail

### Why Helper Functions?

**Consistency**:
- Same UI across all scripts
- Same error handling everywhere
- Same logging format

**DRY Principle**:
- Write once, use many times
- Easier to maintain
- Bugs fixed in one place

**Portability**:
- Abstracts OS differences
- Handles missing commands gracefully
- Works on all supported platforms

### Why Template Variables?

**Flexibility**:
- Single repository, multiple platforms
- OS-specific logic in templates
- No need for multiple branches

**Maintainability**:
- Changes in one place
- No code duplication
- Easy to add new platforms

## Common Workflows

### Adding a New Optional Package

1. Edit `.chezmoiscripts/run_onchange_after_01-optional-packages.sh.tmpl`
2. Add installation block:
```bash
# -----------------------------------------------------------------------------
# PackageName - Description
# -----------------------------------------------------------------------------
if bdb_ask "Do you want to install PackageName"; then
    {{- if eq .packageManager "apt" }}
        bdb_exec "Installing PackageName" sudo apt-get install -y packagename
    {{- else if eq .packageManager "dnf" }}
        bdb_exec "Installing PackageName" sudo dnf install -y packagename
    {{- else if eq .packageManager "pacman" }}
        bdb_exec "Installing PackageName" sudo pacman -S --noconfirm packagename
    {{- else if eq .packageManager "brew" }}
        bdb_exec "Installing PackageName" brew install packagename
    {{- end }}
else
    bdb_warn "Skipping PackageName installation"
fi
```
3. Test on VM
4. Update README.md
5. Commit and push

### Adding Support for New Distribution

1. Update `.chezmoi.toml.tmpl`:
```go
{{- else if eq .osid "linux-newdistro" -}}
    {{- $packageManager = "new-pm" -}}
```
2. Add package installation in all scripts:
```bash
{{- else if eq .packageManager "new-pm" }}
    # New distribution installation
```
3. Test thoroughly
4. Document in README.md

### Debugging Installation Issues

1. **Find the log file**:
```bash
# Bootstrap log
ls -lt bdb_log_*.txt | head -1

# Script log
ls -lt ~/.cache/chezmoi/*.log | head -1
```

2. **Review log for errors**:
```bash
grep -i error bdb_log_*.txt
grep "exit code" bdb_log_*.txt
```

3. **Check specific section**:
```bash
# Find section markers
grep "=========" bdb_log_*.txt

# View specific section
sed -n '/SECTION: Installing Dependencies/,/SECTION END/p' bdb_log_*.txt
```

4. **Verify chezmoi state**:
```bash
chezmoi doctor      # Check chezmoi health
chezmoi verify      # Verify managed files
chezmoi diff        # See what would change
```

## Performance Considerations

### Bootstrap Time

**Typical Installation** (fresh Ubuntu system):
- Bootstrap: 2-5 minutes
- Required packages: 5-10 minutes
- Optional packages: Varies by selection
- Total: 10-20 minutes

**Factors**:
- Internet speed (downloads)
- System update size
- Number of optional packages selected

### Optimization Strategies

1. **Package Cache**: Updates run once, installations reuse cache
2. **Static Plugin Loading**: Antidote generates fast static files
3. **Minimal Dependencies**: Bootstrap installs only git + chezmoi
4. **Idempotent Scripts**: Skip already-installed packages
5. **Parallel Execution**: Future enhancement opportunity

## Security Considerations

### Download Verification

**Bootstrap**: Downloads bdb_helpers.sh from GitHub
- Uses HTTPS (transport security)
- Downloads from user's own repository
- Optional: Could add SHA256 verification

**External Resources**: Managed by chezmoi
- Downloaded over HTTPS
- Checksums managed by chezmoi
- Refresh periods configurable

### Privilege Escalation

**sudo Usage**:
- Requested once at bootstrap start
- Background process keeps sudo alive
- Only used for system operations
- Never used for user file manipulation

**Best Practice**: Review scripts before running bootstrap

### Secret Management

**1Password Integration**:
- SSH keys managed by 1Password
- SSH agent socket detection
- Secrets never stored in dotfiles

**Git Configuration**:
- Email and name in templates
- No credentials in repository

## Troubleshooting Guide

### Bootstrap Fails to Start

**Check**: curl or wget available
```bash
command -v curl || command -v wget
```

**Check**: Internet connectivity
```bash
ping -c 1 github.com
```

### Chezmoi Init Fails

**Check**: Git installed
```bash
git --version
```

**Check**: Repository accessible
```bash
git ls-remote https://github.com/norville/dotfiles
```

### Package Installation Fails

**Check**: Package manager working
```bash
# Ubuntu
sudo apt-get update

# Fedora
sudo dnf check-update

# Arch
sudo pacman -Sy
```

**Check**: Correct distribution detected
```bash
chezmoi execute-template '{{ .osid }}'
chezmoi execute-template '{{ .packageManager }}'
```

### Plugins Not Loading

**Check**: Antidote installed
```bash
ls ~/.local/share/antidote
```

**Check**: Static file generated
```bash
ls ~/.cache/zsh/.zsh_plugins.zsh
```

**Fix**: Regenerate
```bash
zsh-clean-plugins
```

## Future Enhancements

### Potential Improvements

1. **Automated Testing**
   - VM-based integration tests
   - CI/CD pipeline for changes
   - Platform compatibility matrix

2. **Enhanced Logging**
   - Structured logging (JSON)
   - Log aggregation
   - Performance metrics

3. **Additional Platforms**
   - Windows WSL support
   - FreeBSD support
   - Container-based environments

4. **Advanced Features**
   - Parallel package installation
   - Rollback capability
   - Incremental updates

## References

### Official Documentation

- [Chezmoi](https://www.chezmoi.io/) - Dotfiles management
- [Antidote](https://github.com/mattmc3/antidote) - ZSH plugin manager
- [Starship](https://starship.rs/) - Cross-shell prompt
- [Tokyo Night](https://github.com/folke/tokyonight.nvim) - Color scheme

### Related Projects

- [Homebrew](https://brew.sh/) - Package manager (macOS/Linux)
- [1Password](https://developer.1password.com/docs/ssh/) - SSH agent
- [Neovim](https://neovim.io/) - Text editor
- [Kitty](https://sw.kovidgoyal.net/kitty/) - Terminal emulator

---

**Last Updated**: 2025-01-28
**Maintained By**: Norville
**Repository**: https://github.com/norville/dotfiles
