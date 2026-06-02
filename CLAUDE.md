# CLAUDE.md — norville/dotfiles

Context and conventions for Claude Code operating in this repository.

---

## Repository overview

Cross-platform dotfiles managed with [chezmoi](https://www.chezmoi.io/).
Targets macOS, Debian/Ubuntu, Fedora/RHEL, and Arch/Manjaro.

**Source**: `github.com/norville/dotfiles`
**Dotfile manager**: chezmoi (`~/.local/share/chezmoi` is the source directory)

---

## File naming conventions (chezmoi)

| chezmoi prefix / suffix | Meaning |
|--------------------------|---------|
| `dot_` | Deployed with a leading `.` (e.g. `dot_zshrc` → `~/.zshrc`) |
| `private_` | Deployed with `chmod 600` |
| `.tmpl` | Go template — variables substituted at apply time |
| `run_onchange_after_NN-` | Script that runs when its content changes, after file application |
| `run_after_NN-` | Script that runs after every `chezmoi update` |

Always edit **source** files (`chezmoi edit <target>` or directly in `~/.local/share/chezmoi`).
Never hand-edit deployed files — they will be overwritten on the next `chezmoi apply`.

---

## Directory layout

```
dotfiles/
├── .chezmoi.toml.tmpl          # Main chezmoi config; defines template variables
├── .chezmoiexternal.toml.tmpl  # External assets (fonts, themes)
├── .chezmoiignore              # OS/platform/machine exclusions
├── CLAUDE.md                   # This file — not deployed
├── ARCHITECTURE.md             # System architecture — not deployed
├── README.md                   # User docs — not deployed
├── TODO.md                     # Open tasks — not deployed
├── .chezmoiscripts/
│   ├── run_onchange_after_00-install-core.sh.tmpl
│   ├── run_onchange_after_01-optional-packages.sh.tmpl
│   ├── run_onchange_after_02-install-vscode.sh.tmpl   # workstation only
│   ├── run_onchange_after_05-env-setup.sh.tmpl
│   └── run_after_10-env-update.sh.tmpl
├── dot_config/
│   ├── bdb/                    # Bootstrap scripts (bdb_helpers.sh; bdb_bootstrap.sh not deployed)
│   ├── bat/                    # bat config & Tokyo Night theme
│   ├── btop/                   # btop config & Tokyo Night theme
│   ├── delta/                  # delta pager Tokyo Night config
│   ├── eza/                    # eza color config
│   ├── git/                    # git config, global ignore, delta integration
│   ├── kitty/                  # Kitty terminal config (workstation only)
│   ├── lazygit/                # lazygit config with Tokyo Night theme
│   ├── nvim/                   # Neovim (LazyVim) config — see section below
│   └── starship/               # Starship prompt config
├── dot_zsh/
│   ├── plugins.zsh             # Zinit plugin manager and plugin list
│   └── aliases.zsh             # Shell aliases
├── dot_zshrc.tmpl              # Main .zshrc (templated)
├── dot_editorconfig            # Global EditorConfig (single source of truth)
├── dot_vimrc                   # Vim config (terminal machines only)
├── dot_vim/                    # Vim plugins (terminal machines only)
└── dot_ssh/                    # SSH config and 1Password-managed public keys
```

---

## Neovim setup

**Distribution**: [LazyVim](https://www.lazyvim.org/)
**Theme**: Tokyo Night Moon (transparent background)
**Machine**: workstation only — not deployed on terminal machines

### Config layout

```
dot_config/nvim/
├── init.lua                    # Entry point — bootstraps lazy.nvim
└── lua/
    ├── config/
    │   ├── lazy.lua            # lazy.nvim setup; all custom plugins lazy=true by default
    │   ├── options.lua         # vim.opt / vim.g overrides
    │   ├── keymaps.lua         # Custom keymaps
    │   └── autocmds.lua        # Filetype autocmds + chezmoi .tmpl detection
    └── plugins/                # Plugin spec files (one concern per file)
        ├── colorscheme.lua     # Tokyo Night Moon; on_highlights hook for transparency fixes
        ├── render-markdown.lua # render-markdown.nvim config
        └── lint.lua            # nvim-lint; markdownlint-cli2 configured
```

### Key configuration decisions

- `vim.g.autoformat = false` — format-on-save is **disabled**; run manually.
- `vim.opt.concealcursor = "nc"` — concealed syntax stays hidden in normal + command mode.
- `vim.g.editorconfig = true` — Neovim honours `.editorconfig` for indent/charset/trim.
- `lazy = true` is the **default** for all custom plugins; set `lazy = false` explicitly only for plugins that must load at startup (e.g. colorscheme).
- chezmoi `.tmpl` files get filetype-detected from their base name (e.g. `dot_zshrc.tmpl` → `zsh`, `dot_vimrc.tmpl` → `vim`).
- Caddyfile autocmd sets `expandtab = false` to enforce tabs regardless of EditorConfig.

### render-markdown.nvim

- `render_modes = {"n", "c"}` — renders in normal and command mode.
- `position = "inline"` — heading icons rendered inline.
- `on_highlights` hook in `colorscheme.lua` restores heading/code-block backgrounds lost to transparency.

### Linting

- markdownlint-cli2 config: `~/.config/nvim/lua/config/markdownlint-cli2.yaml`.

---

## Shell setup

**Shell**: Zsh
**Plugin manager**: [Zinit](https://github.com/zdharma-continuum/zinit)
**Plugin config**: `~/.zsh/plugins.zsh`

### Plugin load order (strict — do not reorder)

1. OMZ library snippets (`OMZL::`)
2. OMZ plugin snippets (`OMZP::`)
3. `zsh-completions`
4. `zsh-autosuggestions`
5. `fzf-tab` ← must come after autosuggestions
6. `zsh-syntax-highlighting`
7. `zsh-history-substring-search` ← must be last

### Active OMZ plugin snippets

`1password`, `aliases`, `ansible`, `archlinux` (Arch only), `chezmoi`, `docker`,
`docker-compose`, `extract`, `git`, `kitty`, `sudo`

### Key shell details

- Aliases defined in `~/.zsh/aliases.zsh`; modern CLI replacements: `eza` (ls), `bat` (cat), `btop` (top), `fd` (find), `ripgrep` (grep).
- `batman` wraps `man` with bat syntax highlighting.
- FZF colours use Tokyo Night Moon palette; `fd` is the default find command.
- `zoxide` provides `z` / `zi` (frecency-ranked cd). `unalias zi` runs before `zoxide init zsh` in `.zshrc` so zoxide's `zi` takes precedence over zinit's alias.
- Preferred shell reload: `exec zsh` (not `source ~/.zshrc`).

---

## EditorConfig

`~/.editorconfig` is the **single source of truth** for indent style/size, line endings, charset, and trailing-whitespace handling across Vim, Neovim, and VSCode.

Do **not** add editor-specific settings that duplicate EditorConfig rules.

### Notable overrides

| File type | Indent | Reason |
|-----------|--------|--------|
| Shell (`sh`, `bash`, `zsh`) | 4 spaces | Matches nesting depth in bootstrap scripts |
| Python | 4 spaces | PEP 8 |
| Go | tabs | `gofmt` requirement |
| Makefile | tabs | Make syntax requirement |
| Caddyfile | tabs | Caddy canonical style |
| KDL | 2 spaces | Community default |
| QML | 4 spaces | Community default |
| `~/.config/niri/config.kdl` | 4 spaces | Niri-specific override |
| Markdown | trim_trailing_whitespace = false | Two trailing spaces = intentional line break |

---

## Theme

**Tokyo Night Moon** (`#222436` background) applied consistently to:
bat · btop · delta · eza · fzf · Kitty · lazygit · Neovim · Starship

Hex palette reference:
- bg `#222436`, bg+ `#2f334d`, fg `#c8d3f5`
- blue `#82aaff`, cyan `#86e1fc`, green `#c3e88d`, red `#ff757f`
- selection `#2d3f76`, comment/disabled `#636da6`

---

## SSH key management

Four public keys, all managed via 1Password templates. All are guarded in `.chezmoiignore` by `lookPath "op"` — they are skipped when `op` is not yet installed and deployed on a second `chezmoi apply` after 1Password is set up.

| Key | Host |
|-----|------|
| `norville_at_chikyu` | Personal machine |
| `ansible_at_chikyu` | Ansible automation |
| `norville_at_github` | GitHub |
| `norville_at_codeberg` | Codeberg |

---

## Machine types

| Type | Editor | Terminal | lazygit | btop | Vim config |
|------|--------|----------|---------|------|------------|
| `workstation` | Neovim | Kitty | ✓ | ✓ | not deployed |
| `terminal` | Vim | — | — | — | deployed |

---

## Common chezmoi workflows

```bash
# Edit a managed file (opens in $EDITOR, applies on save)
chezmoi edit ~/.zshrc

# Preview what would change
chezmoi diff

# Apply source → home
chezmoi apply

# Pull latest from GitHub and apply
chezmoi update

# Add a new file to management
chezmoi add ~/.config/myapp/config.yml

# Check for problems
chezmoi doctor
chezmoi verify
```

---

## Conventions for making changes

- **Shell scripts** — use `bdb_helpers.sh` functions (`bdb_action`, `bdb_exec`, `bdb_success`, `bdb_warn`) for output; do not use raw `echo`.
- **New Zsh plugins** — add to `dot_zsh/plugins.zsh`, respect the load order above.
- **New chezmoi scripts** — prefix with the next available two-digit number in the appropriate slot; use `run_onchange_after_NN-` unless the script should only run on `chezmoi update` (use `run_after_NN-` then).
- **Neovim plugins** — create a dedicated file under `dot_config/nvim/lua/plugins/`; set `lazy = true` unless there is a specific reason not to.
- **Secrets** — use 1Password template functions (`onepasswordRead`, `onepassword`) in `.tmpl` files; never hardcode credentials.
- **New SSH keys** — add the `.pub.tmpl` file, add the SSH config stanza to `private_config.tmpl`, and add the target path to the `lookPath "op"` guard in `.chezmoiignore`. Commit all three files together.
- **Platform conditionals** — use chezmoi template variables (`machine`, `packageManager`, `.chezmoi.os`, `.chezmoi.osRelease.id`) rather than runtime `uname` checks where possible.
- **Commit messages** — conventional commits style: `feat:`, `fix:`, `chore:`, `refactor:`, etc.

---

## Out of scope / do not change without discussion

- The `dot_editorconfig` indent decisions (intentional, documented above).
- `vim.g.autoformat = false` — format-on-save stays off.
- Load order of Zinit plugins.
- The `lazy = true` default in `lazy.lua`.

---

## Open TODOs

- Ubuntu Snap packages install not yet implemented
- Optional packages for conda, golang, java, lua, nodejs, ruby, rust not yet implemented
- macOS `defaults` automation not yet scripted
- Evaluate Ansible over BDB for provisioning
