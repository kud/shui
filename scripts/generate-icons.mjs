#!/usr/bin/env node
// Generates shui's icon sets from @kud/glyphs — the single source of truth for
// terminal glyphs. Run `npm run generate:icons` after bumping the @kud/glyphs
// dependency to pull in new or changed glyphs.
//
// The four src/icons/*.zsh files are GENERATED — never hand-edit them. To change
// an icon, edit @kud/glyphs (glyphs.json) upstream, publish, bump the dep here,
// and regenerate. shui asks @kud/glyphs to render under its own SHUI_ICON_
// prefix; the escape-safety ($'\U0000XXXX', never raw PUA) is guaranteed there.
import { renderZsh, glyphs } from "@kud/glyphs"
import { writeFileSync } from "fs"
import { fileURLToPath } from "url"
import { dirname, join } from "path"

const ICONS = join(
  dirname(fileURLToPath(import.meta.url)),
  "..",
  "src",
  "icons",
)
const PREFIX = "SHUI_ICON"

const header = (title, ...notes) =>
  [
    "#!/usr/bin/env zsh",
    "#",
    `# ${title}`,
    "# GENERATED from @kud/glyphs by scripts/generate-icons.mjs — do not edit by hand.",
    "# Change the glyph upstream in @kud/glyphs, then `npm run generate:icons`.",
    ...notes.map((n) => `# ${n}`),
    "#",
    "",
    "",
  ].join("\n")

const write = (file, title, body, ...notes) =>
  writeFileSync(join(ICONS, file), header(title, ...notes) + body + "\n")

// nerd — full set: Nerd Font PUA glyphs plus plain-Unicode geometrics.
const nerd = renderZsh({ prefix: PREFIX, variant: "nerd" })
write(
  "nerd.zsh",
  "nerd icon set — requires a Nerd Font (https://www.nerdfonts.com/)",
  nerd,
)

// emoji — full set. Glyphs with no emoji equivalent (e.g. powerline caps) emit
// an empty value so the token set stays in parity with the nerd set.
const emoji = renderZsh({ prefix: PREFIX, variant: "emoji" })
write(
  "emoji.zsh",
  "emoji icon set — Unicode emoji, no special font required",
  emoji,
)

// none — full set, all empty (text-only). Derived from the nerd set's variable
// names so parity holds by construction.
const none = nerd.replace(/=.*$/gm, "=''")
write("none.zsh", "none icon set — no icons (text-only fallback)", none)

// unicode — thin base layer sourced first: only the glyphs that carry a
// plain-Unicode fallback (the geometric shapes). Full sets override these.
const unicodeNames = Object.keys(glyphs).filter((n) => "unicode" in glyphs[n])
const unicode = renderZsh({
  prefix: PREFIX,
  variant: "unicode",
  names: unicodeNames,
})
write(
  "unicode.zsh",
  "unicode icon set — standard Unicode symbols, no special font required",
  unicode,
  "Thin base layer, always sourced first; nerd/emoji/none override per set.",
)

console.log(
  `Generated icon sets: nerd/emoji/none (${Object.keys(glyphs).length} glyphs), unicode (${unicodeNames.length} geometrics)`,
)
