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

### Investigate Claude Code Write path-normalisation for allowlist matching

**Observation:** During the team review of PR 19, the dispatcher tried to write `/tmp/review-pr-19-triage.md` and was prompted for it, despite `Write(/tmp/review-pr-*)` being in `.claude/settings.json`'s allowlist. The path was displayed as `../../../../../../tmp/review-pr-19-triage.md` — a relative path traversal up to the filesystem root, then back down to `/tmp/`. Claude Code's permission matcher seems to have compared the relative form against the absolute pattern and not found a match.

**Hypothesis:** the matcher doesn't normalise relative-vs-absolute paths before applying allowlist patterns. If true, allowlist entries with absolute paths silently fail to match when the tool input is the same path expressed relatively.

**Why this matters:** the dispatcher writes its body files (`/tmp/review-pr-N-light.md`, `/tmp/review-pr-N-standard.md`, `/tmp/review-pr-N-team.md`, `/tmp/review-pr-N-triage.md`, `/tmp/spec-review-N.md`) using absolute paths in the skill prompt. If Claude Code transforms those to relative form before evaluating allowlist matches, the entries we added in this PR won't actually silence the prompts they were meant to silence.

**Next step:** repro deliberately on a fresh review (post PR 19 merge), capture the exact path Claude Code displays in the permission prompt, compare against the allowlist entry. If the hypothesis holds, file the issue against Claude Code (and consider adding both forms to the allowlist as a workaround until fixed).

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
