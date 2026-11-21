#!/usr/bin/env zsh

_SHUI_REQUIRED_TOKENS=(
  SHUI_RESET
  SHUI_BOLD
  SHUI_DIM
  SHUI_ITALIC
  SHUI_UNDERLINE
  SHUI_STRIKETHROUGH

  SHUI_COLOR_ACCENT
  SHUI_COLOR_SUCCESS
  SHUI_COLOR_WARNING
  SHUI_COLOR_ERROR
  SHUI_COLOR_INFO
  SHUI_COLOR_MUTED
  SHUI_COLOR_SECONDARY
  SHUI_COLOR_GROUP
  SHUI_COLOR_DANGER
  SHUI_COLOR_DIM
  SHUI_COLOR_TRACK
  SHUI_COLOR_LINK
  SHUI_COLOR_ADDED
  SHUI_COLOR_REMOVED
  SHUI_COLOR_CYAN
  SHUI_COLOR_WHITE
  SHUI_COLOR_MAGENTA
  SHUI_COLOR_BOLD_WHITE

  SHUI_BG_SUCCESS
  SHUI_BG_WARNING
  SHUI_BG_ERROR
  SHUI_BG_INFO
  SHUI_BG_ACCENT
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

# Run between the theme and the contract check. Two jobs:
#
#   · A theme written before glyphs 0.5 sets PRIMARY (the orange) and ACCENT (a
#     blue that no longer exists). PRIMARY was always the accent, so it wins, and
#     tokens that theme predates are taken from @kud/glyphs rather than failing it.
#   · SHUI_COLOR_PRIMARY / SHUI_BG_PRIMARY become aliases of ACCENT. DEPRECATED:
#     kept so existing callers do not break; use SHUI_COLOR_ACCENT / SHUI_BG_ACCENT.
#
# shui.zsh unsets both PRIMARY names before sourcing the theme, so their presence
# here means the theme itself set them.
_shui_resolve_theme_aliases() {
  (( ${+SHUI_COLOR_PRIMARY} )) && SHUI_COLOR_ACCENT=$SHUI_COLOR_PRIMARY
  (( ${+SHUI_BG_PRIMARY} ))    && SHUI_BG_ACCENT=$SHUI_BG_PRIMARY

  local token name
  for token in DIM TRACK LINK ADDED REMOVED; do
    name=SHUI_COLOR_$token
    (( ${(P)+name} )) || typeset -g "$name=$(_shui_token_color $token)"
  done

  typeset -g SHUI_COLOR_PRIMARY=$SHUI_COLOR_ACCENT   # deprecated alias
  typeset -g SHUI_BG_PRIMARY=$SHUI_BG_ACCENT         # deprecated alias
}

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
