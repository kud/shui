#!/usr/bin/env zsh

_shui_spinner() {
  local message="Loading…"
  local success_msg="" fail_msg=""

  while [[ "$1" != "--" && $# -gt 0 ]]; do
    case "$1" in
      --success=*) success_msg="${1#--success=}"; shift ;;
      --fail=*)    fail_msg="${1#--fail=}";       shift ;;
      *)           message="$1";                  shift ;;
    esac
  done
  [[ "$1" == "--" ]] && shift

  local -a frames=("⠋" "⠙" "⠹" "⠸" "⠼" "⠴" "⠦" "⠧" "⠇" "⠏")

  "$@" &
  local pid=$!
  local i=1

  while kill -0 "$pid" 2>/dev/null; do
    printf '\r%s%s%s %s' "$SHUI_COLOR_PRIMARY" "${frames[$i]}" "$SHUI_RESET" "$message"
    i=$(( (i % ${#frames[@]}) + 1 ))
    sleep 0.08
  done

  wait "$pid"
  local exit_code=$?

  printf '\r\033[K'

  if [[ $exit_code -eq 0 ]]; then
    echo -e "${SHUI_COLOR_SUCCESS}${SHUI_ICON_SUCCESS}${SHUI_RESET} ${success_msg:-${message}}"
  else
    echo -e "${SHUI_COLOR_ERROR}${SHUI_ICON_ERROR}${SHUI_RESET} ${fail_msg:-${message} failed}"
  fi

  return $exit_code
}

_shui_spinner_tick() {
  local frame_idx="$1" msg="$2"
  local -a frames=("⠋" "⠙" "⠹" "⠸" "⠼" "⠴" "⠦" "⠧" "⠇" "⠏")
  local idx=$(( (frame_idx % ${#frames[@]}) + 1 ))
  printf '\r%s%s%s %s' "$SHUI_COLOR_PRIMARY" "${frames[$idx]}" "$SHUI_RESET" "$msg"
}

_shui_spinner_clear() {
  printf '\r\033[K'
}
