# Telegram Channel Setup

Connect MoltBot to Telegram so you can chat with your AI agent from any device.

## Prerequisites

- openclaw installed globally (`pnpm add -g openclaw@latest`)
- A Telegram account

## Step 1: Create a Telegram Bot

1. Open Telegram, search for **@BotFather**
2. Send `/newbot`
3. Enter a display name (e.g. `MoltBot`)
4. Enter a username (must end with `bot`, e.g. `iMoltBot`)
5. BotFather replies with an **HTTP API token** — copy it
6. (Recommended) `/mybots` → select your bot → Bot Settings → Group Privacy → **Turn off**

## Step 2: Save Bot Token

Add the token to your `.env` file (never commit this):

```bash
# .env
TELEGRAM_BOT_TOKEN="123456789:ABCdef..."
```

openclaw reads `TELEGRAM_BOT_TOKEN` from environment automatically — no need to put it in `openclaw.json`.

## Step 3: Enable Telegram Channel

```bash
# Add Telegram channel (interactive — will prompt for token source)
openclaw channels add

# Verify
openclaw channels list
# Expected: Telegram default: configured, token=env, enabled
```

This creates the channel entry in `~/.openclaw/openclaw.json`:

```jsonc
{
  "channels": {
    "telegram": {
      "enabled": true,
      "dmPolicy": "pairing",
      "groupPolicy": "allowlist",
      "streamMode": "partial"
    }
  },
  "plugins": {
    "entries": {
      "telegram": { "enabled": true }
    }
  }
}
```

## Step 4: Start the Gateway

```bash
bash scripts/start_gateway.sh
```

The gateway connects to Telegram via long-polling (not webhook). You should see connection logs in the terminal.

## Step 5: Pair Your Account

DM policy is set to `pairing` — unknown senders must be explicitly approved.

1. Find your bot on Telegram (e.g. `@iMoltBot`), send `hello`
2. The gateway terminal shows a **pairing request** with a code:
   ```
   pairing request from telegram sender <id>, code: ABC123
   ```
3. Approve in a separate terminal:
   ```bash
   openclaw pairing approve telegram <pairing-code>
   ```
4. Confirmation: `Approved telegram sender <your-id>`
5. Send another message — the bot should now respond

## Step 6: Verify

```bash
# Channel status
openclaw channels list
openclaw channels status    # requires running gateway

# Health check
openclaw doctor
```

From Telegram, try:
- Text: `hello` — should get a response
- Photo + question: send a photo with "what is this?" — tests vision
- Slash command: `/weather Taipei` — tests skill invocation

## Configuration Options

| Key | Values | Description |
|-----|--------|-------------|
| `dmPolicy` | `pairing` / `open` | `pairing` = require approval (recommended). `open` = anyone can DM (unsafe) |
| `groupPolicy` | `allowlist` / `open` | `allowlist` = only approved groups. `open` = any group |
| `streamMode` | `partial` / `full` / `off` | How streaming responses are sent. `partial` sends updates as they arrive |

> **Security**: Always use `pairing` for DM policy. The bot can access local system resources — every unauthorized user is a risk.

## Troubleshooting

### Bot not responding to messages

1. Check gateway logs — is the message received?
2. Verify pairing: you must be an approved sender
3. Check for stale polling offset:
   ```bash
   # Reset Telegram polling offset (forces re-fetch)
   rm ~/.openclaw/telegram/update-offset-default.json
   # Restart gateway
   ```

### 409 Conflict error in logs

Another process is polling the same bot token. Stop all other instances:

```bash
bash scripts/stop_gateway.sh
# Then restart
bash scripts/start_gateway.sh
```

### Bot shows "waiting for network"

This is a Telegram client-side display issue. If the gateway is running and you've paired successfully, the bot will still respond to messages regardless of this status indicator.

### Re-pairing after gateway restart

Pairing persists across restarts — you don't need to re-pair each time. If pairing data is lost:

```bash
# Check paired senders
openclaw pairing list

# Re-pair if needed
# Send any message from Telegram → approve the new code
```
