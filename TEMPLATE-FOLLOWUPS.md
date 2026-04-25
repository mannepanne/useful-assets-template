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

---

## Done

### PreToolUse safety-harness hook

**Shipped:** PR 24 (spec + ADR sub-case landed in PR 23).

**Idea:** Add a `PreToolUse` hook in `.claude/settings.json` that intercepts dangerous bash commands before they execute, requiring extra confirmation or outright blocking them. Acts as a safety net against contributor or AI mistakes — distinct from the allowlist (which is about UX/permission grants).

**As shipped:** two-tier rubric (block / ask) calibrated for the less-experienced-user sub-case in the threat-model ADR. Block-tier patterns: `rm -rf` against root/home/`/Users`, `dd of=/dev/disk*`, `mkfs * /dev/disk*`, `diskutil eraseDisk`, SQL `DROP TABLE/DATABASE/SCHEMA` (catches `psql -c "..."`, `supabase db execute "..."`), `gh repo delete`. Ask-tier patterns: `git reset --hard`, `git push --force` to non-main, `chmod 777`. The originally-drafted warn tier was dropped during implementation when `systemMessage` was found not to render in interactive Claude Code; `chmod 777` moved to ask so the educational message rides on the dialog reason. Inline `SAFETY_HARNESS_OFF=1 <command>` bypass is the documented form (with parent-shell export as a fallback). 32-test fixture-based suite at `.claude/hooks/tests/safety-harness/`. How-it-works at `REFERENCE/safety-harness.md`; implementation history at `SPECIFICATIONS/ARCHIVE/pretooluse-safety-harness.md`.

**Deliberately omitted from the original suggestion list:**
- `git push --force` to main → covered by GitHub branch protection + the `.claude/CLAUDE.md` rule. Hook would be a third layer for a problem two layers already solve.
- `git commit --no-verify` → Claude Code itself uses it legitimately; blocking would create false positives that train bypass behaviour.

### Dispatcher temp-file handling shouldn't need an `rm -f` cleanup

**Shipped:** PR 22.

**Observation:** During the team review of PR 19, the dispatcher invoked `rm -f /tmp/review-pr-19-triage.md /tmp/review-pr-19-light.md /tmp/review-pr-19-standard.md` and triggered a manual approval prompt. The `rm -f` was a workaround for the Write tool refusing to overwrite an existing file without a prior Read. Stale temp files from a previous abandoned review run hit that path.

**As shipped:** option 1 from the original entry — Read-then-Write fallback in the skill instructions. `.claude/skills/review-pr/SKILL.md` and `.claude/skills/review-pr-team/SKILL.md` now spell out the fallback explicitly: if Write errors with *"File has not been read yet"*, Read the path first, then re-issue the Write. No Bash `rm -f`, no allowlist churn, no /tmp/ cleanup needed at end of run. `.claude/skills/review-pr-team/SKILL.md` was also converted from the inline `--body "..."` heredoc-style post to the same Write→`--body-file` pattern as the dispatcher, for the same heredoc-quoting safety reasons. `review-spec/SKILL.md` had no relevant code path (it doesn't post to PRs) so it wasn't touched.

---

### Recalibrate reviewer-agent severity defaults against the threat-model ADR

**Shipped:** PR 21.

**Idea:** Update `security-specialist.md` and `triage-reviewer.md` so their severity ratings match the threat model documented in [`REFERENCE/decisions/2026-04-25-pr-review-threat-model.md`](./REFERENCE/decisions/2026-04-25-pr-review-threat-model.md). Today these agents default to a worst-case "all attackers including malicious committers" stance, which produces theoretical-RCE findings that don't apply to the in-scope use case.

**Calibration intent:**
- `security-specialist`: keep vigilant on production-runtime exposure (deployed-app vulns, secrets in repo history, malicious upstream packages, SQL injection, RLS/auth bugs, XSS, IDOR, CSRF). De-prioritise attacks that require a malicious committer (PR-content prompt injection, hostile migrations, backdoors in test code) — flag them as "out-of-scope per threat model" with a one-line tightening pointer rather than as blockers.
- `triage-reviewer`: HIGH→team triggers stay path-based (data layer, auth, CI, supply chain) since those are runtime concerns. The secret-shape scan threshold doesn't change. Add one-line guidance for severity calibration.
- Shared `.claude/agents/CLAUDE.md`: one-line pointer at the ADR for "when assessing severity, see this threat model" so all reviewers can reference it.

**As shipped:** the calibration intent above landed verbatim. The shared contract lives in `.claude/agents/CLAUDE.md` (`Severity calibration` section); `security-specialist.md` gained a `Threat model` section after Role plus a recalibrated `Review Standards` block; `triage-reviewer.md` gained a one-line note explaining why its rubric doesn't need recalibration (path-based HIGH triggers are runtime concerns, in-scope regardless of contributor trust).
