#!/usr/bin/env zsh
#
# Locale robustness.
# Under a non-UTF-8 locale (LANG/LC_ALL unset is the norm on a bare Linux box)
# zsh rejects every $'\U…' escape with a fatal "character not in range". shui
# used to abort mid-way through the icon files, fail its own token contract and
# never define the `shui` function. It must load anyway, on ASCII icons.
# Run: zsh tests/test-locale.zsh
#

SHUI_DIR="${0:A:h}/.."
source "${0:A:h}/_harness.zsh"

_t_title "test-locale"

# Load shui in a scrubbed environment: only the variables given are set, so the
# locale is whatever they say (no LANG/LC_* means the C locale).
_locale_run() {  # _locale_run <env assignments…> -- <zsh code>
  local -a envs=()
  while [[ $1 != -- ]]; do envs+=("$1"); shift; done; shift
  env -i HOME="$HOME" PATH="$PATH" TERM=dumb "${envs[@]}" \
    zsh -fc "source '${SHUI_DIR}/shui.zsh'; $1" 2>&1
}

_t_section "C locale — shui still loads"

_out=$(_locale_run -- 'whence -w shui')
assert_eq "shui is defined with no LANG/LC_ALL" "shui: function" "$_out"

_out=$(_locale_run LC_ALL=C -- 'whence -w shui')
assert_eq "shui is defined under LC_ALL=C" "shui: function" "$_out"

_out=$(_locale_run LC_ALL=C -- 'shui success done')
assert_not_contains "no 'character not in range' error" "character not in range" "$_out"
assert_contains "success line falls back to an ASCII glyph" "+ done" "$_out"

_out=$(_locale_run LC_ALL=C -- 'print -r -- "$_SHUI_ICONS"')
assert_eq "default set falls back to ascii" "ascii" "$_out"

_t_section "C locale — an explicit icon set"

_out=$(_locale_run LC_ALL=C SHUI_ICONS=emoji -- 'print -r -- "$_SHUI_ICONS"')
assert_contains "explicit emoji is replaced by ascii" "ascii" "$_out"
assert_contains "and the user is told why" "locale is not UTF-8" "$_out"

_out=$(_locale_run LC_ALL=C SHUI_ICONS=none -- 'print -r -- "$_SHUI_ICONS"')
assert_eq "none is locale-safe and honoured silently" "none" "$_out"

_t_section "ascii set — 7-bit only, full parity"

_nonascii=$(LC_ALL=C grep -v '^#' "${SHUI_DIR}/src/icons/ascii.zsh" | LC_ALL=C grep -c '[^ -~]' || true)
assert_eq "ascii.zsh has no byte above 0x7F outside comments" "0" "${_nonascii:-0}"

(
  source "${SHUI_DIR}/src/icons/ascii.zsh"
  for _var in $(grep -oE '^SHUI_ICON_[A-Z_]+' "${SHUI_DIR}/src/icons/none.zsh"); do
    assert_defined "$_var is defined" "$_var"
  done
  for _var in SHUI_ICON_SUCCESS SHUI_ICON_ERROR SHUI_ICON_WARNING SHUI_ICON_INFO \
              SHUI_ICON_ARROW SHUI_ICON_CHECK SHUI_ICON_CROSS SHUI_ICON_BULLET; do
    assert_not_empty "$_var is non-empty" "${(P)_var}"
  done
  _t_results
) || exit 1

_t_section "UTF-8 locale — unchanged"

_out=$(_locale_run LC_ALL=C.UTF-8 -- 'print -r -- "$_SHUI_ICONS"')
assert_eq "default set stays nerd" "nerd" "$_out"

_t_results || exit 1
