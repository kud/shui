#!/usr/bin/env zsh
#
# shui tabs — an interactive tabbed selector. Items are grouped into tabs shown as
# a horizontal bar; ←/→ (or h/l) switch tabs, ↑/↓ (or j/k) move within the active
# tab, enter selects, q/esc cancels. Prints the chosen item's label to stdout.
#
# Each option is three tab-separated fields — tab, label, desc (desc optional):
#
#   selected=$(shui tabs "ambre ›" \
#     "setup"$'\t'"install"$'\t'"Set up the environment" \
#     "setup"$'\t'"update"$'\t'"Refresh everything" \
#     "data"$'\t'"env"$'\t'"Env vars ↔ KeePass")
#
# Tabs appear in first-seen order. Prompts + rendering go to stderr so the printed
# result stays capturable, matching shui radio/select.

_shui_tabs() {
  local prompt="$1"; shift
  local -a raw=("$@")

  # Ordered, de-duplicated tab list (first-seen order).
  local -a tabs=()
  typeset -A _seen
  local opt tab
  for opt in "${raw[@]}"; do
    tab="${opt%%$'\t'*}"
    [[ -n "${_seen[$tab]}" ]] || { _seen[$tab]=1; tabs+=("$tab"); }
  done
  local ntabs=${#tabs[@]}
  (( ntabs == 0 )) && return 1

  # label<TAB>desc lines for the tab at index $1.
  _shui_tabs_items() {
    local _t="${tabs[$1]}" _o
    for _o in "${raw[@]}"; do
      [[ "${_o%%$'\t'*}" == "$_t" ]] && printf '%s\n' "${_o#*$'\t'}"
    done
  }

  local active=1 cursor=1 _tabs_lines=0

  _shui_tabs_render() {
    local -a items=("${(@f)$(_shui_tabs_items $active)}")
    items=("${(@)items:#}")
    local nitems=${#items[@]}

    # Tab bar — active tab bracketed + primary, others muted.
    local bar="" t
    for (( t = 1; t <= ntabs; t++ )); do
      if (( t == active )); then
        bar+="  ${SHUI_COLOR_PRIMARY}${SHUI_BOLD}[${tabs[t]}]${SHUI_RESET}"
      else
        bar+="  ${SHUI_COLOR_MUTED} ${tabs[t]} ${SHUI_RESET}"
      fi
    done
    printf '\033[2K\r%s\n' "$bar"

    # Items of the active tab — a radio-style list.
    local pointer="$SHUI_ICON_POINTER" _blank_src=""
    local blank="${(l:${#pointer}:)_blank_src}"
    local i label desc max_len=0 pad
    for (( i = 1; i <= nitems; i++ )); do
      label="${items[$i]%%$'\t'*}"
      (( ${#label} > max_len )) && max_len=${#label}
    done
    for (( i = 1; i <= nitems; i++ )); do
      label="${items[$i]%%$'\t'*}"
      desc="${items[$i]#*$'\t'}"; [[ "$desc" == "$label" ]] && desc=""
      pad=$(( max_len - ${#label} + 2 ))
      printf '\033[2K\r'
      if (( i == cursor )); then
        printf '  %s%s%s %s%s%s%*s' \
          "$SHUI_COLOR_PRIMARY" "$pointer" "$SHUI_RESET" \
          "$SHUI_COLOR_PRIMARY" "$label" "$SHUI_RESET" "$pad" ""
      else
        printf '  %s %s%*s' "$blank" "$label" "$pad" ""
      fi
      [[ -n "$desc" ]] && printf '%s%s%s' "$SHUI_COLOR_SECONDARY" "$desc" "$SHUI_RESET"
      printf '\n'
    done
    printf '\033[J'            # wipe leftover lines (a shorter tab shrinks the list)
    _tabs_lines=$(( 1 + nitems ))
  }

  printf '%s%s%s %s←→ tabs · ↑↓ move · enter select · q cancel%s\n' \
    "$SHUI_BOLD" "$prompt" "$SHUI_RESET" "$SHUI_COLOR_MUTED" "$SHUI_RESET" >&2
  _shui_tabs_render >&2

  local old_stty exit_code=0 char seq nitems
  old_stty=$(stty -g </dev/tty 2>/dev/null) || old_stty=""
  [[ -n "$old_stty" ]] && stty -echo -icanon min 1 time 0 </dev/tty
  _shui_cursor hide-cursor >&2

  while true; do
    nitems=$(_shui_tabs_items $active | grep -c .)
    IFS= read -rk1 char </dev/tty
    case "$char" in
      $'\033')
        if IFS= read -rk2 -t 0.4 seq </dev/tty; then
          case "$seq" in
            '[A') (( cursor > 1 )) && (( cursor-- )) ;;
            '[B') (( cursor < nitems )) && (( cursor++ )) ;;
            '[C') (( active < ntabs )) && { (( active++ )); cursor=1 } ;;
            '[D') (( active > 1 ))     && { (( active-- )); cursor=1 } ;;
          esac
        else
          exit_code=130; break
        fi
        ;;
      l) (( active < ntabs )) && { (( active++ )); cursor=1 } ;;
      h) (( active > 1 ))     && { (( active-- )); cursor=1 } ;;
      j) (( cursor < nitems )) && (( cursor++ )) ;;
      k) (( cursor > 1 ))      && (( cursor-- )) ;;
      $'\r'|$'\n') break ;;
      q|Q|$'\003') exit_code=130; break ;;
    esac
    printf '\033[%dA' "$_tabs_lines" >&2
    _shui_tabs_render >&2
  done

  [[ -n "$old_stty" ]] && stty "$old_stty" </dev/tty
  _shui_cursor show-cursor >&2
  printf '\n' >&2

  if (( exit_code == 0 )); then
    local -a items=("${(@f)$(_shui_tabs_items $active)}")
    items=("${(@)items:#}")
    printf '%s\n' "${items[$cursor]%%$'\t'*}"
  fi
  return $exit_code
}
