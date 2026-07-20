#!/usr/bin/env zsh
#
# fence tests — the labelled rule: ── label ─────────────────
#
# Guards two properties that are easy to break and invisible in review:
#   A. every render is exactly $_SHUI_TERMINAL_WIDTH visible columns, whatever
#      the label length — the rule must absorb the label, not overflow past it
#   B. --color= tints the LABEL only; the rule stays muted
#
# Run: zsh tests/test-fence.zsh
#

SHUI_DIR="${0:A:h}/.."
source "${0:A:h}/_harness.zsh"

export SHUI_ICONS=none
source "${SHUI_DIR}/shui.zsh"

_t_title "test-fence"

# Character count with ANSI stripped. NOT byte count: the rule uses U+2500 (3
# bytes each), so a byte-based length reads ~3x and hides real overflow.
_visible() {
  setopt local_options EXTENDED_GLOB
  local s="${1//(#b)$'\e'\[[0-9;]##m/}"
  print -r -- "${#s}"
}

# ---------------------------------------------------------------------------
_t_section "width is exact, whatever the label"
# ---------------------------------------------------------------------------

for lbl in "keys" "personal" "a" "a-very-long-category-name-here"; do
  assert_eq "fence '$lbl' fills the terminal exactly" \
    "$_SHUI_TERMINAL_WIDTH" "$(_visible "$(shui fence "$lbl")")"
done

assert_eq "bare fence fills the terminal exactly" \
  "$_SHUI_TERMINAL_WIDTH" "$(_visible "$(shui fence)")"

# A label longer than the terminal cannot be absorbed by the rule — truncating it
# would lose meaning, so the trailing rule clamps to 2 rather than going negative.
# The contract is "never a negative-width rule", not "never exceeds the terminal".
_long=$(printf 'x%.0s' {1..200})
assert_eq "over-long label clamps the rule instead of going negative" \
  "$(( 2 + 1 + 200 + 1 + 2 ))" \
  "$(_visible "$(shui fence "$_long")")"

# ---------------------------------------------------------------------------
_t_section "shape"
# ---------------------------------------------------------------------------

assert_contains "labelled fence contains the label" \
  "keys" "$(shui fence "keys")"
assert_contains "labelled fence opens with a rule segment" \
  "──" "$(shui fence "keys")"

# ---------------------------------------------------------------------------
_t_section "--color tints the label, not the rule"
# ---------------------------------------------------------------------------

assert_contains "a --color=error fence carries the error colour" \
  "$SHUI_COLOR_ERROR" "$(shui fence "keys" --color=error)"
assert_not_contains "an uncoloured fence carries no error colour" \
  "$SHUI_COLOR_ERROR" "$(shui fence "keys")"
assert_contains "a coloured fence still emits the muted rule colour" \
  "$SHUI_COLOR_MUTED" "$(shui fence "keys" --color=error)"

# Colouring must not change the geometry.
assert_eq "colour does not alter width" \
  "$(_visible "$(shui fence "keys")")" \
  "$(_visible "$(shui fence "keys" --color=error)")"

# ---------------------------------------------------------------------------
_t_section "--char"
# ---------------------------------------------------------------------------

assert_contains "fence honours --char" \
  "==" "$(shui fence "keys" --char== --color=info)"

_t_results
