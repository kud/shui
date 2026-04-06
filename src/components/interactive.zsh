#!/usr/bin/env zsh

_shui_confirm() {
  local default="n"
  local prompt="Are you sure?"

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --default=*) default="${1#--default=}"; shift ;;
      *)           prompt="$1";               shift ;;
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
    "$prompt" "$hint"

  local response
  read -r response
  response="${response:-$default}"

  [[ "$response" =~ ^[yY]$ ]]
}

_shui_select() {
  local prompt="$1"; shift
  local -a options=("$@")

  echo -e "${SHUI_COLOR_INFO}${SHUI_ICON_BULLET}${SHUI_RESET} ${prompt}"

  local i=1
  for opt in "${options[@]}"; do
    echo -e "  ${SHUI_COLOR_MUTED}${i})${SHUI_RESET} ${opt}"
    (( i++ ))
  done

  printf '%s%s%s ' "$SHUI_COLOR_MUTED" "$SHUI_ICON_ARROW" "$SHUI_RESET"

  local choice
  read -r choice

  if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#options[@]} )); then
    echo "${options[$choice]}"
    return 0
  else
    echo "shui: invalid selection '${choice}'" >&2
    return 1
  fi
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
    "$prompt" "$hint"

  local value
  read -r value
  echo "${value:-$default}"
}
