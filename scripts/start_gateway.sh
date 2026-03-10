#!/usr/bin/env bash
set -euo pipefail

# Start the openclaw gateway in foreground mode.
# Usage: bash scripts/start_gateway.sh [port]
#   port  Gateway port (default: $OPENCLAW_PORT or 18889)

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
if [ -f "$PROJECT_DIR/.env" ]; then
  set -a
  source "$PROJECT_DIR/.env"
  set +a
fi

PORT="${1:-${OPENCLAW_PORT:-18889}}"
PIDFILE="/tmp/openclaw-gateway.pid"
WEBHOOK_URL="${SLACK_WEBHOOK_URL:-}"

notify() {
  local msg="$1"
  if [ -n "$WEBHOOK_URL" ]; then
    curl -s -X POST "$WEBHOOK_URL" \
      -H 'Content-Type: application/json' \
      -d "{\"channel\":\"#update-svc\",\"text\":\"$msg\"}" \
      >/dev/null 2>&1 || true
  fi
  echo "[notify] $msg"
}

cleanup() {
  rm -f "$PIDFILE"
  notify "moltbot stopped"
  exit 0
}

trap cleanup SIGINT SIGTERM EXIT

# Kill existing gateway if running
if [ -f "$PIDFILE" ]; then
  OLD_PID=$(cat "$PIDFILE" 2>/dev/null || true)
  if [ -n "$OLD_PID" ] && kill -0 "$OLD_PID" 2>/dev/null; then
    echo "[gateway] stopping existing gateway (pid $OLD_PID)..."
    kill "$OLD_PID" 2>/dev/null || true
    sleep 1
  fi
  rm -f "$PIDFILE"
fi

notify "moltbot started (port $PORT)"

export PNPM_HOME="$HOME/.local/share/pnpm"
export PATH="$PNPM_HOME:$PATH"

# Foreground execution — Ctrl+C to stop
openclaw gateway --port "$PORT" --verbose
