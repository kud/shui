#!/usr/bin/env zsh

# Colour depth 0 means "emit nothing": NO_COLOR set, or stdout not a terminal.
# FORCE_COLOR wins over both, the same precedence chalk gives @kud/ink-ui, so a
# script piped through `less -R` or a test harness can ask for colour back.
# Decided once at source time, as the reference does, and the `-t 1` test has to
# sit here rather than inside a `$(...)` — a command substitution's stdout is the
# capture pipe, so from inside one stdout is never a terminal.
_SHUI_COLOR_DEPTH=$(tput colors 2>/dev/null || echo 8)
if [[ -n "${FORCE_COLOR:-}" && "${FORCE_COLOR}" != 0 ]]; then
  :
elif [[ -n "${NO_COLOR:-}" || ! -t 1 ]]; then
  _SHUI_COLOR_DEPTH=0
fi
_SHUI_TERMINAL_WIDTH=$(tput cols 2>/dev/null || echo 80)

_shui_sgr() {
  (( _SHUI_COLOR_DEPTH == 0 )) && return
  printf '\033[%sm' "$1"
}

_shui_color() {
  local c256="$1" c16="$2"
  (( _SHUI_COLOR_DEPTH == 0 )) && return
  [[ $_SHUI_COLOR_DEPTH -ge 256 ]] && printf '\033[%sm' "$c256" || printf '\033[%sm' "$c16"
}

_shui_bg_color() {
  local c256="$1" c16="$2"
  (( _SHUI_COLOR_DEPTH == 0 )) && return
  [[ $_SHUI_COLOR_DEPTH -ge 256 ]] && printf '\033[%sm' "$c256" || printf '\033[%sm' "$c16"
}

# SGR parameter for a 16-colour palette index: 0-7 are the normal colours
# (30-37 fg, 40-47 bg), 8-15 the bright ones (90-97 fg, 100-107 bg).
_shui_ansi16_sgr() {  # _shui_ansi16_sgr <index 0-15> [bg]
  local -i i=$1 base=30
  [[ ${2:-} == bg ]] && base=40
  (( i >= 8 )) && (( base += 60, i -= 8 ))
  print -rn -- $(( base + i ))
}

# Render a semantic token from @kud/glyphs (src/tokens/glyphs-colors.zsh) at the
# terminal's depth: its ANSI256 cell on a 256-colour terminal, its ANSI16 index
# (the contract floor) on anything less. The HEX layer is not rendered yet.
_shui_token_color() {  # _shui_token_color <TOKEN> [bg]
  local n256="SHUI_COLOR_${1}_ANSI256" n16="SHUI_COLOR_${1}_ANSI16"
  local layer=38; [[ ${2:-} == bg ]] && layer=48
  _shui_color "${layer};5;${(P)n256}" "$(_shui_ansi16_sgr "${(P)n16}" "${2:-}")"
}

# The ANSI16 floor alone, whatever the terminal's depth — the 16-colour themes.
_shui_token_color16() {  # _shui_token_color16 <TOKEN> [bg]
  local n16="SHUI_COLOR_${1}_ANSI16"
  _shui_sgr "$(_shui_ansi16_sgr "${(P)n16}" "${2:-}")"
}

_shui_repeat() {
  local char="$1" count="$2" result=""
  local i
  for ((i=0; i<count; i++)); do result+="$char"; done
  printf '%s' "$result"
}

# How many COLUMNS a string occupies once its escapes are stripped — the number
# every component pads against.
#
# This counted BYTES until now (`wc -c`), so any multi-byte character made the
# caller pad short by bytes-minus-characters: a table cell holding an em dash
# came out two columns narrow and walked the right-hand border off the grid, and
# a box or row with non-ASCII content drifted the same way. Nothing looked wrong
# in the callers — their padding maths was correct and the measurement was not,
# which is how it survived every table anyone had drawn with it.
#
# Three fixes in the same three lines:
#
#   · characters, not bytes — ${#s} under MULTIBYTE, which zsh sets by default;
#   · no `echo` — it expands backslash escapes in zsh, so a value carrying a
#     literal \t or \n was measured after mangling rather than as written;
#   · no forks — this ran echo | sed | wc | tr for EVERY cell of every table.
#
# Astral-plane emoji are then counted twice, because they occupy two columns and
# shui ships an emoji icon set. Nerd Font glyphs deliberately are NOT in that
# range: they live in the private use area and render single-width.
_shui_visible_len() {
  emulate -L zsh
  setopt extended_glob

  local s="${1//$'\e'\[[0-9;]#[a-zA-Z]/}"
  local -i len=${#s}

  local wide="${s//[^$'\U1F300'-$'\U1FAFF']/}"
  (( len += ${#wide} ))

  print -r -- "$len"
}
