# Threat-model calibration, silent reviews, and PreToolUse safety-harness

**Status:** Active
**Authoritative source:**
- [PR #18 — Add TEMPLATE-UPDATES migration packet system](https://github.com/mannepanne/useful-assets-template/pull/18)
- [PR #19 — Calibrate triage-reviewer for solo-trusted-contributor threat model](https://github.com/mannepanne/useful-assets-template/pull/19)
- [PR #21 — Recalibrate reviewer-agent severity defaults against threat-model ADR](https://github.com/mannepanne/useful-assets-template/pull/21)
- [PR #22 — Replace dispatcher rm -f with Read-then-Write fallback](https://github.com/mannepanne/useful-assets-template/pull/22)
- [PR #23 — Add safety-harness spec + threat-model ADR sub-case](https://github.com/mannepanne/useful-assets-template/pull/23)
- [PR #24 — Implement PreToolUse safety-harness hook (block/ask tiers)](https://github.com/mannepanne/useful-assets-template/pull/24)
- [PR #25 — Steer reviewer agents toward silent built-in tools](https://github.com/mannepanne/useful-assets-template/pull/25)
- Also rolled in: standalone commits `e3521c7`, `4813aad`, `f6050b2`, `db5f200` (silence + threat-model groundwork that landed between PRs 18 and 19)

---

## Why

A coherent set of improvements landed across PRs 18–25 that together shift the review system from a fixed "worst-case attacker" stance to a calibrated, threat-model-driven one — with the operational consequences that follow. Three things are easier to understand together than separately, so this packet rolls them up:

1. **A documented threat model.** Reviewer agents previously rated severity against an implicit "all attackers including malicious committers" stance, producing theoretical-RCE findings that didn't apply to the actual contributor model (solo trusted contributor, or small team of mutually-trusted contributors). The threat-model ADR makes that calibration explicit, and the reviewer agents now read against it.
2. **Silent reviews.** Many small frictions added up to a `/review-pr` or `/review-spec` run that prompted the human for manual approval throughout — unnecessary `git -C` forms, pipe-compounds the matcher couldn't allowlist, secret-shape regex on the command line, reviewers reaching for `curl` and `python3 -c` when built-in tools were silent. Cumulative fix: a Tool invocation conventions section in `.claude/agents/CLAUDE.md`, allowlist tuning in `.claude/settings.json`, a triage-reviewer patterns file split, the dispatcher's Read-then-Write fallback, and `WebFetch` granted to spec-review agents only.
3. **A PreToolUse safety-harness hook.** A two-tier (block/ask) hook script that intercepts genuinely destructive Bash commands before the shell sees them. Calibrated for the *less-experienced-user* sub-case in the threat model (the threat-model ADR has an addendum for this) — block tier catches one-way doors against personal data (`rm -rf` against root/home/`$HOME`, `dd of=/dev/disk*`, `mkfs * /dev/disk*`, `diskutil eraseDisk`, SQL `DROP TABLE/DATABASE/SCHEMA`, `gh repo delete`); ask tier surfaces a permission dialog with educational reason for `git reset --hard`, `git push --force` to non-main, `chmod 777`. Comes with a 32-test fixture-based test suite and an inline `SAFETY_HARNESS_OFF=1` bypass.

Plus one bootstrap dependency: **PR #18 introduced the TEMPLATE-UPDATES packet system itself.** Derivative projects on the previous packet (`2026-04-pr-review-triage`) won't have it, and they need it before they can apply this packet's manifest cleanly. Apply the bootstrap first.

> **⚠️ Read this before adopting any calibration downstream.** The threat-model ADR at `REFERENCE/decisions/2026-04-25-pr-review-threat-model.md` is the load-bearing assumption. **Most derivative projects do not have the template's exact contributor model.** The severity defaults, the safety-harness block/ask choices, and the decision to withhold `WebFetch` from PR-review agents all depend on that calibration. If your project's contributor model differs (open-source PRs from strangers, multi-team enterprise, regulated environments, junior developers as primary users), follow the ADR's *tightening checklist* before adopting downstream changes — otherwise you ship the template's defaults into a project that needs different ones. The receiving Claude must surface this question before applying anything in the manifest.

## What changed

- **New ADR + sub-case:** `REFERENCE/decisions/2026-04-25-pr-review-threat-model.md` documents the in-scope/out-of-scope split for severity calibration and includes a less-experienced-user sub-case that justifies the safety-harness defaults.
- **Reviewer-agent severity recalibration:** `security-specialist` and `triage-reviewer` no longer flag malicious-committer attacks as blockers; they note them as "out-of-scope per threat model" with a one-line pointer.
- **Tool invocation conventions:** new section in `.claude/agents/CLAUDE.md` that steers reviewer agents toward built-in tools (`Read`, `Glob`, `Grep`, `WebFetch`) over shell equivalents (`cat`, `find`/`ls`, `grep`, `curl`, `python3 -c`). Top-line principle: built-ins are silent and bounded; shell forms prompt and are unbounded.
- **Tool grant asymmetry:** spec-review agents (`technical-skeptic`, `requirements-auditor`, `devils-advocate`) gain `WebFetch` for verifying claims against authoritative external docs. PR-review agents do NOT — their substrate is local (code, PR content) and a PR description containing an attacker-controlled URL would otherwise be a fetch target. The asymmetry is documented to prevent future "harmonization" reverts.
- **Triage patterns file rename:** `.claude/agents/triage-secret-patterns.txt` → `.claude/agents/triage-scan-patterns.txt`. The file is loaded via `grep -E -f` to keep the regex off the command line (the Claude Code permission validator was misreading `{N,}` quantifiers as brace expansion). Receiving projects on the previous packet may have neither; receiving projects mid-rename may have the old name.
- **Dispatcher Read-then-Write fallback:** `/review-pr` and `/review-pr-team` no longer use `rm -f /tmp/...` to clear stale temp files (which prompted because `rm` isn't allowlisted). They Read first, then Write — silent under default permissions.
- **Project-relative scratch directory:** review skills write their intermediate comment-body files to a top-level `SCRATCH/` directory rather than `/tmp/`. The directory contents are gitignored (`*\n!.gitignore` inside `SCRATCH/.gitignore`). For `Read`, the allow-list rule `Read(/SCRATCH/*)` works as documented — the leading-`/` is project-root-relative and the matcher honours it. For `Write`, the allow-list rule `Write(/SCRATCH/*)` does **not** silence the prompt across five fresh-session sightings — the upstream `Write` matcher gates beyond the allow-list. The supported path is the `PreToolUse` hook bundled in the *companion packet* (see "Companion packet" below). Derivative projects on an earlier draft of this packet that committed `Write(/SCRATCH/*)` (or any of `Write(/SCRATCH/**)`, `Write(SCRATCH/*)`, `Write(SCRATCH/**)`) should remove all four — they are dead code — and adopt the hook from the companion packet instead. Sidesteps two distinct problems: (1) an intermittent matcher quirk where absolute `/tmp/...` paths were sometimes displayed in `../../../../../../tmp/...` traversal form and failed allow-list matching (see `SPECIFICATIONS/ARCHIVE/INVESTIGATION-claude-code-write-path-normalisation.md`); and (2) a settings-self-modification approval gate that fires on any Write under `.claude/`, regardless of allowlist entries — which is why the directory lives at the repo root rather than inside `.claude/`. Root cause of (1) unresolved upstream; the symptom is now silenced by the SCRATCH-write hook rather than the allow-list.

> **Companion packet for the SCRATCH-write hook.** This packet's allow-list-only approach to silencing SCRATCH/ Write prompts is empirically incomplete. A follow-up packet will carry `.claude/hooks/approve-scratch-write.sh`, the shared parse helper at `.claude/hooks/lib/parse-tool-input.sh`, the test suite at `.claude/hooks/tests/approve-scratch-write/`, and the `hooks.PreToolUse[1]` entry that registers the hook. Until that packet lands, derivative projects can either (a) accept the SCRATCH/ Write prompt, or (b) copy the hook + registration + parse helper directly from the template's main branch. The decision rationale is at [`REFERENCE/decisions/2026-04-26-scratch-write-pretooluse-hook.md`](https://github.com/mannepanne/useful-assets-template/blob/main/REFERENCE/decisions/2026-04-26-scratch-write-pretooluse-hook.md); operations at [`REFERENCE/scratch-write-hook.md`](https://github.com/mannepanne/useful-assets-template/blob/main/REFERENCE/scratch-write-hook.md).
- **PreToolUse safety-harness hook:** new `.claude/hooks/safety-harness.sh` script + 39-fixture test suite at `.claude/hooks/tests/safety-harness/`. Registered in `.claude/settings.json` under `hooks.PreToolUse` with an `if`-filter alternation to keep the script invocation cheap. Inline `SAFETY_HARNESS_OFF=1 <cmd>` bypass works because the script checks the command string explicitly (the env var alone wouldn't propagate — Claude Code spawns the hook before the command shell).
- **Reference doc:** `REFERENCE/safety-harness.md` describes block-tier / ask-tier / what's not caught / how to bypass / how to extend patterns.
- **Allowlist tuning** in `.claude/settings.json` for git-pipe forms, `git fetch`, `Write(/SCRATCH/*)`, `Read(/SCRATCH/*)`, etc.
- **TEMPLATE-UPDATES packet system itself:** `REFERENCE/TEMPLATE-UPDATES/CLAUDE.md` (index + author/apply guide) and `TEMPLATE.md` (skeleton) — the system that lets future packets like this one be applied cleanly.

For the full design rationale, the threat-model ADR is the single most useful starting point. The PR descriptions linked above carry the per-change specifics.

## Application order

The sub-changes have dependencies. Apply in this order:

1. **TEMPLATE-UPDATES bootstrap** (PR #18) — without it, the packet system this README is part of doesn't exist locally.
2. **Threat-model ADR + agent severity calibration** (commits `4813aad`, PR #19, PR #21) — every other calibration in this packet refers back to this ADR. If a derivative project edits the ADR to fit a different contributor model, that edit must land first; downstream calibrations follow.
3. **Silent-review conventions** (commits `e3521c7`, `f6050b2`, `db5f200`, PR #22, PR #25) — Tool invocation conventions section, allowlist additions, triage patterns file rename, dispatcher Read-then-Write fallback, WebFetch grants on spec-review agents.
4. **Safety harness** (PR #23 ADR sub-case, PR #24 implementation) — independent of the silent-review work, can apply last. The `chmod +x` step (see below) is essential.

## File manifest

### Copy verbatim

Files that did not exist before this rollout. Add them as-is unless a same-named file already exists locally (in which case treat as *merge carefully* and flag the conflict).

**Threat-model ADR**
- `REFERENCE/decisions/2026-04-25-pr-review-threat-model.md` — the threat-model ADR with less-experienced-user sub-case

**Allow-list pinning principle ADR**
- `REFERENCE/decisions/2026-04-26-allowlist-pinning-principle.md` — companion to the threat-model ADR; the granularity rule for individual `permissions.allow` entries (subcommand-pin for code-eval-capable binaries, binary-level for pure data transformers). Read this before adding new tooling rules to a derivative project's settings.json.

**Scratch directory placeholder**
- `SCRATCH/.gitignore` — single file, two lines (`*\n!.gitignore`). Keeps the directory tracked but ignores all contents. Review skills write their intermediate comment-body files here; the gitignored contents mean artefacts don't leak into commits. Without this file, the directory wouldn't exist in fresh clones and the first Write would have to create the parent. The directory lives at the repo root (not inside `.claude/`) because Writes under `.claude/` trigger Claude Code's settings-self-modification approval gate regardless of allowlist entries.

**TEMPLATE-UPDATES bootstrap (only if absent locally — projects that already applied a previous packet via this system will have these)**
- `REFERENCE/TEMPLATE-UPDATES/CLAUDE.md` — index + author/apply guide
- `REFERENCE/TEMPLATE-UPDATES/TEMPLATE.md` — skeleton for new packets

**Triage patterns file** (RENAMED — see "Easy-to-miss mechanics" below)
- `.claude/agents/triage-scan-patterns.txt` — secret-shape patterns, loaded via `grep -E -f` to keep regex off the command line. **Note:** the previous packet (`2026-04-pr-review-triage`) now also ships this file, so projects that adopted that packet first will already have it. Skip this entry if the file is already present locally.

**Safety-harness implementation**
- `.claude/hooks/safety-harness.sh` — the hook script (**must `chmod +x` after fetch**)
- `.claude/hooks/tests/safety-harness/run-tests.sh` — fixture runner (**must `chmod +x` after fetch**)
- `.claude/hooks/tests/safety-harness/fixtures/` — 39 fixture pairs (78 files: `*.in.json` + `*.expected.json`). See "Easy-to-miss mechanics" for how to fetch a directory rather than enumerating files.
- `REFERENCE/safety-harness.md` — how-it-works doc (block/ask tiers, what's not caught, bypass mechanics, extension guide)

### Merge carefully

Files that almost certainly exist in the target project but with different content. The receiving Claude must read the local version, identify the section(s) added/changed by this packet, and merge — preserving local customisation elsewhere.

**`.claude/agents/CLAUDE.md` — multiple distinct sections**

This file accumulates four sections across the rolled-up PRs. Treat each as an independent merge:

- **Severity calibration** (heading: `### Severity calibration`) — added by commit `4813aad`. Adds a paragraph and bullet list pointing at the threat-model ADR. If absent locally, add the section. If present with locally-customised wording, keep the local wording but verify it points at the threat-model ADR path.
- **Tool invocation conventions** (heading: `### Tool invocation conventions`) — final form added in PR #25 (subsumes earlier "Bash invocation conventions" content from commits `f6050b2`, `db5f200`). If the local file has the older "Bash invocation conventions" section, replace it wholesale with the broader "Tool invocation conventions" section. If absent, add. The table inside is the source of truth.
- **Tool grant asymmetry** (heading: `#### Tool grant asymmetry`) — added by PR #25. Sub-section under "Tool invocation conventions". If absent, add.
- **Untrusted-content scope when fetching** (heading: `#### Untrusted-content scope when fetching`) — added by PR #25. Sub-section under "Tool invocation conventions". If absent, add.

**`.claude/settings.json` — three independent deltas**

Don't treat this file as a single merge. Apply each delta independently:

- **`env.CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS = "1"`** — already required by the previous packet (`2026-04-pr-review-triage`); it's listed here only because it appears in the source file. **If already present locally with the same value, no change.** If absent, add.
- **`permissions.allow` additions** — multiple new entries across two thematic groups, plus a `_comment` field describing the threat-model assumption:
  - **Review-tooling entries** (the silent-reviews work): `Bash(git fetch *)`, `Bash(git -C * log/show/diff/status *)`, `Bash(git show * | sed -n *)` and the related git-pipe siblings, `Bash(gh pr diff * | grep *)`, `Read(/SCRATCH/*)`. The `Read` rule covers any review skill reading intermediate files in the top-level `SCRATCH/` directory (gitignored contents); the leading `/` is project-root-relative in the Claude Code permission grammar. **Do NOT add `Write(/SCRATCH/*)` (or any of `Write(/SCRATCH/**)`, `Write(SCRATCH/*)`, `Write(SCRATCH/**)`)** — the upstream `Write` matcher empirically does not honour these entries across five fresh-session sightings. Silencing the SCRATCH/ Write prompt is the job of the `PreToolUse` hook described in the companion packet (see the "Companion packet" callout in *What changed*). Older versions of this packet pinned to `/tmp/review-pr-*` and `/tmp/spec-review-*` — derivative projects upgrading from the older form should swap those `/tmp` rules for the single `Read(/SCRATCH/*)` rule and add `SCRATCH/.gitignore`. Projects upgrading from an earlier draft of THIS packet that committed `Write(/SCRATCH/*)` (or any of the four glob shapes) should remove all four — they are dead code. An even-earlier intermediate shape used `.claude/scratch/*`; that form triggered Claude Code's settings-self-modification approval prompt on every Write and was abandoned for the repo-root location.
  - **Test / typecheck / lint entries** (silent test runs across common JS/TS toolchains). Two shape families, both needed:
    - **Plain prefix forms:** `Bash(npm test:*)`, `Bash(npm run test:*)`, `Bash(npm run typecheck:*)`, `Bash(npm run lint:*)`, `Bash(bun test:*)`, `Bash(bun run test:*)`, `Bash(bun run typecheck:*)`, `Bash(bun run lint:*)`, `Bash(node_modules/.bin/vitest:*)`, `Bash(node_modules/.bin/jest:*)`, `Bash(node_modules/.bin/tsc:*)`, `Bash(npx vitest:*)`, `Bash(npx tsc:*)`.
    - **Pipe-aware forms** for common output-truncation patterns Claude reaches for (`| tail -<n>`, `| head -<n>`, `| grep <pattern>`): `Bash(npm test * | tail/head/grep *)`, `Bash(npm run test * | tail/head/grep *)`, `Bash(npm run typecheck * | tail *)`, `Bash(npm run lint * | tail *)`, `Bash(bun run test * | tail/head/grep *)`, `Bash(bun run typecheck * | tail *)`, `Bash(bun run lint * | tail *)`, `Bash(node_modules/.bin/vitest * | tail/head/grep *)`, `Bash(node_modules/.bin/jest * | tail *)`, `Bash(node_modules/.bin/tsc * | tail *)`, `Bash(npx vitest * | tail *)`, `Bash(npx tsc * | tail *)`. The pipe variants are **necessary**, not redundant — the permission matcher checks the full compound command against the pattern, so `Bash(node_modules/.bin/vitest:*)` alone won't silence `vitest run X 2>&1 | tail -30`. The same reason the manifest's git-pipe rules (`Bash(git show * | tail *)` etc) exist as siblings of `Bash(git -C * show *)`.
    - The set is broad on purpose (npm + bun + raw binaries + npx) so it works regardless of which package manager the receiving project uses; entries that don't apply to the local toolchain are harmless no-ops. If a derivative project's existing settings have narrow exact-match forms like `Bash(bun run test)`, it's safe to leave them — but broadening to `:*` form silences flag variants like `--watch` and `--coverage`.
  - **Validation tooling entries** (silent JSON syntax checks and field extraction Claude reaches for after editing settings/config files). The granularity choices below follow the **allow-list pinning principle** ADR (`REFERENCE/decisions/2026-04-26-allowlist-pinning-principle.md`) — read it before adding more tooling rules:
    - **`python3 -m json.tool` (pinned narrowly):** `Bash(python3 -m json.tool:*)`, `Bash(python3 -m json.tool * > /dev/null)`, `Bash(python3 -m json.tool * > /dev/null && echo *)`, `Bash(python3 -m json.tool * && echo *)`. The risk is the binary, not the module — `Bash(python3:*)` or `Bash(python3 -m *)` would silently allow `python3 -c "import os; os.system(...)"` (full arbitrary code execution) and any other Python module. Pin to the specific subcommand only.
    - **`jq` (binary-level allow):** `Bash(jq:*)` plus pipe siblings `Bash(jq * | tail *)`, `Bash(jq * | head *)`, `Bash(jq * | grep *)`. **Different risk profile from Python** — `jq` has no escape hatch to arbitrary code execution: no `-c`-equivalent, no shell-out, no module imports, no file writes. It's a pure JSON-in / JSON-out transformer. So binary-level allow at `Bash(jq:*)` is genuinely safe; the pipe siblings cover jq-as-source patterns. (jq-as-sink — `<command> | jq *` — is intentionally NOT allow-listed broadly: the matcher checks the full compound, so `Bash(* | jq *)` would smuggle in any source command. Add narrow source-piped-to-jq rules only as specific sources surface as pain points.)
    - **`grep` (binary-level allow + semicolon-echo sibling):** `Bash(grep:*)` plus `Bash(grep * ; echo *)`. Same pinning-ADR rationale as `jq` — `grep` is a pure data transformer with no code-eval, no shell-out, no file writes. Binary-level allow is safe. The semicolon-echo sibling silences the `grep ... ; echo "exit=$?"` workaround pattern (used to disambiguate "no matches" from "error" since `grep` exits 1 when the pattern doesn't match, which the shell treats as a failure).
  - Append entries that are absent locally; do not deduplicate or reorder existing local entries. The `_comment` is a no-op key for documentation purposes — fine to add.
- **`hooks.PreToolUse` block** — new top-level `hooks` key with the `PreToolUse` array containing the Bash matcher, the `if`-filter alternation (`rm * | dd * | mkfs* | diskutil* | git push * | git reset * | gh repo * | psql * | supabase * | chmod *`), and the command pointing at `$CLAUDE_PROJECT_DIR/.claude/hooks/safety-harness.sh`. If `hooks.PreToolUse` is absent, add the whole block. If present with other entries, append the safety-harness entry as an additional array element. **Do not overwrite local hook entries.**

**`.claude/agents/triage-reviewer.md`**
- Adopted across PRs #19, `f6050b2`, and PR #21. Three changes: (1) reads patterns from the patterns file via `grep -E -f` rather than inline regex; (2) gained a one-line note explaining its rubric doesn't need recalibration (path-based HIGH triggers are runtime concerns); (3) fail-closed contract escalates to `team` tier when the patterns file is missing or unreadable. If the local file is the older form (inline secret regex on the command line), replace wholesale and verify nothing project-specific was added.

**`.claude/agents/security-specialist.md`**
- Recalibrated by PR #21. Gained a `Threat model` section after Role and a recalibrated `Review Standards` block. Merge by adding the `Threat model` section if absent and reconciling `Review Standards` — keep local-specific stack notes, fold in the threat-model-aware language.

**`.claude/agents/devils-advocate.md`, `.claude/agents/requirements-auditor.md`, `.claude/agents/technical-skeptic.md`**
- All three gained `WebFetch` in their `tools:` frontmatter via PR #25. Single-line change per file: change `tools: Bash, Read, Glob, Grep` to `tools: Bash, Read, Glob, Grep, WebFetch`. If the local frontmatter already lists `WebFetch`, no change.

**`.claude/skills/review-pr/SKILL.md` and `.claude/skills/review-pr-team/SKILL.md`**
- PR #22 added a Read-then-Write fallback paragraph to both files, removing the need for `rm -f /tmp/...` cleanup. The paragraph appears under the "Posting the comment" section in `review-pr/SKILL.md` and the equivalent in `review-pr-team/SKILL.md`. The skill text now references `SCRATCH/review-pr-...` paths (not `/tmp/review-pr-...`) — derivative projects upgrading from an earlier shape of this packet should sweep the skill files for any remaining `/tmp/` or `.claude/scratch/` paths and replace with `SCRATCH/`. If the local skill files don't have this paragraph, add it. If they have a different stale-file workaround (e.g. `rm -f`), replace it with the Read-then-Write text.

**`.claude/skills/review-spec/SKILL.md`**
- PR #25 changed the spec-resolution step from `find SPECIFICATIONS/...` to using the `Glob` tool. Replace the bash code block + surrounding sentence with the Glob-based instruction. Localised wording around it can stay as-is.

**`REFERENCE/CLAUDE.md`**
- Index entry for `safety-harness.md` (PR #24). Add a single section under "Files in this directory" pointing at the new doc, in alphabetical/topical order alongside existing entries.

**`REFERENCE/decisions/CLAUDE.md`**
- Index entry for the threat-model ADR. Add a one-line entry referencing `2026-04-25-pr-review-threat-model.md`.

**`SPECIFICATIONS/ARCHIVE/CLAUDE.md`**
- PR #23 added a "Link convention for archived specs" rule. Apply only if the project uses the `SPECIFICATIONS/ARCHIVE/` pattern. The rule is short and self-contained — append it.

### Conditional

Files that may or may not be relevant depending on whether the target project has related infrastructure.

- **`.gitignore`** — apply only if not already covered by a previous packet. The relevant entries are `.claude/project-config.local.json` (from the previous packet) — no new gitignore entries are introduced by this rollup.
- **`README.md` (project root)** — minor updates only if the project's README references the older review behaviour. Most derivative projects will not need this.
- **`.claude/CLAUDE.md` — Severity calibration cross-reference** — verify there's a one-line pointer at the threat-model ADR somewhere in the file (the existing review-system section is a good location). If absent, add. Localised collaboration content stays as-is.

## Excluded by design — do NOT copy these even though they appear in the source PRs' diffs

- `SPECIFICATIONS/ARCHIVE/pretooluse-safety-harness.md` — template-internal historical spec record (the implementation is what matters; the spec is preserved for the template's own audit trail)
- `TEMPLATE-FOLLOWUPS.md` — template-internal tracker for forward-looking improvements; derivative projects track their own follow-ups elsewhere
- `TEMPLATE-INSTRUCTIONS.md` — template-internal bootstrap doc; derivative projects either delete it after first clone or have their own version

## Apply prompt

> Copy the block below into the receiving project's Claude session. It is self-contained — the receiving Claude won't see this packet's surrounding context.

```
I want to roll out a template improvement to this project: threat-model calibration,
silent reviews, and a PreToolUse safety-harness. The migration packet README is at:

  https://github.com/mannepanne/useful-assets-template/blob/main/REFERENCE/TEMPLATE-UPDATES/2026-04-threat-model-and-safety-harness/README.md

Source PRs: #18, #19, #21, #22, #23, #24, #25 in mannepanne/useful-assets-template.

How to fetch source files: use WebFetch on the raw GitHub URL pattern

  https://raw.githubusercontent.com/mannepanne/useful-assets-template/main/<path>

substituting <path> for any file listed in the manifest. Do NOT invent file contents —
every source file must come from the raw URL above.

For the 39 test-fixture pairs (78 files) under .claude/hooks/tests/safety-harness/fixtures/:
do NOT enumerate them in the apply plan. Use the GitHub tree API to list the directory
once, then WebFetch each file:

  https://api.github.com/repos/mannepanne/useful-assets-template/git/trees/main?recursive=1

filter the response to entries with path prefix
".claude/hooks/tests/safety-harness/fixtures/", and fetch each via the raw URL pattern.

Please:

1. WebFetch the packet README first and read it end-to-end. The "Why" section is
   load-bearing — the threat model is the foundational assumption that calibrates
   everything downstream.

2. **BEFORE applying anything**, surface this question to the user:

   "This packet's calibrations (severity defaults, safety-harness block/ask choices,
   PR-review tool grants) all assume a single trusted contributor or small team of
   mutually-trusted contributors. If this project's contributor model differs (open-
   source PRs from strangers, multi-team enterprise, regulated environments, junior
   developers as primary users), the threat-model ADR's tightening checklist applies
   before adopting the calibrations. Should I read the threat-model ADR and surface
   any calibration that should be tightened for this project, or proceed with the
   template defaults?"

   Wait for an answer before proceeding.

3. Create a feature branch (e.g. feature/adopt-threat-model-and-safety-harness).
   Do NOT work on main.

4. Apply the four sub-changes IN ORDER (the README's "Application order" section
   describes dependencies):

   a. TEMPLATE-UPDATES bootstrap — only if REFERENCE/TEMPLATE-UPDATES/CLAUDE.md
      doesn't already exist locally.
   b. Threat-model ADR + agent severity calibration.
   c. Silent-review conventions (Tool invocation conventions section, allowlist
      additions, triage patterns file rename, dispatcher fallback, WebFetch grants
      on spec-review agents).
   d. Safety harness.

5. **For each "Copy verbatim" file**, check whether a file at that path exists locally.
   If not, WebFetch the source and create it. If it does, treat as "merge carefully"
   instead and flag the conflict.

6. **For each "Merge carefully" entry**, the manifest is section-level for the
   highest-conflict files (.claude/agents/CLAUDE.md, .claude/settings.json). Read the
   local version section-by-section, WebFetch the source, identify what to add/replace,
   and propose a per-section merge. Do NOT treat .claude/settings.json as a single-file
   merge — its three deltas (env, permissions.allow, hooks.PreToolUse) must be applied
   independently.

7. **For triage-secret-patterns.txt → triage-scan-patterns.txt rename**: if the local
   file exists under the OLD name, delete it and create the new name. If neither exists,
   create the new name.

8. **chmod +x** on the two .sh files after fetching:
   - .claude/hooks/safety-harness.sh
   - .claude/hooks/tests/safety-harness/run-tests.sh
   Raw GitHub URLs do not preserve the executable bit. Without this step, the hook
   script will not run and the test runner will fail.

9. **For "Conditional" files**, evaluate the stated condition before deciding.

10. **Excluded files**: do NOT fetch SPECIFICATIONS/ARCHIVE/pretooluse-safety-harness.md,
    TEMPLATE-FOLLOWUPS.md, or TEMPLATE-INSTRUCTIONS.md even though they appear in the
    source PRs' diffs. They are template-internal.

11. **Before writing ANY changes**, list every proposed edit with a one-line rationale,
    and flag every place where local customisation could be lost. Wait for user
    confirmation.

12. **After applying, run the verification commands from the packet** and report results.
    The test-suite check (bash .claude/hooks/tests/safety-harness/run-tests.sh) is the
    one that catches a partially-applied hook — all the test -f and grep -q checks
    are necessary but not sufficient.
```

## Verification

Run each command below and report results. Most should exit 0; the test-suite run should exit 0 with all 40 tests passing.

```bash
# Stage 1: TEMPLATE-UPDATES bootstrap (skip if already had it)
test -f REFERENCE/TEMPLATE-UPDATES/CLAUDE.md
test -f REFERENCE/TEMPLATE-UPDATES/TEMPLATE.md

# Stage 2: Threat-model ADR + calibration
test -f REFERENCE/decisions/2026-04-25-pr-review-threat-model.md
grep -q '2026-04-25-pr-review-threat-model' REFERENCE/decisions/CLAUDE.md
test -f REFERENCE/decisions/2026-04-26-allowlist-pinning-principle.md
grep -q '2026-04-26-allowlist-pinning-principle' REFERENCE/decisions/CLAUDE.md
grep -q 'Severity calibration' .claude/agents/CLAUDE.md
grep -q 'threat-model' .claude/agents/security-specialist.md

# Stage 3: Silent reviews
grep -q 'Tool invocation conventions' .claude/agents/CLAUDE.md
grep -q 'Tool grant asymmetry' .claude/agents/CLAUDE.md
grep -q 'WebFetch' .claude/agents/technical-skeptic.md
grep -q 'WebFetch' .claude/agents/requirements-auditor.md
grep -q 'WebFetch' .claude/agents/devils-advocate.md
test -f .claude/agents/triage-scan-patterns.txt
test ! -f .claude/agents/triage-secret-patterns.txt   # old name must be gone
grep -q 'grep -E -f' .claude/agents/triage-reviewer.md
grep -q 'Read-then-Write' .claude/skills/review-pr/SKILL.md
grep -q 'Read-then-Write' .claude/skills/review-pr-team/SKILL.md
grep -q 'Glob' .claude/skills/review-spec/SKILL.md
grep -q 'Bash(git fetch \*)' .claude/settings.json
grep -q 'Bash(npm test:\*)' .claude/settings.json       # test/lint/typecheck allow-list applied
grep -q 'Bash(node_modules/.bin/vitest:\*)' .claude/settings.json
grep -q 'Bash(python3 -m json.tool:\*)' .claude/settings.json   # JSON-validation allow-list applied
grep -q 'Bash(jq:\*)' .claude/settings.json                     # jq allow-list applied
grep -q 'Bash(grep:\*)' .claude/settings.json                   # bare grep allow-list applied
test -f SCRATCH/.gitignore                                      # scratch dir present
grep -q 'SCRATCH/' .claude/settings.json                        # scratch allow-list applied
grep -q 'SCRATCH/' .claude/skills/review-pr/SKILL.md            # review skills point at scratch dir
grep -q 'SCRATCH/' .claude/skills/review-pr-team/SKILL.md

# Stage 4: Safety harness
test -x .claude/hooks/safety-harness.sh                # chmod +x landed
test -x .claude/hooks/tests/safety-harness/run-tests.sh
test -f REFERENCE/safety-harness.md
grep -q 'safety-harness' REFERENCE/CLAUDE.md
grep -q 'PreToolUse' .claude/settings.json
grep -q 'safety-harness.sh' .claude/settings.json

# Fixture count: 39 pairs = 78 files
test "$(ls .claude/hooks/tests/safety-harness/fixtures/*.in.json 2>/dev/null | wc -l)" -eq 39
test "$(ls .claude/hooks/tests/safety-harness/fixtures/*.expected.json 2>/dev/null | wc -l)" -eq 39

# The single check that catches a partial rollout: run the test suite end-to-end
bash .claude/hooks/tests/safety-harness/run-tests.sh
```

Manual checks (can't be scripted):

- Run `/review-spec` once on any spec and confirm no Bash approval prompts surface during the reviewer agents' work.
- Trigger the safety-harness intentionally: type `rm -rf $HOME/test-nonexistent` (in a state where the path doesn't exist, so it's a no-op even if it ran) and confirm the hook blocks with the expected reason. Then prefix with `SAFETY_HARNESS_OFF=1 ` and confirm the bypass works.

## Notes for the receiving Claude

- **The threat model is the load-bearing assumption.** Do not silently ship the template's calibration into a project whose contributor model differs. Step 2 of the apply prompt is mandatory — surface the question, wait for the user to answer.
- **Application order matters.** Stage 2 (threat-model ADR) must precede Stage 3 (silent-review conventions reference the ADR) and Stage 4 (safety-harness docs link to the ADR's tightening checklist). If you apply the safety harness before the ADR, the cross-reference goes nowhere.
- **`.claude/agents/CLAUDE.md` accumulates four sections.** Don't merge it as a single file — merge each section independently. The local file may have any subset of the four sections from earlier packets or piecemeal adoption.
- **`.claude/settings.json` has three independent deltas.** The `env` block is likely already present (from the previous packet). The `permissions.allow` array gets new entries appended. The `hooks` block is new. Treat each delta as its own merge; do not overwrite the file wholesale.
- **`triage-secret-patterns.txt` was renamed to `triage-scan-patterns.txt`.** If the receiving project is mid-adoption and has the old name, delete it. If it has neither, create the new name. Don't ship both.
- **`chmod +x` on both `.sh` files is essential.** Raw GitHub URLs do not preserve executable bits. Without this step, the hook silently fails (Claude Code will error trying to invoke a non-executable script) and the test runner won't run. Apply `chmod +x` immediately after WebFetch for each.
- **The 39 fixture pairs** are too many to enumerate in the apply plan. Use the GitHub tree API to list the directory recursively, then WebFetch each file. Do not manually list filenames in the apply plan — that's noise and risks transcription errors.
- **The test suite is the single most useful verification check.** All the `test -f` and `grep -q` checks confirm presence; only the test runner confirms behaviour. If `bash .claude/hooks/tests/safety-harness/run-tests.sh` exits non-zero, something is wrong (likely a fixture missing, the script not executable, or a regex behaving differently on the receiving system's bash version).
- **Excluded files**: `SPECIFICATIONS/ARCHIVE/pretooluse-safety-harness.md`, `TEMPLATE-FOLLOWUPS.md`, `TEMPLATE-INSTRUCTIONS.md` are template-internal. They appear in the source PRs' diffs but should not be copied. The "What changed" section explains why each is template-internal.
- **Project-specific stack mentions in `security-specialist.md`** — the template's reference includes generic mentions like "Supabase RLS", "Cloudflare Workers". If the receiving project uses different infrastructure, fold the threat-model-aware language in but keep local stack-specific guidance.
