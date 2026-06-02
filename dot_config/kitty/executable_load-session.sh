#!/usr/bin/env bash
# Load a saved kitty session into a new tab.
# Invoked by F4 via `launch --type=overlay` in kitty.conf.
# Requires allow_remote_control socket-only + listen_on in kitty.conf.

SESSION_DIR="${HOME}/.config/kitty/sessions"

if [[ -z "$(find "${SESSION_DIR}" -maxdepth 1 -name '*.kitty-session' 2>/dev/null)" ]]; then
    echo "No saved sessions in ${SESSION_DIR}"
    read -r -s -n1
    exit 0
fi

session=$(find "${SESSION_DIR}" -maxdepth 1 -name '*.kitty-session' \
    | sed "s|${SESSION_DIR}/||; s|\.kitty-session\$||" \
    | sort \
    | fzf --prompt="Load session: " --reverse --height=40%)

[[ -n "${session}" ]] && kitty @ launch --type=tab --session "${SESSION_DIR}/${session}.kitty-session"
