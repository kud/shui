#!/usr/bin/env zsh

_shui_layout() {
  local type="$1"; shift

  case "$type" in
    section)
      echo -e "\n${SHUI_BOLD}${SHUI_COLOR_PRIMARY}${*}${SHUI_RESET}"
      ;;
    subtitle)
      echo -e "\n${SHUI_COLOR_PRIMARY}${SHUI_ICON_ARROW}${SHUI_RESET} ${SHUI_BOLD}${*}${SHUI_RESET}"
      ;;
    subsection)
      echo -e "  ${SHUI_COLOR_ACCENT}${SHUI_ICON_BULLET}${SHUI_RESET} ${*}"
      ;;
    divider)
      local width="${1:-$_SHUI_TERMINAL_WIDTH}"
      printf '%s' "${SHUI_COLOR_MUTED}"
      _shui_repeat "─" "$width"
      printf '%s\n' "${SHUI_RESET}"
      ;;
    spacer)
      local n="${1:-1}"
      for ((i=0; i<n; i++)); do echo; done
      ;;
  esac
}
