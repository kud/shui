#!/usr/bin/env zsh
#
# shui · 水  —  fluid terminal UI for Zsh
# https://github.com/kud/shui
#

SHUI_VERSION="1.6.0"
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

# shui's own help, drawn by the help component it ships (src/components/help.zsh)
# so the listing follows the same layout every tool built on shui gets. Full
# signatures live in `shui <command> --help`.
_shui_help() {
  _shui_help_render \
    --name=shui --version="$SHUI_VERSION" \
    --desc='Fluid terminal UI for Zsh: a design system for the shell' \
    --usage='shui <command> [options] [args…]' \
    --usage='shui <command> --help' \
    --usage='shui help <command>' \
    --about='Colour types, wherever a command takes one: success error warning info primary muted accent secondary group danger' \
    --command='bold <text>|Bold text' \
    --command='dim <text>|Dimmed text' \
    --command='italic <text>|Italic text' \
    --command='underline <text>|Underlined text' \
    --command='text [<type>] <text>|Text in a colour type' \
    --command='success <message>|Success message with its icon' \
    --command='error <message>|Error message with its icon, on stderr' \
    --command='warning <message>|Warning message with its icon, on stderr' \
    --command='info <message>|Information message with its icon' \
    --command='message <type> <text>|Any message type in one call, muted included' \
    --command='muted <message>|Muted line' \
    --command='section <title>|Section heading' \
    --command='subtitle <title>|Subtitle heading' \
    --command='subsection <title>|Subsection heading' \
    --command='divider|Full-width rule' \
    --command='fence [label]|Rule with a label' \
    --command='hr|Horizontal rule' \
    --command='center-text <text>|Centred text' \
    --command='spacer [n]|Blank lines' \
    --command='screen <title> -- <command>|Heading, then a command and its elapsed time' \
    --command='timer-start|Start a step timer' \
    --command='timer-end [label]|Print the time since timer-start' \
    --command='badge <type> <text>|Inline solid label, for use inside $(…)' \
    --command='pill <type> <text>|Inline rounded tag, for use inside $(…)' \
    --command='box <text>|Bordered block (--title)' \
    --command='banner <type> <title>|Coloured banner block, with optional content' \
    --command='table <header> <row…>|Pipe-separated table (--sep)' \
    --command='row <variant> <tag> <name>|Streaming status row' \
    --command='progress <cur> <total>|Progress bar' \
    --command='spinner <message> -- <command>|Run a command behind a spinner; exits with its code' \
    --command='spinner-tick <frame> <msg>|Draw one spinner frame' \
    --command='spinner-clear|Clear the spinner line' \
    --command='task-start <msg>|Task line, in progress' \
    --command='task-done <msg>|Task line, done' \
    --command='final-success <msg>|Closing success line' \
    --command='final-fail <msg>|Closing failure line' \
    --command='title <text>|Title line' \
    --command='title-action <action> <target>|Title naming an action and its target' \
    --command='title-install <target>|Install title' \
    --command='title-update <target>|Update title' \
    --command='set-total-steps <n>|Set the step count' \
    --command='next-step <msg>|Next numbered step' \
    --command='loader <msg>|Looping indicator (--style, --duration)' \
    --command='typewriter <text>|Text typed out' \
    --command='fade-in <text>|Text faded in' \
    --command='hide-cursor|Hide the cursor' \
    --command='show-cursor|Show the cursor' \
    --command='save-cursor|Save the cursor position' \
    --command='restore-cursor|Restore the cursor position' \
    --command='move-cursor <row> <col>|Move the cursor' \
    --command='clear-line|Clear the current line' \
    --command='cleanup|Restore the cursor and the line' \
    --command='hyperlink <text> <url>|Inline terminal hyperlink' \
    --command='print-link <text> <url>|Hyperlink on its own line' \
    --command='terminal-size|Print the terminal size as WxH' \
    --command='debug <msg>|Debug line, when SHUI_DEBUG is true' \
    --command='debug-vars <var…>|Print variables, when SHUI_DEBUG is true' \
    --command='debug-timing <start> <name>|Print elapsed time, when SHUI_DEBUG is true' \
    --command='debug-command <cmd…>|Run and trace a command, when SHUI_DEBUG is true' \
    --command='confirm <prompt>|Yes or no; exit 0, 1, or 2 without a terminal' \
    --command='select <prompt> <opt…>|Numbered menu' \
    --command='radio <prompt> <opt…>|Arrow-key single choice' \
    --command='multiselect <prompt> <opt…>|Checkbox list, with optional columns' \
    --command='tabs <prompt> <label…>|Horizontal tab bar' \
    --command='input <prompt>|Text entry (--default, --validate)' \
    --command='password [<prompt>]|Masked text entry' \
    --command='help [<command>]|This help, a command'"'"'s help, or a help page for your own tool' \
    --command='theme <subcommand>|List, create or validate themes' \
    --command='version|Print the shui version' \
    --example='A success message|shui success "Deployed"' \
    --example='A help page for your own tool|shui help --name=acme --desc="Ship folders" --command="deploy <dir>|Upload a folder"' \
    --env='SHUI_ICONS|Icon set: nerd, emoji, unicode, ascii or none|nerd' \
    --env='SHUI_THEME|Theme: default, minimal or plain|default' \
    --env='SHUI_QUIET|Set to 1 to silence every command' \
    --env='SHUI_DEBUG|Set to true to enable the debug commands' \
    --env='NO_COLOR|No colour; also the default when stdout is not a terminal' \
    --env='FORCE_COLOR|Colour even when piped; outranks NO_COLOR' \
    --env='SHUI_FORCE_TTY|Treat stdout as a terminal, for tests' \
    --see='https://kud.io/projects/shui/docs'
}

# `shui help`: shui's own help; `shui help <command>`: that command's help;
# `shui help --name=…`: a help page for the caller's own tool.
_shui_help_dispatch() {
  if (( $# == 0 )); then
    _shui_help
  elif [[ $1 == --* ]]; then
    _shui_help_render "$@"
  else
    _shui_help_cmd "$1"
  fi
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
    help)
      echo "Usage: shui help [<command>]"
      echo "       shui help --name=<tool> [--version=<v>] [--desc=<text>] [--usage=<line>]…"
      echo "                 [--about=<text>] [--command=<name|desc>]… [--argument=<name|desc>]…"
      echo "                 [--option=<name|desc[|default]>]… [--example=<comment|command>]…"
      echo "                 [--env=<name|desc[|default]>]… [--see=<url>]…"
      echo "With no argument, shui's own help; with a command, that command's help."
      echo "With flags, a help page for your own tool in the shared layout: USAGE, COMMANDS,"
      echo "ARGUMENTS, OPTIONS, EXAMPLES, ENVIRONMENT, SEE ALSO, each left out when empty."
      echo "Colour on a terminal (truecolor, 256 or 16 from COLORTERM and TERM), bold and"
      echo "underline only under NO_COLOR, no escapes at all when piped." ;;
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
    help|--help|-h) _shui_help_dispatch "$@" ;;
    *)
      echo "shui: unknown command '${_shui_cmd}'" >&2
      echo "Run 'shui help' for usage." >&2
      return 1
      ;;
  esac
}
