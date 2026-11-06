#!/bin/sh
# Adds the "answer from the Lighthouse screen" hooks to ~/.claude/settings.json (run with "uninstall" to remove them).
#   PermissionRequest            → lighthouse-ask.sh permission   (Allow / Always allow / Deny on the screen)
#   PreToolUse: AskUserQuestion  → lighthouse-ask.sh question     (pick an option or type an answer)
#   Stop (asyncRewake)           → lighthouse-ask.sh reply        (type a reply that wakes the session)
# A backup of the settings file is written next to it first. Restart Claude Code sessions to pick it up.
set -e
SETTINGS="$HOME/.claude/settings.json"
ASK="$(cd "$(dirname "$0")" && pwd)/lighthouse-ask.sh"
[ -f "$SETTINGS" ] || echo '{}' > "$SETTINGS"
cp "$SETTINGS" "$SETTINGS.bak-$(date +%Y%m%d%H%M%S)"

# Drop any earlier copies of these hooks first, so running this twice is harmless.
strip='
  def drop: map(.hooks |= map(select((.command // "") | contains("lighthouse-ask.sh") | not))) | map(select(.hooks | length > 0));
  .hooks //= {}
  | .hooks.Stop = ((.hooks.Stop // []) | drop)
  | .hooks.PermissionRequest = ((.hooks.PermissionRequest // []) | drop)
  | .hooks.PreToolUse = ((.hooks.PreToolUse // []) | drop)
  | .hooks |= with_entries(select(.value | length > 0))'

if [ "$1" = "uninstall" ]; then
  /usr/bin/jq "$strip" "$SETTINGS" > "$SETTINGS.tmp" && mv "$SETTINGS.tmp" "$SETTINGS"
  echo "Removed the Lighthouse answer hooks."; exit 0
fi

/usr/bin/jq --arg ask "$ASK" "$strip"'
  | .hooks.Stop += [{hooks: [{type: "command", command: ($ask + " reply"), timeout: 28800, asyncRewake: true}]}]
  | .hooks.PermissionRequest = ((.hooks.PermissionRequest // []) + [{hooks: [{type: "command", command: ($ask + " permission"), timeout: 1800}]}])
  | .hooks.PreToolUse = ((.hooks.PreToolUse // []) + [{matcher: "AskUserQuestion", hooks: [{type: "command", command: ($ask + " question"), timeout: 1800}]}])
' "$SETTINGS" > "$SETTINGS.tmp" && mv "$SETTINGS.tmp" "$SETTINGS"
echo "Lighthouse answer hooks installed. Restart Claude Code sessions to pick them up."
