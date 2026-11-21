#!/usr/bin/env zsh
#
# Warning always carries its glyph. At 256 colours warning (214) sits a hair
# from the accent (208), so the glyph — not the hue — is what reads as
# "warning": every warning output shows ⚠ (or `!` where the icon set has none),
# and nothing paints warning-coloured text without it.
# Also: headers carry no hue, and badge text follows ink-ui's INK table.
# Run: zsh tests/test-warning.zsh
#

SHUI_DIR="${0:A:h}/.."
source "${0:A:h}/_harness.zsh"

_t_title "test-warning"

# Every shui call that can produce warning-coloured output.
_WARN_CALLS=(
  'shui warning careful'
  'shui warning-simple careful'
  'shui banner warning careful'
  'shui text warning careful'
  'shui text --color=warning careful'
  'shui typewriter --delay=0 --color=warning careful'
  'shui badge warning careful'
  'shui pill warning careful'
  'shui fence careful --color=warning'
  'shui divider --width=10 --color=warning'
  'shui row warning differs NAME detail'
)

_warn_run() {  # _warn_run <icons> <theme> <term> <call> → "<glyph>\x1f<output>"
  env FORCE_COLOR=1 SHUI_ICONS=$1 SHUI_THEME=$2 TERM=$3 zsh -fc \
    "source '${SHUI_DIR}/shui.zsh' || exit 1; print -rn -- \"\$SHUI_ICON_WARNING\"\$'\\x1f'; $4" 2>&1
}

_t_section "every warning output carries the glyph"

for _icons in nerd emoji none ascii; do
  for _theme in default minimal plain; do
    _out=$(_warn_run $_icons $_theme xterm-256color 'true')
    _glyph=${_out%%$'\x1f'*}
    assert_not_empty "$_icons/$_theme: warning glyph is never empty" "$_glyph"
    for _call in "${_WARN_CALLS[@]}"; do
      _out=$(_warn_run $_icons $_theme xterm-256color "$_call")
      _body=${_out#*$'\x1f'}
      assert_contains "$_icons/$_theme: ${_call#shui }" "$_glyph" "$_body"
    done
  done
done

_out=$(_warn_run none default xterm 'true')
assert_eq "the none set falls back to '!'" "!" "${_out%%$'\x1f'*}"
_out=$(_warn_run nerd plain xterm 'true')
assert_eq "the plain theme uses '!'" "!" "${_out%%$'\x1f'*}"

_out=$(env LC_ALL=C FORCE_COLOR=1 TERM=xterm-256color zsh -fc \
  "source '${SHUI_DIR}/shui.zsh' && shui text warning careful" 2>&1)
assert_contains "C locale: warning text carries '!'" "!" "$_out"

_t_section "no warning colour without the glyph (source guard)"

# A component that paints SHUI_COLOR_WARNING / SHUI_BG_WARNING must also reach
# the glyph, through SHUI_ICON_WARNING or _shui_warn_text. Catches a new call
# site that forgets it before any output is ever rendered.
for _f in "${SHUI_DIR}"/src/components/*.zsh; do
  grep -qE 'SHUI_(COLOR|BG)_WARNING' "$_f" || continue
  if grep -qE 'SHUI_ICON_WARNING|_shui_warn_text' "$_f"; then
    _t_pass "${_f:t} pairs warning colour with its glyph"
  else
    _t_fail "${_f:t} paints warning colour with no glyph"
  fi
done

_t_section "headers carry no hue"

_hdr() { env FORCE_COLOR=1 SHUI_ICONS=none SHUI_THEME=${_HDR_THEME:-default} TERM=${_HDR_TERM:-xterm-256color} \
  zsh -fc "source '${SHUI_DIR}/shui.zsh'; $1" 2>&1; }
for _HDR_THEME in default minimal; do
  for _HDR_TERM in xterm-256color xterm; do
    for _call in 'shui section Hosts' 'shui subtitle Hosts' 'shui subsection Hosts'; do
      _out=$(_hdr "$_call")
      _tag="$_HDR_THEME/$_HDR_TERM: ${_call#shui }"
      assert_contains     "$_tag is bold" $'\033[1m' "$_out"
      assert_not_contains "$_tag carries no 256-colour hue" $'\033[38;' "$_out"
      assert_not_contains "$_tag carries no 16-colour hue" $'\033[3' "${_out//$'\033[3m'/}"
      assert_not_contains "$_tag carries no bright hue" $'\033[9' "$_out"
    done
  done
done
unset _HDR_THEME _HDR_TERM

_t_section "badge text follows ink-ui's INK table"

_badge() { _hdr "shui badge $1 x"; }
assert_contains "success: black on 79"  $'\033[48;5;79m\033[38;5;0m'   "$(_badge success)"
assert_contains "warning: black on 214" $'\033[48;5;214m\033[38;5;0m'  "$(_badge warning)"
assert_contains "info: black on 117"    $'\033[48;5;117m\033[38;5;0m'  "$(_badge info)"
assert_contains "error: white on 203"   $'\033[48;5;203m\033[38;5;15m' "$(_badge error)"
assert_contains "accent: black on 208"  $'\033[48;5;208m\033[38;5;0m'  "$(_badge accent)"

_t_results
