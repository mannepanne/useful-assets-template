# Template follow-ups

Tracker for improvements to the template itself (distinct from any user project's `SPECIFICATIONS/`). Items here are forward-looking — when one is ready to act on, promote it to a proper spec under `SPECIFICATIONS/` and run `/review-spec` before implementing.

When a derivative project clones this template, this file can usually be deleted unless they want to track their own template-level follow-ups.

---

## Open

### Recalibrate reviewer-agent severity defaults against the threat-model ADR

**Idea:** Update `security-specialist.md` and `triage-reviewer.md` so their severity ratings match the threat model documented in [`REFERENCE/decisions/2026-04-25-pr-review-threat-model.md`](./REFERENCE/decisions/2026-04-25-pr-review-threat-model.md). Today these agents default to a worst-case "all attackers including malicious committers" stance, which produces theoretical-RCE findings that don't apply to the in-scope use case.

**Calibration intent:**
- `security-specialist`: keep vigilant on production-runtime exposure (deployed-app vulns, secrets in repo history, malicious upstream packages, SQL injection, RLS/auth bugs, XSS, IDOR, CSRF). De-prioritise attacks that require a malicious committer (PR-content prompt injection, hostile migrations, backdoors in test code) — flag them as "out-of-scope per threat model" with a one-line tightening pointer rather than as blockers.
- `triage-reviewer`: HIGH→team triggers stay path-based (data layer, auth, CI, supply chain) since those are runtime concerns. The secret-shape scan threshold doesn't change. Add one-line guidance for severity calibration.
- Shared `.claude/agents/CLAUDE.md`: one-line pointer at the ADR for "when assessing severity, see this threat model" so all reviewers can reference it.

**Why separate from PR 19:** PR 19 ships the *foundation* (the ADR, the calibrated allowlist, correctness fixes). This PR ships the *agent-side calibration* that builds on that foundation. Keeping them in separate PRs keeps each one's review surface tractable.

**Next step:** when ready, this is a small focused PR (3-4 files). Likely no spec needed — write the agent-prompt edits directly, run `/review-pr` on it, ship.

---

### Add belt-and-braces relative-path entries for Write allowlist (path-normalisation workaround)

**Status:** hypothesis confirmed. The follow-up team review of PR 19 reproduced the prompt verbatim — Claude Code displayed `../../../../../../tmp/review-pr-19-triage.md` for an absolute Write target, and the absolute-form `Write(/tmp/review-pr-*)` allowlist entry didn't match. Same behaviour for the related `Bash` cleanup of stale temp files (see the next entry).

**Hypothesis (now confirmed):** Claude Code's permission matcher doesn't normalise relative-vs-absolute paths before applying allowlist patterns. Allowlist entries with absolute paths silently fail to match when the tool input is the same path expressed relatively.

**Why this matters:** the dispatcher writes its body files (`/tmp/review-pr-N-light.md`, `/tmp/review-pr-N-standard.md`, `/tmp/review-pr-N-team.md`, `/tmp/review-pr-N-triage.md`, `/tmp/spec-review-N.md`) using absolute paths in the skill prompt. The matcher transforms those to relative form before evaluating allowlist matches, so the entries shipped in PR 19 don't silence the prompts they were meant to silence.

**Proposed workaround:** add a second matching entry in relative-traversal form alongside each absolute-form `Write(/tmp/…)` entry — e.g. `Write(../../../../../../tmp/review-pr-*)` next to `Write(/tmp/review-pr-*)`. Belt-and-braces, costs nothing if the underlying bug is fixed upstream, immediately silences the prompt today.

**Caveat:** the literal traversal depth (`../../../../../../`) depends on where Claude Code starts the relative path from. Capture the exact form from a fresh permission prompt and use that — don't guess the depth.

**Separately:** file the bug against Claude Code so the workaround can be removed once the matcher normalises paths.

---

### Dispatcher temp-file handling shouldn't need an `rm -f` cleanup

**Observation:** During the team review of PR 19, the dispatcher invoked `rm -f /tmp/review-pr-19-triage.md /tmp/review-pr-19-light.md /tmp/review-pr-19-standard.md` and triggered a manual approval prompt. The `rm -f` was a workaround for the Write tool refusing to overwrite an existing file without a prior Read. Stale temp files from a previous abandoned review run hit that path.

**Why the workaround is awkward:** `rm -f /tmp/…` is a Bash command that's not allowlisted (and shouldn't be — generic `Bash(rm -f *)` is too broad to grant). So every run with stale temp files prompts the user. Self-inflicted noise.

**Cleaner options to consider:**
- **Read-then-Write fallback in the skill instructions.** The dispatcher detects the "file already exists" error from Write, then Reads the file (to satisfy the prerequisite), then Writes. No Bash needed.
- **Unique filenames per session.** Add a short random suffix or PID to the temp filename — e.g. `/tmp/review-pr-19-triage-$RANDOM.md`. Always-fresh paths means the conflict never arises. Trade-off: slightly less predictable for debugging.
- **Allow `Bash(rm -f /tmp/review-pr-*)` and `Bash(rm -f /tmp/spec-review-*)` explicitly.** Narrowest possible allowlist scope (only the dispatcher's own temp files). Subject to the same path-normalisation caveat as the Write entries.

**Why separate from the path-normalisation workaround:** that one's about the Write tool's allowlist matcher behaviour. This one's about the dispatcher's design choosing to rely on a Bash cleanup at all. Different fix.

**Next step:** pick an option (probably option 1 — least surface area, no allowlist churn) and apply it to `.claude/skills/review-pr/SKILL.md`, `.claude/skills/review-pr-team/SKILL.md`, and `.claude/skills/review-spec/SKILL.md`. Small docs/skills PR, no spec needed.

---

### PreToolUse safety-harness hook

**Idea:** Add a `PreToolUse` hook in `.claude/settings.json` that intercepts dangerous bash commands before they execute, requiring extra confirmation or outright blocking them. Acts as a safety net against contributor or AI mistakes — distinct from the allowlist (which is about UX/permission grants).

**Examples worth catching:**
- `rm -rf` against anything outside `/tmp/` or designated scratch dirs
- `git push --force` to `main` or other protected branches
- `git reset --hard` when there are unpushed commits
- `git commit --no-verify` (skipping pre-commit hooks)
- `DROP TABLE` / `DROP DATABASE` in non-test database connections
- `chmod -R 777`

**Why separate from PR 19:** PR 19 is about the *allowlist* (silencing UX friction for safe operations). The safety harness is the inverse problem (catching dangerous operations regardless of allowlist). Different goal, complementary. Keeping them in separate PRs keeps each one's reasoning clean.

**Next step:** when ready, write a spec under `SPECIFICATIONS/`, run `/review-spec` on it, then implement. The spec should cover (a) which commands to catch, (b) block-vs-warn for each, (c) escape hatch for legitimate use, (d) interaction with the existing allowlist.

**Related context:** the threat model in [`REFERENCE/decisions/2026-04-25-pr-review-threat-model.md`](./REFERENCE/decisions/2026-04-25-pr-review-threat-model.md) — the template assumes a single trusted contributor running PRs they themselves authored. The safety harness is how we keep that flow safe against honest mistakes (yours or Claude's), not against hostile contributors.

---

## Done

*(Move items here when implemented and merged.)*
