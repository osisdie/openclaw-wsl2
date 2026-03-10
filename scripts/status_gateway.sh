#!/usr/bin/env bash
set -euo pipefail

# Show openclaw gateway status: process, channels, models, and auth.
# Usage: bash scripts/status_gateway.sh

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
if [ -f "$PROJECT_DIR/.env" ]; then
  set -a
  source "$PROJECT_DIR/.env"
  set +a
fi

export PNPM_HOME="$HOME/.local/share/pnpm"
export PATH="$PNPM_HOME:$PATH"

PORT="${OPENCLAW_PORT:-18889}"
PIDFILE="/tmp/openclaw-gateway.pid"

echo "=== MoltBot Gateway Status ==="
echo ""

# Process status
echo "[process]"
if [ -f "$PIDFILE" ]; then
  PID=$(cat "$PIDFILE" 2>/dev/null || true)
  if [ -n "$PID" ] && kill -0 "$PID" 2>/dev/null; then
    echo "  running (pid $PID, port $PORT)"
  else
    echo "  not running (stale pid file)"
  fi
else
  # Check by process name
  GW_PID=$(ps aux 2>/dev/null | grep 'openclaw-gateway' | grep -v grep | awk '{print $2}' | tr '\n' ',' | sed 's/,$//' || true)
  if [ -n "$GW_PID" ]; then
    echo "  running (pid $GW_PID, port $PORT) — no pid file"
  else
    echo "  not running"
  fi
fi
echo ""

# Channel status
echo "[channels]"
openclaw channels status 2>&1 | grep -v '🦞\|OpenClaw\|Tip:' || echo "  (gateway not reachable)"
echo ""

# Model status
echo "[models]"
openclaw models status 2>&1 | grep -E '^(Default|Fallbacks|Image model|Image fallbacks)' || echo "  (unable to read)"
echo ""

# Auth status
echo "[auth]"
openclaw models status 2>&1 | grep -E '(effective=|expir|usage:)' || echo "  (unable to read)"
echo ""

# Doctor summary
echo "[doctor]"
openclaw doctor 2>&1 | grep -E '(Telegram:|Agents:|Skills|Plugins|expir)' || echo "  (unable to read)"
