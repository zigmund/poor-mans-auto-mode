# Poor Man's Auto Mode — Design Spec

_2026-05-02_

## Problem

Claude Code asks for permission on every new Bash command pattern, leading to a growing project-specific allowlist that must be maintained per-repo. The goal is to approve once and never be prompted again, without resorting to `--dangerously-skip-permissions`.

## Solution

Route all Bash tool calls through a single approved script (`auto`) via a `PreToolUse` hook. One global permission entry covers every command.

## Components

### 1. `auto` — pass-through executor

**File:** `~/Projects/poor-mans-auto-mode/bin/auto`  
**Symlink:** `~/.local/bin/auto`

```bash
#!/bin/bash
exec "$@"
```

Executes its arguments as a command. This is the single approved entry point.

### 2. `auto-hook` — Bash rewriter

**File:** `~/Projects/poor-mans-auto-mode/bin/auto-hook`  
**Symlink:** `~/.local/bin/auto-hook`

Reads PreToolUse JSON from stdin, prepends `auto ` to the Bash command, outputs modified JSON.

```bash
#!/bin/bash
input=$(cat)
cmd=$(echo "$input" | jq -r '.tool_input.command')
echo "$input" | jq --arg c "auto $cmd" '.tool_input.command = $c'
```

### 3. `install.sh` — setup script

**File:** `~/Projects/poor-mans-auto-mode/install.sh`

- Creates `~/.local/bin/` if needed
- Symlinks `bin/auto` → `~/.local/bin/auto`
- Symlinks `bin/auto-hook` → `~/.local/bin/auto-hook`
- Prints next steps (manual settings.json edits)

### 4. Global settings additions

**File:** `~/.claude/settings.json`

Add to `permissions.allow`:
```json
"Bash(auto *)"
```

Add hook:
```json
"hooks": {
  "PreToolUse": [{
    "matcher": "Bash",
    "hooks": [{"type": "command", "command": "~/.local/bin/auto-hook"}]
  }]
}
```

## Data Flow

```
Claude emits Bash tool call: {command: "git status"}
        ↓
auto-hook rewrites:          {command: "auto git status"}
        ↓
Permission check:            Bash(auto *) ✓ approved globally
        ↓
auto executes:               exec git status
```

## Cleanup

The existing per-project allowlist in `.claude/settings.local.json` can be removed — it's superseded by the global `Bash(auto *)` entry.

## Verification

1. Run `install.sh` — confirm symlinks exist at `~/.local/bin/auto` and `~/.local/bin/auto-hook`
2. Run `auto echo hello` — should print `hello`
3. Run `auto-hook` with sample JSON — should output modified command
4. Open Claude Code in any project — run a Bash command — confirm no permission prompt
5. Confirm `auto` is called via `ps` or logging in the script
