# CLAUDE.md — AI Assistant Project Guidelines

## Project

MoltBot personal config repo. The bot itself is installed globally (`pnpm add -g openclaw@latest`); this repo holds config, scripts, and docs.

## Key Facts

- **Channel**: Telegram (primary). Slack webhook for status notifications only.
- **Execution**: Foreground only (`openclaw gateway --verbose`). No daemon/systemd.
- **Secrets**: `.env` file, never committed. Contains `TELEGRAM_BOT_TOKEN` and `SLACK_WEBHOOK_URL`.
- **Security**: Bot accesses local system — treat every new permission grant as a risk escalation. DM policy must be `pairing`, never `open`.

## Commands

- Start: `bash scripts/start.sh`
- Stop: `Ctrl+C` (foreground), the script auto-sends stop webhook
- Status: `openclaw doctor` or `openclaw status`

## Files

- `docs/SDD.md` — Design document and requirements
- `scripts/start.sh` — Lifecycle wrapper script (with Slack webhook notifications)
- `.env` — Secrets (gitignored)
- `.env.example` — Secret template
