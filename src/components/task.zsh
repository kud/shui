#!/usr/bin/env zsh

_shui_task() {
  local type="$1" msg="$2"

  case "$type" in
    task-start)
      echo -e "${SHUI_COLOR_INFO}${SHUI_ICON_ARROW}${SHUI_RESET} ${msg}"
      ;;
    task-done)
      echo -e "${SHUI_COLOR_SUCCESS}${SHUI_ICON_SUCCESS}${SHUI_RESET} ${msg}"
      ;;
    final-success)
      local width="$_SHUI_TERMINAL_WIDTH"
      printf '%s' "${SHUI_COLOR_SUCCESS}"
      _shui_repeat "─" "$width"
      printf '%s\n' "${SHUI_RESET}"
      echo -e "${SHUI_COLOR_SUCCESS}${SHUI_BOLD}  ${SHUI_ICON_SUCCESS}  ${msg}${SHUI_RESET}"
      printf '%s' "${SHUI_COLOR_SUCCESS}"
      _shui_repeat "─" "$width"
      printf '%s\n' "${SHUI_RESET}"
      ;;
    final-fail)
      local width="$_SHUI_TERMINAL_WIDTH"
      printf '%s' "${SHUI_COLOR_ERROR}"
      _shui_repeat "─" "$width"
      printf '%s\n' "${SHUI_RESET}"
      echo -e "${SHUI_COLOR_ERROR}${SHUI_BOLD}  ${SHUI_ICON_ERROR}  ${msg}${SHUI_RESET}"
      printf '%s' "${SHUI_COLOR_ERROR}"
      _shui_repeat "─" "$width"
      printf '%s\n' "${SHUI_RESET}"
      ;;
  esac
}
