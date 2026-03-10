# CLAUDE.md — AI Assistant Project Guidelines

## Project

MoltBot personal config repo. The bot itself is installed globally (`pnpm add -g openclaw@latest`); this repo holds config, scripts, and docs.

## Key Facts

- **Channel**: Telegram (primary). Slack webhook for status notifications only.
- **Model**: Gemini 2.5 Flash via `google-gemini-cli-auth` plugin (OAuth). Free fallbacks via OpenRouter.
- **Execution**: Foreground only (`openclaw gateway --verbose`). No daemon/systemd.
- **Secrets**: `.env` file, never committed. Contains `TELEGRAM_BOT_TOKEN`, `OPENROUTER_API_KEY`, and Gemini OAuth credentials.
- **Security**: Bot accesses local system — treat every new permission grant as a risk escalation. DM policy must be `pairing`, never `open`.

## Commands

- Start: `bash scripts/start_gateway.sh` (or `bash scripts/start.sh`)
- Stop: `bash scripts/stop_gateway.sh` (or `Ctrl+C` if foreground)
- Status: `bash scripts/status_gateway.sh`
- Health: `openclaw doctor`
- Re-auth Gemini: `openclaw models auth login --provider google-gemini-cli`

## Files

- `docs/SDD.md` — Design document and requirements
- `docs/SKILL.md` — Skills reference and management guide
- `scripts/start_gateway.sh` — Start gateway (foreground, Slack webhook, port override)
- `scripts/stop_gateway.sh` — Stop gateway (WSL2-compatible)
- `scripts/status_gateway.sh` — Gateway status overview
- `scripts/test-gemini-api.sh` — Gemini API connectivity test
- `.env` — Secrets (gitignored)
- `.env.example` — Secret template
