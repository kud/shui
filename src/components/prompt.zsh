#!/usr/bin/env zsh

_shui_prompt() {
  local type="$1" msg="$2"

  case "$type" in
    user-prompt)
      printf '%s%s%s %s ' \
        "$SHUI_COLOR_PRIMARY" "$SHUI_ICON_PROMPT" "$SHUI_RESET" \
        "$msg"
      ;;
    input-prompt)
      printf '%s%s%s %s ' \
        "$SHUI_COLOR_INFO" "$SHUI_ICON_BULLET" "$SHUI_RESET" \
        "$msg"
      ;;
  esac
}
