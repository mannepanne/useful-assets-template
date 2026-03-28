# Feature: Session State and Context Preservation Hooks

**⚠️ EXPERIMENTAL FEATURE** - First implementation of automated context preservation using Claude Code hooks. Design is thorough but real-world usage will validate and refine the approach.

## Feature overview

**Feature name:** Session State with Hook-Based Context Preservation
**Priority:** High - Prevents context loss during long sessions
**Dependencies:** Claude Code hooks system, existing documentation structure

**Problem statement:**

During long Claude Code sessions, context gets compacted (summarized) to fit within limits. This can cause loss of:
- Recent decisions and reasoning
- Failed approaches (leading to retry loops)
- Current task state and next actions
- Uncommitted work details

Additionally, if a terminal crashes or session ends prematurely, there's no recovery mechanism to resume work effectively.

**Solution:**

Implement a hook-based session memory system that:
1. Maintains ephemeral session state that survives compaction
2. Automatically prompts context preservation at critical moments
3. Enables smooth session resumption after crashes/interruptions
4. Integrates with existing SPECIFICATIONS/ and REFERENCE/ documentation

---

## Scope and deliverables

### In scope

- [ ] Session state file (`session-state.md`) - current work, committed to git
- [ ] PR history files (`session-pr-[number].md`) - archived completed work, keep last 5
- [ ] Session state template (`session-state-template.md`)
- [ ] Session state handler hook script (`.claude/hooks/session-state-handler.sh`)
- [ ] Hook configuration in `.claude/settings.json`
- [ ] SessionStart hook: read state, validate, ask clarifications
- [ ] PreToolUse hook: periodic reminder to update state after work chunks
- [ ] PreCompact hook: **critical** - urgent save before compaction
- [ ] PostCompact hook: read state to restore context after compaction
- [ ] PostToolUse hook: detect PR merge, auto-archive to session-pr-[number].md
- [ ] SessionEnd hook: finalize state
- [ ] Installable skill: `/session-state install` and `/session-state update`
- [ ] Auto-pruning: keep only last 5 session-pr-*.md files
- [ ] Documentation of the system in REFERENCE/
- [ ] Testing of all hooks and auto-archival

### Out of scope

- EverMemos integration (external persistent memory - optional future enhancement)
- Context usage percentage tracking (not available via API)
- Automatic permanent documentation (user decides what moves to SPECIFICATIONS/REFERENCE/)
- Multi-project session memory (this is per-project)
- Git commit capturing in session state (PRs are sufficient granularity)

### Acceptance criteria

- [ ] SessionStart hook fires and reads existing session state
- [ ] PreCompact hook fires before compaction with preservation reminder
- [ ] SessionEnd hook fires and prompts final state update
- [ ] Session state file preserves essential context across compaction
- [ ] After session crash/interruption, resume successfully using saved state
- [ ] Hook scripts are read-only (output reminders, don't modify files)
- [ ] Claude updates session state using Edit tool based on reminders
- [ ] `/doctor` command validates hook configuration with no errors

---

## Technical approach

### Architecture decisions

**Decision 1: Git-Ignored Session State with Optional Commit** (REVISED)
- Choice:
  - `.claude/session-state/*.md` git-ignored by default
  - Users can manually commit for cross-machine sync (not recommended)
  - Strong security warnings in template and documentation
  - Pattern detection scans for secrets at SessionEnd
  - PR-based archival still works (archives also git-ignored)
- Rationale:
  - **Security by default** - prevents accidental secret commits
  - **GDPR compliance** - avoids PII in git history
  - **Information disclosure prevention** - no sensitive business logic in commits
  - Survives local crashes even when git-ignored
  - Users make informed choice if they want to commit
  - Session state is for **active work sessions**, not cross-machine sync
- Alternatives considered:
  - Committed by default (original design) - **Too risky**, users might not realize content is public
  - Always git-ignored, no option - Removes flexibility for users who understand risks
  - Encrypted before commit - Complex, keys become new secret to manage

**Decision 2: Hook Scripts Are Read-Only**
- Choice: Scripts output reminders, Claude updates files
- Rationale:
  - Bash scripts can't understand work context
  - Claude knows what's important and how to describe it
  - Keeps scripts simple and maintainable
  - Follows pattern from referenced blog post
- Alternatives considered:
  - Scripts modify files directly - Can't intelligently decide what to save
  - No hooks, manual updates - Easy to forget, especially before compaction

**Decision 3: Integration with Existing Documentation**
- Choice: Session state supplements (not replaces) SPECIFICATIONS/ and REFERENCE/
- Rationale:
  - Session state is temporary scaffold
  - Important decisions graduate to permanent docs
  - Maintains our existing documentation lifecycle
- Alternatives considered:
  - Replace existing docs with session state - Loses permanent record
  - Ignore existing docs - Creates duplicate/conflicting information

**Decision 4: Proactive Updates Without Context Tracking**
- Choice: PreToolUse reminder every 10 tool uses + PreCompact as safety net
- Rationale:
  - Claude cannot access context usage percentage (no API)
  - `/context` command is user-only
  - PreToolUse fires periodically (every 10 uses), gentle nudge
  - PreCompact always fires before compaction (critical safety net)
  - Rate limiting prevents noise while maintaining awareness
  - Claude proactively updates after meaningful work chunks
- Alternatives considered:
  - Fire PreToolUse every time - Too noisy
  - Only use PreCompact - Might be too late if context already lost
  - Manual user prompting - Defeats purpose of automation

**Decision 5: Installable Skill for Portability**
- Choice: Built into template + installable skill with install/update commands
- Rationale:
  - New projects using template get it automatically
  - Existing projects can install via skill
  - Updates from template can be pushed to other projects
  - Skill lives in template repo for version control
- Commands:
  - `/session-state install` - First-time setup
  - `/session-state update` - Apply improvements from template
  - `/session-state status` - Check installation

### Technology choices

**Hook system:** Claude Code native hooks
- Purpose: Trigger at SessionStart, PreCompact, SessionEnd
- Documentation: https://code.claude.com/docs/en/hooks

**Shell scripts:** Bash
- Purpose: Validate state, output structured reminders
- Dependencies: `jq` (JSON parsing), standard Unix tools

**Session state format:** Markdown
- Purpose: Human-readable, editable, Claude-friendly
- Structure: Templated sections for consistency

### Key files and components

**New files to create:**

```
.claude/
  ├── session-state.md              # Current work (committed to git)
  ├── session-pr-*.md               # PR history (last 5 kept, auto-pruned)
  ├── session-state-template.md     # Template for initializing state
  ├── hooks/
  │   └── session-state-handler.sh  # Hook script (executable)
  ├── settings.json                 # Hook configuration (or update existing)
  └── skills/
      └── session-state.md          # Installable skill for other projects

REFERENCE/
  └── session-state-system.md       # Documentation of how this works
```

**Files to modify:**

```
- CLAUDE.md (root) - Add reference to session memory system
- .claude/CLAUDE.md - Note about session state in memory management section
```

### Session state file structure

```markdown
---
ABOUT: Session working memory - ephemeral notes for active work
ABOUT: Helps survive context compaction and session interruptions
ABOUT: Reset/archive when PR merged - important decisions graduate to SPECIFICATIONS/REFERENCE/
ABOUT: NOT permanent documentation - this is a running set of notes to stay on track
---

# Session State

**Last updated:** [Timestamp]
**Current branch:** [Branch name]
**Session focus:** [What are we working on? Next PR goal?]

---

## Recent PR history

Brief summaries of last 5 PRs (auto-maintained):

- **PR #123** ([Link to session-pr-123.md](./session-pr-123.md)) - [Brief summary]
- **PR #122** ([Link to session-pr-122.md](./session-pr-122.md)) - [Brief summary]
- **PR #121** ([Link to session-pr-121.md](./session-pr-121.md)) - [Brief summary]

---

## Current task

**Task:** [Brief description]
**Status:** [Not started / In progress / Blocked / Complete]
**Next action:** [Immediate next step]

### Subtasks

- [ ] [Subtask 1]
- [ ] [Subtask 2]
- [ ] [Subtask 3]

---

## Work completed this session

- [Accomplishment 1 - brief, with file references]
- [Accomplishment 2 - brief, with file references]

---

## Decisions made

**[Decision topic]:**
- Choice: [What was decided]
- Reasoning: [Why]
- Alternatives: [What was considered and rejected]

---

## Failed approaches (don't retry)

- **[Approach 1]:** Tried [what], failed because [why], learned [what]
- **[Approach 2]:** Attempted [what], blocked by [issue]

---

## Uncommitted changes

**Modified files:**
- `[file path]` - [What changed and why]
- `[file path]` - [What changed and why]

**New files:**
- `[file path]` - [Purpose]

---

## Blockers

- **[Blocker 1]:** [Description and what's needed to unblock]
- **[Blocker 2]:** [Description and what's needed to unblock]

---

## Context for next session

[Any additional context that would help resume this work later]

**Relevant docs:**
- [Link to SPECIFICATIONS/ file if applicable]
- [Link to REFERENCE/ doc if applicable]

**Ready to move to permanent docs:**
- [ ] [Thing that should move to SPECIFICATIONS/]
- [ ] [Thing that should move to REFERENCE/]
```

### Hook script architecture

**Script responsibilities:**
1. Read hook event from stdin JSON
2. Validate session state file exists (SessionStart)
3. Check git status and compare to documented state (SessionStart)
4. Output structured reminders for Claude to see
5. Provide templates for what to capture

**Script does NOT:**
- Modify any files directly
- Make decisions about what's important
- Parse code or understand context
- Require complex dependencies beyond jq

**Hook event flow:**

```
User starts session
  → SessionStart hook fires
    → Script validates session-state.md exists
    → Script outputs git status vs documented state
    → Claude reads state, asks clarifications if needed

Claude uses tool (Read, Edit, Write, Bash)
  → PreToolUse hook fires
    → Script outputs gentle reminder: "Update session state if work completed"
    → Claude proactively updates after meaningful chunks

Context compaction imminent
  → PreCompact hook fires (CRITICAL - safety net)
    → Script outputs urgent preservation reminder
    → Script provides template for what to save
    → Claude updates session-state.md immediately

Context compaction completes
  → PostCompact hook fires
    → Script outputs context restore reminder
    → Claude reads session-state.md to restore saved context
    → Claude reviews current task, decisions, blockers

User runs: gh pr merge
  → PostToolUse (Bash) hook fires
    → Script detects PR merge command
    → Claude runs `git log -1 --format=%s` to get merge commit message
    → Claude extracts PR number from "Merge pull request #123" format
    → If extraction fails, Claude asks user for PR number
    → Claude archives session-state.md → session-pr-[number].md
    → Claude resets session-state.md from template
    → Claude prunes old session-pr-*.md files (keep last 5)
    → Claude updates PR history section in new session-state.md

User ends session
  → SessionEnd hook fires
    → Script outputs finalization reminder
    → Claude updates final state
```

---

## Implementation plan

### Phase 1: Core infrastructure

1. Create `.claude/session-state-template.md` with structure above
2. Create `.claude/hooks/session-state-handler.sh`:
   - Basic structure with event detection
   - SessionStart: validate file exists, output reminder
   - PreCompact: output critical preservation reminder
   - SessionEnd: output finalization reminder
3. Update `.gitignore` to exclude `.claude/session-state.md`
4. Create initial `.claude/session-state.md` from template
5. Make hook script executable

### Phase 2: Hook configuration

1. Create or update `.claude/settings.json` with hook configuration:
   ```json
   {
     "hooks": {
       "SessionStart": [
         {
           "hooks": [
             {
               "type": "command",
               "command": "bash $CLAUDE_PROJECT_DIR/.claude/hooks/session-state-handler.sh",
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
               "command": "bash $CLAUDE_PROJECT_DIR/.claude/hooks/session-state-handler.sh",
               "timeout": 5
             }
           ]
         }
       ],
       "PreCompact": [
         {
           "hooks": [
             {
               "type": "command",
               "command": "bash $CLAUDE_PROJECT_DIR/.claude/hooks/session-state-handler.sh",
               "timeout": 10
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
               "command": "bash $CLAUDE_PROJECT_DIR/.claude/hooks/session-state-handler.sh",
               "timeout": 10
             }
           ]
         }
       ],
       "SessionEnd": [
         {
           "hooks": [
             {
               "type": "command",
               "command": "bash $CLAUDE_PROJECT_DIR/.claude/hooks/session-state-handler.sh",
               "timeout": 10
             }
           ]
         }
       ]
     }
   }
   ```
2. Run `/doctor` to validate configuration
3. Fix any configuration errors

### Phase 3: Installable skill

1. Create `.claude/skills/session-state.md`:
   - Skill commands: install, update, status
   - Install: Copy files, configure hooks, create templates
   - Update: Preserve session-state.md, update scripts/templates
   - Status: Check installation, validate hooks
2. Test skill commands in this repo
3. Test installing skill in a different project
4. Test updating skill in a different project

### Phase 4: Testing and documentation

1. Test SessionStart hook: Start new session, verify state loaded
2. Test PreToolUse hook: Use tools, verify periodic reminder
3. Test PreCompact hook: Trigger compaction, verify urgent reminder
4. Test PostToolUse hook: Run `gh pr merge`, verify auto-archival
5. Test SessionEnd hook: End session, verify finalization
6. Test PR archival: Merge PR, verify session-pr-[number].md created
7. Test auto-pruning: Merge 6+ PRs, verify only last 5 kept
8. Test full cycle: Start → Work → Compact → PR merge → Resume
9. Create `REFERENCE/session-state-system.md` documenting:
   - How the system works
   - What gets saved in session state
   - When to move context to permanent docs
   - PR archival format and structure
   - Troubleshooting common issues
6. Update root CLAUDE.md with reference to session state system
7. Update `.claude/CLAUDE.md` memory management section

---

## Testing strategy

### Functional tests

**SessionStart hook:**
- [ ] Hook fires on session start
- [ ] Validates session-state.md exists
- [ ] Outputs git status comparison
- [ ] Claude reads state and asks clarifications if needed

**PreToolUse hook:**
- [ ] Hook fires before Read, Edit, Write, Bash tools
- [ ] Rate limited: only fires every 10 tool uses
- [ ] Outputs gentle reminder to update state
- [ ] Claude proactively updates after work chunks
- [ ] Not too noisy (short timeout, brief message)

**PreCompact hook:**
- [ ] Hook fires before compaction
- [ ] Outputs urgent preservation reminder
- [ ] Provides template for what to save
- [ ] Claude updates session state immediately

**PostCompact hook:**
- [ ] Hook fires after compaction completes
- [ ] Outputs context restore reminder
- [ ] Claude reads session-state.md to restore context
- [ ] Reviews current task, decisions, blockers from saved state

**PostToolUse hook:**
- [ ] Hook fires after Bash commands
- [ ] Detects `gh pr merge` commands
- [ ] Extracts PR number from merge commit message
- [ ] Fallback: asks user if extraction fails
- [ ] Claude archives to session-pr-[number].md with summary format
- [ ] Claude resets session-state.md from template
- [ ] Claude prunes old history (keep last 5)

**SessionEnd hook:**
- [ ] Hook fires on session end
- [ ] Outputs finalization reminder
- [ ] Claude updates final state

### Integration tests

**Full session lifecycle:**
- [ ] Start session → SessionStart fires → State validated
- [ ] Do work → Update session state as work progresses
- [ ] Trigger compaction → PreCompact fires → Context preserved
- [ ] End session → SessionEnd fires → State finalized
- [ ] Resume session → Previous state readable and useful

**Crash recovery:**
- [ ] Session ends unexpectedly (crash/interrupt)
- [ ] Start new session
- [ ] SessionStart hook shows last known state
- [ ] Claude can resume work from saved context

**PR archival and history:**
- [ ] Merge PR with `gh pr merge`
- [ ] PostToolUse detects merge
- [ ] Current session-state.md archived to session-pr-[number].md
- [ ] New session-state.md created from template
- [ ] PR history section updated with brief summary
- [ ] Old session-pr-*.md files pruned (only last 5 kept)

**Installable skill:**
- [ ] `/session-state install` sets up system in fresh project
- [ ] `/session-state update` updates existing installation
- [ ] `/session-state status` shows current installation state
- [ ] Install preserves no existing files (fresh setup)
- [ ] Update preserves session-state.md (don't overwrite active work)
- [ ] Skill can be copied between projects

**PR archival format:**
- [ ] session-pr-*.md uses simplified summary structure
- [ ] Includes: PR title, date, branch, GitHub link
- [ ] Includes: 2-3 sentence summary, key decisions, files changed
- [ ] Brief "what's next" section
- [ ] Links to full PR on GitHub for details

### Manual testing checklist

- [ ] `/doctor` command shows no hook configuration errors
- [ ] Hook script is executable (`ls -la .claude/hooks/`)
- [ ] Hook script has valid bash syntax (`bash -n script.sh`)
- [ ] `jq` is available (`which jq`)
- [ ] Session state file is git-ignored (`git status` after creating it)
- [ ] Hook outputs appear in Claude's context during session
- [ ] Claude can successfully update session state via Edit tool
- [ ] Session state helps resume work after interruption

---

## Pre-commit checklist

Before creating PR, verify:

- [ ] Hook script created and executable
- [ ] settings.json hook configuration correct
- [ ] `/doctor` shows no errors
- [ ] All hooks tested (SessionStart, PreToolUse, PreCompact, PostCompact, PostToolUse, SessionEnd)
- [ ] Session state template created with frontmatter
- [ ] Session state committed to git (not ignored)
- [ ] PR archival tested (session-pr-*.md files created)
- [ ] Auto-pruning tested (only last 5 kept)
- [ ] Installable skill created and tested
- [ ] Skill install/update/status commands work
- [ ] Documentation created in REFERENCE/
- [ ] Root CLAUDE.md updated with session state reference
- [ ] `.claude/CLAUDE.md` memory management section updated
- [ ] Manual testing complete (full session lifecycle)
- [ ] Crash recovery tested successfully

---

## Edge cases and considerations

### Known risks

- **Hook script doesn't fire:** Validate configuration with `/doctor`, check script permissions
- **jq not available:** Hook script should handle gracefully, provide fallback message
- **Git not available:** Script should detect and skip git-specific checks
- **Session state gets stale:** SessionStart should highlight discrepancies, prompt user to clarify

### Performance considerations

- Hook scripts run synchronously (can block tools)
- Keep script execution fast (<1 second)
- PreToolUse fires every 10 tool uses - must be lightweight (timeout: 5 seconds)
- Script tracks tool use count in temp file (e.g., /tmp/session-state-tool-count)
- SessionStart/End/PreCompact can be slightly slower (timeout: 10 seconds)
- Minimize external command calls in PreToolUse hook
- PostToolUse only processes Bash commands (filtered by matcher)

### Integration with existing workflow

- Session state **supplements** existing SPECIFICATIONS/ and REFERENCE/
- Don't duplicate information between ephemeral and permanent docs
- SessionEnd should remind Claude to move important context to permanent docs
- Todo lists (TodoWrite) continue to track immediate tasks
- Session state captures higher-level context and decisions

### Future enhancement opportunities

- **EverMemos integration:** Cross-project persistent memory
- **Session state diff:** Show what changed since last session
- **Multi-user support:** Session states per user/machine
- **Skill marketplace:** Publish skill for wider distribution
- **Version tracking:** Track session memory system version for updates
- **Migration tools:** Upgrade old session states to new formats

---

## Technical debt introduced

None expected - this is a new isolated system that doesn't modify existing code.

**Potential future debt:**
- If session state grows too large, may need pruning/archival strategy
- If hooks become complex, may need refactoring into separate scripts

---

## Related documentation

- [Root CLAUDE.md](../CLAUDE.md) - Project navigation
- [.claude/CLAUDE.md](../.claude/CLAUDE.md) - Collaboration principles and memory management
- Claude Code Hooks Documentation: https://code.claude.com/docs/en/hooks
- Inspiration: Warren Bullock's session state blog post (provided by user)

---

## Success metrics

**How we'll know this works:**

1. **Context preservation:** After compaction, Claude remembers recent decisions and work
2. **Crash recovery:** After unexpected session end, resume work without re-explaining
3. **Reduced rework:** Fewer instances of retrying failed approaches
4. **User confidence:** Magnus feels safe taking breaks knowing context is preserved
5. **Documentation quality:** Important session insights graduate to permanent docs

**Red flags (if these happen, system needs improvement):**

- Claude still forgets context after compaction
- Session state becomes stale and misleading
- Hooks fire but Claude doesn't update state
- Session state duplicates permanent docs without adding value
- System adds overhead without clear benefit

---

## Resolved design questions

**Session state lifecycle:**
✅ Auto-archive on PR merge to session-pr-[number].md, keep last 5, auto-prune older

**Failed approaches granularity:**
✅ Include specific details: library names, file paths, error context - enough to prevent retries

**TodoWrite integration:**
✅ Keep separate - TodoWrite for task tracking, session state for context/decisions

**Context tracking:**
✅ PreToolUse every 10 tool uses + PreCompact as safety net (no percentage tracking available)

**Multi-branch states:**
✅ Single project-wide session-state.md (matches workflow)

**Packaging:**
✅ Built into template + installable skill (`/session-state`) with install/update commands

**PR number detection:**
✅ Parse merge commit message (`git log -1 --format=%s`), extract from "Merge pull request #123", fallback to asking user

**PreToolUse frequency:**
✅ Rate limited to every 10 tool uses (tracked in temp file)

**session-pr-*.md structure:**
✅ Simplified summary: PR title, date, branch, GitHub link, 2-3 sentence summary, key decisions, files changed, what's next

## Open questions for future iteration

1. **Skill distribution:** Publish to skill marketplace or keep in template only?

2. **Version tracking:** Should session state system track its own version for easier updates?

3. **Migration tools:** Need tools to upgrade old session states to new formats if structure changes?

---

## Implementation notes

[Space for notes during implementation - what worked, what didn't, lessons learned]
