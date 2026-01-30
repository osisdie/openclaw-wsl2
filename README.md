# MoltBot (OpenClaw) — Personal AI Agent Setup

> WSL2 (Ubuntu) + Telegram + OpenRouter, foreground execution mode

## Quick Start

```bash
# 1. Install
npm install -g pnpm
pnpm add -g openclaw@latest
openclaw --version

# 2. Onboarding (choose Manual, skip model setup)
openclaw onboard

# 3. Set model
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

## OpenRouter Privacy Settings

> **Important**: Free models require all of the following OpenRouter privacy settings to be enabled

Go to https://openrouter.ai/settings/privacy and verify:

| # | Setting | Status | Reason |
|---|---------|--------|--------|
| 1 | Enable paid endpoints that may train on inputs | ✅ Enabled | Required for free model + tool calling |
| 2 | Enable free endpoints that may train on inputs | ✅ Enabled | Basic free model access |
| 3 | Enable free endpoints that may publish prompts | ✅ Enabled | Advanced free model endpoints |

⚠️ **When switching to paid models, disable #1, #2, #3 to protect privacy.**

## Execution Mode

Uses **foreground execution** (not daemon) to ensure the operator is always aware of bot activity:

```bash
# Start (auto-sends Slack webhook notification + runs gateway in foreground)
bash scripts/start.sh

# Stop: Ctrl+C (script auto-sends stop notification)
```

## Common Commands

```bash
openclaw doctor              # Health check
openclaw status              # Channel and session status
openclaw channels list       # List configured channels
openclaw channels status     # Channel connection status (requires running gateway)
openclaw models status       # Model and auth status
openclaw cron list           # Scheduled background tasks
```

## File Structure

```
ai-moltbot/
├── .env                     # Secrets: tokens, API keys (gitignored)
├── .env.example             # Secret template (committed)
├── scripts/
│   └── start.sh             # Lifecycle script (with Slack webhook notifications)
├── docs/
│   └── SDD.md               # Software design document
├── CLAUDE.md                # AI assistant guidelines
└── README.md                # This file
```

## Create a Telegram Bot

1. Search **@BotFather** on Telegram → send `/newbot`
2. Enter bot name and username (must end with `bot`)
3. Copy HTTP API token → save to `TELEGRAM_BOT_TOKEN` in `.env`
4. (Recommended) `/mybots` → Bot Settings → Group Privacy → Turn off

## Security Notes

- Bot can access local system resources — **every new permission grant is a risk escalation**
- DM policy must be `pairing`, never use `open`
- Regularly review granted tool permissions
- `.env` is in `.gitignore`, never commit secrets
