# Dotfiles Repository

A comprehensive, cross-platform dotfiles management system using [Chezmoi](https://www.chezmoi.io/). This repository provides automated setup and configuration for development environments across macOS, Linux (Debian/Ubuntu, Fedora/RHEL, Arch/Manjaro), with consistent tooling and shell configuration.

## 🚀 Features

- **Cross-Platform Support**: macOS, Debian, Ubuntu, Fedora, RHEL, Arch, and Manjaro
- **Automated Bootstrap**: One-command installation script for fresh systems
- **Package Management**: Automatic installation of essential development tools
- **Shell Configuration**: Enhanced ZSH setup with Zinit plugin manager
- **Modern CLI Tools**: eza, bat, fzf, ripgrep, neovim, and more
- **Consistent Themes**: Tokyo Night Moon color scheme across all applications
- **SSH Management**: Integrated 1Password SSH agent support
- **Version Control**: Chezmoi-powered dotfile management with Git

## 📋 Requirements

- **Internet connection** for downloading packages and repositories
- **curl** or **wget** (at least one must be installed)
- **sudo privileges** for system package installation
- **Git** (will be installed by bootstrap if missing)

## 🎯 Quick Start

### Bootstrap a Fresh System

Run this single command to set up everything automatically:

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/norville/dotfiles/main/dot_config/bdb/bdb_bootstrap.sh)"
```

Or with wget:

```bash
bash -c "$(wget -qO- https://raw.githubusercontent.com/norville/dotfiles/main/dot_config/bdb/bdb_bootstrap.sh)"
```

**Alternative**: Download and run locally:

```bash
curl -fsSL https://raw.githubusercontent.com/norville/dotfiles/main/dot_config/bdb/bdb_bootstrap.sh -o bdb_bootstrap.sh
chmod +x bdb_bootstrap.sh
./bdb_bootstrap.sh
```

The bootstrap script will:
1. Detect your operating system
2. Install Chezmoi and dependencies
3. Prompt to update your system
4. Clone this dotfiles repository
5. Apply all configurations automatically

### Manual Installation

If you prefer manual control:

```bash
# Install chezmoi
sh -c "$(curl -fsLS get.chezmoi.io)"

# Initialize and apply dotfiles
chezmoi init --apply norville
```

## 📁 Repository Structure

### Root Configuration Files

| File | Description |
|------|-------------|
| `.chezmoi.toml.tmpl` | Chezmoi configuration with OS detection, template variables, and hooks |
| `.chezmoiignore` | Files to exclude from installation based on OS/platform |
| `.chezmoiexternal.toml.tmpl` | External resources (themes, fonts) to download and manage |

### Bootstrap Scripts (`.config/bdb/`)

| File | Description |
|------|-------------|
| `bdb_bootstrap.sh` | Main bootstrap script for fresh system setup |
| `bdb_helpers.sh` | Helper functions for colored output, user prompts, and error handling |

### Installation Scripts (`.chezmoiscripts/`)

These scripts run automatically during `chezmoi apply`:

| File | Description |
|------|-------------|
| `run_onchange_after_00-install-core.sh.tmpl` | Installs essential packages (git, zsh, neovim, bat, eza, fzf, etc.) |
| `run_onchange_after_01-optional-packages.sh.tmpl` | Prompts for optional packages (1Password, Docker, Ansible) |
| `run_onchange_after_02-install-vscode.sh.tmpl` | Prompts for and installs VS Code (workstation only) |
| `run_onchange_after_05-env-setup.sh.tmpl` | Configures shell, themes, and application settings |
| `run_after_10-env-update.sh.tmpl` | Updates packages and tools after `chezmoi update` |

### Shell Configuration (`.zsh/`)

| File | Description |
|------|-------------|
| `plugins.zsh` | Zinit plugin manager configuration and plugin list |
| `aliases.zsh` | Shell aliases for modern CLI tools and convenience shortcuts |

### Application Configurations

| Directory | Description |
|-----------|-------------|
| `.config/bat/` | Bat (syntax highlighter) configuration and themes |
| `.config/btop/` | Btop (system monitor) configuration and theme |
| `.config/eza/` | Eza (modern ls) color theme configuration |
| `.config/git/` | Git configuration with delta pager and Tokyo Night theme |
| `.config/kitty/` | Kitty terminal emulator configuration |
| `.config/lazygit/` | Lazygit configuration with Tokyo Night theme |
| `.config/nvim/` | Neovim configuration (LazyVim + Tokyo Night Moon) |
| `.config/starship/` | Starship prompt configuration |
| `.config/homebrew/` | Homebrew bundle file (macOS only) |

## 🛠️ Installed Tools

### Core Tools (All Systems)

- **Shell**: ZSH with Zinit plugin manager
- **Editor**: Neovim (workstation) / Vim (terminal machines)
- **Terminal**: Kitty (GPU-accelerated, workstation only)
- **Prompt**: Starship (cross-shell prompt)
- **Version Control**: Git with delta pager and enhanced configuration

### Modern CLI Replacements

| Traditional | Modern Alternative | Description |
|-------------|-------------------|-------------|
| `ls` | `eza` | Modern ls with colors and git integration |
| `cat` | `bat` | Syntax highlighting and line numbers |
| `find` | `fd` | Fast and user-friendly file finder |
| `grep` | `ripgrep` | Extremely fast recursive search |
| `top` | `btop` | Beautiful system monitor |
| `man` | `batman` | Man pages with syntax highlighting |
| `cd` | `zoxide` | Frecency-based directory jumping |

### Development Tools

- **lazygit**: Terminal UI for Git operations
- **fzf**: Fuzzy finder for files, history, and more
- **tree-sitter**: Parser generator for syntax highlighting

### Optional Tools (User Prompted)

- **1Password**: Password manager with SSH agent (workstation only)
- **Docker**: Container platform
- **Visual Studio Code**: Code editor (workstation only)
- **Ansible**: IT automation platform

## 🎨 Themes & Appearance

All applications use the **Tokyo Night Moon** color scheme for consistency:

- Neovim (LazyVim + transparent background)
- Kitty terminal
- Bat syntax highlighting
- Eza file listing colors
- Btop system monitor
- Starship prompt
- Delta git diff pager
- Lazygit
- FZF

## 🔑 SSH Keys

SSH keys are managed via 1Password and deployed as templates. They are skipped during `chezmoi apply` when the `op` CLI is not installed:

| Key | Host |
|-----|------|
| `norville_at_chikyu` | Personal machine |
| `ansible_at_chikyu` | Ansible automation |
| `norville_at_github` | GitHub |
| `norville_at_codeberg` | Codeberg |

## 📦 Package Managers

The dotfiles automatically detect and use the appropriate package manager:

| OS/Distribution | Package Manager |
|-----------------|-----------------|
| macOS | Homebrew |
| Debian/Ubuntu | APT + Snap |
| Fedora/RHEL | DNF + Flatpak |
| Arch/Manjaro | Pacman + AUR (yay) |

## 🖥️ Machine Types

Configurations are tailored per machine type, set during `chezmoi init`:

| Type | Description |
|------|-------------|
| `workstation` | Full setup: Neovim, Kitty, lazygit, btop, 1Password, VS Code |
| `terminal` | Minimal setup: Vim only, no GUI tools |

## 🔄 Updating

### Update Dotfiles

```bash
chezmoi update
```

This will:
1. Pull the latest changes from the repository
2. Apply any configuration updates
3. Run the environment update script
4. Update system packages
5. Update ZSH plugins via Zinit
6. Update Neovim plugins via Lazy.nvim
7. Rebuild application caches

### Update Only Dotfiles (No System Updates)

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
sudo pacman -Syu
```

## 🔧 Customization

### Modify Configurations

```bash
# Edit a managed file (opens in $EDITOR, applies on save)
chezmoi edit ~/.zshrc

# Apply changes
chezmoi apply
```

### Add New Files

```bash
# Add a new file to be managed
chezmoi add ~/.config/myapp/config.yml

# Commit changes
cd $(chezmoi source-path)
git add .
git commit -m "feat: add myapp configuration"
git push
```

## 📝 Useful Commands

### Chezmoi Commands

```bash
# Show what would change
chezmoi diff

# Apply changes
chezmoi apply

# Update from repository
chezmoi update

# Edit configuration
chezmoi edit ~/.zshrc

# Show managed files
chezmoi managed

# Check for problems
chezmoi doctor
chezmoi verify
```

### Zinit Commands

```bash
zinit update --all    # Update all plugins and Zinit itself
zinit self-update     # Update only Zinit
zinit list            # List loaded plugins and snippets
zinit times           # Show per-plugin load times (profiling)
```

## 🐛 Troubleshooting

### Bootstrap Fails

If the bootstrap script fails:

1. Check internet connection
2. Ensure curl or wget is installed
3. Verify sudo privileges
4. Check the log file: `bdb_log_YYYYMMDD_HHMMSS.txt`

### Chezmoi Issues

```bash
# Verify chezmoi installation
chezmoi doctor

# Rebuild from scratch
chezmoi init --apply --force norville

# Check for conflicts
chezmoi verify
```

### Font Issues (Linux)

```bash
# Rebuild font cache
fc-cache -fv

# Verify font installation
fc-list | grep "JetBrainsMono Nerd Font"
```

## 🔗 Resources

- [Chezmoi Documentation](https://www.chezmoi.io/)
- [Zinit Plugin Manager](https://github.com/zdharma-continuum/zinit)
- [LazyVim](https://www.lazyvim.org/)
- [Starship Prompt](https://starship.rs/)
- [Tokyo Night Theme](https://github.com/folke/tokyonight.nvim)

## ✨ Acknowledgments

- Built with [Chezmoi](https://www.chezmoi.io/) for dotfile management
- Powered by [Zinit](https://github.com/zdharma-continuum/zinit) for ZSH plugins
- Themed with [Tokyo Night](https://github.com/folke/tokyonight.nvim)
- Inspired by the dotfiles community

---

**Repository**: https://github.com/norville/dotfiles
**Author**: Norville
**Contact**: ing.norville@proton.me
