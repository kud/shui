#!/usr/bin/env zsh
#
# shui · 水  —  fluid terminal UI for Zsh
# https://github.com/kud/shui
#

SHUI_VERSION="1.5.1"
SHUI_DIR="${0:A:h}"

[[ -n "${_SHUI_LOADED:-}" ]] && return 0
typeset -g _SHUI_LOADED=1

# EPOCHSECONDS comes from zsh/datetime, which an interactive profile usually
# loads and a plain `zsh script.zsh` never does. Without it the parameter is
# empty, reads as 0 in arithmetic, and `shui loader --duration=N` spins forever
# on `(( EPOCHSECONDS < end ))` — a hung terminal in every non-interactive
# caller, while the same call works by hand.
zmodload zsh/datetime

source "${SHUI_DIR}/src/tokens/colors.zsh"
source "${SHUI_DIR}/src/tokens/contract.zsh"

_SHUI_ICONS="${SHUI_ICONS:-nerd}"

# Under a non-UTF-8 locale (LANG/LC_ALL unset is the common case on Linux) every
# $'\U…' escape in the icon files is a fatal "character not in range": the file
# aborts mid-way, the theme contract fails, and shui is never defined. Probe the
# escape itself rather than pattern-matching $LANG, which also catches a UTF-8
# name whose locale is not installed. One eval, no fork, no module.
if eval ": \$'\\U2713'" 2>/dev/null; then
  source "${SHUI_DIR}/src/icons/unicode.zsh"
elif [[ $_SHUI_ICONS != (none|ascii) ]]; then
  [[ -n ${SHUI_ICONS:-} ]] &&
    echo "shui: locale is not UTF-8, using ascii icons instead of '${SHUI_ICONS}'" >&2
  _SHUI_ICONS=ascii
fi

# unicode is the base layer, already sourced above (and only under UTF-8; the
# non-UTF-8 branch has rewritten it to ascii). Asking for it explicitly means
# "the base layer alone": nothing more to source, nothing to warn about.
if [[ $_SHUI_ICONS == unicode ]]; then
  :
elif [[ -f "${SHUI_DIR}/src/icons/${_SHUI_ICONS}.zsh" ]]; then
  source "${SHUI_DIR}/src/icons/${_SHUI_ICONS}.zsh"
else
  echo "shui: icon set '${_SHUI_ICONS}' not found, falling back to nerd" >&2
  source "${SHUI_DIR}/src/icons/nerd.zsh"
fi

_SHUI_THEME="${SHUI_THEME:-default}"

if [[ -f "${SHUI_DIR}/src/themes/${_SHUI_THEME}.zsh" ]]; then
  source "${SHUI_DIR}/src/themes/${_SHUI_THEME}.zsh"
else
  echo "shui: theme '${_SHUI_THEME}' not found, falling back to default" >&2
  source "${SHUI_DIR}/src/themes/default.zsh"
fi

_shui_validate_theme || return 1

for _shui_f in "${SHUI_DIR}"/src/components/*.zsh; do
  source "$_shui_f"
done
unset _shui_f

# Opportunistic completion registration. The canonical route is adding
# completions/ to $fpath before compinit; this branch covers sourcing shui.zsh
# after compinit has already run, so `shui <TAB>` works with no extra config.
# Gated on an interactive shell, so script/test sourcing is unaffected.
if [[ -o interactive ]] && (( $+functions[compdef] )); then
  fpath=("${SHUI_DIR}/completions" $fpath)
  autoload -Uz _shui && compdef _shui shui 2>/dev/null
fi

_shui_theme_cmd() {
  local subcmd="${1:-list}"; shift 2>/dev/null || true

  case "$subcmd" in
    list)
      for f in "${SHUI_DIR}"/src/themes/*.zsh; do
        basename "$f" .zsh
      done
      ;;
    create)
      local name="$1"
      [[ -z "$name" ]] && { echo "Usage: shui theme create <name>" >&2; return 1; }
      local dest="${SHUI_DIR}/src/themes/${name}.zsh"
      [[ -f "$dest" ]] && { echo "shui: theme '${name}' already exists" >&2; return 1; }
      cp "${SHUI_DIR}/src/themes/default.zsh" "$dest"
      sed -i '' "1s|.*|# ${name} theme — based on default|" "$dest"
      echo "shui: created ${dest}"
      echo "Load with: SHUI_THEME=${name} source shui.zsh"
      ;;
    validate)
      if _shui_validate_theme; then
        echo -e "${SHUI_COLOR_SUCCESS}${SHUI_ICON_SUCCESS}${SHUI_RESET} Theme '${_SHUI_THEME}' is valid"
      fi
      ;;
    *)
      echo "shui: unknown theme subcommand '${subcmd}'" >&2
      echo "Usage: shui theme list|create|validate" >&2
      return 1
      ;;
  esac
}

_shui_help() {
  echo
  echo -e "${SHUI_BOLD}${SHUI_COLOR_PRIMARY}shui · 水  —  Shell UI for Zsh${SHUI_RESET}"
  echo
  cat <<'HELP'
USAGE
  shui <command> [options] [args…]
  shui <command> --help          per-command help

TEXT
  shui bold <text>
  shui dim <text>
  shui italic <text>
  shui underline <text>
  shui text [<type>] <text>

MESSAGES
  shui success <message>
  shui error <message>
  shui warning <message>
  shui info <message>
  shui success-simple <message> [lines_before]
  shui error-simple <message>
  shui warning-simple <message>
  shui info-simple <message>
  shui muted <message>

LAYOUT
  shui section <title>
  shui subtitle <title>
  shui subsection <title>
  shui divider [--char=C] [--width=N] [--color=<type>]
  shui fence [label] [--char=C] [--color=<type>]
  shui hr
  shui center-text <text> [--width=N]
  shui spacer [n]
  shui screen <title> -- <command> [args…]

INLINE  (use inside $(...))
  shui badge <type> <text>
  shui pill <type> <text>

BLOCKS
  shui box [--title=<title>] <content>
  shui banner <type> <title> [content]
  shui table [--sep=<char>] <header> [<row>…]
  shui row [--tag-width=N] [--name-width=N] <variant> <tag> <name> [<detail>]

PROGRESS
  shui progress <current> <total> [--width=N] [--label=<text>] [--filled-char=X] [--empty-char=Y] [--inline] [--iterm=normal|success|error|warning|indeterminate|clear]
  shui spinner [--success=<msg>] [--fail=<msg>] <message> -- <command>
  shui spinner-tick <frame_idx> <msg>
  shui spinner-clear

TASK
  shui task-start <msg>
  shui task-done <msg>
  shui final-success <msg>
  shui final-fail <msg>

TITLE
  shui title <text>
  shui title-action <action> <target>
  shui title-install <target>
  shui title-update <target>

STEP
  shui set-total-steps <n>
  shui next-step <msg>

LOADER
  shui loader [--style=dots|pulse|spinner] [--duration=N] <msg>

ANIMATION
  shui typewriter [--delay=N] [--color=<type>] <text>
  shui fade-in [--steps=N] <text>

CURSOR
  shui hide-cursor
  shui show-cursor
  shui save-cursor
  shui restore-cursor
  shui move-cursor <row> <col>
  shui clear-line
  shui cleanup

LINK
  shui hyperlink <text> <url>
  shui print-link <text> <url>

UTIL
  shui terminal-size

DEBUG  (requires SHUI_DEBUG=true)
  shui debug <msg>
  shui debug-vars <var1> [var2…]
  shui debug-timing <start_epoch> <operation_name>
  shui debug-command <cmd…>

INTERACTIVE
  shui confirm [--default=y|n] <prompt>
  shui select <prompt> <opt1> [opt2…]
  shui radio <prompt> <opt1> [opt2…]
  shui multiselect <prompt> <opt1> [opt2…]
  shui tabs <prompt> <label[⇥desc]>…
  shui input [--default=<value>] [--validate=email|url|number|<regex>] <prompt>
  shui password [<prompt>]

THEME
  shui theme list
  shui theme create <name>
  shui theme validate

ICONS
  SHUI_ICONS=nerd|emoji|none

QUIET
  SHUI_QUIET=1               suppress all output

COLOUR
  NO_COLOR=1                 no escapes at all; also the default when stdout is not a terminal
  FORCE_COLOR=1              colour even when piped (outranks NO_COLOR)

TYPES
  success  error  warning  info  primary  muted  accent  secondary  group  danger

VERSION
  shui version
HELP
}

_shui_help_cmd() {
  local cmd="$1"
  case "$cmd" in
    bold|dim|italic|underline)
      echo "Usage: shui ${cmd} <text>"
      echo "Prints text with ${cmd} formatting." ;;
    text)
      echo "Usage: shui text [<type>] <text>"
      echo "Types: success error warning info primary muted accent"
      echo "Example: shui text success \"Done\"" ;;
    success|error|warning|info)
      echo "Usage: shui ${cmd} <message>"
      echo "Prints a ${cmd} message with icon and colour." ;;
    section|subtitle|subsection)
      echo "Usage: shui ${cmd} <title>"
      echo "Prints a ${cmd} heading." ;;
    screen)
      echo "Usage: shui screen <title> -- <command> [args…]"
      echo "Renders a section header, runs <command>, then shows elapsed time." ;;
    divider)
      echo "Usage: shui divider"
      echo "Prints a full-width horizontal rule." ;;
    fence)
      echo "Usage: shui fence [label] [--char=C] [--color=<type>]"
      echo "Prints a labelled rule: ── label ─────────────"
      echo "--color tints the label only; the rule stays muted."
      echo "Types: success error warning info primary muted accent" ;;
    spacer)
      echo "Usage: shui spacer [n]"
      echo "Prints n blank lines (default: 1)." ;;
    badge)
      echo "Usage: shui badge <type> <text>"
      echo "Inline solid-background label. Use inside \$(...)."
      echo "Types: success error warning info primary muted" ;;
    pill)
      echo "Usage: shui pill <type> <text>"
      echo "       shui pill <0-255> <text>"
      echo "Inline rounded-edge tag. Use inside \$(...)."
      echo "Types: success error warning info primary muted accent or 0–255 colour code" ;;
    box)
      echo "Usage: shui box [--title=<title>] <content>"
      echo "Bordered content block. Content may contain \\n for multiple lines." ;;
    table)
      echo "Usage: shui table [--sep=<char>] <header> [<row>…]"
      echo "Pipe-separated columns by default. Use --sep to change delimiter."
      echo "Example: shui table --sep=, \"Name,Age\" \"Alice,30\"" ;;
    row)
      echo "Usage: shui row [--tag-width=N] [--name-width=N] <variant> <tag> <name> [<detail>]"
      echo "A streaming status row: coloured tag, white name, muted detail."
      echo "Variants: success error warning info muted"
      echo "Unlike table, rows print as they happen — for reporting item by item."
      echo "Example: shui row success added GITHUB_TOKEN \"stored in the vault\"" ;;
    progress)
      echo "Usage: shui progress <current> <total> [--width=N] [--label=<text>] [--filled-char=X] [--empty-char=Y] [--inline] [--iterm=<state>]"
      echo "Adds a newline by default. Use --inline for loop-based updates."
      echo "iTerm states: normal success error warning indeterminate clear" ;;
    spinner)
      echo "Usage: shui spinner [--success=<msg>] [--fail=<msg>] <message> -- <command>"
      echo "Runs <command> with a spinner. Exits with the command's exit code." ;;
    confirm)
      echo "Usage: shui confirm [--default=y|n] <prompt>"
      echo "Exits 0 for yes, 1 for no, 2 when there is no terminal to ask. Default is n." ;;
    select)
      echo "Usage: shui select <prompt> <opt1> [opt2…]"
      echo "Prints the chosen option to stdout." ;;
    radio)
      echo "Usage: shui radio <prompt> <opt1> [opt2…]"
      echo "Arrow-key list: ↑↓/jk move · g/G first/last · PgUp/PgDn · enter select · q cancel."
      echo "Options may be label⇥hint. A list taller than the terminal scrolls. Prints the chosen label." ;;
    multiselect)
      echo "Usage: shui multiselect [--columns=<spec>] [--header=<row>] [--keys=<text>]"
      echo "                        [--details=<array>] [--footer=<function>] <prompt> <opt1> [opt2…]"
      echo "Checkboxes: ↑↓/jk move · space toggle · a all · enter confirm · q cancel."
      echo "Options may be label⇥hint. A list taller than the terminal scrolls. Prints the selected labels, one per line."
      echo ""
      echo "  --columns=<spec>     rows become id⇥cell⇥cell…; the id is printed, never drawn."
      echo "                       spec: align:width:drop per cell, comma-separated, e.g."
      echo "                       l:*:0,r:16:2,l:7:0 (l|r; a width or * for the one flexible"
      echo "                       column, which stops at its widest cell, *N for a minimum"
      echo "                       of N; columns with the highest"
      echo "                       drop number go first when the row does not fit, 0 never)"
      echo "  --header=<row>       cells drawn muted above the list (needs --columns)"
      echo "  --keys=<text>        replaces the key hint; the keys themselves do not change"
      echo "  --details=<array>    one element per row, lines joined by newlines, drawn under"
      echo "                       the list for the cursor row; the first line is the rule"
      echo "  --footer=<function>  called in a subshell with the ticked ids whenever they"
      echo "                       change; its first line of output is drawn last. Keep it"
      echo "                       fast: a hung footer cannot be interrupted"
      echo "Cells, the header, details and the footer take {success|warning|error|info|muted|bold:text}"
      echo "spans; escape foreign text with \${s//\\{/{{}. --details and --footer name things in"
      echo "the calling shell, so they work only with a sourced shui. A bad flag exits 1." ;;
    tabs)
      echo "Usage: shui tabs <prompt> <label[⇥desc]>…"
      echo "Live horizontal tab bar. Each arg is a tab label, optionally label⇥desc."
      echo "←/→ or h/l or Tab move · 1-9 jump · enter confirm · q cancel."
      echo "Prints the chosen tab's label to stdout." ;;
    input)
      echo "Usage: shui input [--default=<value>] [--validate=<rule>] <prompt>"
      echo "Prints the entered value to stdout."
      echo "--validate rules: email, url, number, or any regex. Re-prompts until valid." ;;
    password)
      echo "Usage: shui password [<prompt>]"
      echo "Masked text entry — echoes '*' per keystroke. Prints the raw value to stdout." ;;
    theme)
      echo "Usage: shui theme list|create|validate"
      echo "  list      — list available themes"
      echo "  create    — scaffold a new theme"
      echo "  validate  — check all required tokens are defined" ;;
    *)
      echo "shui: no help available for '${cmd}'" >&2
      return 1 ;;
  esac
}

shui() {
  [[ $# -eq 0 ]] && { _shui_help; return 0; }
  [[ -n "${SHUI_QUIET:-}" ]] && return 0

  local _shui_cmd="$1"; shift

  # Per-command --help
  if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
    _shui_help_cmd "$_shui_cmd"
    return 0
  fi

  case "$_shui_cmd" in
    bold|dim|italic|underline|text)                            _shui_text    "$_shui_cmd" "$@" ;;
    success|error|warning|info)                                _shui_message "$_shui_cmd" "$@" ;;
    message)                                                   _shui_message_dispatch "$@" ;;
    success-simple|error-simple|warning-simple|info-simple)
      echo -e "\e[33m⚠ shui: '${_shui_cmd}' is deprecated — use 'shui message ${_shui_cmd%-simple}' instead\e[0m" >&2
      _shui_message_simple "${_shui_cmd%-simple}" "$@" ;;
    muted)                                                     _shui_message_simple "muted" "$@" ;;
    section|subtitle|subsection|divider|hr|spacer|center-text|fence) _shui_layout  "$_shui_cmd" "$@" ;;
    screen)       _shui_screen      "$@" ;;
    timer-start)  _shui_timer_start      ;;
    timer-end)    _shui_timer_end   "$@" ;;
    badge)        _shui_badge       "$@" ;;
    pill)         _shui_pill        "$@" ;;
    box)          _shui_box         "$@" ;;
    banner)       _shui_banner      "$@" ;;
    table)        _shui_table       "$@" ;;
    row)          _shui_row         "$@" ;;
    progress)     _shui_progress    "$@" ;;
    spinner)      _shui_spinner     "$@" ;;
    spinner-tick) _shui_spinner_tick "$@" ;;
    spinner-clear) _shui_spinner_clear ;;
    task-start|task-done|final-success|final-fail) _shui_task "$_shui_cmd" "$@" ;;
    title|title-action|title-install|title-update) _shui_title "$_shui_cmd" "$@" ;;
    set-total-steps|next-step)                     _shui_step  "$_shui_cmd" "$@" ;;
    loader)                                          _shui_loader    "$@" ;;
    typewriter|fade-in)                              _shui_animation "$_shui_cmd" "$@" ;;
    hide-cursor|show-cursor|save-cursor|restore-cursor|move-cursor|clear-line|cleanup) _shui_cursor "$_shui_cmd" "$@" ;;
    hyperlink)   _shui_hyperlink  "$@" ;;
    print-link)  _shui_print_link "$@" ;;
    terminal-size) _shui_util "terminal-size" ;;
    debug)         _shui_debug         "$@" ;;
    debug-vars)    _shui_debug_vars    "$@" ;;
    debug-timing)  _shui_debug_timing  "$@" ;;
    debug-command) _shui_debug_command "$@" ;;
    confirm)     _shui_confirm     "$@" ;;
    select)      _shui_select      "$@" ;;
    radio)       _shui_radio       "$@" ;;
    multiselect) _shui_multiselect "$@" ;;
    tabs)        _shui_tabs        "$@" ;;
    input)       _shui_input       "$@" ;;
    password)    _shui_password    "$@" ;;
    theme)    _shui_theme_cmd "$@" ;;
    version|--version|-v) echo "shui $SHUI_VERSION" ;;
    help|--help|-h) _shui_help ;;
    *)
      echo "shui: unknown command '${_shui_cmd}'" >&2
      echo "Run 'shui help' for usage." >&2
      return 1
      ;;
  esac
}
