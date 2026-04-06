#!/usr/bin/env zsh

_SHUI_COLOR_DEPTH=$(tput colors 2>/dev/null || echo 8)
_SHUI_TERMINAL_WIDTH=$(tput cols 2>/dev/null || echo 80)

_shui_color() {
  local c256="$1" c16="$2"
  [[ $_SHUI_COLOR_DEPTH -ge 256 ]] && printf '\033[%sm' "$c256" || printf '\033[%sm' "$c16"
}

_shui_bg_color() {
  local c256="$1" c16="$2"
  [[ $_SHUI_COLOR_DEPTH -ge 256 ]] && printf '\033[%sm' "$c256" || printf '\033[%sm' "$c16"
}

_shui_repeat() {
  local char="$1" count="$2" result=""
  local i
  for ((i=0; i<count; i++)); do result+="$char"; done
  printf '%s' "$result"
}

_shui_visible_len() {
  echo -n "$1" | sed 's/\x1b\[[0-9;]*[mK]//g' | wc -c | tr -d ' '
}
