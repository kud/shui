#!/usr/bin/env zsh
#
# The components that redraw in place, driven through a real pseudo-terminal
# (zsh/zpty) of a chosen size, plus the pure arithmetic behind them.
#
#   - radio and multiselect show a scrolling window when the list is taller
#     than the terminal, instead of stacking a new copy on every keypress
#   - a short list draws byte for byte as it did before the window existed
#   - lines wider than the terminal are cut on screen, never in what is printed
#   - ctrl-c is a keypress, so the tty and the cursor come back on cancel
#   - keys arrive whole: PgDn and Delete leave no stray "~"
#   - tabs fit a narrow terminal; spinner keeps job control quiet
#
# Run: zsh tests/test-tty.zsh
#

SHUI_DIR="${0:A:h}/.."
source "${0:A:h}/_harness.zsh"

unset ITERM_SESSION_ID
export SHUI_ICONS=ascii
export SHUI_THEME=plain
source "${SHUI_DIR}/shui.zsh"

_t_title "test-tty"

# ---------------------------------------------------------------------------
# 1. _shui_list_window — which slice of a list is drawn
# ---------------------------------------------------------------------------
_t_section "_shui_list_window"

_win() { local -a reply; _shui_list_window "$@"; print -r -- "${reply[*]}"; }

assert_eq "short list: whole list, no position line"  "1 5 0"   "$(_win 5 3 1 10)"
assert_eq "list exactly the free rows: not clipped"   "1 10 0"  "$(_win 10 10 1 10)"
assert_eq "long list: window one row short, marker"   "1 19 1"  "$(_win 76 1 1 20)"
assert_eq "cursor past the bottom scrolls down"       "12 19 1" "$(_win 76 30 1 20)"
assert_eq "cursor inside the window keeps it still"   "12 19 1" "$(_win 76 20 12 20)"
assert_eq "cursor above the top scrolls up"           "11 19 1" "$(_win 76 11 12 20)"
assert_eq "last option: window ends on it"            "58 19 1" "$(_win 76 76 1 20)"
assert_eq "terminal shrank: top re-clamped"           "73 4 1"  "$(_win 76 76 58 5)"
assert_eq "two free rows: one option and the marker"  "5 1 1"   "$(_win 10 5 1 2)"
assert_eq "one free row: one option, no marker"       "5 1 0"   "$(_win 10 5 1 1)"
assert_eq "no free row at all: still one option"      "5 1 0"   "$(_win 10 5 1 0)"
assert_eq "no options"                                "1 0 0"   "$(_win 0 1 1 10)"

# ---------------------------------------------------------------------------
# 2. _shui_fit / _shui_plain / _shui_rows_drawn
# ---------------------------------------------------------------------------
_t_section "_shui_fit, _shui_plain, _shui_rows_drawn"

_fit() { local REPLY; _shui_fit "$@"; print -r -- "$REPLY"; }
assert_eq "fits: unchanged"             "hello"   "$(_fit hello 5)"
assert_eq "too wide: cut with ellipsis" "hello…"  "$(_fit 'hello world' 6)"
assert_eq "wide characters count two"   "日本…"   "$(_fit 日本語テキスト 5)"
assert_eq "no room: empty"              ""        "$(_fit hello 0)"

_plain() { local REPLY; _shui_plain "$1"; print -r -- "$REPLY"; }
assert_eq "tab, newline and colour made one plain row" "a b cd" \
  "$(_plain $'a\tb\nc\e[31md\e[0m')"

_rows() { local REPLY; _shui_rows_drawn "$@"; print -r -- "$REPLY"; }
assert_eq "lines that fit: one row each"        "3" "$(_rows 80 5 79 0)"
assert_eq "a narrower window reflows a line"    "4" "$(_rows 10 5 19 0)"

# ---------------------------------------------------------------------------
# The pseudo-terminal driver
# ---------------------------------------------------------------------------
zmodload zsh/zpty zsh/zselect

# Runs $3 on a pseudo-terminal of $1 rows by $2 columns, waits for $4 to appear
# (the prompt holding the keyboard), then types each further argument as one
# write; an argument @N waits N seconds instead. Sets _PTY to everything the
# terminal received, carriage returns removed.
_pty() {
  local rows=$1 cols=$2 code=$3 ready=$4 key fd
  shift 4
  _PTY=""
  zpty -b _t_pty "stty rows $rows cols $cols; $code; print -r -- \"<<end \$?>>\""
  fd=$REPLY
  _pty_wait "$ready" || _PTY+="<<timeout before the prompt>>"
  for key in "$@"; do
    if [[ "$key" == @* ]]; then
      _pty_wait "" ${key#@}
    else
      zpty -w -n _t_pty "$key"
      _pty_wait "" 0.05
    fi
  done
  _pty_wait "<<end" || _PTY+="<<timeout>>"
  zpty -d _t_pty
  _PTY="${_PTY//$'\r'/}"
}

# Reads until the output so far contains $1, or with $1 empty for $2 seconds.
_pty_wait() {
  local want="$1" chunk
  local -F end=$(( EPOCHREALTIME + ${2:-10} ))
  while (( EPOCHREALTIME < end )); do
    zselect -t 5 -r $fd 2>/dev/null
    while zpty -r -t _t_pty chunk 2>/dev/null; do _PTY+=$chunk; done
    [[ -n "$want" && "$_PTY" == *"$want"* ]] && return 0
  done
  [[ -z "$want" ]]
}

# The widest line the terminal was asked to draw, escapes stripped.
_widest() {
  local line REPLY
  local -i max=0
  for line in "${(@f)1}"; do
    _shui_plain "$line"
    (( ${(m)#REPLY} > max )) && max=${(m)#REPLY}
  done
  print -r -- $max
}

# The row counts of every cursor-up the terminal was sent, in order.
_climbs() {
  local s="$1"
  local -a out
  while [[ "$s" =~ $'\e\\[([0-9]+)A' ]]; do
    out+=($match[1])
    s="${s[MEND+1,-1]}"
  done
  print -r -- "${out[*]}"
}

_HIDE=$'\e[?25l'
_SHOW=$'\e[?25h'
_ms='out=$(shui multiselect Pick "${items[@]}"); print -r -- "<<rc=$?>><<out=${(j:,:)${(f)out}}>>"'
_rd='out=$(shui radio Pick "${items[@]}"); print -r -- "<<rc=$?>><<out=$out>>"'

# ---------------------------------------------------------------------------
# 3. A short list draws exactly as before
# ---------------------------------------------------------------------------
_t_section "multiselect: a short list, byte for byte"

items=(a b$'\t'hint c)
_pty 10 60 "$_ms" "$_HIDE" j ' ' $'\e[B' ' ' $'\n'
_want="Pick ↑↓/jk move · space toggle · a all · enter confirm · q cancel"$'\n'
# Each frame: the cursor row, then the three boxes. The pointer marks the
# cursor row; every other row carries a blank of the same width.
for _f in "1 . . ." "2 . . ." "2 . # ." "3 . # ." "3 . # #"; do
  [[ "$_want" == *$_HIDE* ]] && _want+=$'\e[3A'
  _f=(${=_f})
  _ptr=(" " " " " ")
  _ptr[$_f[1]]=">"
  _want+=$'\e[2K  '"$_ptr[1] $_f[2]"$' a  \n\e[2K  '"$_ptr[2] $_f[3]"$' b  hint\n\e[2K  '"$_ptr[3] $_f[4]"$' c  \n'
  [[ "$_want" == *$_HIDE* ]] || _want+="$_HIDE"
done
_want+="$_SHOW"$'\n'"<<rc=0>><<out=b,c>>"$'\n'
assert_eq "every byte as expected, the pointer on the cursor row" "$_want" "${_PTY%<<end 0>>$'\n'}"

_t_section "multiselect: the cursor shows without colour"

# Under `plain` every colour token is empty, so a cursor drawn in colour alone
# vanished. The pointer must be on the cursor row and on no other.
items=(alpha beta gamma)
_pty 10 40 "$_ms" "$_HIDE" j $'\n'
_frame=${${_PTY#*$_HIDE}%%<<rc=*}
_frame=${_frame##*$'\e[3A'}
assert_contains "pointer on the cursor row"   "  > . beta"  "$_frame"
assert_contains "no pointer on another row"   "    . alpha" "$_frame"
_lines=("${(@f)_frame}")
assert_eq "exactly one pointer in the frame" "1" "${#${(@M)_lines:#*\> *}}"

# ---------------------------------------------------------------------------
# 4. A list taller than the terminal scrolls
# ---------------------------------------------------------------------------
_t_section "multiselect: 30 options in a 10-row terminal"

items=(item-{01..30})
_pty 10 40 "$_ms" "$_HIDE" j j j ' ' $'\e[6~' ' ' G ' ' g $'\n'
assert_eq "every redraw climbs the same 7 rows" "7" "$(_climbs "$_PTY" | tr " " "\n" | sort -u)"
assert_contains "position line at the top"    "1–6 of 30"                 "$_PTY"
assert_contains "PgDn moves a page"           "5–10 of 30 · 1 selected"   "$_PTY"
assert_contains "G reaches the end"           "25–30 of 30 · 3 selected"  "$_PTY"
assert_not_contains "never more rows than fit" "item-01  "$'\n'$'\e[2K'"    . item-08" "$_PTY"
assert_contains "returns the ticked labels"   "<<rc=0>><<out=item-04,item-10,item-30>>" "$_PTY"
_out=${${_PTY#*$_HIDE}%%<<rc=*}
assert_eq "no line wider than the terminal" "1" "$(( $(_widest "$_out") <= 39 ))"

_t_section "multiselect: the terminal shrinks between keypresses"

_pty 10 40 "{ sleep 1; stty rows 6 </dev/tty } & $_ms" "$_HIDE" @1.5 j j $'\n'
assert_eq "climbs the old frame, then the new one" "7 3" "$(_climbs "$_PTY")"
assert_contains "clears what the taller frame left" $'\e[J' "$_PTY"
assert_contains "window refitted to 2 rows"          "1–2 of 30" "$_PTY"

# ---------------------------------------------------------------------------
# 5. Lines wider than the terminal
# ---------------------------------------------------------------------------
_t_section "long labels and hints are cut on screen only"

_long="a-package-with-a-very-long-name-indeed"
items=("short"$'\t'"a hint that is far too long to fit" "${_long}"$'\t'"hint")
_pty 10 30 "$_ms" "$_HIDE" ' ' j ' ' $'\n'
_out=${${_PTY#*$_HIDE}%%<<rc=*}
assert_eq "no line wider than 29 columns" "1" "$(( $(_widest "$_out") <= 29 ))"
assert_contains "hint cut with an ellipsis" "…" "$_out"
assert_eq "climb stays 2: nothing wrapped" "2" "$(_climbs "$_out" | tr " " "\n" | sort -u)"
assert_contains "full labels come back" "<<out=short,${_long}>>" "$_PTY"

items=($'tab\there\tand-more' $'esc\e[31mred' $'line\nbreak')
_pty 10 40 "$_ms" "$_HIDE" a $'\n'
assert_contains "labels with control characters come back as given" \
  "<<out=tab,esc"$'\e[31m'"red,line,break>>" "$_PTY"
_out=${${_PTY#*$_HIDE}%%<<rc=*}
assert_not_contains "but none reaches the screen" $'\e[31m' "$_out"

# ---------------------------------------------------------------------------
# 6. radio
# ---------------------------------------------------------------------------
_t_section "radio"

items=(opt-{01..40})
_pty 8 40 "$_rd" "$_HIDE" $'\e[6~' $'\e[6~' $'\e[A' $'\n'
assert_contains "PgDn twice by a 4-row page, up once: opt-08" "<<rc=0>><<out=opt-08>>" "$_PTY"
_pty 8 40 "$_rd" "$_HIDE" $'\e[F' $'\n'
assert_contains "End picks the last option" "<<out=opt-40>>" "$_PTY"
_pty 8 40 "$_rd" "$_HIDE" $'\e[F' $'\e[H' $'\n'
assert_contains "Home goes back to the first" "<<out=opt-01>>" "$_PTY"

items=()
_pty 8 40 "$_rd" "<<end"
assert_contains "no options: exits 1 without drawing" "<<rc=1>><<out=>>" "$_PTY"

# ---------------------------------------------------------------------------
# 7. Cancelling hands the terminal back
# ---------------------------------------------------------------------------
_t_section "ctrl-c, q and esc cancel cleanly"

# The modes a prompt changes. Not `stty -g`: on macOS the kernel sets PENDIN
# whenever canonical mode comes back, so the saved string never matches.
_modes() { stty -a | tr ' ' '\n' | grep -xE -- '-?(echo|icanon|isig)' | tr '\n' ' '; }

_cancel='before=$(_modes); out=$(shui multiselect Pick a b); rc=$?; [[ $(_modes) == $before ]] && t=same || t=changed; print -r -- "<<rc=$rc>><<tty=$t>>"'
for _key in $'\003' q $'\e'; do
  _pty 10 40 "$_cancel" "$_HIDE" ' ' "$_key"
  assert_contains "${(q+)_key}: exits 130"         "<<rc=130>>"    "$_PTY"
  assert_contains "${(q+)_key}: tty settings back" "<<tty=same>>"  "$_PTY"
  assert_contains "${(q+)_key}: cursor shown"      "$_SHOW"        "$_PTY"
done

items=()
_pty 10 40 "$_ms" "$_HIDE" j G $'\n'
assert_not_contains "no options: never climbs a row it did not draw" $'\e[0A' "$_PTY"
assert_contains "and returns nothing" "<<rc=0>><<out=>>" "$_PTY"

# ---------------------------------------------------------------------------
# 8. password
# ---------------------------------------------------------------------------
_t_section "password"

_masked='before=$(_modes); out=$(shui password "Passphrase?"); rc=$?; [[ $(_modes) == $before ]] && t=same || t=changed; print -r -- "<<rc=$rc>><<tty=$t>><<out=$out>>"'
_pty 10 40 "$_masked" "Passphrase?" @0.3 a b $'\e[3~' $'\e[5~' $'\e[A' c $'\177' d $'\n'
assert_contains "Delete, PgUp and arrows add nothing" "<<rc=0>><<tty=same>><<out=abd>>" "$_PTY"
_pty 10 40 "$_masked" "Passphrase?" @0.3 a $'\003'
assert_contains "ctrl-c: exits 130, echo back on, no value" "<<rc=130>><<tty=same>><<out=>>" "$_PTY"

# ---------------------------------------------------------------------------
# 9. confirm
# ---------------------------------------------------------------------------
_t_section "confirm reads its default case-blind"

_cf='shui confirm "$flag" "Go?"; print -r -- "<<rc=$?>>"'
for flag want in --default=Y 0 --default=yes 0 --default=N 1 --default=y 0; do
  _pty 10 40 "flag=$flag; $_cf" "Go?" @0.3 $'\n'
  assert_contains "${flag}: enter answers ${want}" "<<rc=${want}>>" "$_PTY"
done
_pty 10 40 "flag=--default=Y; $_cf" "Go?" @0.3 $'\n'
assert_contains "--default=Y: hint shows Y as the default" "[Y/n]" "$_PTY"

# ---------------------------------------------------------------------------
# 10. tabs
# ---------------------------------------------------------------------------
_t_section "tabs in a narrow terminal"

_tb='out=$(shui tabs Pick Overview Settings$'"'\t'"'"Keys, theme, icons and a long description" Advanced Network Storage Danger); print -r -- "<<rc=$?>><<out=$out>>"'
_pty 10 34 "$_tb" "$_HIDE" $'\e[C' $'\e[C' $'\e[C' 6 $'\n'
_out=${${_PTY#*$_HIDE}%%<<rc=*}
assert_eq "no line wider than 33 columns" "1" "$(( $(_widest "$_out") <= 33 ))"
assert_eq "every redraw climbs 2 rows" "2" "$(_climbs "$_out" | tr " " "\n" | sort -u)"
assert_contains "hidden tabs stand as …" "…  ·  «Network»" "$_out"
assert_contains "returns the chosen label" "<<rc=0>><<out=Danger>>" "$_PTY"

# ---------------------------------------------------------------------------
# 11. spinner under job control
# ---------------------------------------------------------------------------
_t_section "spinner in an interactive shell"

_pty 10 60 "zsh -fic 'source ${SHUI_DIR}/shui.zsh; shui spinner Working -- sleep 0.3'" "Working"
assert_not_contains "no job-control notice" "done" "$_PTY"
assert_contains "the final line still prints" "Working"$'\n' "$_PTY"

_t_results
