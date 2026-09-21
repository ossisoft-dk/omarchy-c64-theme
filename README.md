# C64 - an Omarchy theme

A Commodore 64 palette for [Omarchy](https://omarchy.org), built from the
canonical C64 hardware colors (blue screen, light-blue text/accent, the full
16-color set), with a light-blue-to-white gradient active window border.

## Install

```sh
omarchy theme install https://github.com/ossisoft-dk/omarchy-c64-theme
```

(`omarchy theme install` derives the local slug from the repo name by
stripping a leading `omarchy-` and trailing `-theme`, so `omarchy-c64-theme`
becomes `c64` and `omarchy theme set c64` is what activates it either way,
whether installed from this repo or built locally.)

That alone gives you a complete, working theme: colors, icons, a handful of
wallpapers, a Neovim colorscheme pointer, and a VS Code theme pointer. The
default wallpaper (`backgrounds/1-not-ready.png`) is a static C64 BASIC boot
screen pointing back at this repo. Cycle through the others with
`omarchy theme bg next` or the background picker:

- `2-crt-glow.png`: a soft radial CRT-glow gradient with faint scanlines
- `3-10print-maze.png`: the classic `10 PRINT CHR$(205.5+RND(1));:GOTO 10`
  one-liner, rendered as the actual generated maze pattern
- `4-breadbin.png`: a C64 "breadbin" case, badge stripe and all, with the
  Omarchy wordmark where COMMODORE 64 branding normally sits
- `5-synthwave.png`: a retrowave sunset/grid scene, built entirely from
  this theme's own palette

`omarchy theme install` clones from a stranger's repo, so on principle it
never lets an installed theme carry anything that executes code: no Lua, no
terminal configs, no `vscode.json`. Those get dropped automatically (you'll
see it noted on stderr). If you want them anyway:

- `neovim.lua`: wires up [tssm/c64-vim-color-scheme](https://github.com/tssm/c64-vim-color-scheme)
- `vscode.json`: points at the "Pepto PAL" theme from the
  [Chibantichic.mystico-c64](https://marketplace.visualstudio.com/items?itemName=Chibantichic.mystico-c64)
  extension

Copy whichever of those you trust into
`~/.config/omarchy/themes/c64/` by hand after installing.

## Optional: go live

By default the boot-screen wallpaper is static and your font is untouched.
Run, once:

```sh
~/.config/omarchy/themes/c64/install.sh
```

to turn on two extras, both opt-in on purpose (see the note above about why
installed themes can't wire up hooks automatically):

- **Live-stats wallpaper** (`hooks/set-stats-bg.sh`, plus the renderer in
  `hooks/generate-wallpaper.sh`): the boot screen shows *this machine's* real
  RAM, CPU, GPU, hostname, and kernel instead of a link back to this repo.
  Regenerates whenever you switch to this theme or boot into it. Written to
  `backgrounds/1-ready.png`, a *different* file from the static
  `1-not-ready.png` above; this repo's `.gitignore` deliberately excludes it,
  so your personal stats snapshot never shows up in `git status` or gets
  committed as the shipped default. Requires ImageMagick
  (`sudo pacman -S imagemagick` if you don't have it).

- **Theme-scoped font** (`hooks/set-font.sh`): fonts are a global Omarchy
  setting, not theme-scoped, so switching themes normally never touches
  yours ([omacom/omarchy#10853](https://github.com/omacom/omarchy/issues/10853)).
  This hook installs and switches your monospace font to **Bescii Mono
  Condensed** (see [Fonts](#fonts) below for why it's the condensed variant,
  not plain Bescii Mono) while C64 is active, and restores whatever you had
  the moment you switch to a different theme (stashed in
  `~/.local/state/omarchy-64/previous-font` in between).

Run `uninstall.sh` to remove both hooks, restore your previous font right
now (not just on your next theme switch), and drop the generated wallpaper
back to the static default. It leaves the theme itself (colors, icons, the
static wallpaper) untouched.

## Fonts

The boot-screen text is rendered with
[BESCII](https://codeberg.org/Dmian/font-bescii) (`fonts/Bescii-Mono.ttf`,
CC0 1.0 Universal), a PETSCII-inspired monospace font. It's bundled directly
so wallpaper generation doesn't depend on it being installed system-wide.

`fonts/Bescii-Mono-Condensed.ttf` is a horizontally-squeezed derivative of
that same font (same CC0 lineage), generated with
[fontTools](https://github.com/fonttools/fonttools) at a 0.606× horizontal
scale to match JetBrainsMono's glyph width. It exists because Bescii Mono's
glyphs render ~65% wider than JetBrainsMono's at the same point size, and
some stock Omarchy shell panels (e.g. the network panel's stat grid) lay
text out in fixed-width columns sized against JetBrainsMono, so with plain
Bescii Mono as the system font, that difference is enough for label and
value text to overflow into neighboring columns. The condensed variant is
what `install.sh`/`set-font.sh` actually installs and switches to as the
system font; the wallpaper still renders with full-width Bescii Mono
directly, since we control its layout ourselves and width isn't a
constraint there.

To use either as your desktop's actual monospace font without the auto
switch/restore behavior, set it directly instead of running `install.sh`
(you'll need to install the font file yourself first; see `set-font.sh`
for how):

```sh
omarchy font set "Bescii Mono Condensed"   # recommended for system-wide use
omarchy font set "Bescii Mono"             # full-width original
```

## License

MIT, see [LICENSE](LICENSE). The bundled font is CC0, see
[fonts/LICENSE.txt](fonts/LICENSE.txt).
