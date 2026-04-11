#!/usr/bin/env zsh

_shui_pill() {
  local type="$1" text="$2"

  [[ -n "${NO_COLOR:-}" ]] && { printf '[%s]' "$text"; return; }

  local color_code text_color=15

  case "$type" in
    success)           color_code=46;  text_color=0  ;;
    error|danger|critical) color_code=196; text_color=15 ;;
    warning)           color_code=208; text_color=0  ;;
    info)              color_code=39;  text_color=15 ;;
    primary|major)     color_code=226; text_color=0  ;;
    accent|minor)      color_code=33;  text_color=15 ;;
    muted|default|patch) color_code=240; text_color=15 ;;
    done)              color_code=46;  text_color=0  ;;
    white|light)       color_code=255; text_color=0  ;;
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

  printf '%s' "${reset}${fg}${SHUI_ICON_PL_CAP_LEFT}${bg}${text_fg}${text}${reset}${fg}${SHUI_ICON_PL_CAP_RIGHT}${reset}"
}
