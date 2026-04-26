# Investigation: Claude Code Write path-normalisation for allowlist matching

**Type:** Open investigation (root cause not understood; symptom mitigated but not eliminated by moving scratch files into `<project>/SCRATCH/`)
**Status:** Symptom partially mitigated, root cause still open. Earlier "leading-slash form fixes it" claim **disproven empirically** — see PR-31 post-merge sighting below.

---

## Symptom

During PR 19's team review the dispatcher tried to write `/tmp/review-pr-19-triage.md` and was prompted, despite `Write(/tmp/review-pr-*)` being in the allowlist. The displayed path in the permission prompt was `../../../../../../tmp/review-pr-19-triage.md`.

On a follow-up dispatcher run (PR 20's light review, post-merge of PR 19, fresh session), the same Write call ran silently with the same allowlist entry — no prompt.

**Third sighting (2026-04-26, derivative project):** during a `/review-pr 67` team review the dispatcher tried to write `/tmp/review-pr-67-triage.md` and was prompted with the same `../../../../../../tmp/...` traversal form. Same six-level depth as PR 19.

**Fourth sighting (2026-04-26, this repo, post-PR-31-merge session):** with `Write(/SCRATCH/*)` and `Read(/SCRATCH/*)` committed in `.claude/settings.json` and a Write to `<project>/SCRATCH/review-pr-31-standard.md`, the prompt **still fired**. The exact displayed path was not captured (next-session task — see "Next step").

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

## Live hypotheses (ordered by likelihood)

1. **Stale in-memory allowlist.** Claude Code may read `settings.json` only at session start. If the entry is added mid-session (or the session was started before the commit landed), the in-memory matcher doesn't have it. **Test:** start a fresh Claude Code session in this repo and trigger a Write to `SCRATCH/`. If silent, this hypothesis is confirmed and the doc-correct entry shape needs no change.

2. **Glob-shape pickiness.** Docs say `*` matches a single directory level. `Write(/SCRATCH/*)` should match `SCRATCH/file.md` (no segment boundary to cross), but if the matcher disagrees, `Write(/SCRATCH/**)` is a more permissive form. **Test:** if hypothesis 1 fails, swap to `**` and re-test in a fresh session.

3. **Undocumented gate on the Write tool.** Possibly Write has additional approval logic beyond the documented protected-directory list — e.g. fires for any new file creation, or any write outside an explicit allowlist match shape we haven't tried. Hard to test without primary-source confirmation; would surface as "no glob shape silences it."

## Next step

**Capture the exact path string the prompt displays** when it fires next time. That's the matcher's view of the input and is the most discriminating evidence we don't yet have. The displayed string for the `/tmp/` cases (`../../../../../../tmp/...`) is what tied the original observation to the project-relative-normalisation theory; we need the same evidence for the SCRATCH/ case before we can do more than guess.

After capture, run hypotheses in order:
1. Fresh-session retry with current `Write(/SCRATCH/*)` entry. Note whether it prompts.
2. If still prompts, swap to `Write(/SCRATCH/**)` and `Read(/SCRATCH/**)`, fresh-session retry.
3. If still prompts, file an upstream bug with the captured path string — at that point we have docs saying X, observation showing Y, and shape variants exhausted.

## Why this matters

If the matcher behaviour genuinely diverges from documented semantics, every `/path/...` entry in the allowlist is unreliable. The current symptom is mild (an extra approval click), but the same ambiguity affects any future allowlist tightening — including the threat-model-driven defaults shipped with this template.

## Promotion path

When repro conditions are characterised and a fix path is chosen, promote this file to a numbered phase under `SPECIFICATIONS/` and run `/review-spec` before implementing. If the conclusion is "no fix needed", move this file to `SPECIFICATIONS/ARCHIVE/` with a one-paragraph closing note rather than deleting it — the working hypotheses are useful context if the symptom resurfaces.
