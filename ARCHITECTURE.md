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
- Manage dotfile updates (handled by `chezmoi update`)

### 2. Helper Functions Library (bdb_helpers.sh)

**Purpose**: Provide consistent UI, logging, and utility functions

**Location**: `dot_config/bdb/bdb_helpers.sh`

**Key Features**:
- Dual-output logging (terminal + file)
- Color-coded status messages
- User interaction helpers
- Command execution wrappers
- Error handling and cleanup

**Design Pattern**: Sourced by both bootstrap and chezmoi scripts via the `HELPERS` environment variable set in `[scriptEnv]` of `.chezmoi.toml.tmpl`.

### 3. Chezmoi Configuration (.chezmoi.toml.tmpl)

**Purpose**: Configure chezmoi behavior and define template variables

**Location**: `.chezmoi.toml.tmpl`

**Key Responsibilities**:
- OS and distribution detection
- CPU architecture detection
- Machine type identification (`workstation` / `terminal`)
- Package manager identification
- Template variable definition
- Script environment setup

**Generated Variables** (available in all `.tmpl` files):

| Variable | Example Values | Purpose |
|----------|----------------|---------|
| `osid` | `darwin`, `linux-ubuntu`, `linux-fedora` | OS identifier |
| `machine` | `workstation`, `terminal` | Machine type |
| `packageManager` | `brew`, `apt`, `dnf`, `pacman` | Primary package manager |
| `cpuArch` | `amd64`, `arm64`, `x86_64`, `aarch64` | CPU architecture |
| `isARM` | `true`/`false` | ARM-based CPU flag |
| `isRPi` | `true`/`false` | Raspberry Pi flag |
| `isIntel` | `true`/`false` | Intel/AMD x86_64 flag |
| `isAppleSilicon` | `true`/`false` | Apple Silicon flag |
| `email` | `user@example.com` | User email address |
| `name` | `User Name` | User full name |

### 4. Installation Scripts (.chezmoiscripts/)

**Purpose**: Install and configure packages and environment

**Location**: `.chezmoiscripts/`

**Execution**: Automatic during `chezmoi apply`, in alphanumeric order

**Scripts**:

#### 00-install-core.sh.tmpl
- **When**: Runs when file changes (`onchange`)
- **Purpose**: Install essential tools
- **Installs**: zsh, neovim (workstation) / vim (terminal), bat, eza, fzf, ripgrep, fd, lazygit, kitty (Linux workstation), starship, zoxide, git-delta, btop
- **Platform-specific**: Different package sets per OS/distribution

#### 01-optional-packages.sh.tmpl
- **When**: Runs when file changes (`onchange`)
- **Purpose**: Prompt for optional software
- **Prompts for**: 1Password, Docker, Ansible
- **User control**: Each package requires explicit confirmation

#### 02-install-vscode.sh.tmpl
- **When**: Runs when file changes (`onchange`), workstation only
- **Purpose**: Prompt for and install Visual Studio Code
- **Skipped**: Automatically on `terminal` machines

#### 05-env-setup.sh.tmpl
- **When**: Runs when file changes (`onchange`)
- **Purpose**: Configure environment and applications
- **Actions**: Set ZSH as default shell, configure themes, verify installations

#### 10-env-update.sh.tmpl
- **When**: Runs after `chezmoi update` only (not on regular `chezmoi apply`)
- **Purpose**: Update packages and tools
- **Actions**: Update system packages, update ZSH plugins via Zinit, rebuild caches

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
│     • Define template variables (osid, machine, etc.)       │
│  3. Apply Dotfiles                                          │
│     • Copy/template files to home directory                 │
│     • Download external resources (.chezmoiexternal)        │
│  4. Execute Scripts (.chezmoiscripts/)                      │
│     • Run in alphanumeric order                             │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│          00-install-core.sh.tmpl                            │
├─────────────────────────────────────────────────────────────┤
│  • Update package cache                                     │
│  • Install core packages:                                   │
│    - Shell: zsh, zoxide                                     │
│    - Editor: neovim (workstation) / vim (terminal)          │
│    - Tools: bat, eza, fzf, ripgrep, fd, git-delta           │
│    - Terminal: kitty (Linux workstation only)               │
│    - Git UI: lazygit (workstation only)                     │
│    - Monitor: btop (workstation only)                       │
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
│    3. If no: Skip with warning                              │
│  Packages: 1Password, Docker, Ansible                       │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│          02-install-vscode.sh.tmpl (workstation only)       │
├─────────────────────────────────────────────────────────────┤
│  • Prompt: "Do you want to install VS Code?"                │
│  • If yes: add repo, install via package manager            │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│          05-env-setup.sh.tmpl                               │
├─────────────────────────────────────────────────────────────┤
│  • Set ZSH as default shell                                 │
│  • Verify tool installations                                │
│  • Verify font installation (Linux)                         │
│  • Configure macOS defaults (macOS only)                    │
│  • Configure Homebrew analytics off (macOS only)            │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│                  Installation Complete!                     │
│                                                             │
│  User must log out and back in to:                          │
│  • Load ZSH as default shell                                │
│  • Apply group memberships (docker, etc.)                   │
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
│             10-env-update.sh.tmpl                           │
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
│    - zinit self-update                                      │
│    - zinit update --all                                     │
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

## File Organization

### Repository Structure

```
dotfiles/
├── .chezmoi.toml.tmpl              # Chezmoi configuration + template variables
├── .chezmoiexternal.toml.tmpl      # External resources (themes, fonts)
├── .chezmoiignore                  # OS/platform/machine exclusions
├── CLAUDE.md                       # Context for Claude Code (not deployed)
├── ARCHITECTURE.md                 # This file (not deployed)
├── README.md                       # User documentation (not deployed)
├── TODO.md                         # Open tasks (not deployed)
├── .chezmoiscripts/                # Installation scripts
│   ├── run_onchange_after_00-install-core.sh.tmpl
│   ├── run_onchange_after_01-optional-packages.sh.tmpl
│   ├── run_onchange_after_02-install-vscode.sh.tmpl
│   ├── run_onchange_after_05-env-setup.sh.tmpl
│   └── run_after_10-env-update.sh.tmpl
├── dot_config/                     # Configuration files (→ ~/.config/)
│   ├── bdb/                        # Bootstrap system
│   │   ├── bdb_bootstrap.sh        # Bootstrap script (not deployed)
│   │   └── bdb_helpers.sh          # Helper functions
│   ├── bat/                        # Bat config and Tokyo Night theme
│   ├── btop/                       # Btop config and Tokyo Night theme
│   ├── delta/                      # Delta git pager Tokyo Night config
│   ├── eza/                        # Eza color theme
│   ├── git/                        # Git config, ignore, delta integration
│   ├── kitty/                      # Kitty terminal config (workstation only)
│   ├── lazygit/                    # Lazygit config with Tokyo Night theme
│   ├── nvim/                       # Neovim config (LazyVim, workstation only)
│   └── starship/                   # Starship prompt config
├── dot_zsh/                        # ZSH configuration (→ ~/.zsh/)
│   ├── plugins.zsh                 # Zinit plugin manager and plugin list
│   └── aliases.zsh                 # Shell aliases
├── dot_zshrc.tmpl                  # Main ZSH config (→ ~/.zshrc)
├── dot_editorconfig                # Global EditorConfig (→ ~/.editorconfig)
├── dot_vimrc                       # Vim config (terminal machines only)
├── dot_vim/                        # Vim plugins (terminal machines only)
│   ├── plugins.vim                 # vim-plug plugin list
│   └── theme.vim                   # Tokyo Night theme setup
└── dot_ssh/                        # SSH config and public keys
    ├── private_config.tmpl         # SSH client config
    ├── private_norville_at_chikyu.pub.tmpl
    ├── private_ansible_at_chikyu.pub.tmpl
    ├── private_norville_at_github.pub.tmpl
    └── private_norville_at_codeberg.pub.tmpl
```

### Naming Conventions

**Chezmoi Source Prefixes**:
- `dot_` → deployed with a leading `.` (e.g. `dot_zshrc` → `~/.zshrc`)
- `private_` → deployed with `chmod 600`
- `.tmpl` suffix → Go template, variables substituted at apply time

**Chezmoi Scripts**:
- `run_onchange_after_NN-` → runs when file content changes, after file application
- `run_after_NN-` → runs after every `chezmoi update`
- Number prefix → execution order

## Design Decisions

### Why Separate Bootstrap and Chezmoi?

**Bootstrap** handles the "chicken and egg" problem:
- A fresh system doesn't have chezmoi
- Bootstrap is the minimal installer (git + chezmoi only)

**Chezmoi** handles everything else:
- Powerful templating engine
- Built-in idempotency and state management
- Cross-platform file deployment
- Native update mechanism

### Why Dual Logging?

**Terminal** (FD3): Clean, color-coded status lines for the user watching the install.

**Log file** (FD1/FD2): Full command output and timestamps for debugging. All chezmoi scripts detect an existing `BDB_LOG_FILE` from bootstrap and append to it, producing a single audit trail for the entire installation.

### Why Machine Types?

Two machine types (`workstation` / `terminal`) keep the same source tree deployable to both full development environments and minimal headless servers:

| Concern | Workstation | Terminal |
|---------|-------------|----------|
| Editor | Neovim | Vim |
| Terminal emulator | Kitty | (none) |
| Git TUI | lazygit | (none) |
| System monitor | btop | (none) |
| Vim config deployed | No | Yes |

### Why EditorConfig as the Single Source of Truth?

`~/.editorconfig` governs indent style/size, line endings, charset, and trailing-whitespace handling across Vim, Neovim, VSCode, and Helix. Per-editor settings files only contain what EditorConfig cannot govern.

## Variable Scopes and Lifecycles

### Bootstrap-Only Variables

Scope: `bdb_bootstrap.sh` only. Not exported to chezmoi scripts.

| Variable | Example | Purpose |
|----------|---------|---------|
| `PLATFORM` | `Darwin`, `Linux` | OS type from `uname -s` |
| `DISTRO` | `macos`, `ubuntu`, `arch` | Distribution identifier |
| `BDB_LOG_FILE` | `bdb_log_20260601_143022.txt` | Bootstrap log path |

### Script Environment Variables

Scope: all `.chezmoiscripts/` files. Defined in `[scriptEnv]` in `.chezmoi.toml.tmpl`.

| Variable | Purpose |
|----------|---------|
| `HELPERS` | Absolute path to `bdb_helpers.sh` |

## SSH Key Management

SSH public keys are managed as chezmoi templates that call `onepasswordRead` at apply time. To prevent failures on machines where 1Password is not yet installed, all four keys are wrapped in a `lookPath "op"` guard in `.chezmoiignore`:

```
{{- if not (lookPath "op") }}
.ssh/norville_at_chikyu.pub
.ssh/ansible_at_chikyu.pub
.ssh/norville_at_github.pub
.ssh/norville_at_codeberg.pub
{{- end }}
```

After `run_onchange_after_01` installs 1Password, a second `chezmoi apply` deploys the keys.

## Error Handling

All scripts use a common trap pattern sourced from `bdb_helpers.sh`:

```bash
set -euo pipefail
trap 'bdb_handle_error' ERR
trap 'bdb_cleanup' EXIT
```

`bdb_handle_error` captures the exit code, failed command, and line number, logs them to the log file, and prints a user-friendly message. `bdb_cleanup` removes temp files and restores file descriptors; it always succeeds regardless of how the script exits.

## Performance Considerations

- **Idempotent scripts**: Already-installed packages are detected and skipped.
- **Zinit turbo mode**: Plugins load asynchronously after the shell prompt appears, keeping startup time fast.
- **lazy = true default**: All custom Neovim plugins are lazy-loaded unless explicitly set otherwise.
- **Package cache**: System package lists are updated once per script run; installations reuse the cache.

## Security Considerations

- Secrets are never stored in the repository. SSH keys are populated at apply time via `onepasswordRead`.
- `private_` prefix on SSH key files ensures they are deployed as `chmod 600`.
- `sudo` is requested once at bootstrap start; a background process keeps the session alive only for the duration of the install.
- External resources are downloaded over HTTPS; checksums are managed by chezmoi.

## Common Workflows

### Adding a New Optional Package

1. Edit `run_onchange_after_01-optional-packages.sh.tmpl`
2. Add a `bdb_ask` block with per-`packageManager` branches
3. Test on a VM
4. Update `README.md`
5. Commit with `feat: add <package> as optional package`

### Adding a New SSH Key

1. Store the key in 1Password
2. Add `dot_ssh/private_<name>.pub.tmpl` using `onepasswordRead`
3. Add the SSH config stanza to `dot_ssh/private_config.tmpl`
4. Add the target path to the `lookPath "op"` guard in `.chezmoiignore`
5. Commit both files together: `feat: add <name> ssh key`

### Debugging Installation Issues

```bash
# Find the most recent log
ls -lt bdb_log_*.txt | head -1
ls -lt ~/.cache/chezmoi/*.log | head -1

# Scan for errors
grep -i "error\|exit code" bdb_log_*.txt

# Check chezmoi health
chezmoi doctor
chezmoi verify
chezmoi diff
```
