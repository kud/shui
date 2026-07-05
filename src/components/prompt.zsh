#!/usr/bin/env zsh
#
# prompt component — render a labelled input prompt line
#
# Usage: _shui_prompt <mode> <message>
#   mode: user-prompt | input-prompt (selects the leading bracket icon)
#
# Prints the icon-prefixed message to stdout with no trailing newline, so a
# caller can read the response on the same line. The icon is empty in the
# 'none' set, in which case only the message is printed.

_shui_prompt() {
  local mode="$1"; shift
  local message="$*"

  local icon
  case "$mode" in
    user-prompt)  icon="$SHUI_ICON_USER_BRACKET" ;;
    input-prompt) icon="$SHUI_ICON_INPUT_BRACKET" ;;
    *)            icon="$SHUI_ICON_PROMPT" ;;
  esac

  if [[ -n "$icon" ]]; then
    printf '%s%s%s %s ' "$SHUI_COLOR_PRIMARY" "$icon" "$SHUI_RESET" "$message"
  else
    printf '%s ' "$message"
  fi
}
