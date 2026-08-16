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

In scope: exact concept, evidence, and difficulty-progression research bundles in Discovery Closure, affected links/frontmatter, and repository placement guidance.

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
| Keep difficulty-progression project knowledge | `project-specs/paint-mountain-difficulty-progression/PRD.md`; `DECISIONS.md`; `OPEN_QUESTIONS.md`; `TASKS.md`; `AGENTS.md` | Product definition, decisions, canonical question queue, draft work items, and local workspace guidance |
| Move difficulty-progression research | `project-specs/paint-mountain-difficulty-progression/RESEARCH.md`; `research-context/**` except `research-context/01-research-plan.md` | Archived advisory synthesis and its coherent supporting context |
| Move completed research checklist | `project-specs/paint-mountain-difficulty-progression/research-context/01-research-plan.md` to `.agents/execplans/2026-08-13-difficulty-progression-idea-research.md` | Completed plan instances belong under the unified execution-plan owner |
| Keep existing evidence owner | Existing `.agents/evidence/**` | Already correctly placed |
| Leave unchanged | `docs/handoffs/**`; `docs/difficulty-progression.ko.md`; `docs/itchio-github-actions-setup.ko.md` | Separate lifecycle, ambiguous authority, or maintained user runbook |

Known consumers include `docs/test-checklist.md`, `.agents/Documentation.md`, `.agents/design/VISUAL_REFERENCES.md`, `.agents/Prompt.md`, and relative paths inside moved bundle READMEs. Classification is closed.

## Tasks

### Phase 1: Establish placement contract and manifest

- [x] **1.1 Update root, `.agents`, planning, and difficulty-progression workspace guidance.** Define canonical docs, advisory research, validation evidence, active handoffs, and the completed-checklist owner without enumerating transient files.
  - Accept: the active design/workflow owners remain authoritative and `.agents/research` is not described as a production asset owner.
  - Evidence: root, `.agents`, planning policy, and the difficulty-progression workspace now distinguish canonical project knowledge, advisory synthesis, retained proof, design context, and plan ownership.
- [x] **1.2 Create a path and SHA-256 manifest for all files in the thirteen dated bundles, the difficulty-progression research dossier, and its completed research checklist.**
  - Accept: every source has one predetermined target and no target collision exists.
  - Evidence: all 148 source files had collision-free targets. Pre-move group manifests (`file count / SHA-256`) were: casual UI `11 / FE4BC79E943A2C96E11EFB79448CF827A05232B2937A5DE4130F22D748C37BCB`; runtime-grounded UI `20 / 2FF1F2E17BFAEC1C09145D6E5A79F736414D32B6DF03C37AE9D4BC27860EFF10`; UI layout `4 / 7BA95D2CC3DEA7BA0C2D469FF12C58640618EFB0DA216496A61B885BE0AE8DA8`; aim glyphs `4 / 712953F657AAA9A5A97F0A9707CE2789ED24E8CB23330E3016C4A0960149DBE8`; execplan outcome `8 / 07DE8010AC1BB6FC5C6D126040BAF3BA40B39B025370F282C59B3FDFD320C7AE`; full UI refresh `11 / 575BFA33AFE006AFF5CBCC94007E075025F561068C5274DF15B747C9A2BD210C`; queued-ball UI `7 / F295CD630D8483647EB65C9B238B142B5B8B505BBD7F20F6D4EC3FCF1859934C`; rapid-fire progression `5 / 697D820045B94B8C123ED6B3D8296DFC35B155B9BAD915ABF9C5144BF12CACB3`; approved fidelity `20 / 3833FE8F127F1C594F7F27E0182E6153E99894037F1A5E4A7D9F6048DA6B42EB`; essential fidelity `26 / 55EF8F4EDCDF04EEEE8C58FA64FD67FDE9CF20EAF0693911B396BA3B8C318FBC`; fast readiness `11 / 8CB46658B7356929CEF1D668131A9A866B5F4E2C9FE4A7D82393874A356775B1`; stage readiness `3 / C3214B0F86A8824C3F83A8B5CAB62D8EECF5FC1DA8C4D04F9E62F8636A3DDF4D`; web responsiveness `9 / 54E995FE68154C6A0F6EAF08DDE13EA1581A69000554439C3702DD250FFB59C7`; difficulty research context `8 / 3C0B7DB98668E7B8D3ED49EF058D6FCBBF24FC7C77E56E63BD58CE162E37C21D`; and difficulty `RESEARCH.md` `1 / 87FC87F1F52316C15B6480EAE1A8CA5ADAF62EBBA0477C9B7E56654B9FCCE5FB`.

### Phase 2: Move coherent bundles

- [x] **2.1 Move the three synthesized concept-study bundles with `git mv` to `.agents/research/concepts/`.**
  - Accept: all images/HTML needed by each bundle moved with it and hashes match.
  - Evidence: all three coherent bundles moved with their HTML/images; Git recorded every file as a 100% rename before link edits.
- [x] **2.2 Move the five generated concept/output bundles to `.agents/evidence/concepts/` and the five QA bundles to `.agents/evidence/` with `git mv`.** Merge only at the directory level; never overwrite existing evidence.
  - Accept: each old directory is absent, each target is complete, and hashes match.
  - Evidence: all ten evidence bundles moved without collision; Git recorded every file as a 100% rename before link edits.
- [x] **2.3 Move difficulty-progression advisory research to `.agents/research/paint-mountain-difficulty-progression/` and its completed checklist to `.agents/execplans/2026-08-13-difficulty-progression-idea-research.md`.** Keep the canonical specification package in place.
  - Accept: PRD, decisions, open questions, draft tasks, and local guidance remain under `project-specs/`; all archived research and the completed checklist have one valid agent-environment owner.
  - Evidence: the canonical package remains in place; the archived dossier and completed checklist moved to their unified owners and all internal/frontmatter paths resolve.

### Phase 3: Repair links and validate

- [x] **3.1 Update every affected link and lifecycle path.** Repair consumers and relative links inside moved READMEs/frontmatter.
  - Accept: targeted stale-path scans exclude only this contract's historical source-to-target mapping and contain no stale live path.
  - Evidence: canonical docs, design context, implementation records, handoffs, historical plans, moved evidence frontmatter, and internal research links now resolve to the new single-owned targets.
- [x] **3.2 Validate with `git diff --check`, `Test-Path`, the manifest, frontmatter inspection, and `git diff --name-status -- docs .agents AGENTS.md`.**
  - Accept: no runtime or handoff path changed and all changed links resolve.
  - Evidence: 45 changed Markdown files passed link resolution; Preflight exactly matches the agent-governor template; one active plan remains; all source paths are absent; target paths, lifecycle sections, patch hygiene, and scope checks pass; no runtime path entered the diff.
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
- Current phase: Phase 3, migration validated.
- Next task: 3.3 Commit the scoped migration, then close this contract in a separate plan-state commit.
- Last completed gate: 148 byte-preserving moves plus lifecycle, Preflight, active-plan, changed-link, stale-path, patch-hygiene, and scope validation.

## Completion and Stop Conditions

Complete only after every task passes and frontmatter is `done`. Replan if a bundle cannot stay coherent at its target or a current user edit overlaps a mapped path.
