# Dotfiles TODO

- [ ] 1. Define installation types (workstation / vm / headless): add `.machine` template variable to `.chezmoi.toml.tmpl`, gate package installs in `run_onchange_after_00` and `run_onchange_after_01`, exclude GUI-only configs via `.chezmoiignore`
  - [ ] 1a. Remove `dot_vimrc` and `dot_vim/` for `workstation` only; keep as fallback editor for `vm` and `headless` where nvim is not installed
  - [ ] 1b. Set `EDITOR=nvim VISUAL=nvim` in `dot_zshrc.tmpl:20–29` for `workstation`; keep vim fallback chain for `vm` and `headless`
  - [ ] 1c. Set chezmoi merge command to `nvim -d` for `workstation`; keep `vimdiff` for `vm` and `headless`
- [x] 2. Fix or remove broken `. "$HOME/.local/share/../bin/env"` line in `dot_zshrc.tmpl:334`
- [x] 3. Add FZF + bat preview integration in `dot_zshrc.tmpl`
- [x] 4. Delete `dot_config/nvim/lua/plugins/example.lua` (dead code — guarded by `if true then return {} end`)
- [x] 5. Gate `archlinux` plugin in `dot_zsh/antigen.zsh` to Arch-only
- [x] 6. Verify `run_after_03-env-update.sh.tmpl` covers all secondary package managers per distro (snap on apt, flatpak on dnf, yay on pacman); move snap check outside apt block if needed
- [x] 7. After `chezmoi update`, diff installed packages against the managed list in `run_onchange_after_00` and prompt to remove unrecognised ones (add to `run_after_03-env-update.sh.tmpl`)
- [ ] 8. Indent Go template directives (`{{- if ... }}`) consistently across all `.tmpl` files for readability
- [ ] 9. Integrate 1Password SSH agent: configure `dot_ssh/private_config.tmpl` to point `IdentityAgent` to the 1Password socket, ensure the 1Password plugin in `antigen.zsh` is active, and verify private keys are not stored on disk
- [x] 10. macOS: remove hardcoded `brew upgrade --cask` block from `run_after_03-env-update.sh.tmpl`; limit automated updates to formulae only (`brew upgrade` without `--cask`)
- [x] 11. Verify `eza` plugin in `dot_zsh/antigen.zsh` vs manual aliases — remove if duplicate
- [x] 12. Investigate Antigen cache behaviour for faster shell startup
- [x] 13. Enable `lazy = true` in `dot_config/nvim/lua/config/lazy.lua`
