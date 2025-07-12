# BOOTSTRAP NEW MACHINE

```bash
#script="https://raw.githubusercontent.com/norville/dotfiles/main/dot_bin/bootstrap.sh"; \
script="https://raw.githubusercontent.com/norville/dotfiles/test/dot_config/bdb/bdb_bootstrap.sh"; \
[[ $(command -v curl &>/dev/null) ]] && \
/bin/bash -c "$(curl -fsSL $script)" || \
/bin/bash -c "$(wget -qO- $script)"
```

## TODO

- download helpers from bootstrap
- check whitespaces in go templates
- implement flags:
  - verbose
  - log file
  - no-confirm
- check out twpayne for new ideas
