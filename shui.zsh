#!/usr/bin/env zsh
#
# shui · 水  —  fluid terminal UI for Zsh
# https://github.com/kud/shui
#

SHUI_VERSION="0.1.0"
SHUI_DIR="${0:A:h}"

[[ -n "${_SHUI_LOADED:-}" ]] && return 0
typeset -g _SHUI_LOADED=1

source "${SHUI_DIR}/src/tokens/colors.zsh"
source "${SHUI_DIR}/src/tokens/contract.zsh"

_SHUI_ICONS="${SHUI_ICONS:-nerd}"

if [[ -f "${SHUI_DIR}/src/icons/${_SHUI_ICONS}.zsh" ]]; then
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
  shui pulse [--count=N] <text>
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
  shui input [--default=<value>] <prompt>

THEME
  shui theme list
  shui theme create <name>
  shui theme validate

ICONS
  SHUI_ICONS=nerd|emoji|none

QUIET
  SHUI_QUIET=1               suppress all output

TYPES
  success  error  warning  info  primary  muted  accent  secondary  danger

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
    progress)
      echo "Usage: shui progress <current> <total> [--width=N] [--label=<text>] [--filled-char=X] [--empty-char=Y] [--inline] [--iterm=<state>]"
      echo "Adds a newline by default. Use --inline for loop-based updates."
      echo "iTerm states: normal success error warning indeterminate clear" ;;
    spinner)
      echo "Usage: shui spinner [--success=<msg>] [--fail=<msg>] <message> -- <command>"
      echo "Runs <command> with a spinner. Exits with the command's exit code." ;;
    confirm)
      echo "Usage: shui confirm [--default=y|n] <prompt>"
      echo "Exits 0 for yes, 1 for no. Default is n." ;;
    select)
      echo "Usage: shui select <prompt> <opt1> [opt2…]"
      echo "Prints the chosen option to stdout." ;;
    input)
      echo "Usage: shui input [--default=<value>] <prompt>"
      echo "Prints the entered value to stdout." ;;
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

  local cmd="$1"; shift

  # Per-command --help
  if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
    _shui_help_cmd "$cmd"
    return 0
  fi

  case "$cmd" in
    bold|dim|italic|underline|text)                            _shui_text    "$cmd" "$@" ;;
    success|error|warning|info)                                _shui_message "$cmd" "$@" ;;
    success-simple|error-simple|warning-simple|info-simple)    _shui_message_simple "${cmd%-simple}" "$@" ;;
    muted)                                                     _shui_message_simple "muted" "$@" ;;
    section|subtitle|subsection|divider|hr|spacer|center-text) _shui_layout  "$cmd" "$@" ;;
    screen)       _shui_screen      "$@" ;;
    badge)        _shui_badge       "$@" ;;
    pill)         _shui_pill        "$@" ;;
    box)          _shui_box         "$@" ;;
    banner)       _shui_banner      "$@" ;;
    table)        _shui_table       "$@" ;;
    progress)     _shui_progress    "$@" ;;
    spinner)      _shui_spinner     "$@" ;;
    spinner-tick) _shui_spinner_tick "$@" ;;
    spinner-clear) _shui_spinner_clear ;;
    task-start|task-done|final-success|final-fail) _shui_task "$cmd" "$@" ;;
    title|title-action|title-install|title-update) _shui_title "$cmd" "$@" ;;
    set-total-steps|next-step)                     _shui_step  "$cmd" "$@" ;;
    loader)                                          _shui_loader    "$@" ;;
    typewriter|pulse|fade-in)                        _shui_animation "$cmd" "$@" ;;
    hide-cursor|show-cursor|save-cursor|restore-cursor|move-cursor|clear-line|cleanup) _shui_cursor "$cmd" "$@" ;;
    hyperlink)   _shui_hyperlink  "$@" ;;
    print-link)  _shui_print_link "$@" ;;
    terminal-size) _shui_util "terminal-size" ;;
    debug)         _shui_debug         "$@" ;;
    debug-vars)    _shui_debug_vars    "$@" ;;
    debug-timing)  _shui_debug_timing  "$@" ;;
    debug-command) _shui_debug_command "$@" ;;
    confirm)  _shui_confirm  "$@" ;;
    select)   _shui_select   "$@" ;;
    input)    _shui_input    "$@" ;;
    theme)    _shui_theme_cmd "$@" ;;
    version|--version|-v) echo "shui $SHUI_VERSION" ;;
    help|--help|-h) _shui_help ;;
    *)
      echo "shui: unknown command '${cmd}'" >&2
      echo "Run 'shui help' for usage." >&2
      return 1
      ;;
  esac
}
