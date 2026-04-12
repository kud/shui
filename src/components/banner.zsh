#!/usr/bin/env zsh

_shui_banner() {
  local type="$1"; shift
  local -a content_lines=("$@")

  local color icon
  case "$type" in
    warning) color="$SHUI_COLOR_WARNING"; icon="$SHUI_ICON_WARNING" ;;
    error)   color="$SHUI_COLOR_ERROR";   icon="$SHUI_ICON_ERROR"   ;;
    success) color="$SHUI_COLOR_SUCCESS"; icon="$SHUI_ICON_SUCCESS" ;;
    info|*)  color="$SHUI_COLOR_INFO";    icon="$SHUI_ICON_INFO"    ;;
  esac

  local bar="${color}▌${SHUI_RESET}"
  printf '\n%s\n' "$bar"
  local first=true
  for line in "${content_lines[@]}"; do
    if $first; then
      printf '%s  %s%s%s  %s\n' "$bar" "${color}${SHUI_BOLD}" "$icon" "${SHUI_RESET}" "$line"
      first=false
    else
      printf '%s     %s\n' "$bar" "$line"
    fi
  done
  printf '%s\n\n' "$bar"
}
