#!/usr/bin/env bash
# claude-wrapper.sh — Rate-limited Claude Code CLI wrapper
# Enforces max 5 invocations per rolling hour window.

set -euo pipefail

RATE_FILE="${HOME}/.openclaw/skills/claude-code/.rate-state.json"
MAX_CALLS=5
WINDOW_SECS=3600  # 1 hour

# Ensure rate state file exists
if [[ ! -f "$RATE_FILE" ]]; then
  echo '{"calls":[]}' > "$RATE_FILE"
fi

NOW=$(date +%s)
CUTOFF=$((NOW - WINDOW_SECS))

# Read existing calls and filter to within window
CALLS=$(python3 -c "
import json, sys
with open('$RATE_FILE') as f:
    data = json.load(f)
recent = [t for t in data.get('calls', []) if t > $CUTOFF]
print(json.dumps(recent))
")

COUNT=$(python3 -c "import json; print(len(json.loads('$CALLS')))")

if (( COUNT >= MAX_CALLS )); then
  # Find when the oldest call in window expires
  OLDEST=$(python3 -c "import json; calls=json.loads('$CALLS'); print(min(calls))")
  RESET_AT=$((OLDEST + WINDOW_SECS))
  WAIT_MINS=$(( (RESET_AT - NOW + 59) / 60 ))  # round up
  echo "⛔ Rate limit reached: ${COUNT}/${MAX_CALLS} calls in the last hour."
  echo "⏳ Try again in ~${WAIT_MINS} minute(s)."
  exit 1
fi

# Record this call
NEW_CALLS=$(python3 -c "
import json
calls = json.loads('$CALLS')
calls.append($NOW)
print(json.dumps({'calls': calls}))
")
echo "$NEW_CALLS" > "$RATE_FILE"

REMAINING=$((MAX_CALLS - COUNT - 1))
echo "✅ Claude Code invoked (${REMAINING}/${MAX_CALLS} calls remaining this hour)"
echo "---"

# Forward all arguments to claude
exec "${HOME}/.local/bin/claude" "$@"
