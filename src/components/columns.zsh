#!/usr/bin/env zsh
#
# Columns for `shui multiselect --columns=…`: a small cell markup, the column
# fitting that decides what a width can show, and the renderer that draws the
# list, its header, a detail pane and a footer. The flag parsing and the key
# loop live in interactive.zsh; this file only draws.
#

# The space between two columns.
typeset -gi _SHUI_COLUMN_GAP=2
# The narrowest a flexible column may get before other columns start to drop.
typeset -gi _SHUI_COLUMN_FLEX_MIN=12
# A detail pane never grows past this many lines, its rule included.
typeset -gi _SHUI_PANE_MAX=6

# _shui_markup <text> [max-width] [base-sgr]
#
# Cell text with colour spans, mapped to theme tokens rather than raw escapes:
#
#   {style:text}   paints text; style is success, warning, error, info, muted
#                  or bold. Spans do not nest.
#   {{  }}         a literal { (anywhere) or } (inside a span; outside one a }
#                  is always literal)
#
# Anything else in braces (an unknown style, a lone {, a span never closed) is
# drawn as written, so foreign text cannot be misread as markup. Callers escape
# such text with ${s//\{/{{} all the same.
#
# The text is cut to max-width columns, ending in …, before any escape is added:
# cutting a rendered string would count escape bytes as width. A base SGR is
# re-applied after every span, so a whole cell can be bold or muted.
#
# Sets reply=(rendered visible-width). Pure: no terminal needed.
_shui_markup() {
  emulate -L zsh
  setopt extended_glob
  local text="$1" base="${3:-}" plain="" name rest body REPLY
  local -i max=${2:--1} ok
  local -a seg_style seg_text

  while [[ -n "$text" ]]; do
    if [[ "$text" != *'{'* ]]; then
      plain+="$text"
      break
    fi
    plain+="${text%%\{*}"
    text="${text#*\{}"
    if [[ "$text" == '{'* ]]; then
      plain+='{'
      text="${text#\{}"
      continue
    fi
    if [[ "$text" == (#b)(success|warning|error|info|muted|bold):(*) ]]; then
      name=$match[1] rest=$match[2] body="" ok=0
      while [[ "$rest" == *'}'* ]]; do
        body+="${rest%%\}*}"
        rest="${rest#*\}}"
        if [[ "$rest" == '}'* ]]; then
          body+='}'
          rest="${rest#\}}"
          continue
        fi
        ok=1
        break
      done
      if (( ok )); then
        [[ -n "$plain" ]] && { seg_style+=(""); seg_text+=("$plain"); plain=""; }
        seg_style+=("$name")
        seg_text+=("$body")
        text="$rest"
        continue
      fi
    fi
    plain+='{'
  done
  [[ -n "$plain" ]] && { seg_style+=(""); seg_text+=("$plain"); }

  local -i i total=0 budget cut=0
  for (( i = 1; i <= ${#seg_text}; i++ )); do
    _shui_plain "${seg_text[i]}"
    seg_text[i]="$REPLY"
    (( total += ${(m)#REPLY} ))
  done

  if (( max >= 0 && total > max )); then
    cut=1
    budget=$(( max - 1 ))
    total=0
    for (( i = 1; i <= ${#seg_text}; i++ )); do
      if (( budget <= 0 )); then
        seg_text[i]=""
        continue
      fi
      body="${seg_text[i]}"
      while (( ${(m)#body} > budget )); do body="${body[1,-2]}"; done
      seg_text[i]="$body"
      (( budget -= ${(m)#body} ))
      (( total += ${(m)#body} ))
    done
  fi

  local out="$base" token
  for (( i = 1; i <= ${#seg_text}; i++ )); do
    [[ -n "${seg_text[i]}" ]] || continue
    case "${seg_style[i]}" in
      success) token="$SHUI_COLOR_SUCCESS" ;;
      warning) token="$SHUI_COLOR_WARNING" ;;
      error)   token="$SHUI_COLOR_ERROR" ;;
      info)    token="$SHUI_COLOR_INFO" ;;
      muted)   token="$SHUI_COLOR_MUTED" ;;
      bold)    token="$SHUI_BOLD" ;;
      *)       out+="${seg_text[i]}"; continue ;;
    esac
    out+="${token}${seg_text[i]}${SHUI_RESET}${base}"
  done
  if (( cut && max > 0 )); then
    out+="…"
    (( total++ ))
  fi
  [[ -n "$base" ]] && out+="$SHUI_RESET"
  reply=("$out" $total)
}

# _shui_columns_parse <spec> — checks a --columns spec, "align:width:drop,…":
# align l or r, width a number or * (the one flexible column, optionally *N for
# a minimum of N, at least 12), drop a whole number. Sets reply to one
# "align width drop min" word list per column, width 0 for the flexible one.
# Returns 1, with the reason in REPLY, when the spec is malformed.
_shui_columns_parse() {
  emulate -L zsh
  local spec="$1" entry
  local -a parts out
  local -i flex=0 k=0
  REPLY=""
  if [[ -z "$spec" ]]; then
    REPLY="--columns is empty"
    return 1
  fi
  for entry in "${(@s:,:)spec}"; do
    (( k++ ))
    parts=("${(@s.:.)entry}")
    if (( ${#parts} != 3 )) || [[ "${parts[1]}" != (l|r) || "${parts[3]}" != <-> ]]; then
      REPLY="column $k: '$entry' is not align:width:drop"
      return 1
    fi
    if [[ "${parts[2]}" == \*(<->|) ]]; then
      (( flex++ ))
      local -i min=${${parts[2]#\*}:-$_SHUI_COLUMN_FLEX_MIN}
      (( min < _SHUI_COLUMN_FLEX_MIN )) && min=$_SHUI_COLUMN_FLEX_MIN
      out+=("${parts[1]} 0 ${parts[3]} $min")
    elif [[ "${parts[2]}" == <1-> ]]; then
      out+=("${parts[1]} ${parts[2]} ${parts[3]} 0")
    else
      REPLY="column $k: width '${parts[2]}' is not a number or *"
      return 1
    fi
  done
  if (( flex > 1 )); then
    REPLY="only one column may be *"
    return 1
  fi
  reply=("${out[@]}")
}

# _shui_columns_fit <room> <spec> — which columns a row of <room> terminal
# columns can show. Fixed widths come from the spec, never from the cells, so
# the layout stays put while the list scrolls. While the flexible column would
# fall under its minimum, the column with the highest drop number goes (the
# rightmost first among equals); drop 0 never goes.
#
# Sets reply=(flex-width index…), indexes counted from 1; flex-width is 0 when
# the spec has no flexible column. Returns 1 for a malformed spec. Pure.
_shui_columns_fit() {
  emulate -L zsh
  local -i room=$1 i fixed flex best victim flex_idx=0 flex_min=0
  local -a cols visible words
  _shui_columns_parse "$2" || return 1
  cols=("${reply[@]}")
  for (( i = 1; i <= ${#cols}; i++ )); do
    visible+=($i)
    words=(${=cols[i]})
    if (( words[2] == 0 )); then
      flex_idx=$i
      flex_min=${words[4]}
    fi
  done

  while true; do
    fixed=$(( (${#visible} - 1) * _SHUI_COLUMN_GAP ))
    for i in "${visible[@]}"; do
      words=(${=cols[i]})
      (( fixed += words[2] ))
    done
    flex=$(( room - fixed ))
    if (( flex_idx )); then
      (( flex >= flex_min )) && break
    else
      (( flex >= 0 )) && break
    fi
    best=0 victim=0
    for i in "${visible[@]}"; do
      words=(${=cols[i]})
      (( words[3] > 0 && words[3] >= best )) && { best=${words[3]}; victim=$i; }
    done
    (( victim )) || break
    visible=(${visible:#$victim})
  done

  # Last resort, for a terminal too narrow even for the columns that never
  # drop: shrink the flexible column to what is left, then shed fixed columns
  # from the right, so no row is ever wider than the room it has.
  if (( flex_idx && flex < flex_min )); then
    while (( flex < 1 && ${#visible} > 1 )); do
      victim=0
      for i in "${visible[@]}"; do (( i != flex_idx )) && victim=$i; done
      (( victim )) || break
      visible=(${visible:#$victim})
      words=(${=cols[victim]})
      (( flex += words[2] + _SHUI_COLUMN_GAP ))
    done
  elif (( ! flex_idx )); then
    while (( flex < 0 && ${#visible} > 1 )); do
      victim=${visible[-1]}
      visible=(${visible:#$victim})
      words=(${=cols[victim]})
      (( flex += words[2] + _SHUI_COLUMN_GAP ))
    done
  fi

  if (( flex_idx )); then
    (( flex < 1 )) && flex=1
  else
    flex=0
  fi
  reply=($flex "${visible[@]}")
}

# One row of cells laid out by the fit above: each cell cut to its width and
# padded to it, left or right, columns joined by the gap. $1 is the row's cells
# joined by tabs, $2 the base SGR for every cell, $3 the base SGR for the
# flexible cell (the cursor row's bold). Reads the caller's col_spec (from
# _shui_columns_parse), col_show and col_flex. Sets REPLY and reply=(line width).
_shui_columns_line() {
  local -a cells=("${(@ps:\t:)1}") words
  local line="" base cell _sp=""
  local -i k first=1 w pad width=0
  for k in "${col_show[@]}"; do
    words=(${=col_spec[k]})
    w=${words[2]}
    base="$2"
    if (( w == 0 )); then
      w=$col_flex
      [[ -n "$3" ]] && base="$3"
    fi
    _shui_markup "${cells[k]}" $w "$base"
    cell="${reply[1]}"
    pad=$(( w - reply[2] ))
    (( pad < 0 )) && pad=0
    (( first )) || { line+="${(l:_SHUI_COLUMN_GAP:)_sp}"; (( width += _SHUI_COLUMN_GAP )); }
    first=0
    if [[ "${words[1]}" == r ]]; then
      line+="${(l:pad:)_sp}${cell}"
    else
      line+="${cell}${(l:pad:)_sp}"
    fi
    (( width += w ))
  done
  reply=("$line" $width)
}

# One frame of a column list, drawn over the previous one: the header, the
# list window and its position line, the detail pane for the cursor row, and
# the footer. The prompt and key lines above it are drawn once, by the caller.
#
# Reads the caller's n, cursor, selected, col_spec_text, col_rows (the cells of
# each row, tab-joined), col_header, col_head_rows (rows taken by the lines above
# the frame), col_details, col_pane_h, col_footer and col_has_footer; updates
# top, page and drawn, as _shui_list_render does.
#
# Too short a terminal gives up the pane first, then the header, so the list
# keeps room to move in: the rows already carry what the pane repeats.
_shui_list_render_columns() {
  local -a reply col_spec col_show
  local REPLY _sp=""
  local -i col_flex
  _shui_tty_size
  local -i rows=${reply[1]} cols=${reply[2]}
  local -i limit=$(( cols - 1 ))

  _shui_list_glyphs
  local pointer=$reply[1] on=$reply[2] off=$reply[3]
  local blank="${(l:${(m)#pointer}:)_sp}"
  local -i prefix_w=$(( 2 + ${(m)#pointer} + 1 + ${(m)#on} + 1 ))

  _shui_columns_parse "$col_spec_text"
  col_spec=("${reply[@]}")
  _shui_columns_fit $(( limit - prefix_w )) "$col_spec_text"
  col_flex=${reply[1]}
  col_show=("${reply[@]:1}")

  local -i show_header=$(( ${#col_header} > 0 ))
  local -i pane_rows=$(( col_pane_h > 0 ? col_pane_h + 1 : 0 ))
  local -i foot_rows=$(( col_has_footer ? 2 : 0 ))
  local -i avail=$(( rows - 1 - col_head_rows - show_header - pane_rows - foot_rows ))
  if (( avail < 5 && pane_rows )); then
    (( avail += pane_rows ))
    pane_rows=0
  fi
  if (( avail < 3 && show_header )); then
    (( avail += 1 ))
    show_header=0
  fi
  (( avail < 1 )) && avail=1

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

  local -i i w
  local line check

  if (( show_header )); then
    _shui_columns_line "$col_header" "$SHUI_COLOR_MUTED" ""
    printf '\033[2K\r%*s%s\n' $prefix_w "" "${reply[1]}"
    drawn+=($(( prefix_w + reply[2] )))
  fi

  for (( i = top; i < top + height; i++ )); do
    if (( selected[$i] )); then
      check="${SHUI_COLOR_SUCCESS}${on}${SHUI_RESET}"
    else
      check="${SHUI_COLOR_MUTED}${off}${SHUI_RESET}"
    fi
    if (( i == cursor )); then
      _shui_columns_line "${col_rows[$i]}" "" "$SHUI_BOLD"
      printf '\033[2K\r  %s%s%s %s %s\n' \
        "$SHUI_COLOR_PRIMARY" "$pointer" "$SHUI_RESET" "$check" "${reply[1]}"
    else
      _shui_columns_line "${col_rows[$i]}" "" ""
      printf '\033[2K\r  %s %s %s\n' "$blank" "$check" "${reply[1]}"
    fi
    drawn+=($(( prefix_w + reply[2] )))
  done

  if (( marker )); then
    local position="$top–$(( top + height - 1 )) of $n"
    local -i ticked=0
    for (( i = 1; i <= n; i++ )); do (( selected[$i] )) && (( ticked++ )); done
    (( ticked )) && position+=" · $ticked selected"
    _shui_fit "$position" $(( limit - 2 ))
    printf '\033[2K\r  %s%s%s\n' "$SHUI_COLOR_MUTED" "$REPLY" "$SHUI_RESET"
    drawn+=($(( 2 + ${(m)#REPLY} )))
  fi

  if (( pane_rows )); then
    printf '\033[2K\r\n'
    drawn+=(0)
    local -a pane=("${(@f)col_details[$cursor]}")
    local rule_char='─' rule
    [[ "${_SHUI_ICONS:-}" == ascii ]] && rule_char='-'
    # The rule: "── <text> ───…", muted, the full width.
    _shui_markup "${pane[1]:-}" $(( limit - 2 - 4 )) "$SHUI_COLOR_MUTED"
    if (( reply[2] )); then
      w=$(( limit - 2 - 4 - reply[2] ))
      (( w < 0 )) && w=0
      rule="${SHUI_COLOR_MUTED}${rule_char}${rule_char} ${SHUI_RESET}${reply[1]}${SHUI_COLOR_MUTED} ${(pl:w::$rule_char:)_sp}${SHUI_RESET}"
    else
      rule="${SHUI_COLOR_MUTED}${(pl:limit-2::$rule_char:)_sp}${SHUI_RESET}"
    fi
    printf '\033[2K\r  %s\n' "$rule"
    drawn+=($(( limit )))
    for (( i = 2; i <= col_pane_h; i++ )); do
      if (( i <= ${#pane} )) && [[ -n "${pane[i]}" ]]; then
        _shui_markup "${pane[i]}" $(( limit - 2 )) ""
        printf '\033[2K\r  %s\n' "${reply[1]}"
        drawn+=($(( 2 + reply[2] )))
      else
        printf '\033[2K\r\n'
        drawn+=(0)
      fi
    done
  fi

  if (( foot_rows )); then
    printf '\033[2K\r\n'
    drawn+=(0)
    _shui_markup "$col_footer" $(( limit - 2 )) ""
    printf '\033[2K\r  %s\n' "${reply[1]}"
    drawn+=($(( 2 + reply[2] )))
  fi

  (( ${#drawn} < climbed )) && printf '\033[J'
  return 0
}
