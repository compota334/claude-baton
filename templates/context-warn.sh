#!/bin/bash
# claude-baton: context warning for the agent (sessions methodology in CLAUDE.md).
# The model is blind to its own window %: this hook un-blinds it by reading the
# usage from the transcript and injecting a notice via additionalContext
# (PostToolUse). Thresholds: 70% (close the session in an orderly way) and 80%
# (handoff NOW). Warns ONCE per threshold per session. Default 200k tokens;
# 1M-window users export CLAUDE_CONTEXT_LIMIT=1000000
# (in .claude/settings.local.json -> env).
INPUT=$(cat)
TRANSCRIPT=$(echo "$INPUT" | jq -r '.transcript_path // empty')
SESSION=$(echo "$INPUT" | jq -r '.session_id // "nosession"')
{ [ -z "$TRANSCRIPT" ] || [ ! -f "$TRANSCRIPT" ]; } && exit 0

LIMIT="${CLAUDE_CONTEXT_LIMIT:-200000}"

USED=$(tac "$TRANSCRIPT" 2>/dev/null | jq -r 'select(.message.usage != null) |
  (.message.usage.input_tokens // 0) +
  (.message.usage.cache_read_input_tokens // 0) +
  (.message.usage.cache_creation_input_tokens // 0)' 2>/dev/null | head -1)
[ -z "$USED" ] && exit 0
PCT=$(( USED * 100 / LIMIT ))

BAND=""
[ "$PCT" -ge 70 ] && BAND=70
[ "$PCT" -ge 80 ] && BAND=80
[ -z "$BAND" ] && exit 0

MARK="/tmp/claude-ctx-warn-${SESSION}-${BAND}"
[ -f "$MARK" ] && exit 0
touch "$MARK"

if [ "$BAND" = "80" ]; then
  MSG="CONTEXT WARNING: ${PCT}% of the window used (${USED}/${LIMIT} tokens). CRITICAL THRESHOLD: write the handoff NOW (CLAUDE.md convention, docs/handoff/), commit and push the verified work, and tell the user to rename this session (/rename DD-MM-YY short-title) and open a new one that starts by reading the handoff."
else
  MSG="CONTEXT WARNING: ${PCT}% of the window used (${USED}/${LIMIT} tokens). Start closing the session: do NOT start new large tasks; finish what is open, write the handoff, and commit and push. The goal is to close leaving 10-15% of the window free."
fi

jq -n --arg msg "$MSG" \
  '{"hookSpecificOutput":{"hookEventName":"PostToolUse","additionalContext":$msg}}'
exit 0