# SETUP NEW MAC

1. Copy SSH keys.

2. Install Homebrew:

    ```bash
    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
    ```

3. Install chezmoi:

    ```bash
    brew install chezmoi
    ```

4. Setup apps and preferences:

    ```bash
    chezmoi init --apply --ssh norville
    ```
