#!/usr/bin/env zsh

_shui_title() {
  local type="$1"; shift

  case "$type" in
    title)
      echo -e "\n${SHUI_BOLD}${SHUI_COLOR_ACCENT}${*}${SHUI_RESET}\n"
      ;;
    title-action)
      local action="$1" target="$2"
      echo -e "\n${SHUI_BOLD}${SHUI_COLOR_ACCENT}${action}${SHUI_RESET} ${SHUI_BOLD}${target}${SHUI_RESET}\n"
      ;;
    title-install)
      local target="$1"
      echo -e "\n${SHUI_BOLD}${SHUI_COLOR_ACCENT}${SHUI_ICON_INSTALL}${SHUI_RESET} ${SHUI_BOLD}Installing ${target}${SHUI_RESET}\n"
      ;;
    title-update)
      local target="$1"
      echo -e "\n${SHUI_BOLD}${SHUI_COLOR_ACCENT}${SHUI_ICON_REFRESH}${SHUI_RESET} ${SHUI_BOLD}Updating ${target}${SHUI_RESET}\n"
      ;;
  esac
}
