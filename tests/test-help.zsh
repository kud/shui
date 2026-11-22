#!/usr/bin/env zsh
#
# Tests for `shui help`, the shared CLI help layout.
#
# Golden files in tests/golden/ hold one fixture rendered four ways: colour on a
# terminal, a terminal under NO_COLOR, a pipe, and a 50-column pipe. Any change
# to the layout shows up as a diff against them. SHUI_FORCE_TTY stands in for
# the terminal. After an intended change, regenerate and review the diff:
#
#   SHUI_UPDATE_GOLDEN=1 zsh tests/test-help.zsh
#
# Run: zsh tests/test-help.zsh
#

SHUI_DIR="${0:A:h}/.."
source "${0:A:h}/_harness.zsh"

_t_title "help"

_GOLDEN="${0:A:h}/golden"

# The fixture: every section, a placeholder in a name, an option with a default,
# long-only options, a name over 22 columns, a description that wraps.
_fixture='shui help --name acme-cli --version 1.4.0 --desc "Ship static folders to Acme hosting" \
  --usage "acme-cli <command> [options]" \
  --usage "acme-cli deploy <dir> [--force]" \
  --about "Every command reads acme.json from the current folder when it exists; the flags below override it." \
  --command "deploy <dir>|Upload a folder and publish it" \
  --command "login|Store an API token for later commands" \
  --command "rollback <deployment-id…>|Restore one or more earlier deployments and make the latest of them live" \
  --argument "<dir>|Folder to upload" \
  --option "-p, --project <id>|Project to act on|from acme.json" \
  --option "-f, --force|Skip the confirmation prompt" \
  --option "--dry-run|Show what would be uploaded without sending anything" \
  --option "--region <name>|Data centre to deploy to|eu-west" \
  --example "Publish the build folder|acme-cli deploy dist" \
  --example "acme-cli rollback d_8f2c" \
  --env "ACME_TOKEN|API token, used when no login is stored" \
  --env "ACME_CONFIG_DIRECTORY_OVERRIDE|Where tokens are kept" \
  --see "https://acme.dev/docs/cli"'

# Render in a clean child: $1 is the environment, $2 the shui call.
_render() {
  env -u FORCE_COLOR -u NO_COLOR -u SHUI_FORCE_TTY -u COLUMNS \
    SHUI_ICONS=none SHUI_THEME=default TERM=xterm-256color $=1 \
    zsh -c "source '${SHUI_DIR}/shui.zsh'; ${2:-$_fixture}"
}

# The headings of a rendering, in order, on one line.
_headings() { print -r -- "$1" | grep -E '^[A-Z][A-Z ]+$' | paste -sd " " -; }

_golden() {
  local desc="$1" file="${_GOLDEN}/$2" actual="$3"
  if [[ -n ${SHUI_UPDATE_GOLDEN:-} ]]; then
    mkdir -p "$_GOLDEN"
    print -r -- "$actual" > "$file"
    _t_pass "${desc} (golden written)"
    return
  fi
  if [[ ! -f $file ]]; then
    _t_fail "${desc}: ${file:t} is missing"
    _FAILURES+=("✗ ${desc}: golden file missing")
    return
  fi
  if [[ "$actual" == "$(<$file)" ]]; then
    _t_pass "$desc"
  else
    _t_fail "$desc"
    diff <(print -r -- "$(<$file)" | cat -v) <(print -r -- "$actual" | cat -v) | sed 's/^/      /' | head -20
    _FAILURES+=("✗ ${desc}: differs from ${file:t}")
  fi
}

# ---------------------------------------------------------------------------
_t_section "golden renderings"

if [[ "$(TERM=xterm-256color tput colors 2>/dev/null)" == 256 ]]; then
  _golden "colour on a terminal" help-color.txt "$(_render 'SHUI_FORCE_TTY=1 COLUMNS=80')"
else
  _t_pass "SKIPPED colour golden: no 256-colour terminfo for xterm-256color here"
fi
_golden "terminal under NO_COLOR" help-nocolor.txt "$(_render 'SHUI_FORCE_TTY=1 NO_COLOR=1 COLUMNS=80')"
_golden "piped"                   help-plain.txt   "$(_render 'COLUMNS=80')"
_golden "piped, 50 columns"       help-narrow.txt  "$(_render 'COLUMNS=50')"

# ---------------------------------------------------------------------------
_t_section "modes"

_out=$(_render 'COLUMNS=80')
assert_not_contains "a pipe gets no escape at all" $'\e' "$_out"
_out=$(_render 'SHUI_FORCE_TTY=1 NO_COLOR=1 COLUMNS=80')
assert_contains     "NO_COLOR keeps bold" $'\e[1m' "$_out"
assert_not_contains "NO_COLOR drops every colour" $'\e[3' "$_out"
_out=$(_render 'FORCE_COLOR=1 COLUMNS=80')
assert_contains     "FORCE_COLOR colours a pipe" $'\e[38;5;110mUSAGE' "$_out"
_out=$(_render 'SHUI_FORCE_TTY=1 COLUMNS=80')
assert_contains     "headings bold in the accent colour" $'\e[1m\e[38;5;110mOPTIONS\e[0m' "$_out"
assert_contains     "version in secondary" $'\e[1macme-cli\e[0m \e[38;5;246m1.4.0\e[0m' "$_out"
assert_contains     "placeholder in a name in secondary" $'\e[1mdeploy \e[0m\e[38;5;246m<dir>\e[0m' "$_out"
assert_contains     "default as one secondary run" $'\e[38;5;246m(default: eu-west)\e[0m' "$_out"
assert_contains     "example \$ in secondary" $'\e[38;5;246m$\e[0m acme-cli deploy dist' "$_out"
assert_contains     "see-also link underlined" $'\e[4mhttps://acme.dev/docs/cli\e[0m' "$_out"
assert_not_contains "descriptions never dimmed" $'\e[2m' "$_out"

# ---------------------------------------------------------------------------
_t_section "layout"

_out=$(_render 'COLUMNS=80')
assert_contains "description at column 26" \
  "  login                   Store an API token" "$_out"
assert_contains "long-only option shifted 4" \
  "      --dry-run           Show what" "$_out"
assert_contains "name over 22 alone, description under it" \
  $'  ACME_CONFIG_DIRECTORY_OVERRIDE\n                          Where tokens are kept' "$_out"
assert_contains "wrapped text hangs at 26" \
  $'make the\n                          latest of them live' "$_out"
assert_contains "sections in order" \
  "USAGE COMMANDS ARGUMENTS OPTIONS EXAMPLES ENVIRONMENT SEE ALSO" \
  "$(_headings "$_out")"
_long=0
for _l in "${(f)_out}"; do (( ${#_l} > 80 )) && _long=1; done
assert_eq "no line over 80 columns" 0 $_long
_out=$(_render 'COLUMNS=120')
assert_eq "width capped at 80" "$(_render 'COLUMNS=80')" "$_out"
_out=$(_render 'COLUMNS=50')
assert_contains "below 60, descriptions drop to indent 6" \
  $'  login\n      Store an API token' "$_out"

_out=$(_render 'COLUMNS=80' 'shui help --name=x "--option=--only|Long only"')
assert_contains "no shift when no option has a short form" "  --only" "$_out"
assert_not_contains "no shift when no option has a short form (indent)" "      --only" "$_out"

_out=$(_render 'COLUMNS=80' 'shui help --name x --command "a|b"')
assert_eq "empty sections are left out" $'x\n\nCOMMANDS\n  a                       b' "$_out"
assert_eq "--flag=value and --flag value agree" "$_out" \
  "$(_render 'COLUMNS=80' 'shui help --name=x --command="a|b"')"

_out=$(_render 'COLUMNS=80' 'shui help --bogus=1' 2>&1)
assert_contains "unknown flag is refused" "unknown flag '--bogus'" "$_out"
_render 'COLUMNS=80' 'shui help --name' >/dev/null 2>&1
assert_eq "a flag missing its value exits 1" 1 $?

# ---------------------------------------------------------------------------
_t_section "shui's own help"

_out=$(_render 'COLUMNS=80' 'shui help')
assert_not_contains "no escape when piped" $'\e' "$_out"
assert_contains "header" $'shui ' "${${(f)_out}[1]}"
assert_contains "sections in order" "USAGE COMMANDS EXAMPLES ENVIRONMENT SEE ALSO" \
  "$(_headings "$_out")"
assert_eq "no glyph or emoji (ASCII, plus … in placeholders)" "" \
  "${_out//[[:ascii:]…]/}"
assert_eq "shui with no argument is shui help" "$_out" "$(_render 'COLUMNS=80' 'shui')"
assert_contains "shui help <command> is the command's help" "Usage: shui confirm" \
  "$(_render 'COLUMNS=80' 'shui help confirm')"
assert_contains "shui help --help documents the flags" "--option=<name|desc[|default]>" \
  "$(_render 'COLUMNS=80' 'shui help --help')"

_t_results
