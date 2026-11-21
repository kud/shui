#!/usr/bin/env zsh
#
# shui tabs — a live horizontal tab bar. Tabs render as a single row; the
# highlight moves live as you press ←/→ (or h/l, or Tab/Shift-Tab), number keys
# 1-9 jump straight to a tab, enter confirms, q/esc cancels. Prints the chosen
# tab's label to stdout.
#
# Each argument is a tab label, optionally "label⇥desc" (tab-separated) — the
# active tab's desc, when given, renders as a muted line beneath the bar:
#
#   picked=$(shui tabs "Config" \
#     "Overview" \
#     "Settings"$'\t'"Keys, theme, icons" \
#     "Advanced"$'\t'"Danger zone")
#
# Prompt + rendering go to stderr so the printed result stays capturable,
# matching shui radio/select.
_shui_tabs() {
  emulate -L zsh
  local prompt="$1"; shift
  local -a raw=("$@")
  local n=${#raw[@]}
  (( n == 0 )) && return 1
  # Same refusal as every prompt in interactive.zsh: no terminal, no answer.
  _shui_require_tty || return 2

  # Split each arg into a label and an optional (tab-separated) description.
  # labels are what the caller gets back; shown and descs are what is drawn,
  # escape and control characters already made harmless (see _shui_plain).
  local -a labels shown descs drawn
  local opt REPLY
  for opt in "${raw[@]}"; do
    labels+=("${opt%%$'\t'*}")
    _shui_plain "${opt%%$'\t'*}"
    shown+=("$REPLY")
    if [[ "$opt" == *$'\t'* ]]; then
      _shui_plain "${opt#*$'\t'}"
      descs+=("$REPLY")
    else
      descs+=("")
    fi
  done

  local active=1

  # Two lines, always: the tab bar and a desc line (blank when the active tab
  # has none). Each is cut to the terminal's width, so a constant height keeps
  # the cursor-up redraw a fixed \033[2A until a narrower window reflows them.
  # A bar too wide for the terminal shows the tabs around the active one, with
  # "…" standing for the rest.
  _shui_tabs_render() {
    local -a reply
    local REPLY bar="" label sep="  ·  "
    local -i cols limit used lo hi i grew reserve label_room
    _shui_tty_size
    cols=${reply[2]}
    limit=$(( cols - 1 ))

    if (( ${#drawn} )); then
      _shui_rows_drawn $cols "${drawn[@]}"
      printf '\033[%dA' "$REPLY"
    fi

    lo=$active hi=$active
    used=$(( 2 + ${(m)#shown[active]} + 2 ))
    grew=1
    local -i whole=$(( 2 + 2 + 5 * (n - 1) ))
    for (( i = 1; i <= n; i++ )); do (( whole += ${(m)#shown[i]} )); done
    (( whole <= limit )) && { lo=1 hi=$n used=$whole grew=0; }
    while (( grew )); do
      grew=0
      if (( hi < n )); then
        reserve=$(( (lo > 1 ? 6 : 0) + (hi + 1 < n ? 6 : 0) ))
        if (( used + 5 + ${(m)#shown[hi+1]} + reserve <= limit )); then
          (( used += 5 + ${(m)#shown[hi+1]} ))
          (( hi++ ))
          grew=1
        fi
      fi
      if (( lo > 1 )); then
        reserve=$(( (lo - 1 > 1 ? 6 : 0) + (hi < n ? 6 : 0) ))
        if (( used + 5 + ${(m)#shown[lo-1]} + reserve <= limit )); then
          (( used += 5 + ${(m)#shown[lo-1]} ))
          (( lo-- ))
          grew=1
        fi
      fi
    done
    reserve=$(( (lo > 1 ? 6 : 0) + (hi < n ? 6 : 0) ))
    (( used += reserve ))

    label="${shown[active]}"
    if (( used > limit )); then
      label_room=$(( ${(m)#label} - (used - limit) ))
      _shui_fit "$label" $(( label_room > 1 ? label_room : 1 ))
      label="$REPLY"
      used=$(( 2 + 2 + ${(m)#label} + reserve ))
    fi

    (( lo > 1 )) && bar+="${SHUI_COLOR_MUTED}…${sep}${SHUI_RESET}"
    for (( i = lo; i <= hi; i++ )); do
      (( i > lo )) && bar+="${SHUI_COLOR_MUTED}${sep}${SHUI_RESET}"
      if (( i == active )); then
        bar+="${SHUI_COLOR_ACCENT}${SHUI_BOLD}«${label}»${SHUI_RESET}"
      else
        bar+="${SHUI_COLOR_MUTED}${shown[i]}${SHUI_RESET}"
      fi
    done
    (( hi < n )) && bar+="${SHUI_COLOR_MUTED}${sep}…${SHUI_RESET}"

    printf '\033[2K\r  %s\n' "$bar"
    drawn=($used 0)
    printf '\033[2K\r'
    if [[ -n "${descs[active]}" ]]; then
      _shui_fit "${descs[active]}" $(( limit - 2 ))
      printf '  %s%s%s' "$SHUI_COLOR_SECONDARY" "$REPLY" "$SHUI_RESET"
      drawn[2]=$(( 2 + ${(m)#REPLY} ))
    fi
    printf '\n'
  }

  printf '%s%s%s %s←→/1-9 move · enter confirm · q cancel%s\n' \
    "$SHUI_BOLD" "$prompt" "$SHUI_RESET" "$SHUI_COLOR_MUTED" "$SHUI_RESET" >&2
  _shui_tabs_render >&2

  # stdout on /dev/null, never /dev/tty: see the note in interactive.zsh. The
  # stty warning it avoids shifts every redraw down a row. -isig makes ctrl-c a
  # keypress, for the same reason as there.
  local old_stty exit_code=0
  old_stty=$(stty -g </dev/tty 2>/dev/null) || old_stty=""
  [[ -n "$old_stty" ]] && stty -echo -icanon -isig min 1 time 0 </dev/tty >/dev/null
  _shui_cursor hide-cursor >&2

  while true; do
    if ! _shui_read_key; then
      exit_code=2
      break
    fi
    case "$REPLY" in
      right|$'\t'|l)    active=$(( active % n + 1 )) ;;              # wraps
      left|backtab|h)   active=$(( (active - 2 + n) % n + 1 )) ;;    # wraps
      [1-9])            (( REPLY <= n )) && active=$REPLY ;;
      enter)            break ;;
      esc|q|Q|$'\003')  exit_code=130; break ;;
    esac
    _shui_tabs_render >&2
  done

  [[ -n "$old_stty" ]] && stty "$old_stty" </dev/tty >/dev/null
  _shui_cursor show-cursor >&2
  printf '\n' >&2

  (( exit_code == 0 )) && printf '%s\n' "${labels[active]}"
  return $exit_code
}
