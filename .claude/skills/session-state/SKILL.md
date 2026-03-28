---
name: session-state
description: Maintains session working memory - tracks current task, decisions made, failed approaches, blockers, and progress. Hooks fire automatically during sessions to preserve context across compaction and crashes. Use to install in new projects, update existing installations, or diagnose context loss.
---

# Session State System

**⚠️ EXPERIMENTAL** - Brand new hook-based context preservation. Thoroughly designed but may reveal improvements during real usage.

## What this does

Maintains working memory across:
- Context compaction (save/restore cycle via PreCompact/PostCompact hooks)
- Session crashes or interruptions
- Switching between projects

**How:** 6 hooks fire at critical moments, reminding Claude to update `.claude/session-state/current.md`. On PR merge, current state archives to `.claude/session-state/pr-[number].md` (keeps last 5).

## Commands

### `/session-state install`

Set up session state system in current project.

**Checklist:**
```
Installation:
- [ ] Check if already installed
- [ ] Create directories and copy files
- [ ] Configure hooks in settings.json
- [ ] Initialize session-state/current.md
- [ ] Validate with /doctor
```

**See:** [references/install-procedure.md](references/install-procedure.md)

### `/session-state update`

Update existing installation (preserves active `session-state.md`).

**Checklist:**
```
Update:
- [ ] Verify installation exists
- [ ] Backup current session-state/current.md
- [ ] Update template and hook script
- [ ] Update hooks configuration
- [ ] Validate with /doctor
```

**See:** [references/update-procedure.md](references/update-procedure.md)

### `/session-state status`

Check installation and validate configuration.

**See:** [references/status-check.md](references/status-check.md)

## How hooks work

**See:** [references/hooks-reference.md](references/hooks-reference.md) for complete details.

**Quick summary:**
1. **SessionStart** - Read state, validate
2. **PreToolUse** (every 10 uses) - Gentle update reminder
3. **PreCompact** - **Critical save before compaction**
4. **PostCompact** - Restore context after compaction
5. **PostToolUse** - Detect PR merge, archive state
6. **SessionEnd** - Finalize

## Portable design

**Completely self-contained** - all files bundled in skill directory:

```
.claude/skills/session-state/
├── SKILL.md
├── scripts/session-state-handler.sh
├── assets/session-state-template.md
└── references/
    ├── install-procedure.md
    ├── update-procedure.md
    ├── status-check.md
    ├── pr-archive-format.md
    ├── hooks-reference.md
    └── troubleshooting.md
```

**To install elsewhere:**
1. Copy `session-state/` folder to target project's `.claude/skills/`
2. Run `/session-state install`

## PR archival workflow

When `gh pr merge` runs, PostToolUse hook detects it:

**Checklist:**
```
PR Merge Archival:
- [ ] Extract PR number from merge commit
- [ ] Create session-state/pr-[number].md with summary
- [ ] Reset session-state/current.md from template
- [ ] Prune old files (keep last 5)
- [ ] Update PR history section
```

**Archive format:** [references/pr-archive-format.md](references/pr-archive-format.md)

## Troubleshooting

**Common issues:**
- Hook doesn't fire → [references/troubleshooting.md](references/troubleshooting.md#hook-doesnt-fire)
- State not updating → [references/troubleshooting.md](references/troubleshooting.md#state-not-updating)
- PostCompact validation error → [references/troubleshooting.md](references/troubleshooting.md#postcompact-validation)
- Context still lost → [references/troubleshooting.md](references/troubleshooting.md#context-loss)

**Full guide:** [references/troubleshooting.md](references/troubleshooting.md)

## Experimental status

**This system will evolve based on real usage.** If you encounter issues:
- Check session-state/current.md was updated before compaction
- Verify hooks fire with `/doctor`
- Note patterns where context was lost
- Report findings for system improvements

**Documentation:** See project `REFERENCE/session-state-system.md` for complete implementation details.
