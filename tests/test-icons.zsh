#!/usr/bin/env zsh
#
# Icon set integrity tests.
# Validates that all three icon sets (nerd, emoji, none) define every expected
# variable, that nerd/emoji values are non-empty, and that nerd.zsh stores
# glyphs as $'\UXXXX' escape sequences rather than raw bytes.
# Run: zsh tests/test-icons.zsh
#

SHUI_DIR="${0:A:h}/.."
source "${0:A:h}/_harness.zsh"

_t_title "test-icons"

_ICON_VARS=(
  SHUI_ICON_SUCCESS SHUI_ICON_ERROR SHUI_ICON_WARNING SHUI_ICON_INFO
  SHUI_ICON_BULLET SHUI_ICON_ARROW SHUI_ICON_CHECK SHUI_ICON_CROSS
  SHUI_ICON_CHECKMARK SHUI_ICON_QUESTION SHUI_ICON_CHECK_ALT SHUI_ICON_CROSS_ALT
  SHUI_ICON_ARROW_RIGHT SHUI_ICON_ARROW_LEFT SHUI_ICON_ARROW_UP SHUI_ICON_ARROW_DOWN
  SHUI_ICON_DOWNLOAD SHUI_ICON_UPLOAD SHUI_ICON_DELETE SHUI_ICON_EDIT
  SHUI_ICON_SEARCH SHUI_ICON_SETTINGS SHUI_ICON_REFRESH SHUI_ICON_LOCK SHUI_ICON_UNLOCK
  SHUI_ICON_TOOLS SHUI_ICON_COMPUTER SHUI_ICON_PLUG SHUI_ICON_INSTALL SHUI_ICON_BOLT
  SHUI_ICON_ROCKET SHUI_ICON_CLOCK SHUI_ICON_FIRE SHUI_ICON_STAR SHUI_ICON_HEART
  SHUI_ICON_THUMBS_UP
  SHUI_ICON_INFO_BRACKET SHUI_ICON_WARN_BRACKET SHUI_ICON_USER_BRACKET SHUI_ICON_INPUT_BRACKET
  SHUI_ICON_STARTER SHUI_ICON_PROMPT SHUI_ICON_PALETTE SHUI_ICON_GLOBE SHUI_ICON_TABLE
  SHUI_ICON_FORWARD SHUI_ICON_CHART SHUI_ICON_BUG SHUI_ICON_LOADING
  SHUI_ICON_CIRCLE SHUI_ICON_CIRCLE_EMPTY SHUI_ICON_SQUARE SHUI_ICON_SQUARE_EMPTY
  SHUI_ICON_TRIANGLE SHUI_ICON_DIAMOND
)

# ---------------------------------------------------------------------------
# 1. nerd icon set — all variables defined and non-empty
# ---------------------------------------------------------------------------
_t_section "nerd — variables defined and non-empty"

(
  source "${SHUI_DIR}/src/icons/nerd.zsh"
  for _var in "${_ICON_VARS[@]}"; do
    assert_not_empty "$_var is non-empty" "${(P)_var}"
  done
  _t_results
) || exit 1

# ---------------------------------------------------------------------------
# 2. nerd icon set — source uses $'\UXXXX' escapes, not raw PUA bytes
#    Raw Nerd Font glyphs (U+E000–U+F8FF, U+100000+) in source are fragile:
#    editors and clipboard tools silently strip or mangle them.
# ---------------------------------------------------------------------------
_t_section "nerd — source uses \$'\\UXXXX' escape sequences"

_nerd_src="${SHUI_DIR}/src/icons/nerd.zsh"
_nerd_content=$(<"$_nerd_src")

# Count icon assignments that use the $'\UXXXX' escape form
_escaped_count=$(grep -c "SHUI_ICON_.*=\$'" "$_nerd_src")

# Count icon assignments that have a raw non-ASCII byte between the quotes
# (raw PUA glyph stored as UTF-8 = bytes in range 0xEE–0xEF for BMP PUA)
_raw_count=$(grep -cP 'SHUI_ICON_.*="[^\x00-\x7F]' "$_nerd_src" 2>/dev/null || echo 0)

assert_not_empty "nerd.zsh has at least one \$'\\UXXXX' assignment" "$_escaped_count"
assert_eq "nerd.zsh has zero raw non-ASCII glyphs in assignments" "0" "$_raw_count"

# ---------------------------------------------------------------------------
# 3. emoji icon set — all variables defined and non-empty
# ---------------------------------------------------------------------------
_t_section "emoji — variables defined and non-empty"

(
  source "${SHUI_DIR}/src/icons/emoji.zsh"
  for _var in "${_ICON_VARS[@]}"; do
    assert_not_empty "$_var is non-empty" "${(P)_var}"
  done
  _t_results
) || exit 1

# ---------------------------------------------------------------------------
# 4. none icon set — all variables defined (intentionally empty)
# ---------------------------------------------------------------------------
_t_section "none — all variables defined"

(
  source "${SHUI_DIR}/src/icons/none.zsh"
  for _var in "${_ICON_VARS[@]}"; do
    assert_defined "$_var is defined" "$_var"
  done
  _t_results
) || exit 1

# ---------------------------------------------------------------------------
# 5. Parity — all three sets expose the same variable names
# ---------------------------------------------------------------------------
_t_section "parity — all sets define the same variables"

_collect_vars() {
  local file="$1"
  grep -oE 'SHUI_ICON_[A-Z_]+' "$file" | sort -u
}

_nerd_vars=$(_collect_vars "${SHUI_DIR}/src/icons/nerd.zsh")
_emoji_vars=$(_collect_vars "${SHUI_DIR}/src/icons/emoji.zsh")
_none_vars=$(_collect_vars "${SHUI_DIR}/src/icons/none.zsh")

assert_eq "nerd and emoji define the same variables" "$_emoji_vars" "$_nerd_vars"
assert_eq "nerd and none define the same variables"  "$_none_vars"  "$_nerd_vars"

# ---------------------------------------------------------------------------
# Results
# ---------------------------------------------------------------------------
_t_results || exit 1
