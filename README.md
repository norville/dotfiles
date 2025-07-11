# BOOTSTRAP NEW MACHINE

```bash
script="https://raw.githubusercontent.com/norville/dotfiles/main/dot_bin/bootstrap.sh"; \
[[ $(type curl &>/dev/null) ]] && \
/bin/bash -c "$(curl -fsSL $script)" || \
/bin/bash -c "$(wget -qO- $script)"
```
