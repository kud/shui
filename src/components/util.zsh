#!/usr/bin/env zsh

_shui_util() {
  local type="$1"

  case "$type" in
    terminal-size)
      local width height
      width=$(tput cols 2>/dev/null || echo 80)
      height=$(tput lines 2>/dev/null || echo 24)
      printf '%sx%s\n' "$width" "$height"
      ;;
  esac
}
