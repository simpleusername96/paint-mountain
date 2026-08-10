---
type: evidence
status: active
created: 2026-08-10
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

### Exact delete-after-approval batch

No file in this section is authorized for deletion by this report.

- Retain `.agents/evidence/current/aiming_after_physical.png`; delete its exact
  same-directory duplicate
  `.agents/evidence/current/aiming_after_physical2.png` only after approval
  (86,310 bytes).
- The following seven superseded `improved` report images may be deleted only
  after approval; the refined set replaced them and the report index retains
  only improved states 05, 06, and 07:
  - `docs/reports/screen-audit-2026-08-10/assets/improved/01-main-menu-improved.png`
  - `docs/reports/screen-audit-2026-08-10/assets/improved/02-stage-select-improved.png`
  - `docs/reports/screen-audit-2026-08-10/assets/improved/03-briefing-improved.png`
  - `docs/reports/screen-audit-2026-08-10/assets/improved/04-aim-view-improved.png`
  - `docs/reports/screen-audit-2026-08-10/assets/improved/08-settings-improved.png`
  - `docs/reports/screen-audit-2026-08-10/assets/improved/09-manual-result-improved.png`
  - `docs/reports/screen-audit-2026-08-10/assets/improved/10-timeout-result-improved.png`
- Exact tracked reclaim for the eight-file batch is 8,484,888 bytes. Git
  history makes it recoverable, but deletion still requires explicit approval.

### Blocked or separate cleanup

- `docs/concepts/aim-view-glyph-placement-2026-08-09/` lacks an adjacent owner
  decision, so its four files remain retained pending evidence.
- Three non-active v10 catalog bundles total 2,796,745 bytes, but generated
  resources are outside the media audit and retain historical references. The
  v9 bundle is also a live migration-test fixture. No catalog bundle deletion
  is proposed here.
- Ignored local outputs are separate from tracked cleanup: `.godot/`
  113,263,262 bytes, `builds/` 759,224,928 bytes, and `reports/` 2,126,686
  bytes at audit time. Their contents may include useful caches, the current
  release build, or transient results; exact-path approval is required before
  reclaim.

## Recommendations

1. Apply the non-destructive authority, lifecycle, provenance, and ignore-rule
   repairs in a decision-complete implementation contract.
2. Keep all blocked assets and generated catalogs unchanged.
3. Request separate approval for the exact eight-file tracked deletion batch
   and for any local-output reclaim batch.

## Limitations

The inventory is tied to the recorded commit. Godot import sidecars and ignored
output byte totals are local state and can change after another import, build,
or validation run.
