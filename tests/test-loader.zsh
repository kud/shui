#!/usr/bin/env zsh
#
# Tests for the loader.zsh component (indeterminate loader)
# Run: zsh tests/test-loader.zsh
#
# Covers:
#   - sourcing shui.zsh makes EPOCHSECONDS available (zsh/datetime)
#   - the hang detector actually detects — with zsh/datetime unloaded, the
#     loader spins forever, so a passing termination check means something
#   - shui loader terminates in a non-interactive shell, every style
#   - shui loader clears its own line on exit
#
# Every loader call goes through _loader_run, never straight into this shell:
# the bug under test is an infinite loop, and an in-process call would hang the
# suite rather than fail it.
#

SHUI_DIR="${0:A:h}/.."
source "${0:A:h}/_harness.zsh"

export SHUI_ICONS=none
export SHUI_THEME=plain
source "${SHUI_DIR}/shui.zsh"

_t_title "test-loader"

# Runs the loader in a clean non-interactive zsh — the shell shape that has no
# interactive profile to have loaded zsh/datetime for it — under a hard time
# bound. Sets _LOADER_OUTCOME (terminated|hung) and _LOADER_OUT (its output).
# Assigns globals rather than printing, because $(…) would run it in a subshell
# and strand the captured output there.
#
# $1: loader style   $2: "unload" to strip zsh/datetime after shui.zsh loads
_loader_run() {
  local style="$1" prelude=""
  [[ "$2" == unload ]] && prelude='zmodload -u zsh/datetime 2>/dev/null;'

  local capture=$(mktemp /tmp/shui-loader-XXXXXX)
  env -i HOME="$HOME" PATH="$PATH" TERM=dumb SHUI_ICONS=none SHUI_THEME=plain \
    zsh -c "source '${SHUI_DIR}/shui.zsh'; ${prelude} shui loader --style=${style} --duration=1 probe" \
    >| "$capture" 2>&1 &

  local pid=$! attempt
  _LOADER_OUTCOME=hung
  for attempt in {1..40}; do
    if ! kill -0 "$pid" 2>/dev/null; then
      wait "$pid" 2>/dev/null
      _LOADER_OUTCOME=terminated
      break
    fi
    sleep 0.25
  done

  if [[ "$_LOADER_OUTCOME" == hung ]]; then
    kill -9 "$pid" 2>/dev/null
    wait "$pid" 2>/dev/null
  fi

  _LOADER_OUT=$(cat "$capture")
  rm -f "$capture"
}

# ---------------------------------------------------------------------------
# 1. zsh/datetime is loaded by shui.zsh
# ---------------------------------------------------------------------------
_t_section "zsh/datetime"

_out=$(env -i HOME="$HOME" PATH="$PATH" \
  zsh -c "source '${SHUI_DIR}/shui.zsh'; print -r -- \$EPOCHSECONDS" 2>/dev/null)
assert_not_empty "sourcing shui.zsh makes EPOCHSECONDS available" "$_out"

# ---------------------------------------------------------------------------
# 2. The hang detector actually detects
# ---------------------------------------------------------------------------
_t_section "hang detector"

_loader_run spinner unload
assert_eq "loader hangs when zsh/datetime is unavailable" "hung" "$_LOADER_OUTCOME"

# ---------------------------------------------------------------------------
# 3. Every style terminates
# ---------------------------------------------------------------------------
_t_section "termination"

for _style in dots pulse spinner; do
  _loader_run "$_style"
  assert_eq "loader --style=${_style} terminates in a non-interactive shell" \
    "terminated" "$_LOADER_OUTCOME"
done

# ---------------------------------------------------------------------------
# 4. The loader leaves no residue on its line
# ---------------------------------------------------------------------------
_t_section "line cleanup"

_loader_run dots
assert_contains "loader clears its line on exit" $'\r\033[K' "$_LOADER_OUT"

# ---------------------------------------------------------------------------
# Results
# ---------------------------------------------------------------------------
_t_results || exit 1
