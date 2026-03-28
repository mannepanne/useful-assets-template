#!/bin/bash
# Session state validation and reminder hook
#
# This SCRIPT is read-only - it validates and outputs reminders to Claude.
# CLAUDE is expected to update session-state.md using the Edit tool when prompted.
#
# The script doesn't modify files because bash can't understand work context.
# Claude receives the output as context and makes intelligent updates.

set -euo pipefail

# Validate required environment variable
if [ -z "${CLAUDE_PROJECT_DIR:-}" ]; then
  echo "ERROR: CLAUDE_PROJECT_DIR environment variable not set"
  echo "This script must be run by Claude Code with project context."
  exit 1
fi

# Read hook event from stdin JSON
EVENT_JSON=$(cat)
HOOK_EVENT=$(echo "$EVENT_JSON" | jq -r '.hook_event_name // "unknown"')
SESSION_FILE="$CLAUDE_PROJECT_DIR/.claude/session-state/current.md"

# Use stable tool count file based on project path (not PID)
# This ensures counter persists across hook invocations in the same session
PROJECT_HASH=$(echo "$CLAUDE_PROJECT_DIR" | shasum | cut -d' ' -f1)
TOOL_COUNT_FILE="/tmp/claude-session-state-tool-count-${PROJECT_HASH}"

# ============================================================================
# SessionStart: Validate state exists and show current context
# ============================================================================
if [ "$HOOK_EVENT" = "SessionStart" ]; then
  # Initialize tool count for this session
  echo "0" > "$TOOL_COUNT_FILE"

  # Validate session state exists
  if [ ! -f "$SESSION_FILE" ]; then
    echo "=== SESSION STATE: FILE MISSING ==="
    echo "WARNING: .claude/session-state/current.md does not exist!"
    echo ""
    echo "ACTION REQUIRED:"
    echo "Create current.md from template before proceeding."
    echo "Template: .claude/skills/session-state/assets/session-state-template.md"
    echo "=== END SESSION STATE WARNING ==="
    exit 0
  fi

  # Get current git status
  cd "$CLAUDE_PROJECT_DIR"
  GIT_AVAILABLE=true
  GIT_STATUS=$(git status --porcelain 2>/dev/null) || GIT_AVAILABLE=false
  GIT_BRANCH=$(git branch --show-current 2>/dev/null || echo "unknown")

  # Output context for Claude (SessionStart allows plain text)
  echo "=== SESSION STATE: SESSION START ==="
  echo "Session state file: $SESSION_FILE (exists)"
  echo "Git branch: $GIT_BRANCH"
  echo ""

  if [ "$GIT_AVAILABLE" = false ]; then
    echo "NOTE: Git is not available in this environment."
  elif [ -n "$GIT_STATUS" ]; then
    echo "Git working tree has uncommitted changes:"
    echo "$GIT_STATUS"
    echo ""
    echo "REMINDER: Read session-state.md and verify it reflects current state."
    echo "Ask user for clarification if there are discrepancies."
  else
    echo "Git working tree is clean."
  fi

  echo ""
  echo "ACTION: Read .claude/session-state/current.md to understand current context."
  echo "=== END SESSION STATE ==="
  exit 0

# ============================================================================
# PreToolUse: Periodic reminder to update state (every 10 tool uses)
# ============================================================================
elif [ "$HOOK_EVENT" = "PreToolUse" ]; then
  # Track tool usage count
  if [ -f "$TOOL_COUNT_FILE" ]; then
    TOOL_COUNT=$(cat "$TOOL_COUNT_FILE")
  else
    TOOL_COUNT=0
  fi

  # Increment count
  NEW_COUNT=$((TOOL_COUNT + 1))
  echo "$NEW_COUNT" > "$TOOL_COUNT_FILE"

  # Only output reminder every 10 uses
  if [ $((NEW_COUNT % 10)) -eq 0 ]; then
    # PreToolUse requires JSON with additionalContext to reach Claude
    jq -n '{
      hookSpecificOutput: {
        hookEventName: "PreToolUse",
        permissionDecision: "allow",
        additionalContext: "=== SESSION STATE: UPDATE REMINDER ===\nConsider updating .claude/session-state/current.md if work completed.\n=== END SESSION STATE ==="
      }
    }'
  fi
  exit 0

# ============================================================================
# PostToolUse: Detect PR merge and trigger archival
# ============================================================================
elif [ "$HOOK_EVENT" = "PostToolUse" ]; then
  # Extract the command from tool_input
  COMMAND=$(echo "$EVENT_JSON" | jq -r '.tool_input.command // ""')

  # Only trigger for gh pr merge commands
  if echo "$COMMAND" | grep -q "gh pr merge"; then
    # PostToolUse requires JSON with additionalContext to reach Claude
    CONTEXT="=== SESSION STATE: PR MERGE DETECTED ===

A PR merge was just completed. Archive current session state.

ACTIONS REQUIRED:
1. Get PR number:
   - Run: git log -1 --format=%s
   - Extract number from 'Merge pull request #123' format
   - If extraction fails, ask user for PR number

2. Archive current session state:
   - Read .claude/session-state/current.md
   - Create .claude/session-state/pr-[number].md with summary format:
     * PR title, date, branch, GitHub link
     * 2-3 sentence summary of what was built
     * Key decisions made
     * Files changed (brief)
     * What's next

3. Reset session state:
   - Copy .claude/skills/session-state/assets/session-state-template.md
   - To .claude/session-state/current.md
   - Update PR history section with link to new pr-[number].md

4. Prune old history:
   - Keep only last 5 .claude/session-state/pr-*.md files
   - Delete older ones

=== END PR MERGE HANDLER ==="

    # Output as JSON with escaped newlines
    jq -n --arg context "$CONTEXT" '{
      hookSpecificOutput: {
        hookEventName: "PostToolUse",
        additionalContext: $context
      }
    }'
  fi
  exit 0
fi

exit 0
