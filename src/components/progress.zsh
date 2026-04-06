#!/usr/bin/env zsh

_shui_progress() {
  local current="$1" total="$2"
  local width=40
  local label=""
  local inline=false

  shift 2
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --width=*)  width="${1#--width=}";  shift ;;
      --label=*)  label="${1#--label=} "; shift ;;
      --inline)   inline=true;            shift ;;
      *) shift ;;
    esac
  done

  local percentage=$(( current * 100 / total ))
  local filled=$(( current * width / total ))
  local empty=$(( width - filled ))

  local bar_filled="" bar_empty=""
  [[ $filled -gt 0 ]] && bar_filled=$(_shui_repeat "█" "$filled")
  [[ $empty  -gt 0 ]] && bar_empty=$(_shui_repeat  "░" "$empty")

  printf '\r%s%s%s%s%s%s%s %s%d%%%s' \
    "$label" \
    "$SHUI_COLOR_PRIMARY" "$bar_filled" \
    "$SHUI_COLOR_MUTED"   "$bar_empty" \
    "$SHUI_RESET" \
    "$SHUI_COLOR_MUTED" "$SHUI_RESET" \
    "$percentage" "$SHUI_RESET"

  $inline || printf '\n'
}
