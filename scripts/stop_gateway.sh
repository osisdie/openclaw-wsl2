#!/usr/bin/env bash
set -euo pipefail

# Stop the openclaw gateway.
# Handles WSL2 (no systemd) by killing the process directly.
# Usage: bash scripts/stop_gateway.sh

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
if [ -f "$PROJECT_DIR/.env" ]; then
  set -a
  source "$PROJECT_DIR/.env"
  set +a
fi

PORT="${OPENCLAW_PORT:-18889}"
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

# Method 1: PID file
if [ -f "$PIDFILE" ]; then
  PID=$(cat "$PIDFILE" 2>/dev/null || true)
  if [ -n "$PID" ] && kill -0 "$PID" 2>/dev/null; then
    echo "[gateway] stopping gateway (pid $PID)..."
    kill "$PID" 2>/dev/null || true
    sleep 1
    # Force kill if still running
    if kill -0 "$PID" 2>/dev/null; then
      echo "[gateway] force killing (pid $PID)..."
      kill -9 "$PID" 2>/dev/null || true
    fi
    rm -f "$PIDFILE"
    notify "moltbot stopped"
    exit 0
  else
    echo "[gateway] stale pid file (pid $PID not running), cleaning up"
    rm -f "$PIDFILE"
  fi
fi

# Method 2: Find by port (fallback)
PIDS=$(ss -tlnp 2>/dev/null | grep ":${PORT}" | grep -o 'pid=[0-9]*' | grep -o '[0-9]*' || true)
if [ -n "$PIDS" ]; then
  for PID in $PIDS; do
    echo "[gateway] stopping process on port $PORT (pid $PID)..."
    kill "$PID" 2>/dev/null || true
  done
  sleep 1
  notify "moltbot stopped"
  exit 0
fi

# Method 3: Find by process name (last resort)
PIDS=$(ps aux 2>/dev/null | grep 'openclaw-gateway' | grep -v grep | awk '{print $2}' || true)
if [ -n "$PIDS" ]; then
  for PID in $PIDS; do
    echo "[gateway] stopping openclaw-gateway (pid $PID)..."
    kill "$PID" 2>/dev/null || true
  done
  sleep 1
  notify "moltbot stopped"
  exit 0
fi

echo "[gateway] no running gateway found"
