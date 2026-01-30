# MoltBot — Software Design Document

## 1. Overview

MoltBot (OpenClaw/ClawdBot) is an AI agent gateway that connects to messaging platforms (Telegram) and executes tasks on the local system. This project manages **personal configuration, custom skills, and operational scripts** — the moltbot binary itself is installed globally via `pnpm add -g openclaw@latest`.

## 2. Architecture

```
Telegram ──► moltbot gateway (foreground) ──► AI model (OpenRouter)
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
- Group access: disabled by default

### 3.4 Operations

- Foreground execution for awareness (`openclaw gateway --verbose`)
- Start/stop via wrapper script that handles Slack webhook notifications
- System resource monitoring via agent commands (`openclaw doctor`, `openclaw status`)

## 4. File Structure

```
ai-moltbot/
├── .env                  # TELEGRAM_BOT_TOKEN, SLACK_WEBHOOK_URL (gitignored)
├── .env.example          # Template (committed)
├── scripts/
│   └── start.sh          # Wrapper: webhook notify + start gateway
├── docs/
│   └── SDD.md            # This file
├── CLAUDE.md             # AI assistant guidelines
└── README.md             # Setup guide
```
