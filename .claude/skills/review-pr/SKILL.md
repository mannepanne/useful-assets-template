---
name: review-pr
description: Smart PR review dispatcher — triages the change for risk, then routes to a light, standard, or team review. Explains every decision in plain language so you can override if it got it wrong.
disable-model-invocation: false
user-invocable: true
argument-hint:
  - PR-number
---

# Smart PR Review (Dispatcher)

This skill reviews a PR at the right level of depth — not too shallow, not token-wasteful. It first runs a cheap triage pass, announces what it decided and why, then hands off to one of three review tiers.

## The Three Tiers

| Tier | What runs | Good for | Approx. time |
|---|---|---|---|
| **light** | `light-reviewer` (narrow sanity check) + `technical-writer` (temporal-language + REFERENCE/ currency) | Docs, tests, styling, comment-only changes | ~1–2 min |
| **standard** | `code-reviewer` (full default prompt) + `technical-writer` | Typical feature work, core logic, utilities | ~2–4 min |
| **team** | Multi-perspective team (security, product, architect, docs) with debate | Data layer (Supabase migrations, RLS), auth, CI, dependencies, secrets | ~5–10 min |

Team is auto-selected when the change touches high-blast-radius paths. You can always force team directly with `/review-pr-team N`.

---

## Instructions for Claude

When invoked with a PR number (e.g. `/review-pr 42`):

### Step 1: Triage

Spawn the **`triage-reviewer`** subagent:

**Task:** `Classify PR #$ARGUMENTS for review tier. Follow your rubric and output format exactly. Return only the classification block.`

Wait for the classification. It will be a four-line block: `TIER:`, `RATIONALE:`, `FLAGGED_PATHS:`, `SIZE:`.

**Parsing fallback (fail-closed):** If the response is not a parseable classification block, or `TIER:` is missing, or its value is not one of `{light, standard, team}` (including casing drift like `Tier: light` or out-of-vocabulary values like `medium`), **default to `team`** — the same safety posture the rubric uses for classification ambiguity. Also announce the fallback explicitly in Step 2 so the user can see what happened:

> `🎯 Triage: team (fallback — triage output did not parse). Escalating to team review so a human decides.`

Do not improvise a tier. Do not re-prompt the triage agent — treat the malformed output as a signal that something is off, and let the team tier catch it.

### Step 2: Announce the decision (before running the review)

**CRITICAL:** Tell the user the decision in plain language *before* spawning any reviewer. This lets them catch a mis-triage early instead of paying for a wrong-tier review.

Use this format:

```
🎯 Triage: <tier>
   <rationale>
   <size>

Running <tier> review now. If this looks wrong, stop me and run
/review-pr-team <N> directly to force the deepest tier.
```

Example:

```
🎯 Triage: light
   Docs-only change in REFERENCE/ with no code paths touched.
   Small (23 lines across 2 files)

Running light review now. If this looks wrong, stop me and run
/review-pr-team 42 directly to force the deepest tier.
```

**Note on interruption:** Ctrl-C behaviour during a running sub-agent spawn is not guaranteed to land cleanly on every Claude Code version. If Ctrl-C doesn't take effect immediately, let the current tier finish, then run `/review-pr-team <N>` — reviews stack fine (see override table below).

### Step 3: Route to the right reviewer

**If `TIER: light`:**

Spawn two reviewers in parallel (the narrowed scope is built into the `light-reviewer` agent definition — you do not need to pass override instructions):

1. **`light-reviewer`** with task: `Light-tier review of PR #$ARGUMENTS. Follow your agent definition. Post nothing — return your findings.`
2. **`technical-writer`** with task: `Documentation pass for PR #$ARGUMENTS. Follow your default checklist. Output terse — either "✅ Documentation: no issues" or a short bulleted list with file:line references. Post nothing — return your findings.`

Combine findings in this order: light-reviewer output, then technical-writer output (only include the tech-writer block if it found issues; otherwise a single line `✅ Documentation: no issues`).

**Heredoc templates below are not literal strings.** The placeholders in angle brackets (`<rationale from step 1>`, `<combined findings>`, etc.) must be substituted with real values before running the `gh pr comment` command — the single-quoted heredoc only prevents shell expansion, not placeholder substitution.

Post the result as a PR comment with this header prefix:

```bash
gh pr comment $ARGUMENTS --body "$(cat <<'EOF'
**Triage: light** — <rationale from step 1>

<combined findings>
EOF
)"
```

Why two agents in light tier: the triage routes docs-only PRs to `light`, and docs PRs are exactly the case where temporal-language and REFERENCE/ currency checks matter most. Keeping `technical-writer` in this tier closes that gap without bloating the light-reviewer prompt with doc-specific rules.

**If `TIER: standard`:**

Follow the two-reviewer flow:

1. Spawn **`code-reviewer`** with its default task: `Conduct a comprehensive code review of PR #$ARGUMENTS. Follow your review checklist and output format. Post nothing — return your findings.`
2. Spawn **`technical-writer`** with: `Conduct a documentation review of PR #$ARGUMENTS. Follow your review checklist and output format. Post nothing — return your findings.`
3. Combine findings (code review first, documentation second). If the doc reviewer found nothing, `✅ Documentation: No issues found` is sufficient.
4. Post with this header prefix:

```
**Triage: standard** — <rationale from step 1>

<combined findings>
```

**If `TIER: team`:**

1. Emit one user-facing line in chat:

   ```
   Auto-escalating to team review. This takes 5–10 minutes. If you want to
   abort, try Ctrl-C; if that doesn't land cleanly, wait for the team review
   to finish (it posts to the PR regardless).
   ```

2. Post a **separate triage marker comment** to the PR *before* invoking the team skill (the team skill can't receive extra arguments, so the header is posted directly):

   ```bash
   gh pr comment $ARGUMENTS --body "$(cat <<'EOF'
   **Triage: team (auto-escalated)** — <rationale from step 1>

   *Flagged paths: <flagged_paths from step 1>*

   Full team review follows in the next comment.
   EOF
   )"
   ```

3. Invoke the `review-pr-team` skill using the Skill tool, passing the same PR number as `args`. That skill owns its own orchestration, team setup, discussion phase, and clean-up. Its review posts as a second, larger comment.

(The team skill is user-invocable on its own, so if you prefer to skip the dispatcher entirely, just run `/review-pr-team N` directly — no triage runs and no marker comment is posted.)

### Step 4: User summary

After posting, always end with a short summary in chat:

- **Tier that ran** and why (one line)
- **Issues found** (critical count / suggestions count)
- **Recommendation** (approve / request changes / block)
- **Link** to the posted PR comment
- If tier was `light` or `standard`: one-line reminder — *"Run `/review-pr-team N` if you want deeper multi-perspective analysis."*

---

## Override & escape hatches

| Situation | What to do |
|---|---|
| Want to skip triage entirely | Run `/review-pr-team N` directly |
| Triage chose wrong tier (too shallow) — caught during announce | Try Ctrl-C; if the interrupt doesn't land, let the current tier finish and then run `/review-pr-team N` — reviews stack fine |
| Triage flagged something unexpected | Read the rationale — if wrong, let Magnus know; the rubric lives in `.claude/agents/triage-reviewer.md` |
| Want a deeper look after a `light` or `standard` review | Run `/review-pr-team N` on the same PR — reviews stack fine |
| Triage output didn't parse / `gh` command failed | Dispatcher falls back to `team` tier automatically (see Step 1 fallback) |

---

## Example usage

```
/review-pr 42
```

The dispatcher will:
1. Classify risk — paths, size, secret-scan (~30 sec)
2. Announce the tier + rationale to you
3. Run the appropriate review
4. Post results with the triage decision visible in the comment header

---

## When to use which skill

- **`/review-pr N`** — default. The dispatcher picks the right tier automatically and explains why.
- **`/review-pr-team N`** — skip triage. Use when you *already know* the change is critical, or when a lighter tier surfaced something that needs deeper analysis.
