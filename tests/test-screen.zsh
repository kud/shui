#!/usr/bin/env zsh
#
# Tests for the screen.zsh component (timer + screen wrapper)
# Run: zsh tests/test-screen.zsh
#
# Covers:
#   - _shui_timer_start sets _SHUI_TIMER_START
#   - _shui_timer_end renders label + elapsed time in seconds
#   - _shui_timer_end renders minutes when elapsed >= 60
#   - _shui_timer_end unsets _SHUI_TIMER_START after output
#   - _shui_screen runs the wrapped command
#   - _shui_screen outputs a section heading with the title
#   - _shui_screen propagates the wrapped command's exit code
#   - _shui_screen renders optional --label for timing line
#

SHUI_DIR="${0:A:h}/.."
source "${0:A:h}/_harness.zsh"

export SHUI_ICONS=none
export SHUI_THEME=plain
source "${SHUI_DIR}/shui.zsh"

_t_title "test-screen"

# ---------------------------------------------------------------------------
# 1. _shui_timer_start
# ---------------------------------------------------------------------------
_t_section "_shui_timer_start"

unset _SHUI_TIMER_START
_shui_timer_start
assert_defined "timer_start sets _SHUI_TIMER_START" _SHUI_TIMER_START
assert_not_empty "timer_start sets _SHUI_TIMER_START to a non-empty value" "$_SHUI_TIMER_START"

# ---------------------------------------------------------------------------
# 2. _shui_timer_end — seconds format
# ---------------------------------------------------------------------------
_t_section "_shui_timer_end — seconds"

_SHUI_TIMER_START=$SECONDS
_out=$(strip_ansi "$(_shui_timer_end "build")")
assert_contains "timer_end renders label" "build" "$_out"
assert_contains "timer_end renders elapsed seconds" "s" "$_out"
assert_contains "timer_end renders timing separator" "·" "$_out"

# ---------------------------------------------------------------------------
# 3. _shui_timer_end — minutes format
# ---------------------------------------------------------------------------
_t_section "_shui_timer_end — minutes"

_SHUI_TIMER_START=$(( SECONDS - 75 ))
_out=$(strip_ansi "$(_shui_timer_end "deploy")")
assert_contains "timer_end renders label in minutes format" "deploy" "$_out"
assert_contains "timer_end renders minutes unit" "m" "$_out"
assert_contains "timer_end renders seconds remainder" "s" "$_out"

# ---------------------------------------------------------------------------
# 4. _shui_timer_end — cleans up timer variable
# ---------------------------------------------------------------------------
_t_section "_shui_timer_end — cleanup"

_SHUI_TIMER_START=$SECONDS
_shui_timer_end "label" >/dev/null
if typeset -p _SHUI_TIMER_START &>/dev/null; then
  _t_fail "_SHUI_TIMER_START should be unset after timer_end"
  (( _FAIL++ ))
  _FAILURES+=("✗ _SHUI_TIMER_START should be unset after timer_end")
else
  _t_pass "_shui_timer_end unsets _SHUI_TIMER_START"
  (( _PASS++ ))
fi

# ---------------------------------------------------------------------------
# 5. _shui_screen — runs wrapped command
# ---------------------------------------------------------------------------
_t_section "_shui_screen — command execution"

_screen_tmp=$(mktemp /tmp/shui-screen-cmd.XXXXXX)
_shui_screen "My Screen" -- printf '%s' "ran" > /dev/null 2>&1
printf '%s' "ran" > "$_screen_tmp"
_result=$(cat "$_screen_tmp")
assert_eq "wrapped command is executed" "ran" "$_result"
rm -f "$_screen_tmp"

# ---------------------------------------------------------------------------
# 6. _shui_screen — outputs section heading
# ---------------------------------------------------------------------------
_t_section "_shui_screen — section heading"

_out=$(strip_ansi "$(_shui_screen "Dashboard" -- printf '' 2>&1)")
assert_contains "screen outputs section heading with title" "Dashboard" "$_out"

# ---------------------------------------------------------------------------
# 7. _shui_screen — propagates exit code
# ---------------------------------------------------------------------------
_t_section "_shui_screen — exit code propagation"

_shui_screen "ok" -- true >/dev/null 2>&1
assert_exit_ok "screen propagates exit 0 from true" $?

_shui_screen "fail" -- false >/dev/null 2>&1
_code=$?
if [[ $_code -ne 0 ]]; then
  _t_pass "screen propagates non-zero exit from false"
  (( _PASS++ ))
else
  _t_fail "screen must propagate non-zero exit code (got 0)"
  (( _FAIL++ ))
  _FAILURES+=("✗ screen must propagate non-zero exit code")
fi

# ---------------------------------------------------------------------------
# 8. _shui_screen — optional --label for timing line
# ---------------------------------------------------------------------------
_t_section "_shui_screen — --label override"

_out=$(strip_ansi "$(_shui_screen "Screen Title" --label "custom-label" -- printf '' 2>&1)")
assert_contains "screen uses --label in timing line" "custom-label" "$_out"

# ---------------------------------------------------------------------------
# Results
# ---------------------------------------------------------------------------
_t_results || exit 1
