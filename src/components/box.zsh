#!/usr/bin/env zsh

_shui_box() {
  local title=""
  local -a content_lines=()

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --title=*) title="${1#--title=}"; shift ;;
      --title)   title="$2"; shift 2 ;;
      *)
        while IFS=$'\n' read -r line; do
          content_lines+=("$line")
        done <<< "$(echo -e "$1")"
        shift ;;
    esac
  done

  local inner=$(( _SHUI_TERMINAL_WIDTH - 6 ))

  if [[ -n "$title" ]]; then
    local title_len=${#title}
    local left=$(( (inner - title_len - 2) / 2 ))
    local right=$(( inner - title_len - 2 - left ))
    printf '%s' "${SHUI_COLOR_MUTED}┌"
    _shui_repeat "─" "$left"
    printf ' %s%s%s%s ' "${SHUI_COLOR_PRIMARY}${SHUI_BOLD}" "$title" "${SHUI_RESET}${SHUI_COLOR_MUTED}"
    _shui_repeat "─" "$right"
    printf '┐%s\n' "${SHUI_RESET}"
  else
    printf '%s' "${SHUI_COLOR_MUTED}┌"
    _shui_repeat "─" $(( inner + 2 ))
    printf '┐%s\n' "${SHUI_RESET}"
  fi

  local vis_len pad
  for line in "${content_lines[@]}"; do
    vis_len=$(_shui_visible_len "$line")
    pad=$(( inner - vis_len ))
    [[ $pad -lt 0 ]] && pad=0
    printf '%s' "${SHUI_COLOR_MUTED}│${SHUI_RESET}  ${line}"
    _shui_repeat " " "$pad"
    printf '  %s\n' "${SHUI_COLOR_MUTED}│${SHUI_RESET}"
  done

  printf '%s' "${SHUI_COLOR_MUTED}└"
  _shui_repeat "─" $(( inner + 2 ))
  printf '┘%s\n' "${SHUI_RESET}"
}
