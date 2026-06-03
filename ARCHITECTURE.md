# Dotfiles System Architecture

## Overview

BDB (Bassa's Dotfiles Bootstrapper) is a comprehensive, multi-phase dotfiles management
system built on [Chezmoi](https://www.chezmoi.io/). The system provides automated
installation, configuration, and maintenance of development environments across multiple
operating systems and architectures.

### Design Philosophy

1. **Separation of Concerns** — Bootstrap handles installation; Chezmoi handles configuration
2. **Idempotent Operations** — All scripts safely re-run: check before acting, skip if current
3. **Progressive Enhancement** — Core → Optional → Configuration → Updates
4. **Platform Abstraction** — OS-specific logic isolated in templates
5. **User-Centric Design** — Clear feedback, sensible defaults, optional prompts

## System Components

### 1. Bootstrap Phase (bdb_bootstrap.sh)

**Purpose**: Install Chezmoi and dependencies on fresh systems

**Location**: `dot_config/bdb/bdb_bootstrap.sh`

**Responsibilities**:
- Detect operating system and distribution
- Update system packages (with user confirmation)
- Install git and chezmoi
- Initialize dotfiles repository

**Does NOT**:
- Install application packages (handled by chezmoi scripts)
- Configure shell or applications (handled by chezmoi)
- Manage dotfile updates (handled by `chezmoi update`)

### 2. Helper Functions Library (bdb_helpers.sh)

**Purpose**: Provide consistent UI, logging, and utility functions

**Location**: `dot_config/bdb/bdb_helpers.sh`

**Key Features**:
- Dual-output logging (terminal FD3 + log file FD1/FD2)
- Color-coded status messages (`bdb_action`, `bdb_exec`, `bdb_success`, `bdb_warn`)
- Interactive prompts (`bdb_ask` — reads from `/dev/tty`, safe in chezmoi scripts)
- Command execution wrappers
- Error handling and cleanup traps

**Design Pattern**: Sourced by both bootstrap and chezmoi scripts via the `HELPERS`
environment variable set in `[scriptEnv]` of `.chezmoi.toml.tmpl`.

### 3. Chezmoi Configuration (.chezmoi.toml.tmpl)

**Purpose**: Configure chezmoi behavior and define template variables

**Location**: `.chezmoi.toml.tmpl`

**Key Responsibilities**:
- OS and distribution detection
- CPU architecture detection
- Machine type identification (`workstation` / `terminal`)
- Desktop environment detection (for GNOME-specific features)
- Package manager identification
- Package list centralisation (all package governance lives here)
- Template variable definition

**Generated Variables** (available in all `.tmpl` files):

| Variable | Example Values | Purpose |
|----------|----------------|---------|
| `osid` | `darwin`, `linux-ubuntu`, `linux-arch` | OS + distro identifier |
| `machine` | `workstation`, `terminal` | Machine type |
| `desktop` | `gnome`, `niri`, `""` | Lowercased XDG_CURRENT_DESKTOP |
| `packageManager` | `brew`, `apt`, `dnf`, `pacman` | Primary package manager |
| `cpuArch` | `amd64`, `arm64` | CPU architecture |
| `isARM` / `isIntel` / `isAppleSilicon` / `isRPi` | `true`/`false` | Architecture flags |
| `email` / `name` | — | User identity for git config etc. |
| `corePackages` | `["bat","fzf",…]` | Packages installed on every platform |
| `pacmanPackages` / `aptPackages` / `dnfPackages` / `aurPackages` | `[…]` | Distro-specific package lists |
| `brewFormulae` / `brewCasks` | `[…]` | macOS Homebrew lists |

**Note on `desktop`**: `.chezmoi.toml.tmpl` is re-rendered only on `chezmoi init`, not
on `chezmoi apply`. Templates that need GNOME detection in active conditionals
(`.chezmoiignore`, scripts) use `env "XDG_CURRENT_DESKTOP" | lower` directly rather
than `.desktop` to avoid a missing-key error on machines that haven't re-run `chezmoi init`.

### 4. Installation Scripts (.chezmoiscripts/)

**Purpose**: Install and configure packages and environment

**Execution**: Automatic during `chezmoi apply` (onchange) or `chezmoi update` (run_after)

#### Idempotency pattern

All install scripts (`01`–`04`) check whether the tool is already installed before
prompting the user:

```bash
if bdb_has_cmd "docker"; then
  bdb_success "Docker already installed"
  bdb_end_section; exit 0
fi
bdb_ask "Do you want to install Docker?" || { … exit 0; }
# install…
```

Deployment scripts (`06-install-sddm`) write expected content to a temp directory, then compare
against deployed files with `cmp -s` before prompting — no sudo, no prompt if already current:

```bash
if cmp -s "$_TMP/sddm.conf" /etc/sddm.conf && …; then
  bdb_success "SDDM already up to date"; exit 0
fi
bdb_ask "Install SDDM configuration?" || …
sudo install -m 644 "$_TMP/sddm.conf" /etc/sddm.conf
```

Service scripts (`07-install-darkman`) check `is-enabled && is-active` before prompting:

```bash
if systemctl --user is-enabled darkman.service &>/dev/null \
   && systemctl --user is-active darkman.service &>/dev/null; then
  bdb_success "darkman.service already running"; exit 0
fi
```

#### Scripts

| Script | Trigger | Purpose |
|--------|---------|---------|
| `00-install-core` | onchange | Essential packages for all machine types |
| `01-config-env` | onchange | Default shell, bat cache, font cache, nvim dirs |
| `02-install-1password` | onchange | 1Password + op CLI (workstation, skipped if installed) |
| `03-install-vscode` | onchange | VS Code (workstation, skipped if installed) |
| `04-install-ansible` | onchange | Ansible (skipped if installed) |
| `05-install-docker` | onchange | Docker (skipped if installed) |
| `06-install-sddm` | onchange | SDDM config + Tokyo Night Moon theme → /etc/ and /usr/share/ |
| `07-install-darkman` | onchange | Enable darkman.service (GNOME workstation only) |
| `90-update-env` | every update | System packages, ZSH plugins, caches |

### 5. System-Level Files (sddm/)

Files that must live outside `~/` are stored in a source-only directory at the repo root.
`.chezmoiignore` excludes the directory from home deployment. A `run_onchange_after_`
script deploys them with `sudo install`.

**Change detection**: text files use `{{ include "path" | sha256sum }}` in the script
header comment; binary files use `{{ output "sha256sum" (joinPath .chezmoi.sourceDir "path") }}`.
Chezmoi re-runs the script whenever those hashes change.

**Deployment pattern** (idempotent):
1. Write all expected content to `$(mktemp -d)` once
2. Compare every target with `cmp -s` (no sudo — targets are world-readable)
3. Exit 0 silently if all match; prompt and `sudo install` if any differ
4. Temp dir cleaned up by EXIT trap

## Execution Flow

### Initial Installation

```
User runs bootstrap
        │
        ▼
bdb_bootstrap.sh
  ├── Detect OS & distribution
  ├── Update system packages (prompted)
  ├── Install git + chezmoi
  └── chezmoi init --apply norville
              │
              ▼
      Chezmoi Initialization
        ├── Clone repository → ~/.local/share/chezmoi
        ├── Process .chezmoi.toml.tmpl → ~/.config/chezmoi/chezmoi.toml
        ├── Deploy dotfiles (templates expanded, externals downloaded)
        └── Run scripts in order:
              ├── 00-install-core    (essential packages)
              ├── 01-config-env      (shell, caches, fonts)
              ├── 02-install-1pw     (optional, prompted — skipped if installed)
              ├── 03-install-vscode  (optional, prompted — workstation only)
              ├── 04-install-ansible (optional, prompted — skipped if installed)
              ├── 05-install-docker  (optional, prompted — skipped if installed)
              ├── 06-install-sddm    (SDDM theme — Arch workstation only)
              └── 07-install-darkman (enable service — GNOME workstation only)
```

### Update Flow

```
chezmoi update
        │
        ▼
  Pull latest from GitHub
  Apply configuration changes
  Run run_after_* scripts:
    └── 90-update-env    (system packages, zinit, bat cache, font cache)
```

## File Organization

### Repository Structure

```
dotfiles/
├── .chezmoi.toml.tmpl              # Chezmoi config + template variables + package lists
├── .chezmoiexternal.toml.tmpl      # External resources (themes, fonts)
├── .chezmoiignore                  # OS/platform/machine exclusions
├── CLAUDE.md                       # Context for Claude Code (not deployed, gitignored)
├── ARCHITECTURE.md                 # This file (not deployed)
├── README.md                       # User documentation (not deployed)
├── TODO.md                         # Open tasks (not deployed)
├── sddm/                           # Source-only: SDDM config + Tokyo Night Moon theme
│   ├── etc/sddm.conf
│   ├── etc/sddm.conf.d/tokyonight-moon.conf
│   ├── etc/sddm/Xsetup
│   └── themes/tokyonight-moon/     # metadata.desktop, Main.qml, LoginFormComponent.qml, background.jpg
├── .chezmoiscripts/
│   ├── run_onchange_after_00-install-core.sh.tmpl
│   ├── run_onchange_after_01-config-env.sh.tmpl
│   ├── run_onchange_after_02-install-1password.sh.tmpl
│   ├── run_onchange_after_03-install-vscode.sh.tmpl
│   ├── run_onchange_after_04-install-ansible.sh.tmpl
│   ├── run_onchange_after_05-install-docker.sh.tmpl
│   ├── run_onchange_after_06-install-sddm.sh.tmpl
│   ├── run_onchange_after_07-install-darkman.sh.tmpl
│   └── run_after_90-update-env.sh.tmpl
├── dot_config/
│   ├── bdb/
│   │   ├── bdb_bootstrap.sh        # Not deployed
│   │   └── bdb_helpers.sh
│   ├── bat/                        # Bat config and Tokyo Night theme
│   ├── btop/                       # Btop config and Tokyo Night theme
│   ├── darkman/                    # darkman config.yaml (GNOME workstation only)
│   ├── delta/                      # Delta pager Tokyo Night config
│   ├── eza/                        # Eza color theme (downloaded via chezmoiexternal)
│   ├── git/                        # Git config, ignore, delta integration
│   ├── kitty/                      # Kitty config, tab_bar.py, Tokyo Night theme, sessions/
│   ├── lazygit/                    # Lazygit config with Tokyo Night theme
│   ├── nvim/                       # Neovim (LazyVim, workstation only)
│   ├── starship/                   # Starship prompt config
│   ├── yay/                        # yay AUR helper config (pacman only)
│   ├── yazi/                       # yazi file manager (workstation only)
│   └── zed/                        # Zed editor (workstation only)
├── dot_local/share/darkman/
│   └── executable_gtk3-theme.sh    # GTK3 dark/light switch script
├── dot_zsh/
│   ├── plugins.zsh
│   └── aliases.zsh
├── dot_zshrc.tmpl
├── dot_editorconfig
├── dot_vimrc
├── dot_vim/
└── dot_ssh/
    ├── private_config.tmpl
    ├── private_norville_at_chikyu.pub.tmpl
    ├── private_ansible_at_chikyu.pub.tmpl
    ├── private_norville_at_github.pub.tmpl
    └── private_norville_at_codeberg.pub.tmpl
```

### Naming Conventions

**Chezmoi Source Prefixes**:

| Prefix/Suffix | Deployed As |
|---------------|-------------|
| `dot_` | Leading `.` (e.g. `dot_zshrc` → `~/.zshrc`) |
| `private_` | `chmod 600` |
| `executable_` | Execute bit set |
| `.tmpl` | Go template expanded at apply time |

**Chezmoi Scripts**:

| Prefix | When it runs |
|--------|-------------|
| `run_onchange_after_NN-` | When script content changes, after file application |
| `run_after_NN-` | After every `chezmoi update` |

Number prefix controls execution order within each group.

## Design Decisions

### Why Separate Bootstrap and Chezmoi?

**Bootstrap** solves the chicken-and-egg problem: a fresh system has no chezmoi.
It is the minimal installer (git + chezmoi only) that hands off immediately.

**Chezmoi** handles everything else: templating, idempotency, cross-platform file
deployment, state tracking, and native update mechanism.

### Why Dual Logging?

**Terminal** (FD3): Clean, color-coded status lines for the watching user.

**Log file**: Full command output and timestamps for debugging. All chezmoi scripts
detect an existing `BDB_LOG_FILE` from bootstrap and append to it, producing a single
audit trail for the entire installation.

### Why Machine Types?

Two types (`workstation` / `terminal`) keep the same source tree deployable to both
full development environments and minimal headless servers:

| Concern | Workstation | Terminal |
|---------|-------------|----------|
| Editor | Neovim + Zed | Vim |
| Terminal emulator | Kitty | (none) |
| File manager | yazi | (none) |
| Git TUI | lazygit | (none) |
| System monitor | btop | (none) |
| Dark mode | darkman (GNOME) | (none) |
| Vim config deployed | No | Yes |

### Why EditorConfig as Single Source of Truth?

`~/.editorconfig` governs indent style/size, line endings, charset, and trailing-whitespace
across Vim, Neovim, VSCode, and Zed. Per-editor settings files (`settings.json`,
`options.lua`) only contain what EditorConfig cannot govern (e.g. vim mode, scrolloff).

### Why a Source-Only `sddm/` Directory?

Chezmoi targets `~/`. System-level files in `/etc/` and `/usr/share/` cannot be deployed
directly. The chosen pattern:

1. Store source in `sddm/` at the repo root (not `dot_config/`)
2. Exclude from home deployment via `.chezmoiignore`: `sddm/`
3. Deploy via `run_onchange_after_06-install-sddm.sh.tmpl` using `sudo install`
4. Embed text files as heredocs so their content hash drives change detection
5. Use `{{ output "sha256sum" … }}` for binary files (background.jpg)

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

SSH public keys are managed as chezmoi templates that call `onepasswordRead` at apply time.
To prevent failures on machines where 1Password is not yet installed, all four keys are
wrapped in a `lookPath "op"` guard in `.chezmoiignore`.

After `run_onchange_after_02` installs 1Password, a second `chezmoi apply` deploys the keys.

## Error Handling

All scripts use a common trap pattern sourced from `bdb_helpers.sh`:

```bash
set -euo pipefail
trap 'bdb_handle_error' ERR
trap 'bdb_cleanup' EXIT
```

`bdb_handle_error` captures the exit code, failed command, and line number, logs them,
and prints a user-friendly message. `bdb_cleanup` removes temp files and restores file
descriptors; it always succeeds.

Scripts that create temp directories extend the EXIT trap:

```bash
_TMP=$(mktemp -d)
trap 'rm -rf "$_TMP"; bdb_cleanup' EXIT
```

## Performance Considerations

- **Idempotent scripts**: Already-installed tools are detected and skipped, no reinstall.
- **`--needed` flag on pacman/yay**: Skip packages that are already up to date.
- **Zinit turbo mode**: Plugins load asynchronously after the shell prompt appears.
- **`lazy = true` default**: All custom Neovim plugins are lazy-loaded unless specified.
- **compinit cache**: `.zcompdump` is only regenerated once per day.

## Security Considerations

- Secrets are never stored in the repository. SSH keys are populated at apply time via `onepasswordRead`.
- `private_` prefix on SSH key files ensures `chmod 600` on deployment.
- `allow_remote_control` is **not** enabled in Kitty — no remote control socket exposed.
- External resources are downloaded over HTTPS; content hashes are tracked by chezmoi.

## Common Workflows

### Adding a New App Configuration

1. Create `dot_config/<app>/` in the source directory
2. Add a `.chezmoiignore` gate if the app is not for all machines
3. If themes are downloadable: add an entry to `.chezmoiexternal.toml.tmpl`
4. Commit with `feat: track <app> configuration`

### Adding a System-Level File (e.g. new `/etc/` config)

1. Add the source file under `sddm/etc/` (or create a new source-only dir)
2. Add a `sha256sum` comment for the file to the header of the deploy script
3. Add a `cat > "$_TMP/file"` heredoc block
4. Add a `cmp -s "$_TMP/file" /target/path` condition to the idempotency check
5. Add a `sudo install -m MODE "$_TMP/file" /target/path` to the deploy block

### Adding a New Optional Package

1. Create `run_onchange_after_NN-install-<pkg>.sh.tmpl`
2. Start with a `bdb_has_cmd` idempotency check
3. Add `bdb_ask` prompt before installing
4. Add to `$pacman` / `$apt` / `$dnf` / `$cask` in `.chezmoi.toml.tmpl` if appropriate
5. Commit with `feat: add <package> install script`

### Adding a New SSH Key

1. Store the key in 1Password
2. Add `dot_ssh/private_<name>.pub.tmpl` using `onepasswordRead`
3. Add the SSH config stanza to `dot_ssh/private_config.tmpl`
4. Add the target path to the `lookPath "op"` guard in `.chezmoiignore`
5. Commit all three files together

### Debugging Installation Issues

```bash
# Find the most recent log
ls -lt ~/.cache/chezmoi/*.log | head -3

# Scan for errors
grep -i "error\|exit code" ~/.cache/chezmoi/*.log

# Check chezmoi health
chezmoi doctor
chezmoi verify
chezmoi diff
```
