#!/usr/bin/env zsh

_shui_confirm() {
  local default="n"
  local prompt="Are you sure?"

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --default=*) default="${1#--default=}"; shift ;;
      *)           prompt="$1";              shift ;;
    esac
  done

  local hint
  if [[ "$default" == "y" ]]; then
    hint="${SHUI_COLOR_PRIMARY}Y${SHUI_RESET}/${SHUI_COLOR_MUTED}n${SHUI_RESET}"
  else
    hint="${SHUI_COLOR_MUTED}y${SHUI_RESET}/${SHUI_COLOR_PRIMARY}N${SHUI_RESET}"
  fi

  printf '%s%s%s %s [%s] ' \
    "$SHUI_COLOR_INFO" "$SHUI_ICON_INFO" "$SHUI_RESET" \
    "$prompt" "$hint" >&2

  local response
  read -r response </dev/tty
  response="${response:-$default}"

  [[ "$response" =~ ^[yY]$ ]]
}

_shui_select() {
  local prompt="$1"; shift
  local -a options=("$@")

  printf '%s%s%s\n' \
    "$SHUI_BOLD" "$prompt" "$SHUI_RESET" >&2

  local i=1
  for opt in "${options[@]}"; do
    printf '  %s%s)%s %s\n' "$SHUI_COLOR_MUTED" "$i" "$SHUI_RESET" "$opt" >&2
    (( i++ ))
  done

  printf '%s%s%s ' "$SHUI_COLOR_MUTED" "$SHUI_ICON_ARROW" "$SHUI_RESET" >&2

  local choice
  read -r choice </dev/tty

  if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#options[@]} )); then
    printf '%s\n' "${options[$choice]}"
    return 0
  else
    printf 'shui: invalid selection "%s"\n' "$choice" >&2
    return 1
  fi
}

_shui_radio() {
  local prompt="$1"; shift
  local -a options=("$@")
  local n=${#options[@]}
  local cursor=1

  _shui_radio_render() {
    local i label desc max_len=0 pad
    local pointer="$SHUI_ICON_POINTER" _blank_src=""
    local blank="${(l:${#pointer}:)_blank_src}"
    for (( i = 1; i <= n; i++ )); do
      label="${options[$i]%%$'\t'*}"
      (( ${#label} > max_len )) && max_len=${#label}
    done

    for (( i = 1; i <= n; i++ )); do
      label="${options[$i]%%$'\t'*}"
      desc="${options[$i]#*$'\t'}"
      [[ "$desc" == "$label" ]] && desc=""
      pad=$(( max_len - ${#label} + 2 ))
      printf '\033[2K\r'
      if (( i == cursor )); then
        printf '  %s%s%s %s%s%s%*s' \
          "$SHUI_COLOR_PRIMARY" "$pointer" "$SHUI_RESET" \
          "$SHUI_COLOR_PRIMARY" "$label" "$SHUI_RESET" \
          "$pad" ""
        [[ -n "$desc" ]] && printf '%s%s%s' "$SHUI_COLOR_SECONDARY" "$desc" "$SHUI_RESET"
        printf '\n'
      else
        printf '  %s %s%*s' \
          "$blank" "$label" "$pad" ""
        [[ -n "$desc" ]] && printf '%s%s%s' "$SHUI_COLOR_SECONDARY" "$desc" "$SHUI_RESET"
        printf '\n'
      fi
    done
  }

  printf '%s%s%s %s↑↓/jk move · g/G first/last · enter select · q cancel%s\n' \
    "$SHUI_BOLD" "$prompt" "$SHUI_RESET" \
    "$SHUI_COLOR_MUTED" "$SHUI_RESET" >&2
  _shui_radio_render >&2

  # Both streams must point at the tty, here and at every other stty call in this
  # file. With only stdin redirected, a caller whose stdout is a pipe
  # ("ambre install | tee log") gives stty a tty stdin and a redirected stdout,
  # and it writes "stdout appears redirected, but stdin is the control
  # descriptor" into the log at every prompt. The -g read below escapes that only
  # by silencing stderr, which is why it never showed the problem.
  local old_stty exit_code=0 char seq
  old_stty=$(stty -g </dev/tty 2>/dev/null) || old_stty=""
  [[ -n "$old_stty" ]] && stty -echo -icanon min 1 time 0 </dev/tty >/dev/tty
  _shui_cursor hide-cursor >&2

  while true; do
    IFS= read -rk1 char </dev/tty
    case "$char" in
      $'\033')
        if IFS= read -rk2 -t 0.4 seq </dev/tty; then
          case "$seq" in
            '[A') (( cursor > 1 )) && (( cursor-- )) ;;
            '[B') (( cursor < n )) && (( cursor++ )) ;;
          esac
        else
          exit_code=130; break
        fi
        ;;
      k) (( cursor > 1 )) && (( cursor-- )) ;;
      j) (( cursor < n )) && (( cursor++ )) ;;
      g) cursor=1 ;;
      G) cursor=$n ;;
      $'\r'|$'\n') break ;;
      q|Q|$'\003') exit_code=130; break ;;
    esac
    printf '\033[%dA' "$n" >&2
    _shui_radio_render >&2
  done

  [[ -n "$old_stty" ]] && stty "$old_stty" </dev/tty >/dev/tty
  _shui_cursor show-cursor >&2
  printf '\n' >&2

  (( exit_code == 0 )) && printf '%s\n' "${options[$cursor]%%$'\t'*}"
  return $exit_code
}

_shui_multiselect() {
  local prompt="$1"; shift
  local -a options=("$@")
  local n=${#options[@]}
  local cursor=1
  local -a selected
  local i
  for (( i = 1; i <= n; i++ )); do selected[$i]=0; done

  _shui_multiselect_render() {
    local i check
    for (( i = 1; i <= n; i++ )); do
      printf '\033[2K\r'
      if (( selected[$i] )); then
        check="${SHUI_COLOR_SUCCESS}${SHUI_ICON_SQUARE}${SHUI_RESET}"
      else
        check="${SHUI_COLOR_MUTED}${SHUI_ICON_SQUARE_EMPTY}${SHUI_RESET}"
      fi
      if (( i == cursor )); then
        printf '  %s %s%s%s\n' "$check" "$SHUI_COLOR_PRIMARY" "${options[$i]}" "$SHUI_RESET"
      else
        printf '  %s %s\n' "$check" "${options[$i]}"
      fi
    done
  }

  printf '%s%s%s %s↑↓/jk move · space toggle · a all · enter confirm · q cancel%s\n' \
    "$SHUI_BOLD" "$prompt" "$SHUI_RESET" \
    "$SHUI_COLOR_MUTED" "$SHUI_RESET" >&2
  _shui_multiselect_render >&2

  local old_stty exit_code=0 char seq
  old_stty=$(stty -g </dev/tty 2>/dev/null) || old_stty=""
  [[ -n "$old_stty" ]] && stty -echo -icanon min 1 time 0 </dev/tty >/dev/tty
  _shui_cursor hide-cursor >&2

  while true; do
    IFS= read -rk1 char </dev/tty
    case "$char" in
      $'\033')
        if IFS= read -rk2 -t 0.4 seq </dev/tty; then
          case "$seq" in
            '[A') (( cursor > 1 )) && (( cursor-- )) ;;
            '[B') (( cursor < n )) && (( cursor++ )) ;;
          esac
        else
          exit_code=130; break
        fi
        ;;
      ' ') selected[$cursor]=$(( ! selected[$cursor] )) ;;
      k) (( cursor > 1 )) && (( cursor-- )) ;;
      j) (( cursor < n )) && (( cursor++ )) ;;
      g) cursor=1 ;;
      G) cursor=$n ;;
      a|A)
        local all=1 idx
        for (( idx = 1; idx <= n; idx++ )); do (( selected[$idx] )) || { all=0; break; }; done
        for (( idx = 1; idx <= n; idx++ )); do selected[$idx]=$(( all ? 0 : 1 )); done
        ;;
      $'\r'|$'\n') break ;;
      q|Q|$'\003') exit_code=130; break ;;
    esac
    printf '\033[%dA' "$n" >&2
    _shui_multiselect_render >&2
  done

  [[ -n "$old_stty" ]] && stty "$old_stty" </dev/tty >/dev/tty
  _shui_cursor show-cursor >&2
  printf '\n' >&2

  if (( exit_code == 0 )); then
    for (( i = 1; i <= n; i++ )); do
      (( selected[$i] )) && printf '%s\n' "${options[$i]}"
    done
  fi
  return $exit_code
}

# Pure validator — no TTY, no side effects. Returns 0 if $2 satisfies rule $1.
# Named rules (email/url/number) plus an arbitrary-regex fallback, so it stays
# unit-testable in isolation while _shui_input owns the prompt/retry loop.
_shui_validate_value() {
  local rule="$1" value="$2"
  case "$rule" in
    email)  [[ "$value" =~ '^[^[:space:]@]+@[^[:space:]@]+\.[^[:space:]@]+$' ]] ;;
    url)    [[ "$value" =~ '^https?://[^[:space:]]+$' ]] ;;
    number) [[ "$value" =~ '^-?[0-9]+$' ]] ;;
    *)      [[ "$value" =~ "$rule" ]] ;;
  esac
}

_shui_input() {
  local default=""
  local prompt="Input:"
  local validate=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --default=*)  default="${1#--default=}";   shift ;;
      --validate=*) validate="${1#--validate=}"; shift ;;
      *)            prompt="$1";                  shift ;;
    esac
  done

  local hint=""
  [[ -n "$default" ]] && hint=" ${SHUI_COLOR_MUTED}(${default})${SHUI_RESET}"

  local value
  while true; do
    printf '%s%s%s%s ' \
      "$SHUI_BOLD" "$prompt" "$SHUI_RESET" "$hint" >&2

    read -r value </dev/tty
    value="${value:-$default}"

    if [[ -n "$validate" ]] && ! _shui_validate_value "$validate" "$value"; then
      printf '%s%s%s Invalid input — expected %s%s%s\n' \
        "$SHUI_COLOR_ERROR" "$SHUI_ICON_ERROR" "$SHUI_RESET" \
        "$SHUI_COLOR_MUTED" "$validate" "$SHUI_RESET" >&2
      continue
    fi
    break
  done

  printf '%s\n' "$value"
}

# Masked text entry — echoes '*' per keystroke, never the raw character.
# Reads in raw mode from the tty so nothing lands in the terminal scrollback;
# the resolved value still prints to stdout, matching _shui_input.
_shui_password() {
  local prompt="Password:"

  while [[ $# -gt 0 ]]; do
    case "$1" in
      *) prompt="$1"; shift ;;
    esac
  done

  printf '%s%s%s ' "$SHUI_BOLD" "$prompt" "$SHUI_RESET" >&2

  local old_stty value="" char seq
  old_stty=$(stty -g </dev/tty 2>/dev/null) || old_stty=""
  [[ -n "$old_stty" ]] && stty -echo -icanon min 1 time 0 </dev/tty >/dev/tty

  while IFS= read -rk1 char </dev/tty; do
    case "$char" in
      $'\r'|$'\n') break ;;
      $'\003')                                    # ctrl-c — cancel
        [[ -n "$old_stty" ]] && stty "$old_stty" </dev/tty >/dev/tty
        printf '\n' >&2
        return 130
        ;;
      $'\177'|$'\010')                            # backspace / delete
        if (( ${#value} > 0 )); then
          value="${value[1,-2]}"
          printf '\b \b' >&2
        fi
        ;;
      $'\033')                                    # swallow escape sequences (arrows…)
        IFS= read -rk2 -t 0.01 seq </dev/tty 2>/dev/null
        ;;
      [[:cntrl:]]) ;;                             # ignore other control chars
      *) value+="$char"; printf '*' >&2 ;;
    esac
  done

  [[ -n "$old_stty" ]] && stty "$old_stty" </dev/tty >/dev/tty
  printf '\n' >&2
  printf '%s\n' "$value"
}
