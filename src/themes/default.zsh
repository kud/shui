#!/usr/bin/env zsh
#
# default theme — 256-colour with automatic 16-colour fallback
#

SHUI_RESET="\033[0m"
SHUI_BOLD="\033[1m"
SHUI_DIM="\033[2m"
SHUI_ITALIC="\033[3m"
SHUI_UNDERLINE="\033[4m"

SHUI_COLOR_PRIMARY=$(_shui_color  "38;5;226" "0;33")
SHUI_COLOR_SUCCESS=$(_shui_color  "38;5;46"  "0;32")
SHUI_COLOR_WARNING=$(_shui_color  "38;5;208" "0;33")
SHUI_COLOR_ERROR=$(_shui_color    "38;5;196" "0;31")
SHUI_COLOR_INFO=$(_shui_color     "38;5;39"  "0;34")
SHUI_COLOR_MUTED=$(_shui_color    "38;5;240" "0;90")
SHUI_COLOR_ACCENT=$(_shui_color   "38;5;226" "0;33")

SHUI_BG_SUCCESS=$(_shui_bg_color  "48;5;46"  "42")
SHUI_BG_WARNING=$(_shui_bg_color  "48;5;208" "43")
SHUI_BG_ERROR=$(_shui_bg_color    "48;5;196" "41")
SHUI_BG_INFO=$(_shui_bg_color     "48;5;39"  "44")
SHUI_BG_PRIMARY=$(_shui_bg_color  "48;5;226" "43")
SHUI_BG_MUTED=$(_shui_bg_color    "48;5;240" "100")
