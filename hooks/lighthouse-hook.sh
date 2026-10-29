#!/bin/sh
# Claude Code hook → Lighthouse. Appends one compact JSON line per event to ~/.lighthouse/events.ndjson.
# The Lighthouse app watches that file and turns it into agent shapes on the Wokyis screen.
# Other agents (e.g. Grok Bot) can append the same shape with "src":"grok".
mkdir -p "$HOME/.lighthouse"
/usr/bin/jq -c '{
  t: now,
  src: "claude",
  ev: .hook_event_name,
  sid: .session_id,
  cwd: .cwd,
  n: (.notification_type // null),
  msg: ((.message // null) | if . then .[0:160] else . end),
  prompt: ((.prompt // null) | if . then .[0:140] else . end),
  last: ((.last_assistant_message // null) | if type == "string" then .[0:200] else null end),
  tool: (.tool_name // null)
} | with_entries(select(.value != null))' >> "$HOME/.lighthouse/events.ndjson"
