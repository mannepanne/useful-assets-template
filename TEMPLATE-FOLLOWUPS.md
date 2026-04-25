# Template follow-ups

Tracker for improvements to the template itself (distinct from any user project's `SPECIFICATIONS/`). Items here are forward-looking — when one is ready to act on, promote it to a proper spec under `SPECIFICATIONS/` and run `/review-spec` before implementing.

When a derivative project clones this template, this file can usually be deleted unless they want to track their own template-level follow-ups.

---

## Open

### Investigate Claude Code Write path-normalisation for allowlist matching

**Status:** intermittent — observed once, couldn't reproduce on the next run. During PR 19's team review the dispatcher tried to write `/tmp/review-pr-19-triage.md` and was prompted, despite `Write(/tmp/review-pr-*)` being in the allowlist; the displayed path was `../../../../../../tmp/review-pr-19-triage.md`. On a follow-up dispatcher run (PR 20's light review, post-merge of PR 19, fresh session), the same Write call ran silently with the same allowlist entry — no prompt. Repro conditions are not yet characterised.

**Working hypothesis:** Claude Code's permission matcher *may* not normalise relative-vs-absolute paths before applying allowlist patterns, so absolute-form entries fail to match relative-form tool inputs in some sessions. The PR 19 observation is consistent with this; the PR 20 silent run is not. Possible explanations for the inconsistency: the matcher does normalise and the PR 19 prompt was caused by something else (settings.json change without session restart, missing entry at the time, transient cache issue); the matcher has session-scoped state we haven't identified; the displayed path differs between sessions for reasons unrelated to allowlist matching.

**Why this still matters:** if the matcher genuinely doesn't normalise, then every `Write(/tmp/…)` and `Bash(... /tmp/…)` allowlist entry is unreliable depending on session state. That's a footgun worth understanding even if the current symptoms are mild.

**Next step:** deliberate repro. Try toggling: (a) settings.json edits without session restart vs. with restart, (b) fresh session vs. resumed session, (c) different invocation paths (skill-driven Write vs. agent-driven Write). Capture the exact displayed path in each case. Once the conditions are characterised, decide between: file an upstream bug; ship the relative-form belt-and-braces workaround as a permanent precaution; or close the entry as a session-state quirk that doesn't need a fix.

**If a workaround is needed later:** add a second matching entry in relative-traversal form alongside each absolute-form `Write(/tmp/…)` entry — e.g. `Write(../../../../../../tmp/review-pr-*)` next to `Write(/tmp/review-pr-*)`. The literal traversal depth depends on where Claude Code starts the relative path from, so capture the exact form from a fresh permission prompt rather than guessing.

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

### Recalibrate reviewer-agent severity defaults against the threat-model ADR

**Shipped:** PR 21.

**Idea:** Update `security-specialist.md` and `triage-reviewer.md` so their severity ratings match the threat model documented in [`REFERENCE/decisions/2026-04-25-pr-review-threat-model.md`](./REFERENCE/decisions/2026-04-25-pr-review-threat-model.md). Today these agents default to a worst-case "all attackers including malicious committers" stance, which produces theoretical-RCE findings that don't apply to the in-scope use case.

**Calibration intent:**
- `security-specialist`: keep vigilant on production-runtime exposure (deployed-app vulns, secrets in repo history, malicious upstream packages, SQL injection, RLS/auth bugs, XSS, IDOR, CSRF). De-prioritise attacks that require a malicious committer (PR-content prompt injection, hostile migrations, backdoors in test code) — flag them as "out-of-scope per threat model" with a one-line tightening pointer rather than as blockers.
- `triage-reviewer`: HIGH→team triggers stay path-based (data layer, auth, CI, supply chain) since those are runtime concerns. The secret-shape scan threshold doesn't change. Add one-line guidance for severity calibration.
- Shared `.claude/agents/CLAUDE.md`: one-line pointer at the ADR for "when assessing severity, see this threat model" so all reviewers can reference it.

**As shipped:** the calibration intent above landed verbatim. The shared contract lives in `.claude/agents/CLAUDE.md` (`Severity calibration` section); `security-specialist.md` gained a `Threat model` section after Role plus a recalibrated `Review Standards` block; `triage-reviewer.md` gained a one-line note explaining why its rubric doesn't need recalibration (path-based HIGH triggers are runtime concerns, in-scope regardless of contributor trust).
