#!/bin/sh
# Claude Code hook → lets you answer an agent from the Lighthouse screen.
#
#   lighthouse-ask.sh permission   (PermissionRequest)          Allow / Always allow / Deny on the screen
#   lighthouse-ask.sh question     (PreToolUse: AskUserQuestion) pick an option or type an answer
#   lighthouse-ask.sh reply        (Stop, asyncRewake)           type a reply that wakes the session
#
# The hook writes ~/.lighthouse/asks/<session>.json, the Lighthouse app shows it, and your answer comes back
# as ~/.lighthouse/answers/<ask id>.json. Permission prompts and questions only wait for the screen while the
# app says so in ~/.lighthouse/mode.json (big monitor switched away, or "always" chosen in its menu);
# otherwise they exit at once and Claude Code shows its normal prompt. If nobody answers in time, the normal
# prompt appears anyway.

kind="$1"
LH="$HOME/.lighthouse"
JQ=/usr/bin/jq
mkdir -p "$LH/asks" "$LH/answers"
input=$(cat)
sid=$(printf '%s' "$input" | $JQ -r '.session_id // empty')
[ -n "$sid" ] || exit 0
askf="$LH/asks/$sid.json"
id="$sid-$(date +%s)-$$"
now=$(date +%s)

screen_first() { [ "$($JQ -r '.screenFirst // false' "$LH/mode.json" 2>/dev/null)" = "true" ]; }

# Write the ask atomically so the app never reads half a file.
put_ask() {
  tmp="$askf.$$"
  printf '%s' "$1" > "$tmp" && mv "$tmp" "$askf"
}

# Wait for an answer file. Stops early if the ask was replaced or cleared (you answered elsewhere,
# typed a new prompt, or the session ended). Prints the answer JSON on success.
wait_answer() {
  limit=$1; waited=0
  while [ "$waited" -lt "$limit" ]; do
    ans="$LH/answers/$id.json"
    if [ -f "$ans" ]; then cat "$ans"; rm -f "$ans"; return 0; fi
    [ "$($JQ -r '.id // empty' "$askf" 2>/dev/null)" = "$id" ] || return 1
    sleep 1; waited=$((waited + 1))
  done
  return 1
}

clear_ask() { [ "$($JQ -r '.id // empty' "$askf" 2>/dev/null)" = "$id" ] && rm -f "$askf"; }

case "$kind" in
permission)
  screen_first || exit 0
  put_ask "$(printf '%s' "$input" | $JQ -c --arg id "$id" --argjson t "$now" '{
    id: $id, sid: .session_id, kind: "permission", t: $t, tool: .tool_name,
    summary: ((.tool_input.description // .tool_input.command // .tool_input.file_path // .tool_input.url // .tool_input.pattern // "") | tostring | .[0:240]),
    detail: ((.tool_input.command // .tool_input.file_path // .tool_input.url // "") | tostring | .[0:400]),
    canAlways: ((.permission_suggestions // []) | length > 0)
  }')"
  ans=$(wait_answer 1800) || { clear_ask; exit 0; }
  clear_ask
  printf '%s' "$input" | $JQ -c --argjson a "$ans" '
    if $a.behavior == "allow" then
      {hookSpecificOutput: {hookEventName: "PermissionRequest", decision: (
        {behavior: "allow"} + (if $a.always and ((.permission_suggestions // []) | length > 0)
                               then {updatedPermissions: .permission_suggestions} else {} end))}}
    else
      {hookSpecificOutput: {hookEventName: "PermissionRequest", decision: {behavior: "deny",
        message: (if ($a.message // "") != "" then "Evan answered from the Lighthouse screen: " + $a.message
                  else "Evan denied this from the Lighthouse screen." end)}}}
    end'
  ;;

question)
  screen_first || exit 0
  put_ask "$(printf '%s' "$input" | $JQ -c --arg id "$id" --argjson t "$now" '{
    id: $id, sid: .session_id, kind: "question", t: $t, questions: (.tool_input.questions // [])
  }')"
  ans=$(wait_answer 1800) || { clear_ask; exit 0; }
  clear_ask
  printf '%s' "$input" | $JQ -c --argjson a "$ans" '{hookSpecificOutput: {
    hookEventName: "PreToolUse", permissionDecision: "allow",
    updatedInput: (.tool_input + {answers: $a.answers})}}'
  ;;

reply)
  # Runs in the background after every turn. A reply from the screen wakes Claude (exit 2, stderr).
  [ "$(printf '%s' "$input" | $JQ -r '.stop_hook_active // false')" = "true" ] && exit 0
  put_ask "$(printf '%s' "$input" | $JQ -c --arg id "$id" --argjson t "$now" '{
    id: $id, sid: .session_id, kind: "reply", t: $t,
    last: ((.last_assistant_message // "") | tostring | .[-600:])
  }')"
  ans=$(wait_answer 28000) || { clear_ask; exit 0; }
  clear_ask
  text=$(printf '%s' "$ans" | $JQ -r '.text // empty')
  [ -n "$text" ] || exit 0
  printf 'Evan replied from the Lighthouse screen (treat this as his next message): %s\n' "$text" >&2
  exit 2
  ;;
esac
exit 0
