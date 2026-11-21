#!/usr/bin/env zsh
#
# minimal theme — clean 16-colour ANSI palette
#

source "${SHUI_DIR}/src/themes/default.zsh"

# The ANSI16 floor of each @kud/glyphs token, on every terminal.
SHUI_COLOR_ACCENT=$(_shui_token_color16    ACCENT)
SHUI_COLOR_SUCCESS=$(_shui_token_color16   SUCCESS)
SHUI_COLOR_WARNING=$(_shui_token_color16   WARNING)
SHUI_COLOR_ERROR=$(_shui_token_color16     ERROR)
SHUI_COLOR_INFO=$(_shui_token_color16      INFO)
SHUI_COLOR_MUTED=$(_shui_token_color16     MUTED)
SHUI_COLOR_GROUP=$(_shui_token_color16     GROUP)
SHUI_COLOR_SECONDARY=$(_shui_token_color16 SECONDARY)
SHUI_COLOR_DIM=$(_shui_token_color16       DIM)
SHUI_COLOR_TRACK=$(_shui_token_color16     TRACK)
SHUI_COLOR_LINK=$(_shui_token_color16      LINK)
SHUI_COLOR_ADDED=$(_shui_token_color16     ADDED)
SHUI_COLOR_REMOVED=$(_shui_token_color16   REMOVED)
SHUI_COLOR_DANGER=$SHUI_COLOR_ERROR

SHUI_COLOR_CYAN=$(_shui_sgr "0;36")
SHUI_COLOR_WHITE=$(_shui_sgr "0;37")
SHUI_COLOR_MAGENTA=$(_shui_sgr "0;35")
SHUI_COLOR_BOLD_WHITE=$(_shui_sgr "1;37")

SHUI_BG_SUCCESS=$(_shui_token_color16 SUCCESS bg)
SHUI_BG_WARNING=$(_shui_token_color16 WARNING bg)
SHUI_BG_ERROR=$(_shui_token_color16   ERROR   bg)
SHUI_BG_INFO=$(_shui_token_color16    INFO    bg)
SHUI_BG_ACCENT=$(_shui_token_color16  ACCENT  bg)
SHUI_BG_MUTED=$(_shui_sgr "100")
