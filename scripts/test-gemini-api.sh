#!/usr/bin/env bash
set -euo pipefail

# Test Gemini API connectivity with minimal token usage.
# Uses GEMINI_API_KEY from .env — NOT the OAuth flow used by openclaw.
# Purpose: verify the API key works and gemini-2.5-flash is reachable.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

if [ -f "$PROJECT_DIR/.env" ]; then
  set -a
  source "$PROJECT_DIR/.env"
  set +a
fi

API_KEY="${GEMINI_API_KEY:-}"
MODEL="${1:-gemini-2.5-flash}"
BASE_URL="https://generativelanguage.googleapis.com/v1beta"

if [ -z "$API_KEY" ]; then
  echo "ERROR: GEMINI_API_KEY not set in .env"
  exit 1
fi

echo "=== Gemini API Connectivity Test ==="
echo "Model: $MODEL"
echo ""

# Test 1: List models (zero token usage)
echo "[1/2] Listing available models (zero tokens)..."
HTTP_CODE=$(curl -s -o /tmp/gemini-test-models.json -w "%{http_code}" --max-time 15 \
  "${BASE_URL}/models?key=${API_KEY}" 2>&1)

if [ "$HTTP_CODE" = "200" ]; then
  echo "  OK: API key valid (HTTP $HTTP_CODE)"
  if grep -q "$MODEL" /tmp/gemini-test-models.json; then
    echo "  OK: Model '$MODEL' found in available models"
  else
    echo "  WARN: Model '$MODEL' not found in model list"
  fi
else
  echo "  FAIL: HTTP $HTTP_CODE"
  cat /tmp/gemini-test-models.json 2>/dev/null
  exit 1
fi

echo ""

# Test 2: Minimal generation (~10 tokens)
# Uses maxOutputTokens:100 because 2.5-flash thinking can consume low budgets.
echo "[2/2] Minimal generation test (maxOutputTokens=100, timeout=60s)..."
HTTP_CODE=$(curl -s -o /tmp/gemini-test-gen.json -w "%{http_code}" --max-time 60 \
  "${BASE_URL}/models/${MODEL}:generateContent?key=${API_KEY}" \
  -H 'Content-Type: application/json' \
  -d '{"contents":[{"parts":[{"text":"Reply with exactly one word: OK"}]}],"generationConfig":{"maxOutputTokens":100}}' \
  2>&1)

if [ "$HTTP_CODE" = "200" ]; then
  REPLY=$(grep -o '"text"[[:space:]]*:[[:space:]]*"[^"]*"' /tmp/gemini-test-gen.json 2>/dev/null | sed 's/.*"text"[[:space:]]*:[[:space:]]*"//;s/"$//' | tr -d '\n' || true)
  TOKENS=$(grep -o '"totalTokenCount"[[:space:]]*:[[:space:]]*[0-9]*' /tmp/gemini-test-gen.json 2>/dev/null | sed 's/.*[[:space:]]//' || true)
  echo "  OK: Model responded (HTTP $HTTP_CODE)"
  echo "  Reply: ${REPLY:-<no text in response>}"
  echo "  Tokens used: ${TOKENS:-unknown}"
elif [ "$HTTP_CODE" = "429" ]; then
  echo "  WARN: Rate limited (HTTP 429) — API key works but quota exceeded"
  echo "  This is expected on the free tier. The key is valid."
elif [ "$HTTP_CODE" = "000" ]; then
  echo "  FAIL: Timeout (no response within 60s)"
  echo "  Check network connectivity to generativelanguage.googleapis.com"
  exit 1
else
  echo "  FAIL: HTTP $HTTP_CODE"
  cat /tmp/gemini-test-gen.json 2>/dev/null
  exit 1
fi

echo ""
echo "=== Test complete ==="
echo ""
echo "Next steps:"
echo "  1. Run: openclaw models auth login --provider google-gemini-cli"
echo "  2. Run: openclaw models set 'google-gemini-cli/${MODEL}'"
echo "  3. Restart gateway: bash scripts/start.sh"

# Cleanup
rm -f /tmp/gemini-test-models.json /tmp/gemini-test-gen.json
