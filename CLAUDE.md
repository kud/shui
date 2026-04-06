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
    spinner.zsh           # command spinner
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

Screenshots in `assets/` are SVG files generated from asciinema recordings. Use **emoji icon set** (`SHUI_ICONS=emoji`) so glyphs render universally without Nerd Font.

```zsh
# Record a cast (must use -f asciicast-v2 — svg-term does not support v3)
asciinema rec /tmp/shui-<name>.cast --cols <W> --rows <H> --overwrite -f asciicast-v2 \
  -c "SHUI_ICONS=emoji zsh -c 'source shui.zsh && <commands>'"

# Convert to SVG — --at 99999 freezes on the final frame (omitting it produces a blinking animation)
svg-term --in /tmp/shui-<name>.cast --out assets/<name>.svg --width <W> --height <H> --no-cursor --at 99999
```

Requirements: `asciinema` (brew), `svg-term-cli` (npm install -g svg-term-cli).

After regenerating SVGs, commit `assets/` alongside any code changes.

---

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
