#!/usr/bin/env zsh

_shui_screen() {
  local title="$1"; shift
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

  _shui_message_simple muted "⏱ ${_time}" 1
  return $_exit
}
