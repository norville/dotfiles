# Dotfiles TODO

- [ ] Define installation types (workstation / vm / headless): add `.machine` template variable to `.chezmoi.toml.tmpl`, gate package installs in `run_onchange_after_00` and `run_onchange_after_01`, exclude GUI-only configs via `.chezmoiignore`
  - [ ] Remove `dot_vimrc` and `dot_vim/` for `workstation` only; keep as fallback editor for `vm` and `headless` where nvim is not installed
  - [ ] Set `EDITOR=nvim VISUAL=nvim` in `dot_zshrc.tmpl:20–29` for `workstation`; keep vim fallback chain for `vm` and `headless`
  - [ ] Set chezmoi merge command to `nvim -d` for `workstation`; keep `vimdiff` for `vm` and `headless`
- [x] Fix or remove broken `. "$HOME/.local/share/../bin/env"` line in `dot_zshrc.tmpl:334`
- [x] Add FZF + bat preview integration in `dot_zshrc.tmpl`
- [x] Delete `dot_config/nvim/lua/plugins/example.lua` (dead code — guarded by `if true then return {} end`)
- [x] Gate `archlinux` plugin in `dot_zsh/antigen.zsh` to Arch-only
- [x] Verify `run_after_03-env-update.sh.tmpl` covers all secondary package managers per distro (snap on apt, flatpak on dnf, yay on pacman); move snap check outside apt block if needed
- [ ] After `chezmoi update`, diff installed packages against the managed list in `run_onchange_after_00` and prompt to remove unrecognised ones (add to `run_after_03-env-update.sh.tmpl`)
- [ ] Indent Go template directives (`{{- if ... }}`) consistently across all `.tmpl` files for readability
- [ ] Integrate 1Password SSH agent: configure `dot_ssh/private_config.tmpl` to point `IdentityAgent` to the 1Password socket, ensure the 1Password plugin in `antigen.zsh` is active, and verify private keys are not stored on disk
- [ ] macOS: remove hardcoded `brew upgrade --cask` block from `run_after_03-env-update.sh.tmpl`; limit automated updates to formulae only (`brew upgrade` without `--cask`)
- [x] Verify `eza` plugin in `dot_zsh/antigen.zsh` vs manual aliases — remove if duplicate
- [x] Investigate Antigen cache behaviour for faster shell startup
- [x] Enable `lazy = true` in `dot_config/nvim/lua/config/lazy.lua`
