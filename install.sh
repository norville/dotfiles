#!/usr/bin/env bash
# =============================================================================
# BDB Install — bootstrap entry point
# =============================================================================
# Short, stable URL wrapper: downloads and runs bdb_bootstrap.sh, trying
# curl first and falling back to wget.
#
# Usage:
#   wget -qO install.sh https://bit.ly/4gm2dU8
#   or
#   curl -fsSL https://bit.ly/4gm2dU8 -o install.sh
#   chmod +x install.sh && ./install.sh
# =============================================================================

set -euo pipefail

_BDB_URL="https://raw.githubusercontent.com/norville/dotfiles/main/home/dot_config/bdb/bdb_bootstrap.sh"

if command -v curl >/dev/null 2>&1; then
    exec bash -c "$(curl -fsSL "${_BDB_URL}")"
elif command -v wget >/dev/null 2>&1; then
    exec bash -c "$(wget -qO- "${_BDB_URL}")"
else
    echo "Error: curl or wget is required. Please install one and try again." >&2
    exit 1
fi
