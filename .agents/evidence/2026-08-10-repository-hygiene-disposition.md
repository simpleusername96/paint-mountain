---
type: evidence
status: active
created: 2026-08-10
last_reviewed: 2026-08-10
scope: repository documentation, tracked visual and runtime assets, and ignored project-local output
source: ../execplans/2026-08-10-repository-hygiene-disposition.md
related:
  - ../Documentation.md
  - ../../docs/asset-licenses.md
  - ../../assets/ui/icons/GENERATED_ASSETS.md
---

# Repository Hygiene Disposition Evidence

## Purpose

Classify current documents and assets by authority, lifecycle, runtime use,
provenance, and recoverability before any destructive cleanup.

## Sources

- Commit `fc02848dc2abad7ee7c8518c4faa6374f57bd452` and its tracked file graph.
- Root and nearest `AGENTS.md`, `.agents/PLANS.md`, the effective source brief,
  current specs, `.agents/Documentation.md`, and the design reference map.
- Godot scene, resource, script, test, import, and export references.
- `docs/asset-licenses.md`, adjacent source/license records, exact SHA-256
  groups, file sizes, and targeted path history.

## Findings

### Inventory and retained authority

- The audit covered 84 tracked Markdown files (1,782,497 bytes) and 530
  tracked files in the asset/evidence scope (141,435,189 bytes).
- No Markdown file is an exact duplicate, no relative Markdown link is dead,
  and no formal `canonical_for` value competes with another.
- Protected instructions, canonical specs, current implementation records,
  raw external-review provenance, required runtime assets, license texts, and
  linked historical evidence remain retained.
- The five evidence documents using `done` or `superseded` have invalid
  evidence lifecycle states. Twenty-one more historical evidence, concept, and
  handoff documents still claim `active`. All 26 can be archived in place
  without moving files or breaking inbound links.
- `README.md`, `.agents/Prompt.md`, `.agents/design/VISUAL_REFERENCES.md`, and
  `docs/design-spec.md` contain stale current-authority statements. The design
  spec points to `v10-d508...`; the live catalog and technical architecture
  agree on `v10-701b3...` and bundle format 5.
- Two active evidence READMEs lack the required `Purpose`, `Sources`, and
  `Findings` structure.

### Runtime and provenance

- All 36 runtime source assets have matching tracked Godot import metadata;
  all 22 current ledger entries resolve and match their recorded hashes.
- `assets/ui/icons/result_timeout_clock.png` is a current generated runtime
  asset but is missing from the generated-asset record. Its SHA-256 is
  `A2D4B6D57114BB3236413D10598D553301EF92102C1E0B8EA81AF1375F175E46`.
- `pause.png` and `restart.png` have no current repository caller, but prior
  use and the absence of an explicit retirement decision block deletion.
- The unreferenced Kenney `divider.png` remains intentionally reserved by its
  active provenance record.
- Godot produced 43 currently observed, untracked `docs/evidence/**/*.import`
  sidecars (44,520 bytes). The repository ignores other documentation import
  surfaces but not this one; the correct repair is an ignore rule, not tracking
  or treating the sidecars as source assets.

### Approved and executed tracked cleanup

The user approved the audit-backed deletion batch after this report was first
written. The cleanup retained
`.agents/evidence/current/aiming_after_physical.png` and removed its exact
same-directory duplicate (86,310 bytes). It also removed the following seven
superseded `improved` report images; the refined set replaced them and the
report index retains only improved states 05, 06, and 07:
  - `docs/reports/screen-audit-2026-08-10/assets/improved/01-main-menu-improved.png`
  - `docs/reports/screen-audit-2026-08-10/assets/improved/02-stage-select-improved.png`
  - `docs/reports/screen-audit-2026-08-10/assets/improved/03-briefing-improved.png`
  - `docs/reports/screen-audit-2026-08-10/assets/improved/04-aim-view-improved.png`
  - `docs/reports/screen-audit-2026-08-10/assets/improved/08-settings-improved.png`
  - `docs/reports/screen-audit-2026-08-10/assets/improved/09-manual-result-improved.png`
  - `docs/reports/screen-audit-2026-08-10/assets/improved/10-timeout-result-improved.png`
- The cleanup also removed the zero-consumer `pause.png`, `restart.png`, and
  Kenney `divider.png` source/import pairs and repaired the two provenance
  records. It removed the three inactive v10 catalog bundles while retaining
  the complete active v10 bundle and the complete v9 migration fixture.
- The tracked cleanup removed 290 files and reclaimed 11,315,576 bytes. Git
  history keeps those deletions recoverable.

### Retained and locally blocked cleanup

- `docs/concepts/aim-view-glyph-placement-2026-08-09/` lacks an adjacent owner
  decision, so its four files remain retained pending evidence.
- The three non-active v10 bundles were removed after a wider catalog audit
  proved they had no live consumer. The v9 bundle remains because the
  materialization regression uses it.
- The user approved exact-path local-output cleanup. The host execution policy
  nevertheless rejected deletion of `.godot/`, `builds/`, and root `reports/`,
  including a later `git clean` preview. Windows UI deletion was also
  unavailable because its native connection could not be established. Ignored
  logs and documentation `.import` sidecars were removed, and four `.gdignore`
  boundaries prevent those sidecars from returning. Godot verification touched
  `.godot`, but no successful deletion established that its contents are a
  completely fresh cache.

## Recommendations

1. Keep the active v10 bundle, the v9 migration fixture, current runtime assets,
   and unique evidence unchanged.
2. Remove the three remaining ignored local-output directories when a
   deletion-capable executor is available.

## Limitations

The inventory is tied to the reviewed cleanup worktree. Ignored output byte
totals are local state and can change after another import, build, or validation
run.
