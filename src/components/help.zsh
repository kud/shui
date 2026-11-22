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
#   --name --version --desc   header: name bold, version secondary, one-line description
#   --usage    (repeat)       USAGE lines
#   --about                   short paragraph printed under the USAGE lines
#   --command  (repeat)       COMMANDS rows      name|description
#   --argument (repeat)       ARGUMENTS rows     name|description
#   --option   (repeat)       OPTIONS rows       name|description[|default]
#   --example  (repeat)       EXAMPLES           comment|command, or command alone
#   --env      (repeat)       ENVIRONMENT rows   name|description[|default]
#   --see      (repeat)       SEE ALSO links
#
# The layout is fixed, so every tool reads the same:
#   - sections in the order above, each left out when empty, one blank line
#     before each heading; headings in capitals, bold, in the accent colour —
#     the one colour that carries structure
#   - rows indented 2; descriptions start at column 26 in every section; a name
#     wider than 22 goes alone on its line with its description under it at 26;
#     wrapped text hangs at 26; below 60 columns descriptions drop under the
#     name at indent 6
#   - names bold in the text colour; placeholders <x> [x] and (default: …) in
#     secondary; a long option without a short form is shifted 4 so the `--`
#     align with the options that have one
#   - width min(COLUMNS, 80); no glyphs
#
# Three output modes, chosen per call because help is so often piped to a pager:
#   colour      stdout a terminal (or SHUI_FORCE_TTY=1), or FORCE_COLOR set
#   bold only   a terminal under NO_COLOR: no colour, structure kept
#   plain       anything else (a pipe, a file): not one escape byte
#

# Placeholders and brackets in a name or a usage line go secondary; the rest
# keeps the style in $2 (bold for names, nothing for usage). Sets REPLY.
_shui_help_hl() {
  emulate -L zsh
  local s="$1" base="$2" out=""
  while [[ $s =~ '<[^>]*>|\[[^]]*\]' ]]; do
    (( MBEGIN > 1 )) && out+="${base}${s[1,MBEGIN-1]}${base:+$_SHUI_HELP_R}"
    out+="${_SHUI_HELP_S}${MATCH}${_SHUI_HELP_S:+$_SHUI_HELP_R}"
    s="${s[MEND+1,-1]}"
  done
  [[ -n $s ]] && out+="${base}${s}${base:+$_SHUI_HELP_R}"
  REPLY="$out"
}

# Word-wraps $3 to $2 columns: the first line starts at column $4, the others
# at column $1 (the caller prints whatever fills the columns before). A default
# given as $5 joins the text as "(default: …)" and stays secondary across a
# wrap; <x> inside a description goes secondary too. Appends to `lines`.
_shui_help_wrap() {
  emulate -L zsh
  local -i indent=$1 width=$2 col=${4:-$1}
  local text="$3" default="$5" w d
  local -a words styles
  for w in ${=text}; do words+=("$w"); styles+=(0); done
  if [[ -n $default ]]; then
    d="(default: ${default})"
    for w in ${=d}; do words+=("$w"); styles+=(1); done
  fi
  (( ${#words} )) || return 0

  # `open` marks a secondary run still open on the current line, so the
  # default prints as one run, not one escape pair per word.
  local line="" close="${_SHUI_HELP_S:+$_SHUI_HELP_R}"
  local -i i len=0 open=0
  for (( i = 1; i <= ${#words}; i++ )); do
    w="${words[i]}"
    if (( len > 0 && len + 1 + ${#w} > width - col )); then
      (( open )) && line+="$close"
      lines+=("$line")
      line="" len=0 open=0 col=$indent
    fi
    if (( styles[i] )); then
      (( len > 0 )) && line+=" "
      (( open )) || line+="$_SHUI_HELP_S"
      open=1
    else
      (( open )) && line+="$close"
      open=0
      (( len > 0 )) && line+=" "
      if [[ -n $_SHUI_HELP_S && $w == *\<*\>* ]]; then
        _shui_help_hl "$w" ""
        w="$REPLY"
      fi
    fi
    (( len += (len > 0) + ${#words[i]} ))
    line+="$w"
  done
  (( open )) && line+="$close"
  lines+=("$line")
}

# One row: name, description, optional default. $4 = 1 shifts the name by 4.
_shui_help_row() {
  emulate -L zsh
  local name="$1" desc="$2" default="$3" lead="  " l
  local -i W=$_SHUI_HELP_W used
  [[ ${4:-0} == 1 ]] && lead="      "
  _shui_help_hl "$name" "$_SHUI_HELP_B"
  print -rn -- "${lead}${REPLY}"

  local -a lines=()
  if (( W < 60 )); then
    print
    _shui_help_wrap 6 $W "$desc" 6 "$default"
    for l in "${lines[@]}"; do print -r -- "      $l"; done
    return
  fi

  _shui_help_wrap 26 $W "$desc" 26 "$default"
  (( ${#lines} )) || { print; return; }
  used=$(( ${#lead} + ${#name} ))
  if (( used > 24 )); then
    print
  else
    print -r -- "${(l:26-used:: :)}${lines[1]}"
    shift lines
  fi
  for l in "${lines[@]}"; do print -r -- "${(l:26:: :)}$l"; done
}

# A heading, with the blank line before it unless it opens the output.
_shui_help_heading() {
  (( printed )) && print
  printed=1
  print -r -- "${_SHUI_HELP_B}${_SHUI_HELP_A}$1${_SHUI_HELP_B:+$_SHUI_HELP_R}"
}

_shui_help_render() {
  emulate -L zsh

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
  local -i tty=0 force=0 nocolor=0
  [[ -t 1 ]] && tty=1
  [[ -n ${SHUI_FORCE_TTY:-} && $SHUI_FORCE_TTY != 0 ]] && tty=1
  [[ -n ${FORCE_COLOR:-} && $FORCE_COLOR != 0 ]] && force=1
  [[ -n ${NO_COLOR:-} ]] && nocolor=1

  local _SHUI_HELP_B="" _SHUI_HELP_R="" _SHUI_HELP_A="" _SHUI_HELP_S="" _SHUI_HELP_L=""
  if (( force || (tty && !nocolor && _SHUI_COLOR_DEPTH > 0) )); then
    _SHUI_HELP_B="$SHUI_BOLD" _SHUI_HELP_R="$SHUI_RESET"
    _SHUI_HELP_A="$SHUI_COLOR_ACCENT" _SHUI_HELP_S="$SHUI_COLOR_SECONDARY"
    _SHUI_HELP_L="${SHUI_COLOR_LINK-$SHUI_COLOR_INFO}${SHUI_UNDERLINE}"
  elif (( tty && nocolor )); then
    # NO_COLOR forbids colour, not emphasis: bold keeps the structure legible.
    _SHUI_HELP_B=$'\e[1m' _SHUI_HELP_R=$'\e[0m'
  fi

  local -i _SHUI_HELP_W=${COLUMNS:-0}
  if (( _SHUI_HELP_W <= 0 )); then
    if (( tty )); then _shui_tty_size; _SHUI_HELP_W=${reply[2]}; else _SHUI_HELP_W=80; fi
  fi
  (( _SHUI_HELP_W > 80 )) && _SHUI_HELP_W=80

  local -a lines parts rows
  local row l section title
  local -i printed=0 shift4 n

  if [[ -n $name ]]; then
    print -r -- "${_SHUI_HELP_B}${name}${_SHUI_HELP_B:+$_SHUI_HELP_R}${version:+ ${_SHUI_HELP_S}${version}${_SHUI_HELP_S:+$_SHUI_HELP_R}}"
    printed=1
  fi
  if [[ -n $desc ]]; then
    lines=(); _shui_help_wrap 0 $_SHUI_HELP_W "$desc"
    print -rl -- "${lines[@]}"
    printed=1
  fi

  if (( ${#usage} )) || [[ -n $about ]]; then
    _shui_help_heading USAGE
    for row in "${usage[@]}"; do
      _shui_help_hl "$row" ""
      print -r -- "  $REPLY"
    done
    if [[ -n $about ]]; then
      (( ${#usage} )) && print
      lines=(); _shui_help_wrap 2 $_SHUI_HELP_W "$about"
      for l in "${lines[@]}"; do print -r -- "  $l"; done
    fi
  fi

  for section title in commands COMMANDS arguments ARGUMENTS options OPTIONS; do
    rows=("${(@P)section}")
    (( ${#rows} )) || continue
    _shui_help_heading "$title"
    # A long option without a short form is shifted 4 so its `--` lines up
    # under the `--` of `-p, --project` — only when some option has a short
    # form, since there is nothing to line up with otherwise — and not below 60
    # columns, where indent 6 belongs to the descriptions.
    shift4=0
    if [[ $section == options ]]; then
      for row in "${rows[@]}"; do [[ $row == -[^-]* ]] && shift4=1; done
    fi
    for row in "${rows[@]}"; do
      parts=("${(@s:|:)row}")
      if (( shift4 && _SHUI_HELP_W >= 60 )) && [[ ${parts[1]} == --* ]]; then
        _shui_help_row "${parts[1]}" "${parts[2]}" "${parts[3]}" 1
      else
        _shui_help_row "${parts[1]}" "${parts[2]}" "${parts[3]}"
      fi
    done
  done

  if (( ${#examples} )); then
    _shui_help_heading EXAMPLES
    n=0
    for row in "${examples[@]}"; do
      (( n++ )) && print
      if [[ $row == *\|* ]]; then
        print -r -- "  ${_SHUI_HELP_S}# ${row%%|*}${_SHUI_HELP_S:+$_SHUI_HELP_R}"
        row="${row#*|}"
      fi
      print -r -- "  ${_SHUI_HELP_S}\$${_SHUI_HELP_S:+$_SHUI_HELP_R} ${row}"
    done
  fi

  if (( ${#envs} )); then
    _shui_help_heading ENVIRONMENT
    for row in "${envs[@]}"; do
      parts=("${(@s:|:)row}")
      _shui_help_row "${parts[1]}" "${parts[2]}" "${parts[3]}"
    done
  fi

  if (( ${#sees} )); then
    _shui_help_heading "SEE ALSO"
    for row in "${sees[@]}"; do
      print -r -- "  ${_SHUI_HELP_L}${row}${_SHUI_HELP_L:+$_SHUI_HELP_R}"
    done
  fi
}
