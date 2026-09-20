# C64 — an Omarchy theme

A Commodore 64 palette for [Omarchy](https://omarchy.org), built from the
canonical C64 hardware colors (blue screen, light-blue text/accent, the full
16-color set), with a light-blue-to-white gradient active window border.

## Install

```sh
omarchy theme install https://github.com/ossisoft-dk/omarchy-c64-theme
```

(`omarchy theme install` derives the local slug from the repo name by
stripping a leading `omarchy-` and trailing `-theme` — `omarchy-c64-theme`
becomes `c64`, so `omarchy theme set c64` is what activates it either way,
whether installed from this repo or built locally.)

That alone gives you a complete, working theme: colors, icons, two
wallpapers, a Neovim colorscheme pointer, and a VS Code theme pointer. The
default wallpaper (`backgrounds/1-not-ready.png`) is a static C64 BASIC boot
screen pointing back at this repo.

`omarchy theme install` clones from a stranger's repo, so on principle it
never lets an installed theme carry anything that executes code — no Lua, no
terminal configs, no `vscode.json`. Those get dropped automatically (you'll
see it noted on stderr). If you want them anyway:

- `neovim.lua` — wires up [tssm/c64-vim-color-scheme](https://github.com/tssm/c64-vim-color-scheme)
- `vscode.json` — points at the "Pepto PAL" theme from the
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

to turn on two extras, both opt-in on purpose — see the note above about why
installed themes can't wire up hooks automatically:

- **Live-stats wallpaper** (`hooks/set-stats-bg.sh`, plus the renderer in
  `hooks/generate-wallpaper.sh`): the boot screen shows *this machine's* real
  RAM, CPU, GPU, hostname, and kernel instead of a link back to this repo.
  Regenerates whenever you switch to this theme or boot into it. Written to
  `backgrounds/1-ready.png` — a *different* file from the static
  `1-not-ready.png` above, and one this repo's `.gitignore` deliberately
  excludes, so your personal stats snapshot never shows up in `git status`
  or gets committed as the shipped default. Requires ImageMagick
  (`sudo pacman -S imagemagick` if you don't have it).

- **Theme-scoped font** (`hooks/set-font.sh`): fonts are a global Omarchy
  setting, not theme-scoped, so switching themes normally never touches
  yours ([omacom/omarchy#10853](https://github.com/omacom/omarchy/issues/10853)).
  This hook switches your monospace font to Bescii Mono while C64 is active,
  and restores whatever you had the moment you switch to a different theme
  (stashed in `~/.local/state/omarchy-64/previous-font` in between).

Run `uninstall.sh` to remove both hooks, restore your previous font right
now (not just on your next theme switch), and drop the generated wallpaper
back to the static default. It leaves the theme itself — colors, icons, the
static wallpaper — untouched.

## Fonts

The boot-screen text is rendered with
[BESCII](https://codeberg.org/Dmian/font-bescii) (bundled in `fonts/`,
CC0 1.0 Universal), a PETSCII-inspired monospace font. It's bundled directly
so wallpaper generation doesn't depend on it being installed system-wide.

To use it as your desktop's actual monospace font without the auto
switch/restore behavior, set it directly instead of running `install.sh`:

```sh
omarchy font set "Bescii Mono"
```

## License

MIT — see [LICENSE](LICENSE). The bundled font is CC0 — see
[fonts/LICENSE.txt](fonts/LICENSE.txt).
