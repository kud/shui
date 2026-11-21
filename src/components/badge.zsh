#!/usr/bin/env zsh

_shui_badge() {
  local type="$1" text="$2"

  [[ $type == warning ]] && text="$(_shui_warn_text "$text")"
  { [[ -n "${NO_COLOR:-}" ]] || (( _SHUI_COLOR_DEPTH == 0 )) } && { printf '[%s]' "$text"; return; }

  local bg fg

  # Text on each fill follows ink-ui's INK table: black on the light fills
  # (79 success, 214 warning, 117 info, 208 accent), white on 203 error and grey.
  case "$type" in
    success) bg="$SHUI_BG_SUCCESS"; fg="\033[38;5;0m"  ;;
    error)   bg="$SHUI_BG_ERROR";   fg="\033[38;5;15m" ;;
    warning) bg="$SHUI_BG_WARNING"; fg="\033[38;5;0m"  ;;
    info)    bg="$SHUI_BG_INFO";    fg="\033[38;5;0m"  ;;
    accent|primary) bg="$SHUI_BG_ACCENT"; fg="\033[38;5;0m"  ;;
    muted)   bg="$SHUI_BG_MUTED";   fg="\033[38;5;15m" ;;
    *)       bg="$SHUI_BG_MUTED";   fg="\033[38;5;15m" ;;
  esac

  printf "${bg}${fg} %s ${SHUI_RESET}" "$text"
}
