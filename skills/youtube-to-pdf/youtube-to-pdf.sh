#!/usr/bin/env bash
# youtube-to-pdf.sh — Full pipeline: YouTube → subtitles → summaries → HTML → PDF → B2 signed URL
# Usage: youtube-to-pdf.sh <youtube_url> [language]
#   language: zh-tw (default) or en

set -euo pipefail

URL="${1:-}"
LANG="${2:-zh-tw}"

if [[ -z "$URL" ]]; then
    echo "Error: YouTube URL is required" >&2
    echo "Usage: youtube-to-pdf.sh <youtube_url> [zh-tw|en]" >&2
    exit 1
fi

# --- Extract video ID ---
VIDEO_ID=""
re_long='[?\&]v=([a-zA-Z0-9_-]{11})'
re_short='youtu\.be/([a-zA-Z0-9_-]{11})'
if [[ "$URL" =~ $re_long ]]; then
    VIDEO_ID="${BASH_REMATCH[1]}"
elif [[ "$URL" =~ $re_short ]]; then
    VIDEO_ID="${BASH_REMATCH[1]}"
fi

if [[ -z "$VIDEO_ID" ]]; then
    echo "Error: Could not extract video ID from URL: $URL" >&2
    exit 1
fi

echo "Video ID: $VIDEO_ID"
CHANNEL_SLUG="tg-${VIDEO_ID}"

# --- Paths ---
SKILL_DIR="$(cd "$(dirname "$0")" && pwd -P)"
PROJECT_DIR="$(cd "$SKILL_DIR/../.." && pwd -P)"
OUTPUT_BASE="${PROJECT_DIR}/output/youtube"

# Load .env from project root
if [[ -f "${PROJECT_DIR}/.env" ]]; then
    set -a
    source "${PROJECT_DIR}/.env"
    set +a
fi

# --- Step 1: Process video (subtitles + screenshots + summaries) ---
echo "=== Step 1/4: Processing video ==="
python3 "$SKILL_DIR/process_video.py" "$URL" --channel-slug "$CHANNEL_SLUG" --output "$OUTPUT_BASE"

# Find the video output directory (there should be exactly one subdir under the channel slug)
VIDEO_DIR=$(find "${OUTPUT_BASE}/${CHANNEL_SLUG}" -mindepth 1 -maxdepth 1 -type d | head -1)
if [[ -z "$VIDEO_DIR" || ! -d "$VIDEO_DIR" ]]; then
    echo "Error: Could not find video output directory under ${OUTPUT_BASE}/${CHANNEL_SLUG}/" >&2
    exit 1
fi
echo "Video dir: $VIDEO_DIR"

# --- Step 2: Generate HTML ---
echo "=== Step 2/4: Generating HTML ==="
python3 "$SKILL_DIR/summaries_to_html.py" "$VIDEO_DIR" --lang "$LANG"

HTML_FILE="${VIDEO_DIR}/summary_${LANG}.html"
if [[ ! -f "$HTML_FILE" ]]; then
    echo "Error: HTML file not generated at $HTML_FILE" >&2
    exit 1
fi

# --- Step 3: Generate PDF ---
echo "=== Step 3/4: Generating PDF ==="
python3 "$SKILL_DIR/html_to_pdf.py" "$HTML_FILE"

PDF_FILE="${VIDEO_DIR}/summary_${LANG}.pdf"
if [[ ! -f "$PDF_FILE" ]]; then
    echo "Error: PDF file not generated at $PDF_FILE" >&2
    exit 1
fi
echo "PDF: $PDF_FILE ($(du -h "$PDF_FILE" | cut -f1))"

# --- Step 4: Upload to Backblaze B2 ---
echo "=== Step 4/4: Uploading to B2 ==="

B2_KEY_ID="${B2_KEY_ID:-}"
B2_APP_KEY="${B2_APP_KEY:-}"

if [[ -z "$B2_KEY_ID" || -z "$B2_APP_KEY" ]]; then
    echo "Error: B2_KEY_ID or B2_APP_KEY not set in .env" >&2
    exit 1
fi

# Authorize B2
backblaze-b2 authorize-account "$B2_KEY_ID" "$B2_APP_KEY" > /dev/null

# Upload with date in filename to avoid B2 version duplicates
DATE_TAG=$(date +%Y%m%d)
B2_PATH="youtube-pdfs/${VIDEO_ID}/summary_${LANG}_${DATE_TAG}.pdf"

# Skip upload if same-day file already exists
EXISTING=$(backblaze-b2 ls claw-dir "youtube-pdfs/${VIDEO_ID}/" 2>/dev/null | grep "summary_${LANG}_${DATE_TAG}.pdf" || true)
if [[ -n "$EXISTING" ]]; then
    echo "Already uploaded today, skipping re-upload"
else
    backblaze-b2 upload-file claw-dir "$PDF_FILE" "$B2_PATH"
fi

# Generate signed URL (7 days = 604800 seconds)
SIGNED_URL=$(backblaze-b2 get-download-url-with-auth --duration 604800 claw-dir "$B2_PATH")

echo ""
echo "$SIGNED_URL"
