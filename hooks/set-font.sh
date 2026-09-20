#!/bin/bash
# theme-set hook only (not post-boot — a font setting persists across
# reboots on its own; there's nothing to refresh at boot). Switches to the
# theme's bundled font while C64 is active, and restores whatever font was
# active before as soon as you switch to any other theme.
#
# `omarchy hook install` copies this file itself into
# ~/.config/omarchy/hooks/theme-set.d/, so it can't rely on a relative path
# back to the rest of this repo — THEME_SLUG/OUR_FONT below have to match
# this repo (edit them if you renamed the theme or its font).
THEME_SLUG="c64"
OUR_FONT="Bescii Mono"
STATE_DIR="$HOME/.local/state/omarchy-64"
PREV_FONT_FILE="$STATE_DIR/previous-font"

mkdir -p "$STATE_DIR"

if [[ ${1:-} == "$THEME_SLUG" ]]; then
  # Entering: stash whatever font was active, but only if nothing's already
  # stashed — re-selecting C64 while already on it must not overwrite a
  # real previous font with "Bescii" (fc-match's own name for our font once
  # it's already active, from the font's own multi-alias metadata).
  if [[ ! -f $PREV_FONT_FILE ]]; then
    current_font=$(omarchy font current 2>/dev/null)
    [[ -n $current_font ]] && printf '%s' "$current_font" >"$PREV_FONT_FILE"
  fi
  omarchy font set "$OUR_FONT" >/dev/null 2>&1
elif [[ -f $PREV_FONT_FILE ]]; then
  # Leaving: restore and clear the stash, so a *later* re-entry starts fresh.
  prev_font=$(<"$PREV_FONT_FILE")
  rm -f "$PREV_FONT_FILE"
  [[ -n $prev_font ]] && omarchy font set "$prev_font" >/dev/null 2>&1
fi
