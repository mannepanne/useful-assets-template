# Install Procedure

Complete workflow for installing session state system in a project.

## Pre-check

```bash
# Check if already installed
ls -la .claude/session-state/current.md
```

If exists, suggest `/session-state update` instead.

## Installation steps

### 1. Create directory structure

```bash
mkdir -p .claude/hooks
```

### 2. Copy files from skill directory

```bash
# Create working directory
mkdir -p .claude/session-state
```

### 3. Configure hooks

Read existing `.claude/settings.json` and add hooks configuration:

```json
{
  "hooks": {
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
    ],
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
    ],
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
}
```

**Preserve existing settings:** Merge hooks into existing configuration, don't replace entire file.

### 4. Initialize session state

```bash
# Create from template
cp .claude/skills/session-state/assets/session-state-template.md .claude/session-state/current.md
```

Update with current context:
- Set timestamp
- Set current branch
- Set session focus (e.g., "Session state system installed")

### 5. Validate

```bash
/doctor
```

Check for:
- Hook configuration errors
- Script permissions
- File paths

## Expected outcome

```
Session state system installed successfully!

Files created:
- .claude/session-state/current.md (working state)

Hooks configured (3 events):
- SessionStart, PreToolUse, PostToolUse
- All reference script from skill folder: .claude/skills/session-state/scripts/
- Strategy: Keep state updated regularly, not last-minute saves

⚠️  SECURITY REMINDER:
   Session state is git-ignored by default (see .gitignore).
   Do NOT include API keys, passwords, PII, or sensitive business data.
   See references/session-state-system.md for complete security guidelines.

Check .claude/session-state/current.md to track your work.
Hooks will activate on next tool use.
```

## Next steps

1. Start working - hooks fire automatically
2. SessionStart fires when session begins - reads existing state
3. PreToolUse reminds every 10 tool uses - keep state current
4. PostToolUse detects PR merges - triggers archival workflow

State stays fresh through regular updates. If compaction happens, state won't be more than 10 tool uses stale.
