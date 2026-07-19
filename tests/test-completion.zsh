#!/usr/bin/env zsh
#
# Completion parity tests.
# Guards completions/_shui against the shui() dispatcher so the two can't drift:
#   A. every command the completion offers is actually dispatchable
#   B. every dispatcher command (minus intentional exclusions) is offered
# Run: zsh tests/test-completion.zsh
#

SHUI_DIR="${0:A:h}/.."
source "${0:A:h}/_harness.zsh"

export SHUI_ICONS=none
export SHUI_THEME=plain
source "${SHUI_DIR}/shui.zsh"

_t_title "test-completion"

_COMPFILE="${SHUI_DIR}/completions/_shui"

# ---------------------------------------------------------------------------
# 0. Completion file exists and is syntactically valid
# ---------------------------------------------------------------------------
_t_section "completion file"

if [[ -f "$_COMPFILE" ]]; then
  _t_pass "completions/_shui exists"
else
  _t_fail "completions/_shui is missing"
  _FAILURES+=("✗ completions/_shui missing")
  _t_results; exit $?
fi

zsh -n "$_COMPFILE" 2>/dev/null
assert_exit_ok "zsh -n completions/_shui" $?

# ---------------------------------------------------------------------------
# Extract the two command sets.
# ---------------------------------------------------------------------------

# Completion commands: the 'cmd:desc' entries in the commands=( … ) array.
local -a _completion_cmds
_completion_cmds=("${(@f)$(grep -oE "^    '[a-z][a-z-]*:" "$_COMPFILE" | sed "s/^    '//; s/:$//")}")

# Dispatcher commands: case labels inside shui()'s `case "$cmd" in`, split on |.
local -a _dispatch_cmds
_dispatch_cmds=("${(@f)$(
  awk '
    /^shui\(\) \{/{f=1}
    f && /case "\$cmd" in/{c=1; next}
    c && /^  esac/{c=0}
    c && /\)/{
      sub(/\).*/, "");        # drop everything from the first )
      gsub(/[ \t]/, "");      # strip whitespace
      n = split($0, a, "|");
      for (i = 1; i <= n; i++) print a[i]
    }
  ' "${SHUI_DIR}/shui.zsh"
)}")

# Commands present in the dispatcher but intentionally NOT offered for
# completion: deprecated -simple aliases, flag-form version/help aliases, and
# the case default.
local -A _exclude
for _e in success-simple error-simple warning-simple info-simple \
          --version -v --help -h '*'; do
  _exclude[$_e]=1
done

# ---------------------------------------------------------------------------
# A. Every completion command is a real, dispatchable subcommand
# ---------------------------------------------------------------------------
_t_section "completion ⊆ dispatcher (no dead entries)"

assert_not_empty "parsed completion command list" "${_completion_cmds[*]}"

for _cmd in "${_completion_cmds[@]}"; do
  # `shui <cmd> --help` is intercepted before execution — no tty, no side
  # effects — and only the case default prints "unknown command".
  _out=$(shui "$_cmd" --help 2>&1)
  if [[ "$_out" == *"unknown command"* ]]; then
    _t_fail "completion offers '${_cmd}' but dispatcher rejects it"
    _FAILURES+=("✗ dead completion entry: ${_cmd}")
  else
    _t_pass "'${_cmd}' is dispatchable"
  fi
done

# ---------------------------------------------------------------------------
# B. Every dispatcher command (minus exclusions) is offered by completion
# ---------------------------------------------------------------------------
_t_section "dispatcher ⊆ completion (no missing entries)"

assert_not_empty "parsed dispatcher command list" "${_dispatch_cmds[*]}"

typeset -A _have
for _c in "${_completion_cmds[@]}"; do _have[$_c]=1; done

for _cmd in "${_dispatch_cmds[@]}"; do
  [[ -n "${_exclude[$_cmd]}" ]] && continue
  if [[ -n "${_have[$_cmd]}" ]]; then
    _t_pass "dispatcher '${_cmd}' is in completion"
  else
    _t_fail "dispatcher '${_cmd}' is missing from completion"
    _FAILURES+=("✗ uncovered command: ${_cmd}")
  fi
done

_t_results
