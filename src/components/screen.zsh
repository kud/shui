#!/usr/bin/env zsh

_shui_timer_start() {
  _SHUI_TIMER_START=$SECONDS
}

_shui_timer_end() {
  local label="${1:?Usage: shui timer-end <label>}"
  local _elapsed=$(( SECONDS - ${_SHUI_TIMER_START:-$SECONDS} ))
  local _time
  if (( _elapsed < 60 )); then
    _time="${_elapsed}s"
  else
    _time="$(( _elapsed / 60 ))m $(( _elapsed % 60 ))s"
  fi
  _shui_message_simple muted "⏱ ${label} · ${_time}" 0
  unset _SHUI_TIMER_START
}

_shui_screen() {
  local title="$1" label; shift
  if [[ "$1" == "--label" ]]; then
    label="$2"; shift 2
  else
    label="$title"
  fi
  [[ "$1" == "--" ]] && shift

  local _start=$SECONDS
  _shui_layout section "$title"
  "$@"
  local _exit=$?

  local _elapsed=$(( SECONDS - _start ))
  local _time
  if (( _elapsed < 60 )); then
    _time="${_elapsed}s"
  else
    _time="$(( _elapsed / 60 ))m $(( _elapsed % 60 ))s"
  fi

  _shui_message_simple muted "⏱ ${label} · ${_time}" 1
  return $_exit
}
