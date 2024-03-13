# BOOTSTRAP NEW MACHINE

## AUTO SETUP

```bash
script="https://raw.githubusercontent.com/norville/dotfiles/main/dot_config/dotfiles/bootstrap.sh"; \
[[ $(type curl &>/dev/null) ]] && \
/bin/bash -c "$(curl -fsSL $script)" || \
/bin/bash -c "$(wget -qO- $script)"
```

## MANUAL SETUP

1. Copy SSH keys.

2. Install chezmoi:

    - On Mac:

        ```bash
        type brew &>/dev/null || NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
        brew install chezmoi
        ```

    - On Debian:

        ```bash
        sudo sh -c "$(wget -qO- get.chezmoi.io)" -- -b /usr/local/bin
        ```

3. Setup apps and preferences:

    ```bash
    chezmoi init --apply norville
    ```
