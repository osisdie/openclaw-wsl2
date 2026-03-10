# MoltBot — Software Design Document

## 1. Overview

MoltBot (OpenClaw/ClawdBot) is an AI agent gateway that connects to messaging platforms (Telegram) and executes tasks on the local system. This project manages **personal configuration, custom skills, and operational scripts** — the moltbot binary itself is installed globally via `pnpm add -g openclaw@latest`.

## 2. Architecture

```
Telegram ──► moltbot gateway (foreground) ──► AI model (Gemini / OpenRouter)
                  │
                  ├── custom-skills/
                  ├── crons/
                  └── ~/.openclaw/openclaw.json
```

- **Runtime**: Node.js v22.x on WSL2 (Ubuntu)
- **Channel**: Telegram Bot API (primary), Slack webhook for status notifications only
- **Execution mode**: Foreground (`openclaw gateway --verbose`), NOT daemon/systemd — ensures operator awareness of all activity

## 3. Requirements

### 3.1 Status Notifications

Send notification to Slack webhook on bot **start** or **stop**:
- URL: Read from `SLACK_WEBHOOK_URL` in `.env`
- Channel: `#update-svc`
- Payload: `{ "channel": "#update-svc", "text": "moltbot <started|stopped>" }`

Implementation: wrapper script (`start.sh`) sends webhook on lifecycle events.

### 3.2 Security

> **Critical**: Once running, the bot can access local system resources via granted permissions. The attack surface grows with each new permission.

Mitigations:
- Run in **foreground only** — operator sees all activity in real time
- Telegram DM policy: `pairing` (require explicit approval per user)
- Never use `"open"` DM policy in production
- `.env` holds all secrets, is `.gitignore`'d, never committed
- Regularly review granted tool permissions
- Restrict shell exec scope where possible

### 3.3 Telegram Integration

- Bot token stored in `.env` as `TELEGRAM_BOT_TOKEN`
- Config in `~/.openclaw/openclaw.json` under `channels.telegram`
- DM policy: `pairing`
- Group access: `allowlist` (disabled by default)
- Stream mode: `partial` (sends partial responses as they stream)

### 3.4 Operations

- Foreground execution for awareness (`openclaw gateway --verbose`)
- Start/stop via wrapper script that handles Slack webhook notifications
- System resource monitoring via agent commands (`openclaw doctor`, `openclaw status`)

### 3.5 Model Strategy

Tiered model approach balancing cost, capability, and vision support:

| Role | Model | Capabilities | Cost |
|------|-------|-------------|------|
| Primary | `google-gemini-cli/gemini-2.5-flash` | text + vision + tools, 1024k context | Paid (very low) |
| Fallback 1 | `openrouter/google/gemma-3-27b-it:free` | text + vision, 128k context | Free |
| Fallback 2 | `openrouter/meta-llama/llama-3.3-70b-instruct:free` | text + tools, 128k context | Free |

- **Primary provider**: Google Gemini API via `google-gemini-cli-auth` plugin (OAuth)
- **Fallback provider**: OpenRouter API via `OPENROUTER_API_KEY` env var
- Thinking level: per-command (`--thinking off|minimal|low|medium|high`), default `low`

### 3.6 Vision

- Image model: `google-gemini-cli/gemini-2.5-flash` (native vision support)
- Telegram photo analysis: users send photos with a question, model analyzes content
- Supports: image description, OCR, visual reasoning (charts, diagrams, screenshots)
- Image fallback: `openrouter/google/gemma-3-27b-it:free` (free vision model)

### 3.7 Authentication

- **Gemini**: OAuth via `google-gemini-cli-auth` plugin. Requires `@google/gemini-cli` installed globally. OAuth credentials sourced from env vars (`GEMINI_CLI_OAUTH_CLIENT_ID`, `GEMINI_CLI_OAUTH_CLIENT_SECRET`) or extracted from gemini-cli package.
- **OpenRouter**: API key via `OPENROUTER_API_KEY` env var (for fallback models).
- **Telegram**: Bot token via `TELEGRAM_BOT_TOKEN` env var.

## 4. File Structure

```
ai-moltbot/
├── .env                  # TELEGRAM_BOT_TOKEN, OPENROUTER_API_KEY, OAuth credentials (gitignored)
├── .env.example          # Template (committed)
├── scripts/
│   ├── start_gateway.sh  # Start gateway (foreground, Slack webhook, port override)
│   ├── stop_gateway.sh   # Stop gateway (WSL2-compatible, no systemd needed)
│   ├── status_gateway.sh # Gateway status: process, channels, models, auth
│   ├── start.sh          # Legacy wrapper → start_gateway.sh
│   └── test-gemini-api.sh # Gemini API connectivity test
├── openclaw/
│   ├── openclaw.example.json         # Config template (OpenRouter free models)
│   └── openclaw.gemini.example.json  # Config template (Gemini direct + free fallbacks)
├── docs/
│   ├── SDD.md            # This file
│   ├── SKILL.md          # Skills reference and management guide
│   ├── SOD_zh-tw.md      # Enhancement plan (zh-TW)
│   └── channels/
│       ├── telegram.md   # Telegram channel setup and pairing guide
│       └── discord.md    # Discord channel setup and pairing guide
├── CLAUDE.md             # AI assistant guidelines
└── README.md             # Setup guide
```
