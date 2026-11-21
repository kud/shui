#!/usr/bin/env zsh
#
# Sync shui's semantic colour tokens from @kud/glyphs — the source of truth for
# the terminal colour vocabulary, as it already is for glyphs. No node, no
# runtime dependency: fetch @kud/glyphs' plain zsh/colors.zsh at a pinned tag
# and prefix its COLOR_* / STATE_* names into shui's namespace, writing
# src/tokens/glyphs-colors.zsh, which shui sources directly at load time.
#
#   COLOR_ACCENT_ANSI256=208   →  SHUI_COLOR_ACCENT_ANSI256=208
#   STATE_RUNNING_COLOR=ACCENT →  SHUI_STATE_RUNNING_COLOR=ACCENT
#
# The prefix is added, not swapped (upstream's own `s/^(COLOR|STATE)_/P_&/`), so
# a state's COLOR value names its rendered token directly: SHUI_COLOR_${value}.
#
# Run this when bumping GLYPHS_VERSION below; commit the regenerated file. CI
# re-runs it at the pinned version and fails on any diff.
#
#   zsh scripts/sync-colors.zsh

set -euo pipefail

GLYPHS_VERSION=v0.5.0
GLYPHS_RAW="https://raw.githubusercontent.com/kud/glyphs/${GLYPHS_VERSION}/zsh"
OUT="${0:A:h}/../src/tokens/glyphs-colors.zsh"

{
  print -r -- "#!/usr/bin/env zsh"
  print -r -- "#"
  print -r -- "# Semantic colour tokens and state vocabulary."
  print -r -- "# GENERATED from @kud/glyphs ${GLYPHS_VERSION} by scripts/sync-colors.zsh — do not edit."
  print -r -- "# Change the token upstream in @kud/glyphs, bump GLYPHS_VERSION, and re-run the sync."
  print -r -- "#"
  print -r -- "# SHUI_COLOR_<TOKEN>_{ANSI16,ANSI256,HEX}: ANSI16 is the contract floor (palette"
  print -r -- "# index 0-15), ANSI256 the 256-colour rendering, HEX an optional truecolour layer."
  print -r -- "# Themes derive the rendered SHUI_COLOR_<TOKEN> escapes from these numbers."
  print -r -- "# SHUI_STATE_<STATE>_{GLYPH,COLOR,SPINNER}: GLYPH names a SHUI_ICON_*, COLOR a token."
  print -r -- "#"
  print -r --
  curl -fsSL "${GLYPHS_RAW}/colors.zsh" | grep -E '^(COLOR|STATE)_' | sed -E 's/^(COLOR|STATE)_/SHUI_&/'
} >| "${OUT}.tmp"

# Never leave a truncated file behind: an empty fetch fails the grep above
# (pipefail), and a file with no colour tokens is refused here.
grep -q '^SHUI_COLOR_ACCENT_ANSI16=' "${OUT}.tmp" || { rm -f "${OUT}.tmp"; print -u2 "sync-colors: no tokens fetched"; exit 1; }
mv "${OUT}.tmp" "$OUT"

print -r -- "Synced colour tokens from @kud/glyphs ${GLYPHS_VERSION}"
