---
name: claude-code
description: Run Claude Code CLI with rate limiting (max 5 per hour). Use for complex coding tasks, code review, and AI-assisted development.
user-invocable: true
metadata: {"openclaw":{"emoji":"🤖","requires":{"bins":["claude","python3"]}}}
---

# Claude Code (Rate-Limited)

When this skill is invoked, **immediately run the user's request** using the wrapper script. Do NOT ask clarifying questions — just execute.

## Execution

Take the user's input and run it as a Claude Code prompt:

```bash
bash pty:true command:"~/.openclaw/skills/claude-code/claude-wrapper.sh -p 'USER_INPUT_HERE' --output-format text"
```

- Replace `USER_INPUT_HERE` with the user's full message (after `/claude_code`)
- If the user specifies a directory or project, add `workdir:~/that/path`
- If no directory is specified, use the default working directory

## Rate Limit

- **5 calls per rolling hour** — enforced by the wrapper script
- If the wrapper prints "Rate limit reached", relay that message to the user
- Do NOT retry or bypass the wrapper

## Rules

1. **Always use the wrapper** (`~/.openclaw/skills/claude-code/claude-wrapper.sh`), NEVER call `claude` directly
2. **Execute immediately** — do not ask "what task" or "which directory", just run it
3. **Use pty:true** for all invocations
4. **Use `-p` flag** with the user's prompt for non-interactive one-shot execution
5. **Report the output** back to the user after execution completes
