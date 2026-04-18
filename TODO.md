# Dotfiles TODO

## Backlog

- define installation types:
  - workstation
  - vm
    - no: zsh, btop, fd, fzf, git, delta, gpg, kitty, ripgrep, starship, tree-sitter, eza, fresh, bat, bat-extras, lazygit, neovim, jetbrains, 1password, vscode, ansible
  - headless
    - no: kitty, starship, jetbrains, 1password, vscode
- config fd and fzf
- remove antidote update
- add snap/flatpack/yay update in bootstrap
- after chezmoi update print list of extra formulae/packages and ask for removal
- indent go templates
- integrate 1password and ssh keys
- macos: when updating env do not update brew casks, only formulae

## Audit fixes

- [ ] Remove `dot_vimrc` and `dot_vim/` (dead code — Neovim is the only editor)
- [x] Fix or remove broken `. "$HOME/.local/share/../bin/env"` line in `dot_zshrc.tmpl:334`
- [ ] Simplify editor env vars in `dot_zshrc.tmpl:20–29` to `export EDITOR=nvim VISUAL=nvim`
- [ ] Fix chezmoi merge command in `.chezmoi.toml.tmpl` from `vimdiff` to `nvim -d`
- [x] Add FZF + bat preview integration in `dot_zshrc.tmpl`
- [x] Delete `dot_config/nvim/lua/plugins/example.lua` (dead code — guarded by `if true then return {} end`)
- [ ] Gate `archlinux` plugin in `dot_zsh/antigen.zsh` to Arch-only
- [x] Verify `eza` plugin in `dot_zsh/antigen.zsh` vs manual aliases — remove if duplicate
- [x] Investigate Antigen cache behaviour for faster shell startup
- [x] Enable `lazy = true` in `dot_config/nvim/lua/config/lazy.lua`
