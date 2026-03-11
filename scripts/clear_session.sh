#!/usr/bin/env bash
# Clear openclaw agent sessions to remove poisoned conversation history.
# Usage:
#   bash scripts/clear_session.sh              # clear telegram session (default)
#   bash scripts/clear_session.sh telegram     # clear telegram session
#   bash scripts/clear_session.sh discord      # clear all discord sessions
#   bash scripts/clear_session.sh all          # clear all sessions

set -euo pipefail

TARGET="${1:-telegram}"
SESSIONS_DIR="$HOME/.openclaw/agents/main/sessions"
SESSIONS_INDEX="$SESSIONS_DIR/sessions.json"

if [[ ! -f "$SESSIONS_INDEX" ]]; then
    echo "No sessions index at $SESSIONS_INDEX"
    exit 0
fi

# Use Python for reliable JSON parsing — match on both 'lastChannel' and 'channel' fields,
# also match session keys containing the target (e.g. "telegram" in key name)
RESULT=$(python3 -c "
import json, sys, os

target = sys.argv[1]
index_path = sys.argv[2]
sessions_dir = sys.argv[3]

with open(index_path) as f:
    data = json.load(f)

cleared = []
for key in list(data.keys()):
    entry = data[key]
    channel = entry.get('lastChannel', '') or entry.get('channel', '')
    key_match = target in key.lower()
    channel_match = channel == target

    if target == 'all' or channel_match or key_match:
        sf = entry.get('sessionFile', '')
        if sf and os.path.isfile(sf):
            bak = sf + '.bak'
            os.rename(sf, bak)
            cleared.append(os.path.basename(sf))
        del data[key]

# Also scan for orphan .jsonl files not tracked in sessions.json
# (gateway may recreate sessions that aren't in the index yet)
if target != 'all':
    tracked_files = {e.get('sessionFile', '') for e in data.values()}
    for f in sorted(os.listdir(sessions_dir)):
        if not f.endswith('.jsonl'):
            continue
        full = os.path.join(sessions_dir, f)
        if full in tracked_files:
            continue
        # Read first few KB to check channel
        try:
            with open(full) as fh:
                head = fh.read(4096)
            if target in head:
                os.rename(full, full + '.bak')
                cleared.append(f)
        except Exception:
            pass

with open(index_path, 'w') as f:
    json.dump(data, f, indent=2)

if cleared:
    for c in cleared:
        print(f'Cleared: {c}')
    print(f'\nCleared {len(cleared)} {target} session(s).')
    print('Backups saved as .jsonl.bak — restart gateway to take effect.')
else:
    print(f'No {target} sessions found.')
" "$TARGET" "$SESSIONS_INDEX" "$SESSIONS_DIR")

echo "$RESULT"
