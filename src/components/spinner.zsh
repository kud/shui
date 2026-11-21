#!/usr/bin/env zsh

_shui_spinner() {
  # Without these, an interactive shell's job control announced the background
  # command around the spinner: "[1] 12345" before it, "[1] + done" after.
  setopt local_options no_monitor no_notify

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

  # Each frame returns to column 0 with \r, which only reaches the start of the
  # current row: a message wider than the terminal wraps, and every frame then
  # lands a row lower. The frames show it cut to fit; the final line is whole.
  local frame_msg="$message" REPLY
  local -a reply
  if [[ -t 1 ]]; then
    _shui_tty_size
    _shui_plain "$message"
    _shui_fit "$REPLY" $(( reply[2] - 3 ))
    frame_msg="$REPLY"
  fi

  _shui_iterm_progress 3
  "$@" &
  local pid=$!
  local i=1

  while kill -0 "$pid" 2>/dev/null; do
    printf '\r%s%s%s %s' "$SHUI_COLOR_PRIMARY" "${frames[$i]}" "$SHUI_RESET" "$frame_msg"
    i=$(( (i % ${#frames[@]}) + 1 ))
    sleep 0.08
  done

  wait "$pid"
  local exit_code=$?

  printf '\r\033[K'

  if [[ $exit_code -eq 0 ]]; then
    _shui_iterm_progress 1 100
    echo -e "${SHUI_COLOR_SUCCESS}${SHUI_ICON_SUCCESS}${SHUI_RESET} ${success_msg:-${message}}"
  else
    _shui_iterm_progress 2
    echo -e "${SHUI_COLOR_ERROR}${SHUI_ICON_ERROR}${SHUI_RESET} ${fail_msg:-${message} failed}"
  fi

  _shui_iterm_progress 0
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
