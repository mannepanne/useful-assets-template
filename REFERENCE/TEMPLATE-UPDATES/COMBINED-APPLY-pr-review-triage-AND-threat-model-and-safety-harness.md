# Combined apply prompt — PR review triage + threat model & safety harness

A single self-contained message to paste into a derivative project's Claude Code session that rolls out **both** of the following packets back-to-back, in order:

1. [`2026-04-pr-review-triage/`](./2026-04-pr-review-triage/) — tiered review dispatcher, `prReviewMode` opt-in, extracted `review-gate.md`.
2. [`2026-04-threat-model-and-safety-harness/`](./2026-04-threat-model-and-safety-harness/) — threat-model ADR, silent-review conventions, PreToolUse safety-harness hook.

## When to use this

- The derivative project has neither packet applied yet (typical for an older fork from before PR #13).
- You want a single paste rather than running the two packets' apply prompts separately.

## When NOT to use this

- The derivative project already has packet 1 applied. In that case, paste only the apply prompt from `2026-04-threat-model-and-safety-harness/README.md` — no need for the combined version.
- The derivative project has a contributor model that differs from the template's (open-source PRs from strangers, multi-team enterprise, regulated environment, junior developers as primary users). Use the individual packet READMEs and engage with the threat-model ADR's tightening checklist deliberately rather than running this combined flow.

## How to use it

1. Open Claude Code in the derivative project's directory (clean working tree).
2. Copy the entire fenced block below (including the outer code fences only as visual delimiters — paste the inner content).
3. Paste into the session and let Claude work through it. It will pause between packets so you can review and merge packet 1's PR before packet 2 starts.

## Notes for future maintenance

- If a third packet lands that should also be combined into this rollout, either extend this file (and rename it) or — better — create a new combined-apply file for the new pair/triple, leaving this one in place for projects that only need these two.
- If either underlying packet is superseded, mark this file with a `**Superseded by:** [link]` line at the top rather than deleting it. Derivative projects on older forks may still reference it.

## The combined apply prompt

```
I want to roll out two template improvements from `mannepanne/useful-assets-template` into
this project, in order. Each is a self-contained "migration packet" with its own README and
"Apply prompt". Run them as two sequential feature branches + PRs.

Source repo: https://github.com/mannepanne/useful-assets-template (branch: main)

How to fetch source files: WebFetch on the raw GitHub URL pattern

  https://raw.githubusercontent.com/mannepanne/useful-assets-template/main/<path>

Do NOT invent file contents — every source file must come from the raw URL above.

================================================================================
PACKET 1 — PR review triage system
================================================================================

Migration packet README:
  https://github.com/mannepanne/useful-assets-template/blob/main/REFERENCE/TEMPLATE-UPDATES/2026-04-pr-review-triage/README.md

Source PRs in mannepanne/useful-assets-template: #13, #14, #15, #16

Steps:

1. WebFetch the packet 1 README and read it end-to-end. The two ADRs it references are
   the best design-rationale context.
2. Create a feature branch (e.g. `feature/adopt-pr-review-triage`). Do NOT work on main.
3. For each file in "Copy verbatim", check whether a file at that path exists locally.
   If not, WebFetch the source and create it. If it does, treat as "merge carefully" and
   flag the conflict.
4. For each file in "Merge carefully", read the local version and WebFetch the source
   version. Identify the sections this rollout adds or modifies and propose a merged
   version that preserves any local customisation. Pay special attention to
   `.claude/CLAUDE.md` and `.claude/skills/review-pr/SKILL.md` — highest conflict surface.
5. For each "Conditional" file, evaluate the stated condition before deciding.
6. Before writing ANY changes, list every proposed edit with a one-line rationale and
   flag every place where local customisation could be lost. Wait for my confirmation.
7. After I confirm and you've applied the changes, run the packet's verification commands
   and report results.
8. Commit, push, open a PR, wait for me to merge it before continuing to packet 2.

================================================================================
PACKET 2 — Threat-model calibration, silent reviews, and safety-harness hook
================================================================================

(Only proceed once packet 1's PR is merged.)

Migration packet README:
  https://github.com/mannepanne/useful-assets-template/blob/main/REFERENCE/TEMPLATE-UPDATES/2026-04-threat-model-and-safety-harness/README.md

Source PRs in mannepanne/useful-assets-template: #18, #19, #21, #22, #23, #24, #25

Steps:

1. WebFetch the packet 2 README and read it end-to-end. The "Why" section is load-bearing
   — the threat model is the foundational assumption that calibrates everything downstream.

2. **BEFORE applying anything**, surface this question to me:

   "This packet's calibrations (severity defaults, safety-harness block/ask choices,
    PR-review tool grants) all assume a single trusted contributor or small team of
    mutually-trusted contributors. If this project's contributor model differs (open-
    source PRs from strangers, multi-team enterprise, regulated environments, junior
    developers as primary users), the threat-model ADR's tightening checklist applies
    before adopting the calibrations. Should I read the threat-model ADR and surface
    any calibration that should be tightened for this project, or proceed with the
    template defaults?"

   Wait for my answer before proceeding.

3. Create a feature branch (e.g. `feature/adopt-threat-model-and-safety-harness`).
   Do NOT work on main.

4. Apply the four sub-changes IN ORDER (see the packet's "Application order" section):
   a. TEMPLATE-UPDATES bootstrap — only if `REFERENCE/TEMPLATE-UPDATES/CLAUDE.md` does
      NOT already exist locally.
   b. Threat-model ADR + agent severity calibration.
   c. Silent-review conventions (Tool invocation conventions section, allowlist
      additions, triage patterns file rename, dispatcher fallback, WebFetch grants on
      spec-review agents).
   d. Safety harness.

5. For each "Copy verbatim" file, check existence; WebFetch + create if absent, treat as
   "merge carefully" if present.

6. For each "Merge carefully" entry, the manifest is section-level for the highest-
   conflict files (`.claude/agents/CLAUDE.md`, `.claude/settings.json`). Read the local
   version section-by-section, WebFetch source, identify what to add/replace, propose
   per-section merge. Do NOT treat `.claude/settings.json` as a single-file merge — its
   three deltas (env, permissions.allow, hooks.PreToolUse) must apply independently.

7. Triage patterns file rename: if the local file exists under the OLD name
   (`triage-secret-patterns.txt`), delete it and create the new name
   (`triage-scan-patterns.txt`). If neither exists, create the new name only.

8. `chmod +x` on these two .sh files immediately after WebFetching them. Raw GitHub URLs
   do not preserve the executable bit. Without this step, the hook silently fails:
   - `.claude/hooks/safety-harness.sh`
   - `.claude/hooks/tests/safety-harness/run-tests.sh`

9. The 39 fixture pairs (78 files) under `.claude/hooks/tests/safety-harness/fixtures/`:
   do NOT enumerate them in the apply plan. Use the GitHub tree API to list the
   directory once, then WebFetch each file:

     https://api.github.com/repos/mannepanne/useful-assets-template/git/trees/main?recursive=1

   Filter to entries with path prefix `.claude/hooks/tests/safety-harness/fixtures/`,
   fetch each via the raw URL pattern.

10. For "Conditional" files, evaluate the stated condition before deciding.

11. Excluded files — do NOT fetch even though they appear in the source PRs' diffs:
    - `SPECIFICATIONS/ARCHIVE/pretooluse-safety-harness.md`
    - `TEMPLATE-INSTRUCTIONS.md`

12. Before writing ANY changes, list every proposed edit with a one-line rationale and
    flag every place where local customisation could be lost. Wait for my confirmation.

13. After applying, run the packet's verification commands and report results. The
    test-suite check (`bash .claude/hooks/tests/safety-harness/run-tests.sh`) is the
    one that catches a partially-applied hook — `test -f` and `grep -q` checks are
    necessary but not sufficient.

14. Commit, push, open a PR.

================================================================================
GROUND RULES (BOTH PACKETS)
================================================================================

- NEVER work on main. Feature branch + PR per packet, always.
- NEVER invent file contents — always WebFetch from the raw URL.
- Always diff before overwriting; flag local customisation that could be lost and wait
  for my confirmation before writing.
- If a step in a packet's apply prompt conflicts with the local project's own CLAUDE.md
  rules, stop and ask — don't silently choose one.
- Stop and report between packet 1 and packet 2 — don't run them back-to-back without
  giving me a chance to merge packet 1's PR first.
```
