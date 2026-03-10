# Discord Channel Setup

Connect MoltBot to Discord so your AI agent can respond in Discord DMs and servers.

## Prerequisites

- openclaw installed globally (`pnpm add -g openclaw@latest`)
- A Discord account with permission to create applications

## Step 1: Create a Discord Bot

1. Go to [Discord Developer Portal](https://discord.com/developers/applications)
2. Click **New Application** → enter a name (e.g. `MoltBot`) → Create
3. Go to **Bot** tab (left sidebar):
   - Click **Reset Token** → copy the bot token (save it — you can only see it once)
   - Under **Privileged Gateway Intents**, enable:
     - **Message Content Intent** (required for reading messages)
     - **Server Members Intent** (optional, for member info)
4. Go to **Installation** tab (left sidebar):
   - Integration Type: **Guild Install**
   - Install Link: **Discord Provided Link**
   - Under **Guild Install** → Default Install Settings:
     - Scopes: `bot`
     - Permissions: `Send Messages`, `Read Message History`, `Attach Files`
   - Copy the **Install Link** at the top of the page
5. Open the install link in browser → select your server → **Authorize**

> **Note**: The OAuth2 → URL Generator page may be disabled. Use the **Installation** page instead — it is the current recommended method for configuring bot permissions and generating the invite link.

## Step 2: Save Bot Token

Add the token to your `.env` file (never commit this):

```bash
# .env
DISCORD_BOT_TOKEN="MTIz..."
```

## Step 3: Enable Discord Channel

```bash
# Add Discord channel
openclaw channels add

# Select "Discord" when prompted
# Token source: environment variable

# Verify
openclaw channels list
# Expected: Discord default: configured, token=env, enabled
```

The channel config in `~/.openclaw/openclaw.json` should look like:

```jsonc
{
  "channels": {
    "discord": {
      "enabled": true,
      "dmPolicy": "pairing",
      "groupPolicy": "allowlist",
      "streamMode": "partial"
    }
  },
  "plugins": {
    "entries": {
      "discord": { "enabled": true }
    }
  }
}
```

> If `openclaw channels add` doesn't list Discord, enable the plugin first:
> ```bash
> openclaw plugins enable discord
> ```

## Step 4: Start the Gateway

```bash
bash scripts/start_gateway.sh
```

Look for Discord connection confirmation in the gateway logs.

## Step 5: Pair Your Account

With `dmPolicy: "pairing"`, you need to approve your Discord account before the bot responds.

1. DM the bot on Discord — send `hello`
2. The gateway terminal shows a pairing request:
   ```
   pairing request from discord sender <id>, code: XYZ789
   ```
3. Approve in a separate terminal:
   ```bash
   openclaw pairing approve discord <pairing-code>
   ```
4. Confirmation: `Approved discord sender <your-id>`
5. Send another message — the bot should now respond

## Step 6: Verify

```bash
# Channel status
openclaw channels list
openclaw channels status    # requires running gateway

# Health check
openclaw doctor
```

From Discord, try:
- DM the bot with `hello`
- Send a photo with a question (if vision model is configured)
- Try `/weather Taipei`

## Configuration Options

| Key | Values | Description |
|-----|--------|-------------|
| `dmPolicy` | `pairing` / `open` | `pairing` = require approval (recommended). `open` = anyone can DM (unsafe) |
| `groupPolicy` | `allowlist` / `open` | `allowlist` = only approved servers/channels. `open` = respond everywhere |
| `streamMode` | `partial` / `full` / `off` | How streaming responses are sent |

> **Security**: Always use `pairing` for DM policy. The bot can access local system resources — every unauthorized user is a risk.

## Adding the Bot to a Server

### Invite via Install Link

1. Developer Portal → your app → **Installation** tab
2. Copy the **Install Link** (or **Discord Provided Link**)
3. Open in browser → select your server → Authorize
4. Bot appears in the server member list (may show as offline until gateway starts)

### Configure Channel Allowlist

With `groupPolicy: "allowlist"`, specify which server/channel the bot can respond in.

During `openclaw channels add`, enter the allowlist in `guildId/channelId` format. Get the IDs from the Discord channel URL:

```
https://discord.com/channels/GUILD_ID/CHANNEL_ID
                               ↑           ↑
                          Server ID    Channel ID
```

Example:
```
1111111111111111111/222222222222222222
```

## Troubleshooting

### Bot is online but not responding

1. Check **Message Content Intent** is enabled in Discord Developer Portal
2. Verify pairing — DM the bot and check gateway logs for pairing request
3. Check gateway logs for errors

### Bot not appearing online

1. Verify `DISCORD_BOT_TOKEN` is set in `.env`
2. Ensure the discord plugin is enabled:
   ```bash
   openclaw plugins list
   # Should show: discord: enabled
   ```
3. Restart gateway after config changes

### "Missing Access" or permission errors

The bot needs proper permissions in the server:
1. Developer Portal → **Installation** → Guild Install → Default Install Settings
2. Ensure Scopes has `bot`, Permissions has `Send Messages`, `Read Message History`
3. Copy the Install Link → re-invite the bot to the server with updated permissions

### Bot not visible in server member list

1. Bot only shows as "Online" when the gateway is running
2. Scroll down in the member list to check the "Offline" section
3. Search for the bot name in the Discord search bar or type `@BotName` in chat
4. Verify **Server Members Intent** is enabled in Developer Portal → Bot tab

### Running both Telegram and Discord

openclaw supports multiple channels simultaneously. Both can be enabled in the same config:

```jsonc
{
  "channels": {
    "telegram": { "enabled": true, "dmPolicy": "pairing" },
    "discord": { "enabled": true, "dmPolicy": "pairing" }
  }
}
```

Each channel has its own pairing — approve separately for each platform.
