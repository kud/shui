#!/usr/bin/env zsh
#
# Tests for `_shui_visible_len` — the column measurement every padded component
# depends on: table, box, row, layout.
#
# It had no coverage at all until now, which is how it shipped counting BYTES.
# Every non-ASCII cell in every table was padded short by bytes-minus-characters
# and the borders walked off the grid; the padding maths in the callers was
# right the whole time, so nothing in a code read pointed at the cause.
#
# The tests that matter are the WIDTH ones — a value whose measured length is
# wrong is a component that renders crooked forever after.
#
# Run: zsh tests/test-visible-len.zsh
#

SHUI_DIR="${0:A:h}/.."
source "${0:A:h}/_harness.zsh"

export SHUI_ICONS=none
export SHUI_THEME=plain
source "${SHUI_DIR}/shui.zsh"

_t_title "test-visible-len"

# ---------------------------------------------------------------------------
_t_section "syntax"
# ---------------------------------------------------------------------------

zsh -n "${SHUI_DIR}/src/tokens/colors.zsh" 2>/dev/null
assert_exit_ok "zsh -n colors.zsh" $?

# ---------------------------------------------------------------------------
_t_section "ascii"
# ---------------------------------------------------------------------------

assert_eq "empty string"      "0" "$(_shui_visible_len '')"
assert_eq "plain word"        "2" "$(_shui_visible_len 'OK')"
assert_eq "spaces count"      "7" "$(_shui_visible_len 'a b c d')"

# ---------------------------------------------------------------------------
_t_section "multi-byte characters count as characters, not bytes"
#
# Each of these is one column wide and more than one byte long. The em dash is
# the case that surfaced the bug: 3 bytes, so every cell holding one was two
# columns short.
# ---------------------------------------------------------------------------

assert_eq "em dash"           "1" "$(_shui_visible_len '—')"
assert_eq "warning sign"      "1" "$(_shui_visible_len '⚠')"
assert_eq "warning + word"    "7" "$(_shui_visible_len '⚠ stale')"
assert_eq "accented latin"    "4" "$(_shui_visible_len 'café')"
assert_eq "box drawing"       "3" "$(_shui_visible_len '│─│')"
assert_eq "circled info"      "1" "$(_shui_visible_len 'ⓘ')"

# ---------------------------------------------------------------------------
_t_section "double-width characters count as two columns"
#
# Astral-plane emoji occupy two cells in every terminal shui targets, and shui
# ships an emoji icon set — so counting them as one is the same class of bug in
# the opposite direction.
# ---------------------------------------------------------------------------

assert_eq "emoji alone"       "2" "$(_shui_visible_len '🎉')"
assert_eq "emoji plus word"   "8" "$(_shui_visible_len '🎉 party')"

# Nerd Font glyphs live in the private use area and render single-width. They
# must NOT be caught by the double-width rule, or every nerd-icon row over-pads.
assert_eq "nerd PUA glyph"    "1" "$(_shui_visible_len $'\UF00C')"

# ---------------------------------------------------------------------------
_t_section "escapes are not counted"
# ---------------------------------------------------------------------------

assert_eq "sgr bold"          "4" "$(_shui_visible_len $'\e[1mbold\e[0m')"
assert_eq "256-colour"        "3" "$(_shui_visible_len $'\e[38;5;240mdim\e[m')"
assert_eq "erase-line"        "1" "$(_shui_visible_len $'\e[Kx')"

# ---------------------------------------------------------------------------
_t_section "backslashes survive measurement"
#
# The old implementation piped through `echo`, which expands escapes in zsh — so
# a value containing a literal \t was measured after being turned into a tab.
# ---------------------------------------------------------------------------

assert_eq "literal backslash-t" "4" "$(_shui_visible_len 'a\tb')"
assert_eq "literal backslash-n" "4" "$(_shui_visible_len 'a\nb')"

# ---------------------------------------------------------------------------
_t_section "the table stays square"
#
# The end the measurement exists for. Every line of a rendered table must be the
# same width — that is the property the byte count broke, and asserting it here
# means a future rewrite of the measurement cannot quietly break it again.
# ---------------------------------------------------------------------------

_widths_of_table() {
  local out
  out="$(strip_ansi "$(shui table "$@")")"
  local -A seen
  local line
  while IFS= read -r line; do
    [[ -n "$line" ]] || continue
    seen[${#line}]=1
  done <<< "$out"
  print -r -- "${#seen}"
}

assert_eq "ascii table has one width"        "1" "$(_widths_of_table 'A|B' 'x|y')"
assert_eq "em-dash table has one width"      "1" "$(_widths_of_table 'A|B' 'x|—')"
assert_eq "mixed-glyph table has one width"  "1" "$(_widths_of_table 'Variable|Value|State' 'LANG|en_GB.UTF-8|—' 'MODE|⚠ stale|ⓘ')"
assert_eq "accented table has one width"     "1" "$(_widths_of_table 'A|B' 'café|thé')"

_t_results
