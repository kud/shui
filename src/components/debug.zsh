#!/usr/bin/env zsh

_shui_debug() {
  [[ "${SHUI_DEBUG:-}" != "true" ]] && return 0
  local msg="$1"
  echo -e "${SHUI_COLOR_MUTED}[debug]${SHUI_RESET} ${msg}" >&2
}

_shui_debug_vars() {
  [[ "${SHUI_DEBUG:-}" != "true" ]] && return 0
  local var
  for var in "$@"; do
    echo -e "${SHUI_COLOR_MUTED}[debug]${SHUI_RESET} ${SHUI_BOLD}${var}${SHUI_RESET}=${(P)var}" >&2
  done
}

_shui_debug_timing() {
  [[ "${SHUI_DEBUG:-}" != "true" ]] && return 0
  local start_epoch="$1" operation_name="$2"
  local elapsed=$(( EPOCHSECONDS - start_epoch ))
  echo -e "${SHUI_COLOR_MUTED}[debug]${SHUI_RESET} ${operation_name} took ${elapsed}s" >&2
}

_shui_debug_command() {
  [[ "${SHUI_DEBUG:-}" != "true" ]] && return 0
  echo -e "${SHUI_COLOR_MUTED}[debug]${SHUI_RESET} running: ${*}" >&2
  "$@"
}
