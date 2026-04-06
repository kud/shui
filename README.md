# shui · 水

**Fluid terminal UI for Zsh.**

A design system for the shell. One file to source. A complete set of components — messages, badges, pills, boxes, tables, spinners, and interactive prompts — all styled through a clean token-based theme system.

No dependencies. Pure Zsh.

---

## Install

### Manually

```zsh
git clone https://github.com/kud/shui ~/.shui
```

### As a project submodule (recommended)

```zsh
git submodule add https://github.com/kud/shui lib/shui
```

### Via curl

```zsh
curl -fsSL https://raw.githubusercontent.com/kud/shui/main/install.sh | zsh
```

---

## Quick start

```zsh
source ~/.shui/shui.zsh

shui success "Deployment complete"
shui error   "Build failed"
shui warning "Deprecated flag used"
shui info    "Running in dry-run mode"
```

---

## Importing in your project

Source shui at the top of any Zsh script:

```zsh
#!/usr/bin/env zsh
source "${0:A:h}/lib/shui/shui.zsh"
```

`${0:A:h}` is the Zsh idiom for the absolute directory of the current script — the path resolves correctly regardless of where you call your script from.

Or use an environment variable for a globally installed shui:

```zsh
# ~/.zshrc
export SHUI_DIR="$HOME/.shui"

# your-script.zsh
source "$SHUI_DIR/shui.zsh"
```

To select a theme before loading:

```zsh
SHUI_THEME=minimal source "$SHUI_DIR/shui.zsh"
```

---

## Components

### Messages

```zsh
shui success "Operation completed"
shui error   "Something went wrong"
shui warning "Proceed with caution"
shui info    "For your information"
```

### Text

```zsh
shui bold      "Bold"
shui dim       "Dimmed"
shui italic    "Italic"
shui underline "Underlined"

shui text --color=success "Custom colour"
shui text --color=muted   "Muted colour"
```

Colour types: `success` `error` `warning` `info` `primary` `muted` `accent`

### Layout

```zsh
shui section    "Major Section"
shui subtitle   "Sub-heading"
shui subsection "Nested item"

shui divider        # full-width rule
shui spacer         # one blank line
shui spacer 3       # three blank lines
```

### Inline components

Inline components write to stdout **without a newline** — compose them inside `$(...)`:

```zsh
echo "Version: $(shui badge success v2.0)"
echo "Status:  $(shui pill warning beta)"
echo "$(shui badge error FAIL) Build #42 failed"
```

**Badge** — solid background label:

```zsh
shui badge <type> <text>
```

**Pill** — rounded edge tag:

```zsh
shui pill <type> <text>
shui pill 135 "custom"   # any 256-colour code (0–255)
```

Types: `success` `error` `warning` `info` `primary` `muted` `accent`

### Box

```zsh
shui box "Simple content"
shui box --title="Summary" "3 installed\n1 skipped\n0 errors"
```

Inline components work inside box content:

```zsh
shui box --title="Status" "$(shui badge success OK) All systems nominal"
```

### Table

First argument is the header row. Subsequent arguments are data rows. Columns are pipe-separated (`|`). Column widths are calculated automatically, and inline components in cells are handled correctly.

```zsh
shui table \
  "Package|Version|Status" \
  "node|20.11.0|$(shui badge success OK)" \
  "bun|1.1.3|$(shui badge success OK)" \
  "python|3.12.0|$(shui badge warning outdated)"
```

### Progress

Writes inline — add `echo` to move to the next line:

```zsh
shui progress 45 100
shui progress 45 100 --width=30
shui progress 45 100 --label="Downloading "
echo
```

### Spinner

Runs a command with a spinner. Returns the command's exit code.

```zsh
shui spinner "Installing…" -- brew install ripgrep

shui spinner \
  --success="Installed!" \
  --fail="Installation failed" \
  "Installing…" -- npm install
```

### Interactive

```zsh
# Confirm — exits 0 for yes, 1 for no
shui confirm "Deploy to production?"
shui confirm --default=y "Continue?"

# Select — prints chosen option to stdout
choice=$(shui select "Pick a profile:" work personal staging)

# Input — prints entered value to stdout
name=$(shui input "Your name:")
name=$(shui input --default="world" "Your name:")
```

---

## Themes

### Built-in themes

| Theme     | Description                                  |
| --------- | -------------------------------------------- |
| `default` | 256-colour with automatic 16-colour fallback |
| `minimal` | Clean 16-colour ANSI palette                 |
| `plain`   | No colour — text and ASCII icons only        |

### Selecting a theme

```zsh
SHUI_THEME=minimal source shui.zsh
```

Or export it from your shell profile so all scripts pick it up:

```zsh
export SHUI_THEME=minimal
```

### `NO_COLOR`

shui respects the [NO_COLOR](https://no-color.org/) convention. When `$NO_COLOR` is set, inline components (`badge`, `pill`) fall back to ASCII representations and no colour codes are emitted.

### Custom themes

```zsh
shui theme create mytheme
# → src/themes/mytheme.zsh, pre-filled with all tokens from default
```

Edit the generated file, then load it:

```zsh
SHUI_THEME=mytheme source shui.zsh
```

A custom theme sources `default.zsh` first — you only need to override the tokens you want to change:

```zsh
# src/themes/mytheme.zsh
source "${SHUI_DIR}/src/themes/default.zsh"

SHUI_COLOR_PRIMARY=$(_shui_color "38;5;135" "0;35")  # purple
SHUI_COLOR_ACCENT=$(_shui_color  "38;5;135" "0;35")
```

Validate at any time:

```zsh
shui theme validate
shui theme list
```

### Token reference

| Token                                                                                                | Purpose              |
| ---------------------------------------------------------------------------------------------------- | -------------------- |
| `SHUI_RESET`                                                                                         | Reset all styles     |
| `SHUI_BOLD` `SHUI_DIM` `SHUI_ITALIC` `SHUI_UNDERLINE`                                                | Text styles          |
| `SHUI_COLOR_PRIMARY`                                                                                 | Primary accent       |
| `SHUI_COLOR_SUCCESS`                                                                                 | Success              |
| `SHUI_COLOR_WARNING`                                                                                 | Warning              |
| `SHUI_COLOR_ERROR`                                                                                   | Error                |
| `SHUI_COLOR_INFO`                                                                                    | Informational        |
| `SHUI_COLOR_MUTED`                                                                                   | Secondary / dim text |
| `SHUI_COLOR_ACCENT`                                                                                  | Highlight accent     |
| `SHUI_BG_SUCCESS` `SHUI_BG_WARNING` `SHUI_BG_ERROR` `SHUI_BG_INFO` `SHUI_BG_PRIMARY` `SHUI_BG_MUTED` | Badge backgrounds    |
| `SHUI_ICON_SUCCESS` `SHUI_ICON_ERROR` `SHUI_ICON_WARNING` `SHUI_ICON_INFO`                           | Status icons         |
| `SHUI_ICON_BULLET` `SHUI_ICON_ARROW` `SHUI_ICON_CHECK` `SHUI_ICON_CROSS`                             | UI icons             |

---

## Demo

```zsh
zsh demo.zsh
zsh demo.zsh --interactive   # includes confirm, select, and input
```

---

## Requirements

- Zsh 5.0+
- A [Nerd Font](https://www.nerdfonts.com/) for the `default` and `minimal` themes — or use `SHUI_THEME=plain` for ASCII-only output

---

## License

MIT
