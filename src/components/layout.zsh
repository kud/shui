#!/usr/bin/env zsh

_shui_layout() {
  local type="$1"; shift

  case "$type" in
    section)
      echo -e "\n${SHUI_BOLD}${SHUI_COLOR_PRIMARY}${*}${SHUI_RESET}"
      ;;
    subtitle)
      echo -e "\n${SHUI_COLOR_WARNING}${SHUI_BOLD}${*}${SHUI_RESET}"
      ;;
    subsection)
      echo -e "${SHUI_COLOR_ACCENT}${SHUI_BOLD}${SHUI_ICON_BULLET} ${*}${SHUI_RESET}"
      ;;
    divider)
      local char="─" width="$_SHUI_TERMINAL_WIDTH" color="$SHUI_COLOR_MUTED"
      while [[ $# -gt 0 ]]; do
        case "$1" in
          --char=*)  char="${1#--char=}";  shift ;;
          --width=*) width="${1#--width=}"; shift ;;
          --color=*)
            case "${1#--color=}" in
              success) color="$SHUI_COLOR_SUCCESS" ;;
              error)   color="$SHUI_COLOR_ERROR"   ;;
              warning) color="$SHUI_COLOR_WARNING" ;;
              info)    color="$SHUI_COLOR_INFO"    ;;
              primary) color="$SHUI_COLOR_PRIMARY" ;;
              accent)  color="$SHUI_COLOR_ACCENT"  ;;
              muted)   color="$SHUI_COLOR_MUTED"   ;;
            esac
            shift ;;
          *) shift ;;
        esac
      done
      printf '%s' "$color"
      _shui_repeat "$char" "$width"
      printf '%s\n' "${SHUI_RESET}"
      ;;
    hr)
      printf '%s' "${SHUI_COLOR_PRIMARY}"
      _shui_repeat "─" 40
      printf '%s\n' "${SHUI_RESET}"
      ;;
    fence)
      local label="${1:-}" char="─" color="$SHUI_COLOR_MUTED"
      if [[ -n "$label" ]]; then
        local prefix="── ${label} "
        local prefix_len=$(( ${#label} + 4 ))
        local trail_len=$(( _SHUI_TERMINAL_WIDTH - prefix_len ))
        [[ $trail_len -lt 2 ]] && trail_len=2
        printf '%s%s%s%s\n' "$color" "$prefix" "$(_shui_repeat "$char" $trail_len)" "$SHUI_RESET"
      else
        printf '%s' "$color"
        _shui_repeat "$char" "$_SHUI_TERMINAL_WIDTH"
        printf '%s\n' "$SHUI_RESET"
      fi
      ;;
    spacer)
      local n="${1:-1}"
      for ((i=0; i<n; i++)); do echo; done
      ;;
    center-text)
      local text="$1" width="${2:-$_SHUI_TERMINAL_WIDTH}"
      if [[ "$2" == --width=* ]]; then width="${2#--width=}"; fi
      local text_len=$(_shui_visible_len "$text")
      local pad=$(( (width - text_len) / 2 ))
      [[ $pad -lt 0 ]] && pad=0
      _shui_repeat " " "$pad"
      printf '%s\n' "$text"
      ;;
  esac
}
