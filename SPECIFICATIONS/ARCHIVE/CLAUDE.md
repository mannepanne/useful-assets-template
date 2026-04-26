# Archived Specifications

Auto-loaded when working with files in this directory. Completed implementation phases moved here for reference.

## Completed phases

- [pretooluse-safety-harness.md](./pretooluse-safety-harness.md) — PreToolUse safety-harness hook (block/ask tiers, calibrated for the less-experienced-user sub-case). How-it-works at [`REFERENCE/safety-harness.md`](../../REFERENCE/safety-harness.md).

## Link convention for archived specs

Archived specs sit one directory deeper than their original `SPECIFICATIONS/` location. Outbound relative links must use `../../` (not `../`) to reach project-root-relative paths like `REFERENCE/`, `CLAUDE.md`, etc. When moving a spec into this directory, walk every `](../...)` link and add one extra `../` segment. A markdown link checker can catch missed updates.

---

**Note:** Archived specs are historical record. For current implementation details, see `REFERENCE/` documentation.
