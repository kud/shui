#!/usr/bin/env zsh

_shui_hyperlink() {
  local text="$1" url="$2"
  printf '\033]8;;%s\033\\%s\033]8;;\033\\' "$url" "$text"
}

_shui_print_link() {
  local text="$1" url="$2"
  _shui_hyperlink "$text" "$url"
  printf '\n'
}
