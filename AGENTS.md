# AGENTS, Multi-Agent Contract for watchdocker

This file is the contract any AI agent (Claude, Qwen, Mistral, opencode, Continue, Zed-agent) must read before editing the repo.

## Project ethos

`watchdocker` is intentionally minimal. **Resist feature bloat.** Before adding any feature, ask: does this break design constraint 1-7 in the README? If yes, decline. If no, add it.

## Models available
- Default for daily work: `qwen3:8b` (local Ollama)
- Heavy lift, refactor, deep analysis: `sparki/qwen3.6-35b` (Sparki via Tailscale)

## MCP tools enabled
- `kb`, search local Knowledge-Base
- `mem0`, persistent personal memory
- `sovgrid-ai`, search sovgrid.org blog
- `context7`, current library docs

## Rules

1. **Pure bash only.** No Python, Node, Go, Rust. Standard POSIX tools (`find`, `grep`, `sed`, `awk`, `date`) plus `docker compose`. Already on every Linux host.

2. **No em-dashes (U+2014) in any user-facing string.** Use comma, period, or parens.

3. **No "Generated with Claude Code" / "Co-Authored-By: Claude" trailers** in commits intended for GitHub. Local Gitea: agent-trailers OK and encouraged.

4. **TASKS.md is canonical.** Every commit references a CW-### task or adds one.

5. **Read in this order**: `README.md` to know the design constraints, this file for ground rules, `TASKS.md` for current work, `git log -5` for context.

6. **shellcheck must pass.** Before any commit touching `bin/watchdocker`: run `shellcheck bin/watchdocker`. Zero warnings is the gate.

7. **Test on a real compose-project before commit.** Use `--dry-run` against `/opt/legi-openwebui` or similar. Verify output is correct.

8. **Question the user before destructive ops.** No silent `rm`, no force-push, no schema drop.

## Commit-message format

```
CW-### short imperative subject

Optional body. Why, not what.

Co-Authored-By: <agent-name> <agent@legi.local>
```

Agent-trailer naming convention:
- `qwen3-8b@legi.local`
- `mistral-7b@legi.local`
- `sparki-qwen36@sparki.local`
- `claude-code@anthropic`

## Tools/IDE setup
- **Zed**: opens repo, default model qwen3:8b
- **VSCodium + Continue**: same provider list
- **opencode TUI**: same providers + MCPs
- **shellcheck**: `apt install shellcheck` if not present
