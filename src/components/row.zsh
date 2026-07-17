#!/usr/bin/env zsh

# A streaming status row: tag · name · detail.
#
#   shui row success added   MCP_GITHUB_TOKEN "stored in the vault"
#   shui row muted   same    MCP_JENKINS_URL  "vault already matches"
#   shui row warning differs NEO4J_QA_URI     "vault has a different value"
#
# Why not `shui table`: a table measures every column before drawing, so it must
# hold all the rows first. This is for a command that decides one item at a time
# and should say so as it goes — the widths are therefore fixed, not computed.
#
# The name is the column you scan down, so it is the only part left bright: tag
# coloured, name white, detail muted. Dimming the name (as a key/value pair would)
# hides the one thing you are looking for.
#
# Each variant's *word* carries the meaning — "added" vs "differs" — so a row
# still reads with colour stripped, piped, or unseen. Colour only reinforces.

_shui_row() {
  local tag_width=8 name_width=28
  local -a args=()

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --tag-width=*)  tag_width="${1#--tag-width=}";  shift ;;
      --name-width=*) name_width="${1#--name-width=}"; shift ;;
      *) args+=("$1"); shift ;;
    esac
  done

  local variant="${args[1]:-muted}" tag="${args[2]:-}" name="${args[3]:-}" detail="${args[4]:-}"
  local color

  case "$variant" in
    success) color="$SHUI_COLOR_SUCCESS" ;;
    error)   color="$SHUI_COLOR_ERROR"   ;;
    warning) color="$SHUI_COLOR_WARNING" ;;
    info)    color="$SHUI_COLOR_INFO"    ;;
    muted)   color="$SHUI_COLOR_MUTED"   ;;
    *) echo "shui: unknown row variant '${variant}'" >&2; return 1 ;;
  esac

  # Every column ends with a literal space, not merely padding. Padding alone
  # collapses to nothing the moment a value exactly fills its width — an 8-char
  # tag in an 8-wide column renders "attachedid_ed25519" — and a value that
  # overflows the width would run on regardless of how wide it is set. Widths
  # align the common case; the space is what guarantees the columns stay columns.
  printf '  %s%-*s%s %s%-*s%s %s%s%s\n' \
    "$color" "$tag_width" "$tag" "$SHUI_RESET" \
    "$SHUI_COLOR_BOLD_WHITE" "$name_width" "$name" "$SHUI_RESET" \
    "$SHUI_COLOR_MUTED" "$detail" "$SHUI_RESET"
}
