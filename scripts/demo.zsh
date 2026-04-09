#!/usr/bin/env zsh
#
# shui demo — run with: zsh demo.zsh
# Add --interactive to test confirm, select, and input
#

source "${0:A:h}/shui.zsh"

shui section "shui · 水  —  component demo"

# ── Text ─────────────────────────────────────────────────────────────────────

shui subtitle "Text"

shui bold      "Bold text"
shui dim       "Dimmed text"
shui italic    "Italic text"
shui underline "Underlined text"
shui spacer
shui text --color=primary "Primary colour"
shui text --color=success "Success colour"
shui text --color=warning "Warning colour"
shui text --color=error   "Error colour"
shui text --color=info    "Info colour"
shui text --color=muted   "Muted colour"
shui text --color=accent  "Accent colour"

# ── Messages ──────────────────────────────────────────────────────────────────

shui subtitle "Messages"

shui success "Operation completed successfully"
shui error   "Something went wrong — check the logs"
shui warning "This action cannot be undone"
shui info    "Running in dry-run mode, no changes made"

# ── Layout ────────────────────────────────────────────────────────────────────

shui subtitle "Layout"

shui section    "This is a section"
shui subtitle   "This is a subtitle"
shui subsection "This is a subsection item"
shui spacer
shui divider
shui spacer

# ── Badges ────────────────────────────────────────────────────────────────────

shui subtitle "Inline — Badges"

echo "$(shui badge success SUCCESS)  $(shui badge error ERROR)  $(shui badge warning WARNING)  $(shui badge info INFO)  $(shui badge primary PRIMARY)  $(shui badge muted MUTED)"

# ── Pills ─────────────────────────────────────────────────────────────────────

shui subtitle "Inline — Pills"

echo "$(shui pill success success)  $(shui pill error error)  $(shui pill warning warning)  $(shui pill info info)  $(shui pill primary primary)  $(shui pill muted muted)"

# ── Box ───────────────────────────────────────────────────────────────────────

shui subtitle "Box"

shui box "Simple content inside a box"
shui spacer
shui box --title="Deployment Summary" "$(shui badge success 3 installed)\n$(shui badge warning 1 skipped)\n$(shui badge muted 0 errors)"

# ── Table ─────────────────────────────────────────────────────────────────────

shui subtitle "Table"

shui table \
  "Package|Version|Status" \
  "node|20.11.0|$(shui badge success OK)" \
  "bun|1.1.3|$(shui badge success OK)" \
  "python|3.12.0|$(shui badge warning outdated)" \
  "ruby|2.7.0|$(shui badge error EOL)"

# ── Progress ──────────────────────────────────────────────────────────────────

shui subtitle "Progress"

shui progress 0   100; echo
shui progress 25  100; echo
shui progress 50  100; echo
shui progress 75  100; echo
shui progress 100 100; echo
shui spacer
shui progress 65 100 --width=20 --label="Downloading "; echo

# ── Interactive ───────────────────────────────────────────────────────────────

shui subtitle "Interactive"

if [[ "${1}" == "--interactive" ]]; then
  shui spacer

  if shui confirm "Do you want to continue?"; then
    shui success "Confirmed!"
  else
    shui error "Cancelled"
  fi

  shui spacer

  local choice
  choice=$(shui select "Pick a theme:" default minimal plain)
  shui info "You selected: ${choice}"

  shui spacer

  local name
  name=$(shui input --default="world" "Enter your name:")
  shui success "Hello, ${name}!"
else
  shui info "Run with --interactive to test confirm, select, and input"
fi

shui spacer
shui success "Demo complete!"
