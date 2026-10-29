#!/bin/sh
# Start Lighthouse automatically at login (run with "uninstall" to stop).
set -e
DEST="$HOME/Library/LaunchAgents/local.lighthouse.kiosk.plist"
if [ "$1" = "uninstall" ]; then
  launchctl bootout "gui/$(id -u)" "$DEST" 2>/dev/null || true
  rm -f "$DEST"; echo "Lighthouse will no longer start at login."; exit 0
fi
mkdir -p "$HOME/Library/LaunchAgents"
cp "$(dirname "$0")/local.lighthouse.kiosk.plist" "$DEST"
launchctl bootout "gui/$(id -u)" "$DEST" 2>/dev/null || true
launchctl bootstrap "gui/$(id -u)" "$DEST"
echo "Lighthouse will start at login."
