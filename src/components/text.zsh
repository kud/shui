#!/usr/bin/env zsh

_shui_text() {
  local style="$1"; shift

  case "$style" in
    bold)      echo -e "${SHUI_BOLD}${*}${SHUI_RESET}" ;;
    dim)       echo -e "${SHUI_DIM}${*}${SHUI_RESET}" ;;
    italic)    echo -e "${SHUI_ITALIC}${*}${SHUI_RESET}" ;;
    underline) echo -e "${SHUI_UNDERLINE}${*}${SHUI_RESET}" ;;
    text)
      local color="$SHUI_COLOR_PRIMARY"
      local -a words=()

      while [[ $# -gt 0 ]]; do
        case "$1" in
          --color=*|success|error|warning|info|muted|accent|primary)
            local type="${1#--color=}"
            [[ "$1" != --color=* ]] && type="$1"
            case "$type" in
              success) color="$SHUI_COLOR_SUCCESS" ;;
              error)   color="$SHUI_COLOR_ERROR"   ;;
              warning) color="$SHUI_COLOR_WARNING" ;;
              info)    color="$SHUI_COLOR_INFO"    ;;
              muted)   color="$SHUI_COLOR_MUTED"   ;;
              accent)  color="$SHUI_COLOR_ACCENT"  ;;
              primary) color="$SHUI_COLOR_PRIMARY" ;;
            esac
            shift ;;
          *) words+=("$1"); shift ;;
        esac
      done

      echo -e "${color}${words[*]}${SHUI_RESET}" ;;
  esac
}
