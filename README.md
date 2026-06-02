# Dotfiles Repository

A comprehensive, cross-platform dotfiles management system using [Chezmoi](https://www.chezmoi.io/). This repository provides automated setup and configuration for development environments across macOS, Linux (Debian/Ubuntu, Fedora/RHEL, Arch/Manjaro), with consistent tooling and shell configuration.

## Features

- **Cross-Platform Support**: macOS, Debian, Ubuntu, Fedora, RHEL, Arch, and Manjaro
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

Run this single command to set up everything automatically:

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/norville/dotfiles/main/dot_config/bdb/bdb_bootstrap.sh)"
```

Or with wget:

```bash
bash -c "$(wget -qO- https://raw.githubusercontent.com/norville/dotfiles/main/dot_config/bdb/bdb_bootstrap.sh)"
```

The bootstrap script will:
1. Detect your operating system
2. Install Chezmoi and dependencies
3. Prompt to update your system
4. Clone this dotfiles repository
5. Apply all configurations automatically

### Manual Installation

```bash
# Install chezmoi
sh -c "$(curl -fsLS get.chezmoi.io)"

# Initialize and apply dotfiles
chezmoi init --apply norville
```

## Repository Structure

### Root Configuration Files

| File | Description |
|------|-------------|
| `.chezmoi.toml.tmpl` | Chezmoi config: OS detection, template variables, package lists |
| `.chezmoiignore` | Files excluded from deployment based on OS/platform/machine type |
| `.chezmoiexternal.toml.tmpl` | External resources (Tokyo Night themes, fonts) downloaded by chezmoi |

### Bootstrap Scripts (`.config/bdb/`)

| File | Description |
|------|-------------|
| `bdb_bootstrap.sh` | Main bootstrap script for fresh system setup (not deployed) |
| `bdb_helpers.sh` | Helper functions: colored output, user prompts, logging, error handling |

### Installation Scripts (`.chezmoiscripts/`)

These scripts run automatically during `chezmoi apply` or `chezmoi update`:

| File | Trigger | Description |
|------|---------|-------------|
| `run_onchange_after_00-install-core.sh.tmpl` | on change | Essential packages: zsh, neovim/vim, bat, eza, fzf, ripgrep, lazygit, kitty… |
| `run_onchange_after_01-install-1password.sh.tmpl` | on change | Prompts for and installs 1Password + CLI (workstation only) |
| `run_onchange_after_02-install-vscode.sh.tmpl` | on change | Prompts for and installs VS Code (workstation only) |
| `run_onchange_after_03-install-docker.sh.tmpl` | on change | Prompts for and installs Docker |
| `run_onchange_after_04-install-ansible.sh.tmpl` | on change | Prompts for and installs Ansible |
| `run_onchange_after_05-env-setup.sh.tmpl` | on change | Set ZSH as default shell, verify themes and fonts |
| `run_onchange_after_06-sddm.sh.tmpl` | on change | Deploy SDDM config + Tokyo Night Moon theme to `/etc/` and `/usr/share/` |
| `run_onchange_after_07-darkman.sh.tmpl` | on change | Enable darkman.service (GNOME workstations only) |
| `run_after_10-env-update.sh.tmpl` | every update | Update system packages, ZSH plugins, bat theme cache, font cache |
| `run_after_20-audit-packages.sh.tmpl` | every update | Report packages installed outside chezmoi's managed lists |

### Shell Configuration (`.zsh/`)

| File | Description |
|------|-------------|
| `plugins.zsh` | Zinit plugin manager: load order, plugin list, fzf-tab, syntax highlighting |
| `aliases.zsh` | Shell aliases for modern CLI tools and convenience shortcuts |

### Application Configurations

| Directory | Description | Condition |
|-----------|-------------|-----------|
| `.config/bat/` | Bat syntax highlighter — config and Tokyo Night theme | all |
| `.config/btop/` | Btop system monitor — config and Tokyo Night theme | workstation |
| `.config/darkman/` | darkman auto dark/light mode — config and switch scripts | GNOME workstation |
| `.config/delta/` | Delta git diff pager — Tokyo Night theme | all |
| `.config/eza/` | Eza (modern ls) — Tokyo Night color theme | all |
| `.config/git/` | Git config, global ignore, delta integration | all |
| `.config/kitty/` | Kitty terminal — config, tab bar, Tokyo Night theme, session management | workstation |
| `.config/lazygit/` | Lazygit TUI — Tokyo Night theme | workstation |
| `.config/nvim/` | Neovim (LazyVim + Tokyo Night Moon, transparent bg) | workstation |
| `.config/starship/` | Starship cross-shell prompt | all |
| `.config/yay/` | yay AUR helper — build dir and config | pacman only |
| `.config/yazi/` | yazi file manager — config, Tokyo Night theme, status bar plugin | workstation |
| `.config/zed/` | Zed editor — settings aligned with nvim, Tokyo Night theme | workstation |
| `.config/homebrew/` | Homebrew bundle file | macOS only |

## Installed Tools

### Core Tools (All Systems)

- **Shell**: ZSH with Zinit plugin manager
- **Editor**: Neovim (workstation) / Vim (terminal machines)
- **Terminal**: Kitty (GPU-accelerated, workstation only)
- **Prompt**: Starship (cross-shell prompt)
- **Version Control**: Git with delta pager and enhanced configuration

### Modern CLI Replacements

| Traditional | Modern Alternative | Description |
|-------------|-------------------|-------------|
| `ls` | `eza` | Modern ls with colors, git integration, icons |
| `cat` | `bat` | Syntax highlighting and line numbers |
| `find` | `fd` | Fast and user-friendly file finder |
| `grep` | `ripgrep` | Extremely fast recursive search |
| `top` | `btop` | Beautiful system monitor |
| `man` | `batman` | Man pages with bat syntax highlighting |
| `cd` | `zoxide` | Frecency-based directory jumping (`z` / `zi`) |

### Workstation Tools

- **yazi**: Terminal file manager with image previews (requires Kitty)
- **zed**: Modern code editor (Tokyo Night Moon theme, aligned with nvim settings)
- **lazygit**: Terminal UI for Git operations
- **fzf**: Fuzzy finder for files, history, and more
- **darkman**: Automatic dark/light mode switching by geographic position (GNOME only)

### Optional Tools (User Prompted on First Apply)

All optional installs are idempotent — if the tool is already present, the prompt is skipped.

- **1Password**: Password manager with SSH agent (workstation only)
- **Visual Studio Code**: Code editor (workstation only)
- **Docker**: Container platform
- **Ansible**: IT automation platform

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
| macOS | Homebrew |
| Debian/Ubuntu | APT + Snap |
| Fedora/RHEL | DNF + Flatpak |
| Arch/Manjaro | Pacman + AUR (yay) |

## Machine Types

Configurations are tailored per machine type, detected automatically at `chezmoi init`:

| Type | Description |
|------|-------------|
| `workstation` | Full setup: Neovim, Zed, Kitty, lazygit, btop, yazi, 1Password, VS Code |
| `terminal` | Minimal setup: Vim only, no GUI tools |

## Updating

### Update Dotfiles and System

```bash
chezmoi update
```

This will:
1. Pull the latest changes from the repository
2. Apply any configuration updates
3. Run the environment update script (`10-env-update`)
4. Update system packages
5. Update ZSH plugins via Zinit
6. Rebuild bat theme cache and font cache
7. Run the package audit (`20-audit-packages`)

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

# Fedora/RHEL
sudo dnf upgrade -y

# Arch/Manjaro
sudo pacman -Syu && yay -Syu
```

## Customization

### Modify a Managed File

```bash
# Edit (opens in $EDITOR, applies on save)
chezmoi edit ~/.zshrc

# Or edit the source directly
nvim ~/.local/share/chezmoi/dot_zshrc.tmpl
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
