#!/bin/bash
# ABOUT: PreToolUse hook — auto-approve Write tool calls into <project>/SCRATCH/.
# ABOUT: Workaround for the documented Write allowlist not silencing prompts.
#
# Background: SPECIFICATIONS/INVESTIGATION-claude-code-write-path-normalisation.md
# documents that allowlist entries like Write(/SCRATCH/*), Write(SCRATCH/*),
# Write(/SCRATCH/**), Write(SCRATCH/**) all fail to silence the Write prompt
# in fresh sessions, even though the documented `/path` semantics say they
# should match. After exhausting glob-shape variants (fifth sighting in a
# fresh session, with all four shapes present), hypothesis #3 wins: the Write
# tool gates beyond the allowlist matcher. PreToolUse hooks bypass the matcher
# and emit an explicit permissionDecision, so this script is the fallback path.
#
# Scope: only Write tool calls, only paths under $CLAUDE_PROJECT_DIR/SCRATCH/.
# Anything else falls through unchanged.
#
# Bypass: this hook only emits "allow" — it cannot block anything. There is
# no SAFETY_HARNESS_OFF style escape because there is nothing destructive to
# escape from.

set -u

INPUT=$(cat)

# Parse tool_name and file_path. base64 round-trip avoids whitespace/newline
# splitting issues if the file_path ever contains odd characters.
read -r TOOL_NAME FILE_PATH_B64 <<< "$(printf '%s' "$INPUT" | python3 -c "
import sys, json, base64
try:
    data = json.loads(sys.stdin.read())
    name = data.get('tool_name', '')
    fp = data.get('tool_input', {}).get('file_path', '')
    fp_b64 = base64.b64encode(fp.encode('utf-8')).decode('ascii')
    print(name, fp_b64)
except Exception:
    print('', '')
" 2>/dev/null)"

if [ -n "${FILE_PATH_B64:-}" ]; then
    FILE_PATH=$(printf '%s' "$FILE_PATH_B64" | base64 --decode 2>/dev/null)
else
    FILE_PATH=""
fi

# Only operate on Write. Hook is registered with matcher "Write" but if the
# matcher behaviour ever changes, fail safe by exiting silently for other tools.
if [ "${TOOL_NAME:-}" != "Write" ]; then
    exit 0
fi

# Must have a project root to compare against. If CLAUDE_PROJECT_DIR is unset
# (which would be unusual — Claude Code always exports it), fall through to
# default behaviour rather than risk approving writes outside the project.
if [ -z "${CLAUDE_PROJECT_DIR:-}" ]; then
    exit 0
fi

SCRATCH_DIR="$CLAUDE_PROJECT_DIR/SCRATCH"

# Reject any path containing `..` segments. The case pattern below would
# otherwise match traversal forms like "$SCRATCH_DIR/../etc/passwd" because
# the prefix string still equals "$SCRATCH_DIR/". Legitimate Writes inside
# SCRATCH never contain `..`, so this is safe to reject outright.
case "$FILE_PATH" in
    *..*)
        exit 0
        ;;
esac

# Approve only if file_path is strictly inside $CLAUDE_PROJECT_DIR/SCRATCH/.
# The trailing /* in the case pattern enforces "must have at least one segment
# after SCRATCH/", so the hook never approves writes to the SCRATCH directory
# entry itself or to a sibling like SCRATCHPAD.
case "$FILE_PATH" in
    "$SCRATCH_DIR"/*)
        python3 -c "
import json
print(json.dumps({
    'hookSpecificOutput': {
        'hookEventName': 'PreToolUse',
        'permissionDecision': 'allow',
        'permissionDecisionReason': 'Auto-approved: Write into project SCRATCH directory. See SPECIFICATIONS/INVESTIGATION-claude-code-write-path-normalisation.md for why the allowlist alone does not silence this prompt.'
    }
}))
"
        exit 0
        ;;
esac

# Not a SCRATCH write — let default behaviour proceed.
exit 0
