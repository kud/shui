#!/usr/bin/env zsh

_shui_badge() {
  local type="$1" text="$2"

  [[ -n "${NO_COLOR:-}" ]] && { printf '[%s]' "$text"; return; }

  local bg fg

  case "$type" in
    success) bg="$SHUI_BG_SUCCESS"; fg="\033[38;5;0m"  ;;
    error)   bg="$SHUI_BG_ERROR";   fg="\033[38;5;15m" ;;
    warning) bg="$SHUI_BG_WARNING"; fg="\033[38;5;0m"  ;;
    info)    bg="$SHUI_BG_INFO";    fg="\033[38;5;15m" ;;
    primary) bg="$SHUI_BG_PRIMARY"; fg="\033[38;5;0m"  ;;
    muted)   bg="$SHUI_BG_MUTED";   fg="\033[38;5;15m" ;;
    *)       bg="$SHUI_BG_MUTED";   fg="\033[38;5;15m" ;;
  esac

  printf "${bg}${fg} %s ${SHUI_RESET}" "$text"
}
