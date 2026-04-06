#!/usr/bin/env zsh

_shui_table() {
  [[ $# -eq 0 ]] && return

  local sep="|"
  local -a data_rows=()

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --sep=*) sep="${1#--sep=}"; shift ;;
      *)       data_rows+=("$1"); shift ;;
    esac
  done

  local -a col_widths cols
  local num_cols=0 row col len i dashes

  for row in "${data_rows[@]}"; do
    IFS="$sep" read -rA cols <<< "$row"
    i=1
    for col in "${cols[@]}"; do
      len=$(_shui_visible_len "$col")
      [[ ${col_widths[$i]:-0} -lt $len ]] && col_widths[$i]=$len
      (( i++ ))
    done
    [[ ${#cols[@]} -gt $num_cols ]] && num_cols=${#cols[@]}
  done

  local top_sep="┌" mid_sep="├" bot_sep="└"
  for ((i=1; i<=num_cols; i++)); do
    dashes=$(_shui_repeat "─" $(( col_widths[$i] + 2 )))
    top_sep+="${dashes}"
    mid_sep+="${dashes}"
    bot_sep+="${dashes}"
    if (( i < num_cols )); then
      top_sep+="┬"; mid_sep+="┼"; bot_sep+="┴"
    else
      top_sep+="┐"; mid_sep+="┤"; bot_sep+="┘"
    fi
  done

  echo -e "${SHUI_COLOR_MUTED}${top_sep}${SHUI_RESET}"

  local is_header=true vis_len pad
  for row in "${data_rows[@]}"; do
    IFS="$sep" read -rA cols <<< "$row"

    printf '%s' "${SHUI_COLOR_MUTED}│${SHUI_RESET}"
    for ((i=1; i<=num_cols; i++)); do
      col="${cols[$i]:-}"
      vis_len=$(_shui_visible_len "$col")
      pad=$(( col_widths[$i] - vis_len ))

      if $is_header; then
        printf ' %s%s%s' "${SHUI_BOLD}" "$col" "${SHUI_RESET}"
      else
        printf ' %s' "$col"
      fi
      _shui_repeat " " "$pad"
      printf ' %s' "${SHUI_COLOR_MUTED}│${SHUI_RESET}"
    done
    printf '\n'

    if $is_header; then
      echo -e "${SHUI_COLOR_MUTED}${mid_sep}${SHUI_RESET}"
      is_header=false
    fi
  done

  echo -e "${SHUI_COLOR_MUTED}${bot_sep}${SHUI_RESET}"
}
