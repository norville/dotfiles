# SETUP NEW COMPUTER

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
    chezmoi init --apply --ssh norville
    ```
