#!/usr/bin/env zsh

_shui_util() {
  local type="$1"

  case "$type" in
    terminal-size)
      local width height
      width=$(tput cols 2>/dev/null || echo 80)
      height=$(tput lines 2>/dev/null || echo 24)
      printf '%sx%s\n' "$width" "$height"
      ;;
  esac
}

# The terminal's rows and columns, asked of the tty itself on every call:
# $LINES and $COLUMNS are 0 in a script and stale after a resize, and the value
# loaded at source time is stale by definition. Sets reply=(rows cols); with no
# terminal to ask, 24×80.
_shui_tty_size() {
  local size
  size=$(stty size </dev/tty 2>/dev/null)
  reply=(${=size})
  (( ${#reply} == 2 && reply[1] > 0 && reply[2] > 0 )) || reply=(24 80)
}

# Display text for a caller's string: escape sequences removed, any other
# control character (tab, newline, a stray escape) turned into a space. Every
# component that redraws in place counts on one string being one row of a known
# width; a newline or a colour code inside it breaks that count. Sets REPLY.
_shui_plain() {
  emulate -L zsh
  setopt extended_glob
  local s="${1//$'\e'\[[0-9;?]#[@-~]/}"
  REPLY="${s//[[:cntrl:]]/ }"
}

# $1 cut to at most $2 columns, ending in an ellipsis when anything was cut.
# Columns, not characters: a CJK character or an emoji takes two. Sets REPLY.
_shui_fit() {
  emulate -L zsh
  local text="$1"
  local -i width=$2
  if (( ${(m)#text} <= width )); then
    REPLY="$text"
    return
  fi
  if (( width <= 0 )); then
    REPLY=""
    return
  fi
  text="${text[1,width-1]}"
  while (( ${(m)#text} > width - 1 )); do text="${text[1,-2]}"; done
  REPLY="${text}…"
}

# How many rows the cursor must climb to reach the top of a block it drew, given
# the visible width of each line it wrote and the columns of the terminal now.
# Each line was cut to fit when it was drawn, so this is the line count, until a
# narrower window reflows a line onto two rows or more. Sets REPLY.
_shui_rows_drawn() {
  emulate -L zsh
  local -i cols=$1 rows=0 w
  shift
  for w in "$@"; do
    (( rows += w > 0 ? (w + cols - 1) / cols : 1 ))
  done
  REPLY=$rows
}
