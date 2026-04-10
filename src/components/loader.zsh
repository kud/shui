#!/usr/bin/env zsh

_shui_loader() {
  local style="dots"
  local duration=3
  local msg="Loading"

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --style=*)    style="${1#--style=}";       shift ;;
      --duration=*) duration="${1#--duration=}"; shift ;;
      *)            msg="$1";                    shift ;;
    esac
  done

  case "$style" in
    dots)
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
      ;;
    pulse)
      local end=$(( EPOCHSECONDS + duration ))
      while (( EPOCHSECONDS < end )); do
        printf '\r%s%s%s' "$SHUI_BOLD" "$msg" "$SHUI_RESET"
        sleep 0.3
        printf '\r%s%s%s' "$SHUI_DIM" "$msg" "$SHUI_RESET"
        sleep 0.3
      done
      ;;
    spinner)
      local frames=("⠋" "⠙" "⠹" "⠸" "⠼" "⠴" "⠦" "⠧" "⠇" "⠏")
      local end=$(( EPOCHSECONDS + duration ))
      local i=0
      while (( EPOCHSECONDS < end )); do
        printf '\r%s%s%s %s' "$SHUI_COLOR_INFO" "${frames[$((i % ${#frames[@]} + 1))]}" "$SHUI_RESET" "$msg"
        sleep 0.1
        (( i++ ))
      done
      ;;
  esac

  printf '\r\033[K'
}
