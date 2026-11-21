#!/usr/bin/env zsh
#
# Semantic colour tokens from @kud/glyphs and the deprecated PRIMARY alias.
# Run: zsh tests/test-tokens.zsh
#

SHUI_DIR="${0:A:h}/.."
source "${0:A:h}/_harness.zsh"

_t_title "test-tokens"

# Load shui in a fresh zsh with the given environment and print the result of
# the code, so each case gets its own colour depth and theme.
_tok_run() {  # _tok_run <env assignments…> -- <zsh code>
  local -a envs=()
  while [[ $1 != -- ]]; do envs+=("$1"); shift; done; shift
  env "${envs[@]}" zsh -fc "source '${SHUI_DIR}/shui.zsh' || exit 1; $1" 2>&1
}

_t_section "generated file"

_gen="${SHUI_DIR}/src/tokens/glyphs-colors.zsh"
assert_contains "generated from a pinned glyphs version" "GENERATED from @kud/glyphs v" "$(head -5 "$_gen")"
_stray=$(grep -vE '^(#|$|SHUI_(COLOR|STATE)_[A-Z0-9_]+=)' "$_gen" | wc -l | tr -d ' ')
assert_eq "only SHUI_COLOR_* / SHUI_STATE_* assignments" "0" "$_stray"
_nonascii=$(LC_ALL=C grep -v '^#' "$_gen" | LC_ALL=C grep -c '[^ -~]' || true)
assert_eq "assignments are 7-bit (locale-safe)" "0" "${_nonascii:-0}"
# Sourced in this shell, not a subshell: a subshell would swallow its failures.
source "$_gen"
for _t in ACCENT SUCCESS WARNING ERROR INFO GROUP MUTED SECONDARY DIM TRACK LINK ADDED REMOVED; do
  assert_defined "SHUI_COLOR_${_t}_ANSI16"  "SHUI_COLOR_${_t}_ANSI16"
  assert_defined "SHUI_COLOR_${_t}_ANSI256" "SHUI_COLOR_${_t}_ANSI256"
done
for _s in SUCCESS ERROR WARNING INFO PENDING RUNNING; do
  _n="SHUI_STATE_${_s}_COLOR"
  assert_defined "state $_s names a colour token" "SHUI_COLOR_${(P)_n}_ANSI16"
done

_t_section "ANSI16 → SGR"

source "${SHUI_DIR}/src/tokens/colors.zsh"
assert_eq "index 3 → 33"        "33"  "$(_shui_ansi16_sgr 3)"
assert_eq "index 8 → 90"        "90"  "$(_shui_ansi16_sgr 8)"
assert_eq "index 15 → 97"       "97"  "$(_shui_ansi16_sgr 15)"
assert_eq "index 1 bg → 41"     "41"  "$(_shui_ansi16_sgr 1 bg)"
assert_eq "index 8 bg → 100"    "100" "$(_shui_ansi16_sgr 8 bg)"

_t_section "default theme derives from the tokens"

_out=$(_tok_run FORCE_COLOR=1 TERM=xterm-256color -- 'print -rn -- "$SHUI_COLOR_ACCENT"')
assert_eq "256-colour accent is the ANSI256 cell" $'\033[38;5;208m' "$_out"
_out=$(_tok_run FORCE_COLOR=1 TERM=xterm-256color -- 'print -rn -- "$SHUI_BG_ACCENT"')
assert_eq "256-colour accent background" $'\033[48;5;208m' "$_out"
_out=$(_tok_run FORCE_COLOR=1 TERM=xterm -- 'print -rn -- "$SHUI_COLOR_ACCENT"')
assert_eq "16-colour accent is the ANSI16 floor" $'\033[33m' "$_out"
_out=$(_tok_run FORCE_COLOR=1 TERM=xterm -- 'print -rn -- "$SHUI_COLOR_LINK"')
assert_eq "16-colour link (index 4) is blue" $'\033[34m' "$_out"
_out=$(_tok_run FORCE_COLOR=1 SHUI_THEME=minimal TERM=xterm-256color -- 'print -rn -- "$SHUI_COLOR_MUTED"')
assert_eq "minimal stays on the floor at any depth" $'\033[90m' "$_out"

_t_section "PRIMARY is a deprecated alias of ACCENT"

for _theme in default minimal plain; do
  for _term in xterm-256color xterm; do
    _out=$(_tok_run FORCE_COLOR=1 SHUI_THEME=$_theme TERM=$_term -- \
      '[[ $SHUI_COLOR_PRIMARY == "$SHUI_COLOR_ACCENT" && $SHUI_BG_PRIMARY == "$SHUI_BG_ACCENT" ]] && print ok')
    assert_eq "$_theme / $_term: PRIMARY resolves to ACCENT" "ok" "$_out"
  done
done

_out=$(_tok_run FORCE_COLOR=1 TERM=xterm-256color -- 'shui text --color=primary hi')
assert_contains "--color=primary still renders the accent" $'\033[38;5;208mhi' "$_out"
_out=$(_tok_run FORCE_COLOR=1 TERM=xterm-256color -- 'shui badge primary P')
assert_contains "badge primary still renders the accent background" $'\033[48;5;208m' "$_out"

_out=$(_tok_run LC_ALL=C -- '[[ $SHUI_COLOR_PRIMARY == "$SHUI_COLOR_ACCENT" ]] && print ok')
assert_eq "alias resolves under the C locale" "ok" "$_out"

_t_section "a theme written before the rename"

# Such a theme sets PRIMARY (the accent) and a separate ACCENT, and none of the
# tokens added since. It must still load, with PRIMARY taken as the accent.
_legacy=$(mktemp -d)
cp -R "${SHUI_DIR}/shui.zsh" "${SHUI_DIR}/src" "$_legacy/"
cat > "$_legacy/src/themes/legacy.zsh" <<'EOF'
source "${SHUI_DIR}/src/themes/default.zsh"
unset SHUI_COLOR_DIM SHUI_COLOR_TRACK SHUI_COLOR_LINK SHUI_COLOR_ADDED SHUI_COLOR_REMOVED SHUI_BG_ACCENT
SHUI_COLOR_PRIMARY=$(_shui_sgr 35)
SHUI_COLOR_ACCENT=$(_shui_sgr 34)
SHUI_BG_PRIMARY=$(_shui_sgr 45)
EOF
_out=$(env FORCE_COLOR=1 SHUI_THEME=legacy TERM=xterm zsh -fc \
  "source '$_legacy/shui.zsh' || exit 1; print -rn -- \"\$SHUI_COLOR_ACCENT|\$SHUI_BG_ACCENT|\$SHUI_COLOR_PRIMARY\"" 2>&1)
assert_eq "legacy PRIMARY becomes the accent, BG too" $'\033[35m|\033[45m|\033[35m' "$_out"
_out=$(env FORCE_COLOR=1 SHUI_THEME=legacy TERM=xterm zsh -fc \
  "source '$_legacy/shui.zsh' || exit 1; print -rn -- \"\$SHUI_COLOR_LINK\"" 2>&1)
assert_eq "tokens the theme predates come from glyphs" $'\033[34m' "$_out"
[[ -n $_legacy && -d $_legacy/src ]] && rm -rf -- "$_legacy"

_t_results
