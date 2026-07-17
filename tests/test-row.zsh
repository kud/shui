#!/usr/bin/env zsh
#
# Tests for `shui row` — the streaming status row.
# Run: zsh tests/test-row.zsh
#

SHUI_DIR="${0:A:h}/.."
source "${0:A:h}/_harness.zsh"

export SHUI_ICONS=none
export SHUI_THEME=plain
source "${SHUI_DIR}/shui.zsh"

_t_title "test-row"

# ---------------------------------------------------------------------------
_t_section "syntax"
# ---------------------------------------------------------------------------

zsh -n "${SHUI_DIR}/src/components/row.zsh" 2>/dev/null
assert_exit_ok "zsh -n row.zsh" $?

# ---------------------------------------------------------------------------
_t_section "content"
# ---------------------------------------------------------------------------

out="$(strip_ansi "$(shui row success added GITHUB_TOKEN 'stored in the vault')")"
assert_contains "renders the tag"    "added" "$out"
assert_contains "renders the name"   "GITHUB_TOKEN" "$out"
assert_contains "renders the detail" "stored in the vault" "$out"

out="$(strip_ansi "$(shui row muted same MCP_JENKINS_URL)")"
assert_contains "detail is optional" "MCP_JENKINS_URL" "$out"

# ---------------------------------------------------------------------------
_t_section "column separation"
# ---------------------------------------------------------------------------

# The bug this component exists to prevent: a tag that exactly fills its column
# pads to nothing and runs into the name. "updated" is 7 chars — the width must
# exceed the longest tag, not equal it.
out="$(strip_ansi "$(shui row success updated ATLASSIAN_BASE_URL 'x')")"
assert_not_contains "7-char tag does not touch the name" "updatedATLASSIAN" "$out"
assert_contains     "7-char tag is separated"            "updated ATLASSIAN" "$out"

out="$(strip_ansi "$(shui row warning differs NEO4J_QA_URI 'y')")"
assert_not_contains "differs does not touch the name" "differsNEO4J" "$out"

# A name at the column width must still be separated from the detail.
long_name="ABCDEFGHIJKLMNOPQRSTUVWXYZ012"   # 29 chars, beyond the 28 default
out="$(strip_ansi "$(shui row muted same "$long_name" 'detail here')")"
assert_not_contains "over-long name does not touch the detail" "012detail" "$out"

# ---------------------------------------------------------------------------
_t_section "variants"
# ---------------------------------------------------------------------------

for v in success error warning info muted; do
  shui row "$v" tag NAME detail >/dev/null 2>&1
  assert_exit_ok "variant '$v' is accepted" $?
done

shui row bogus tag NAME detail >/dev/null 2>&1
[[ $? -ne 0 ]] && _t_pass "unknown variant is rejected" || _t_fail "unknown variant is rejected"

# ---------------------------------------------------------------------------
_t_section "readable without colour"
# ---------------------------------------------------------------------------

# Colour only reinforces: the tag word must carry the meaning by itself, so the
# row still reads when piped, stripped, or unseen.
a="$(strip_ansi "$(shui row success added FOO)")"
b="$(strip_ansi "$(shui row warning differs FOO)")"
[[ "$a" != "$b" ]] && _t_pass "variants differ with colour stripped" \
                   || _t_fail "variants differ with colour stripped"

# ---------------------------------------------------------------------------
_t_section "width overrides"
# ---------------------------------------------------------------------------

out="$(strip_ansi "$(shui row --tag-width=4 --name-width=6 muted ok NAME detail)")"
assert_contains "custom widths still separate columns" "ok  NAME   detail" "$out"

_t_results
