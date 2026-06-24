# Dotfiles Repository

A comprehensive, cross-platform dotfiles management system using [Chezmoi](https://www.chezmoi.io/). This repository provides automated setup and configuration for development environments across macOS, Linux (Debian/Ubuntu, Fedora, Rocky Linux, Arch/CachyOS), with consistent tooling and shell configuration.

## Features

- **Cross-Platform Support**: macOS, Debian, Ubuntu, Fedora, Rocky Linux, Arch, and CachyOS
- **Automated Bootstrap**: One-command installation script for fresh systems
- **Idempotent Scripts**: All install scripts safely re-run — skip what is already installed
- **Package Management**: Automatic installation of essential development tools
- **Shell Configuration**: Enhanced ZSH setup with Zinit plugin manager
- **Modern CLI Tools**: eza, bat, fzf, ripgrep, neovim, yazi, zed, and more
- **Consistent Themes**: Tokyo Night Moon color scheme across all applications
- **SSH Management**: Integrated 1Password SSH agent support
- **Session Management**: Kitty terminal sessions saved/loaded with F1/F4

## Requirements

- **Internet connection** for downloading packages and repositories
- **curl** or **wget** (at least one must be installed)
- **sudo privileges** for system package installation
- **Git** (will be installed by bootstrap if missing)

## Quick Start

### Bootstrap a Fresh System

**1. Download `install.sh` from this repository**

```bash
wget -qO install.sh https://bit.ly/4gm2dU8
# or with curl:
curl -fsSL https://bit.ly/4gm2dU8 -o install.sh
```

**2. Make it executable, and run it**

```bash
chmod +x install.sh && ./install.sh
```

The bootstrap script will:
1. Detect your operating system
2. Install Chezmoi and dependencies
3. Prompt to update your system
4. Clone this dotfiles repository
5. Apply all configurations automatically

### Manual Installation

Install chezmoi, clone the dotfiles, and apply — all in one command. Everything
after `--` is handed to the freshly installed chezmoi binary, so this works
without chezmoi already being on `PATH`:

```bash
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply norville
```

Unlike the bootstrap, this does not update the system or pre-install
dependencies — git must already be present (see [Requirements](#requirements)),
and the chezmoi scripts install the rest on first apply.

## Repository Structure

### Repository Layout

The repo root holds only documentation and the chezmoi root pointer:

| File | Description |
|------|-------------|
| `.chezmoiroot` | Tells chezmoi to use `home/` as the source root |
| `install.sh` | Bootstrap entry point — short URL wrapper for `bdb_bootstrap.sh` |
| `README.md` | This file |
| `ARCHITECTURE.md` | System architecture reference |
| `TODO.md` | Open tasks |

All chezmoi-managed files live under `home/`:

| File | Description |
|------|-------------|
| `home/.chezmoi.toml.tmpl` | Chezmoi config: OS/machine/packageManager detection, template variables |
| `home/.chezmoidata.toml` | Canonical package matrix — single source of truth for all package data |
| `home/.chezmoiignore` | Files excluded from deployment based on OS/platform/machine type |
| `home/.chezmoiexternal.toml.tmpl` | External resources (Tokyo Night themes, fonts) downloaded by chezmoi |

### Bootstrap Scripts (`.config/bdb/`)

| File | Description |
|------|-------------|
| `bdb_bootstrap.sh` | Main bootstrap script for fresh system setup (not deployed) |
| `bdb_helpers.sh` | Helper functions: colored output, user prompts, logging, error handling |
| `bdb_update.sh` | System/toolchain update — runs as a chezmoi `[hooks.update.post]` hook |

### Installation Scripts (`home/.chezmoiscripts/`)

These scripts run automatically during `chezmoi apply` or `chezmoi update`:

| File | Trigger | Description |
|------|---------|-------------|
| `run_onchange_after_00-install-core.sh.tmpl` | on change | Essential packages: zsh, neovim/vim, bat, eza, fzf, ripgrep, lazygit, kitty, Go, Ruby, Rust, Java, OpenTofu… |
| `run_onchange_after_01-config-env.sh.tmpl` | on change | Default shell, themes/fonts; Go GOPATH/GOBIN; Ruby gems (bundler, erb); Rust stable toolchain + rust-analyzer via rustup |
| `run_onchange_after_02-install-1password.sh.tmpl` | on change | Prompts for and installs 1Password + CLI (workstation only) |
| `run_onchange_after_03-install-vscode.sh.tmpl` | on change | Prompts for and installs VS Code (workstation only) |
| `run_onchange_after_04-install-ansible.sh.tmpl` | on change | Prompts for and installs Ansible |
| `run_onchange_after_05-install-docker.sh.tmpl` | on change | Prompts for and installs Docker |
| `run_onchange_after_06-install-sddm.sh.tmpl` | on change | Deploy SDDM config + Tokyo Night Moon theme to `/etc/` and `/usr/share/` |
| `run_onchange_after_07-install-darkman.sh.tmpl` | on change | Enable darkman.service (GNOME workstations only) |

System and toolchain updates (`~/.config/bdb/bdb_update.sh`) run as a chezmoi
`[hooks.update.post]` hook — only after `chezmoi update`, never on plain
`chezmoi apply`. The hook updates system packages, ZSH plugins, bat theme cache,
font cache, `rustup update`, and `gem update bundler erb`.

### Shell Configuration (`home/.zsh/`)

| File | Description |
|------|-------------|
| `plugins.zsh` | Zinit plugin manager: load order, plugin list, fzf-tab, syntax highlighting |
| `aliases.zsh` | Shell aliases for modern CLI tools and convenience shortcuts |

### Application Configurations

| Directory | Description | Condition |
|-----------|-------------|-----------|
| `.config/bat/` | Bat syntax highlighter — config and Tokyo Night theme | workstation + terminal |
| `.config/btop/` | Btop system monitor — config and Tokyo Night theme | workstation + terminal |
| `.config/darkman/` | darkman auto dark/light mode — config and switch scripts | GNOME workstation (pacman/dnf only) |
| `.config/delta/` | Delta git diff pager — Tokyo Night theme | workstation + terminal |
| `.config/eza/` | Eza (modern ls) — Tokyo Night color theme | workstation + terminal |
| `.config/git/` | Git config, global ignore, delta integration | all |
| `.config/kitty/` | Kitty terminal — config, tab bar, Tokyo Night theme, session management | workstation |
| `.config/lazygit/` | Lazygit TUI — Tokyo Night theme | workstation + terminal |
| `.config/niri/` | niri tiling compositor | workstation (niri installed) |
| `.config/noctalia/` | Noctalia desktop shell — Tokyo Night colors | workstation (qs installed) |
| `.config/nvim/` | Neovim (LazyVim + Tokyo Night Moon, transparent bg) | workstation + terminal |
| `.config/starship/` | Starship cross-shell prompt | workstation + terminal |
| `.config/yay/` | yay AUR helper — build dir and config | workstation (pacman only) |
| `.config/yazi/` | yazi file manager — config, Tokyo Night theme, status bar plugin | workstation |
| `.config/zed/` | Zed editor — settings aligned with nvim, Tokyo Night theme | workstation |
| `.config/homebrew/` | Homebrew bundle file | macOS (workstation) |

## Installed Tools

### Core Tools

- **Version Control**: Git (all machine types)
- **Editor**: Vim (all) + Neovim (workstation + terminal)
- **Shell**: ZSH with Zinit plugin manager (workstation + terminal)
- **Prompt**: Starship cross-shell prompt (workstation + terminal)

### Workstation + Terminal Tools

| Traditional | Modern Alternative | Description |
|-------------|-------------------|-------------|
| `ls` | `eza` | Modern ls with colors, git integration, icons |
| `cat` | `bat` | Syntax highlighting and line numbers |
| `find` | `fd` | Fast and user-friendly file finder |
| `grep` | `ripgrep` | Extremely fast recursive search |
| `top` | `btop` | Beautiful system monitor |
| `man` | `batman` | Man pages with bat syntax highlighting |
| `cd` | `zoxide` | Frecency-based directory jumping (`z` / `zi`) |

Also: lazygit, fzf, git-delta, jq, resvg, tree-sitter-cli, Node.js + npm, shellcheck.

### Language Runtimes (Workstation + Terminal)

| Language | Runtime | Toolchain notes |
|----------|---------|-----------------|
| Go | `go` | GOPATH (`~/go`) and GOBIN (`~/go/bin`) configured via `go env -w` |
| Ruby | `ruby` | `bundler` and `erb` gems installed to user gem dir (`GEM_HOME`) |
| Rust | `rustup` | Stable toolchain + `rust-analyzer` component installed via rustup |
| Java | JDK | `jdk-openjdk` / `openjdk` / `default-jdk` / `java-devel` per platform |
| Terraform/OpenTofu | `opentofu` (`tofu` on apt) | LazyVim terraform extra redirected to `tofu` binary |

### Workstation-Only Tools

- **Kitty**: GPU-accelerated terminal (workstation only)
- **yazi**: Terminal file manager with image previews (requires Kitty)
- **zed**: Modern code editor (Tokyo Night Moon theme, aligned with nvim settings)
- **Brave Browser**: Web browser
- **darkman**: Automatic dark/light mode switching by geographic position (GNOME only; pacman/dnf only — not available in apt repos)

### Optional Tools (User Prompted on First Apply)

All optional installs are idempotent — if the tool is already present, the prompt is skipped.

- **1Password**: Password manager with SSH agent (workstation only)
- **Visual Studio Code**: Code editor (workstation only)
- **Docker**: Container platform (workstation + server)
- **Ansible**: IT automation platform (all machine types)

## Themes & Appearance

All applications use the **Tokyo Night Moon** color scheme for consistency:

Bat · Btop · Delta · Eza · FZF · Kitty · lazygit · Neovim · SDDM · Starship · yazi · Zed

Themes are downloaded automatically by chezmoi from authoritative sources (mainly
`folke/tokyonight.nvim` extras and `ssaunderss/zed-tokyo-night`) — no manual theme
installation required.

## SSH Keys

SSH keys are managed via 1Password and deployed as templates. They are skipped during
`chezmoi apply` when the `op` CLI is not installed:

| Key | Host |
|-----|------|
| `norville_at_chikyu` | Personal machine |
| `ansible_at_chikyu` | Ansible automation |
| `norville_at_github` | GitHub |
| `norville_at_codeberg` | Codeberg |

## Package Managers

The dotfiles automatically detect and use the appropriate package manager:

| OS/Distribution | Package Manager |
|-----------------|-----------------|
| macOS | Homebrew (formulae + casks) |
| Debian/Ubuntu | APT + Snap |
| Fedora/Rocky Linux | DNF |
| Arch/CachyOS | Pacman + AUR (yay) |

## Machine Types

Three machine types are supported. `workstation` is auto-detected on macOS, Arch, CachyOS,
and Fedora, or when a graphical session is detected on Ubuntu. On Debian, Rocky Linux, and
headless Ubuntu the user is prompted for `terminal` or `server` on first `chezmoi init`
(shown interactively during bootstrap); the answer is cached for later applies.

| Type | Description | Dev tools | GUI tools |
|------|-------------|-----------|-----------|
| `workstation` | Full setup: Neovim, Zed, Kitty, lazygit, yazi, btop, Brave, 1Password, VS Code | ✅ | ✅ |
| `terminal` | CLI dev environment: Neovim, lazygit, btop, bat, eza, ripgrep — no GUI tools | ✅ | ❌ |
| `server` | Minimal homelab setup: git, vim, curl, wget, chezmoi only | ❌ | ❌ |

## Updating

### Update Dotfiles and System

```bash
chezmoi update
```

This will:
1. Pull the latest changes from the repository
2. Apply any configuration updates
3. Run the post-update hook (`~/.config/bdb/bdb_update.sh`)
4. Update system packages
5. Update ZSH plugins via Zinit
6. Rebuild bat theme cache and font cache
7. Update Rust toolchain (`rustup update`)
8. Update Ruby user gems (`bundler`, `erb`)

### Apply Config Changes Only (No System Updates)

```bash
chezmoi apply
```

### Manual Package Updates

```bash
# macOS
brew update && brew upgrade

# Debian/Ubuntu
sudo apt update && sudo apt upgrade -y

# Fedora/Rocky Linux
sudo dnf upgrade -y

# Arch/CachyOS
sudo pacman -Syu && yay -Syu
```

## Customization

### Modify a Managed File

```bash
# Edit (opens in $EDITOR, applies on save)
chezmoi edit ~/.zshrc

# Or edit the source directly
nvim ~/.local/share/chezmoi/home/dot_zshrc.tmpl
chezmoi apply
```

### Add a New File

```bash
chezmoi add ~/.config/myapp/config.yml
cd $(chezmoi source-path)
git add .
git commit -m "feat: add myapp configuration"
git push
```

## Useful Commands

### Chezmoi

```bash
chezmoi diff          # Preview pending changes
chezmoi apply         # Apply source → home
chezmoi update        # Pull from repo and apply
chezmoi edit ~/.zshrc # Edit a managed file
chezmoi managed       # List all managed files
chezmoi doctor        # Check for problems
chezmoi verify        # Verify deployed files match source
```

### Zinit

```bash
zinit update --all    # Update all plugins and Zinit itself
zinit self-update     # Update only Zinit
zinit list            # List loaded plugins and snippets
zinit times           # Show per-plugin load times (profiling)
```

## Troubleshooting

### Bootstrap Fails

1. Check internet connection
2. Ensure curl or wget is installed
3. Verify sudo privileges
4. Check the log file: `bdb_log_YYYYMMDD_HHMMSS.txt`

### Chezmoi Issues

```bash
chezmoi doctor                       # Verify chezmoi installation
chezmoi init --apply --force norville # Rebuild from scratch
chezmoi verify                       # Check for conflicts
```

### Font Issues (Linux)

```bash
fc-cache -fv
fc-list | grep "JetBrainsMono Nerd Font"
```

## Resources

- [Chezmoi Documentation](https://www.chezmoi.io/)
- [Zinit Plugin Manager](https://github.com/zdharma-continuum/zinit)
- [LazyVim](https://www.lazyvim.org/)
- [Starship Prompt](https://starship.rs/)
- [Tokyo Night Theme](https://github.com/folke/tokyonight.nvim)
- [yazi File Manager](https://yazi-rs.github.io/)
- [Zed Editor](https://zed.dev/)

---

**Repository**: https://github.com/norville/dotfiles
**Author**: Norville
**Contact**: ing.norville@proton.me
