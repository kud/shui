#!/usr/bin/env zsh
#
# Shared test harness — source this at the top of each test file.
# Provides: assert_*, strip_ansi, _t_section, _t_title, _t_results
#

_T_RESET=$'\033[0m'
_T_BOLD=$'\033[1m'
_T_DIM=$'\033[2m'
_T_GREEN=$'\033[38;5;46m'
_T_RED=$'\033[38;5;196m'
_T_CYAN=$'\033[38;5;39m'

_PASS=0
_FAIL=0
_FAILURES=()

_t_title() {
  printf '\n%s● %s%s\n' "$_T_BOLD$_T_CYAN" "$1" "$_T_RESET"
}

_t_section() {
  printf '\n%s  %s%s\n' "$_T_DIM" "$1" "$_T_RESET"
}

_t_pass() {
  (( _PASS++ ))
  printf '    %s✓%s %s%s%s\n' "$_T_GREEN" "$_T_RESET" "$_T_DIM" "$1" "$_T_RESET"
}

_t_fail() {
  (( _FAIL++ ))
  printf '    %s✗%s %s\n' "$_T_RED" "$_T_RESET" "$1"
}

assert_eq() {
  local desc="$1" expected="$2" actual="$3"
  if [[ "$actual" == "$expected" ]]; then
    _t_pass "$desc"
  else
    _t_fail "$desc"
    printf '      %sexpected:%s %s\n' "$_T_DIM" "$_T_RESET" "$(printf '%q' "$expected")"
    printf '      %sactual:  %s %s\n' "$_T_DIM" "$_T_RESET" "$(printf '%q' "$actual")"
    _FAILURES+=("✗ ${desc}")
  fi
}

assert_contains() {
  local desc="$1" needle="$2" haystack="$3"
  if [[ "$haystack" == *"$needle"* ]]; then
    _t_pass "$desc"
  else
    _t_fail "$desc"
    printf '      %sexpected to contain:%s %s\n' "$_T_DIM" "$_T_RESET" "$(printf '%q' "$needle")"
    _FAILURES+=("✗ ${desc}")
  fi
}

assert_not_contains() {
  local desc="$1" needle="$2" haystack="$3"
  if [[ "$haystack" != *"$needle"* ]]; then
    _t_pass "$desc"
  else
    _t_fail "$desc"
    printf '      %sexpected NOT to contain:%s %s\n' "$_T_DIM" "$_T_RESET" "$(printf '%q' "$needle")"
    _FAILURES+=("✗ ${desc}")
  fi
}

assert_exit_ok() {
  local desc="$1" code="$2"
  if [[ "$code" -eq 0 ]]; then
    _t_pass "$desc"
  else
    _t_fail "$desc (exited $code)"
    _FAILURES+=("✗ ${desc} — exited $code")
  fi
}

assert_defined() {
  local desc="$1" var="$2"
  if typeset -p "$var" &>/dev/null; then
    _t_pass "$desc"
  else
    _t_fail "$desc"
    printf '      %svariable %s not defined%s\n' "$_T_DIM" "$var" "$_T_RESET"
    _FAILURES+=("✗ ${desc} — variable '$var' is not defined")
  fi
}

assert_not_empty() {
  local desc="$1" val="$2"
  if [[ -n "$val" ]]; then
    _t_pass "$desc"
  else
    _t_fail "$desc"
    printf '      %sexpected non-empty value%s\n' "$_T_DIM" "$_T_RESET"
    _FAILURES+=("✗ ${desc} — value is empty")
  fi
}

strip_ansi() { printf '%s' "$1" | sed 's/\x1b\[[0-9;]*[mK]//g'; }

_t_results() {
  local div="" i
  for ((i=0; i<50; i++)); do div+="─"; done
  printf '\n%s  %s%s\n' "$_T_DIM$_T_CYAN" "$div" "$_T_RESET"
  if [[ $_FAIL -eq 0 ]]; then
    printf '  %s%s✓ %d passed%s\n\n' "$_T_BOLD" "$_T_GREEN" "$_PASS" "$_T_RESET"
  else
    printf '  %s%s✓ %d passed%s   %s%s✗ %d failed%s\n\n' \
      "$_T_BOLD" "$_T_GREEN" "$_PASS" "$_T_RESET" \
      "$_T_BOLD" "$_T_RED"   "$_FAIL" "$_T_RESET"
  fi
  [[ $_FAIL -eq 0 ]]
}
