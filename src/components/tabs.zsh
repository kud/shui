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
  local prompt="$1"; shift
  local -a raw=("$@")
  local n=${#raw[@]}
  (( n == 0 )) && return 1

  # Split each arg into a label and an optional (tab-separated) description.
  local -a labels descs
  local opt
  for opt in "${raw[@]}"; do
    labels+=("${opt%%$'\t'*}")
    [[ "$opt" == *$'\t'* ]] && descs+=("${opt#*$'\t'}") || descs+=("")
  done

  local active=1

  # Two lines, always: the tab bar and a desc line (blank when the active tab
  # has none). A constant height keeps the cursor-up redraw a fixed \033[2A.
  _shui_tabs_render() {
    local bar="" i
    for (( i = 1; i <= n; i++ )); do
      (( i > 1 )) && bar+="${SHUI_COLOR_MUTED}  ·  ${SHUI_RESET}"
      if (( i == active )); then
        bar+="${SHUI_COLOR_PRIMARY}${SHUI_BOLD}«${labels[i]}»${SHUI_RESET}"
      else
        bar+="${SHUI_COLOR_MUTED}${labels[i]}${SHUI_RESET}"
      fi
    done
    printf '\033[2K\r  %s\n' "$bar"
    printf '\033[2K\r'
    [[ -n "${descs[active]}" ]] && \
      printf '  %s%s%s' "$SHUI_COLOR_SECONDARY" "${descs[active]}" "$SHUI_RESET"
    printf '\n'
  }

  printf '%s%s%s %s←→/1-9 move · enter confirm · q cancel%s\n' \
    "$SHUI_BOLD" "$prompt" "$SHUI_RESET" "$SHUI_COLOR_MUTED" "$SHUI_RESET" >&2
  _shui_tabs_render >&2

  local old_stty exit_code=0 char seq
  old_stty=$(stty -g </dev/tty 2>/dev/null) || old_stty=""
  [[ -n "$old_stty" ]] && stty -echo -icanon min 1 time 0 </dev/tty
  _shui_cursor hide-cursor >&2

  while true; do
    IFS= read -rk1 char </dev/tty
    case "$char" in
      $'\033')
        if IFS= read -rk2 -t 0.4 seq </dev/tty; then
          case "$seq" in
            '[C') active=$(( active % n + 1 )) ;;              # right — wraps
            '[D') active=$(( (active - 2 + n) % n + 1 )) ;;    # left  — wraps
            '[Z') active=$(( (active - 2 + n) % n + 1 )) ;;    # shift-tab
          esac
        else
          exit_code=130; break                                # bare esc — cancel
        fi
        ;;
      $'\t'|l) active=$(( active % n + 1 )) ;;
      h)        active=$(( (active - 2 + n) % n + 1 )) ;;
      [1-9])    (( char <= n )) && active=$char ;;
      $'\r'|$'\n') break ;;
      q|Q|$'\003') exit_code=130; break ;;
    esac
    printf '\033[2A' >&2
    _shui_tabs_render >&2
  done

  [[ -n "$old_stty" ]] && stty "$old_stty" </dev/tty
  _shui_cursor show-cursor >&2
  printf '\n' >&2

  (( exit_code == 0 )) && printf '%s\n' "${labels[active]}"
  return $exit_code
}
