#!/usr/bin/env zsh
#
# minimal theme — clean 16-colour ANSI palette
#

source "${SHUI_DIR}/src/themes/default.zsh"

SHUI_COLOR_PRIMARY=$(_shui_sgr "0;33")
SHUI_COLOR_SUCCESS=$(_shui_sgr "0;32")
SHUI_COLOR_WARNING=$(_shui_sgr "0;33")
SHUI_COLOR_ERROR=$(_shui_sgr "0;31")
SHUI_COLOR_INFO=$(_shui_sgr "0;34")
SHUI_COLOR_MUTED=$(_shui_sgr "0;90")
SHUI_COLOR_ACCENT=$(_shui_sgr "1;33")
SHUI_COLOR_SECONDARY=$(_shui_sgr "0;37")
SHUI_COLOR_GROUP=$(_shui_sgr "0;35")
SHUI_COLOR_DANGER=$(_shui_sgr "0;31")

SHUI_COLOR_CYAN=$(_shui_sgr "0;36")
SHUI_COLOR_WHITE=$(_shui_sgr "0;37")
SHUI_COLOR_MAGENTA=$(_shui_sgr "0;35")
SHUI_COLOR_BOLD_WHITE=$(_shui_sgr "1;37")

SHUI_BG_SUCCESS=$(_shui_sgr "42")
SHUI_BG_WARNING=$(_shui_sgr "43")
SHUI_BG_ERROR=$(_shui_sgr "41")
SHUI_BG_INFO=$(_shui_sgr "44")
SHUI_BG_PRIMARY=$(_shui_sgr "43")
SHUI_BG_MUTED=$(_shui_sgr "100")
