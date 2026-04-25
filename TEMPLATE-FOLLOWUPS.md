# Template follow-ups

Tracker for improvements to the template itself (distinct from any user project's `SPECIFICATIONS/`). Items here are forward-looking — when one is ready to act on, promote it to a proper spec under `SPECIFICATIONS/` and run `/review-spec` before implementing.

When a derivative project clones this template, this file can usually be deleted unless they want to track their own template-level follow-ups.

---

## Open

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

**Related context:** the threat model documented in [REFERENCE/decisions/](./REFERENCE/decisions/) (forthcoming with PR 19's revision) — the template assumes a single trusted contributor running PRs they themselves authored. The safety harness is how we keep that flow safe against honest mistakes (yours or Claude's), not against hostile contributors.

---

## Done

*(Move items here when implemented and merged.)*
