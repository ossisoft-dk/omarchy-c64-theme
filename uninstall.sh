#!/bin/bash
# Reverts everything install.sh did:
#   - removes both installed hooks
#   - restores your previous font right now, if set-font.sh had changed it
#     (waiting for your next theme switch wouldn't work — the hook doing
#     that restore is gone the moment this script removes it)
#   - deletes the generated live wallpaper, so the theme falls back to its
#     static default instead of leaving a stale stats snapshot in place
#
# The theme itself (colors, icons, the static wallpaper) is untouched —
# this only undoes what install.sh set up.
set -uo pipefail

THEME_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STATE_DIR="$HOME/.local/state/omarchy-64"
PREV_FONT_FILE="$STATE_DIR/previous-font"

removed=0
for dir in theme-set post-boot; do
  hook_file="$HOME/.config/omarchy/hooks/$dir.d/set-stats-bg.sh"
  if [[ -f $hook_file ]]; then
    rm -f "$hook_file"
    echo "Removed $hook_file"
    removed=1
  fi
done

hook_file="$HOME/.config/omarchy/hooks/theme-set.d/set-font.sh"
if [[ -f $hook_file ]]; then
  rm -f "$hook_file"
  echo "Removed $hook_file"
  removed=1
fi

if [[ -f $PREV_FONT_FILE ]]; then
  prev_font=$(<"$PREV_FONT_FILE")
  rm -f "$PREV_FONT_FILE"
  if [[ -n $prev_font ]]; then
    echo "Restoring your previous font: $prev_font"
    omarchy font set "$prev_font" >/dev/null 2>&1
  fi
fi
rmdir "$STATE_DIR" 2>/dev/null || true

staged_ready="$HOME/.local/state/omarchy/current/theme/backgrounds/1-ready.png"
current_bg_link="$HOME/.local/state/omarchy/current/background"
rm -f "$THEME_DIR/backgrounds/1-ready.png" "$staged_ready"

# If the live wallpaper we just deleted was the one on screen, the symlink
# is now dangling — point it back at the theme's static default instead of
# leaving a broken background.
fallback="$HOME/.local/state/omarchy/current/theme/backgrounds/1-not-ready.png"
if [[ -L $current_bg_link ]] && [[ ! -e $current_bg_link ]] && [[ -f $fallback ]]; then
  command -v omarchy >/dev/null && omarchy theme bg set "$fallback" >/dev/null 2>&1
fi

if (( removed )); then
  echo "Uninstalled."
else
  echo "Nothing was installed."
fi
