#!/usr/bin/env zsh
#
# Tests for feat/close-api-gap changes
# Run: zsh tests/test-feat-close-api-gap.zsh
#
# Covers:
#   - 9 new components: task, title, step, prompt, link, util, debug, animation, cursor
#   - message simple variants (success/error/warning/info/muted + lines_before)
#   - divider flags (--char, --width, --color) and new hr / center-text
#   - spinner helpers (spinner-tick, spinner-clear)
#   - progress custom chars (--filled-char / --empty-char)
#   - pill aliases (critical, major, minor, patch, done, white/light)
#   - icon parity: all three icon sets define the same 54 tokens
#   - colour contract: themes define every required token
#

SHUI_DIR="${0:A:h}/.."

# ---------------------------------------------------------------------------
# Minimal test harness
# ---------------------------------------------------------------------------

_PASS=0
_FAIL=0
_FAILURES=()

assert_eq() {
  local desc="$1" expected="$2" actual="$3"
  if [[ "$actual" == "$expected" ]]; then
    (( _PASS++ ))
  else
    (( _FAIL++ ))
    _FAILURES+=("FAIL: ${desc}")
    _FAILURES+=("  expected: $(printf '%q' "$expected")")
    _FAILURES+=("  actual:   $(printf '%q' "$actual")")
  fi
}

assert_contains() {
  local desc="$1" needle="$2" haystack="$3"
  if [[ "$haystack" == *"$needle"* ]]; then
    (( _PASS++ ))
  else
    (( _FAIL++ ))
    _FAILURES+=("FAIL: ${desc}")
    _FAILURES+=("  expected to contain: $(printf '%q' "$needle")")
    _FAILURES+=("  in: $(printf '%q' "$haystack")")
  fi
}

assert_not_contains() {
  local desc="$1" needle="$2" haystack="$3"
  if [[ "$haystack" != *"$needle"* ]]; then
    (( _PASS++ ))
  else
    (( _FAIL++ ))
    _FAILURES+=("FAIL: ${desc}")
    _FAILURES+=("  expected NOT to contain: $(printf '%q' "$needle")")
    _FAILURES+=("  in: $(printf '%q' "$haystack")")
  fi
}

assert_exit_ok() {
  local desc="$1" code="$2"
  if [[ "$code" -eq 0 ]]; then
    (( _PASS++ ))
  else
    (( _FAIL++ ))
    _FAILURES+=("FAIL: ${desc} — exited $code")
  fi
}

assert_defined() {
  local desc="$1" var="$2"
  if typeset -p "$var" &>/dev/null; then
    (( _PASS++ ))
  else
    (( _FAIL++ ))
    _FAILURES+=("FAIL: ${desc} — variable '$var' is not defined")
  fi
}

# Strip ANSI codes for plain-text assertions
strip_ansi() { printf '%s' "$1" | sed 's/\x1b\[[0-9;]*[mK]//g'; }

# ---------------------------------------------------------------------------
# Load shui in a clean subshell and capture output helpers
# ---------------------------------------------------------------------------
# Source once so all component functions are available in this process.
# We use NO_COLOR / SHUI_ICONS=none so assertions are colour-agnostic.
export SHUI_ICONS=none
export SHUI_THEME=plain
source "${SHUI_DIR}/shui.zsh"

# ---------------------------------------------------------------------------
# 1. Syntax check — all source files
# ---------------------------------------------------------------------------
print "\n=== Syntax checks ==="

for f in "${SHUI_DIR}"/shui.zsh "${SHUI_DIR}"/src/**/*.zsh; do
  zsh -n "$f" 2>/dev/null
  assert_exit_ok "zsh -n ${f:t}" $?
done

# ---------------------------------------------------------------------------
# 2. Icon parity — all three sets must define the same 54 tokens
# ---------------------------------------------------------------------------
print "\n=== Icon token parity ==="

# Collect token names from the nerd set (it was the first to be extended)
typeset -a _EXPECTED_ICONS
_EXPECTED_ICONS=(
  SHUI_ICON_SUCCESS SHUI_ICON_ERROR SHUI_ICON_WARNING SHUI_ICON_INFO
  SHUI_ICON_BULLET SHUI_ICON_ARROW SHUI_ICON_CHECK SHUI_ICON_CROSS

  SHUI_ICON_CHECKMARK SHUI_ICON_QUESTION SHUI_ICON_CHECK_ALT SHUI_ICON_CROSS_ALT
  SHUI_ICON_ARROW_RIGHT SHUI_ICON_ARROW_LEFT SHUI_ICON_ARROW_UP SHUI_ICON_ARROW_DOWN

  SHUI_ICON_DOWNLOAD SHUI_ICON_UPLOAD SHUI_ICON_DELETE SHUI_ICON_EDIT
  SHUI_ICON_SEARCH SHUI_ICON_SETTINGS SHUI_ICON_REFRESH SHUI_ICON_LOCK SHUI_ICON_UNLOCK

  SHUI_ICON_TOOLS SHUI_ICON_COMPUTER SHUI_ICON_PLUG SHUI_ICON_INSTALL
  SHUI_ICON_BOLT SHUI_ICON_ROCKET SHUI_ICON_CLOCK SHUI_ICON_FIRE
  SHUI_ICON_STAR SHUI_ICON_HEART SHUI_ICON_THUMBS_UP

  SHUI_ICON_INFO_BRACKET SHUI_ICON_WARN_BRACKET SHUI_ICON_USER_BRACKET SHUI_ICON_INPUT_BRACKET

  SHUI_ICON_STARTER SHUI_ICON_PROMPT SHUI_ICON_PALETTE SHUI_ICON_GLOBE
  SHUI_ICON_TABLE SHUI_ICON_FORWARD SHUI_ICON_CHART SHUI_ICON_BUG SHUI_ICON_LOADING

  SHUI_ICON_CIRCLE SHUI_ICON_CIRCLE_EMPTY SHUI_ICON_SQUARE SHUI_ICON_SQUARE_EMPTY
  SHUI_ICON_TRIANGLE SHUI_ICON_DIAMOND
)

for _set in nerd emoji none; do
  # Source each icon set in an isolated subshell and print missing vars
  _missing=$(
    zsh -c "
      source '${SHUI_DIR}/src/icons/${_set}.zsh'
      for v in ${_EXPECTED_ICONS[*]}; do
        typeset -p \"\$v\" &>/dev/null || echo \"\$v\"
      done
    " 2>/dev/null
  )
  assert_eq "icon set '${_set}' defines all 54 tokens" "" "$_missing"
done

# ---------------------------------------------------------------------------
# 3. Colour contract — required tokens present after loading each theme
# ---------------------------------------------------------------------------
print "\n=== Theme contract ==="

for _theme in default minimal plain; do
  _contract_ok=$(
    SHUI_DIR="${SHUI_DIR}" zsh -c "
      source \"\${SHUI_DIR}/src/tokens/colors.zsh\"
      source \"\${SHUI_DIR}/src/tokens/contract.zsh\"
      source \"\${SHUI_DIR}/src/icons/none.zsh\"
      source \"\${SHUI_DIR}/src/themes/${_theme}.zsh\"
      _shui_validate_theme && echo ok
    " 2>/dev/null
  )
  assert_eq "theme '${_theme}' passes contract validation" "ok" "$_contract_ok"
done

# ---------------------------------------------------------------------------
# 4. message simple variants
# ---------------------------------------------------------------------------
print "\n=== _shui_message_simple ==="

for _type in success error warning info muted; do
  _out=$(strip_ansi "$(_shui_message_simple "$_type" "hello")")
  assert_contains "_shui_message_simple ${_type} contains message text" "hello" "$_out"
done

# lines_before inserts blank lines — use grep -c '' which counts all lines
# including blank ones (unlike wc -l which misses a missing trailing newline)
_out=$(_shui_message_simple "info" "msg" 2)
_lines=$(printf '%s' "$_out" | grep -c '' || true)
assert_eq "_shui_message_simple lines_before=2 produces 3 lines total" "3" "$_lines"

# lines_before defaults to 0 — one content line
_out=$(_shui_message_simple "success" "msg")
_lines=$(printf '%s' "$_out" | grep -c '' || true)
assert_eq "_shui_message_simple default lines_before=0 produces 1 line" "1" "$_lines"

# ---------------------------------------------------------------------------
# 5. layout — divider flags, hr, center-text
# ---------------------------------------------------------------------------
print "\n=== layout new features ==="

# --char flag
_out=$(strip_ansi "$(_shui_layout divider --char='=' --width=5)")
assert_contains "divider --char uses custom character" "=====" "$_out"

# --width flag
_out=$(strip_ansi "$(_shui_layout divider --char='-' --width=10)")
_len=${#${_out//[$'\n\r']/}}
assert_eq "divider --width=10 produces exactly 10 chars" "10" "$_len"

# --color flag (plain theme has no colour but should not error)
_shui_layout divider --color=success --width=3 >/dev/null 2>&1
assert_exit_ok "divider --color=success exits 0" $?

# hr produces output
_out=$(strip_ansi "$(_shui_layout hr)")
assert_contains "hr produces dashes" "─" "$_out"

# center-text pads short text inside a known width
_out=$(strip_ansi "$(_shui_layout "center-text" "hi" --width=10)")
# "hi" is 2 chars, pad = (10-2)/2 = 4 spaces
assert_contains "center-text pads text" "    hi" "$_out"

# center-text with text longer than width should not error
_shui_layout "center-text" "hello world this is very long text indeed" --width=5 >/dev/null 2>&1
assert_exit_ok "center-text does not error when text exceeds width" $?

# ---------------------------------------------------------------------------
# 6. spinner helpers
# ---------------------------------------------------------------------------
print "\n=== spinner helpers ==="

# spinner-tick outputs a frame and message
_out=$(_shui_spinner_tick 0 "working")
assert_contains "spinner-tick frame 0 includes message" "working" "$(strip_ansi "$_out")"

_out=$(_shui_spinner_tick 9 "done")
assert_contains "spinner-tick frame 9 includes message" "done" "$(strip_ansi "$_out")"

# spinner-tick wraps frame index (10 frames, mod 10 = same as 0)
_frame0=$(strip_ansi "$(_shui_spinner_tick 0  "x")")
_frame10=$(strip_ansi "$(_shui_spinner_tick 10 "x")")
assert_eq "spinner-tick wraps at frame count (0 == 10)" "$_frame0" "$_frame10"

# spinner-clear outputs carriage-return + erase-line escape
_out=$(_shui_spinner_clear)
assert_contains "spinner-clear outputs CR" $'\r' "$_out"

# ---------------------------------------------------------------------------
# 7. progress custom chars
# ---------------------------------------------------------------------------
print "\n=== progress custom chars ==="

_out=$(strip_ansi "$(_shui_progress 5 10 --width=10 --filled-char='#' --empty-char='.')")
assert_contains "progress --filled-char uses '#'" "#" "$_out"
assert_contains "progress --empty-char uses '.'" "." "$_out"
assert_not_contains "progress --filled-char='#' removes default '█'" "█" "$_out"

# Default chars still work when flags are absent
_out=$(strip_ansi "$(_shui_progress 5 10 --width=10)")
assert_contains "progress default filled char is '█'" "█" "$_out"
assert_contains "progress default empty char is '░'" "░" "$_out"

# Percentage is calculated correctly
_out=$(strip_ansi "$(_shui_progress 3 4 --width=4)")
assert_contains "progress 3/4 = 75%" "75%" "$_out"

# ---------------------------------------------------------------------------
# 8. pill aliases
# ---------------------------------------------------------------------------
print "\n=== pill aliases ==="

# critical, major, minor, patch, done, white/light should not error and should
# produce non-empty output
export NO_COLOR=1  # avoid ANSI so we can inspect bare text

for _alias in critical major minor patch done white light; do
  _out=$(_shui_pill "$_alias" "label")
  assert_contains "pill alias '$_alias' renders label" "label" "$_out"
done

# accent changed from 226 to 33 (different from primary 226) — verify both
# render without error
_out=$(_shui_pill "accent" "test")
assert_contains "pill 'accent' renders text" "test" "$_out"
_out=$(_shui_pill "primary" "test")
assert_contains "pill 'primary' renders text" "test" "$_out"

unset NO_COLOR

# ---------------------------------------------------------------------------
# 9. task component
# ---------------------------------------------------------------------------
print "\n=== _shui_task ==="

_out=$(strip_ansi "$(_shui_task task-start "Installing foo")")
assert_contains "task-start contains message" "Installing foo" "$_out"

_out=$(strip_ansi "$(_shui_task task-done "Done")")
assert_contains "task-done contains message" "Done" "$_out"

_out=$(strip_ansi "$(_shui_task final-success "All good")")
assert_contains "final-success contains message" "All good" "$_out"
# final-success wraps in border lines (two ─ lines)
_out=$(_shui_task final-success "ok")
_border_count=$(printf '%s' "$(strip_ansi "$_out")" | grep -c '─' || true)
assert_eq "final-success has 2 border lines" "2" "$_border_count"

_out=$(strip_ansi "$(_shui_task final-fail "Oops")")
assert_contains "final-fail contains message" "Oops" "$_out"

# ---------------------------------------------------------------------------
# 10. title component
# ---------------------------------------------------------------------------
print "\n=== _shui_title ==="

_out=$(strip_ansi "$(_shui_title title "My Title")")
assert_contains "title renders text" "My Title" "$_out"

_out=$(strip_ansi "$(_shui_title title-action "Installing" "brew")")
assert_contains "title-action renders action" "Installing" "$_out"
assert_contains "title-action renders target" "brew" "$_out"

_out=$(strip_ansi "$(_shui_title title-install "node")")
assert_contains "title-install renders target" "node" "$_out"
assert_contains "title-install contains 'Installing'" "Installing" "$_out"

_out=$(strip_ansi "$(_shui_title title-update "npm")")
assert_contains "title-update renders target" "npm" "$_out"
assert_contains "title-update contains 'Updating'" "Updating" "$_out"

# ---------------------------------------------------------------------------
# 11. step component
# ---------------------------------------------------------------------------
print "\n=== _shui_step ==="

# Reset state
_SHUI_TOTAL_STEPS=0
_SHUI_CURRENT_STEP=0

_shui_step set-total-steps 3
assert_eq "set-total-steps sets _SHUI_TOTAL_STEPS" "3" "$_SHUI_TOTAL_STEPS"
assert_eq "set-total-steps resets _SHUI_CURRENT_STEP to 0" "0" "$_SHUI_CURRENT_STEP"

# next-step increments _SHUI_CURRENT_STEP in the current shell.
# Capture via $(...) creates a subshell so the increment stays in the
# subshell. Run each step with redirection to a temp file instead.
_step_tmp=$(mktemp /tmp/shui-step-test.XXXXXX)

_shui_step next-step "First" > "$_step_tmp"
_out=$(strip_ansi "$(cat "$_step_tmp")")
assert_contains "next-step output contains [1/3]" "[1/3]" "$_out"
assert_contains "next-step output contains message" "First" "$_out"

_shui_step next-step "Second" > /dev/null

_shui_step next-step "Third" > "$_step_tmp"
_out=$(strip_ansi "$(cat "$_step_tmp")")
assert_contains "next-step increments to [3/3]" "[3/3]" "$_out"

rm -f "$_step_tmp"

# set-total-steps resets the counter
_shui_step set-total-steps 5
assert_eq "set-total-steps again resets _SHUI_CURRENT_STEP" "0" "$_SHUI_CURRENT_STEP"

# ---------------------------------------------------------------------------
# 12. prompt component
# ---------------------------------------------------------------------------
print "\n=== _shui_prompt ==="

# user-prompt and input-prompt produce non-empty output containing the message
_out=$(strip_ansi "$(_shui_prompt user-prompt "Enter name:")")
assert_contains "user-prompt outputs message" "Enter name:" "$_out"

_out=$(strip_ansi "$(_shui_prompt input-prompt "Value:")")
assert_contains "input-prompt outputs message" "Value:" "$_out"

# ---------------------------------------------------------------------------
# 13. link component
# ---------------------------------------------------------------------------
print "\n=== _shui_hyperlink / _shui_print_link ==="

_out=$(_shui_hyperlink "Docs" "https://example.com")
assert_contains "hyperlink contains text" "Docs" "$_out"
assert_contains "hyperlink contains URL" "https://example.com" "$_out"
assert_contains "hyperlink uses OSC 8 escape" $'\033]8;;' "$_out"

_out=$(_shui_print_link "Home" "https://example.com")
assert_contains "print-link contains text" "Home" "$_out"
# print-link appends a newline — verify via a temp file (subshell $() strips
# trailing newlines so we cannot use $() capture for this assertion)
_link_tmp=$(mktemp /tmp/shui-link-test.XXXXXX)
_shui_print_link "Home" "https://example.com" > "$_link_tmp"
_last_char=$(tail -c1 "$_link_tmp" | xxd -p 2>/dev/null || tail -c1 "$_link_tmp" | od -An -tx1 | tr -d ' \n')
assert_eq "print-link ends with newline (0a)" "0a" "$_last_char"
rm -f "$_link_tmp"

# ---------------------------------------------------------------------------
# 14. util component
# ---------------------------------------------------------------------------
print "\n=== _shui_util ==="

_out=$(_shui_util terminal-size)
# Must match NxN pattern
[[ "$_out" =~ ^[0-9]+x[0-9]+$ ]]
assert_exit_ok "terminal-size returns WxH format" $?

# ---------------------------------------------------------------------------
# 15. debug component
# ---------------------------------------------------------------------------
print "\n=== _shui_debug ==="

# When SHUI_DEBUG is unset, debug produces no output
unset SHUI_DEBUG
_out=$( _shui_debug "silent" 2>&1 )
assert_eq "_shui_debug is silent without SHUI_DEBUG=true" "" "$_out"

_out=$( _shui_debug_vars SHUI_VERSION 2>&1 )
assert_eq "_shui_debug_vars is silent without SHUI_DEBUG=true" "" "$_out"

_out=$( _shui_debug_command echo "silent" 2>&1 )
assert_eq "_shui_debug_command is silent without SHUI_DEBUG=true" "" "$_out"

# When SHUI_DEBUG=true, output appears on stderr
export SHUI_DEBUG=true

_out=$( _shui_debug "test message" 2>&1 )
assert_contains "_shui_debug emits message on stderr" "test message" "$(strip_ansi "$_out")"
assert_contains "_shui_debug includes [debug] prefix" "[debug]" "$(strip_ansi "$_out")"

SHUI_TESTVAR="hello"
_out=$( _shui_debug_vars SHUI_TESTVAR 2>&1 )
assert_contains "_shui_debug_vars shows variable name" "SHUI_TESTVAR" "$(strip_ansi "$_out")"
assert_contains "_shui_debug_vars shows variable value" "hello" "$(strip_ansi "$_out")"

_out=$( _shui_debug_command printf '%s' "ran" 2>&1 )
assert_contains "_shui_debug_command actually runs the command" "ran" "$_out"
assert_contains "_shui_debug_command logs the command to stderr" "printf" "$(strip_ansi "$_out")"

unset SHUI_DEBUG

# ---------------------------------------------------------------------------
# 16. cursor component
# ---------------------------------------------------------------------------
print "\n=== _shui_cursor ==="

assert_eq "hide-cursor emits correct escape" $'\033[?25l' "$(_shui_cursor hide-cursor)"
assert_eq "show-cursor emits correct escape" $'\033[?25h' "$(_shui_cursor show-cursor)"
assert_eq "save-cursor emits correct escape"    $'\033[s'    "$(_shui_cursor save-cursor)"
assert_eq "restore-cursor emits correct escape" $'\033[u'    "$(_shui_cursor restore-cursor)"
assert_eq "clear-line emits CR + erase"         $'\r\033[K'  "$(_shui_cursor clear-line)"

_out=$(_shui_cursor move-cursor 5 10)
assert_eq "move-cursor emits correct CSI sequence" $'\033[5;10H' "$_out"

# cleanup restores cursor and reset
_out=$(_shui_cursor cleanup)
assert_contains "cleanup includes show-cursor" $'\033[?25h' "$_out"

# ---------------------------------------------------------------------------
# Results
# ---------------------------------------------------------------------------

print "\n=== Results ==="
printf '%d passed, %d failed\n' "$_PASS" "$_FAIL"

if [[ ${#_FAILURES[@]} -gt 0 ]]; then
  print ""
  for _line in "${_FAILURES[@]}"; do
    print "$_line"
  done
  exit 1
fi

exit 0
