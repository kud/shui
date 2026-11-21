#!/usr/bin/env zsh
#
# default theme — the same values as @kud/ink-ui's `tokens.ts`, not a translation
# of them. ink-ui names its semantic colours with ANSI names (`green`, `yellow`,
# `cyan`, `gray`, `magenta`) so they follow the terminal's own palette; the two
# it fixes by hex (`accent` #FF8C00, `secondary` #999999) are measured steps and
# take the nearest 256-colour cell. Muted is SGR 2, exactly what ink-ui's
# `dimColor` emits: it dims whatever the foreground is, where a fixed grey reads
# as body text on a light theme and drops below the floor on a very dark one.
# Every literal goes through _shui_sgr so NO_COLOR and a pipe strip it too.
#

SHUI_RESET=$(_shui_sgr 0)
SHUI_BOLD=$(_shui_sgr 1)
SHUI_DIM=$(_shui_sgr 2)
SHUI_ITALIC=$(_shui_sgr 3)
SHUI_UNDERLINE=$(_shui_sgr 4)
SHUI_STRIKETHROUGH=$(_shui_sgr 9)

# Semantic colours, derived from @kud/glyphs' tokens (src/tokens/glyphs-colors.zsh):
# the ANSI256 cell on a 256-colour terminal, the ANSI16 index otherwise.
SHUI_COLOR_ACCENT=$(_shui_token_color    ACCENT)      # #FF8C00
SHUI_COLOR_SUCCESS=$(_shui_token_color   SUCCESS)
SHUI_COLOR_WARNING=$(_shui_token_color   WARNING)
SHUI_COLOR_ERROR=$(_shui_token_color     ERROR)
SHUI_COLOR_INFO=$(_shui_token_color      INFO)
SHUI_COLOR_GROUP=$(_shui_token_color     GROUP)
SHUI_COLOR_SECONDARY=$(_shui_token_color SECONDARY)   # #999999
SHUI_COLOR_DIM=$(_shui_token_color       DIM)
SHUI_COLOR_TRACK=$(_shui_token_color     TRACK)
SHUI_COLOR_LINK=$(_shui_token_color      LINK)
SHUI_COLOR_ADDED=$(_shui_token_color     ADDED)
SHUI_COLOR_REMOVED=$(_shui_token_color   REMOVED)
SHUI_COLOR_DANGER=$SHUI_COLOR_ERROR
# Muted stays SGR 2, ink-ui's dimColor, rather than glyphs' palette grey: it
# dims whatever the foreground is (see the header), and tests pin it.
SHUI_COLOR_MUTED=$(_shui_sgr 2)

# SHUI_COLOR_PRIMARY / SHUI_BG_PRIMARY are deprecated aliases of ACCENT, set by
# shui.zsh after the theme loads — a theme defines ACCENT only.

SHUI_COLOR_CYAN=$(_shui_color      "38;5;51"  "0;36")
SHUI_COLOR_WHITE=$(_shui_color     "38;5;15"  "0;37")
SHUI_COLOR_MAGENTA=$(_shui_color   "38;5;201" "0;35")
SHUI_COLOR_BOLD_WHITE=$(_shui_sgr "1;37")

SHUI_BG_SUCCESS=$(_shui_token_color SUCCESS bg)
SHUI_BG_WARNING=$(_shui_token_color WARNING bg)
SHUI_BG_ERROR=$(_shui_token_color   ERROR   bg)
SHUI_BG_INFO=$(_shui_token_color    INFO    bg)
SHUI_BG_ACCENT=$(_shui_token_color  ACCENT  bg)
SHUI_BG_MUTED=$(_shui_bg_color    "48;5;240" "100")
