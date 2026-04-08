#!/usr/bin/env zsh

_shui_iterm_progress() {
  [[ -z "$ITERM_SESSION_ID" ]] && return
  local state="${1:-0}" percent="${2:-}"
  if [[ -n "$percent" ]]; then
    printf '\033]9;4;%s;%s\a' "$state" "$percent"
  else
    printf '\033]9;4;%s\a' "$state"
  fi
}

_shui_progress() {
  local current="$1" total="$2"
  local width=40
  local label=""
  local inline=false
  local filled_char="█" empty_char="░"
  local iterm_state=""

  shift 2
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --width=*)        width="${1#--width=}";        shift ;;
      --label=*)        label="${1#--label=} ";       shift ;;
      --filled-char=*)  filled_char="${1#--filled-char=}"; shift ;;
      --empty-char=*)   empty_char="${1#--empty-char=}";   shift ;;
      --inline)         inline=true;                 shift ;;
      --iterm=*)        iterm_state="${1#--iterm=}";  shift ;;
      --iterm)          iterm_state="normal";         shift ;;
      *) shift ;;
    esac
  done

  local percentage=$(( current * 100 / total ))
  local filled=$(( current * width / total ))
  local empty=$(( width - filled ))

  local bar_filled="" bar_empty=""
  [[ $filled -gt 0 ]] && bar_filled=$(_shui_repeat "$filled_char" "$filled")
  [[ $empty  -gt 0 ]] && bar_empty=$(_shui_repeat  "$empty_char"  "$empty")

  printf '\r%s%s%s%s%s%s%s %s%d%%%s' \
    "$label" \
    "$SHUI_COLOR_PRIMARY" "$bar_filled" \
    "$SHUI_COLOR_MUTED"   "$bar_empty" \
    "$SHUI_RESET" \
    "$SHUI_COLOR_MUTED" "$SHUI_RESET" \
    "$percentage" "$SHUI_RESET"

  $inline || printf '\n'

  if [[ -n "$iterm_state" ]]; then
    case "$iterm_state" in
      normal|success) _shui_iterm_progress 1 "$percentage" ;;
      error)          _shui_iterm_progress 2 "$percentage" ;;
      indeterminate)  _shui_iterm_progress 3             ;;
      warning)        _shui_iterm_progress 4 "$percentage" ;;
      clear)          _shui_iterm_progress 0             ;;
    esac
  fi
}
