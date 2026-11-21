#!/usr/bin/env zsh

# Every prompt below reads its answer from /dev/tty, never stdin, so piped input
# cannot answer on the user's behalf. With no controlling terminal (cron, CI, a
# detached `setsid`, an agent's subprocess) that open fails: the read errors out,
# `confirm` falls back to its default and a `--default=y` reads as consent nobody
# gave, while `--default=n` exits 1 and the caller cannot tell "declined" from
# "never asked". Refuse instead: one stderr line and exit 2, before any prompt is
# drawn. The probe is a builtin redirect, so it costs no fork.
_shui_require_tty() {
  { true </dev/tty } 2>/dev/null && return 0
  printf 'shui: no terminal to ask; pass --yes\n' >&2
  return 2
}

_shui_confirm() {
  local default="n"
  local prompt="Are you sure?"

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --default=*) default="${1#--default=}"; shift ;;
      *)           prompt="$1";              shift ;;
    esac
  done

  # Only a bare lowercase "y" counted as a yes default: "--default=Y" drew the
  # hint as y/N while enter answered yes, and "--default=yes" answered no.
  [[ "${(L)default}" == y* ]] && default=y || default=n

  _shui_require_tty || return 2

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
  _shui_require_tty || return 2
  local prompt="$1"; shift
  local -a options=("$@")
  local opt

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


# Reads one keypress from the terminal and names it: up, down, left, right,
# home, end, pgup, pgdn, backtab, esc, enter, or the character itself; "" for a
# sequence nothing here uses. An escape sequence is read to its final byte, so a
# four-byte key such as PgDn (\e[6~) never leaves a stray "~" behind to be taken
# for the next keypress. Fails only when the terminal is gone. Sets REPLY.
_shui_read_key() {
  emulate -L zsh
  local c seq
  IFS= read -rk1 c </dev/tty || return 1
  case "$c" in
    $'\r'|$'\n') REPLY=enter; return 0 ;;
    $'\033')     ;;
    *)           REPLY="$c"; return 0 ;;
  esac

  # A bare escape sends nothing after it; a slow link gets 0.4s to prove otherwise.
  if ! IFS= read -rk1 -t 0.4 c </dev/tty; then
    REPLY=esc
    return 0
  fi
  REPLY=""
  [[ "$c" == '[' || "$c" == 'O' ]] || return 0
  seq="$c"
  while (( ${#seq} < 8 )) && IFS= read -rk1 -t 0.4 c </dev/tty; do
    seq+="$c"
    [[ "$seq" != '[[' && "$c" == [@-~] ]] && break
  done
  case "$seq" in
    '[A'|'OA')             REPLY=up ;;
    '[B'|'OB')             REPLY=down ;;
    '[C'|'OC')             REPLY=right ;;
    '[D'|'OD')             REPLY=left ;;
    '[H'|'OH'|'[1~'|'[7~') REPLY=home ;;
    '[F'|'OF'|'[4~'|'[8~') REPLY=end ;;
    '[5~')                 REPLY=pgup ;;
    '[6~')                 REPLY=pgdn ;;
    '[Z')                  REPLY=backtab ;;
  esac
  return 0
}

# Which slice of a list to draw. A list taller than the terminal cannot be
# redrawn by moving the cursor up its full height: the cursor stops at the top
# row, and every redraw lands below the last one. So a long list shows a window,
# scrolled just far enough to keep the cursor in it, and a position line under it.
#
#   $1 options  $2 cursor  $3 current top  $4 rows free for the list
#
# Sets reply=(top height marker), marker 1 when the list is clipped and the
# position line fits. Pure, so the arithmetic is testable without a terminal.
_shui_list_window() {
  emulate -L zsh
  local -i n=$1 cursor=$2 top=$3 avail=$4 height marker=1
  if (( n <= avail )); then
    reply=(1 $n 0)
    return
  fi
  height=$(( avail - 1 ))
  if (( height < 1 )); then
    height=$(( avail > 1 ? avail : 1 ))
    marker=0
  fi
  (( cursor < 1 )) && cursor=1
  (( top > cursor )) && top=$cursor
  (( cursor > top + height - 1 )) && top=$(( cursor - height + 1 ))
  (( top > n - height + 1 )) && top=$(( n - height + 1 ))
  (( top < 1 )) && top=1
  reply=($top $height $marker)
}

# One frame of a radio or multiselect list, drawn over the previous one. Reads
# the caller's locals: mode (radio|multi), labels and descs (display text),
# label_w, max_len, n, cursor, selected, header_w; updates top, page and drawn
# (the visible width of each line written, which the next frame climbs back over).
#
# Every line is cut to the terminal's width, hint first and then label, so no
# line wraps and the climb is exact. Only the display is cut: callers still get
# the full label back.
_shui_list_render() {
  local -a reply
  local REPLY
  _shui_tty_size
  local -i rows=${reply[1]} cols=${reply[2]}
  local -i limit=$(( cols - 1 ))
  local -i header_rows=$(( header_w > 0 ? (header_w + cols - 1) / cols : 1 ))
  local -i avail=$(( rows - 1 - header_rows ))
  (( avail < 2 )) && avail=$(( rows - 1 ))

  _shui_list_window $n $cursor $top $avail
  top=${reply[1]}
  local -i height=${reply[2]} marker=${reply[3]}
  page=$height

  local -i climbed=0
  if (( ${#drawn} )); then
    _shui_rows_drawn $cols "${drawn[@]}"
    climbed=$REPLY
    printf '\033[%dA' "$climbed"
  fi
  drawn=()

  local pointer="$SHUI_ICON_POINTER" _blank_src=""
  local blank="${(l:${(m)#pointer}:)_blank_src}" check
  local -i glyph_w=${(m)#pointer}
  if [[ "$mode" == multi ]]; then
    glyph_w=$(( ${(m)#SHUI_ICON_SQUARE} > ${(m)#SHUI_ICON_SQUARE_EMPTY} ? ${(m)#SHUI_ICON_SQUARE} : ${(m)#SHUI_ICON_SQUARE_EMPTY} ))
  fi
  local -i room=$(( limit - 3 - glyph_w ))
  local -i col=$(( max_len < room ? max_len : room ))
  (( col < 0 )) && col=0
  local -i i pad width hint_room
  local label desc

  for (( i = top; i < top + height; i++ )); do
    label="${labels[$i]}"
    desc="${descs[$i]}"
    (( label_w[$i] > col )) && { _shui_fit "$label" $col; label="$REPLY"; }
    hint_room=$(( room - col - 2 ))
    if [[ -n "$desc" ]]; then
      if (( hint_room >= 2 )); then
        _shui_fit "$desc" $hint_room
        desc="$REPLY"
      else
        desc=""
      fi
    fi
    pad=$(( col - ${(m)#label} + 2 ))
    width=$(( 3 + glyph_w + ${(m)#label} + pad + ${(m)#desc} ))
    (( width > limit )) && { (( pad -= width - limit )); width=$limit; }
    (( pad < 0 )) && pad=0

    printf '\033[2K\r'
    if [[ "$mode" == radio ]]; then
      if (( i == cursor )); then
        printf '  %s%s%s %s%s%s%*s' \
          "$SHUI_COLOR_PRIMARY" "$pointer" "$SHUI_RESET" \
          "$SHUI_COLOR_PRIMARY" "$label" "$SHUI_RESET" \
          "$pad" ""
      else
        printf '  %s %s%*s' \
          "$blank" "$label" "$pad" ""
      fi
    else
      if (( selected[$i] )); then
        check="${SHUI_COLOR_SUCCESS}${SHUI_ICON_SQUARE}${SHUI_RESET}"
      else
        check="${SHUI_COLOR_MUTED}${SHUI_ICON_SQUARE_EMPTY}${SHUI_RESET}"
      fi
      if (( i == cursor )); then
        printf '  %s %s%s%s%*s' "$check" "$SHUI_COLOR_PRIMARY" "$label" "$SHUI_RESET" "$pad" ""
      else
        printf '  %s %s%*s' "$check" "$label" "$pad" ""
      fi
    fi
    [[ -n "$desc" ]] && printf '%s%s%s' "$SHUI_COLOR_SECONDARY" "$desc" "$SHUI_RESET"
    printf '\n'
    drawn+=($width)
  done

  if (( marker )); then
    local position="$top–$(( top + height - 1 )) of $n"
    if [[ "$mode" == multi ]]; then
      local -i ticked=0
      for (( i = 1; i <= n; i++ )); do (( selected[$i] )) && (( ticked++ )); done
      (( ticked )) && position+=" · $ticked selected"
    fi
    _shui_fit "$position" $(( limit - 2 ))
    printf '\033[2K\r  %s%s%s\n' "$SHUI_COLOR_MUTED" "$REPLY" "$SHUI_RESET"
    drawn+=($(( 2 + ${(m)#REPLY} )))
  fi

  # A frame shorter than the last one (the window shrank, the list stopped being
  # clipped) leaves the old frame's tail below it.
  (( ${#drawn} < climbed )) && printf '\033[J'
  return 0
}

# The shared loop behind radio and multiselect: draws, reads keys, redraws, and
# hands back the tty as it found it. Sets the caller's cursor and selected.
# Returns 0 on enter, 130 on q, esc or ctrl-c, 2 if the terminal goes away.
_shui_list_run() {
  local hint="$1"
  local -a labels descs label_w drawn
  local -i max_len=0 top=1 page=1 header_w i
  local opt REPLY

  for opt in "${options[@]}"; do
    _shui_plain "${opt%%$'\t'*}"
    labels+=("$REPLY")
    label_w+=(${(m)#REPLY})
    (( ${(m)#REPLY} > max_len )) && max_len=${(m)#REPLY}
    if [[ "$opt" == *$'\t'* ]]; then
      _shui_plain "${opt#*$'\t'}"
      descs+=("$REPLY")
    else
      descs+=("")
    fi
  done

  _shui_plain "$prompt"
  header_w=$(( ${(m)#REPLY} + 1 + ${(m)#hint} ))
  printf '%s%s%s %s%s%s\n' \
    "$SHUI_BOLD" "$prompt" "$SHUI_RESET" \
    "$SHUI_COLOR_MUTED" "$hint" "$SHUI_RESET" >&2
  _shui_list_render >&2

  # stdin on the tty, stdout on /dev/null, here and at every other stty call in
  # this file. macOS stty writes "stdout appears redirected, but stdin is the
  # control descriptor" to stderr when stdout is /dev/tty, and it writes the same
  # line when stdout is a caller's pipe ("ambre install | tee log"). That line
  # lands between the first draw and the first redraw, so every redraw starts one
  # row low and the top option shows up twice. /dev/null is the only target that
  # avoids the warning in both cases.
  #
  # -isig makes ctrl-c a keypress like q. As a signal it killed the caller's
  # script mid-prompt, past the restore below: echo off, cursor hidden.
  local old_stty
  local -i exit_code=0
  old_stty=$(stty -g </dev/tty 2>/dev/null) || old_stty=""
  [[ -n "$old_stty" ]] && stty -echo -icanon -isig min 1 time 0 </dev/tty >/dev/null
  _shui_cursor hide-cursor >&2

  while true; do
    if ! _shui_read_key; then
      exit_code=2
      break
    fi
    case "$REPLY" in
      up|k)   (( cursor > 1 )) && (( cursor-- )) ;;
      down|j) (( cursor < n )) && (( cursor++ )) ;;
      home|g) cursor=1 ;;
      end|G)  cursor=$n ;;
      pgup)   cursor=$(( cursor - page > 1 ? cursor - page : 1 )) ;;
      pgdn)   cursor=$(( cursor + page < n ? cursor + page : n )) ;;
      ' ')
        [[ "$mode" == multi ]] && (( n )) && selected[$cursor]=$(( ! selected[$cursor] ))
        ;;
      a|A)
        if [[ "$mode" == multi ]]; then
          local -i all=1
          for (( i = 1; i <= n; i++ )); do (( selected[$i] )) || { all=0; break; }; done
          for (( i = 1; i <= n; i++ )); do selected[$i]=$(( all ? 0 : 1 )); done
        fi
        ;;
      enter) break ;;
      esc|q|Q|$'\003') exit_code=130; break ;;
    esac
    _shui_list_render >&2
  done

  [[ -n "$old_stty" ]] && stty "$old_stty" </dev/tty >/dev/null
  _shui_cursor show-cursor >&2
  printf '\n' >&2
  return $exit_code
}

_shui_radio() {
  emulate -L zsh
  local prompt="$1"; shift
  local -a options=("$@")
  local -i n=${#options[@]} cursor=1 exit_code
  # Nothing to choose from is not a choice: exiting 0 would hand back an empty
  # "selection" as though someone had made it. Same answer as tabs.
  (( n == 0 )) && return 1
  _shui_require_tty || return 2
  local mode=radio
  local -a selected

  _shui_list_run "↑↓/jk move · g/G first/last · enter select · q cancel"
  exit_code=$?

  (( exit_code == 0 )) && printf '%s\n' "${options[$cursor]%%$'\t'*}"
  return $exit_code
}

_shui_multiselect() {
  emulate -L zsh
  _shui_require_tty || return 2
  local prompt="$1"; shift
  local -a options=("$@")
  local -i n=${#options[@]} cursor=1 exit_code i
  local mode=multi
  local -a selected
  for (( i = 1; i <= n; i++ )); do selected[$i]=0; done

  # "label<TAB>hint", as in radio: the hint is drawn as an aligned grey column and
  # never returned, so a caller gets back only the labels it can act on.
  _shui_list_run "↑↓/jk move · space toggle · a all · enter confirm · q cancel"
  exit_code=$?

  if (( exit_code == 0 )); then
    for (( i = 1; i <= n; i++ )); do
      (( selected[$i] )) && printf '%s\n' "${options[$i]%%$'\t'*}"
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

  _shui_require_tty || return 2

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

  _shui_require_tty || return 2

  printf '%s%s%s ' "$SHUI_BOLD" "$prompt" "$SHUI_RESET" >&2

  # -isig makes ctrl-c a keypress: as a signal it killed the caller with echo
  # still off, and the cancel branch below never ran.
  local old_stty value=""
  local -i exit_code=0
  old_stty=$(stty -g </dev/tty 2>/dev/null) || old_stty=""
  [[ -n "$old_stty" ]] && stty -echo -icanon -isig min 1 time 0 </dev/tty >/dev/null

  # Keys arrive whole (_shui_read_key): arrows, Home, Delete and the like used to
  # be swallowed two bytes at a time, so the "~" ending Delete or PgUp went into
  # the password unseen.
  while true; do
    if ! _shui_read_key; then
      exit_code=2
      break
    fi
    case "$REPLY" in
      enter)   break ;;
      $'\003') exit_code=130; break ;;            # ctrl-c — cancel
      $'\177'|$'\010')                            # backspace / delete
        if (( ${#value} > 0 )); then
          value="${value[1,-2]}"
          printf '\b \b' >&2
        fi
        ;;
      [[:cntrl:]]) ;;                             # ignore other control chars
      ?) value+="$REPLY"; printf '*' >&2 ;;
      *) ;;                                       # a named key: arrows, home…
    esac
  done

  [[ -n "$old_stty" ]] && stty "$old_stty" </dev/tty >/dev/null
  printf '\n' >&2
  (( exit_code == 0 )) && printf '%s\n' "$value"
  return $exit_code
}
