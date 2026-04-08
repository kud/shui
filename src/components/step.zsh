#!/usr/bin/env zsh

_SHUI_TOTAL_STEPS=0
_SHUI_CURRENT_STEP=0

_shui_step() {
  local type="$1"; shift

  case "$type" in
    set-total-steps)
      _SHUI_TOTAL_STEPS="$1"
      _SHUI_CURRENT_STEP=0
      ;;
    next-step)
      local msg="$1"
      (( _SHUI_CURRENT_STEP++ ))
      echo -e "${SHUI_COLOR_MUTED}[${_SHUI_CURRENT_STEP}/${_SHUI_TOTAL_STEPS}]${SHUI_RESET} ${SHUI_COLOR_INFO}${SHUI_ICON_ARROW}${SHUI_RESET} ${msg}"
      ;;
  esac
}
