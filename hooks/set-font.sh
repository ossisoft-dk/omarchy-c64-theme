#!/bin/bash
# theme-set hook only (not post-boot: a font setting persists across
# reboots on its own; there's nothing to refresh at boot). Switches to the
# theme's bundled font while C64 is active, and restores whatever font was
# active before as soon as you switch to any other theme.
#
# `omarchy hook install` copies this file itself into
# ~/.config/omarchy/hooks/theme-set.d/, so it can't rely on a relative path
# back to the rest of this repo, so THEME_SLUG/OUR_FONT/FONT_FILE below have
# to match this repo (edit them if you renamed the theme or its font).
THEME_SLUG="c64"
THEME_DIR="$HOME/.config/omarchy/themes/$THEME_SLUG"
OUR_FONT="Bescii Mono Condensed"
FONT_FILE="Bescii-Mono-Condensed.ttf"
STATE_DIR="$HOME/.local/state/omarchy-64"
PREV_FONT_FILE="$STATE_DIR/previous-font"
USER_FONTS_DIR="$HOME/.local/share/fonts/omarchy-c64"

mkdir -p "$STATE_DIR"

# Bescii Mono itself is too wide for some stock shell panels' fixed-width
# layouts (columns sized against JetBrainsMono; Bescii's glyphs run ~65%
# wider, so text overflows into neighboring columns). This is a
# horizontally-condensed derivative (same glyphs, same CC0 lineage,
# rescaled with fontTools to match JetBrainsMono's width) used here
# instead. The wallpaper still uses full-width Bescii Mono directly, since
# we control its layout ourselves and width isn't a constraint there.
ensure_font_installed() {
  local src="$THEME_DIR/fonts/$FONT_FILE"
  local dest="$USER_FONTS_DIR/$FONT_FILE"
  [[ -f $src ]] || return 1
  if [[ ! -f $dest ]] || ! cmp -s "$src" "$dest"; then
    mkdir -p "$USER_FONTS_DIR"
    cp "$src" "$dest"
    chmod 644 "$dest"
    fc-cache -f "$USER_FONTS_DIR" >/dev/null 2>&1
  fi
}

if [[ ${1:-} == "$THEME_SLUG" ]]; then
  # Entering: stash whatever font was active, but only if nothing's already
  # stashed, since re-selecting C64 while already on it must not overwrite a
  # real previous font with our own font's own fc-match alias.
  if [[ ! -f $PREV_FONT_FILE ]]; then
    current_font=$(omarchy font current 2>/dev/null)
    [[ -n $current_font ]] && printf '%s' "$current_font" >"$PREV_FONT_FILE"
  fi
  ensure_font_installed
  omarchy font set "$OUR_FONT" >/dev/null 2>&1
elif [[ -f $PREV_FONT_FILE ]]; then
  # Leaving: restore and clear the stash, so a *later* re-entry starts fresh.
  prev_font=$(<"$PREV_FONT_FILE")
  rm -f "$PREV_FONT_FILE"
  [[ -n $prev_font ]] && omarchy font set "$prev_font" >/dev/null 2>&1
fi
