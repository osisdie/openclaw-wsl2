#!/usr/bin/env bash
set -euo pipefail

# Load environment variables
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
if [ -f "$PROJECT_DIR/.env" ]; then
  set -a
  source "$PROJECT_DIR/.env"
  set +a
fi

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
  notify "moltbot stopped"
  exit 0
}

trap cleanup SIGINT SIGTERM EXIT

notify "moltbot started"

# Foreground execution, --verbose ensures operator can observe in real time
export PNPM_HOME="$HOME/.local/share/pnpm"
export PATH="$PNPM_HOME:$PATH"
openclaw gateway --port 18889 --verbose
