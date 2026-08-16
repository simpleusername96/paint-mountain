---
type: plan
status: active
created: 2026-08-16
scope: Separate Paint Mountain canonical documentation, reusable concept research, validation evidence, and active handoffs
---

# Document Placement Migration - Execution Contract

## Purpose

- Objective: keep maintained project truth in `docs/`, move reusable concept studies to `.agents/research/`, and consolidate retained QA proof under `.agents/evidence/`.
- Deliverable: path-preserving bundle moves, corrected links and lifecycle paths, and explicit placement guidance.
- Completion state: canonical docs and active handoffs remain stable while all listed research/evidence bundles have one valid owner.

## Scope and Boundaries

In scope: exact concept and evidence bundles in Discovery Closure, affected links/frontmatter, and repository placement guidance.

Out of scope:

- Runtime, scenes, assets outside listed document bundles, tests, gameplay, and UI changes.
- `docs/handoffs/**`; handoff lifecycle and the active special-ball package remain untouched.
- `docs/difficulty-progression.ko.md` and `docs/itchio-github-actions-setup.ko.md`.
- Recreating missing generated reports or repairing unrelated pre-existing report links.

Constraints:

- Move each dated directory as a coherent bundle, including images and HTML required by its Markdown.
- Preserve bytes, nested paths, and lifecycle status. Use `git mv` and a SHA-256 manifest.
- No deletion, archive, or semantic rewrite is authorized.

## Discovery Closure

| Disposition | Exact paths | Locked reason |
| --- | --- | --- |
| Keep canonical docs | `docs/source-brief.md`; `docs/design-spec.md`; `docs/technical-architecture.md`; `docs/test-checklist.md`; `docs/asset-licenses.md` | Maintained product, design, architecture, test, and provenance owners |
| Move to `.agents/research/concepts/` | `docs/concepts/casual-ui-directions-2026-08-08/**`; `docs/concepts/runtime-grounded-ui-2026-08-05/**`; `docs/concepts/ui-layout-directions-2026-08-06/**` | Reusable archived concept and reference studies |
| Move to `.agents/evidence/concepts/` | `docs/concepts/aim-view-glyph-placement-2026-08-09/**`; `docs/concepts/execplan-outcome-2026-08-03/**`; `docs/concepts/full-ui-refresh-2026-08-09/**`; `docs/concepts/queued-ball-ui-2026-08-14/**`; `docs/concepts/rapid-fire-progression-2026-08-04/**` | Generated visual alternatives, selected-image proof, superseded concepts, and task outcome captures |
| Move to `.agents/evidence/` | `docs/evidence/approved-image-fidelity-correction-2026-08-10/**`; `docs/evidence/essential-ui-fidelity-2026-08-10/**`; `docs/evidence/fast-stage-readiness-2026-08-11/**`; `docs/evidence/stage-selection-readiness-2026-08-11/**`; `docs/evidence/web-runtime-responsiveness-2026-08-11/**` | Rendered and runtime validation proof |
| Keep existing evidence owner | Existing `.agents/evidence/**` | Already correctly placed |
| Leave unchanged | `docs/handoffs/**`; `docs/difficulty-progression.ko.md`; `docs/itchio-github-actions-setup.ko.md` | Separate lifecycle, ambiguous authority, or maintained user runbook |

Known consumers include `docs/test-checklist.md`, `.agents/Documentation.md`, `.agents/design/VISUAL_REFERENCES.md`, `.agents/Prompt.md`, and relative paths inside moved bundle READMEs. Classification is closed.

## Tasks

### Phase 1: Establish placement contract and manifest

- [ ] **1.1 Update root and `.agents` guidance.** Define canonical docs, advisory research, validation evidence, and active handoffs without enumerating transient files.
  - Accept: the active design/workflow owners remain authoritative and `.agents/research` is not described as a production asset owner.
- [ ] **1.2 Create a path and SHA-256 manifest for all files in the thirteen dated bundles.**
  - Accept: every source has one predetermined target and no target collision exists.

### Phase 2: Move coherent bundles

- [ ] **2.1 Move the three synthesized concept-study bundles with `git mv` to `.agents/research/concepts/`.**
  - Accept: all images/HTML needed by each bundle moved with it and hashes match.
- [ ] **2.2 Move the five generated concept/output bundles to `.agents/evidence/concepts/` and the five QA bundles to `.agents/evidence/` with `git mv`.** Merge only at the directory level; never overwrite existing evidence.
  - Accept: each old directory is absent, each target is complete, and hashes match.

### Phase 3: Repair links and validate

- [ ] **3.1 Update every affected link and lifecycle path.** Repair consumers and relative links inside moved READMEs/frontmatter.
  - Accept: targeted `rg -n 'docs/(concepts|evidence)' docs .agents AGENTS.md` contains no stale live path.
- [ ] **3.2 Validate with `git diff --check`, `Test-Path`, the manifest, frontmatter inspection, and `git diff --name-status -- docs .agents AGENTS.md`.**
  - Accept: no runtime or handoff path changed and all changed links resolve.
- [ ] **3.3 Record evidence, set `status: done`, and commit only migration-owned files.**

## Validation and Rework Controls

- Validate one full concept bundle and one full evidence bundle before moving the remaining batches.
- Do not run game/runtime tests because no product behavior changes.
- Do not treat references to missing generated reports as migration failures unless this migration changed the reference.
- Rerun checks only after their relevant bundle or link changes.

## Predetermined Contingencies and Change Control

- If an image or HTML file is required to render a moved report, include it in the same bundle and manifest; do not duplicate it under `docs/`. Update `.agents/design/VISUAL_REFERENCES.md`, `.agents/design/UIUX_GUIDELINES.md`, canonical-doc links, handoff links, and historical-plan links to the new single-owned targets.
- If existing `.agents/evidence/` contains a conflicting target, stop and revise the mapping rather than overwrite.
- If a handoff appears complete or stale, leave it unchanged; archival requires separate owner approval.
- Any classification of the two explicitly excluded Korean documents requires a separate lifecycle review.

## Progress and Next Steps

- Canonical progress: this contract's checkboxes.
- Current phase: Awaiting owner approval to execute.
- Next task after approval: 1.1 Update root and `.agents` guidance.
- Last completed gate: Markdown, bundle, frontmatter, and inbound-link audit; dispositions are locked.

## Completion and Stop Conditions

Complete only after every task passes and frontmatter is `done`. Replan if a bundle cannot stay coherent at its target or a current user edit overlaps a mapped path.
