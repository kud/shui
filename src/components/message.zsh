#!/usr/bin/env zsh

_shui_message() {
  local type="$1" msg="$2"
  local icon color

  case "$type" in
    success) icon="$SHUI_ICON_SUCCESS" color="$SHUI_COLOR_SUCCESS" ;;
    error)   icon="$SHUI_ICON_ERROR"   color="$SHUI_COLOR_ERROR"   ;;
    warning) icon="$SHUI_ICON_WARNING" color="$SHUI_COLOR_WARNING" ;;
    info)    icon="$SHUI_ICON_INFO"    color="$SHUI_COLOR_INFO"    ;;
  esac

  echo -e "${color}${icon}${SHUI_RESET} ${msg}"
}

_shui_message_simple() {
  local type="$1" msg="$2" lines_before="${3:-0}"
  local icon color

  case "$type" in
    success) icon="$SHUI_ICON_SUCCESS" color="$SHUI_COLOR_SUCCESS" ;;
    error)   icon="$SHUI_ICON_ERROR"   color="$SHUI_COLOR_ERROR"   ;;
    warning) icon="$SHUI_ICON_WARNING" color="$SHUI_COLOR_WARNING" ;;
    info)    icon="$SHUI_ICON_INFO"    color="$SHUI_COLOR_INFO"    ;;
    muted)   icon=""                    color="$SHUI_COLOR_MUTED"   ;;
  esac

  local i
  for ((i=0; i<lines_before; i++)); do echo; done
  if [[ "$type" == "muted" ]]; then
    echo -e "${SHUI_ITALIC}${color}${msg}${SHUI_RESET}"
  else
    echo -e "${color}${icon}${SHUI_RESET} ${msg}"
  fi
}
