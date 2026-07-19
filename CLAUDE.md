# shui — Project Instructions

## Overview

shui is a Zsh design system. Primary language: **Zsh**. No external runtime dependencies.

---

## Project structure

```
shui.zsh                  # main entrypoint — loads tokens, icons, theme, components
src/
  tokens/
    colors.zsh            # _shui_color(), _shui_bg_color(), _shui_repeat(), _shui_visible_len()
    contract.zsh          # _SHUI_REQUIRED_TOKENS list + _shui_validate_theme()
  icons/
    unicode.zsh           # base layer — standard Unicode symbols, always sourced first
    nerd.zsh              # Nerd Font PUA glyphs (default, SHUI_ICONS=nerd)
    emoji.zsh             # Unicode emoji  (SHUI_ICONS=emoji)
    none.zsh              # no icons       (SHUI_ICONS=none)
  themes/
    default.zsh           # 256-colour with 16-colour fallback (colours only, no icons)
    minimal.zsh           # 16-colour ANSI (inherits default, overrides colours)
    plain.zsh             # no colour (inherits default, overrides colours + icons with ASCII)
  components/
    text.zsh              # bold, dim, italic, underline, text --color=
    message.zsh           # success, error, warning, info
    layout.zsh            # section, subtitle, subsection, divider, spacer
    badge.zsh             # inline solid-background label
    pill.zsh              # inline rounded-edge tag
    box.zsh               # bordered content block
    table.zsh             # pipe-separated column table
    progress.zsh          # inline progress bar
    spinner.zsh           # command spinner — wraps a command, exits with its exit code
    loader.zsh            # indeterminate loader — looping indicator (--style=dots|pulse|spinner)
    animation.zsh         # one-shot text effects — typewriter, fade-in
    screen.zsh            # section header + command runner with elapsed time; also timer-start/timer-end for per-step timing
    tabs.zsh              # interactive tabbed selector — items grouped into ←/→ tabs
    interactive.zsh       # confirm, select, radio, multiselect, input (--validate=email|url|number|<regex>), password (masked)
assets/                   # SVG screenshots embedded in README
completions/
  _shui                   # zsh completion — kept in parity with the dispatcher by tests/test-completion.zsh
scripts/
  demo.zsh                # visual showcase of all components (--interactive for form fields)
  sync-icons.zsh          # regenerate src/icons/*.zsh from @kud/glyphs
```

---

## Loading order (shui.zsh)

1. `src/tokens/colors.zsh` — utilities available to themes
2. `src/tokens/contract.zsh` — token list + validation function
3. `src/icons/unicode.zsh` — base Unicode symbols, always loaded regardless of icon set
4. `src/icons/<SHUI_ICONS>.zsh` — overrides `SHUI_ICON_*` tokens for the selected set
5. `src/themes/<SHUI_THEME>.zsh` — sets colour/style tokens (may override icon tokens)
6. `_shui_validate_theme` — aborts if any required token is missing
7. All `src/components/*.zsh`

Themes only define **colours**. Icons are owned by icon sets. The `plain` theme is an exception — it overrides icon tokens with ASCII fallbacks intentionally.

`unicode.zsh` defines geometric symbols (`SHUI_ICON_BULLET`, `SHUI_ICON_CIRCLE`, etc.) that work in any terminal. Icon sets can override these — `none.zsh` blanks them; `emoji.zsh` inherits them unchanged. Nerd Font-only tokens (`SHUI_ICON_PL_*`) are defined only in `nerd.zsh` and have no equivalent in other sets.

---

## Generating README screenshots

Screenshots in `assets/` are **PNG files** (SVGs caused flickering on GitHub due to `xlink:href` CSP stripping).

Pipeline: asciinema → svg-term (static frame) → rsvg-convert (SVG → PNG).

```zsh
# 1. Record a cast (must use -f asciicast-v2 — svg-term does not support v3)
asciinema rec /tmp/shui-<name>.cast --cols <W> --rows <H> --overwrite -f asciicast-v2 \
  -c "SHUI_ICONS=emoji zsh -c 'source shui.zsh && <commands>'"

# 2. Convert to SVG — --at 99999 freezes on the final frame (omitting it produces animation)
svg-term --in /tmp/shui-<name>.cast --out /tmp/shui-<name>.svg --width <W> --height <H> --no-cursor --at 99999

# 3. Convert SVG to PNG at 2x for retina clarity
rsvg-convert -z 2 /tmp/shui-<name>.svg -o assets/<name>.png
```

Requirements: `asciinema` (brew), `svg-term-cli` (npm install -g svg-term-cli), `librsvg` (brew install librsvg).

After regenerating SVGs, commit `assets/` alongside any code changes.

---

## Icon files (`src/icons/`)

**The four `src/icons/*.zsh` files are GENERATED from [@kud/glyphs](https://github.com/kud/glyphs)** — the shared source of truth for terminal glyphs. Do not hand-edit them. To change or add an icon:

1. Edit `glyphs.json` in @kud/glyphs and release a new version.
2. Bump `GLYPHS_VERSION` in `scripts/sync-icons.zsh`.
3. Run `zsh scripts/sync-icons.zsh` and commit the regenerated files.

The sync fetches @kud/glyphs' escape-safe `ICON_*` zsh files and text-substitutes the prefix into shui's namespace (`sed 's/^ICON_/SHUI_ICON_/'`). **No node, no runtime dependency** — the generated files are plain literal assignments shui sources directly at load time.

Invariants (produced upstream by @kud/glyphs, still enforced by `tests/test-icons.zsh`):

- **Parity** — `nerd.zsh`, `emoji.zsh`, `none.zsh` declare the identical `SHUI_ICON_*` token set (geometrics and the `SHUI_ICON_PL_*` powerline caps included). A set with no glyph for a token still declares it empty. `unicode.zsh` is the thin base layer (geometric shapes only), sourced first.
- **Escape-safe** — `nerd.zsh` uses `$'\UXXXX'` escapes, never raw PUA bytes. Guaranteed by construction upstream, not by hand.
- Never write a literal `SHUI_ICON_<UPPERCASE>` token in a comment inside an icon file — the grep-based parity check counts it as a phantom definition.

Run `mise test` to verify (`tests/test-icons.zsh` checks non-empty values, escape syntax, and parity). To inspect codepoints, see @kud/glyphs' `glyphs.json` — the authoritative `name → { nerd, unicode?, emoji? }` map.

## Versioning

Release through `bin/release.sh` — **not** `git lzv` directly.

```zsh
bin/release.sh patch   # bug fixes
bin/release.sh minor   # new features
bin/release.sh major   # breaking changes
bin/release.sh --sync  # repair drift: write the current tag into both strings
```

Each of the first three syncs the version strings, then hands off to `git lzv`
(commit + tag + push). Add `--dry-run` to any of them to see the target first.

**Why not `git lzv` directly.** It syncs a version into `package.json` and
nothing else. shui has none, so it tags and stops — leaving the two places the
version is actually written untouched:

- `shui.zsh` → `SHUI_VERSION` — what `shui version` tells a user
- `VERSION` — read by the test suite

Nothing in the generic flow writes those, so every direct `git lzv` widened the
gap silently. By v1.1.0 the tag said `1.1.0`, `VERSION` said `0.4.4`, and users
were told `0.1.0`. A version that lies is worse than no version at all.

`k-release` picks `bin/release.sh` up automatically while it stays executable
(its Step 0.5) — so the drift cannot return by someone forgetting.

## Syntax checking

```zsh
zsh -n shui.zsh
zsh -n src/**/*.zsh
```
