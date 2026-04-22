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
| **light** | One reviewer, narrow scope | Docs, tests, styling, comment-only changes | ~1 min |
| **standard** | Code review + documentation review | Typical feature work, core logic, utilities | ~2–4 min |
| **team** | Multi-perspective team (security, product, architect, docs) with debate | Data layer (Supabase migrations, RLS), auth, CI, dependencies, secrets | ~5–10 min |

Team is auto-selected when the change touches high-blast-radius paths. You can always force team directly with `/review-pr-team N`.

---

## Instructions for Claude

When invoked with a PR number (e.g. `/review-pr 42`):

### Step 1: Triage

Spawn the **`triage-reviewer`** subagent:

**Task:** `Classify PR #$ARGUMENTS for review tier. Follow your rubric and output format exactly. Return only the classification block.`

Wait for the classification. It will be a four-line block: `TIER:`, `RATIONALE:`, `FLAGGED_PATHS:`, `SIZE:`.

### Step 2: Announce the decision (before running the review)

**CRITICAL:** Tell the user the decision in plain language *before* spawning any reviewer. This lets them catch a mis-triage early instead of paying for a wrong-tier review.

Use this format:

```
🎯 Triage: <tier>
   <rationale>
   <size>

Running <tier> review now.
If this looks wrong — e.g. the change is riskier than the rationale suggests —
interrupt and run /review-pr-team <N> to force the deepest tier.
```

Example:

```
🎯 Triage: light
   Docs-only change in REFERENCE/ with no code paths touched.
   Small (23 lines across 2 files)

Running light review now.
If this looks wrong — e.g. the change is riskier than the rationale suggests —
interrupt and run /review-pr-team 42 to force the deepest tier.
```

### Step 3: Route to the right reviewer

**If `TIER: light`:**

Spawn the **`code-reviewer`** subagent with this *narrowed* task (the narrowing is the whole point of the light tier — don't send the default prompt):

**Task:**
```
LIGHT TIER REVIEW of PR #$ARGUMENTS.

**IMPORTANT — this is a light tier review. Override your default review
protocol as follows:**
- DO NOT run your "Completion Requirements Verification" step
- DO NOT flag missing tests or low coverage as critical issues
- DO NOT produce the standard ✅/🔴/⚠️/💡 structured output
- The triage reviewer has already confirmed this PR is low-risk
  (docs / tests / styling / comments only). Trust that classification.

Focus ONLY on:
- Obvious bugs or broken logic
- Typos or factual errors in code, comments, or docs
- Accidentally committed debug statements, console.logs, or secret-shaped strings
- Broken links or stale refs in docs
- ABOUT headers present on any NEW code files

Skip: architecture critique, performance analysis, test coverage gaps,
style nits, threat modelling, deep security review, completion-requirements
checklist.

Output: terse. Either the single line "✅ No issues" or 1–3 specific
comments with file:line references. Do not write long-form analysis,
headings, or structured sections. Post nothing — return your findings.
```

Then post the result as a PR comment with this header prefix:

```bash
gh pr comment $ARGUMENTS --body "$(cat <<'EOF'
**Triage: light** — <rationale from step 1>

<reviewer findings>
EOF
)"
```

No technical-writer pass in the light tier — the narrowed code reviewer already covers doc basics.

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
   Auto-escalating to team review. This takes 5–10 minutes. You can cancel
   any time with Ctrl-C and run /review-pr-team <N> separately.
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
| Triage chose wrong tier (too shallow) | Interrupt during Step 2 and run `/review-pr-team N` |
| Triage flagged something unexpected | Read the rationale — if wrong, let Magnus know; the rubric lives in `.claude/agents/triage-reviewer.md` |
| Want a deeper look after a `light` or `standard` review | Run `/review-pr-team N` on the same PR — reviews stack fine |

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
