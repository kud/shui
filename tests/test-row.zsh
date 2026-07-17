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

# Columns must stay columns for ANY input, not merely for tags that happen to be
# shorter than the width. Padding alone collapses to nothing when a value exactly
# fills its column, and does nothing at all when a value overflows it — so the
# component emits a literal separator rather than relying on width arithmetic.
out="$(strip_ansi "$(shui row success updated ATLASSIAN_BASE_URL 'x')")"
assert_not_contains "7-char tag does not touch the name" "updatedATLASSIAN" "$out"

out="$(strip_ansi "$(shui row warning differs NEO4J_QA_URI 'y')")"
assert_not_contains "differs does not touch the name" "differsNEO4J" "$out"

# Exactly the default width (8) — the case that collapses under padding alone.
out="$(strip_ansi "$(shui row success attached id_ed25519 'in the vault')")"
assert_not_contains "8-char tag (== default width) does not touch the name" "attachedid_ed25519" "$out"
assert_contains     "8-char tag is separated"                               "attached id_ed25519" "$out"

# Beyond the width — no width setting can rescue this; only the separator can.
out="$(strip_ansi "$(shui row error CATASTROPHE id_ed25519 'boom')")"
assert_not_contains "over-long tag does not touch the name" "CATASTROPHEid_ed25519" "$out"

# A name at or beyond the column width must still be separated from the detail.
long_name="ABCDEFGHIJKLMNOPQRSTUVWXYZ012"   # 29 chars, beyond the 28 default
out="$(strip_ansi "$(shui row muted same "$long_name" 'detail here')")"
assert_not_contains "over-long name does not touch the detail" "012detail" "$out"

# Every tag in real use across `my`, short and long — none may touch the name.
# The invariant is separation, not a fixed gap: a short tag is padded out to the
# column and then separated, so the gap varies while "never touching" does not.
for t in same added new update updated differs skip FAILED attach attached restored write; do
  out="$(strip_ansi "$(shui row muted "$t" SOME_KEY 'detail')")"
  assert_not_contains "tag '$t' never touches the name" "${t}SOME_KEY" "$out"
done

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
assert_contains "custom widths still separate columns" "ok   NAME   detail" "$out"

_t_results
