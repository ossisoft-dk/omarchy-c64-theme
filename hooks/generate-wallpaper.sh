#!/bin/bash
# Regenerates backgrounds/1-ready.png as a C64 BASIC boot screen showing this
# machine's live stats, then (if that background is the one currently on
# screen) hot-swaps it in immediately via `omarchy theme bg set`.
#
# Safe to run by hand any time: `bash hooks/generate-wallpaper.sh`.
set -uo pipefail

THEME_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FONT="$THEME_DIR/fonts/Bescii-Mono.ttf"
OUT="$THEME_DIR/backgrounds/1-ready.png"

MAGICK=$(command -v magick || command -v convert)
if [[ -z $MAGICK ]]; then
  echo "generate-wallpaper.sh: ImageMagick not found (install with: sudo pacman -S imagemagick)" >&2
  exit 1
fi

if [[ ! -f $FONT ]]; then
  echo "generate-wallpaper.sh: missing bundled font $FONT" >&2
  exit 1
fi

# Truncate a stat to a safe on-screen width so no field can push the frame's
# right edge, whatever hardware this runs on.
clip() {
  local s=$1 max=${2:-58}
  if (( ${#s} > max )); then
    s="${s:0:$((max - 3))}..."
  fi
  printf '%s' "$s"
}

ram_kb=$(awk '/MemTotal/{print $2}' /proc/meminfo)
avail_kb=$(awk '/MemAvailable/{print $2}' /proc/meminfo)
cores=$(nproc)
kernel=$(uname -r | tr '[:lower:]' '[:upper:]')
omarchy_ver=$(omarchy version 2>/dev/null || echo "?")
hostn=$(hostnamectl --static 2>/dev/null | tr '[:lower:]' '[:upper:]')

cpu=$(lscpu 2>/dev/null | awk -F': +' '/^Model name/{print $2; exit}' \
  | sed -E 's/\(R\)|\(TM\)|CPU //g' | xargs | tr '[:lower:]' '[:upper:]')
[[ -z $cpu ]] && cpu="UNKNOWN CPU"

# Every display/3D-capable PCI device, not just the first — a laptop with
# hybrid graphics (integrated + discrete) has two, and both should show up.
gpu_names=()
if command -v lspci >/dev/null; then
  while IFS= read -r line; do
    [[ -n $line ]] && gpu_names+=("$line")
  done < <(
    lspci 2>/dev/null \
      | grep -iE 'VGA compatible controller|3D controller|Display controller' \
      | sed -E 's/^[0-9a-f:.]+ [^:]+: //; s/ \(rev.*\)//; s/^[A-Za-z0-9.,& ]+Corporation //' \
      | tr '[:lower:]' '[:upper:]'
  )
fi
(( ${#gpu_names[@]} == 0 )) && gpu_names=("UNKNOWN GPU")

cpu=$(clip "$cpu" 50)
hostn=$(clip "$hostn" 58)

printf -v l_cpu  "%-4s %s X%s" "CPU" "$cpu" "$cores"
printf -v l_host "%-4s %s" "HOST" "$hostn"
printf -v l_os   "%-4s OMARCHY %s  LINUX %s" "OS" "$omarchy_ver" "$kernel"

gpu_block=""
if (( ${#gpu_names[@]} == 1 )); then
  printf -v gpu_block ' %-4s %s' "GPU" "$(clip "${gpu_names[0]}" 58)"
else
  for i in "${!gpu_names[@]}"; do
    printf -v gpu_line ' %-4s %s' "GPU$((i + 1))" "$(clip "${gpu_names[$i]}" 57)"
    gpu_block+="${gpu_block:+$'\n'}$gpu_line"
  done
fi

text=$'    **** OMARCHY 64 ****\n\n '"${ram_kb}"$'K RAM SYSTEM\n '"${avail_kb}"$' BYTES FREE\n\n '"${l_cpu}"$'\n'"${gpu_block}"$'\n '"${l_host}"$'\n '"${l_os}"$'\n\nREADY.\n\xe2\x96\x88'

tmp=$(mktemp --suffix=.png)
trap 'rm -f "$tmp"' EXIT

"$MAGICK" -size 3840x2160 xc:"#7869C4" \
  -fill "#40318D" -draw "rectangle 100,100 3739,2059" \
  -font "$FONT" -pointsize 50 -fill "#7869C4" \
  -gravity NorthWest -annotate +260+260 "$text" \
  "$tmp" || { echo "generate-wallpaper.sh: render failed" >&2; exit 1; }

mkdir -p "$(dirname "$OUT")"
chmod 644 "$tmp"
mv "$tmp" "$OUT"
trap - EXIT

# `omarchy theme set` stages a *copy* of backgrounds/ under
# ~/.local/state/omarchy/current/theme/ — that staged copy, not this repo
# path, is what's actually symlinked as the live background and what
# `omarchy theme bg next` scans. Keep it in sync so cycling and a live
# refresh both see the update.
theme_slug=$(basename "$THEME_DIR")
staged_name_file="$HOME/.local/state/omarchy/current/theme.name"
staged_bg="$HOME/.local/state/omarchy/current/theme/backgrounds/$(basename "$OUT")"

if [[ -f $staged_name_file ]] && [[ "$(<"$staged_name_file")" == "$theme_slug" ]] && [[ -d $(dirname "$staged_bg") ]]; then
  cp "$OUT" "$staged_bg"

  # omarchy-menu-images (the background picker) short-circuits its whole
  # thumbnail rebuild on a *directory* mtime check — an in-place `cp` changes
  # the file's mtime but not the directory's, so the picker would otherwise
  # keep serving a stale cached thumbnail forever. Bump it explicitly.
  touch "$(dirname "$staged_bg")"

  # Hot-swap the on-screen wallpaper if either:
  #   - this file is the one already shown, or
  #   - we were just invoked as a theme-set hook ($1 = force). Right after a
  #     switch there's no deliberate choice to protect: omarchy-theme-set
  #     picks a background *before* this hook ever runs, and at that moment
  #     1-ready.png may not exist yet (e.g. first activation, or it was
  #     deleted), so it can fall back to some other file in the theme by
  #     pure alphabetical luck. That's not a choice the user made — force
  #     past it so switching to this theme reliably lands on its live
  #     wallpaper. A background cycled to *after* the switch (post-boot,
  #     or just idle desktop use) still isn't touched.
  current_bg_link="$HOME/.local/state/omarchy/current/background"
  already_showing=false
  [[ -L $current_bg_link ]] && [[ "$(readlink -f "$current_bg_link")" == "$(readlink -f "$staged_bg")" ]] && already_showing=true

  if [[ $already_showing == true || ${1:-} == force ]]; then
    # Plain `omarchy theme bg set` is a no-op here: Background.qml skips
    # re-rendering whenever the new path string equals the already-loaded one
    # (a sound optimization for ordinary cycling between distinct files — it
    # just doesn't know *this* path's content changed underneath it). The
    # only thing that bypasses that guard is the `force` flag a real theme
    # switch sets via the themeTransition IPC call, so use that directly
    # instead, re-sending the theme's own current colors/shell payloads
    # (unchanged) alongside it, same as omarchy-theme-set does.
    ln -nsf "$staged_bg" "$current_bg_link"
    if command -v omarchy-shell >/dev/null; then
      colors_file="$(dirname "$staged_bg")/../colors.toml"
      shell_file="$(dirname "$staged_bg")/../shell.toml"
      colors_b64=$([[ -f $colors_file ]] && base64 -w 0 "$colors_file")
      shell_b64=$([[ -f $shell_file ]] && base64 -w 0 "$shell_file")
      timeout 2 omarchy-shell -q background themeTransition "" "$staged_bg" "$staged_bg" "$colors_b64" "$shell_b64" >/dev/null 2>&1
    fi
  fi

  # Pre-warm the picker's thumbnail cache now rather than leaving the first
  # open to generate it lazily.
  command -v omarchy-theme-bg-cache >/dev/null && omarchy-theme-bg-cache >/dev/null 2>&1
fi
