# Investigation: Claude Code Write path-normalisation for allowlist matching

**Type:** Open investigation (root cause not understood; symptom mitigated but not eliminated by moving scratch files into `<project>/SCRATCH/`)
**Status:** Symptom partially mitigated, root cause still open. Earlier "leading-slash form fixes it" claim **disproven empirically** — see PR-31 post-merge sighting below.

---

## Symptom

During PR 19's team review the dispatcher tried to write `/tmp/review-pr-19-triage.md` and was prompted, despite `Write(/tmp/review-pr-*)` being in the allowlist. The displayed path in the permission prompt was `../../../../../../tmp/review-pr-19-triage.md`.

On a follow-up dispatcher run (PR 20's light review, post-merge of PR 19, fresh session), the same Write call ran silently with the same allowlist entry — no prompt.

**Third sighting (2026-04-26, derivative project):** during a `/review-pr 67` team review the dispatcher tried to write `/tmp/review-pr-67-triage.md` and was prompted with the same `../../../../../../tmp/...` traversal form. Same six-level depth as PR 19.

**Fourth sighting (2026-04-26, this repo, post-PR-31-merge session):** with `Write(/SCRATCH/*)` and `Read(/SCRATCH/*)` committed in `.claude/settings.json` and a Write to `<project>/SCRATCH/review-pr-31-standard.md`, the prompt **still fired**. The exact displayed path was not captured (next-session task — see "Next step").

**Fifth sighting (2026-04-26, this repo, fresh session, `/review-pr 32`):** prompt fired again on `Write` to `SCRATCH/review-pr-32-light.md`. Key new evidence:
- **Displayed path was bare cwd-relative form**: `SCRATCH/review-pr-32-light.md` — *not* the `../../../../../../tmp/...` traversal form, *not* `/SCRATCH/...`. Different display shape from the `/tmp/` sightings.
- **Only the Write tool prompted.** Triage-reviewer, light-reviewer, and technical-writer subagents all ran silently — including their `gh pr view`, `gh pr diff`, and Bash calls. The post-approval `Bash(gh pr comment ... --body-file SCRATCH/...)` also ran silently.
- **Fresh session**, so hypothesis #1 (stale in-memory allowlist) is **eliminated**.
- **Reproduces in a separate derivative project** with the same template state — eliminates project-specific weirdness.

## Primary-source semantics (confirmed)

Verified against https://code.claude.com/docs/en/permissions.md (§ "Read and Edit"):

- `/path` in a permission glob = **project-root-relative** (e.g. `Edit(/docs/**)` matches `<project>/docs/`, **not** filesystem `/docs/`).
- `//path` = filesystem-absolute (explicit, documented).
- `~/path` = home directory.
- `./path` or bare `path` = cwd-relative.
- `*` matches a single directory level; `**` matches recursively.
- `.claude/` (and `.git/`, `.vscode/`, `.idea/`, `.husky/`) are **protected directories** that prompt even in `bypassPermissions` mode. This applies regardless of allowlist entries.
- The matcher checks both the requested path and any symlink-resolved target — so *some* path resolution happens internally.
- Docs are **silent** on:
  - Whether the matcher normalises absolute tool-input paths to project-relative form before matching (symlink handling implies it does, but no explicit statement).
  - Env-var interpolation (`$CLAUDE_PROJECT_DIR` etc.) in permission patterns.

### Retroactive explanation of the `/tmp/` traversal display

The `../../../../../../tmp/...` form shown in PR 19's prompt is consistent with the matcher resolving the absolute tool-input path to project-relative form: from project root `/Users/magnus/Documents/Coding/AllUsefulAssets/useful-assets-template/`, six `../` levels reach filesystem root, so `../../../../../../tmp/...` is the project-relative spelling of `/tmp/...`.

That also retroactively explains why `Write(/tmp/review-pr-*)` was the wrong entry shape all along: by docs, `/tmp/` is project-root-relative, so the matcher was looking for `<project>/tmp/...`, not filesystem `/tmp/...`. The correct shape would have been `Write(//tmp/review-pr-*)` (double-leading-slash for filesystem-absolute). The PR 20 silent run is then plausibly explained as a one-off "always-allow" click rather than genuine intermittency.

This sub-claim is consistent but not directly verified — capturing the exact displayed path next time the prompt fires would either confirm or refute it.

## Mitigation taken (not a fix)

The review skills were migrated to write into `<project>/SCRATCH/` rather than `/tmp/`:
- Avoids the absolute-vs-project-relative mismatch that broke `Write(/tmp/...)` entries.
- Avoids the `.claude/` protected-directory gate (which would prompt regardless).
- Contents gitignored so artefacts don't leak.

Allowlist entries became `Write(/SCRATCH/*)` and `Read(/SCRATCH/*)`. **Per docs these should silence the prompt for writes to `<project>/SCRATCH/file.md`.** Empirically (PR 31 post-merge session, fourth sighting) they did not. Root cause unknown.

## Disproven hypothesis: "leading-slash form fixes it"

A previous version of this doc claimed:

> the leading-slash form `Write(/SCRATCH/*)` and `Read(/SCRATCH/*)` matches reliably. This is a permission-glob shape issue, distinct from the `/tmp/` traversal-form intermittency above.

**This claim is false.** It was based on a single intra-session observation; the next attempted Write in the same session prompted again. The leading-slash semantics are correct per docs, but something else is preventing the match in practice.

## Live hypotheses (ordered by likelihood after fifth sighting)

1. ~~**Stale in-memory allowlist.**~~ **Eliminated** by fifth sighting (fresh session still prompts).

2. **Glob-shape pickiness.** Docs say `*` matches a single directory level and `/path` is project-root-relative. `Write(/SCRATCH/*)` should match `SCRATCH/file.md`, but the matcher displays the input path as bare cwd-relative `SCRATCH/...` (no leading slash) — that display divergence is suggestive that the leading-slash and bare forms aren't being treated as equivalent at match time. **Now the leading hypothesis.**

3. **Undocumented gate on the Write tool.** Write tool may have approval logic beyond the documented allowlist — e.g. unconditional gating on new-file creation regardless of glob match. The fifth sighting evidence that *only* the Write tool prompted (Bash, Read, subagent invocations all silent) keeps this live. Surfaces as "no glob shape silences it" in the experiment below.

## Active experiment (running now — refresh from here after session restart)

**Working theory:** the matcher canonicalises Write paths to bare cwd-relative form (`SCRATCH/file.md`) for matching, but the documented `/path` semantics (project-root-relative) mean `Write(/SCRATCH/*)` is being parsed as a literal-leading-slash glob that doesn't match the canonicalised form. Belt-and-braces: add every plausible glob shape simultaneously so at least one matches.

**Step 1 — done in this session (commit on branch `fix/investigation-doc-update`):**

Added all four glob-shape variants for both `Write` and `Read` to `.claude/settings.json`:

```jsonc
"Write(/SCRATCH/*)",
"Write(/SCRATCH/**)",
"Write(SCRATCH/*)",
"Write(SCRATCH/**)",
"Read(/SCRATCH/*)",
"Read(/SCRATCH/**)",
"Read(SCRATCH/*)",
"Read(SCRATCH/**)"
```

Glob lists are additive — any single matching entry silences the prompt. Commit this on the feature branch before restarting the session so the change is loaded at session start.

**Step 2 — requires fresh session:**

Magnus restarts Claude Code, runs `/review-pr 32` (or any review that triggers a Write to `SCRATCH/`). Two outcomes:

- **Silent (no prompt fires):** hypothesis #2 confirmed. The `/SCRATCH/*` shape doesn't match in practice despite docs. Bisect later to find the minimum entry that works (one fresh session per shape — drop entries one at a time until prompt returns) and trim the allowlist to just the working shape. Then update this investigation with the conclusion and move to `SPECIFICATIONS/ARCHIVE/`.
- **Still prompts:** hypothesis #3 is now the survivor. The Write tool has gating beyond the allowlist matcher entirely. Move to fallback below.

**Fallback if Step 2 still prompts:**

Add a `PreToolUse` hook that auto-approves `Write` to `SCRATCH/*.md`. The repo already has hook infrastructure (commit 0d810ea — `safety-harness.sh`), so this is a well-trodden path. Hooks bypass the allowlist matcher entirely — if even that fails we know the tool itself has unconditional gating. At that point file an upstream bug with this investigation as the report, since we'll have docs saying X, fresh-session observation showing Y across two projects, and all glob-shape variants exhausted.

**Why not jump straight to the hook?** Because the hook is a workaround, not a diagnosis. If we hop to it now we never learn whether the documented `/path` semantics work at all in practice, and every other `/path` allowlist entry in this template stays unreliable. One fresh-session test costs nothing and tells us whether the matcher honours the documented semantics.

## Why this matters

If the matcher behaviour genuinely diverges from documented semantics, every `/path/...` entry in the allowlist is unreliable. The current symptom is mild (an extra approval click), but the same ambiguity affects any future allowlist tightening — including the threat-model-driven defaults shipped with this template.

## Promotion path

When repro conditions are characterised and a fix path is chosen, promote this file to a numbered phase under `SPECIFICATIONS/` and run `/review-spec` before implementing. If the conclusion is "no fix needed", move this file to `SPECIFICATIONS/ARCHIVE/` with a one-paragraph closing note rather than deleting it — the working hypotheses are useful context if the symptom resurfaces.
