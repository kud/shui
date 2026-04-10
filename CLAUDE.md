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
    nerd.zsh              # Nerd Font glyphs (default, SHUI_ICONS=nerd)
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
    screen.zsh            # section header + command runner with elapsed time
    interactive.zsh       # confirm, select, input
assets/                   # SVG screenshots embedded in README
demo.zsh                  # visual showcase of all components
```

---

## Loading order (shui.zsh)

1. `src/tokens/colors.zsh` — utilities available to themes
2. `src/tokens/contract.zsh` — token list + validation function
3. `src/icons/<SHUI_ICONS>.zsh` — sets `SHUI_ICON_*` tokens
4. `src/themes/<SHUI_THEME>.zsh` — sets colour/style tokens (may override icon tokens)
5. `_shui_validate_theme` — aborts if any required token is missing
6. All `src/components/*.zsh`

Themes only define **colours**. Icons are owned by icon sets. The `plain` theme is an exception — it overrides icon tokens with ASCII fallbacks intentionally.

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

## Nerd Font icons (`src/icons/nerd.zsh`)

Nerd Font glyphs are invisible in Claude's environment (PUA codepoints render as empty). See the global `CLAUDE.md` for the general inspection pattern.

Rules specific to this project:

- All `SHUI_ICON_*` assignments in `nerd.zsh` **must** use `$'\UXXXX'` escape sequences — never raw bytes.
- `emoji.zsh` and `none.zsh` must define the exact same set of variables as `nerd.zsh` (parity).
- Run `mise test` to verify — `tests/test-icons.zsh` checks non-empty values, escape syntax, and cross-set parity.

To inspect current codepoints:

```js
node -e "
import { readFileSync } from 'fs';
for (const line of readFileSync('src/icons/nerd.zsh', 'utf8').split('\n')) {
  const m = line.match(/^(SHUI_ICON_\w+)=\\\$'(.*?)'/);
  if (m) console.log(m[1] + ': U+' + parseInt(m[2].replace(/\\\\U/, ''), 16).toString(16).toUpperCase().padStart(4, '0'));
}
"
```

## Versioning

```zsh
git lzv patch   # bug fixes
git lzv minor   # new features
git lzv major   # breaking changes
```

## Syntax checking

```zsh
zsh -n shui.zsh
zsh -n src/**/*.zsh
```
