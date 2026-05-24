#!/usr/bin/env bash
PROFILE="$CLAUDE_PROJECT_DIR/.claude/COLLABORATION/personal-profile.md"
if [ ! -f "$PROFILE" ]; then
  exit 0
fi
if grep -q "<!-- profile_status: default -->" "$PROFILE"; then
  echo "PERSONAL_PROFILE_SETUP_REQUIRED: The personal-profile.md file still contains the default template profile. Before doing anything else this session, run the profile setup flow described in .claude/COLLABORATION/profile-setup-flow.md."
fi
exit 0
