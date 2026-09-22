#!/usr/bin/env bash
# Add/remove yabai signals that point at a dev obi instance (default port 7778),
# without touching simple-bar-conf.sh. Usage: dev-signals.sh add|remove [port]
set -euo pipefail
YABAI="${YABAI:-/opt/homebrew/bin/yabai}"
PORT="${2:-7778}"
cmd="${1:-}"

declare -A EVENTS=(
  [window_created]=windows [window_minimized]=windows [window_deminimized]=windows
  [window_focused]=windows [window_resized]=windows [window_destroyed]=windows
  [window_title_changed]=windows [application_activated]=windows
  [space_changed]=spaces [space_destroyed]=spaces [space_created]=spaces
  [display_changed]=spaces [display_added]=displays [display_removed]=displays [display_moved]=displays
)

case "$cmd" in
  add)
    for ev in "${!EVENTS[@]}"; do
      kind="${EVENTS[$ev]}"
      "$YABAI" -m signal --add label="obi-$ev" event="$ev" \
        action="curl -s localhost:$PORT/yabai/$kind/refresh >/dev/null; curl -s localhost:$PORT/yabai/windows/refresh >/dev/null"
    done
    echo "added ${#EVENTS[@]} signals → :$PORT"
    ;;
  remove)
    for ev in "${!EVENTS[@]}"; do "$YABAI" -m signal --remove "obi-$ev" 2>/dev/null || true; done
    echo "removed"
    ;;
  *) echo "usage: $0 add|remove [port]"; exit 2 ;;
esac
