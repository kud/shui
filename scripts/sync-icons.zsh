#!/usr/bin/env zsh
#
# Sync shui's icon sets from @kud/glyphs — the source of truth for terminal
# glyphs. No node, no runtime dependency: fetch @kud/glyphs' escape-safe ICON_*
# zsh files and text-substitute the prefix into shui's namespace, writing plain
# literal src/icons/*.zsh files that shui sources directly at load time.
#
# Run this when bumping GLYPHS_VERSION below; commit the regenerated files.
#
#   zsh scripts/sync-icons.zsh

set -euo pipefail

GLYPHS_VERSION=v0.3.0
GLYPHS_RAW="https://raw.githubusercontent.com/kud/glyphs/${GLYPHS_VERSION}/zsh"
ICONS="${0:A:h}/../src/icons"

header() {  # header <title> [note]
  print -r -- "#!/usr/bin/env zsh"
  print -r -- "#"
  print -r -- "# $1"
  print -r -- "# GENERATED from @kud/glyphs ${GLYPHS_VERSION} by scripts/sync-icons.zsh — do not edit."
  print -r -- "# Change the glyph upstream in @kud/glyphs, bump GLYPHS_VERSION, and re-run the sync."
  [[ -n ${2:-} ]] && print -r -- "# $2"
  print -r -- "#"
  print -r --
}

# Fetch a variant's ICON_* assignments and re-prefix them into SHUI_ICON_.
# The swap is anchored to the variable name (^ICON_), never the $'\U…' value.
fetch() { curl -fsSL "${GLYPHS_RAW}/$1.zsh" | grep -E '^ICON_' | sed 's/^ICON_/SHUI_ICON_/' }

{ header "nerd icon set — requires a Nerd Font (https://www.nerdfonts.com/)"
  fetch nerd } >| "${ICONS}/nerd.zsh"

{ header "emoji icon set — Unicode emoji, no special font required"
  fetch emoji } >| "${ICONS}/emoji.zsh"

{ header "unicode icon set — standard Unicode symbols, no special font required" \
    "Thin base layer, sourced first; nerd/emoji/none override per set."
  fetch unicode } >| "${ICONS}/unicode.zsh"

# none — every name from the nerd set, emptied (text-only fallback, keeps parity).
{ header "none icon set — no icons (text-only fallback)"
  fetch nerd | sed -E "s/=.*/=''/" } >| "${ICONS}/none.zsh"

print -r -- "Synced icon sets from @kud/glyphs ${GLYPHS_VERSION}"
