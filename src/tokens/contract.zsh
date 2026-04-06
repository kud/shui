#!/usr/bin/env zsh

_SHUI_REQUIRED_TOKENS=(
  SHUI_RESET
  SHUI_BOLD
  SHUI_DIM
  SHUI_ITALIC
  SHUI_UNDERLINE

  SHUI_COLOR_PRIMARY
  SHUI_COLOR_SUCCESS
  SHUI_COLOR_WARNING
  SHUI_COLOR_ERROR
  SHUI_COLOR_INFO
  SHUI_COLOR_MUTED
  SHUI_COLOR_ACCENT

  SHUI_BG_SUCCESS
  SHUI_BG_WARNING
  SHUI_BG_ERROR
  SHUI_BG_INFO
  SHUI_BG_PRIMARY
  SHUI_BG_MUTED

  SHUI_ICON_SUCCESS
  SHUI_ICON_ERROR
  SHUI_ICON_WARNING
  SHUI_ICON_INFO
  SHUI_ICON_BULLET
  SHUI_ICON_ARROW
  SHUI_ICON_CHECK
  SHUI_ICON_CROSS
)

_shui_validate_theme() {
  local missing=()
  local token
  for token in "${_SHUI_REQUIRED_TOKENS[@]}"; do
    typeset -p "$token" &>/dev/null || missing+=("$token")
  done

  if [[ ${#missing[@]} -gt 0 ]]; then
    echo "shui: broken theme '${_SHUI_THEME}' — missing tokens:" >&2
    for t in "${missing[@]}"; do echo "  • $t" >&2; done
    return 1
  fi
}
