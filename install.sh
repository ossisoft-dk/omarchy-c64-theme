#!/bin/bash
# Opt-in: wires up the C64 theme's two live extras.
#   - hooks/set-stats-bg.sh  -> live wallpaper with this machine's stats
#   - hooks/set-font.sh      -> switch to the theme's font while C64 is
#                               active, restore your previous font the
#                               moment you switch away
#
# `omarchy theme install` only ever copies theme assets (colors, icons,
# backgrounds...) — it deliberately never installs hooks on your behalf (a
# theme pulled from a stranger's git repo can't be allowed to run arbitrary
# code just by being installed). So both extras stay a separate, explicit
# step: run this script once after installing the theme.
#
# Safe to re-run any time (e.g. after `omarchy update` recreates the hook
# directories). To remove everything again, including restoring your
# previous font right now rather than on your next theme switch, run
# uninstall.sh instead.
set -euo pipefail

THEME_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if ! command -v omarchy >/dev/null; then
  echo "install.sh: 'omarchy' command not found — is this an Omarchy system?" >&2
  exit 1
fi

omarchy hook install theme-set "$THEME_DIR/hooks/set-stats-bg.sh"
omarchy hook install post-boot "$THEME_DIR/hooks/set-stats-bg.sh"
omarchy hook install theme-set "$THEME_DIR/hooks/set-font.sh"

echo "Generating an initial live wallpaper..."
bash "$THEME_DIR/hooks/generate-wallpaper.sh" force

if [[ "$(cat "$HOME/.local/state/omarchy/current/theme.name" 2>/dev/null)" == "c64" ]]; then
  echo "Switching to the theme's font..."
  bash "$THEME_DIR/hooks/set-font.sh" c64
fi

cat <<'EOF'
Done. From now on:
  - the wallpaper regenerates with live stats whenever you switch to the
    C64 theme, or boot into it while it's already active
  - your monospace font switches to Bescii Mono while C64 is active, and
    back to whatever you had as soon as you switch to a different theme

Run uninstall.sh to remove both and restore your previous font.
EOF
