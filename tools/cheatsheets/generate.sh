#!/usr/bin/env bash
# =============================================================================
# cheatsheets — regenerate the keybinding cheatsheet PNGs
# =============================================================================
# One tokyonight-moon PNG per tool (bat btop delta kitty lazygit niri noctalia
# lazyvim yazi), merging each tool's official defaults with the keys defined in
# these dotfiles (dotfile keys in orange). Output lands in the chezmoi source,
# home/Pictures/Cheatsheets/, so `chezmoi apply` deploys it to
# ~/Pictures/Cheatsheets on workstations.
#
# Reads the dotfiles from the chezmoi SOURCE (rendered into a scratch home with
# `chezmoi archive`), so a keybinding edit is reflected without applying it.
# Defaults come from the installed tools, or from their docs pinned to the
# installed version (downloaded once into .cache/dl). See build.py.
#
# Needs: chezmoi, python3 (3.11+), kitty, nvim, ImageMagick and a Chromium-based
# browser (Brave/Chromium/Chrome) for the headless screenshots.
#
# Not a dotfile — lives in tools/ at the repo root, outside .chezmoiroot (home/),
# so chezmoi never deploys it.
#
# Usage:  tools/cheatsheets/generate.sh [tool ...]       (default: all)
#   CHEATSHEETS_BROWSER=/path/to/chromium   browser binary to use
#   CHEATSHEETS_NO_SANDBOX=1                pass --no-sandbox (needed when run
#                                           inside an already-sandboxed shell,
#                                           where Chromium's sandbox hangs)
# =============================================================================
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "${HERE}/../.." && pwd)"
CACHE="${HERE}/.cache"
OUT="${REPO}/home/Pictures/Cheatsheets"
SCRATCH="${CACHE}/home"
tools=("$@")

mkdir -p "${CACHE}"/{data,dl,html,raw} "${OUT}"

# -----------------------------------------------------------------------------
# 1. Render the relevant dotfiles from the chezmoi source into a scratch home
# -----------------------------------------------------------------------------
rm -rf "${SCRATCH}" && mkdir -p "${SCRATCH}"
chezmoi --source "${REPO}" archive --format tar --output "${CACHE}/home.tar" \
    ~/.config/{bat,btop,delta,kitty,lazygit,niri,noctalia,nvim,yazi} 2>/dev/null || true
tar -m -xf "${CACHE}/home.tar" -C "${SCRATCH}"  # -m: chezmoi stamps files a hair in the future
rm -f "${CACHE}/home.tar"

# lazyvim.json (enabled extras) and lazy-lock.json are not tracked; borrow them.
for f in lazyvim.json lazy-lock.json; do
    [[ -f "${SCRATCH}/.config/nvim/${f}" || ! -f ~/.config/nvim/${f} ]] \
        || cp ~/.config/nvim/"${f}" "${SCRATCH}/.config/nvim/"
done

want() { [[ ${#tools[@]} -eq 0 ]] || [[ " ${tools[*]} " == *" $1 "* ]]; }

# -----------------------------------------------------------------------------
# 2. Dumps that need the tool's own runtime
# -----------------------------------------------------------------------------
if want kitty; then
    kitty +launch "${HERE}/kitty_maps.py" "${SCRATCH}/.config/kitty/kitty.conf" "${CACHE}/data/kitty-maps.json"
fi
if want lazyvim; then
    CHEATSHEETS_NVIM_OUT="${CACHE}/data/nvim-keymaps.json" XDG_CONFIG_HOME="${SCRATCH}/.config" \
        timeout 120 nvim --headless "+luafile ${HERE}/nvim_dump.lua" +qa >/dev/null 2>&1
fi

# -----------------------------------------------------------------------------
# 3. HTML
# -----------------------------------------------------------------------------
rm -f "${CACHE}"/html/*.html
python3 -I "${HERE}/build.py" --home "${SCRATCH}" --cache "${CACHE}" --repo "${REPO}" "${tools[@]}"

# -----------------------------------------------------------------------------
# 4. PNG — headless screenshot (measure, then 2x), trim, palette-compress
# -----------------------------------------------------------------------------
browser="${CHEATSHEETS_BROWSER:-}"
if [[ -z "${browser}" ]]; then
    for b in /opt/brave-bin/brave chromium google-chrome-stable brave; do
        command -v "${b}" >/dev/null 2>&1 && { browser="${b}"; break; }
    done
fi
[[ -n "${browser}" ]] || { echo "no Chromium-based browser found (set CHEATSHEETS_BROWSER)" >&2; exit 1; }

sandbox=()
[[ "${CHEATSHEETS_NO_SANDBOX:-}" == 1 ]] && sandbox=(--no-sandbox)

# Short throwaway profile: Chromium puts a socket in it and long paths overflow.
profile="$(mktemp -d /tmp/cheatsheets.XXXX)"
trap 'rm -rf "${profile}"' EXIT

# The first launch on a fresh profile can stall in first-run setup, so each
# shot gets a timeout and one retry.
shot() {  # html scale width height out
    local _
    for _ in 1 2; do
        timeout 30 "${browser}" --headless=new --disable-gpu "${sandbox[@]}" \
            --no-first-run --disable-component-update --user-data-dir="${profile}" \
            --hide-scrollbars --force-device-scale-factor="$2" --window-size="$3,$4" \
            --screenshot="$5" "file://$1" >/dev/null 2>&1 && return 0
    done
    echo "screenshot failed: $1" >&2
    return 1
}

for html in "${CACHE}"/html/*.html; do
    name="$(basename "${html}" .html)"
    width="$(grep -o 'class="page" style="width:[0-9]*' "${html}" | grep -o '[0-9]*$')"

    # Measure the content height (bounding box of non-background pixels).
    shot "${html}" 1 "${width}" 9000 "${CACHE}/raw/${name}-measure.png"
    geom="$(magick "${CACHE}/raw/${name}-measure.png" -fuzz 2% -trim -format '%h+%Y' info:)"

    # Headless capture is a little shorter than the window: render with headroom,
    # then trim to the content and add an even border. PNG8 keeps it ~1/3 size.
    shot "${html}" 2 "${width}" "$(( ${geom%%+*} + ${geom##*+} + 200 ))" "${CACHE}/raw/${name}-2x.png"
    magick "${CACHE}/raw/${name}-2x.png" -fuzz 2% -trim +repage -bordercolor '#222436' -border 64 \
        -colors 256 -define png:compression-level=9 "PNG8:${OUT}/${name}.png"
    printf '  %-9s %s\n' "${name}" "$(magick identify -format '%wx%h' "${OUT}/${name}.png")"
done
