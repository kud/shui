#!/usr/bin/env zsh
#
# help — the shared CLI help layout, rendered for Zsh.
#
#   shui help --name=acme-cli --version=1.4.0 --desc='Ship folders to Acme' \
#     --usage='acme-cli <command> [options]' \
#     --command='deploy <dir>|Upload a folder' \
#     --option='-p, --project <id>|Project to act on|from acme.json' \
#     --example='Publish the build folder|acme-cli deploy dist' \
#     --env='ACME_TOKEN|API token' \
#     --see='https://acme.dev/docs/cli'
#
# Every flag takes `--flag=value` or `--flag value`; every list flag repeats, and
# rows print in the order given. Rows split on `|`.
#
#   --name --version --desc   header: name bold, version secondary, description
#   --usage    (repeat)       USAGE lines, never wrapped
#   --about                   short paragraph under the USAGE lines
#   --command  (repeat)       COMMANDS rows      name|description[|default]
#   --argument (repeat)       ARGUMENTS rows     name|description[|default]
#   --option   (repeat)       OPTIONS rows       name|description[|default]
#   --example  (repeat)       EXAMPLES           comment|command, or command alone
#   --env      (repeat)       ENVIRONMENT rows   name|description[|default]
#   --see      (repeat)       SEE ALSO links
#
# This is the zsh twin of @kud/ink-ui's `renderHelp`, and its byte contract is
# the same: tests/golden/help/deploy.*.txt are ink-ui's golden files, and
# tests/test-help.zsh holds shui to them byte for byte. The rules:
#
#   - width min(COLUMNS, 80); sections USAGE, COMMANDS, ARGUMENTS, OPTIONS,
#     EXAMPLES, ENVIRONMENT, SEE ALSO, each left out when empty, each after one
#     blank line; headings bold in `accent`, the only colour carrying structure
#   - rows indented 2, descriptions at column 26; a name wider than 22 sits
#     alone with its description on the next line at 26; continuations hang at
#     26; below 60 columns every description drops under its name at indent 6
#   - in OPTIONS, when some option has a short form, a long-only option shifts
#     4 so the `--` align — not below 60 columns
#   - names: <x> and [x] runs secondary, every other word bold, spaces unstyled
#   - descriptions: whitespace collapsed, a first a–z letter capitalised, one
#     final `.` dropped; `(default: …)` one secondary run wrapping never splits;
#     greedy wrap by display width, an over-wide word overflows
#   - one SGR per styled run, parameters bold;underline;colour, closed ESC[0m
#
# Colour mode, decided per call (help is so often piped to a pager):
#   plain        stdout not a terminal (SHUI_FORCE_TTY=1 or FORCE_COLOR say it is)
#   monochrome   NO_COLOR set: bold and underline kept, no colour
#   truecolor    COLORTERM truecolor or 24bit
#   ansi256      TERM naming 256 colours
#   ansi16       any other terminal
#
# Colours are @kud/glyphs 0.6.0 `colors.json`, not the theme's: the layout is
# shared across tools, so it reads the same whatever theme a script loaded.
#   accent    #FF8C00  ansi256 208  ansi16 3
#   secondary #999999  ansi256 246  ansi16 7
#   link      #82AAFF  ansi256 111  ansi16 4
typeset -g _SHUI_HELP_R=$'\e[0m'
typeset -gA _SHUI_HELP_COLORS=(
  accent:truecolor    '38;2;255;140;0'   accent:ansi256    '38;5;208'  accent:ansi16    '33'
  secondary:truecolor '38;2;153;153;153' secondary:ansi256 '38;5;246'  secondary:ansi16 '37'
  link:truecolor      '38;2;130;170;255' link:ansi256      '38;5;111'  link:ansi16      '34'
)

# The opening SGR for a style in the current mode: $1 bold, $2 underline (0/1),
# $3 a colour token or empty. Empty in plain mode. Sets REPLY.
_shui_help_sgr() {
  local -a p=()
  REPLY=""
  [[ $_SHUI_HELP_MODE == plain ]] && return
  (( $1 )) && p+=(1)
  (( $2 )) && p+=(4)
  [[ -n $3 && $_SHUI_HELP_MODE != monochrome ]] && p+=("${_SHUI_HELP_COLORS[$3:$_SHUI_HELP_MODE]}")
  (( ${#p} )) && REPLY=$'\e['"${(j:;:)p}m"
}

# Appends one run to the line being built: $1 the opening SGR (may be empty),
# $2 the text. Keeps `line` (bytes) and `lw` (display columns) in step.
_shui_help_put() {
  line+="${1}${2}${1:+$_SHUI_HELP_R}"
  (( lw += ${(m)#2} ))
}

# A name or usage line as runs: <x> and [x] in secondary, every other word in
# $2 (an opening SGR, empty for usage), the spaces between them unstyled.
_shui_help_term() {
  emulate -L zsh
  local s="$1" open="$2" text part
  local -a bits
  while [[ -n $s ]]; do
    if [[ $s =~ '<[^>]*>|\[[^]]*\]' ]]; then
      text="${s[1,MBEGIN-1]}"
    else
      text="$s"
    fi
    # Words and the space runs between them, in order.
    while [[ -n $text ]]; do
      if [[ $text == ' '* ]]; then
        part="${text%%[^ ]*}"
        _shui_help_put "" "$part"
      else
        part="${text%% *}"
        _shui_help_put "$open" "$part"
      fi
      text="${text[${#part}+1,-1]}"
    done
    [[ $s =~ '<[^>]*>|\[[^]]*\]' ]] || break
    _shui_help_put "$_SHUI_HELP_SEC" "$MATCH"
    s="${s[MEND+1,-1]}"
  done
}

# Capital first letter, no final full stop, whitespace collapsed. Sets REPLY.
_shui_help_normalise() {
  local out="${(j: :)${=1}}"
  [[ $out == [a-z]* ]] && out="${(U)out[1]}${out[2,-1]}"
  [[ $out == *. && $out != *.. ]] && out="${out[1,-2]}"
  REPLY="$out"
}

# Greedy wrap of the words in `words` (styles in `wstyles`, an opening SGR or
# empty) into `available` columns. Each wrapped line goes to `wrapped` as the
# encoded words joined by single spaces.
_shui_help_wrap() {
  emulate -L zsh
  local -i available=$1 used=0 i w
  local cur=""
  local -i have=0
  for (( i = 1; i <= ${#words}; i++ )); do
    w=${(m)#words[i]}
    if (( have && used + 1 + w > available )); then
      wrapped+=("$cur"); cur="" used=0 have=0
    fi
    (( have )) && { cur+=" "; (( used++ )); }
    cur+="${wstyles[i]}${words[i]}${wstyles[i]:+$_SHUI_HELP_R}"
    (( used += w ))
    have=1
  done
  (( have )) && wrapped+=("$cur")
}

# A free-text paragraph at an indent: whitespace collapsed, not normalised.
_shui_help_paragraph() {
  emulate -L zsh
  local -i indent=$1
  local -a words=(${=2}) wstyles=() wrapped=()
  local w
  for w in "${words[@]}"; do wstyles+=(""); done
  _shui_help_wrap $(( _SHUI_HELP_W - indent ))
  for w in "${wrapped[@]}"; do print -r -- "${(l:indent:: :)}$w"; done
}

# The rows of one section. $1 = 1 for OPTIONS (the long-only shift applies);
# the rows themselves are the remaining arguments, name|description[|default].
_shui_help_rows() {
  emulate -L zsh
  setopt extended_glob
  local -i opts=$1 sh=0 lead
  shift
  local row name desc default l
  local -a parts words wstyles wrapped
  if (( opts && _SHUI_HELP_W >= 60 )); then
    for row in "$@"; do [[ ${${row%%|*}## #} == -[^-[:space:]]* ]] && sh=1; done
  fi
  for row in "$@"; do
    parts=("${(@s:|:)row}")
    name="${${parts[1]## #}%% #}" desc="${parts[2]}" default="${parts[3]}"
    lead=2
    (( sh )) && [[ $name == --* ]] && lead=6

    local line="${(l:lead:: :)}" lw=$lead
    _shui_help_term "$name" "$_SHUI_HELP_NAME"

    words=() wstyles=() wrapped=()
    if [[ -n ${desc//[[:space:]]/} ]]; then
      _shui_help_normalise "$desc"
      words=(${=REPLY})
      for l in "${words[@]}"; do wstyles+=(""); done
    fi
    if [[ -n $default ]]; then
      words+=("(default: ${(j: :)${=default}})")
      wstyles+=("$_SHUI_HELP_SEC")
    fi

    if (( ! ${#words} )); then
      print -r -- "$line"
    elif (( _SHUI_HELP_W < 60 )); then
      print -r -- "$line"
      _shui_help_wrap $(( _SHUI_HELP_W - 6 ))
      for l in "${wrapped[@]}"; do print -r -- "      $l"; done
    else
      _shui_help_wrap $(( _SHUI_HELP_W - 26 ))
      if (( lw - 2 <= 22 )); then
        print -r -- "${line}${(l:26-lw:: :)}${wrapped[1]}"
        shift wrapped
      else
        print -r -- "$line"
      fi
      for l in "${wrapped[@]}"; do print -r -- "${(l:26:: :)}$l"; done
    fi
  done
}

# A heading after its blank line, when its section has content.
_shui_help_heading() {
  print
  print -r -- "${_SHUI_HELP_HEAD}${1}${_SHUI_HELP_HEAD:+$_SHUI_HELP_R}"
}

_shui_help_render() {
  emulate -L zsh
  setopt extended_glob

  local name="" version="" desc="" about="" flag val
  local -a usage commands arguments options examples envs sees

  while (( $# )); do
    case "$1" in
      --*=*) flag="${1%%=*}" val="${1#*=}"; shift ;;
      --*)   flag="$1"
             (( $# >= 2 )) || { print -u2 "shui help: ${flag} needs a value"; return 1; }
             val="$2"; shift 2 ;;
      *)     print -u2 "shui help: unexpected argument '$1'"; return 1 ;;
    esac
    case "$flag" in
      --name)     name="$val" ;;
      --version)  version="$val" ;;
      --desc)     desc="$val" ;;
      --about)    about="$val" ;;
      --usage)    usage+=("$val") ;;
      --command)  commands+=("$val") ;;
      --argument) arguments+=("$val") ;;
      --option)   options+=("$val") ;;
      --example)  examples+=("$val") ;;
      --env)      envs+=("$val") ;;
      --see)      sees+=("$val") ;;
      *) print -u2 "shui help: unknown flag '${flag}'"; return 1 ;;
    esac
  done

  # Mode, decided at call time rather than at source time: `shui help | less`
  # must not carry escapes even when shui was sourced on a terminal.
  local _SHUI_HELP_MODE=plain
  if [[ -t 1 || ( -n ${SHUI_FORCE_TTY:-} && $SHUI_FORCE_TTY != 0 ) \
        || ( -n ${FORCE_COLOR:-} && $FORCE_COLOR != 0 ) ]]; then
    if [[ -n ${NO_COLOR:-} && ( -z ${FORCE_COLOR:-} || $FORCE_COLOR == 0 ) ]]; then
      _SHUI_HELP_MODE=monochrome
    elif [[ ${(L)COLORTERM:-} == (truecolor|24bit) ]]; then
      _SHUI_HELP_MODE=truecolor
    elif [[ ${TERM:-} == *256* ]]; then
      _SHUI_HELP_MODE=ansi256
    else
      _SHUI_HELP_MODE=ansi16
    fi
  fi
  local _SHUI_HELP_NAME _SHUI_HELP_SEC _SHUI_HELP_HEAD _SHUI_HELP_LINK
  _shui_help_sgr 1 0 "";          _SHUI_HELP_NAME=$REPLY
  _shui_help_sgr 0 0 secondary;   _SHUI_HELP_SEC=$REPLY
  _shui_help_sgr 1 0 accent;      _SHUI_HELP_HEAD=$REPLY
  _shui_help_sgr 0 1 link;        _SHUI_HELP_LINK=$REPLY

  local -i _SHUI_HELP_W=${COLUMNS:-0}
  if (( _SHUI_HELP_W <= 0 )) && [[ -t 1 ]]; then
    _shui_tty_size; _SHUI_HELP_W=${reply[2]}
  fi
  (( _SHUI_HELP_W <= 0 || _SHUI_HELP_W > 80 )) && _SHUI_HELP_W=80

  local row line
  local -i lw

  # Header: name, version, description.
  line="" lw=0
  _shui_help_put "$_SHUI_HELP_NAME" "${${name## #}%% #}"
  [[ -n $version ]] && { _shui_help_put "" " "; _shui_help_put "$_SHUI_HELP_SEC" "${${version## #}%% #}"; }
  print -r -- "$line"
  if [[ -n ${desc//[[:space:]]/} ]]; then
    _shui_help_normalise "$desc"
    _shui_help_paragraph 0 "$REPLY"
  fi

  local -a lines=()
  for row in "${usage[@]}"; do
    row="${${row## #}%% #}"
    [[ -n $row ]] && lines+=("$row")
  done
  if (( ${#lines} )); then
    _shui_help_heading USAGE
    for row in "${lines[@]}"; do
      line="  " lw=2
      _shui_help_term "$row" ""
      print -r -- "$line"
    done
    if [[ -n ${about//[[:space:]]/} ]]; then
      print
      _shui_help_paragraph 2 "$about"
    fi
  fi

  (( ${#commands} ))  && { _shui_help_heading COMMANDS;    _shui_help_rows 0 "${commands[@]}"; }
  (( ${#arguments} )) && { _shui_help_heading ARGUMENTS;   _shui_help_rows 0 "${arguments[@]}"; }
  (( ${#options} ))   && { _shui_help_heading OPTIONS;     _shui_help_rows 1 "${options[@]}"; }

  if (( ${#examples} )); then
    _shui_help_heading EXAMPLES
    for row in "${examples[@]}"; do
      if [[ $row == *\|* ]]; then
        [[ -n ${${row%%|*}//[[:space:]]/} ]] &&
          print -r -- "  ${_SHUI_HELP_SEC}# ${(j: :)${=row%%|*}}${_SHUI_HELP_SEC:+$_SHUI_HELP_R}"
        row="${row#*|}"
      fi
      print -r -- "  ${_SHUI_HELP_SEC}\$${_SHUI_HELP_SEC:+$_SHUI_HELP_R} ${${row## #}%% #}"
    done
  fi

  (( ${#envs} )) && { _shui_help_heading ENVIRONMENT; _shui_help_rows 0 "${envs[@]}"; }

  lines=()
  for row in "${sees[@]}"; do
    row="${${row## #}%% #}"
    [[ -n $row ]] && lines+=("$row")
  done
  if (( ${#lines} )); then
    _shui_help_heading "SEE ALSO"
    for row in "${lines[@]}"; do
      print -r -- "  ${_SHUI_HELP_LINK}${row}${_SHUI_HELP_LINK:+$_SHUI_HELP_R}"
    done
  fi
}
