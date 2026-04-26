# Investigation: Claude Code Write path-normalisation for allowlist matching

**Type:** Open investigation (root cause not understood; symptom now sidestepped by abandoning `/tmp/` for scratch files)
**Status:** Symptom sidestepped, root cause still open.

---

## Symptom

During PR 19's team review the dispatcher tried to write `/tmp/review-pr-19-triage.md` and was prompted, despite `Write(/tmp/review-pr-*)` being in the allowlist. The displayed path in the permission prompt was `../../../../../../tmp/review-pr-19-triage.md`.

On a follow-up dispatcher run (PR 20's light review, post-merge of PR 19, fresh session), the same Write call ran silently with the same allowlist entry — no prompt.

**Third sighting (2026-04-26, derivative project):** during a `/review-pr 67` team review the dispatcher tried to write `/tmp/review-pr-67-triage.md` and was prompted with the same `../../../../../../tmp/...` traversal form. Same six-level depth as PR 19. Three sightings now (PR 19 prompted, PR 20 silent, PR 67 prompted) — the intermittency is real but unexplained.

## Resolution path taken

Rather than ship a relative-form workaround pinned to a particular directory depth (brittle across derivative projects clone locations), the review skills were migrated to write into `SCRATCH/` at the repo root — a project-relative path that doesn't trigger the absolute-vs-relative form question, contents gitignored to avoid leaking artefacts. The allowlist entries became `Write(/SCRATCH/*)` and `Read(/SCRATCH/*)`. The directory lives at the repo root rather than under `.claude/` so that Write calls don't trigger Claude Code's "modifying its own settings" approval gate, which fires for any path under `.claude/` regardless of allowlist entries.

This sidesteps the symptom but does **not** explain or fix the underlying matcher behaviour. If the same intermittency surfaces with project-relative paths in the future, this file is the place to add the next sighting.

### Follow-up sighting (2026-04-26): permission-glob path semantics

While verifying the `SCRATCH/` migration, the dispatcher still surfaced a manual approval prompt for `Write(/Users/.../SCRATCH/review-pr-31-triage.md)` despite `Write(SCRATCH/*)` being in the allowlist. Investigation via the Claude Code permissions docs confirmed: a leading `/` in a permission glob means "project-root-relative" (not filesystem-absolute — that's `//`), and the no-slash form is matched against the cwd-relative form. Because the Write/Read tools always pass an absolute path, the matcher compares against the absolute form, so `Write(SCRATCH/*)` silently fails to match and prompts on every scratch write.

**Fix:** the leading-slash form `Write(/SCRATCH/*)` and `Read(/SCRATCH/*)` matches reliably. This is a permission-glob shape issue, distinct from the `/tmp/` traversal-form intermittency above.

This is also a partial corroboration of the working hypothesis below — the matcher does NOT silently normalise paths to a single canonical form before applying patterns; pattern shape matters. Whether the `/tmp/` traversal-form sightings are explained by the same matcher behaviour or something else is still open.

## Working hypothesis

Claude Code's permission matcher *may* not normalise relative-vs-absolute paths before applying allowlist patterns, so absolute-form entries fail to match relative-form tool inputs in some sessions. The PR 19 observation is consistent with this; the PR 20 silent run is not.

Possible explanations for the inconsistency:
- The matcher does normalise, and the PR 19 prompt was caused by something else (a `settings.json` change without session restart, missing entry at the time, transient cache issue).
- The matcher has session-scoped state that hasn't been identified.
- The displayed path differs between sessions for reasons unrelated to allowlist matching.

## Why this matters

If the matcher genuinely doesn't normalise, then every `Write(/tmp/…)` and `Bash(... /tmp/…)` allowlist entry is unreliable depending on session state. That's a footgun worth understanding even if the current symptoms are mild.

## Next step

Deliberate repro. Try toggling:

- (a) `settings.json` edits without session restart vs. with restart.
- (b) Fresh session vs. resumed session.
- (c) Different invocation paths (skill-driven Write vs. agent-driven Write).

Capture the exact displayed path in each case. Once the conditions are characterised, decide between:

- File an upstream bug.
- Ship the relative-form belt-and-braces workaround as a permanent precaution.
- Close the entry as a session-state quirk that doesn't need a fix.

## If a workaround is needed later

Add a second matching entry in relative-traversal form alongside each absolute-form `Write(/tmp/…)` entry — e.g. `Write(../../../../../../tmp/review-pr-*)` next to `Write(/tmp/review-pr-*)`. The literal traversal depth depends on where Claude Code starts the relative path from, so capture the exact form from a fresh permission prompt rather than guessing.

## Promotion path

When repro conditions are characterised and a fix path is chosen, promote this file to a numbered phase under `SPECIFICATIONS/` and run `/review-spec` before implementing. If the conclusion is "no fix needed", move this file to `SPECIFICATIONS/ARCHIVE/` with a one-paragraph closing note rather than deleting it — the working hypothesis is useful context if the symptom resurfaces.
