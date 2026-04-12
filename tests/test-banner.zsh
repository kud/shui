#!/usr/bin/env zsh
#
# Tests for the _shui_banner component
# Run: zsh tests/test-banner.zsh
#
# Covers:
#   - all 4 types (info, warning, error, success)
#   - single-line and multi-line content
#   - trailing blank line (post-bar newline)
#   - leading blank line (pre-bar newline)
#   - content text is not bold (caller controls bold via ${SHUI_BOLD}…${SHUI_RESET})
#   - continuation lines rendered for multi-line banners
#

SHUI_DIR="${0:A:h}/.."
source "${0:A:h}/_harness.zsh"

export SHUI_ICONS=none
export SHUI_THEME=plain
source "${SHUI_DIR}/shui.zsh"

_t_title "test-banner"

# ---------------------------------------------------------------------------
# 1. All types render content text
# ---------------------------------------------------------------------------
_t_section "type variants"

for _type in info warning error success; do
  _out=$(strip_ansi "$(_shui_banner "$_type" "the banner text")")
  assert_contains "${_type}: renders content text" "the banner text" "$_out"
done

# ---------------------------------------------------------------------------
# 2. Unknown type falls back to info (no error, content still rendered)
# ---------------------------------------------------------------------------
_t_section "fallback type"

_shui_banner "unknown-type" "fallback content" >/dev/null 2>&1
assert_exit_ok "unknown type exits 0" $?

_out=$(strip_ansi "$(_shui_banner "unknown-type" "fallback content")")
assert_contains "unknown type renders content" "fallback content" "$_out"

# ---------------------------------------------------------------------------
# 3. Structure — leading and trailing blank lines
# ---------------------------------------------------------------------------
_t_section "blank line structure"

_banner_tmp=$(mktemp /tmp/shui-banner-test.XXXXXX)
_shui_banner info "test" > "$_banner_tmp"

# Output should be: \n▌\n▌  icon  text\n▌\n\n
# That is 5 lines (including the empty ones). Count total newlines.
_nl_count=$(tr -cd '\n' < "$_banner_tmp" | wc -c | tr -d ' ')
assert_eq "single-line banner produces 5 newlines (leading \\n + bar + content + bar + trailing \\n)" "5" "$_nl_count"

# The first character of output should be a newline (leading blank)
_first=$(head -c1 "$_banner_tmp" | od -An -tx1 | tr -d ' \n')
assert_eq "banner output starts with a newline" "0a" "$_first"

# The last two characters should be \n\n (trailing blank)
_last2=$(tail -c2 "$_banner_tmp" | od -An -tx1 | tr -d ' \n')
assert_eq "banner output ends with two newlines (trailing blank line)" "0a0a" "$_last2"

rm -f "$_banner_tmp"

# ---------------------------------------------------------------------------
# 4. Multi-line banners render all lines
# ---------------------------------------------------------------------------
_t_section "multi-line content"

_out=$(strip_ansi "$(_shui_banner info "first line" "second line" "third line")")
assert_contains "multi-line: first line present" "first line" "$_out"
assert_contains "multi-line: second line present" "second line" "$_out"
assert_contains "multi-line: third line present" "third line" "$_out"

# Continuation lines are indented differently from the icon line — verify they
# both appear in the output (structure test, not exact indent test)
_banner_tmp=$(mktemp /tmp/shui-banner-multi.XXXXXX)
strip_ansi "$(_shui_banner info "line one" "line two")" > "$_banner_tmp"
_content_lines=$(grep -c 'line' "$_banner_tmp" || true)
assert_eq "multi-line banner has 2 content lines" "2" "$_content_lines"
rm -f "$_banner_tmp"

# ---------------------------------------------------------------------------
# 5. Content text is NOT bold by default (caller adds bold explicitly)
# ---------------------------------------------------------------------------
_t_section "bold not applied to content"

# Capture raw output (with ANSI) and check that bold escape does NOT wrap
# the content text. Bold is CSI 1m = \033[1m.
_raw=$(_shui_banner info "plain content text")
# Extract just the content line (contains the text we passed)
_content_line=$(printf '%s' "$_raw" | grep 'plain content text')
# There should be no bold escape code immediately before the content text
if [[ "$_content_line" == *$'\033[1m'*'plain content text'* ]]; then
  _t_fail "content text must not be wrapped in bold (\\033[1m…content)"
  (( _FAIL++ ))
  _FAILURES+=("✗ content text must not be wrapped in bold")
else
  _t_pass "content text is not bold — caller controls bold explicitly"
  (( _PASS++ ))
fi

# ---------------------------------------------------------------------------
# 6. Bar character (▌) appears in output
# ---------------------------------------------------------------------------
_t_section "bar character"

_out=$(_shui_banner info "any text")
assert_contains "banner includes ▌ bar character" "▌" "$_out"

# ---------------------------------------------------------------------------
# Results
# ---------------------------------------------------------------------------
_t_results || exit 1
