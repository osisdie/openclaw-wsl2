# MoltBot — Skills Reference

OpenClaw skills are agent capabilities that extend what the bot can do via Telegram.
Skills are different from tools — they are higher-level actions that may use multiple tools internally.

## Quick Reference

```bash
# List all skills with status
openclaw skills check

# Show details for a specific skill
openclaw skills info <skill-name>

# Search and install community skills
npx clawdhub
```

## Skill Status Categories

| Status | Meaning |
|--------|---------|
| ✓ Eligible | Ready to use, all requirements met |
| ⏸ Disabled | Manually disabled in config |
| 🚫 Blocked | Blocked by skill allowlist |
| ✗ Missing | Missing binary dependencies, env vars, or OS requirements |

## Currently Installed Skills (Bundled)

```bash
# List all ready skills
openclaw skills check 2>&1 | grep -A 100 "Ready to use:"

# List missing requirements
openclaw skills check 2>&1 | grep -A 200 "Missing requirements:"
```

### Ready Skills

| Skill | Description | Requirements |
|-------|------------|-------------|
| `weather` | Current weather and forecasts via wttr.in | `curl` |
| `coding-agent` | Run Codex CLI, Claude Code, OpenCode, Pi Agent | varies |
| `skill-creator` | Create/update custom AgentSkills | none |
| `tmux` | Remote-control tmux sessions | `tmux` |
| `gemini` | Gemini-specific skill | none |
| `nano-banana-pro` | Image generation | `GEMINI_API_KEY` |
| `bluebubbles` | BlueBubbles (iMessage bridge) | BlueBubbles server + Mac |

### Notable Missing Skills

| Skill | Missing | How to Install |
|-------|---------|---------------|
| `github` | `gh` CLI | `sudo apt install gh && gh auth login` |
| `session-logs` | `rg` (ripgrep) | `sudo apt install ripgrep` |
| `summarize` | `summarize` CLI | `pip install summarize-cli` |
| `video-frames` | `ffmpeg` | `sudo apt install ffmpeg` |
| `slack` | channel config | Enable slack plugin in `openclaw.json` |

## Skill Management

### Install a Skill Dependency

Most skills just need a binary or env var. Check what's missing:

```bash
# Check what a skill needs
openclaw skills info <skill-name>

# Example: install github skill dependency
sudo apt install gh
gh auth login

# Re-check status
openclaw skills check
```

### Install Community Skills

```bash
# Browse and install from ClawdHub
npx clawdhub

# Search for a specific skill
npx clawdhub search <keyword>
```

### Disable / Re-enable a Skill

Bundled skills are auto-enabled when their requirements are met. To manually disable a skill you don't use, add an entry in `~/.openclaw/openclaw.json`:

```jsonc
// ~/.openclaw/openclaw.json
{
  "skills": {
    "entries": {
      "bluebubbles": { "enabled": false },
      "nano-banana-pro": { "enabled": false }
    }
  }
}
```

To re-enable, set `"enabled": true` or remove the entry.

Verify the change:

```bash
# Should no longer list the disabled skill
openclaw skills list --eligible
```

## Using Skills from Telegram

### Slash Commands

Some skills register as Telegram slash commands:

```
/weather Taipei
/coding_agent run tests
/skill_creator create a new skill
```

### Natural Language

The agent may invoke skills automatically based on your message:

```
"What's the weather in Taipei?"  →  may trigger weather skill
"Generate an image of a cat"    →  may trigger nano-banana-pro
```

> **Note**: Whether the agent correctly invokes a skill depends on the model's
> understanding. If a skill doesn't trigger, try the slash command directly.

## Testing a Skill

### From CLI

```bash
# Run agent with a specific skill invocation
openclaw agent --message "/weather Taipei" --thinking low

# Run agent locally (requires API keys in shell)
openclaw agent --local --message "/weather Taipei"
```

### From Telegram

Send the slash command directly to the bot:

```
/weather Taipei
```

### Debug Skill Execution

Watch gateway logs for skill-related events:

```bash
# In another terminal while gateway is running
tail -f /tmp/openclaw/openclaw-$(date +%Y-%m-%d).log | grep -i "skill\|weather\|tool"
```

## Creating Custom Skills

```bash
# Interactive skill creator
openclaw skills create

# Or use the skill-creator skill from Telegram
/skill_creator create a skill that checks disk usage
```

Custom skills are stored in `~/.openclaw/skills/`.

### Skill File Structure

```
~/.openclaw/skills/
└── my-skill/
    ├── SKILL.md          # Skill definition (markdown + frontmatter)
    └── (optional files)  # Supporting scripts, templates, etc.
```

### SKILL.md Format

```markdown
---
name: my-skill
description: Short description for the agent
requirements:
  bins: [curl]           # Required binaries
  env: [MY_API_KEY]      # Required env vars
  os: [linux, darwin]    # OS restrictions (optional)
---

# My Skill

Instructions for the agent on how to use this skill...
```

## Troubleshooting

### Skill shows "Ready" but doesn't work from Telegram

1. The model may not recognize the skill — try the slash command (e.g., `/weather`)
2. Check gateway logs for tool execution errors
3. Verify the skill's dependencies work in your shell:
   ```bash
   # For weather: test curl to wttr.in
   curl -s "https://wttr.in/Taipei?format=3"
   ```

### Skill shows "Missing requirements"

```bash
# Check what's missing
openclaw skills info <skill-name>

# Install the missing binary/env var, then re-check
openclaw skills check
```

### Skill command not appearing in Telegram

Restart the gateway after installing new skill dependencies:

```bash
bash scripts/stop_gateway.sh
bash scripts/start_gateway.sh
```
