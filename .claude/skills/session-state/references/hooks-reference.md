# Hooks Reference

Complete technical documentation for the 3 hooks used by the session state system.

## Overview

The session state system uses **3 Claude Code hooks** to maintain working memory:

| Hook | Fires | Purpose | Output Format |
|------|-------|---------|---------------|
| **SessionStart** | Session begins | Read state, validate | Plain text |
| **PreToolUse** | Every 10 tool uses | Regular update reminder | JSON |
| **PostToolUse** | After `gh pr merge` | Archive workflow | JSON |

**Key insight:** Hooks keep state **continuously updated** via regular reminders, not last-minute saves before compaction.

---

## SessionStart Hook

**When it fires:** Once when Claude Code session begins or resumes

**Configuration:**
```json
{
  "SessionStart": [
    {
      "hooks": [
        {
          "type": "command",
          "command": "bash $CLAUDE_PROJECT_DIR/.claude/skills/session-state/scripts/session-state-handler.sh",
          "timeout": 10
        }
      ]
    }
  ]
}
```

**Input:** Minimal JSON with session context

**Output format:** Plain text (stdout directly becomes context Claude can see)

**What it does:**
1. Initializes tool counter to 0
2. Validates `.claude/session-state/current.md` exists
3. Shows git branch and working tree status
4. Reminds Claude to read session state

**Example output:**
```
=== SESSION STATE: SESSION START ===
Session state file: /path/to/.claude/session-state/current.md (exists)
Git branch: main

Git working tree has uncommitted changes:
 M src/components/Login.tsx
 M src/App.tsx

REMINDER: Read session-state.md and verify it reflects current state.
Ask user for clarification if there are discrepancies.

ACTION: Read .claude/session-state/current.md to understand current context.
=== END SESSION STATE ===
```

**Why plain text works:** SessionStart is one of the few hooks where stdout is automatically added as context.

---

## PreToolUse Hook

**When it fires:** Before Read, Edit, Write, or Bash tool execution (with rate limiting)

**Rate limiting:** Only outputs reminder every 10th tool use (via persistent counter)

**Configuration:**
```json
{
  "PreToolUse": [
    {
      "matcher": "Read|Edit|Write|Bash",
      "hooks": [
        {
          "type": "command",
          "command": "bash $CLAUDE_PROJECT_DIR/.claude/skills/session-state/scripts/session-state-handler.sh",
          "timeout": 5
        }
      ]
    }
  ]
}
```

**Input:** Tool information (tool_name, tool_input, etc.)

**Output format:** JSON with `additionalContext` (required for Claude to see it)

**What it does:**
1. Increments persistent tool counter (stored in `/tmp/claude-session-state-tool-count-<project-hash>`)
2. Every 10th use, outputs JSON reminder
3. Otherwise exits silently

**Example output (every 10th call):**
```json
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "allow",
    "additionalContext": "=== SESSION STATE: UPDATE REMINDER ===\nConsider updating .claude/session-state/current.md if work completed.\n=== END SESSION STATE ==="
  }
}
```

**Why JSON is required:** PreToolUse hook output only reaches Claude if formatted as JSON with `additionalContext`. Plain text stdout only appears in verbose mode (Ctrl+O).

**Tool counter persistence:** Uses project path hash (not PID) for stable filename across hook invocations in the same session.

---

## PostToolUse Hook

**When it fires:** After Bash tool execution succeeds

**Trigger:** Detects `gh pr merge` commands in the Bash tool input

**Configuration:**
```json
{
  "PostToolUse": [
    {
      "matcher": "Bash",
      "hooks": [
        {
          "type": "command",
          "command": "bash $CLAUDE_PROJECT_DIR/.claude/skills/session-state/scripts/session-state-handler.sh",
          "timeout": 10
        }
      ]
    }
  ]
}
```

**Input:** Tool execution details including `tool_input.command`

**Output format:** JSON with `additionalContext` (required for Claude to see it)

**What it does:**
1. Extracts command from `tool_input.command`
2. Checks if command contains `gh pr merge`
3. If match, outputs archival workflow reminder
4. Otherwise exits silently

**Example output (when PR merge detected):**
```json
{
  "hookSpecificOutput": {
    "hookEventName": "PostToolUse",
    "additionalContext": "=== SESSION STATE: PR MERGE DETECTED ===\n\nA PR merge was just completed. Archive current session state.\n\nACTIONS REQUIRED:\n1. Get PR number...\n2. Archive current session state...\n..."
  }
}
```

**Why JSON is required:** PostToolUse hook output only reaches Claude if formatted as JSON with `additionalContext`. Plain text stdout only appears in verbose mode.

**Archival workflow:** Full instructions included in the reminder tell Claude exactly how to:
- Extract PR number from merge commit
- Create pr-[number].md archive
- Reset session state from template
- Prune old archives (keep last 5)

---

## What About Compaction Hooks?

**PreCompact, PostCompact, and SessionEnd hooks do NOT work** for this use case.

### Why They Don't Work

According to Claude Code documentation:

> PreCompact hooks have no decision control. They cannot affect the compaction result but can perform follow-up tasks.
>
> PostCompact hooks have no decision control. They cannot affect the compaction result but can perform follow-up tasks.

**Their output never reaches Claude.** These hooks are for:
- Audit logging
- Metrics collection
- External notifications
- Side effects only

**SessionEnd** similarly cannot provide context to Claude.

### Original Design vs Reality

**Original intent:** Save state right before compaction (PreCompact), restore after (PostCompact)

**Why it can't work:** Hook output doesn't reach Claude, defeating the entire purpose

**Redesigned approach:** Keep state continuously updated via PreToolUse reminders (every 10 tools). If compaction happens, state is at most 10 tool uses stale. SessionStart reads whatever exists when resuming.

---

## Hook Output Visibility Table

Comprehensive reference for which hooks can reach Claude:

| Hook Event | Plain Text Stdout | JSON `additionalContext` | Decision Control |
|------------|-------------------|--------------------------|------------------|
| **SessionStart** | ✅ Yes (added as context) | ✅ Yes | ✅ Full |
| **UserPromptSubmit** | ✅ Yes (added as context) | ✅ Yes | ✅ Full |
| **PreToolUse** | ❌ No (verbose mode only) | ✅ Yes | ✅ Can block |
| **PostToolUse** | ❌ No (verbose mode only) | ✅ Yes | ✅ Can block |
| **PostToolUseFailure** | ❌ No (verbose mode only) | ✅ Yes | ✅ Can block |
| **PreCompact** | ❌ No | ❌ No | ❌ None |
| **PostCompact** | ❌ No | ❌ No | ❌ None |
| **SessionEnd** | ❌ No | ❌ No | ❌ None |
| **Stop** | ❌ No | ❌ No | ✅ Can block |

**Source:** [Claude Code Hooks Documentation](https://code.claude.com/docs/en/hooks)

---

## Best Practices

### For Hook Scripts

1. **Always validate environment variables** - Check `$CLAUDE_PROJECT_DIR` exists
2. **Use proper JSON output** - PreToolUse and PostToolUse require JSON with `additionalContext`
3. **Handle missing files gracefully** - Don't crash if session state doesn't exist
4. **Use stable filenames for persistence** - Project hash, not PID
5. **Keep reminders concise** - Hook output becomes conversation context

### For Tool Counter Persistence

```bash
# BAD: Uses $$ (PID) - counter resets every invocation
TOOL_COUNT_FILE="/tmp/tool-count-$$"

# GOOD: Uses project hash - persists across invocations
PROJECT_HASH=$(echo "$CLAUDE_PROJECT_DIR" | shasum | cut -d' ' -f1)
TOOL_COUNT_FILE="/tmp/tool-count-${PROJECT_HASH}"
```

### For JSON Output

```bash
# PreToolUse/PostToolUse - use JSON
jq -n '{
  hookSpecificOutput: {
    hookEventName: "PreToolUse",
    permissionDecision: "allow",
    additionalContext: "Your message here"
  }
}'

# SessionStart - plain text works
echo "Your message here"
```

---

## Debugging Hooks

### Check if hooks are firing

```bash
# Run Claude Code in debug mode
claude --debug

# Then use Ctrl+O for verbose transcript mode to see hook output
```

### Manually test hook script

```bash
export CLAUDE_PROJECT_DIR="/path/to/project"

# Test SessionStart
echo '{"hook_event_name":"SessionStart"}' | bash .claude/skills/session-state/scripts/session-state-handler.sh

# Test PreToolUse (10th call)
# First set counter to 9
echo "9" > /tmp/claude-session-state-tool-count-$(echo "$CLAUDE_PROJECT_DIR" | shasum | cut -d' ' -f1)
echo '{"hook_event_name":"PreToolUse"}' | bash .claude/skills/session-state/scripts/session-state-handler.sh

# Test PostToolUse
echo '{"hook_event_name":"PostToolUse","tool_input":{"command":"gh pr merge 123"}}' | bash .claude/skills/session-state/scripts/session-state-handler.sh
```

### Verify JSON output is valid

```bash
echo '{"hook_event_name":"PreToolUse"}' | bash .claude/skills/session-state/scripts/session-state-handler.sh | jq .
# Should parse without errors
```

---

## Related Documentation

- **Hook script implementation:** `.claude/skills/session-state/scripts/session-state-handler.sh`
- **Hook configuration:** `.claude/settings.json`
- **Complete system docs:** `references/session-state-system.md`
- **Official Claude Code hooks:** [code.claude.com/docs/en/hooks](https://code.claude.com/docs/en/hooks)
