---
name: youtube-to-pdf
description: Convert a YouTube video into a bilingual summary PDF and upload to cloud storage. Returns a download URL.
user-invocable: true
metadata: {"openclaw":{"emoji":"📄","requires":{"bins":["python3","backblaze-b2","google-chrome"]}}}
---

# YouTube to PDF

Converts a YouTube video into a styled bilingual summary PDF uploaded to Backblaze B2.

## Invocation

The user sends: `/youtube_to_pdf <URL> [--lang en]`

## Execution

1. **Send a "processing" message immediately** — tell the user: "Processing video... This may take several minutes (downloading subtitles, generating summaries, creating PDF, uploading). I'll send the download link when ready."

2. **Parse arguments** from the user's message:
   - `URL` (required) — a YouTube URL (e.g. `https://www.youtube.com/watch?v=...` or `https://youtu.be/...`)
   - `--lang` (optional) — summary language, default `zh-tw`, supports `en`

3. **Run the pipeline script**:

```bash
bash ~/.openclaw/skills/youtube-to-pdf/youtube-to-pdf.sh "URL" "LANG"
```

   - Replace `URL` with the extracted YouTube URL
   - Replace `LANG` with the language (`zh-tw` or `en`)
   - The script outputs the signed download URL as its **last line** on success

4. **Report the result**:
   - On success: send the signed download URL to the user
   - On failure: send the error message from the script

## Rules

1. **URL is required** — if no URL is provided, reply with usage: `/youtube_to_pdf <URL> [--lang en]`
2. **Always send the processing message first** before running the script
3. **Do not modify the URL** — pass it exactly as the user provided
4. **Pipeline takes minutes** — this is expected, do not timeout early
