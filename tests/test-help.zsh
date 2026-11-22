#!/usr/bin/env zsh
#
# Tests for `shui help`, the shared CLI help layout.
#
# tests/golden/help/ holds @kud/ink-ui's byte contract for the layout: the
# deploy.*.txt files are copied verbatim from ink-ui's
# src/components/help.golden/, and deploy.zsh is its deploy.json written as
# shui help flags. shui must reproduce every file byte for byte, so the two
# renderers cannot drift apart. When ink-ui changes the layout on purpose, copy
# its new golden files here and make shui match them; never edit them by hand.
#
# Run: zsh tests/test-help.zsh
#

SHUI_DIR="${0:A:h}/.."
source "${0:A:h}/_harness.zsh"

_t_title "help"

_GOLDEN="${0:A:h}/golden/help"
_tmp=$(mktemp -d)
trap 'rm -rf "$_tmp"' EXIT

# Render in a clean child into $_tmp/out: $1 is the environment, $2 the shui
# call (the deploy fixture when omitted). Bytes go to a file, not through $(…),
# so the final newline is part of what is compared.
_render() {
  env -u FORCE_COLOR -u NO_COLOR -u COLORTERM -u SHUI_FORCE_TTY -u COLUMNS \
    SHUI_ICONS=none SHUI_THEME=default TERM=xterm $=1 \
    zsh -c "source '${SHUI_DIR}/shui.zsh'; ${2:-source '${_GOLDEN}/deploy.zsh'}" >"$_tmp/out" 2>"$_tmp/err"
}

_golden() {
  local desc="$1" file="${_GOLDEN}/$2"
  if cmp -s "$file" "$_tmp/out"; then
    _t_pass "$desc"
  else
    _t_fail "$desc"
    diff <(cat -v "$file") <(cat -v "$_tmp/out") | sed 's/^/      /' | head -20
    _FAILURES+=("✗ ${desc}: differs from ${file:t}")
  fi
}

# The headings of a rendering, in order, on one line.
_headings() { grep -E '^[A-Z][A-Z ]+$' "$_tmp/out" | paste -sd " " -; }

# ---------------------------------------------------------------------------
_t_section "byte for byte with @kud/ink-ui"

_render 'SHUI_FORCE_TTY=1 COLORTERM=truecolor COLUMNS=80'
_golden "truecolor terminal"       deploy.tty.txt
_render 'SHUI_FORCE_TTY=1 TERM=xterm-256color COLUMNS=80'
_golden "256-colour terminal"      deploy.ansi256.txt
_render 'SHUI_FORCE_TTY=1 TERM=xterm COLUMNS=80'
_golden "16-colour terminal"       deploy.ansi16.txt
_render 'SHUI_FORCE_TTY=1 NO_COLOR=1 TERM=xterm-256color COLUMNS=80'
_golden "terminal under NO_COLOR"  deploy.no-color.txt
_render 'COLUMNS=80'
_golden "piped"                    deploy.piped.txt
_render 'COLUMNS=50'
_golden "piped, 50 columns"        deploy.narrow.txt

# ---------------------------------------------------------------------------
_t_section "modes"

_render 'COLORTERM=truecolor COLUMNS=80'
assert_not_contains "a pipe gets no escape, whatever the terminal advertises" $'\e' "$(<$_tmp/out)"
_render 'FORCE_COLOR=1 TERM=xterm-256color COLUMNS=80'
assert_contains "FORCE_COLOR colours a pipe" $'\e[1;38;5;208mUSAGE\e[0m' "$(<$_tmp/out)"
_render 'SHUI_FORCE_TTY=1 COLORTERM=24bit COLUMNS=80'
assert_contains "COLORTERM=24bit is truecolor" $'\e[38;2;153;153;153m2.4.0' "$(<$_tmp/out)"
_render 'SHUI_FORCE_TTY=1 SHUI_THEME=plain COLUMNS=80'
assert_contains "the theme does not change the layout's colours" $'\e[1;33mUSAGE' "$(<$_tmp/out)"
_render 'COLUMNS=120'
cp "$_tmp/out" "$_tmp/wide"
_render 'COLUMNS=80'
assert_eq "width capped at 80" "$(<$_tmp/out)" "$(<$_tmp/wide)"

# ---------------------------------------------------------------------------
_t_section "input"

_render 'COLUMNS=80' 'shui help --name x --command "a|  spread   out  text."'
assert_contains "descriptions normalised" "  a                       Spread out text" "$(<$_tmp/out)"
_render 'COLUMNS=80' 'shui help --name x --command "a|ends with an ellipsis.."'
assert_contains "a double full stop is kept" "Ends with an ellipsis.." "$(<$_tmp/out)"
_render 'COLUMNS=80' 'shui help --name x --command "a|b"'
assert_eq "empty sections are left out" $'x\n\nCOMMANDS\n  a                       B' "$(<$_tmp/out)"
_render 'COLUMNS=80' 'shui help --name=x --command="a|b"'
assert_eq "--flag=value and --flag value agree" $'x\n\nCOMMANDS\n  a                       B' "$(<$_tmp/out)"
_render 'COLUMNS=80' 'shui help --name=x "--option=--only|Long only"'
assert_contains "no shift when no option has a short form" $'\n  --only' "$(<$_tmp/out)"
_render 'COLUMNS=80' 'shui help --name=x --about="A note"'
assert_not_contains "a note without usage lines is left out" "A note" "$(<$_tmp/out)"
_render 'COLUMNS=80' 'shui help --bogus=1'
assert_contains "an unknown flag is refused" "unknown flag '--bogus'" "$(<$_tmp/err)"
_render 'COLUMNS=80' 'shui help --name'
assert_contains "a flag missing its value is refused" "--name needs a value" "$(<$_tmp/err)"

# ---------------------------------------------------------------------------
_t_section "shui's own help"

_render 'COLUMNS=80' 'shui help'
assert_not_contains "no escape when piped" $'\e' "$(<$_tmp/out)"
assert_contains "header" "shui " "$(head -1 "$_tmp/out")"
assert_eq "sections in order" "USAGE COMMANDS EXAMPLES ENVIRONMENT SEE ALSO" "$(_headings)"
_out=$(<$_tmp/out)
assert_eq "no glyph or emoji (ASCII, plus … in placeholders)" "" "${_out//[[:ascii:]…]/}"
_render 'COLUMNS=80' 'shui'
assert_eq "shui with no argument is shui help" "$_out" "$(<$_tmp/out)"
_render 'COLUMNS=80' 'shui help confirm'
assert_contains "shui help <command> is the command's help" "Usage: shui confirm" "$(<$_tmp/out)"
_render 'COLUMNS=80' 'shui help --help'
assert_contains "shui help --help documents the flags" "--option=<name|desc[|default]>" "$(<$_tmp/out)"

_t_results
