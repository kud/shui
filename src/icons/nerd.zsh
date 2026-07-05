#!/usr/bin/env zsh
#
# nerd icon set — requires a Nerd Font
# https://www.nerdfonts.com/
#
# Format: raw glyph assigned to variable, codepoint in comment.
# To add a new entry: node -e "process.stdout.write(String.fromCodePoint(0xXXXX))"
# then paste the char and note the U+XXXX in the comment.

# ── Status ──────────────────────────────────────────────────────────────────────
SHUI_ICON_SUCCESS=""         # U+F00C  nf-fa-check
SHUI_ICON_ERROR=""           # U+F00D  nf-fa-times
SHUI_ICON_WARNING=""         # U+F071  nf-fa-warning
SHUI_ICON_INFO=""            # U+F05A  nf-fa-info-circle
SHUI_ICON_ARROW=""           # U+F178  nf-fa-long-arrow-right
SHUI_ICON_CHECK=""           # U+F00C  nf-fa-check
SHUI_ICON_CROSS=""           # U+F00D  nf-fa-times
SHUI_ICON_CHECKMARK=""       # U+F058  nf-fa-check-circle
SHUI_ICON_QUESTION=""        # U+F059  nf-fa-question-circle
SHUI_ICON_CHECK_ALT=""       # U+F046  nf-fa-check-square-o
SHUI_ICON_CROSS_ALT=""       # U+F05C  nf-fa-times-circle-o

# ── Arrows ──────────────────────────────────────────────────────────────────────
SHUI_ICON_ARROW_RIGHT=""     # U+F061  nf-fa-arrow-right
SHUI_ICON_ARROW_LEFT=""      # U+F060  nf-fa-arrow-left
SHUI_ICON_ARROW_UP=""        # U+F062  nf-fa-arrow-up
SHUI_ICON_ARROW_DOWN=""      # U+F063  nf-fa-arrow-down

# ── Actions ─────────────────────────────────────────────────────────────────────
SHUI_ICON_DOWNLOAD=""        # U+F019  nf-fa-download
SHUI_ICON_UPLOAD=""          # U+F093  nf-fa-upload
SHUI_ICON_DELETE=""          # U+F1F8  nf-fa-trash
SHUI_ICON_EDIT=""            # U+F040  nf-fa-pencil
SHUI_ICON_SEARCH=""          # U+F002  nf-fa-search
SHUI_ICON_SETTINGS=""        # U+F013  nf-fa-cog
SHUI_ICON_REFRESH=""         # U+F021  nf-fa-refresh
SHUI_ICON_LOCK=""            # U+F023  nf-fa-lock
SHUI_ICON_UNLOCK=""          # U+F09C  nf-fa-unlock

# ── UI ──────────────────────────────────────────────────────────────────────────
SHUI_ICON_TOOLS=""           # U+F0AD  nf-fa-wrench
SHUI_ICON_COMPUTER=""        # U+F108  nf-fa-desktop
SHUI_ICON_PLUG=""            # U+F1E6  nf-fa-plug
SHUI_ICON_INSTALL=""         # U+F487  nf-oct-package
SHUI_ICON_BOLT=""            # U+F0E7  nf-fa-bolt
SHUI_ICON_ROCKET=""          # U+F135  nf-fa-rocket
SHUI_ICON_CLOCK=""           # U+F017  nf-fa-clock-o
SHUI_ICON_FIRE=""            # U+F06D  nf-fa-fire
SHUI_ICON_STAR=""            # U+F005  nf-fa-star
SHUI_ICON_HEART=""           # U+F004  nf-fa-heart
SHUI_ICON_THUMBS_UP=""       # U+F164  nf-fa-thumbs-up

# ── Brackets ────────────────────────────────────────────────────────────────────
SHUI_ICON_INFO_BRACKET=""    # U+F129  nf-fa-info
SHUI_ICON_WARN_BRACKET=""    # U+F12A  nf-fa-exclamation
SHUI_ICON_USER_BRACKET=""    # U+F007  nf-fa-user
SHUI_ICON_INPUT_BRACKET=""   # U+F11C  nf-fa-keyboard-o

# ── General ─────────────────────────────────────────────────────────────────────
SHUI_ICON_STARTER=""         # U+F04B  nf-fa-play
SHUI_ICON_PROMPT=""          # U+F120  nf-fa-terminal
SHUI_ICON_PALETTE=""         # U+F1FC  nf-fa-paint-brush
SHUI_ICON_GLOBE=""           # U+F0AC  nf-fa-globe
SHUI_ICON_TABLE=""           # U+F0CE  nf-fa-table
SHUI_ICON_FORWARD=""         # U+F04E  nf-fa-forward
SHUI_ICON_CHART=""           # U+F080  nf-fa-bar-chart
SHUI_ICON_BUG=""             # U+F188  nf-fa-bug
SHUI_ICON_LOADING=""         # U+F110  nf-fa-spinner

# ── Tech ────────────────────────────────────────────────────────────────────────
SHUI_ICON_ROBOT=""           # U+E28C  nf-mdi-robot
SHUI_ICON_APPLE=""           # U+F179  nf-fa-apple
SHUI_ICON_GIT=""             # U+F1D3  nf-fa-git
SHUI_ICON_FOLDER=""          # U+F07B  nf-fa-folder
SHUI_ICON_LINK=""            # U+F0C1  nf-fa-link
SHUI_ICON_CLOUD=""           # U+F0C2  nf-fa-cloud
SHUI_ICON_BREW=$'\UF0FC'      # U+F0FC  nf-fa-beer
SHUI_ICON_NODE=""            # U+E718  nf-dev-nodejs_small
SHUI_ICON_PYTHON=""          # U+E235  nf-seti-python
SHUI_ICON_RUBY=""            # U+E791  nf-dev-ruby
SHUI_ICON_RUST="󱘗"            # U+F1617  nf-md-language_rust
SHUI_ICON_GEM=""             # U+F219  nf-fa-diamond
SHUI_ICON_GO=""              # U+E627  nf-dev-go
SHUI_ICON_JAVA=""            # U+E256  nf-dev-java
SHUI_ICON_PHP=""             # U+E608  nf-dev-php
SHUI_ICON_SWIFT=""           # U+E755  nf-dev-swift
SHUI_ICON_KOTLIN=""          # U+E634  nf-dev-kotlin
SHUI_ICON_LUA=""             # U+E620  nf-dev-lua
SHUI_ICON_SCALA=""           # U+E737  nf-dev-scala
SHUI_ICON_ZIG=""             # U+E6A9  nf-seti-zig
SHUI_ICON_DART=""            # U+E798  nf-dev-dart
SHUI_ICON_ELIXIR=""          # U+E62D  nf-dev-elixir
SHUI_ICON_ELM=""             # U+E62C  nf-dev-elm
SHUI_ICON_HASKELL=""         # U+E777  nf-dev-haskell
SHUI_ICON_JULIA=""           # U+E624  nf-dev-julia
SHUI_ICON_C=""               # U+E61E  nf-dev-c
SHUI_ICON_CPP=""             # U+E61D  nf-dev-cpp
SHUI_ICON_DOCKER=""          # U+F308  nf-dev-docker
SHUI_ICON_AWS=""             # U+E33D  nf-dev-aws
SHUI_ICON_BUN=""             # U+E76F  nf-seti-bun
SHUI_ICON_NPM=""             # U+E71E  nf-dev-npm

# ── Powerline ───────────────────────────────────────────────────────────────────
SHUI_ICON_PL_ARROW_RIGHT=""  # U+E0B0  nf-pl-right_hard_divider
SHUI_ICON_PL_ARROW_LEFT=""   # U+E0B2  nf-pl-left_hard_divider
SHUI_ICON_PL_CAP_RIGHT=""    # U+E0B4  nf-pl-right_soft_divider
SHUI_ICON_PL_CAP_LEFT=""     # U+E0B6  nf-pl-left_soft_divider


# ── Geometric ───────────────────────────────────────────────────────────────────
# Plain Unicode geometric shapes — universal and render correctly in a Nerd Font,
# so no PUA glyph is needed for these.
SHUI_ICON_BULLET="•"         # U+2022  bullet
SHUI_ICON_CIRCLE="●"         # U+25CF  black circle
SHUI_ICON_CIRCLE_EMPTY="○"   # U+25CB  white circle
SHUI_ICON_SQUARE="■"         # U+25A0  black square
SHUI_ICON_SQUARE_EMPTY="□"   # U+25A1  white square
SHUI_ICON_TRIANGLE="▲"       # U+25B2  black up-pointing triangle
SHUI_ICON_DIAMOND="◆"        # U+25C6  black diamond

# ── Selection ───────────────────────────────────────────────────────────────────
SHUI_ICON_POINTER="❯"        # U+276F  heavy right-pointing angle quotation mark
