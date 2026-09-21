#!/bin/bash
# Trigger stub. `omarchy hook install` copies this file itself into
# ~/.config/omarchy/hooks/<type>.d/, so it can't rely on a relative path back
# to the rest of this repo, so THEME_SLUG below has to match wherever the c64
# theme actually lives (edit it if you renamed the theme's folder).
#
# Installed twice, into two different hook types with two different calling
# conventions:
#   theme-set.d/  -> called as `hook "$theme_slug_just_applied"`
#   post-boot.d/  -> called with no arguments at all
THEME_SLUG="c64"
THEME_DIR="$HOME/.config/omarchy/themes/$THEME_SLUG"

if [[ -n ${1:-} ]]; then
  [[ $1 == "$THEME_SLUG" ]] || exit 0
  swap_mode="force"
else
  [[ "$(cat "$HOME/.local/state/omarchy/current/theme.name" 2>/dev/null)" == "$THEME_SLUG" ]] || exit 0
  swap_mode=""
fi

[[ -f $THEME_DIR/hooks/generate-wallpaper.sh ]] && exec bash "$THEME_DIR/hooks/generate-wallpaper.sh" "$swap_mode"
