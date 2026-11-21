#!/usr/bin/env zsh

# OSC 8 is an escape sequence like any colour, so it obeys the same gate
# (_SHUI_COLOR_DEPTH, set once in src/tokens/colors.zsh): on a pipe or under
# NO_COLOR it would land as raw bytes in a log, and the URL would be invisible
# to anyone reading it. Plain text keeps the URL: "text (url)", or the URL alone
# when the text is empty or already is the URL. FORCE_COLOR brings OSC 8 back.
_shui_hyperlink() {
  local text="$1" url="$2"
  if (( _SHUI_COLOR_DEPTH == 0 )); then
    if [[ -z "$text" || "$text" == "$url" ]]; then
      printf '%s' "$url"
    else
      printf '%s (%s)' "$text" "$url"
    fi
    return
  fi
  printf '\033]8;;%s\033\\%s\033]8;;\033\\' "$url" "$text"
}

_shui_print_link() {
  local text="$1" url="$2"
  _shui_hyperlink "$text" "$url"
  printf '\n'
}
