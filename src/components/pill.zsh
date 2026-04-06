#!/usr/bin/env zsh

_shui_pill() {
  local type="$1" text="$2"

  [[ -n "${NO_COLOR:-}" ]] && { printf '[%s]' "$text"; return; }

  local color_code text_color=15

  case "$type" in
    success)      color_code=46;  text_color=0  ;;
    error|danger) color_code=196; text_color=15 ;;
    warning)      color_code=208; text_color=0  ;;
    info)         color_code=39;  text_color=15 ;;
    primary)      color_code=226; text_color=0  ;;
    accent)       color_code=226; text_color=0  ;;
    muted|default)color_code=240; text_color=15 ;;
    *)
      if [[ "$type" =~ ^[0-9]+$ ]] && (( type >= 0 && type <= 255 )); then
        color_code=$type
      else
        color_code=240
      fi
      ;;
  esac

  local reset=$'\e[0m'
  local bg=$'\e[48;5;'${color_code}'m'
  local fg=$'\e[38;5;'${color_code}'m'
  local text_fg=$'\e[38;5;'${text_color}'m'

  printf '%s' "${reset}${fg}▐${bg}${text_fg}${text}${reset}${fg}▌${reset}"
}
