# MoltBot (OpenClaw) — Personal AI Agent Setup

> WSL2 (Ubuntu) + Telegram + Gemini/OpenRouter, foreground execution mode

## Quick Start

```bash
# 1. Install
npm install -g pnpm
pnpm add -g openclaw@latest
openclaw --version

# 2. Onboarding (choose Manual, skip model setup)
openclaw onboard

# 3. Set model (choose one)
# Option A: Gemini API key (recommended — vision + tools + free tier)
#   Get a key at https://aistudio.google.com/apikey
#   Add GEMINI_API_KEY=AIza... to .env
openclaw models set "google/gemini-2.5-flash"
openclaw models set-image "google/gemini-2.5-flash"

# Option B: OpenRouter free models (no API cost)
openclaw models set "openrouter/openai/gpt-oss-120b:free"

# 4. Start (foreground mode)
bash scripts/start.sh
```

## Token Security

### All secrets in `.env`, never in config

```bash
# .env (gitignored, never committed)
TELEGRAM_BOT_TOKEN="your-telegram-bot-token"
OPENROUTER_API_KEY="sk-or-v1-your-openrouter-key"
SLACK_WEBHOOK_URL="https://hooks.slack.com/services/..."

GEMINI_API_KEY="AIza..."          # Primary model auth (google provider)
HF_TOKEN="hf_..."                 # HuggingFace Inference API (Whisper transcription)
B2_KEY_ID="..."                   # Backblaze B2 (youtube-to-pdf uploads)
B2_APP_KEY="..."
```

openclaw automatically reads `TELEGRAM_BOT_TOKEN` and `OPENROUTER_API_KEY` from environment variables — **no need to put them in `openclaw.json`**.

### Add Telegram Channel

```bash
# Interactive setup (will prompt for token)
openclaw channels add

# Verify token source is env var
openclaw channels list
# Should show: Telegram default: configured, token=env, enabled
```

### Pairing (Authorize Users)

DM policy should be set to `pairing` to ensure only you can operate the bot:

1. Find your bot on Telegram (e.g. `@iNewsyBot`), send `hello`
2. Bot replies with a pairing code
3. Approve in terminal:
   ```bash
   openclaw pairing approve telegram <pairing-code>
   ```
4. Success when you see `Approved telegram sender <your-id>`

### Restart Gateway to Apply Changes

```bash
# If gateway is running in foreground: Ctrl+C to stop, then restart
bash scripts/start.sh

# If running as systemd daemon:
openclaw gateway stop
bash scripts/start.sh
```

## Model Tiers

MoltBot uses a tiered model strategy:

| Role | Model | Capabilities | Cost |
|------|-------|-------------|------|
| Primary | `google/gemini-2.5-flash` | text + vision + tools, 1024k context | Free tier / very low |
| Fallback 1 | `openrouter/google/gemma-3-27b-it:free` | text + vision, 128k context | Free |
| Fallback 2 | `openrouter/meta-llama/llama-3.3-70b-instruct:free` | text + tools, 128k context | Free |

### Switching Models

```bash
# Change primary model
openclaw models set "google/gemini-2.5-flash"

# Change image model
openclaw models set-image "google/gemini-2.5-flash"

# Manage fallbacks
openclaw models fallbacks add "openrouter/model-name"
openclaw models fallbacks clear

# Scan for new free models with tool support
openclaw models scan
```

## Vision (Image Understanding)

Send a photo to the Telegram bot with a question and it will analyze the image. Supports:
- Image description and analysis
- OCR (text extraction from screenshots/photos)
- Visual reasoning (charts, diagrams, UI screenshots)

Requires a vision-capable primary model (e.g. `gemini-2.5-flash`).

## Thinking Level

Per-command thinking level for agent reasoning. Options: `off`, `minimal`, `low`, `medium`, `high`.

```bash
# Via CLI
openclaw agent --thinking medium --message "Analyze this data"

# Default is 'low' when using Gemini 2.5 Flash via Telegram
```

## OpenRouter Privacy Settings

> **Important**: Free models require all of the following OpenRouter privacy settings to be enabled

Go to https://openrouter.ai/settings/privacy and verify:

| # | Setting | Free models | Paid models |
|---|---------|-------------|-------------|
| 1 | Enable paid endpoints that may train on inputs | ✅ Enabled | ❌ Disabled |
| 2 | Enable free endpoints that may train on inputs | ✅ Enabled | ❌ Disabled |
| 3 | Enable free endpoints that may publish prompts | ✅ Enabled | ❌ Disabled |

⚠️ **When using paid models (or Gemini direct), disable #1–#3 to protect privacy.**

## Gateway Lifecycle

Uses **foreground execution** (not daemon) to ensure the operator is always aware of bot activity:

```bash
# Start (auto-sends Slack webhook notification + runs gateway in foreground)
bash scripts/start_gateway.sh          # default port 18889
bash scripts/start_gateway.sh 19000    # custom port

# Stop
bash scripts/stop_gateway.sh           # graceful stop (finds process automatically)

# Status
bash scripts/status_gateway.sh         # process, channels, models, auth overview

# Legacy (still works)
bash scripts/start.sh
```

## Common Commands

```bash
openclaw doctor              # Health check
openclaw status              # Channel and session status
openclaw channels list       # List configured channels
openclaw channels status     # Channel connection status (requires running gateway)
openclaw models status       # Model and auth status
bash scripts/test-gemini-api.sh    # Verify Gemini API key
openclaw cron list           # Scheduled background tasks
```

## Gemini API Test

Verify Gemini API key connectivity (minimal token usage):

```bash
bash scripts/test-gemini-api.sh                    # Default: gemini-2.5-flash
bash scripts/test-gemini-api.sh gemini-2.0-flash   # Test specific model
```

## Custom Skills

### YouTube to PDF (`/youtube_to_pdf`)

Converts a YouTube video into a bilingual summary PDF and uploads to Backblaze B2.

```
/youtube_to_pdf https://www.youtube.com/watch?v=... --lang zh-tw
/youtube_to_pdf https://youtu.be/abc123 --lang en
```

Pipeline: subtitles (yt-dlp + Whisper fallback) → summaries (HuggingFace) → HTML → PDF (headless Chrome) → B2 upload. Skill files live in `skills/youtube-to-pdf/`, symlinked from `~/.openclaw/skills/`.

### Claude Code (`/claude_code`)

Telegram command that invokes Claude Code CLI with a **5 calls/hour** rate limit.

```
/claude_code Explain what this function does: ...
/claude_code Review this code for security issues
```

Skill files live in `~/.openclaw/skills/claude-code/`. See [docs/skills/claude_code.md](docs/skills/claude_code.md) for details.

## File Structure

```
ai-moltbot/
├── .env                     # Secrets: tokens, API keys (gitignored)
├── .env.example             # Secret template (committed)
├── scripts/
│   ├── start_gateway.sh     # Start gateway (foreground, API key preflight)
│   ├── stop_gateway.sh      # Stop gateway (handles WSL2/no-systemd)
│   ├── status_gateway.sh    # Gateway status overview
│   ├── clear_session.sh     # Clear agent session history (telegram/discord/all)
│   ├── start.sh             # Legacy wrapper → start_gateway.sh
│   └── test-gemini-api.sh   # Gemini API connectivity test
├── skills/
│   └── youtube-to-pdf/      # YouTube → PDF pipeline (symlinked to ~/.openclaw/skills/)
│       ├── SKILL.md         # Skill definition
│       ├── youtube-to-pdf.sh
│       ├── youtube_utils.py
│       ├── process_video.py
│       ├── summaries_to_html.py
│       ├── html_to_pdf.py
│       └── requirements.txt
├── openclaw/
│   ├── openclaw.example.json         # Config template (OpenRouter free models)
│   └── openclaw.gemini.example.json  # Config template (Gemini direct + free fallbacks)
├── docs/
│   ├── SDD.md               # Software design document
│   ├── SKILL.md             # Skills reference and management guide
│   ├── SOD_zh-tw.md         # Enhancement plan (zh-TW)
│   ├── channels/
│   │   ├── telegram.md      # Telegram setup and pairing guide
│   │   └── discord.md       # Discord setup and pairing guide
│   └── skills/
│       ├── claude_code.md   # Claude Code skill overview
│       └── claude_code/     # Skill source files (SKILL.md, wrapper, state)
├── CLAUDE.md                # AI assistant guidelines
└── README.md                # This file
```

## Channel Setup

- **Telegram**: See [docs/channels/telegram.md](docs/channels/telegram.md) — bot creation, token setup, pairing
- **Discord**: See [docs/channels/discord.md](docs/channels/discord.md) — bot creation, intents, pairing

## Security Notes

- Bot can access local system resources — **every new permission grant is a risk escalation**
- DM policy must be `pairing`, never use `open`
- Regularly review granted tool permissions
- `.env` is in `.gitignore`, never commit secrets
- Gemini uses API key auth (`GEMINI_API_KEY`) — no OAuth, no token expiry
