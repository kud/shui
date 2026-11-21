#!/usr/bin/env zsh
#
# The pure helpers behind `multiselect --columns`, no terminal needed:
#
#   - _shui_markup: {style:text} spans mapped to theme tokens, the {{ and }}
#     escapes, literal text for anything else, widths measured without markup,
#     and the cut made on visible text before any escape is added
#   - _shui_columns_parse / _shui_columns_fit: the spec grammar, and which
#     columns a given width can show
#
# The drawn frames are covered through a pseudo-terminal in test-tty.zsh.
# Run: zsh tests/test-columns.zsh
#

SHUI_DIR="${0:A:h}/.."
source "${0:A:h}/_harness.zsh"

unset ITERM_SESSION_ID
export SHUI_ICONS=nerd
export SHUI_THEME=minimal
source "${SHUI_DIR}/shui.zsh"

_t_title "test-columns"

_m() { local -a reply; _shui_markup "$@"; print -r -- "${reply[1]}|${reply[2]}"; }
G=$SHUI_COLOR_SUCCESS R=$SHUI_COLOR_ERROR D=$SHUI_COLOR_MUTED B=$SHUI_BOLD Z=$SHUI_RESET

# ---------------------------------------------------------------------------
# 1. _shui_markup
# ---------------------------------------------------------------------------
_t_section "_shui_markup: spans"

assert_eq "plain text is unchanged"           "1.2.0|5"                  "$(_m 1.2.0)"
assert_eq "a span inside a cell"              "1.2.${G}1${Z}|5"          "$(_m '1.2.{success:1}')"
assert_eq "two spans, text between"           "${D}a${Z} · ${R}b${Z}|5"  "$(_m '{muted:a} · {error:b}')"
assert_eq "bold is a style too"               "${B}x${Z}|1"              "$(_m '{bold:x}')"
assert_eq "every style maps to its token"     "${SHUI_COLOR_WARNING}w${Z}${SHUI_COLOR_INFO}i${Z}|2" \
  "$(_m '{warning:w}{info:i}')"

_t_section "_shui_markup: escapes and literal braces"

assert_eq "{{ is a literal {"                 "{x}|3"         "$(_m '{{x}')"
assert_eq "}} inside a span is a literal }"   "${G}a}b${Z}|3" "$(_m '{success:a}}b}')"
assert_eq "} outside a span is literal"       "a}b|3"         "$(_m 'a}b')"
assert_eq "an unknown style is drawn as written" "{primary:x}|11" "$(_m '{primary:x}')"
assert_eq "a lone { is drawn as written"      "a { b|5"       "$(_m 'a { b')"
assert_eq "an unclosed span is drawn as written" "{bold:open|10" "$(_m '{bold:open')"
assert_eq "spans do not nest: drawn as written" "{success:{bold:x}}|18" "$(_m '{success:{bold:x}}')"
_s='brace {in} a description'
assert_eq "the documented escape keeps foreign text literal" "${_s}|${#_s}" "$(_m "${_s//\{/{{}")"

_t_section "_shui_markup: widths and the cut"

assert_eq "wide characters count two"         "日本${R}語${Z}|6"  "$(_m '日本{error:語}')"
assert_eq "control characters become spaces"  "a b|3"             "$(_m $'a\tb')"
assert_eq "raw escapes never reach the cell"  "ab|2"              "$(_m $'a\e[31mb')"
assert_eq "fits: not cut"                     "hello|5"           "$(_m hello 5)"
assert_eq "cut on visible text, then …"       "hello ${G}w${Z}…|8" "$(_m 'hello {success:world}' 8)"
assert_eq "a cut wide character is not split" "日…|3"             "$(_m 日本語 4)"
assert_eq "no room: empty"                    "|0"                "$(_m hello 0)"
assert_eq "a base style wraps the cell and returns after each span" \
  "${D}a ${G}b${Z}${D} c${Z}|5" "$(_m 'a {success:b} c' -1 "$D")"

_t_section "_shui_markup under plain"

_out=$(SHUI_THEME=plain zsh -fc "source '${SHUI_DIR}/shui.zsh'; local -a reply; _shui_markup '3.8.{success:14} {bold:MAJOR}'; print -r -- \"\${reply[1]}|\${reply[2]}\"")
assert_eq "markup simply disappears" "3.8.14 MAJOR|12" "$_out"

# ---------------------------------------------------------------------------
# 2. _shui_columns_parse
# ---------------------------------------------------------------------------
_t_section "_shui_columns_parse"

_p() { local -a reply; local REPLY; _shui_columns_parse "$1"; local rc=$?; print -r -- "$rc ${(j:,:)reply}${REPLY:+ $REPLY}"; }
assert_eq "fixed and flexible columns" "0 l 3 1 0,l 0 0 12,r 5 0 0" "$(_p 'l:3:1,l:*:0,r:5:0')"
assert_eq "a flexible minimum"         "0 l 0 0 30"                  "$(_p 'l:*30:0')"
assert_eq "a minimum under 12 is 12"   "0 l 0 0 12"                  "$(_p 'l:*4:0')"
assert_contains "two flexible columns are refused" "1 " "$(_p 'l:*:0,r:*:0')"
assert_contains "a bad align is refused"           "1 " "$(_p 'x:3:0')"
assert_contains "a bad width is refused"           "1 " "$(_p 'l:0:0')"
assert_contains "a missing part is refused"        "1 " "$(_p 'l:3')"
assert_contains "an empty spec is refused"         "1 " "$(_p '')"

# ---------------------------------------------------------------------------
# 3. _shui_columns_fit
# ---------------------------------------------------------------------------
_t_section "_shui_columns_fit"

# A six-column spec: a 3-wide mark, the flexible name, a 23-wide version span,
# an 8-wide word, a 4-wide meter and a 5-wide time. The room passed is the
# terminal's columns less one and less a 6-column pointer-and-box prefix.
_spec='l:3:1,l:*:0,r:23:3,l:8:0,l:4:2,r:5:0'
_f() { local -a reply; _shui_columns_fit $(( $1 - 7 )) "$2"; print -r -- "${reply[*]}"; }
assert_eq "120 columns: everything"            "60 1 2 3 4 5 6" "$(_f 120 $_spec)"
assert_eq "100 columns: everything"            "40 1 2 3 4 5 6" "$(_f 100 $_spec)"
assert_eq "80 columns: the flex still fits"    "20 1 2 3 4 5 6" "$(_f 80 $_spec)"
assert_eq "60 columns: drop 3 goes first"      "25 1 2 4 5 6"   "$(_f 60 $_spec)"
assert_eq "40 columns: then drop 2, then 1"    "16 2 4 6"       "$(_f 40 $_spec)"
assert_eq "a flex minimum drops columns sooner" "64 1 2 4 5 6"  "$(_f 99 'l:3:1,l:*40:0,r:23:3,l:8:0,l:4:2,r:5:0')"
assert_eq "too narrow for the never-drop columns: sheds from the right" "5 2" "$(_f 12 $_spec)"
assert_eq "no flexible column: fixed ones drop until they fit" "0 1 3" "$(_f 20 'l:4:0,l:9:1,r:5:0')"
assert_eq "a malformed spec fails" "1" "$(_shui_columns_fit 80 'l:*:0,l:*:0' >/dev/null; print $?)"

_t_results
