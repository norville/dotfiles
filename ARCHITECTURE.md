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
- Shared system package update (`bdb_update_packages`) — single implementation
  with runtime package-manager detection, called by both `bdb_bootstrap.sh`
  (pre-chezmoi) and `bdb_update.sh` (the `chezmoi update` post hook)

**Design Pattern**: Sourced by both bootstrap and chezmoi scripts via the `HELPERS`
environment variable set in `[scriptEnv]` of `.chezmoi.toml.tmpl`.

### 3. Package Matrix (.chezmoidata.toml)

**Purpose**: Single source of truth for all package data

**Location**: `.chezmoidata.toml`

Each entry declares `name`, `managers` (brew-formula/brew-cask/apt/snap/pacman/aur/dnf),
and `machines` (workstation/terminal/server). Install scripts and `brewfile.tmpl` filter
this data at template render time using `range .package` + `has $.machine .machines`.

GNOME-conditional packages (darkman, xdg-desktop-portal-gtk) are **not** in this file —
they depend on `XDG_CURRENT_DESKTOP` at render time and are appended explicitly in the
install script.

This file is a chezmoi special file (starts with `.chezmoi`) — not deployed to `~/`.

#### Package Manager Name Splits

Same logical tool delivered under a different name per manager:

| Logical Tool | brew-formula | brew-cask | apt | snap | pacman | aur | dnf |
|---|---|---|---|---|---|---|---|
| Brave Browser | — | `brave-browser` | `brave-browser` | — | — | `brave-bin` | `brave-browser` |
| fd | `fd` | — | `fd-find` | — | `fd` | — | `fd-find` |
| Go | `go` | — | `golang-go` | — | `go` | — | `golang` |
| Java JDK | `openjdk` | — | `default-jdk` | — | `jdk-openjdk` | — | `java-devel` |
| Neovim | `neovim` | — | — | `nvim` | `neovim` | — | `neovim` |
| Node.js | `node` | — | `nodejs` | — | `nodejs` | — | `nodejs` |
| OpenTofu | `opentofu` | — | `tofu` | — | `opentofu` | — | `opentofu` |
| rustup | `rustup` | — | — | `rustup` | `rustup` | — | `rustup` |
| ffmpeg | `ffmpeg-full` | — | — | — | `ffmpeg` | — | — |
| ImageMagick | `imagemagick-full` | — | — | — | `imagemagick` | — | — |
| GnuPG | — | — | `gpg` | — | `gnupg` | — | `gnupg2` |
| 7-Zip | `sevenzip` | — | — | — | `7zip` | — | — |

#### Full Package Matrix

The full package list is **not** duplicated here — `.chezmoidata.toml` is the single
source of truth and is readable directly (one `[[package]]` entry per package with
`name`, `managers`, and `machines`). To see the resolved list for a given machine,
render an install script:

```bash
chezmoi execute-template < .chezmoiscripts/run_onchange_after_00-install-core.sh.tmpl
```

### 4. Chezmoi Configuration (.chezmoi.toml.tmpl)

**Purpose**: Configure chezmoi behavior and define template variables

**Location**: `.chezmoi.toml.tmpl`

**Key Responsibilities**:
- OS and distribution detection
- CPU architecture detection
- Machine type identification (`workstation` / `terminal` / `server`)
- Desktop environment detection (for GNOME-specific features)
- Package manager identification
- Template variable definition

**Note on package lists**: Package data lives in `.chezmoidata.toml`. `.chezmoi.toml.tmpl`
does not export package lists — `.chezmoidata.toml` is not available during `chezmoi init`
template processing (fresh machine), so list construction is deferred to script render time.

**Generated Variables** (available in all `.tmpl` files):

| Variable | Example Values | Purpose |
|----------|----------------|---------|
| `osid` | `darwin`, `linux-ubuntu`, `linux-rocky` | OS + distro identifier |
| `machine` | `workstation`, `terminal`, `server` | Machine type |
| `desktop` | `gnome`, `niri`, `""` | Lowercased XDG_CURRENT_DESKTOP |
| `packageManager` | `brew`, `apt`, `dnf`, `pacman` | Primary package manager |
| `cpuArch` | `amd64`, `arm64` | CPU architecture |
| `isARM` / `isIntel` / `isAppleSilicon` / `isRPi` | `true`/`false` | Architecture flags |
| `email` / `name` | — | User identity for git config etc. |

Package lists are **not** exported here — scripts and `brewfile.tmpl` filter `.package`
(from `.chezmoidata.toml`) directly at render time.

#### OS / Distro → Machine Type

| `osid` | workstation | terminal | server | Detection |
|---|:---:|:---:|:---:|---|
| `darwin` | ✓ | — | — | auto |
| `linux-arch` | ✓ | — | — | auto |
| `linux-cachyos` | ✓ | — | — | auto |
| `linux-fedora` | ✓ | — | — | auto |
| `linux-ubuntu` | ✓ | ✓ | ✓ | graphical session env vars → workstation; else `promptStringOnce` |
| `linux-debian` | — | ✓ | ✓ | always `promptStringOnce` |
| `linux-rocky` | — | ✓ | ✓ | always `promptStringOnce` |

#### OS / Distro → Package Manager

| `osid` | `packageManager` | Managers used |
|---|---|---|
| `darwin` | `brew` | brew-formula, brew-cask |
| `linux-arch` | `pacman` | pacman, aur |
| `linux-cachyos` | `pacman` | pacman, aur |
| `linux-ubuntu` | `apt` | apt, snap |
| `linux-debian` | `apt` | apt, snap |
| `linux-fedora` | `dnf` | dnf |
| `linux-rocky` | `dnf` | dnf |

**Machine type detection**: `darwin`, `linux-arch`, `linux-cachyos`, and `linux-fedora`
are always `workstation`. `linux-ubuntu` resolves to `workstation` if a graphical session
is detected (via `XDG_SESSION_TYPE` / `DISPLAY` / `WAYLAND_DISPLAY`); otherwise
`promptStringOnce` asks the user to choose `terminal` or `server`. `linux-debian` and
`linux-rocky` always prompt (never `workstation`). The answer is cached so subsequent
`chezmoi apply` runs don't re-prompt.

**Note on `desktop`**: `.chezmoi.toml.tmpl` is re-rendered only on `chezmoi init`, not
on `chezmoi apply`. Templates that need GNOME detection in active conditionals
(`.chezmoiignore`, scripts) use `env "XDG_CURRENT_DESKTOP" | lower` directly rather
than `.desktop` to avoid a missing-key error on machines that haven't re-run `chezmoi init`.

### 5. Installation Scripts (.chezmoiscripts/)

**Purpose**: Install and configure packages and environment

**Execution**: Automatic during `chezmoi apply` (`run_onchange_after_` scripts).
The system-update script is **not** a chezmoi script — it is deployed to
`~/.config/bdb/bdb_update.sh` and registered as a `[hooks.update.post]` hook so it
runs only after `chezmoi update` (chezmoi has no update-only script class;
`run_after_` scripts would fire on every apply).

#### Idempotency pattern

All optional install scripts (`02`–`05`) check whether the tool is already installed
before prompting the user:

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

| Script | Trigger | W | T | S | Purpose |
|--------|---------|---|---|---|---------|
| `00-install-core` | onchange | ✅ | ✅ | ✅ | Platform packages (per-manager lists, machine-type filtered) |
| `01-config-env` | onchange | ✅ | ✅ | — | Default shell, bat cache, font cache; Go GOPATH/GOBIN; Ruby gems (bundler, erb); Rust stable + rust-analyzer via rustup |
| `02-install-1password` | onchange | ✅ | — | — | 1Password + op CLI (prompted; darwin: brew cask) |
| `03-install-vscode` | onchange | ✅ | — | — | VS Code (prompted; darwin: brew cask) |
| `04-install-ansible` | onchange | ✅ | ✅ | ✅ | Ansible (prompted on all platforms) |
| `05-install-docker` | onchange | ✅ | — | ✅ | Docker (linux only; prompted) |
| `06-install-sddm` | onchange | ✅ | — | — | SDDM config + Tokyo Night Moon → /etc/ and /usr/share/ (requires `sddm` on PATH) |
| `07-install-darkman` | onchange | ✅ | — | — | Enable darkman.service (GNOME workstation only) |
| `bdb_update.sh` (hook) | `chezmoi update` only | ✅ | ✅ | ✅ | System packages (all); ZSH plugins + caches + `rustup update` + `gem update bundler erb` (non-server) |

W = workstation, T = terminal, S = server.

### 6. System-Level Files (sddm/)

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
              ├── 00-install-core    (packages — machine-type filtered)
              ├── 01-config-env      (shell, caches, fonts — W+T only)
              ├── 02-install-1pw     (prompted — workstation only)
              ├── 03-install-vscode  (prompted — workstation only)
              ├── 04-install-ansible (prompted — all machine types)
              ├── 05-install-docker  (prompted — W+S, linux only)
              ├── 06-install-sddm    (SDDM theme — workstation with SDDM only)
              └── 07-install-darkman (enable service — GNOME workstation only)
```

### Update Flow

```
chezmoi update
        │
        ▼
  Pull latest from GitHub
  Apply configuration changes
  Run [hooks.update.post]:
    └── ~/.config/bdb/bdb_update.sh
        (system packages for all; zinit + caches + rustup update + gem update for W+T only)
```

Plain `chezmoi apply` does **not** trigger the update hook.

## File Organization

### Repository Structure

```
dotfiles/
├── .chezmoi.toml.tmpl              # Chezmoi config + template variables (no package lists)
├── .chezmoidata.toml               # Canonical package matrix (never deployed)
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
│   ├── run_onchange_after_00-install-core.sh.tmpl        # all machine types
│   ├── run_onchange_after_01-config-env.sh.tmpl           # workstation + terminal
│   ├── run_onchange_after_02-install-1password.sh.tmpl    # workstation only
│   ├── run_onchange_after_03-install-vscode.sh.tmpl       # workstation only
│   ├── run_onchange_after_04-install-ansible.sh.tmpl      # all machine types
│   ├── run_onchange_after_05-install-docker.sh.tmpl       # workstation + server, linux only
│   ├── run_onchange_after_06-install-sddm.sh.tmpl         # workstation only
│   └── run_onchange_after_07-install-darkman.sh.tmpl      # GNOME workstation only
├── dot_config/
│   ├── bdb/
│   │   ├── bdb_bootstrap.sh        # Not deployed
│   │   ├── bdb_helpers.sh
│   │   └── executable_bdb_update.sh.tmpl  # post-update hook (system/toolchain updates)
│   ├── bat/                        # Bat config and Tokyo Night theme
│   ├── btop/                       # Btop config and Tokyo Night theme
│   ├── darkman/                    # darkman config.yaml (GNOME workstation only)
│   ├── delta/                      # Delta pager Tokyo Night config
│   ├── eza/                        # Eza color theme (downloaded via chezmoiexternal)
│   ├── git/                        # Git config, ignore, delta integration
│   ├── kitty/                      # Kitty config, tab_bar.py, Tokyo Night theme, sessions/
│   ├── lazygit/                    # Lazygit config with Tokyo Night theme
│   ├── niri/                       # niri compositor config (workstation, niri installed)
│   ├── noctalia/                   # Noctalia shell config (workstation, qs installed)
│   ├── nvim/                       # Neovim (LazyVim, workstation + terminal)
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

### Dotfiles Deployment Scope

Canonical table of which machine types receive each config directory.
Implemented via `.chezmoiignore` template conditionals. Source of truth: `.chezmoiignore`.

| Source path | Deployed path | W | T | S | Extra gates |
|---|---|:---:|:---:|:---:|---|
| `dot_config/bdb` | `.config/bdb/` | ✓ | ✓ | ✓ | |
| `dot_config/git` | `.config/git/` | ✓ | ✓ | ✓ | |
| `dot_vim` | `.vim/` | ✓ | ✓ | ✓ | |
| `dot_vimrc` | `.vimrc` | ✓ | ✓ | ✓ | |
| `dot_config/bat` | `.config/bat/` | ✓ | ✓ | — | |
| `dot_config/btop` | `.config/btop/` | ✓ | ✓ | — | |
| `dot_config/delta` | `.config/delta/` | ✓ | ✓ | — | |
| `dot_config/eza` | `.config/eza/` | ✓ | ✓ | — | |
| `dot_config/lazygit` | `.config/lazygit/` | ✓ | ✓ | — | |
| `dot_config/nvim` | `.config/nvim/` | ✓ | ✓ | — | |
| `dot_config/starship` | `.config/starship/` | ✓ | ✓ | — | |
| `dot_editorconfig` | `.editorconfig` | ✓ | ✓ | — | |
| `dot_ssh` | `.ssh/` | ✓ | ✓ | — | `lookPath "op"` guards individual keys |
| `dot_zsh` | `.zsh/` | ✓ | ✓ | — | |
| `dot_zshrc.tmpl` | `.zshrc` | ✓ | ✓ | — | |
| `dot_config/darkman` | `.config/darkman/` | ✓ | — | — | GNOME desktop (`contains "gnome" XDG_CURRENT_DESKTOP`) |
| `dot_config/homebrew` | `.config/homebrew/` | ✓ | — | — | macOS (workstation is always darwin or linux-arch/cachyos/fedora) |
| `dot_config/kitty` | `.config/kitty/` | ✓ | — | — | |
| `dot_config/niri` | `.config/niri/` | ✓ | — | — | `lookPath "niri"` |
| `dot_config/noctalia` | `.config/noctalia/` | ✓ | — | — | `lookPath "qs"` |
| `dot_config/yay` | `.config/yay/` | ✓ | — | — | |
| `dot_config/yazi` | `.config/yazi/` | ✓ | — | — | |
| `dot_config/zed` | `.config/zed/` | ✓ | — | — | |
| `dot_local/share/darkman` | `.local/share/darkman/` | ✓ | — | — | GNOME desktop |
| `sddm/` | (deployed by script 06) | ✓ | — | — | |

W = workstation, T = terminal, S = server.

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
| `run_after_NN-` | After **every** `chezmoi apply` (not used — update-only logic lives in `[hooks.update.post]`) |

Number prefix controls execution order within each group.

## Design Decisions

### Why Separate Bootstrap and Chezmoi?

**Bootstrap** solves the chicken-and-egg problem: a fresh system has no chezmoi.
It is the minimal installer (git + chezmoi only) that hands off immediately.

**Chezmoi** handles everything else: templating, idempotency, cross-platform file
deployment, state tracking, and native update mechanism.

### Why Dual Logging?

**Terminal** (FD3): Clean, color-coded status lines for the watching user.

**Log file**: Structured records for debugging — one line per event, every line
timestamped:

```
[2026-06-11 10:38:41] [CMD    ] Installing Pacman packages
[2026-06-11 10:38:41] [CMD    ] $ sudo pacman -S --needed --noconfirm bat eza …
[2026-06-11 10:38:41] [OUT    ] warning: bat-0.26.1-2.1 is up to date -- skipping
[2026-06-11 10:38:42] [OK     ] Installing Pacman packages (exit 0, 1s)
```

Levels: `START`/`END` (session), `SECTION`, `ACTION`, `CMD`/`OUT`/`OK`/`FAIL`
(command execution — every `[OUT]` line belongs to the `[CMD]` above it),
`INFO`/`WARN`/`ERROR`, `ASK` (prompt + response). Captured command output is
stripped of ANSI escapes; carriage-return progress redraws collapse to their
final state.

All chezmoi scripts detect an existing `BDB_LOG_FILE` from bootstrap and append
to it, producing a single audit trail for the entire installation.

### Why Machine Types?

Three types keep the same source tree deployable across full GUI environments, headless
dev machines, and minimal homelab servers:

| Concern | Workstation | Terminal | Server |
|---------|-------------|----------|--------|
| Editor | Neovim + Zed | Neovim + Vim | Vim |
| Terminal emulator | Kitty | (none) | (none) |
| File manager | yazi | (none) | (none) |
| Git TUI | lazygit | lazygit | (none) |
| System monitor | btop | btop | (none) |
| Dark mode | darkman (GNOME) | (none) | (none) |
| Vim config deployed | Yes | Yes | Yes |
| Neovim config deployed | Yes | Yes | No |

### Why EditorConfig as Single Source of Truth?

`~/.editorconfig` governs indent style/size, line endings, charset, and trailing-whitespace
across Vim, Neovim, VSCode, and Zed. Per-editor settings files (`settings.json`,
`options.lua`) only contain what EditorConfig cannot govern (e.g. vim mode, scrolloff).

### Why a Source-Only `sddm/` Directory?

Chezmoi targets `~/`. System-level files in `/etc/` and `/usr/share/` cannot be deployed
directly. The chosen pattern:

1. Store source in `sddm/` at the repo root (not `dot_config/`)
2. Exclude from home deployment via `.chezmoiignore`: `sddm/`
3. Deploy via `run_onchange_after_06-install-sddm.sh.tmpl` using `sudo install` (workstation only)
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

Hooks (`bdb_update.sh`) do not receive `[scriptEnv]` — they fall back to the
deployed helpers path (`~/.config/bdb/bdb_helpers.sh`).

## SSH Key Management

SSH public keys are managed as chezmoi templates that call `onepasswordRead` at apply time.
To prevent failures on machines where 1Password is not yet installed, all four keys are
wrapped in a `lookPath "op"` guard in `.chezmoiignore`.

After `run_onchange_after_02` installs 1Password, a second `chezmoi apply` deploys the keys.

## Error Handling

All scripts share a common lifecycle via `bdb_script_init` from `bdb_helpers.sh`,
which sets up per-run logging, strict mode, and traps:

```bash
source "${HELPERS}"
bdb_script_init "${BASH_SOURCE[0]}"
# equivalent to: per-script log file + set -euo pipefail
#                + trap 'bdb_handle_error' ERR + trap 'bdb_cleanup' EXIT
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

### Adding a New Core Package

1. Add an entry to `.chezmoidata.toml` with `name`, `managers`, and `machines`
2. The install script and Brewfile pick it up automatically on next render
3. Commit with `feat: add <package> to package matrix`

### Adding a New Optional Package (prompted install)

1. Create `run_onchange_after_NN-install-<pkg>.sh.tmpl`
2. Start with a `bdb_has_cmd` idempotency check
3. Add `bdb_ask` prompt before installing
4. Commit with `feat: add <package> install script`

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
