# Claude Code Skill

Custom OpenClaw skill that exposes Claude Code CLI (`~/.local/bin/claude`) via Telegram command `/claude_code`, with rate limiting.

## Overview

| Item | Value |
|------|-------|
| Skill name | `claude-code` |
| Telegram command | `/claude_code` |
| Rate limit | 5 calls per rolling hour |
| Requirements | `claude` (Claude Code CLI), `python3` |
| Deploy to | `~/.openclaw/skills/claude-code/` |

## How It Works

1. User sends `/claude_code <prompt>` in Telegram
2. OpenClaw matches the command to the `claude-code` skill
3. The agent reads `SKILL.md` instructions and runs `claude-wrapper.sh`
4. Wrapper checks `.rate-state.json` — if 5+ calls in the last hour, blocks with wait time
5. Otherwise, records the timestamp and `exec`s `~/.local/bin/claude -p '<prompt>'`
6. Output is relayed back to Telegram

### Rate Limiting

Uses a **rolling window** (not fixed hourly reset):

- Each call timestamp is stored in `.rate-state.json`
- On invocation, timestamps older than 1 hour are pruned
- If 5+ remain, the call is rejected with a countdown
- This prevents burst abuse (e.g. 5 at :59 + 5 at :01)

## Source Files

Reference copies of the deployed skill files are in [`claude_code/`](claude_code/):

| File | Description |
|------|-------------|
| [`SKILL.md`](claude_code/SKILL.md) | Skill definition — YAML frontmatter + agent prompt |
| [`claude-wrapper.sh`](claude_code/claude-wrapper.sh) | Rate-limited wrapper script (`chmod +x`) |
| [`.rate-state.json`](claude_code/.rate-state.json) | Call timestamp state (auto-managed) |

## Usage (Telegram)

```
/claude_code 幫我看 ~/.local/bin/claude --version
/claude_code Review this Python script for bugs: <paste code>
/claude_code Explain what this error means: <paste error>
```

## Setup

```bash
# 1. Copy skill files to openclaw
cp -r docs/skills/claude_code/ ~/.openclaw/skills/claude-code/
chmod +x ~/.openclaw/skills/claude-code/claude-wrapper.sh

# 2. Allowlist the wrapper in exec approvals
openclaw approvals allowlist add ~/.openclaw/skills/claude-code/claude-wrapper.sh

# 3. Restart gateway
bash scripts/stop_gateway.sh && bash scripts/start_gateway.sh
```

## Maintenance

```bash
# Check remaining quota
cat ~/.openclaw/skills/claude-code/.rate-state.json

# Reset rate limit
echo '{"calls":[]}' > ~/.openclaw/skills/claude-code/.rate-state.json

# Adjust limit: edit MAX_CALLS or WINDOW_SECS in claude-wrapper.sh
```

## Troubleshooting

| Problem | Fix |
|---------|-----|
| `/claude_code` not in Telegram menu | Restart gateway |
| Bot asks clarifying questions instead of executing | Check `SKILL.md` has "immediately run" directive; restart gateway |
| Rate limit hit unexpectedly | Check `.rate-state.json` timestamps; reset if stale |
| `claude` not found | Verify `~/.local/bin/claude` exists and is in PATH |
