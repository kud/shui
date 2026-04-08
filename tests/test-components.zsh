#!/usr/bin/env zsh
#
# Comprehensive component tests — text, badge, pill, message, layout, box,
# table, progress (iTerm), and animation.
# Run: zsh tests/test-components.zsh
#

SHUI_DIR="${0:A:h}/.."

# ---------------------------------------------------------------------------
# Minimal test harness (verbatim from test-feat-close-api-gap.zsh)
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
# Load shui
# ---------------------------------------------------------------------------
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
# 2. _shui_text
# ---------------------------------------------------------------------------
print "\n=== _shui_text ==="

for _style in bold dim italic underline; do
  _out=$(strip_ansi "$(_shui_text "$_style" "hello world")")
  assert_contains "_shui_text ${_style} renders message text" "hello world" "$_out"
done

# text with no --color renders the text
_out=$(strip_ansi "$(_shui_text text "plain text")")
assert_contains "_shui_text text (no --color) renders text" "plain text" "$_out"

# text with each --color= value renders the text and does not error
for _color in success error warning info muted accent primary; do
  _out=$(strip_ansi "$(_shui_text text --color="$_color" "coloured text")")
  assert_contains "_shui_text text --color=${_color} renders text" "coloured text" "$_out"
done

# ---------------------------------------------------------------------------
# 3. _shui_badge
# ---------------------------------------------------------------------------
print "\n=== _shui_badge ==="

# All known types render the label text (with ANSI)
for _type in success error warning info primary muted; do
  _out=$(strip_ansi "$(_shui_badge "$_type" "my-label")")
  assert_contains "_shui_badge ${_type} renders label" "my-label" "$_out"
done

# Unknown type falls back without error
_shui_badge "unknown-type" "fallback-label" >/dev/null 2>&1
assert_exit_ok "_shui_badge unknown type exits 0" $?
_out=$(strip_ansi "$(_shui_badge "unknown-type" "fallback-label")")
assert_contains "_shui_badge unknown type renders label" "fallback-label" "$_out"

# NO_COLOR=1 renders [label] with no ANSI escape sequences
export NO_COLOR=1
_out=$(_shui_badge "success" "no-color-label")
assert_eq "_shui_badge NO_COLOR renders [label]" "[no-color-label]" "$_out"
# Confirm there are no ESC bytes in the output
assert_not_contains "_shui_badge NO_COLOR has no ANSI escapes" $'\033' "$_out"
unset NO_COLOR

# ---------------------------------------------------------------------------
# 4. _shui_pill / _shui_pill_custom
# ---------------------------------------------------------------------------
print "\n=== _shui_pill_custom ==="

# _shui_pill_custom renders the text
_out=$(strip_ansi "$(_shui_pill_custom 15 46 "custom-text")")
assert_contains "_shui_pill_custom renders the text" "custom-text" "$_out"

# NO_COLOR=1 renders [text]
export NO_COLOR=1
_out=$(_shui_pill_custom 15 46 "nc-text")
assert_eq "_shui_pill_custom NO_COLOR renders [text]" "[nc-text]" "$_out"
assert_not_contains "_shui_pill_custom NO_COLOR has no ANSI escapes" $'\033' "$_out"
unset NO_COLOR

# ---------------------------------------------------------------------------
# 5. _shui_message
# ---------------------------------------------------------------------------
print "\n=== _shui_message ==="

for _type in success error warning info; do
  _out=$(strip_ansi "$(_shui_message "$_type" "the message text")")
  assert_contains "_shui_message ${_type} renders message text" "the message text" "$_out"
done

# ---------------------------------------------------------------------------
# 6. layout — section, subtitle, subsection, spacer
# ---------------------------------------------------------------------------
print "\n=== layout — section / subtitle / subsection / spacer ==="

_out=$(strip_ansi "$(_shui_layout section "My Section Title")")
assert_contains "section renders title text" "My Section Title" "$_out"

_out=$(strip_ansi "$(_shui_layout subtitle "Sub Heading")")
assert_contains "subtitle renders text" "Sub Heading" "$_out"

_out=$(strip_ansi "$(_shui_layout subsection "Item Text")")
assert_contains "subsection renders text" "Item Text" "$_out"

# spacer with no args produces exactly 1 blank line.
# $(...) strips trailing newlines, so we redirect to a temp file instead.
_spacer_tmp=$(mktemp /tmp/shui-spacer-test.XXXXXX)
_shui_layout spacer > "$_spacer_tmp"
_newline_count=$(tr -cd '\n' < "$_spacer_tmp" | wc -c | tr -d ' ')
assert_eq "spacer (no args) produces 1 blank line" "1" "$_newline_count"

# spacer 3 produces exactly 3 blank lines
_shui_layout spacer 3 > "$_spacer_tmp"
_newline_count=$(tr -cd '\n' < "$_spacer_tmp" | wc -c | tr -d ' ')
assert_eq "spacer 3 produces 3 blank lines" "3" "$_newline_count"
rm -f "$_spacer_tmp"

# ---------------------------------------------------------------------------
# 7. _shui_box
# ---------------------------------------------------------------------------
print "\n=== _shui_box ==="

# No title: output contains top-left corner, bottom-right corner, and content
_out=$(strip_ansi "$(_shui_box "box content text")")
assert_contains "_shui_box (no title) contains top-left corner ┌" "┌" "$_out"
assert_contains "_shui_box (no title) contains bottom-right corner ┘" "┘" "$_out"
assert_contains "_shui_box (no title) contains content text" "box content text" "$_out"

# --title= option: output contains the title
_out=$(strip_ansi "$(_shui_box --title="My Box" "some content")")
assert_contains "_shui_box --title renders title text" "My Box" "$_out"
assert_contains "_shui_box --title still renders content" "some content" "$_out"

# Multi-line content: both lines appear in output
_out=$(strip_ansi "$(_shui_box "line1\nline2")")
assert_contains "_shui_box multi-line: first line present" "line1" "$_out"
assert_contains "_shui_box multi-line: second line present" "line2" "$_out"

# ---------------------------------------------------------------------------
# 8. _shui_table
# ---------------------------------------------------------------------------
print "\n=== _shui_table ==="

# Basic 2-row table (header + 1 data row)
_out=$(strip_ansi "$(_shui_table "Name|Age" "Alice|30")")
assert_contains "_shui_table header text present" "Name" "$_out"
assert_contains "_shui_table header column 2 present" "Age" "$_out"
assert_contains "_shui_table data text present" "Alice" "$_out"
assert_contains "_shui_table data column 2 present" "30" "$_out"
assert_contains "_shui_table has top-left corner ┌" "┌" "$_out"
assert_contains "_shui_table has bottom-right corner ┘" "┘" "$_out"

# The mid-separator ├ appears between the header row and the first data row
assert_contains "_shui_table has mid-separator ├ after header" "├" "$_out"

# Custom --sep=, splits columns correctly
_out=$(strip_ansi "$(_shui_table --sep="," "ColA,ColB" "val1,val2")")
assert_contains "_shui_table --sep=, renders first header column" "ColA" "$_out"
assert_contains "_shui_table --sep=, renders second header column" "ColB" "$_out"
assert_contains "_shui_table --sep=, renders first data column" "val1" "$_out"
assert_contains "_shui_table --sep=, renders second data column" "val2" "$_out"

# ---------------------------------------------------------------------------
# 9. _shui_progress — iTerm integration
# ---------------------------------------------------------------------------
print "\n=== _shui_progress --iterm ==="

# Without ITERM_SESSION_ID: no iTerm escape should be emitted
unset ITERM_SESSION_ID
_out=$(_shui_progress 5 10 --width=10 --iterm)
assert_not_contains "--iterm without ITERM_SESSION_ID emits no iTerm escape" $'\033]9;4;' "$_out"

# With ITERM_SESSION_ID set: the iTerm progress escape must appear
export ITERM_SESSION_ID="fake-session"

_out=$(_shui_progress 5 10 --width=10 --iterm)
assert_contains "--iterm (normal) emits state 1 escape" $'\033]9;4;1;' "$_out"

_out=$(_shui_progress 5 10 --width=10 --iterm=warning)
assert_contains "--iterm=warning emits state 4 escape" $'\033]9;4;4;' "$_out"

_out=$(_shui_progress 5 10 --width=10 --iterm=error)
assert_contains "--iterm=error emits state 2 escape" $'\033]9;4;2;' "$_out"

_out=$(_shui_progress 5 10 --width=10 --iterm=indeterminate)
assert_contains "--iterm=indeterminate emits state 3 escape" $'\033]9;4;3' "$_out"

_out=$(_shui_progress 5 10 --width=10 --iterm=clear)
assert_contains "--iterm=clear emits state 0 escape" $'\033]9;4;0' "$_out"

unset ITERM_SESSION_ID

# ---------------------------------------------------------------------------
# 10. _shui_animation
# ---------------------------------------------------------------------------
print "\n=== _shui_animation ==="

# typewriter with --delay=0 renders the text immediately (no sleep overhead)
_out=$(strip_ansi "$(_shui_animation typewriter --delay=0 "typewriter text")")
assert_contains "_shui_animation typewriter renders text" "typewriter text" "$_out"

# pulse with --count=1 exits 0
_shui_animation pulse --count=1 "pulse text" >/dev/null 2>&1
assert_exit_ok "_shui_animation pulse --count=1 exits 0" $?

# fade-in with --steps=1 exits 0
_shui_animation fade-in --steps=1 "fade text" >/dev/null 2>&1
assert_exit_ok "_shui_animation fade-in --steps=1 exits 0" $?

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
