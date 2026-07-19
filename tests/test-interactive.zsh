#!/usr/bin/env zsh
#
# Interactive/form component tests.
# The prompt loops read from /dev/tty and can't run headlessly, so this covers
# the parts that can: the pure _shui_validate_value helper, that every form
# function is defined, and that the shui() dispatcher routes each subcommand.
# Run: zsh tests/test-interactive.zsh
#

SHUI_DIR="${0:A:h}/.."
source "${0:A:h}/_harness.zsh"

export SHUI_ICONS=none
export SHUI_THEME=plain
source "${SHUI_DIR}/shui.zsh"

_t_title "test-interactive"

# ---------------------------------------------------------------------------
# 1. Functions defined
# ---------------------------------------------------------------------------
_t_section "form functions defined"

for _fn in _shui_confirm _shui_select _shui_radio _shui_multiselect \
           _shui_tabs _shui_input _shui_password _shui_validate_value; do
  if typeset -f "$_fn" &>/dev/null; then
    _t_pass "${_fn} is defined"
  else
    _t_fail "${_fn} is not defined"
    _FAILURES+=("✗ ${_fn} not defined")
  fi
done

# ---------------------------------------------------------------------------
# 2. _shui_validate_value — email
# ---------------------------------------------------------------------------
_t_section "_shui_validate_value email"

for _ok in "a@b.io" "erwann.mest@kud.io" "x+tag@sub.example.co.uk"; do
  _shui_validate_value email "$_ok"
  assert_exit_ok "email accepts ${_ok}" $?
done

for _bad in "nope" "a@b" "@b.io" "a@.io" "a b@c.io" "" "a@b.io c"; do
  if _shui_validate_value email "$_bad"; then
    _t_fail "email rejects ${(qq)_bad}"
    _FAILURES+=("✗ email wrongly accepted ${(qq)_bad}")
  else
    _t_pass "email rejects ${(qq)_bad}"
  fi
done

# ---------------------------------------------------------------------------
# 3. _shui_validate_value — url / number
# ---------------------------------------------------------------------------
_t_section "_shui_validate_value url / number"

_shui_validate_value url "https://kud.io/x"; assert_exit_ok "url accepts https://kud.io/x" $?
_shui_validate_value url "http://a.b";       assert_exit_ok "url accepts http://a.b" $?
if _shui_validate_value url "ftp://a.b"; then _t_fail "url rejects ftp://a.b"; _FAILURES+=("✗ url ftp"); else _t_pass "url rejects ftp://a.b"; fi
if _shui_validate_value url "kud.io";    then _t_fail "url rejects bare host"; _FAILURES+=("✗ url bare"); else _t_pass "url rejects bare host"; fi

_shui_validate_value number "42";  assert_exit_ok "number accepts 42" $?
_shui_validate_value number "-7";  assert_exit_ok "number accepts -7" $?
if _shui_validate_value number "3.14"; then _t_fail "number rejects 3.14"; _FAILURES+=("✗ number float"); else _t_pass "number rejects 3.14"; fi
if _shui_validate_value number "1a";   then _t_fail "number rejects 1a"; _FAILURES+=("✗ number 1a"); else _t_pass "number rejects 1a"; fi

# ---------------------------------------------------------------------------
# 4. _shui_validate_value — arbitrary regex fallback
# ---------------------------------------------------------------------------
_t_section "_shui_validate_value regex fallback"

_shui_validate_value '^[A-Z]{3}$' "ABC"; assert_exit_ok "regex accepts ABC" $?
if _shui_validate_value '^[A-Z]{3}$' "abcd"; then
  _t_fail "regex rejects abcd"; _FAILURES+=("✗ regex abcd")
else
  _t_pass "regex rejects abcd"
fi

# ---------------------------------------------------------------------------
# 5. Dispatcher routing — unknown commands are now known
# ---------------------------------------------------------------------------
_t_section "shui() routes new subcommands"

# 'shui <cmd> --help' hits _shui_help_cmd without touching a tty — proves the
# dispatcher knows the command (an unknown command would print 'no help').
for _cmd in tabs password input; do
  _out=$(shui "$_cmd" --help 2>&1)
  assert_not_contains "shui ${_cmd} --help is a known command" "no help available" "$_out"
done

_out=$(shui input --help 2>&1)
assert_contains "input --help documents --validate" "--validate" "$_out"

_out=$(shui password --help 2>&1)
assert_contains "password --help mentions masking" "Masked" "$_out"

_t_results
