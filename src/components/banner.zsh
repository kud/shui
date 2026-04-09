#!/usr/bin/env zsh

_shui_banner() {
  local type="$1"; shift
  local -a content_lines=()

  while IFS=$'\n' read -r line; do
    content_lines+=("$line")
  done <<< "$(echo -e "${*}")"

  local color icon
  case "$type" in
    warning) color="$SHUI_COLOR_WARNING"; icon="$SHUI_ICON_WARNING" ;;
    error)   color="$SHUI_COLOR_ERROR";   icon="$SHUI_ICON_ERROR"   ;;
    success) color="$SHUI_COLOR_SUCCESS"; icon="$SHUI_ICON_SUCCESS" ;;
    info|*)  color="$SHUI_COLOR_INFO";    icon="$SHUI_ICON_INFO"    ;;
  esac

  local inner=$(( _SHUI_TERMINAL_WIDTH - 8 ))
  local vis_len pad

  printf '%s┌' "$color"; _shui_repeat "─" $(( inner + 2 )); printf '┐%s\n' "$SHUI_RESET"

  local first=true
  for line in "${content_lines[@]}"; do
    vis_len=$(_shui_visible_len "$line")
    pad=$(( inner - vis_len )); [[ $pad -lt 0 ]] && pad=0

    if $first; then
      printf '%s│%s  %s %s  %s%s  %s│%s\n' \
        "$color" "$SHUI_RESET" \
        "${color}${SHUI_BOLD}${icon}${SHUI_RESET}" \
        "${SHUI_BOLD}${line}${SHUI_RESET}" \
        "$(_shui_repeat " " "$pad")" \
        "$color" "$SHUI_RESET" \
        "$SHUI_RESET"
      first=false
    else
      printf '%s│%s     %s%s  %s│%s\n' \
        "$color" "$SHUI_RESET" \
        "$line" \
        "$(_shui_repeat " " $(( pad + ${#icon} )) )" \
        "$color" "$SHUI_RESET"
    fi
  done

  printf '%s└' "$color"; _shui_repeat "─" $(( inner + 2 )); printf '┘%s\n' "$SHUI_RESET"
}
