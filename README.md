<div align="center">
  <img src="icon.png" width="128" alt="shui" />
  <h1>shui · 水</h1>
  <p><strong>Fluid terminal UI for Zsh.</strong></p>
  <p>
    <img src="https://img.shields.io/badge/zsh-5.0%2B-blue" alt="Zsh 5.0+" />
    <img src="https://img.shields.io/badge/dependencies-none-brightgreen" alt="No dependencies" />
    <img src="https://img.shields.io/badge/license-MIT-lightgrey" alt="MIT" />
  </p>
</div>

---

Most Zsh scripts scatter raw `echo -e "\033[32m..."` calls everywhere. shui gives you a proper design system instead — semantic components, a token-based theme engine, and a single consistent API.

One file to source. No dependencies. Pure Zsh.

---

## Table of contents

- [Installation](#installation)
- [Quick start](#quick-start)
- [Usage](#usage)
  - [Importing in your project](#importing-in-your-project)
  - [Components](#components)
    - [Messages](#messages)
    - [Text](#text)
    - [Layout](#layout)
    - [Badge](#badge)
    - [Pill](#pill)
    - [Box](#box)
    - [Table](#table)
    - [Progress](#progress)
    - [Spinner](#spinner)
    - [Interactive](#interactive)
- [Themes](#themes)
  - [Built-in themes](#built-in-themes)
  - [Selecting a theme](#selecting-a-theme)
  - [NO_COLOR](#no_color)
  - [Custom themes](#custom-themes)
  - [Token reference](#token-reference)
- [Icons](#icons)
  - [Icon sets](#icon-sets)
  - [Selecting an icon set](#selecting-an-icon-set)
- [Demo](#demo)
- [Requirements](#requirements)
- [License](#license)

---

## Installation

### Manually

```zsh
git clone https://github.com/kud/shui ~/.shui
```

### As a project submodule (recommended)

```zsh
git submodule add https://github.com/kud/shui lib/shui
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

## Usage

### Importing in your project

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

### Components

#### Messages

The four semantic message types. Each prints an icon and coloured text on its own line.

```zsh
shui success "Operation completed"
shui error   "Something went wrong"
shui warning "Proceed with caution"
shui info    "For your information"
```

![messages](assets/messages.svg)

---

#### Text

Inline text formatting and semantic colour helpers.

```zsh
shui bold      "Bold"
shui dim       "Dimmed"
shui italic    "Italic"
shui underline "Underlined"

shui text --color=success "Custom colour"
shui text --color=muted   "Muted colour"
```

Available colour types: `success` `error` `warning` `info` `primary` `muted` `accent`

---

#### Layout

Structure your script output with sections, headings, and spacing.

```zsh
shui section    "Major Section"     # bold, coloured top-level heading
shui subtitle   "Sub-heading"       # arrow + bold
shui subsection "Nested item"       # indented bullet

shui divider                        # full-width horizontal rule
shui spacer                         # one blank line
shui spacer 3                       # three blank lines
```

![layout](assets/layout.svg)

---

#### Badge

Solid background inline label. Writes to stdout **without a newline** — use inside `$(...)`.

```zsh
echo "Version: $(shui badge success v2.0)"
echo "$(shui badge error FAIL) Build #42 failed"
```

```zsh
shui badge <type> <text>
```

Available types: `success` `error` `warning` `info` `primary` `muted`

---

#### Pill

Rounded-edge inline tag. Writes to stdout **without a newline** — use inside `$(...)`.

```zsh
echo "Status: $(shui pill warning beta)"
echo "$(shui pill success stable)  $(shui pill muted deprecated)"
```

```zsh
shui pill <type> <text>
shui pill 135 "custom"   # any 256-colour code (0–255)
```

Available types: `success` `error` `warning` `info` `primary` `muted` `accent` or any `0–255` colour code

![inline](assets/inline.svg)

---

#### Box

Bordered content block with an optional title. Inline components work inside content.

```zsh
shui box "Simple content"
shui box --title="Summary" "3 installed\n1 skipped\n0 errors"
shui box --title="Status" "$(shui badge success OK) All systems nominal"
```

![box](assets/box.svg)

---

#### Table

Pipe-separated (`|`) rows. First argument is the header. Column widths adjust automatically and inline components in cells are handled correctly.

```zsh
shui table \
  "Package|Version|Status" \
  "node|20.11.0|$(shui badge success OK)" \
  "bun|1.1.3|$(shui badge success OK)" \
  "python|3.12.0|$(shui badge warning outdated)"
```

![table](assets/table.svg)

---

#### Progress

Renders a progress bar inline. Add `echo` after to move to the next line.

```zsh
shui progress 45 100
shui progress 45 100 --width=30
shui progress 45 100 --label="Downloading "
echo
```

---

#### Spinner

Runs a command in the background with a spinner. Exits with the command's exit code.

```zsh
shui spinner "Installing…" -- brew install ripgrep

shui spinner \
  --success="Installed!" \
  --fail="Installation failed" \
  "Installing…" -- npm install
```

---

#### Interactive

Prompt the user for confirmation, a selection, or free-form input.

```zsh
# Confirm — exits 0 for yes, 1 for no
shui confirm "Deploy to production?"
shui confirm --default=y "Continue?"

# Select — prints the chosen option to stdout
choice=$(shui select "Pick a profile:" work personal staging)

# Input — prints the entered value to stdout
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

---

### Selecting a theme

```zsh
SHUI_THEME=minimal source shui.zsh
```

Or export it from your shell profile so all scripts pick it up automatically:

```zsh
export SHUI_THEME=minimal
```

---

### NO_COLOR

shui respects the [NO_COLOR](https://no-color.org/) convention. When `$NO_COLOR` is set, inline components (`badge`, `pill`) fall back to ASCII representations and no colour codes are emitted.

---

### Custom themes

Generate a new theme pre-filled with all tokens:

```zsh
shui theme create mytheme
# → src/themes/mytheme.zsh
```

A custom theme sources `default.zsh` first — only override the tokens you want to change:

```zsh
# src/themes/mytheme.zsh
source "${SHUI_DIR}/src/themes/default.zsh"

SHUI_COLOR_PRIMARY=$(_shui_color "38;5;135" "0;35")  # purple
SHUI_COLOR_ACCENT=$(_shui_color  "38;5;135" "0;35")
```

Load it:

```zsh
SHUI_THEME=mytheme source shui.zsh
```

Manage themes:

```zsh
shui theme list       # list available themes
shui theme validate   # check all required tokens are defined
```

---

### Token reference

| Token                                                                                                | Purpose                  |
| ---------------------------------------------------------------------------------------------------- | ------------------------ |
| `SHUI_RESET`                                                                                         | Reset all styles         |
| `SHUI_BOLD` `SHUI_DIM` `SHUI_ITALIC` `SHUI_UNDERLINE`                                                | Text styles              |
| `SHUI_COLOR_PRIMARY`                                                                                 | Primary accent colour    |
| `SHUI_COLOR_SUCCESS`                                                                                 | Success colour           |
| `SHUI_COLOR_WARNING`                                                                                 | Warning colour           |
| `SHUI_COLOR_ERROR`                                                                                   | Error colour             |
| `SHUI_COLOR_INFO`                                                                                    | Info colour              |
| `SHUI_COLOR_MUTED`                                                                                   | Secondary / dim text     |
| `SHUI_COLOR_ACCENT`                                                                                  | Highlight accent         |
| `SHUI_BG_SUCCESS` `SHUI_BG_WARNING` `SHUI_BG_ERROR` `SHUI_BG_INFO` `SHUI_BG_PRIMARY` `SHUI_BG_MUTED` | Badge background colours |
| `SHUI_ICON_SUCCESS` `SHUI_ICON_ERROR` `SHUI_ICON_WARNING` `SHUI_ICON_INFO`                           | Status icons             |
| `SHUI_ICON_BULLET` `SHUI_ICON_ARROW` `SHUI_ICON_CHECK` `SHUI_ICON_CROSS`                             | UI icons                 |

---

## Icons

### Icon sets

| Set     | Requires                                | Description                     |
| ------- | --------------------------------------- | ------------------------------- |
| `nerd`  | [Nerd Font](https://www.nerdfonts.com/) | Rich glyphicons _(default)_     |
| `emoji` | Nothing                                 | Unicode emoji, works everywhere |
| `none`  | Nothing                                 | No icons — text only            |

### Selecting an icon set

```zsh
SHUI_ICONS=emoji source shui.zsh   # emoji
SHUI_ICONS=nerd  source shui.zsh   # nerd font (default)
SHUI_ICONS=none  source shui.zsh   # no icons
```

Combine freely with any theme:

```zsh
SHUI_THEME=minimal SHUI_ICONS=emoji source shui.zsh
SHUI_THEME=plain   SHUI_ICONS=none   source shui.zsh   # fully plain
```

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
