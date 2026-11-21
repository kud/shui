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

  if [[ "$type" == (error|warning) ]]; then
    echo -e "${color}${icon}${SHUI_RESET} ${msg}" >&2
  else
    echo -e "${color}${icon}${SHUI_RESET} ${msg}"
  fi
}

_shui_message_dispatch() {
  local type="$1"
  shift
  case "$type" in
    success|error|warning|info|muted) _shui_message_simple "$type" "$@" ;;
    *) echo "shui: unknown message type '${type}'" >&2; return 1 ;;
  esac
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

  # Diagnostics go to stderr, so `cmd | jq` or `x=$(cmd)` never swallows a
  # failure into data. Callers that already add >&2 are unaffected.
  if [[ "$type" == (error|warning) ]]; then
    _shui_message_emit "$type" "$color" "$icon" "$msg" "$lines_before" >&2
  else
    _shui_message_emit "$type" "$color" "$icon" "$msg" "$lines_before"
  fi
}

_shui_message_emit() {
  local type="$1" color="$2" icon="$3" msg="$4" lines_before="$5" i
  for ((i=0; i<lines_before; i++)); do echo; done
  if [[ "$type" == "muted" ]]; then
    echo -e "${color}${msg}${SHUI_RESET}"
  else
    echo -e "${color}${icon}${SHUI_RESET} ${msg}"
  fi
}
