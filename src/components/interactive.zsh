#!/usr/bin/env zsh

_shui_confirm() {
  local default="n"
  local prompt="Are you sure?"

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --default=*) default="${1#--default=}"; shift ;;
      *)           prompt="$1";              shift ;;
    esac
  done

  local hint
  if [[ "$default" == "y" ]]; then
    hint="${SHUI_COLOR_PRIMARY}Y${SHUI_RESET}/${SHUI_COLOR_MUTED}n${SHUI_RESET}"
  else
    hint="${SHUI_COLOR_MUTED}y${SHUI_RESET}/${SHUI_COLOR_PRIMARY}N${SHUI_RESET}"
  fi

  printf '%s%s%s %s [%s] ' \
    "$SHUI_COLOR_INFO" "$SHUI_ICON_INFO" "$SHUI_RESET" \
    "$prompt" "$hint" >&2

  local response
  read -r response </dev/tty
  response="${response:-$default}"

  [[ "$response" =~ ^[yY]$ ]]
}

_shui_select() {
  local prompt="$1"; shift
  local -a options=("$@")

  printf '%s%s%s %s\n' \
    "$SHUI_COLOR_INFO" "$SHUI_ICON_BULLET" "$SHUI_RESET" "$prompt" >&2

  local i=1
  for opt in "${options[@]}"; do
    printf '  %s%s)%s %s\n' "$SHUI_COLOR_MUTED" "$i" "$SHUI_RESET" "$opt" >&2
    (( i++ ))
  done

  printf '%s%s%s ' "$SHUI_COLOR_MUTED" "$SHUI_ICON_ARROW" "$SHUI_RESET" >&2

  local choice
  read -r choice </dev/tty

  if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#options[@]} )); then
    printf '%s\n' "${options[$choice]}"
    return 0
  else
    printf 'shui: invalid selection "%s"\n' "$choice" >&2
    return 1
  fi
}

_shui_radio() {
  local prompt="$1"; shift
  local -a options=("$@")
  local n=${#options[@]}
  local cursor=1

  _shui_radio_render() {
    local i label desc max_len=0 pad
    for (( i = 1; i <= n; i++ )); do
      label="${options[$i]%%$'\t'*}"
      (( ${#label} > max_len )) && max_len=${#label}
    done

    for (( i = 1; i <= n; i++ )); do
      label="${options[$i]%%$'\t'*}"
      desc="${options[$i]#*$'\t'}"
      [[ "$desc" == "$label" ]] && desc=""
      pad=$(( max_len - ${#label} + 2 ))
      printf '\033[2K\r'
      if (( i == cursor )); then
        printf '  %s%s%s %s%s%s%*s' \
          "$SHUI_COLOR_PRIMARY" "$SHUI_ICON_CIRCLE" "$SHUI_RESET" \
          "$SHUI_COLOR_PRIMARY" "$label" "$SHUI_RESET" \
          "$pad" ""
        [[ -n "$desc" ]] && printf '%s%s%s%s' "$SHUI_DIM" "$SHUI_COLOR_MUTED" "$desc" "$SHUI_RESET"
        printf '\n'
      else
        printf '  %s%s%s %s%*s' \
          "$SHUI_COLOR_MUTED" "$SHUI_ICON_CIRCLE_EMPTY" "$SHUI_RESET" \
          "$label" "$pad" ""
        [[ -n "$desc" ]] && printf '%s%s%s%s' "$SHUI_DIM" "$SHUI_COLOR_MUTED" "$desc" "$SHUI_RESET"
        printf '\n'
      fi
    done
  }

  printf '%s%s%s %s\n' \
    "$SHUI_COLOR_INFO" "$SHUI_ICON_BULLET" "$SHUI_RESET" "$prompt" >&2
  _shui_radio_render >&2

  local old_stty exit_code=0 char seq
  old_stty=$(stty -g </dev/tty 2>/dev/null) || old_stty=""
  [[ -n "$old_stty" ]] && stty -echo -icanon min 1 time 0 </dev/tty
  _shui_cursor hide-cursor >&2

  while true; do
    IFS= read -rk1 char </dev/tty
    case "$char" in
      $'\033')
        IFS= read -rk2 seq </dev/tty
        case "$seq" in
          '[A') (( cursor > 1 )) && (( cursor-- )) ;;
          '[B') (( cursor < n )) && (( cursor++ )) ;;
        esac
        ;;
      $'\r'|$'\n') break ;;
      $'\003') exit_code=130; break ;;
    esac
    printf '\033[%dA' "$n" >&2
    _shui_radio_render >&2
  done

  [[ -n "$old_stty" ]] && stty "$old_stty" </dev/tty
  _shui_cursor show-cursor >&2
  printf '\n' >&2

  (( exit_code == 0 )) && printf '%s\n' "${options[$cursor]%%$'\t'*}"
  return $exit_code
}

_shui_multiselect() {
  local prompt="$1"; shift
  local -a options=("$@")
  local n=${#options[@]}
  local cursor=1
  local -a selected
  local i
  for (( i = 1; i <= n; i++ )); do selected[$i]=0; done

  _shui_multiselect_render() {
    local i check
    for (( i = 1; i <= n; i++ )); do
      printf '\033[2K\r'
      if (( selected[$i] )); then
        check="${SHUI_COLOR_SUCCESS}${SHUI_ICON_SQUARE}${SHUI_RESET}"
      else
        check="${SHUI_COLOR_MUTED}${SHUI_ICON_SQUARE_EMPTY}${SHUI_RESET}"
      fi
      if (( i == cursor )); then
        printf '  %s %s%s%s\n' "$check" "$SHUI_COLOR_PRIMARY" "${options[$i]}" "$SHUI_RESET"
      else
        printf '  %s %s\n' "$check" "${options[$i]}"
      fi
    done
  }

  printf '%s%s%s %s %s↑↓ navigate · space toggle · enter confirm%s\n' \
    "$SHUI_COLOR_INFO" "$SHUI_ICON_BULLET" "$SHUI_RESET" \
    "$prompt" "$SHUI_COLOR_MUTED" "$SHUI_RESET" >&2
  _shui_multiselect_render >&2

  local old_stty exit_code=0 char seq
  old_stty=$(stty -g </dev/tty 2>/dev/null) || old_stty=""
  [[ -n "$old_stty" ]] && stty -echo -icanon min 1 time 0 </dev/tty
  _shui_cursor hide-cursor >&2

  while true; do
    IFS= read -rk1 char </dev/tty
    case "$char" in
      $'\033')
        IFS= read -rk2 seq </dev/tty
        case "$seq" in
          '[A') (( cursor > 1 )) && (( cursor-- )) ;;
          '[B') (( cursor < n )) && (( cursor++ )) ;;
        esac
        ;;
      ' ') (( selected[$cursor] = !selected[$cursor] )) ;;
      $'\r'|$'\n') break ;;
      $'\003') exit_code=130; break ;;
    esac
    printf '\033[%dA' "$n" >&2
    _shui_multiselect_render >&2
  done

  [[ -n "$old_stty" ]] && stty "$old_stty" </dev/tty
  _shui_cursor show-cursor >&2
  printf '\n' >&2

  if (( exit_code == 0 )); then
    for (( i = 1; i <= n; i++ )); do
      (( selected[$i] )) && printf '%s\n' "${options[$i]}"
    done
  fi
  return $exit_code
}

_shui_input() {
  local default=""
  local prompt="Input:"

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --default=*) default="${1#--default=}"; shift ;;
      *)           prompt="$1";               shift ;;
    esac
  done

  local hint=""
  [[ -n "$default" ]] && hint=" ${SHUI_COLOR_MUTED}(${default})${SHUI_RESET}"

  printf '%s%s%s %s%s ' \
    "$SHUI_COLOR_INFO" "$SHUI_ICON_BULLET" "$SHUI_RESET" \
    "$prompt" "$hint" >&2

  local value
  read -r value </dev/tty
  printf '%s\n' "${value:-$default}"
}
