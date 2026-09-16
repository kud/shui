# Changelog

All notable changes to this project are documented here.

---

## [1.3.0] — 2026-09-16

### ✨ Features

- shui is one of two renderers of the same terminal design system — `@kud/ink-ui` is the reference — and this release is the first slice of converging on it ([kud/plans#87](https://github.com/kud/plans/issues/87)). Colour now goes through one gate instead of two: `NO_COLOR` and a non-TTY stdout strip every escape sequence, across every theme and every component, not just `badge` and `pill` as before — previously piping `shui table`, `shui section`, or almost anything else through `less` or a log file left raw ANSI in the output, because only those two components checked `NO_COLOR` themselves. `FORCE_COLOR` outranks both, the same precedence chalk gives ink-ui, so a script piped through `less -R` or a test harness can ask for colour back. The check happens once at source time using `tput` and `-t 1` against real stdout, deliberately outside any command substitution — a `$(...)` capture pipe is never a terminal, so testing inside one would always read as "no colour". ([b202a2f](https://github.com/kud/shui/commit/b202a2f4ba015aef37963f90496f53f6bc1d8f12))
- The default theme now carries `@kud/ink-ui`'s own token values instead of a 256-colour approximation of them. Semantic colours ink-ui names by ANSI colour (`green`, `yellow`, `cyan`, `red`, `magenta`) now follow the terminal's own palette instead of being pinned to fixed 256-colour cells; `primary` is ink-ui's accent `#FF8C00` and `secondary` is `#999999`, both taking the nearest 256-colour cell. `warning` moves from orange to yellow and `info` from blue to cyan to match. A new `group` token (magenta) joins the semantic set. Muted text is now SGR 2 (dim) — exactly what ink-ui's `dimColor` emits — replacing italic on a fixed grey 240: a fixed grey reads as body text on light themes and drops below the floor on very dark ones, and terminal italic's actual failure mode is reverse video, which inverts the emphasis it was meant to lower. `shui section` headings drop primary-yellow entirely and render bold in the default foreground instead — a heading is structure, not a claim, and primary-yellow reads as a warning in ink-ui's own vocabulary. The `minimal` theme's colour literals go through the same gate as everything else, help text gains a COLOUR block documenting `NO_COLOR`/`FORCE_COLOR`, and a new `tests/test-color-gate.zsh` pins the precedence and the one-shot semantic rulings — the test harness now exports `FORCE_COLOR=1` so existing colour-dependent coverage keeps testing real escape sequences under the piped test run instead of silently degrading to plain text. Not in this release, deliberately: the default icon set stays `nerd` — moving it to unicode waits on `@kud/glyphs` gaining a `unicode` variant for the status glyphs. ([b202a2f](https://github.com/kud/shui/commit/b202a2f4ba015aef37963f90496f53f6bc1d8f12))

### 🐛 Bug Fixes

- `shui row`'s default tag column widens from 8 to 9 characters, so common real-world tags like `untracked` and `snapshots` pad correctly instead of falling into the overflow path; test coverage grows to cover them. ([2dccb65](https://github.com/kud/shui/commit/2dccb650cb933bab8761ede34317ddb5091f3754))

---

## [1.2.4] — 2026-08-27

### 🐛 Bug Fixes

- `shui loader --duration=N` could hang forever when called from a script, because `EPOCHSECONDS` was never populated — that parameter comes from the `zsh/datetime` module, which an interactive profile generally loads and a plain `zsh script.zsh` never does. Unset, it reads as empty in arithmetic, so `(( EPOCHSECONDS < end ))` evaluated as `0 < N` and stayed true forever: the loader spun until killed, across all three styles (`dots`, `pulse`, `spinner`). It worked flawlessly when tried by hand in a terminal, which is exactly why it went unnoticed — the failure only shows up in the one shape nobody sits and watches. `shui debug-timing` hit the same gap more quietly, reporting every operation as `0s`. `shui.zsh` now calls `zmodload zsh/datetime` at load time, so every component gets it rather than whichever one happened to need it next. A new regression test, `tests/test-loader.zsh`, pins the fix — it first proves the hang is real by unloading the module and watching the loader spin, so the termination checks that follow aren't passing by finding nothing. ([8cb4dcf](https://github.com/kud/shui/commit/8cb4dcf))

---

## [1.2.3] — 2026-08-17

### 🐛 Bug Fixes

- `_shui_visible_len` now measures **characters**, not bytes. It counted bytes (`wc -c`), so every multi-byte character made its caller pad short by bytes-minus-characters: a table cell holding an em dash came out two columns narrow and walked the right-hand border off the grid, and boxes and rows drifted the same way. The padding maths in the callers was correct throughout — only the measurement was wrong, which is why it survived every table anyone had drawn with it. Astral-plane emoji now count as two columns to match the emoji icon set, while Nerd Font PUA glyphs stay single-width. ([5d261d1](https://github.com/kud/shui/commit/5d261d1))
- The same function no longer shells out. It ran `echo | sed | wc | tr` — four forks — for **every cell of every table**, which on a machine with an endpoint-security agent inspecting each `exec` cost roughly 235ms per call: a 230-row table took 47 seconds to measure. It is now pure zsh parameter expansion, ~3600x faster on that workload, and dropping `echo` also stops a value containing a literal `\t` or `\n` being mangled before it is measured. ([5d261d1](https://github.com/kud/shui/commit/5d261d1))
- Interactive prompts (`confirm`, `select`, `radio`, `multiselect`, `input`, `password`) and the tabs bar now redirect **stdout**, not just stdin, to `/dev/tty` when putting the terminal into raw mode via `stty`. Previously, piping shui's output to a log file left stdin still pointed at the real terminal while stdout went elsewhere — GNU `stty` treats that as a mismatch and prints "stdout appears redirected, but stdin is the control descriptor" into the log on every single prompt. BSD `stty` never raised it, so the noise was invisible locally and only showed up on hosts where GNU coreutils comes first on `PATH`. ([176094d](https://github.com/kud/shui/commit/176094ddb0f4eba492c2a33d7ff3b32806d668ec))

---

## [1.2.1] — 2026-07-20

### 💥 Breaking Changes

- `shui tabs` was reshaped from a two-level picker into a live horizontal tab bar — ←/→ or 1-9 move between tabs, enter confirms. Callers written against the old two-level flow need updating. ([354ae1b](https://github.com/kud/shui/commit/354ae1b))

---

## [1.2.0] — 2026-07-20

### ✨ Features

- `shui fence` gained `--color=<type>` and `--char=C`, bringing it in line with `divider`, which had both already. The colour tints the **label only** — the rule stays muted, so a section header reads as a heading rather than a stripe of colour across the terminal. It mirrors ink-ui's `Header`, which pairs a bold title with a dim subtitle. `shui fence "keys" --color=error` now gives `── keys ─────────────` with a red bold label, which is what a labelled rule wanted to be all along. ([d565a60](https://github.com/kud/shui/commit/d565a60))
- New interactive components: `tabs`, a masked `password` field, and `--validate=email|url|number|<regex>` on `input`. ([02d3261](https://github.com/kud/shui/commit/02d3261))
- Zsh completion for `shui`, kept in parity with the dispatcher by `tests/test-completion.zsh`. ([a53d2a5](https://github.com/kud/shui/commit/a53d2a5))
- `SHUI_ICON_KEY` and `SHUI_ICON_FILE` added across all icon sets. ([01d0023](https://github.com/kud/shui/commit/01d0023))

<details>
<summary>🔧 Internal changes</summary>

- New `tests/test-fence.zsh` (13 assertions) pins the two properties that are easy to break and invisible in review: every render is exactly `$_SHUI_TERMINAL_WIDTH` visible columns whatever the label length, and `--color` never leaks into the rule. The width assertions count **characters, not bytes** — the rule uses U+2500 at 3 bytes each, so a byte-based length reads triple and would hide real overflow.
- `shui fence --help` and the main `shui help` listing now document both flags.
- The icon generator moved from a node script to a zsh sync script, removing the last runtime dependency from the toolchain. ([398da5e](https://github.com/kud/shui/commit/398da5e), [86d34f9](https://github.com/kud/shui/commit/86d34f9))

</details>

---

## [1.1.1] — 2026-07-17

### 🐛 Bug Fixes

- `shui row` now emits a literal separator after each column instead of relying on width padding alone — padding collapses to nothing the moment a value exactly fills its column (an 8-char tag like `attached` in the 8-wide default rendered `attachedid_ed25519`), and does nothing at all once a value overflows. Columns now stay columns for any input.
- `shui version` had been reporting `0.1.0` while the git tag said `1.1.0` — `git lzv` was tagging releases without ever writing `SHUI_VERSION` or `VERSION`. Both are now synced from the tag before every release, closing the gap for good ([#0fc19e1](https://github.com/kud/shui/commit/0fc19e11dc8f8ab87ccd0d3de18e2b5ab3886ad3)).
- `shui row` is now listed in the main `shui help` output — it previously only had its own per-command help and was easy to miss.

<details>
<summary>🔧 Internal changes (1 commit)</summary>

- Add `bin/release.sh`, which syncs `SHUI_VERSION`/`VERSION` from the tag before handing off to `git lzv`; `--sync` repairs existing drift without cutting a release, `--dry-run` previews the target version. `CLAUDE.md` now documents it as the required release path ([#0fc19e1](https://github.com/kud/shui/commit/0fc19e11dc8f8ab87ccd0d3de18e2b5ab3886ad3)).

</details>

---

## [1.1.0] — 2026-07-17

### ✨ Features

- Add a new `row` streaming status-row component for reporting items one at a time as they happen, without buffering all input first the way `table` does ([#aa130b8](https://github.com/kud/shui/commit/aa130b86e8ee54b1ae2c747ad5d2e5c6d10d2a6d))
- Add geometric (bullet, circle, square, triangle, diamond), pointer, and npm icon tokens across every icon set (nerd, emoji, none), a new `_shui_prompt()` component, and a CI workflow running `mise lint` + `mise test` on every push and PR ([#0a83dfa](https://github.com/kud/shui/commit/0a83dfafa9182a2f8a3359447e7c6ea9ce2c3170))
- Interactive components (`select`, `radio`, `multiselect`) gained vim-style navigation — `j`/`k` to move, `g`/`G` to jump to first/last, `q`/`Q` to cancel — plus a fix for the escape-key ambiguity that could misfire on fast keypresses ([#ffb4d89](https://github.com/kud/shui/commit/ffb4d89443293330e992910b5c02126181889e02))
- Redesign `radio` visuals: a pointer (❯) icon replaces the circle for the selected option, unselected options use blank space instead of an empty circle, and descriptions move to a higher-contrast colour ([#c9ef362](https://github.com/kud/shui/commit/c9ef3625e68abf370d1a02cadf8c76713c3b62e2))

### 🐛 Bug Fixes

- Fix a padding bug in interactive prompts where multi-byte or Nerd Font pointer glyphs threw off column alignment ([#96209e0](https://github.com/kud/shui/commit/96209e0bf583703dd6961bf0ec11b3f3952d6164))
- Prompt labels in `select`, `radio`, `multiselect`, and `input` now render bold, matching the visual weight of the rest of the UI ([#faf2166](https://github.com/kud/shui/commit/faf2166067717f33ac016f4983b674c907f4a062))
- Fix a `grep` false-positive that could corrupt the raw-glyph count check on icon definitions ([#bed67aa](https://github.com/kud/shui/commit/bed67aa1ea0a8b7c8492cf44889f1a78e776f49b))

### 📝 Documentation

- Slim the README down to a GitHub front page aligned with the canonical kud-site shape, with full docs living on kud.io ([#606a0c0](https://github.com/kud/shui/commit/606a0c04dc651d7b85c918945adce4e78c02b136))
- Reframe shui as a design system on the landing page — component showcase, theme engine — with emoji headings for easier scanning ([#e4706f7](https://github.com/kud/shui/commit/e4706f726affeab091d1526ab96540f21f801254))

<details>
<summary>🔧 Internal changes (2 commits)</summary>

- refactor(icons): replace raw glyph bytes with `$'\UXXXX'` escape sequences in icon definitions, keeping the source ASCII-safe and diff-friendly, enforced by new icon tests ([#5409ce7](https://github.com/kud/shui/commit/5409ce78d4e4152d7a9d89cbf52c49a09638b420))
- chore: remove the obsolete GitHub Pages workflow now that docs live on kud.io/projects ([#1fc8335](https://github.com/kud/shui/commit/1fc8335be3d626718a54272d22843b4e9abc8983))

</details>

---

## [1.0.2] — 2026-06-17

### 🐛 Bug Fixes

- Remove double-dim on radio/multiselect description rendering ([#818642d](https://github.com/kud/shui/commit/818642d))

---

## [1.0.1] — 2026-04-25

### 🐛 Bug Fixes

- Restore cursor visibility in radio and multiselect ([#be8a5cc](https://github.com/kud/shui/commit/be8a5cc))

---

## [1.0.0] — 2026-04-24

### ✨ Features

- Add unified `shui message <type> <text>` API for inline messages

### ⚠️ Deprecations

- Deprecate `info-simple`, `warning-simple`, `success-simple`, `error-simple` in favour of `shui message` — legacy functions still work but print migration warning to stderr

---

## [v0.4.13] — 2026-04-12

<details>
<summary>🔧 Internal changes (1 commit)</summary>

- style(interactive): align radio descriptions and dim secondary text ([#1f809e4](https://github.com/kud/shui/commit/1f809e4))

</details>

---

## [v0.4.12] — 2026-04-12

### ✨ Features

- Support optional muted descriptions in radio options ([#49bb3e3](https://github.com/kud/shui/commit/49bb3e3))

---

## [v0.4.11] — 2026-04-12

### ✨ Features

- Add radio and multiselect components ([#bdb5991](https://github.com/kud/shui/commit/bdb5991))

### 🐛 Bug Fixes

- Replace numbered input with arrow-key navigation for radio/multiselect ([#4f04544](https://github.com/kud/shui/commit/4f04544))

---

## [v0.4.10] — 2026-04-12

<details>
<summary>🔧 Internal changes (1 commit)</summary>

- test(components): add comprehensive tests for banner and screen components ([#5e012e3](https://github.com/kud/shui/commit/5e012e3))

</details>

---

## [v0.4.9] — 2026-04-12

<details>
<summary>🔧 Internal changes (1 commit)</summary>

- style(banner): add trailing blank line after closing bar for breathing room ([#8f28389](https://github.com/kud/shui/commit/8f28389))

</details>

---

## [v0.4.8] — 2026-04-12

<details>
<summary>🔧 Internal changes (1 commit)</summary>

- style(banner): remove hardcoded bold styling from content text ([#bc15fdb](https://github.com/kud/shui/commit/bc15fdb))

</details>

---

## [v0.4.7] — 2026-04-12

### 📝 Documentation

- Simplify box and table markup in docs ([#b65888c](https://github.com/kud/shui/commit/b65888c))

---

## [v0.4.6] — 2026-04-12

### 📝 Documentation

- Update landing page with examples section and copy improvements ([#16fd18d](https://github.com/kud/shui/commit/16fd18d))

---

## [v0.4.5] — 2026-04-12

### ✨ Features

- Redesign documentation homepage with new CSS ([#a9cd7f9](https://github.com/kud/shui/commit/a9cd7f9))

---

## [v0.4.4] — 2026-04-12

<details>
<summary>🔧 Internal changes (1 commit)</summary>

- ci(docs): add GitHub Pages deploy workflow ([#7fc9ca7](https://github.com/kud/shui/commit/7fc9ca7))

</details>

---

## [v0.4.3] — 2026-04-11

### 🐛 Bug Fixes

- Route display output to stderr for command substitution ([#035cf15](https://github.com/kud/shui/commit/035cf15))

---

## [v0.4.2] — 2026-04-11

### ✨ Features

- Add fence component for labeled dividers ([#dc2629a](https://github.com/kud/shui/commit/dc2629a))

---

## [v0.4.1] — 2026-04-11

### 🐛 Bug Fixes

- Improve accent colour for colourblind accessibility ([#faa1031](https://github.com/kud/shui/commit/faa1031))

<details>
<summary>🔧 Internal changes (1 commit)</summary>

- style(message): add italic styling to muted output ([#291d702](https://github.com/kud/shui/commit/291d702))

</details>

---

## [v0.4.0] — 2026-04-11

### ♻️ Refactoring

- Introduce unicode base layer, clarify loading order ([#dbb5d25](https://github.com/kud/shui/commit/dbb5d25))

---

## [v0.3.12] — 2026-04-11

### ♻️ Refactoring

- Use icon variables for cap glyphs in pill ([#eb2465a](https://github.com/kud/shui/commit/eb2465a))

---

## [v0.3.11] — 2026-04-11

### 🐛 Bug Fixes

- Reset Zsh styling after subsection bullet ([#28fa9f4](https://github.com/kud/shui/commit/28fa9f4))

---

## [v0.3.10] — 2026-04-11

<details>
<summary>🔧 Internal changes (1 commit)</summary>

- style(layout,icons,theme): harmonise accent colour and geometric icons ([#143fbe7](https://github.com/kud/shui/commit/143fbe7))

</details>

---

## [v0.3.9] — 2026-04-11

### 🐛 Bug Fixes

- Replace unsupported robot icon with JetBrains Mono compatible glyph ([#d0fe309](https://github.com/kud/shui/commit/d0fe309))

### ♻️ Refactoring

- Reorganise Nerd Font glyphs into semantic sections with U+XXXX codepoints ([#0ece018](https://github.com/kud/shui/commit/0ece018))

---

## [v0.3.8] — 2026-04-10

### ✨ Features

- Add `--label` flag to separate timer display from title ([#ffe553c](https://github.com/kud/shui/commit/ffe553c))

---

## [v0.3.7] — 2026-04-10

<details>
<summary>🔧 Internal changes (1 commit)</summary>

- style(pill): use Powerline rounded caps for pill rendering ([#e1e24da](https://github.com/kud/shui/commit/e1e24da))

</details>

---

## [v0.3.6] / [v0.3.5] — 2026-04-10

### ✨ Features

- Add `timer-start` and `timer-end` for per-step timing ([#a9a85ac](https://github.com/kud/shui/commit/a9a85ac))

### 📝 Documentation

- Document `timer-start` and `timer-end` features ([#6e81c9c](https://github.com/kud/shui/commit/6e81c9c))

---

## [v0.3.4] — 2026-04-10

### ♻️ Refactoring

- Remove pulse effect support from animation ([#4187b4b](https://github.com/kud/shui/commit/4187b4b))

---

## [v0.3.3] — 2026-04-10

### ♻️ Refactoring

- Include title in screen timer and remove bullet from muted messages ([#65e61cd](https://github.com/kud/shui/commit/65e61cd))

---

## [v0.3.2] — 2026-04-10

### 📝 Documentation

- Document loader component and update components list ([#c9d7bf4](https://github.com/kud/shui/commit/c9d7bf4))

---

## [v0.3.1] — 2026-04-10

### ✨ Features

- Add extended icons for languages and tools ([#f93ba4e](https://github.com/kud/shui/commit/f93ba4e))

---

## [v0.3.0] / [v0.2.14] — 2026-04-10

### ✨ Features

- Add screen layout section with timing ([#264927c](https://github.com/kud/shui/commit/264927c))

---

## [v0.2.13] — 2026-04-10

<details>
<summary>🔧 Internal changes (1 commit)</summary>

- style(layout): replace subtitle arrow with diamond glyph ([#bef3667](https://github.com/kud/shui/commit/bef3667))

</details>

---

## [v0.2.12] — 2026-04-10

<details>
<summary>🔧 Internal changes (1 commit)</summary>

- chore(core): prevent multiple sourcing of shui.zsh ([#b1014ca](https://github.com/kud/shui/commit/b1014ca))

</details>

---

## [v0.2.11] — 2026-04-10

<details>
<summary>🔧 Internal changes (1 commit)</summary>

- style(banner): add leading newline to banner bar ([#9951b47](https://github.com/kud/shui/commit/9951b47))

</details>

---

## [v0.2.10] — 2026-04-10

### ✨ Features

- Add new Nerd Font icons for languages and tools ([#28e52f4](https://github.com/kud/shui/commit/28e52f4))

---

## [v0.2.9] — 2026-04-09

### 🐛 Bug Fixes

- Adjust muted message formatting ([#5e5d838](https://github.com/kud/shui/commit/5e5d838))

---

## [v0.2.8] — 2026-04-09

### 📝 Documentation

- Add Nerd Font icon usage and inspection rules to README ([#7ae7af2](https://github.com/kud/shui/commit/7ae7af2))

---

## [v0.2.7] — 2026-04-09

<details>
<summary>🔧 Internal changes (1 commit)</summary>

- test(icons): add icon set integrity tests and harness update ([#d33420c](https://github.com/kud/shui/commit/d33420c))

</details>

---

## [v0.2.6] — 2026-04-09

### ♻️ Refactoring

- Replace box-drawing with left-border bar design for banner ([#12b108f](https://github.com/kud/shui/commit/12b108f))

---

## [v0.2.5] — 2026-04-09

### ✨ Features

- Add banner component, simplify prompts, improve text/progress/confirm ([#a8f6f45](https://github.com/kud/shui/commit/a8f6f45))

---

## [v0.2.4] — 2026-04-09

### 🐛 Bug Fixes

- Support y|n default for `shui confirm` ([#02181fa](https://github.com/kud/shui/commit/02181fa))

---

## [v0.2.3] — 2026-04-09

### ♻️ Refactoring

- Move demo.zsh to scripts/ and remove antidote plugin entry point ([#0dc640d](https://github.com/kud/shui/commit/0dc640d))

---

## [v0.2.2] — 2026-04-09

<details>
<summary>🔧 Internal changes (1 commit)</summary>

- chore(plugin): add shui.plugin.zsh plugin loader ([#f4f63b3](https://github.com/kud/shui/commit/f4f63b3))

</details>

---

## [v0.2.1] — 2026-04-09

### 📝 Documentation

- Add development section with task runner and test info to README ([#5647294](https://github.com/kud/shui/commit/5647294))

---

## [v0.2.0] — 2026-04-09

<details>
<summary>🔧 Internal changes (1 commit)</summary>

- test: add shared Zsh test harness and modernise tests ([#409f76b](https://github.com/kud/shui/commit/409f76b))

</details>

---

## [v0.1.2] — 2026-04-08

<details>
<summary>🔧 Internal changes (1 commit)</summary>

- test: add comprehensive tests for components ([#e3d28b6](https://github.com/kud/shui/commit/e3d28b6))

</details>

---

## [v0.1.1] — 2026-04-08

### ✨ Features

- Add iTerm2 badge support for progress and spinner ([#762ff40](https://github.com/kud/shui/commit/762ff40))

---

## [v0.1.0] — 2026-04-08

### ✨ Features

- Scaffold shui — fluid terminal UI for Zsh ([#c19ab47](https://github.com/kud/shui/commit/c19ab47))
- Add icon set selection with emoji and none variants ([#9bc7abc](https://github.com/kud/shui/commit/9bc7abc))
- Phase 1 — close API gap with ui-kit.zsh ([#eed61b7](https://github.com/kud/shui/commit/eed61b7))
- Update README with PNG pipeline and install methods ([#072f809](https://github.com/kud/shui/commit/072f809))

### 🐛 Bug Fixes

- Fix local variable leaks, table column split, and ANSI escape quoting ([#6fa1a2e](https://github.com/kud/shui/commit/6fa1a2e))

### 📝 Documentation

- Enhance intro with branding and badges ([#9ed8b28](https://github.com/kud/shui/commit/9ed8b28))
- Restructure and expand component docs ([#322feae](https://github.com/kud/shui/commit/322feae))
- Clarify svg-term usage for final frame ([#184e732](https://github.com/kud/shui/commit/184e732))
- Update component SVG screenshots ([#2c01db2](https://github.com/kud/shui/commit/2c01db2))

<details>
<summary>🔧 Internal changes (3 commits)</summary>

- chore(root): add MIT License file ([#be3cce2](https://github.com/kud/shui/commit/be3cce2))
- chore(readme): remove embedded image references and metadata ([#bea5e91](https://github.com/kud/shui/commit/bea5e91))
- test(feat-close-api-gap): add comprehensive test suite for API gap closure ([#b80625c](https://github.com/kud/shui/commit/b80625c))

</details>
