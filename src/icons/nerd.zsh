#!/usr/bin/env zsh
#
# nerd icon set — requires a Nerd Font
# https://www.nerdfonts.com/
#
# Format: $'\UXXXXXXXX' escape assigned to variable, codepoint in comment.
# Raw glyphs are forbidden here (enforced by tests/test-icons.zsh) — the escape
# form keeps the source pure ASCII and portable.
# To add a new entry, assign the escape with the codepoint noted in a comment:
#   SHUI_ICON_<NAME>=$'\U0001F600'  # U+1F600  description

# ── Status ──────────────────────────────────────────────────────────────────────
SHUI_ICON_SUCCESS=$'\U0000F00C'         # U+F00C  nf-fa-check
SHUI_ICON_ERROR=$'\U0000F00D'           # U+F00D  nf-fa-times
SHUI_ICON_WARNING=$'\U0000F071'         # U+F071  nf-fa-warning
SHUI_ICON_INFO=$'\U0000F05A'            # U+F05A  nf-fa-info-circle
SHUI_ICON_ARROW=$'\U0000F178'           # U+F178  nf-fa-long-arrow-right
SHUI_ICON_CHECK=$'\U0000F00C'           # U+F00C  nf-fa-check
SHUI_ICON_CROSS=$'\U0000F00D'           # U+F00D  nf-fa-times
SHUI_ICON_CHECKMARK=$'\U0000F058'       # U+F058  nf-fa-check-circle
SHUI_ICON_QUESTION=$'\U0000F059'        # U+F059  nf-fa-question-circle
SHUI_ICON_CHECK_ALT=$'\U0000F046'       # U+F046  nf-fa-check-square-o
SHUI_ICON_CROSS_ALT=$'\U0000F05C'       # U+F05C  nf-fa-times-circle-o

# ── Arrows ──────────────────────────────────────────────────────────────────────
SHUI_ICON_ARROW_RIGHT=$'\U0000F061'     # U+F061  nf-fa-arrow-right
SHUI_ICON_ARROW_LEFT=$'\U0000F060'      # U+F060  nf-fa-arrow-left
SHUI_ICON_ARROW_UP=$'\U0000F062'        # U+F062  nf-fa-arrow-up
SHUI_ICON_ARROW_DOWN=$'\U0000F063'      # U+F063  nf-fa-arrow-down

# ── Actions ─────────────────────────────────────────────────────────────────────
SHUI_ICON_DOWNLOAD=$'\U0000F019'        # U+F019  nf-fa-download
SHUI_ICON_UPLOAD=$'\U0000F093'          # U+F093  nf-fa-upload
SHUI_ICON_DELETE=$'\U0000F1F8'          # U+F1F8  nf-fa-trash
SHUI_ICON_EDIT=$'\U0000F040'            # U+F040  nf-fa-pencil
SHUI_ICON_SEARCH=$'\U0000F002'          # U+F002  nf-fa-search
SHUI_ICON_SETTINGS=$'\U0000F013'        # U+F013  nf-fa-cog
SHUI_ICON_REFRESH=$'\U0000F021'         # U+F021  nf-fa-refresh
SHUI_ICON_LOCK=$'\U0000F023'            # U+F023  nf-fa-lock
SHUI_ICON_UNLOCK=$'\U0000F09C'          # U+F09C  nf-fa-unlock
SHUI_ICON_KEY=$'\U0000F084'             # U+F084  nf-fa-key

# ── UI ──────────────────────────────────────────────────────────────────────────
SHUI_ICON_TOOLS=$'\U0000F0AD'           # U+F0AD  nf-fa-wrench
SHUI_ICON_COMPUTER=$'\U0000F108'        # U+F108  nf-fa-desktop
SHUI_ICON_PLUG=$'\U0000F1E6'            # U+F1E6  nf-fa-plug
SHUI_ICON_INSTALL=$'\U0000F487'         # U+F487  nf-oct-package
SHUI_ICON_BOLT=$'\U0000F0E7'            # U+F0E7  nf-fa-bolt
SHUI_ICON_ROCKET=$'\U0000F135'          # U+F135  nf-fa-rocket
SHUI_ICON_CLOCK=$'\U0000F017'           # U+F017  nf-fa-clock-o
SHUI_ICON_FIRE=$'\U0000F06D'            # U+F06D  nf-fa-fire
SHUI_ICON_STAR=$'\U0000F005'            # U+F005  nf-fa-star
SHUI_ICON_HEART=$'\U0000F004'           # U+F004  nf-fa-heart
SHUI_ICON_THUMBS_UP=$'\U0000F164'       # U+F164  nf-fa-thumbs-up

# ── Brackets ────────────────────────────────────────────────────────────────────
SHUI_ICON_INFO_BRACKET=$'\U0000F129'    # U+F129  nf-fa-info
SHUI_ICON_WARN_BRACKET=$'\U0000F12A'    # U+F12A  nf-fa-exclamation
SHUI_ICON_USER_BRACKET=$'\U0000F007'    # U+F007  nf-fa-user
SHUI_ICON_INPUT_BRACKET=$'\U0000F11C'   # U+F11C  nf-fa-keyboard-o

# ── General ─────────────────────────────────────────────────────────────────────
SHUI_ICON_STARTER=$'\U0000F04B'         # U+F04B  nf-fa-play
SHUI_ICON_PROMPT=$'\U0000F120'          # U+F120  nf-fa-terminal
SHUI_ICON_PALETTE=$'\U0000F1FC'         # U+F1FC  nf-fa-paint-brush
SHUI_ICON_GLOBE=$'\U0000F0AC'           # U+F0AC  nf-fa-globe
SHUI_ICON_TABLE=$'\U0000F0CE'           # U+F0CE  nf-fa-table
SHUI_ICON_FORWARD=$'\U0000F04E'         # U+F04E  nf-fa-forward
SHUI_ICON_CHART=$'\U0000F080'           # U+F080  nf-fa-bar-chart
SHUI_ICON_BUG=$'\U0000F188'             # U+F188  nf-fa-bug
SHUI_ICON_LOADING=$'\U0000F110'         # U+F110  nf-fa-spinner

# ── Tech ────────────────────────────────────────────────────────────────────────
SHUI_ICON_ROBOT=$'\U0000E28C'           # U+E28C  nf-mdi-robot
SHUI_ICON_APPLE=$'\U0000F179'           # U+F179  nf-fa-apple
SHUI_ICON_GIT=$'\U0000F1D3'             # U+F1D3  nf-fa-git
SHUI_ICON_FOLDER=$'\U0000F07B'          # U+F07B  nf-fa-folder
SHUI_ICON_FILE=$'\U0000F15B'            # U+F15B  nf-fa-file
SHUI_ICON_LINK=$'\U0000F0C1'            # U+F0C1  nf-fa-link
SHUI_ICON_CLOUD=$'\U0000F0C2'           # U+F0C2  nf-fa-cloud
SHUI_ICON_BREW=$'\UF0FC'      # U+F0FC  nf-fa-beer
SHUI_ICON_NODE=$'\U0000E718'            # U+E718  nf-dev-nodejs_small
SHUI_ICON_PYTHON=$'\U0000E235'          # U+E235  nf-seti-python
SHUI_ICON_RUBY=$'\U0000E791'            # U+E791  nf-dev-ruby
SHUI_ICON_RUST=$'\U000F1617'            # U+F1617  nf-md-language_rust
SHUI_ICON_GEM=$'\U0000F219'             # U+F219  nf-fa-diamond
SHUI_ICON_GO=$'\U0000E627'              # U+E627  nf-dev-go
SHUI_ICON_JAVA=$'\U0000E256'            # U+E256  nf-dev-java
SHUI_ICON_PHP=$'\U0000E608'             # U+E608  nf-dev-php
SHUI_ICON_SWIFT=$'\U0000E755'           # U+E755  nf-dev-swift
SHUI_ICON_KOTLIN=$'\U0000E634'          # U+E634  nf-dev-kotlin
SHUI_ICON_LUA=$'\U0000E620'             # U+E620  nf-dev-lua
SHUI_ICON_SCALA=$'\U0000E737'           # U+E737  nf-dev-scala
SHUI_ICON_ZIG=$'\U0000E6A9'             # U+E6A9  nf-seti-zig
SHUI_ICON_DART=$'\U0000E798'            # U+E798  nf-dev-dart
SHUI_ICON_ELIXIR=$'\U0000E62D'          # U+E62D  nf-dev-elixir
SHUI_ICON_ELM=$'\U0000E62C'             # U+E62C  nf-dev-elm
SHUI_ICON_HASKELL=$'\U0000E777'         # U+E777  nf-dev-haskell
SHUI_ICON_JULIA=$'\U0000E624'           # U+E624  nf-dev-julia
SHUI_ICON_C=$'\U0000E61E'               # U+E61E  nf-dev-c
SHUI_ICON_CPP=$'\U0000E61D'             # U+E61D  nf-dev-cpp
SHUI_ICON_DOCKER=$'\U0000F308'          # U+F308  nf-dev-docker
SHUI_ICON_AWS=$'\U0000E33D'             # U+E33D  nf-dev-aws
SHUI_ICON_BUN=$'\U0000E76F'             # U+E76F  nf-seti-bun
SHUI_ICON_NPM=$'\U0000E71E'             # U+E71E  nf-dev-npm

# ── Powerline ───────────────────────────────────────────────────────────────────
SHUI_ICON_PL_ARROW_RIGHT=$'\U0000E0B0'  # U+E0B0  nf-pl-right_hard_divider
SHUI_ICON_PL_ARROW_LEFT=$'\U0000E0B2'   # U+E0B2  nf-pl-left_hard_divider
SHUI_ICON_PL_CAP_RIGHT=$'\U0000E0B4'    # U+E0B4  nf-pl-right_soft_divider
SHUI_ICON_PL_CAP_LEFT=$'\U0000E0B6'     # U+E0B6  nf-pl-left_soft_divider


# ── Geometric ───────────────────────────────────────────────────────────────────
# Plain Unicode geometric shapes — universal and render correctly in a Nerd Font,
# so no PUA glyph is needed for these.
SHUI_ICON_BULLET=$'\U00002022'         # U+2022  bullet
SHUI_ICON_CIRCLE=$'\U000025CF'         # U+25CF  black circle
SHUI_ICON_CIRCLE_EMPTY=$'\U000025CB'   # U+25CB  white circle
SHUI_ICON_SQUARE=$'\U000025A0'         # U+25A0  black square
SHUI_ICON_SQUARE_EMPTY=$'\U000025A1'   # U+25A1  white square
SHUI_ICON_TRIANGLE=$'\U000025B2'       # U+25B2  black up-pointing triangle
SHUI_ICON_DIAMOND=$'\U000025C6'        # U+25C6  black diamond

# ── Selection ───────────────────────────────────────────────────────────────────
SHUI_ICON_POINTER=$'\U0000276F'        # U+276F  heavy right-pointing angle quotation mark
