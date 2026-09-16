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

SHUI_COLOR_PRIMARY=$(_shui_color   "38;5;208" "33")    # ink-ui accent #FF8C00
SHUI_COLOR_SUCCESS=$(_shui_color   "32"       "32")    # green
SHUI_COLOR_WARNING=$(_shui_color   "33"       "33")    # yellow
SHUI_COLOR_ERROR=$(_shui_color     "31"       "31")    # red
SHUI_COLOR_INFO=$(_shui_color      "36"       "36")    # cyan
SHUI_COLOR_MUTED=$(_shui_sgr 2)                        # dimColor
SHUI_COLOR_ACCENT=$(_shui_color    "38;5;110" "0;36")
SHUI_COLOR_SECONDARY=$(_shui_color "38;5;246" "37")    # ink-ui secondary #999999
SHUI_COLOR_GROUP=$(_shui_color     "35"       "35")    # magenta
SHUI_COLOR_DANGER=$(_shui_color    "31"       "31")

SHUI_COLOR_CYAN=$(_shui_color      "38;5;51"  "0;36")
SHUI_COLOR_WHITE=$(_shui_color     "38;5;15"  "0;37")
SHUI_COLOR_MAGENTA=$(_shui_color   "38;5;201" "0;35")
SHUI_COLOR_BOLD_WHITE=$(_shui_sgr "1;37")

SHUI_BG_SUCCESS=$(_shui_bg_color  "42"        "42")
SHUI_BG_WARNING=$(_shui_bg_color  "43"        "43")
SHUI_BG_ERROR=$(_shui_bg_color    "41"        "41")
SHUI_BG_INFO=$(_shui_bg_color     "46"        "46")
SHUI_BG_PRIMARY=$(_shui_bg_color  "48;5;208" "43")
SHUI_BG_MUTED=$(_shui_bg_color    "48;5;240" "100")
