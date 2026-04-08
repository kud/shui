#!/usr/bin/env zsh

_shui_cursor() {
  local type="$1"; shift

  case "$type" in
    hide-cursor)    printf '\033[?25l' ;;
    show-cursor)    printf '\033[?25h' ;;
    save-cursor)    printf '\033[s'    ;;
    restore-cursor) printf '\033[u'    ;;
    move-cursor)
      local row="$1" col="$2"
      printf '\033[%d;%dH' "$row" "$col"
      ;;
    clear-line)     printf '\r\033[K'  ;;
    cleanup)
      printf '\033[?25h'
      printf '%s' "$SHUI_RESET"
      ;;
  esac
}
