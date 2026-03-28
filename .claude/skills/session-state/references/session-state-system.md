# Session State System

**⚠️ EXPERIMENTAL FEATURE** - This system uses Claude Code hooks to automatically preserve context across compaction and crashes. While thoroughly designed, this is a brand new approach that may reveal improvements or edge cases during real-world usage.

How context preservation works across compaction, crashes, and session interruptions.

---

## Overview

The session state system maintains working memory for Claude Code sessions through:

1. **`.claude/session-state/current.md`** - Current work context (git-ignored by default for security)
2. **Hook scripts** - Automatic reminders at critical moments
3. **PR-based archival** - Auto-archive when PRs merge, keep last 5
4. **Progressive disclosure** - Current work prominent, history available when needed

**Purpose:** Bridge context loss during compaction or crashes for active work sessions, not replace permanent documentation or provide cross-machine sync.

---

## How It Works

### The Five Hooks

**1. SessionStart**
- Fires when Claude Code session begins
- Validates `.claude/session-state/current.md` exists
- Shows git status vs documented state
- Claude reads state and asks clarifications if needed

**2. PreToolUse (every 10 tool uses)**
- Fires before Read, Edit, Write, Bash tools
- Rate limited to every 10th use (tracked in temp file)
- Gentle reminder: "Update session state if work completed"
- Claude proactively updates after meaningful chunks

**3. PreCompact (CRITICAL - Save)**
- Fires before context compaction
- Urgent reminder with checklist of what to save
- Safety net - last chance before context loss
- Claude immediately updates session-state.md

**4. PostCompact (Restore)**
- Fires after context compaction completes
- Reminder to read session-state.md
- Claude reads saved state to restore lost context
- Reviews current task, decisions, blockers

**5. PostToolUse (on PR merge)**
- Fires after Bash commands
- Detects `gh pr merge` commands
- Claude archives current state to `.claude/session-state/pr-[number].md`
- Resets `session-state.md` from template
- Prunes old history (keeps last 5)

**6. SessionEnd**
- Fires when session ends
- Reminder to finalize state
- Claude updates final context for next session

### Hook Philosophy

**Scripts remind, Claude updates:**
- Hook scripts are read-only (can't understand context)
- Scripts output structured reminders
- Claude sees reminders and uses Edit tool to update files
- This keeps scripts simple while leveraging Claude's understanding

---

## Security and Privacy Guidelines

**⚠️ IMPORTANT:** Session state encourages capturing work context, but you must be careful what you include.

### What NOT to Include in Session State

**Never include:**
- **Secrets:** API keys, passwords, tokens, credentials, authentication details
- **Personal Data (PII):** Customer names, email addresses, phone numbers, addresses
- **Sensitive Business Data:** Proprietary algorithms, confidential strategies, unreleased product details
- **Infrastructure Details:** Database connection strings, server IPs, internal architecture (if repo is public)
- **Security Information:** Failed security approaches, vulnerability details, penetration test results
- **Compliance-Sensitive Data:** Health records (HIPAA), financial data, anything subject to regulatory requirements

**Why:** Even though session state is git-ignored by default, removing files from .gitignore could expose sensitive content. Pattern detection helps catch obvious secrets, but you're the final safeguard.

### Safe to Include

**Generally safe:**
- **High-level task descriptions:** "Implementing user search feature", "Refactoring authentication module"
- **Architectural decisions:** "Chose Postgres over MySQL because better JSON support"
- **Failed technical approaches:** "Tried library X, incompatible with our TypeScript version"
- **Non-sensitive blockers:** "Waiting for API documentation", "Need to install jq"
- **File paths and code structure:** "Modified src/components/UserProfile.tsx"
- **Abstract decisions:** "Decided to use factory pattern for widget creation"

### Git Ignore Status

**By default:** Session state files are git-ignored for security:
- `.claude/session-state/current.md`
- `.claude/session-state/pr-*.md`

**Why git-ignored:**
- Prevents accidental secret commits
- Avoids GDPR violations (PII in git history)
- Reduces information disclosure risk
- Makes security the default behavior

**If you want cross-machine sync:**
1. **Not recommended** for active development work
2. Session state is for active sessions, not long-term sync
3. Use permanent docs (SPECIFICATIONS/, REFERENCE/) for cross-machine knowledge
4. If you must: Remove patterns from .gitignore, manually commit, review carefully

### Pattern Detection

SessionEnd hook scans for common secret patterns:
- API key patterns (`api_key=`, `apikey:`)
- Password patterns (`password:`, `passwd=`)
- Secret/token patterns (`secret:`, `bearer`)
- Email addresses (potential PII)
- Known secret formats (Stripe keys, GitHub tokens, AWS keys)

**Warnings don't block** - you can continue, but review carefully before committing.

### GDPR Considerations

If working with EU user data:
- **Do not** include customer names, emails, or identifiable information
- Session state is **not encrypted** at rest
- If committed to git, consider personal data **retention obligations**
- Using default (git-ignored) configuration is safest

### Repository Visibility

**If working on public repos:**
- Be extra cautious about business logic details
- Architectural decisions are usually fine
- Avoid anything that reveals competitive advantage
- Remember: if repo becomes public later, old git history is exposed

### Best Practice: Assume Public

Write session state as if the repository might become public someday. If you wouldn't want it on GitHub's explore page, don't include it.

---

## File Structure

### .claude/session-state/current.md

**Current work** - tracks active tasks and context.

**Sections:**
- **Recent PR history** - Links to last 5 .claude/session-state/pr-*.md files
- **Current task** - What we're building, status, next action
- **Work completed** - This session's accomplishments
- **Decisions made** - Key choices and reasoning
- **Failed approaches** - What didn't work (prevent retry loops)
- **Uncommitted changes** - Modified/new files
- **Blockers** - Current obstacles
- **Context for next session** - Additional helpful info

**Lifecycle:**
- Updated throughout session as work progresses
- Archived to .claude/session-state/pr-[number].md when PR merges
- Reset from template after archival
- Committed to git (survives across machines/crashes)

### .claude/session-state/pr-[number].md

**PR history** - simplified summaries of completed work.

**Format:**
```markdown
# PR #123: Feature Name

**Merged:** 2026-03-20
**Branch:** feature/feature-name
**GitHub:** https://github.com/user/repo/pull/123

## Summary

2-3 sentences: what was built, why, key changes.

## Key decisions made

- Decision 1 and reasoning
- Decision 2 and reasoning

## Files changed

- `file1.ts` - What changed
- `file2.tsx` - What changed

## What's next

Brief note about what this enables.
```

**Lifecycle:**
- Created automatically on PR merge
- Keep last 5 (auto-pruned on new merge)
- Links in session-state.md for reference
- Full details on GitHub, this is quick summary

### .claude/session-state-template.md

**Template** for initializing new session state.

**Usage:**
- Copied to session-state.md after PR merge
- Used by `/session-state install` command
- Updated when session state format evolves

### .claude/skills/session-state/scripts/session-state-handler.sh

**Hook script** - outputs reminders for all 5 events.

**Responsibilities:**
- Validate files exist
- Check git status
- Track tool usage count (for rate limiting)
- Detect PR merges
- Output structured reminders

**Does NOT:**
- Modify session-state.md directly
- Make decisions about what's important
- Parse code or understand context

---

## When to Update Session State

### Automatically (via hooks):

- **SessionStart:** Read state, validate current
- **Every 10 tools:** Consider updating if work done
- **PreCompact:** MUST update before context loss (save)
- **PostCompact:** Read state to restore context (restore)
- **PR merge:** Auto-archive and reset
- **SessionEnd:** Finalize for next session

### Proactively (as Claude):

Update session state after:
- Completing a meaningful file edit
- Making an architectural decision
- Discovering a failed approach
- Hitting a blocker
- Finishing a subtask

**Don't wait for hooks** - be proactive to minimize risk.

---

## PR Archival Workflow

When `gh pr merge` runs:

1. **PostToolUse hook fires**
2. **Extract PR number:**
   - Run `git log -1 --format=%s`
   - Parse "Merge pull request #123" format
   - If fails, ask user for number

3. **Archive current state:**
   - Read `.claude/session-state/current.md`
   - Create `.claude/session-state/pr-[number].md` with summary:
     - PR title, date, branch, GitHub link
     - 2-3 sentence summary
     - Key decisions
     - Files changed (brief)
     - What's next

4. **Reset session state:**
   - Copy `.claude/session-state-template.md` to `.claude/session-state/current.md`
   - Update "Last updated" timestamp
   - Update current branch
   - Add link to new .claude/session-state/pr-[number].md in PR history section

5. **Prune old history:**
   - List all `.claude/session-state/pr-*.md` files
   - Sort by number (descending)
   - Keep last 5
   - Delete older ones

---

## Integration with Permanent Documentation

Session state **supplements** (not replaces) permanent docs:

### Session State (ephemeral)
- **Purpose:** Bridge compaction/crashes
- **Audience:** Claude resuming work
- **Lifecycle:** Reset on PR merge
- **Content:** Current task, recent decisions, active work

### SPECIFICATIONS/ (active)
- **Purpose:** Guide implementation
- **Audience:** Claude + developers
- **Lifecycle:** Archived when phase complete
- **Content:** Requirements, acceptance criteria, technical approach

### REFERENCE/ (implemented)
- **Purpose:** Explain how things work
- **Audience:** Claude + developers + future maintainers
- **Lifecycle:** Updated when features change
- **Content:** Architecture, patterns, how-to guides

### Migration Path

As work progresses:

1. **During session:** Capture in session-state.md
2. **PR time:** Summarize in .claude/session-state/pr-[number].md
3. **Important decisions:** Move to SPECIFICATIONS/ or REFERENCE/
4. **After merge:** Session state resets, permanent docs persist

**Example:**
- Tried library X, didn't work → session-state.md "Failed approaches"
- Decided to use library Y → session-state.md "Decisions made"
- Create PR → .claude/session-state/pr-123.md includes decision
- Update REFERENCE/tech-choices.md → Permanent record of library Y choice

---

## Troubleshooting

### Hook doesn't fire

**Check configuration:**
```bash
# Validate hooks
/doctor

# Check script exists and is executable
ls -la .claude/skills/session-state/scripts/session-state-handler.sh

# Test script syntax
bash -n .claude/skills/session-state/scripts/session-state-handler.sh

# Check jq is installed
which jq
```

**Common issues:**
- Missing jq: `brew install jq` (macOS) or `apt-get install jq` (Linux)
- Script not executable: `chmod +x .claude/skills/session-state/scripts/session-state-handler.sh`
- Syntax error in settings.json: Run `/doctor` to see errors

### Session state not updating

**Expected behavior:**
- Hooks remind but don't force updates
- Claude should proactively update after work
- PreCompact is safety net, not primary mechanism

**If context still lost:**
- Check `.claude/session-state/current.md` was actually updated before compaction
- Verify PreCompact hook is configured and firing
- Consider updating more frequently (don't wait for PreCompact)

### Git not available

**Hook handles gracefully:**
- Script detects if git commands fail
- Outputs "Git is not available" message
- Continues without git-specific checks
- Session state still works

### PR number extraction fails

**Fallback:**
- Hook asks user: "What PR number was just merged?"
- User provides number
- Claude continues with manual number

**Why might fail:**
- Non-standard merge commit format
- Manual merge (not via gh pr merge)
- Squash merge with custom message

---

## Installing in Other Projects

### Using the skill:

```bash
/session-state install
```

This will:
1. Create `.claude/session-state-template.md`
2. Create `.claude/skills/session-state/scripts/session-state-handler.sh`
3. Configure hooks in `.claude/settings.json`
4. Initialize `.claude/session-state/current.md`
5. Run `/doctor` to validate

### Updating from template:

```bash
/session-state update
```

This will:
1. Update template (safe to overwrite)
2. Update hook script (safe to overwrite)
3. Update hooks configuration
4. **Preserve** `.claude/session-state/current.md` (active work!)
5. **Preserve** `.claude/session-state/pr-*.md` (history!)

### Manual installation:

If skill unavailable, copy these files from template repo:
1. `.claude/session-state-template.md`
2. `.claude/skills/session-state/scripts/session-state-handler.sh` (make executable)
3. Add hooks configuration to `.claude/settings.json`
4. Copy template to `.claude/session-state/current.md`
5. Run `/doctor` to validate

---

## Best Practices

### For Claude:

1. **Read session state on SessionStart** - understand current context before starting work
2. **Update proactively** - after meaningful work chunks, don't wait for reminders
3. **PreCompact is critical** - always honour this hook, update immediately
4. **Be specific in "Failed approaches"** - include enough detail to prevent retries
5. **Capture decisions with reasoning** - not just "what" but "why"
6. **Ask clarifications on resume** - if session state is stale or unclear
7. **Suggest permanent doc moves** - when decisions are important enough

### For Users:

1. **Trust the system** - let Claude manage session state, don't manually edit often
2. **Check session-state.md periodically** - verify it reflects current reality
3. **Use .claude/session-state/pr-*.md for reference** - quick reminders of recent work
4. **Move important context to permanent docs** - session state is ephemeral
5. **Update the system** - run `/session-state update` when template improves

---

## Future Enhancements

Potential improvements to consider:

- **Session state diff:** Show what changed since last session
- **Version tracking:** Track system version for easier updates
- **Migration tools:** Upgrade old session states to new formats
- **Context percentage:** If API becomes available, use thresholds instead of tool count
- **Multi-user support:** Per-user session states for team environments
- **EverMemos integration:** Cross-project persistent memory layer

---

## Related Documentation

- **Installation:** `.claude/skills/session-state/SKILL.md` - How to install/update
- **Template:** `.claude/skills/session-state/assets/session-state-template.md` - Session state structure (also copied to `.claude/session-state-template.md`)
- **Hook script:** `.claude/skills/session-state/scripts/session-state-handler.sh` - Implementation details (also copied to `.claude/skills/session-state/scripts/session-state-handler.sh`)
- **Specification:** `SPECIFICATIONS/01-session-memory-hooks.md` - Original design (if still active)

---

## Experimental Status and Feedback

This is a **brand new experimental system**. While the design is thorough and implementation complete, real-world usage will:

- Validate the hook timing and frequency
- Reveal edge cases not anticipated
- Show whether the save/restore cycle is robust
- Identify improvements to the session state structure
- Test PostCompact hook reliability across Claude Code versions

**If you encounter issues:**
- Check `.claude/session-state/current.md` was actually updated before compaction
- Verify hooks are firing with `/doctor`
- Note any cases where context was still lost
- Report patterns that could improve the system

This system will evolve based on actual usage patterns.

---

**Remember:** Session state is a scaffold, not an archive. Important insights should graduate to permanent documentation in SPECIFICATIONS/ or REFERENCE/.
