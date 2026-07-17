#!/usr/bin/env zsh

################################################################################
#                                                                              #
#   🚢 RELEASE                                                                  #
#   ---------                                                                  #
#   Cuts a release: syncs the version strings, then hands off to `git lzv`.    #
#                                                                              #
#   Why this exists. `git lzv` syncs a version into package.json and nothing   #
#   else. shui has no package.json, so it tags and stops — leaving the two     #
#   places the version is actually written untouched:                          #
#                                                                              #
#     shui.zsh  SHUI_VERSION=…   ← what `shui version` tells a user            #
#     VERSION                    ← read by tests and tooling                   #
#                                                                              #
#   Nothing in the generic flow ever writes those, so each release widened the #
#   gap silently. By v1.1.0 the tag said 1.1.0, VERSION said 0.4.4, and users  #
#   were told 0.1.0. A version that lies is worse than no version.             #
#                                                                              #
#   Usage:  bin/release.sh <major|minor|patch> [--dry-run]                     #
#           bin/release.sh --sync [--dry-run]                                  #
#                                                                              #
#   `--sync` writes the *current* tag into both strings and stops: no bump, no #
#   tag, no push. It repairs drift that already exists, without inventing a    #
#   release to carry the repair — and means nobody has to hand-edit a version  #
#   field to fix one.                                                          #
#                                                                              #
#   `k-release` runs this automatically when it is executable (its Step 0.5),  #
#   after the changelog is written — this commits it along with everything     #
#   else pending.                                                              #
#                                                                              #
################################################################################

emulate -L zsh
setopt err_exit no_unset pipe_fail

bump=""
dry_run=false
sync_only=false
for arg in "$@"; do
  case "$arg" in
    major|minor|patch) bump="$arg" ;;
    --sync)            sync_only=true ;;
    --dry-run)         dry_run=true ;;
    *) print -u2 "release: unknown argument '$arg'"; exit 1 ;;
  esac
done

if [[ -z "$bump" ]] && ! $sync_only; then
  print -u2 "usage: bin/release.sh <major|minor|patch> [--dry-run]"
  print -u2 "       bin/release.sh --sync [--dry-run]"
  exit 1
fi
if [[ -n "$bump" ]] && $sync_only; then
  print -u2 "release: --sync repairs the current version; it cannot also bump"
  exit 1
fi

root="${0:A:h:h}"
cd "$root"

if ! command -v svu >/dev/null 2>&1; then
  print -u2 "release: svu not found — brew install caarlos0/tap/svu"
  exit 1
fi

current="$(git describe --tags --abbrev=0 2>/dev/null || print -r -- 'none')"

if $sync_only; then
  # Repairing, not releasing: the target is the tag that already exists.
  next="${current#v}"
  if [[ "$current" == "none" ]]; then
    print -u2 "release: no tag to sync to — cut a release first"
    exit 1
  fi
  print -r -- "  syncing version strings to the current tag ${current}"
else
  # Ask svu, because `git tag-version` asks svu. Computing the next version any
  # other way here would be a second opinion, and the two would eventually differ.
  next_tag="$(svu "$bump")"
  next="${next_tag#v}"
  print -r -- "  ${current} → ${next_tag}  [${bump}]"
fi

if $dry_run; then
  print -r -- "  would set SHUI_VERSION and VERSION to ${next}"
  $sync_only || print -r -- "  then: git lzv ${bump}"
  print -r -- "  nothing written."
  exit 0
fi

perl -i -pe "s/^SHUI_VERSION=\".*\"\$/SHUI_VERSION=\"${next}\"/" shui.zsh
print -r -- "$next" >| VERSION

# Verify rather than trust the exit code: a regex that silently matches nothing
# would ship a release still announcing the old version, which is the exact
# failure this script exists to prevent.
written_code="$(grep -m1 '^SHUI_VERSION=' shui.zsh | cut -d'"' -f2)"
written_file="$(<VERSION)"
if [[ "$written_code" != "$next" ]]; then
  print -u2 "release: failed to set SHUI_VERSION in shui.zsh (found '${written_code}')"
  exit 1
fi
if [[ "$written_file" != "$next" ]]; then
  print -u2 "release: failed to write VERSION (found '${written_file}')"
  exit 1
fi

print -r -- "  synced SHUI_VERSION and VERSION → ${next}"

if $sync_only; then
  print -r -- "  commit them when ready — no tag, no push."
  exit 0
fi

# git lzv commits everything pending — the CHANGELOG entry and the two strings
# above — then tags and pushes. It asks svu for the same number we just wrote.
exec git lzv "$bump"
