#!/usr/bin/env zsh
#
# Tests for the colour gate: NO_COLOR and a non-TTY stdout strip every escape,
# FORCE_COLOR restores them, and the two one-shot rulings hold — a section
# heading carries no hue, muted is SGR 2 and never italic.
# Run: zsh tests/test-color-gate.zsh
#

SHUI_DIR="${0:A:h}/.."
source "${0:A:h}/_harness.zsh"

_t_title "colour gate"

_load() {
  zsh -c "$1 source '${SHUI_DIR}/shui.zsh'; shui section Hosts; shui success Saved; shui muted quiet; shui row warning differs NAME detail; shui badge success ok"
}

_t_section "piped stdout (the harness's own FORCE_COLOR unset)"
_out=$(_load "unset FORCE_COLOR; export SHUI_ICONS=none;")
assert_not_contains "no escape survives a pipe" $'\033' "$_out"
assert_contains    "content survives a pipe" "Saved" "$_out"

_t_section "NO_COLOR"
_out=$(_load "unset FORCE_COLOR; export NO_COLOR=1 SHUI_ICONS=none;")
assert_not_contains "NO_COLOR strips every escape" $'\033' "$_out"
_out=$(_load "unset FORCE_COLOR; export NO_COLOR=1 SHUI_ICONS=none SHUI_THEME=minimal;")
assert_not_contains "NO_COLOR strips the minimal theme too" $'\033' "$_out"

_t_section "FORCE_COLOR"
_out=$(_load "export FORCE_COLOR=1 SHUI_ICONS=none;")
assert_contains "FORCE_COLOR restores colour under a pipe" $'\033[' "$_out"
_out=$(_load "export FORCE_COLOR=1 NO_COLOR=1 SHUI_ICONS=none;")
assert_contains "FORCE_COLOR outranks NO_COLOR" $'\033[' "$_out"

_t_section "one-shot rulings"
export SHUI_ICONS=none
source "${SHUI_DIR}/shui.zsh"
_out=$(shui section Hosts)
assert_contains     "section is bold" $'\033[1m' "$_out"
assert_not_contains "section carries no hue" $'\033[3' "$_out"
_out=$(shui muted quiet)
assert_contains     "muted is SGR 2" $'\033[2m' "$_out"
assert_not_contains "muted is never italic" $'\033[3m' "$_out"

_t_results
