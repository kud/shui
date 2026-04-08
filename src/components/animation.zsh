#!/usr/bin/env zsh

_shui_animation() {
  local type="$1"; shift

  case "$type" in
    dots-loading)
      local duration=3
      local msg="Loading"
      while [[ $# -gt 0 ]]; do
        case "$1" in
          --duration=*) duration="${1#--duration=}"; shift ;;
          *)            msg="$1";                    shift ;;
        esac
      done
      local end=$(( EPOCHSECONDS + duration ))
      local i=0
      while (( EPOCHSECONDS < end )); do
        local dots=$(( (i % 3) + 1 ))
        local dot_str=""
        local d
        for ((d=0; d<dots; d++)); do dot_str+="."; done
        printf '\r%s%s%s' "$SHUI_COLOR_INFO" "${msg}${dot_str}" "$SHUI_RESET"
        sleep 0.4
        (( i++ ))
      done
      printf '\r\033[K'
      ;;
    typewriter)
      local delay=0.03
      local color="$SHUI_COLOR_PRIMARY"
      local text=""
      while [[ $# -gt 0 ]]; do
        case "$1" in
          --delay=*)
            delay="${1#--delay=}"; shift ;;
          --color=*)
            case "${1#--color=}" in
              success) color="$SHUI_COLOR_SUCCESS" ;;
              error)   color="$SHUI_COLOR_ERROR"   ;;
              warning) color="$SHUI_COLOR_WARNING" ;;
              info)    color="$SHUI_COLOR_INFO"    ;;
              muted)   color="$SHUI_COLOR_MUTED"   ;;
              accent)  color="$SHUI_COLOR_ACCENT"  ;;
              primary) color="$SHUI_COLOR_PRIMARY" ;;
            esac
            shift ;;
          *) text="$1"; shift ;;
        esac
      done
      local ch
      printf '%s' "$color"
      for ((i=1; i<=${#text}; i++)); do
        ch="${text[$i]}"
        printf '%s' "$ch"
        sleep "$delay"
      done
      printf '%s\n' "$SHUI_RESET"
      ;;
    pulse)
      local count=3
      local text=""
      while [[ $# -gt 0 ]]; do
        case "$1" in
          --count=*) count="${1#--count=}"; shift ;;
          *)         text="$1";            shift ;;
        esac
      done
      local p
      for ((p=0; p<count; p++)); do
        printf '\r%s%s%s' "$SHUI_BOLD" "$text" "$SHUI_RESET"
        sleep 0.3
        printf '\r%s%s%s' "$SHUI_DIM" "$text" "$SHUI_RESET"
        sleep 0.3
      done
      printf '\r%s\n' "$text"
      ;;
    fade-in)
      local steps=5
      local text=""
      while [[ $# -gt 0 ]]; do
        case "$1" in
          --steps=*) steps="${1#--steps=}"; shift ;;
          *)         text="$1";            shift ;;
        esac
      done
      local s
      for ((s=0; s<steps; s++)); do
        printf '\r%s%s%s' "$SHUI_DIM" "$text" "$SHUI_RESET"
        sleep 0.1
      done
      printf '\r%s\n' "$text"
      ;;
  esac
}
