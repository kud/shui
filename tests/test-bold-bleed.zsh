#!/usr/bin/env zsh
#
# Bold never leaks past a styled span.
#
# The 16-colour themes used to write every colour as "0;3x": a full reset glued
# to the hue. That reset also cancelled the bold a component had just asked
# for (`title` is BOLD then the accent, so minimal titles came out thin), so
# the themes now emit the bare hue. That is safe only while every styled span
# closes with SHUI_RESET; this suite holds that line.
#
# A leak is a new colour starting while bold is still on from an EARLIER span —
# one that already printed text. BOLD-then-colour with nothing between them is
# a single span (bold accent) and is fine. Every line must also end with no
# attribute left on.
# Run: zsh tests/test-bold-bleed.zsh
#

SHUI_DIR="${0:A:h}/.."
source "${0:A:h}/_harness.zsh"

_t_title "test-bold-bleed"

# Prints nothing when clean, else a description of the first leak.
_bleed_check() {  # _bleed_check <rendered output>
  emulate -L zsh
  setopt extended_glob
  local s=$1 params p
  local -i bold=0 colour=0 printed=0   # printed: text since bold was switched on
  local -i lineno=1
  while [[ -n $s ]]; do
    if [[ $s == (#b)$'\e['([0-9\;]#)m* ]]; then
      params=${match[1]:-0}
      s=${s#$'\e['${match[1]}m}
      local -a ps=(${(s:;:)params})
      local -i i=1
      while (( i <= $#ps )); do
        p=${ps[i]}
        case $p in
          0|'')  bold=0 colour=0 ;;
          1)     bold=1 printed=0 ;;
          22)    bold=0 ;;
          39)    colour=0 ;;
          3[0-7]|9[0-7]|38)
            if (( bold && printed )); then
              print -r -- "line $lineno: bold from an earlier span carries into a new colour"
              return
            fi
            colour=1
            [[ $p == 38 ]] && (( i += 2 ))
            ;;
        esac
        (( i++ ))
      done
    elif [[ $s == $'\e'* ]]; then
      s=${s#?}                                   # other escapes (OSC, cursor)
    else
      if [[ ${s[1]} == $'\n' ]]; then
        if (( bold )); then
          print -r -- "line $lineno: bold still on at end of line"
          return
        fi
        (( lineno++ ))
      elif [[ ${s[1]} != ' ' ]]; then
        printed=1
      fi
      s=${s[2,-1]}
    fi
  done
  (( bold )) && print -r -- "end of output: bold still on"
}

_t_section "the checker itself can fail"

assert_eq "clean span"            ""  "$(_bleed_check $'\e[1m\e[33mT\e[0m\n')"
assert_eq "bold accent is one span" "" "$(_bleed_check $'\e[33m\e[1mT\e[0m \e[2mx\e[0m\n')"
assert_not_empty "bold carried into the next colour" \
  "$(_bleed_check $'\e[1mA \e[33mB\e[0m\n')"
assert_not_empty "bold left on at end of line" \
  "$(_bleed_check $'\e[1mA\n')"

_t_section "no component leaks bold"

_CALLS=(
  'shui title T'
  'shui title-action Deploy app'
  'shui title-install pkg'
  'shui title-update pkg'
  'shui section S'
  'shui subtitle S'
  'shui subsection S'
  'shui success m'
  'shui warning m'
  'shui error m'
  'shui info m'
  'shui muted m'
  'shui text accent t'
  'shui text warning t'
  'shui bold b'
  'shui badge warning b'
  'shui badge info b'
  'shui banner warning title body'
  'shui box --title=T content'
  'shui fence label --color=warning'
  'shui fence label --color=accent'
  'shui row warning tag NAME detail'
  'shui row success tag NAME detail'
  'shui table "A|B" "1|2"'
  'shui progress 3 10 --width=10 --label=L'
  'shui task-done done'
  'shui final-success ok'
  'shui final-fail no'
  'shui help'
)

for _theme in default minimal; do
  for _term in xterm-256color xterm; do
    for _call in "${_CALLS[@]}"; do
      _out=$(env FORCE_COLOR=1 SHUI_ICONS=none SHUI_THEME=$_theme TERM=$_term zsh -fc \
        "source '${SHUI_DIR}/shui.zsh' || exit 1; $_call" 2>&1)
      assert_eq "$_theme/$_term: ${_call#shui }" "" "$(_bleed_check "$_out")"
    done
  done
done

_t_results
