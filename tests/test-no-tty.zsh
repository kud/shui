#!/usr/bin/env zsh
#
# Honesty without a terminal: what shui does when nobody is there to answer,
# when its output is a pipe, and when an icon set is asked for by name.
#
#   - every prompt refuses (exit 2, one stderr line) when /dev/tty cannot be
#     opened, instead of taking a default nobody chose
#   - error and warning go to stderr
#   - print-link / hyperlink emit no OSC 8 on a pipe or under NO_COLOR
#   - SHUI_ICONS=unicode keeps the unicode base layer, silently
#
# The prompt cases run in a new session (setsid, or perl's POSIX::setsid where
# util-linux is absent, as on macOS) with stdin on /dev/null, so there is no
# controlling terminal. If neither can detach, those cases are skipped rather
# than left to block on a real terminal.
# Run: zsh tests/test-no-tty.zsh
#

SHUI_DIR="${0:A:h}/.."
source "${0:A:h}/_harness.zsh"

_t_title "no terminal, no pretending"

_tmp=$(mktemp -d)
trap 'rm -rf "$_tmp"' EXIT

# Run a zsh snippet with no controlling terminal. Stdout, stderr and the exit
# code land in $_tmp/{out,err,rc}.
_detached() {
  local -a detach
  if (( $+commands[setsid] )); then
    detach=(setsid -w)
  elif (( $+commands[perl] )); then
    detach=(perl -MPOSIX -e 'POSIX::setsid(); exec @ARGV or die')
  else
    return 1
  fi
  # Before the fix, radio and multiselect spun forever here, redrawing on every
  # failed read: a watchdog turns a hang into a failure (rc 137), and a file-size
  # limit keeps the redraw storm from filling the disk meanwhile.
  $detach zsh -c "ulimit -f 1024; $1" </dev/null >"$_tmp/out" 2>"$_tmp/err" &
  local pid=$! dog rc
  { sleep 5; kill -9 $pid } 2>/dev/null &
  dog=$!
  wait $pid; rc=$?
  kill $dog 2>/dev/null; wait $dog 2>/dev/null
  print -r -- $rc >"$_tmp/rc"
}

_t_section "the detached child really has no terminal"
_detached '{ true </dev/tty } 2>/dev/null && print yes || print no'
if [[ "$(<$_tmp/out)" != no ]]; then
  _t_pass "SKIPPED: cannot detach from the controlling terminal here"
  _can_detach=0
else
  _t_pass "/dev/tty cannot be opened in the detached child"
  _can_detach=1
fi

if (( _can_detach )); then
  _t_section "prompts refuse instead of guessing"

  typeset -A _calls=(
    'confirm --default=y'  'shui confirm --default=y "Delete everything?"'
    'confirm --default=n'  'shui confirm --default=n "Delete everything?"'
    'confirm (no default)' 'shui confirm "Delete everything?"'
    'select'               'shui select "Pick" one two'
    'radio'                'shui radio "Pick" one two'
    'multiselect'          'shui multiselect "Pick" one two'
    'input --default'      'shui input --default=fallback "Name?"'
    'password'             'shui password "Secret?"'
    'tabs'                 'shui tabs "Pick" one two'
  )
  for _name in ${(ko)_calls}; do
    _detached "source '${SHUI_DIR}/shui.zsh'; ${_calls[$_name]}"
    assert_eq "${_name}: exits 2" "2" "$(<$_tmp/rc)"
    assert_eq "${_name}: prints nothing on stdout" "" "$(<$_tmp/out)"
    assert_eq "${_name}: one stderr line, nothing else" \
      "shui: no terminal to ask; pass --yes" "$(<$_tmp/err)"
  done

  _detached "source '${SHUI_DIR}/shui.zsh'; shui confirm --default=y 'Go?' && print CONSENTED"
  assert_not_contains "confirm --default=y never reads as consent" "CONSENTED" "$(<$_tmp/out)"
  assert_not_contains "no raw /dev/tty error leaks" "/dev/tty" "$(<$_tmp/err)"
fi

_t_section "error and warning go to stderr"

source "${SHUI_DIR}/shui.zsh"

for _type in error warning; do
  _out=$(shui "$_type" "boom" 2>/dev/null)
  assert_eq "shui ${_type}: nothing on stdout" "" "$_out"
  _err=$(strip_ansi "$(shui "$_type" "boom" 2>&1 >/dev/null)")
  assert_contains "shui ${_type}: message on stderr" "boom" "$_err"
  _out=$(_shui_message "$_type" "boom" 2>/dev/null)
  assert_eq "_shui_message ${_type}: nothing on stdout" "" "$_out"
done

_err=$(strip_ansi "$({ shui error "boom" >&2 } 2>&1)")
assert_contains "a caller's own >&2 still reaches stderr" "boom" "$_err"

for _type in success info muted; do
  _out=$(strip_ansi "$(shui "$_type" "fine" 2>/dev/null)")
  assert_contains "shui ${_type}: stays on stdout" "fine" "$_out"
done

_t_section "print-link obeys the colour gate"

_link() {
  zsh -c "$1 source '${SHUI_DIR}/shui.zsh'; shui print-link Docs https://example.com; shui hyperlink https://example.com https://example.com"
}

_out=$(_link "unset FORCE_COLOR;")
assert_not_contains "piped: no OSC 8" $'\033]8' "$_out"
assert_not_contains "piped: no escape at all" $'\033' "$_out"
assert_eq "piped: plain text keeps the URL" \
  "Docs (https://example.com)"$'\n'"https://example.com" "$_out"

_out=$(_link "unset FORCE_COLOR; export NO_COLOR=1;")
assert_not_contains "NO_COLOR: no OSC 8" $'\033]8' "$_out"

_out=$(_link "export FORCE_COLOR=1;")
assert_contains "FORCE_COLOR: OSC 8 comes back" $'\033]8;;https://example.com' "$_out"

_t_section "SHUI_ICONS=unicode keeps unicode"

_icons() {
  zsh -c "export LC_ALL='${LC_ALL:-C.UTF-8}'; $1" 2>"$_tmp/err"
}

_want=$(_icons "source '${SHUI_DIR}/src/icons/unicode.zsh'; print -r -- \"\$SHUI_ICON_SUCCESS|\$SHUI_ICON_CHECK|\$SHUI_ICON_BULLET\"")
_got=$(_icons "export SHUI_ICONS=unicode; source '${SHUI_DIR}/shui.zsh'; print -r -- \"\$SHUI_ICON_SUCCESS|\$SHUI_ICON_CHECK|\$SHUI_ICON_BULLET\"")
assert_eq "no warning on stderr" "" "$(<$_tmp/err)"
assert_eq "icons are the unicode layer's, not nerd's" "$_want" "$_got"

_nerd=$(_icons "export SHUI_ICONS=nerd; source '${SHUI_DIR}/shui.zsh'; print -r -- \"\$SHUI_ICON_SUCCESS|\$SHUI_ICON_CHECK|\$SHUI_ICON_BULLET\"")
assert_not_contains "and they differ from nerd's" "$_nerd" "$_got"

_t_results
