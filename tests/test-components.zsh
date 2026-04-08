#!/usr/bin/env zsh
#
# Comprehensive component tests — text, badge, pill, message, layout, box,
# table, progress (iTerm), and animation.
# Run: zsh tests/test-components.zsh
#

SHUI_DIR="${0:A:h}/.."
source "${0:A:h}/_harness.zsh"

export SHUI_ICONS=none
export SHUI_THEME=plain
source "${SHUI_DIR}/shui.zsh"

_t_title "test-components"

# ---------------------------------------------------------------------------
# 1. Syntax checks
# ---------------------------------------------------------------------------
_t_section "syntax checks"

for f in "${SHUI_DIR}"/shui.zsh "${SHUI_DIR}"/src/**/*.zsh; do
  zsh -n "$f" 2>/dev/null
  assert_exit_ok "zsh -n ${f:t}" $?
done

# ---------------------------------------------------------------------------
# 2. _shui_text
# ---------------------------------------------------------------------------
_t_section "_shui_text"

for _style in bold dim italic underline; do
  _out=$(strip_ansi "$(_shui_text "$_style" "hello world")")
  assert_contains "${_style} renders text" "hello world" "$_out"
done

_out=$(strip_ansi "$(_shui_text text "plain text")")
assert_contains "text (no --color) renders text" "plain text" "$_out"

for _color in success error warning info muted accent primary; do
  _out=$(strip_ansi "$(_shui_text text --color="$_color" "coloured text")")
  assert_contains "text --color=${_color} renders text" "coloured text" "$_out"
done

# ---------------------------------------------------------------------------
# 3. _shui_badge
# ---------------------------------------------------------------------------
_t_section "_shui_badge"

for _type in success error warning info primary muted; do
  _out=$(strip_ansi "$(_shui_badge "$_type" "my-label")")
  assert_contains "${_type} renders label" "my-label" "$_out"
done

_shui_badge "unknown-type" "fallback-label" >/dev/null 2>&1
assert_exit_ok "unknown type exits 0" $?
_out=$(strip_ansi "$(_shui_badge "unknown-type" "fallback-label")")
assert_contains "unknown type renders label" "fallback-label" "$_out"

export NO_COLOR=1
_out=$(_shui_badge "success" "no-color-label")
assert_eq "NO_COLOR renders [label]" "[no-color-label]" "$_out"
assert_not_contains "NO_COLOR has no ANSI escapes" $'\033' "$_out"
unset NO_COLOR

# ---------------------------------------------------------------------------
# 4. _shui_pill_custom
# ---------------------------------------------------------------------------
_t_section "_shui_pill_custom"

_out=$(strip_ansi "$(_shui_pill_custom 15 46 "custom-text")")
assert_contains "renders the text" "custom-text" "$_out"

export NO_COLOR=1
_out=$(_shui_pill_custom 15 46 "nc-text")
assert_eq "NO_COLOR renders [text]" "[nc-text]" "$_out"
assert_not_contains "NO_COLOR has no ANSI escapes" $'\033' "$_out"
unset NO_COLOR

# ---------------------------------------------------------------------------
# 5. _shui_message
# ---------------------------------------------------------------------------
_t_section "_shui_message"

for _type in success error warning info; do
  _out=$(strip_ansi "$(_shui_message "$_type" "the message text")")
  assert_contains "${_type} renders message text" "the message text" "$_out"
done

# ---------------------------------------------------------------------------
# 6. layout — section, subtitle, subsection, spacer
# ---------------------------------------------------------------------------
_t_section "layout — section / subtitle / subsection / spacer"

_out=$(strip_ansi "$(_shui_layout section "My Section Title")")
assert_contains "section renders title text" "My Section Title" "$_out"

_out=$(strip_ansi "$(_shui_layout subtitle "Sub Heading")")
assert_contains "subtitle renders text" "Sub Heading" "$_out"

_out=$(strip_ansi "$(_shui_layout subsection "Item Text")")
assert_contains "subsection renders text" "Item Text" "$_out"

_spacer_tmp=$(mktemp /tmp/shui-spacer-test.XXXXXX)
_shui_layout spacer > "$_spacer_tmp"
_newline_count=$(tr -cd '\n' < "$_spacer_tmp" | wc -c | tr -d ' ')
assert_eq "spacer (no args) produces 1 blank line" "1" "$_newline_count"

_shui_layout spacer 3 > "$_spacer_tmp"
_newline_count=$(tr -cd '\n' < "$_spacer_tmp" | wc -c | tr -d ' ')
assert_eq "spacer 3 produces 3 blank lines" "3" "$_newline_count"
rm -f "$_spacer_tmp"

# ---------------------------------------------------------------------------
# 7. _shui_box
# ---------------------------------------------------------------------------
_t_section "_shui_box"

_out=$(strip_ansi "$(_shui_box "box content text")")
assert_contains "no title: contains ┌" "┌" "$_out"
assert_contains "no title: contains ┘" "┘" "$_out"
assert_contains "no title: contains content text" "box content text" "$_out"

_out=$(strip_ansi "$(_shui_box --title="My Box" "some content")")
assert_contains "--title renders title text" "My Box" "$_out"
assert_contains "--title still renders content" "some content" "$_out"

_out=$(strip_ansi "$(_shui_box "line1\nline2")")
assert_contains "multi-line: first line present" "line1" "$_out"
assert_contains "multi-line: second line present" "line2" "$_out"

# ---------------------------------------------------------------------------
# 8. _shui_table
# ---------------------------------------------------------------------------
_t_section "_shui_table"

_out=$(strip_ansi "$(_shui_table "Name|Age" "Alice|30")")
assert_contains "header column 1 present" "Name" "$_out"
assert_contains "header column 2 present" "Age" "$_out"
assert_contains "data column 1 present" "Alice" "$_out"
assert_contains "data column 2 present" "30" "$_out"
assert_contains "has top-left corner ┌" "┌" "$_out"
assert_contains "has bottom-right corner ┘" "┘" "$_out"
assert_contains "has mid-separator ├ after header" "├" "$_out"

_out=$(strip_ansi "$(_shui_table --sep="," "ColA,ColB" "val1,val2")")
assert_contains "--sep=, header column 1" "ColA" "$_out"
assert_contains "--sep=, header column 2" "ColB" "$_out"
assert_contains "--sep=, data column 1" "val1" "$_out"
assert_contains "--sep=, data column 2" "val2" "$_out"

# ---------------------------------------------------------------------------
# 9. _shui_progress — iTerm integration
# ---------------------------------------------------------------------------
_t_section "_shui_progress --iterm"

unset ITERM_SESSION_ID
_out=$(_shui_progress 5 10 --width=10 --iterm)
assert_not_contains "no ITERM_SESSION_ID: no iTerm escape emitted" $'\033]9;4;' "$_out"

export ITERM_SESSION_ID="fake-session"
_out=$(_shui_progress 5 10 --width=10 --iterm)
assert_contains "--iterm (normal) emits state 1" $'\033]9;4;1;' "$_out"

_out=$(_shui_progress 5 10 --width=10 --iterm=warning)
assert_contains "--iterm=warning emits state 4" $'\033]9;4;4;' "$_out"

_out=$(_shui_progress 5 10 --width=10 --iterm=error)
assert_contains "--iterm=error emits state 2" $'\033]9;4;2;' "$_out"

_out=$(_shui_progress 5 10 --width=10 --iterm=indeterminate)
assert_contains "--iterm=indeterminate emits state 3" $'\033]9;4;3' "$_out"

_out=$(_shui_progress 5 10 --width=10 --iterm=clear)
assert_contains "--iterm=clear emits state 0" $'\033]9;4;0' "$_out"

unset ITERM_SESSION_ID

# ---------------------------------------------------------------------------
# 10. _shui_animation
# ---------------------------------------------------------------------------
_t_section "_shui_animation"

_out=$(strip_ansi "$(_shui_animation typewriter --delay=0 "typewriter text")")
assert_contains "typewriter renders text" "typewriter text" "$_out"

_shui_animation pulse --count=1 "pulse text" >/dev/null 2>&1
assert_exit_ok "pulse --count=1 exits 0" $?

_shui_animation fade-in --steps=1 "fade text" >/dev/null 2>&1
assert_exit_ok "fade-in --steps=1 exits 0" $?

# ---------------------------------------------------------------------------
# Results
# ---------------------------------------------------------------------------
_t_results || exit 1
