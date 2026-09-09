#!/usr/bin/env bash
# =============================================================================
# fastfetch-dump — introspect every fastfetch module on THIS system
# =============================================================================
# For each module fastfetch knows about, print every format variable it exposes
# together with the value it renders to here. Modules that don't support output
# formatting (Break, Colors, Custom, Logo, Separator) or expose no variables are
# listed at the end as "skipped". Driver/probe noise on stderr (e.g. Mesa
# Rusticl warnings during GPU/OpenCL detection) is captured separately so it can
# never interleave the data.
#
# Fully dynamic: the module list and each module's variables are read from
# `fastfetch --list-modules` and `fastfetch --help <type>-format`, so it needs
# no hardcoding and tracks whatever fastfetch version is installed.
#
# Not a dotfile — lives in tools/ at the repo root, outside .chezmoiroot (home/),
# so chezmoi never deploys it.
#
# Usage:  tools/fastfetch-dump.sh [-o OUTFILE]
# =============================================================================
set -euo pipefail

outfile=""
[[ "${1:-}" == "-o" && -n "${2:-}" ]] && outfile="$2"

command -v fastfetch >/dev/null 2>&1 || { echo "fastfetch not found" >&2; exit 1; }

cfg="$(mktemp --suffix=.jsonc)"
skipped_file="$(mktemp)"
warn_file="$(mktemp)"
trap 'rm -f "$cfg" "$skipped_file" "$warn_file"' EXIT

# --- generate the config -----------------------------------------------------
{
  printf '{\n  "logo": { "type": "none" },\n  "display": { "separator": "" },\n  "modules": [\n'
  first=1
  # `--list-modules` lines look like:  "15) CPU           : Print CPU name, ..."
  while IFS= read -r line; do
    name="$(sed -E 's/^[0-9]+\)[[:space:]]*//; s/[[:space:]]*:.*$//' <<<"$line")"
    [[ -n "$name" ]] || continue
    type="$(tr '[:upper:]' '[:lower:]' <<<"$name" | tr -cd '[:alnum:]')"

    help="$(fastfetch --help "${type}-format" 2>&1 || true)"
    if grep -q "doesn't support" <<<"$help"; then
      printf '%s (no output formatting)\n' "$name" >>"$skipped_file"; continue
    fi
    vars="$(grep -oE '\{[a-z0-9-]+\}' <<<"$help" | awk '!seen[$0]++')"
    if [[ -z "$vars" ]]; then
      printf '%s (no format variables)\n' "$name" >>"$skipped_file"; continue
    fi

    fmt=""
    while IFS= read -r v; do
      vn="${v#\{}"; vn="${vn%\}}"
      fmt+="\\n    ${vn} = ${v}"
    done <<<"$vars"

    [[ $first -eq 1 ]] || printf ',\n'
    first=0
    printf '    { "type": "%s", "key": "### %s", "format": "%s" }' "$type" "$name" "$fmt"
  done < <(fastfetch --list-modules 2>/dev/null)
  printf '\n  ]\n}\n'
} >"$cfg"

# --- render (stdout = data only; stderr probe-noise kept aside) ---------------
render() {
  fastfetch --config "$cfg" 2>"$warn_file"
  printf '\n=== skipped modules (no per-variable output) ===\n'
  sort "$skipped_file"
  if [[ -s "$warn_file" ]]; then
    printf '\n=== probe warnings (stderr, informational) ===\n'
    cat "$warn_file"
  fi
}

if [[ -n "$outfile" ]]; then
  render >"$outfile"
  echo "Wrote full dump to: $outfile"
else
  render
fi
