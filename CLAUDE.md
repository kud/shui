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
    glyphs-colors.zsh     # GENERATED semantic colour tokens (SHUI_COLOR_*_ANSI16/ANSI256/HEX, SHUI_STATE_*)
    contract.zsh          # _SHUI_REQUIRED_TOKENS + _shui_resolve_tokens() + _shui_validate_theme()
  icons/
    unicode.zsh           # base layer — standard Unicode symbols, always sourced first
    nerd.zsh              # Nerd Font PUA glyphs (default, SHUI_ICONS=nerd)
    emoji.zsh             # Unicode emoji  (SHUI_ICONS=emoji)
    none.zsh              # no icons       (SHUI_ICONS=none)
    ascii.zsh             # 7-bit ASCII    (SHUI_ICONS=ascii) — hand-written, layered on none.zsh; the non-UTF-8 fallback
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
    tabs.zsh              # live horizontal tab bar — ←/→/1-9 move, enter confirms
    interactive.zsh       # confirm, select, radio, multiselect, input (--validate=email|url|number|<regex>), password (masked)
assets/                   # SVG screenshots embedded in README
completions/
  _shui                   # zsh completion — kept in parity with the dispatcher by tests/test-completion.zsh
scripts/
  demo.zsh                # visual showcase of all components (--interactive for form fields)
  sync-icons.zsh          # regenerate src/icons/*.zsh from @kud/glyphs
  sync-colors.zsh         # regenerate src/tokens/glyphs-colors.zsh from @kud/glyphs (CI checks drift)
```

---

## Loading order (shui.zsh)

1. `src/tokens/colors.zsh` — utilities available to themes
2. `src/tokens/glyphs-colors.zsh` — generated colour tokens the themes derive from
3. `src/tokens/contract.zsh` — token list + validation function
4. `src/icons/unicode.zsh` — base Unicode symbols, loaded regardless of icon set **when the locale is UTF-8**.
   Otherwise every `$'\U…'` escape is a fatal "character not in range", so shui skips it and switches any
   set but `none` to `ascii` (escape-free). The check probes the escape itself (one `eval`, no fork).
5. `src/icons/<SHUI_ICONS>.zsh` — overrides `SHUI_ICON_*` tokens for the selected set
6. `src/themes/<SHUI_THEME>.zsh` — sets colour/style tokens (may override icon tokens)
7. `_shui_resolve_tokens` — PRIMARY → ACCENT alias, legacy-theme fallbacks
8. `_shui_validate_theme` — aborts if any required token is missing
9. All `src/components/*.zsh`

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

**The four `src/icons/{unicode,nerd,emoji,none}.zsh` files are GENERATED from [@kud/glyphs](https://github.com/kud/glyphs)** — the shared source of truth for terminal glyphs. Do not hand-edit them. To change or add an icon:

1. Edit `glyphs.json` in @kud/glyphs and release a new version.
2. Bump `GLYPHS_VERSION` in `scripts/sync-icons.zsh`.
3. Run `zsh scripts/sync-icons.zsh` and commit the regenerated files.

The sync fetches @kud/glyphs' escape-safe `ICON_*` zsh files and text-substitutes the prefix into shui's namespace (`sed 's/^ICON_/SHUI_ICON_/'`). **No node, no runtime dependency** — the generated files are plain literal assignments shui sources directly at load time.

`unicode.zsh` gets the state glyphs (success, error, warning, info, arrow, check, cross) from
`UNICODE_STATES` in `scripts/sync-icons.zsh`, because @kud/glyphs has no `unicode` value for them yet;
each is emitted only when upstream does not already provide that name.

`ascii.zsh` is the one hand-written icon file: plain quoted 7-bit literals over `none.zsh`, never an escape
(`tests/test-locale.zsh` enforces both).

Invariants (produced upstream by @kud/glyphs, still enforced by `tests/test-icons.zsh`):

- **Parity** — `nerd.zsh`, `emoji.zsh`, `none.zsh` declare the identical `SHUI_ICON_*` token set (geometrics and the `SHUI_ICON_PL_*` powerline caps included). A set with no glyph for a token still declares it empty. `unicode.zsh` is the thin base layer (geometric shapes only), sourced first.
- **Escape-safe** — `nerd.zsh` uses `$'\UXXXX'` escapes, never raw PUA bytes. Guaranteed by construction upstream, not by hand.
- Never write a literal `SHUI_ICON_<UPPERCASE>` token in a comment inside an icon file — the grep-based parity check counts it as a phantom definition.

Run `mise test` to verify (`tests/test-icons.zsh` checks non-empty values, escape syntax, and parity). To inspect codepoints, see @kud/glyphs' `glyphs.json` — the authoritative `name → { nerd, unicode?, emoji? }` map.

## Colour tokens (`src/tokens/glyphs-colors.zsh`)

**Generated from @kud/glyphs' `zsh/colors.zsh`** by `scripts/sync-colors.zsh`, pinned by its
`GLYPHS_VERSION`. Do not hand-edit; change the token upstream, bump the pin, re-run the sync. The
CI job `colour-tokens` re-runs it and fails on `git diff --exit-code`. The prefix is added, not
swapped (`COLOR_ACCENT_ANSI256` → `SHUI_COLOR_ACCENT_ANSI256`, `STATE_RUNNING_COLOR` →
`SHUI_STATE_RUNNING_COLOR`), so a state's colour value names `SHUI_COLOR_<value>` directly.

Themes derive the rendered `SHUI_COLOR_*` / `SHUI_BG_*` escapes from those numbers with
`_shui_token_color` (ANSI256 on a 256-colour terminal, ANSI16 otherwise) or `_shui_token_color16`
(the ANSI16 floor only — `minimal`). The ANSI16 index is the contract; HEX is not rendered yet.
`SHUI_COLOR_MUTED` deliberately stays SGR 2 (dimColor) in `default`.

Colour roles: headers (`section`, `subtitle`, `subsection`) are bold in the default foreground;
the accent marks names and the current item only. **Warning always carries its glyph** — 214 sits a
hair from the accent's 208 — so any warning-coloured output goes through `_shui_warn_text` or shows
`SHUI_ICON_WARNING`, which `_shui_resolve_tokens` guarantees non-empty (`!` for the `none` set).
`tests/test-warning.zsh` renders every warning call site and guards the sources. Badge text on
each fill follows ink-ui's INK table (black on 79/214/117/208, white on 203).

`SHUI_COLOR_PRIMARY` / `SHUI_BG_PRIMARY` are **deprecated aliases** of `ACCENT`, set by
`_shui_resolve_tokens`; components use `ACCENT`. Do not reintroduce them in themes.

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
