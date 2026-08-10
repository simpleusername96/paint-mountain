---
type: plan
status: done
created: 2026-08-10
scope: repository documentation, visual evidence, runtime media assets, and project-local generated artifacts
related:
  - ../PLANS.md
  - ../Documentation.md
  - ../design/DESIGN.md
  - ../../docs/source-brief.md
  - ../../docs/asset-licenses.md
---

# Repository Document and Asset Disposition - Research Checklist

## Purpose

- Decision or research question: Which project documents and assets should be
  retained, lifecycle-repaired, archived, deleted, or left unchanged without
  losing product authority, implementation evidence, license provenance,
  reproducibility, or runtime behavior?
- Why it matters: The repository currently carries substantial historical design
  and validation material alongside active sources. A cleanup based on names,
  age, size, or apparent non-use could delete an authority source, a licensed
  runtime dependency, or evidence needed to interpret the current game.
- Decision owner: The audit executor recommends dispositions; the user approves
  every deletion, move, protected-instruction edit, or active-spec
  supersession.
- Final output: Create
  `.agents/evidence/2026-08-10-repository-hygiene-disposition.md` as a
  path-level disposition matrix with evidence, confidence, exact proposed
  batches, and recoverable-byte totals. The report is advisory and does not
  authorize file changes.

## Observed Starting Point

- The worktree was clean when this checklist was authored.
- `.agents/execplans/` contains 27 prior plans: 19 `done`, 7 `superseded`, and
  1 `archived`; none was active before these two user-requested, separately
  scoped research checklists were created.
- Agent-relevant Markdown currently includes 28 `evidence + active` documents,
  while several older handoff and concept surfaces still use active lifecycle
  metadata. This is a review signal, not proof that any file is disposable.
- The current checkout contains approximately 106 MB under `docs/`, 34 MB
  under `.agents/`, and 2.5 MB under `assets/`; most of the first two totals are
  visual concepts, captures, comparisons, and execution evidence.
- `docs/source-brief.md` is the effective baseline product authority,
  `docs/technical-architecture.md` maps runtime ownership,
  `.agents/Documentation.md` records implemented truth, `.agents/design/`
  controls design interpretation, and `docs/asset-licenses.md` records approved
  asset provenance. These sources must not be treated as ordinary age-based
  cleanup candidates.

## Scope and Evidence Contract

- In scope:
  - Tracked Markdown and adjacent agent-relevant files at the repository root,
    under `.agents/`, and under `docs/`.
  - Tracked runtime fonts, icons, textures, models, VFX, license files, and
    Godot import metadata under `assets/`.
  - Tracked visual concepts, screenshots, comparison sheets, handoff media,
    prototype media, and delivery evidence under `.agents/`, `docs/`,
    `screenshots/`, and `prototypes/`.
  - Ignored `.godot/`, `builds/`, and `reports/` only as a separate local-output
    category whose optional reclaim must never be mixed with tracked-source
    deletion.
- Out of scope:
  - Editing or deleting any file during this research checklist.
  - Rewriting product requirements, design direction, architecture, gameplay,
    or test acceptance to make cleanup easier.
  - Git-history rewriting, dependency changes, package downloads, or creation
    of a new document or asset folder taxonomy.
  - Treating `.uid` or `.import` files as removable without verifying current
    Godot ownership and the repository's tracked-file convention.
- Destructive or irreversible actions: None are permitted while this checklist
  is active. The audit may only read files and write its named evidence report.
- Approval required before: Every deletion or move; edits to protected
  instruction files; superseding an active spec; changing license/provenance
  records; removing an asset used by scenes, resources, themes, scripts, tests,
  exports, or evidence still designated as required; and clearing ignored local
  output.
- Search budget or reassessment point: One complete tracked-file inventory, one
  document-authority/lifecycle pass, one runtime and documentation reference
  pass, one exact-hash duplicate pass, and targeted Git history only for
  unresolved candidates. Reassess scope before a second repository-wide pass.
- Conflict-resolution rule: Follow root and nearest `AGENTS.md`, then the
  effective `docs/source-brief.md`, current canonical specs and design maps,
  `.agents/Documentation.md`, current production references, and the asset
  license ledger. A stale lifecycle label creates a repair candidate; it never
  overrides inspected content or proves deletion safety.
- Stop rule for unproductive exploration: Stop expanding a candidate when the
  disposition is already forced by a canonical/runtime/license dependency, or
  when one exact missing owner decision is the only remaining blocker. Do not
  search unrelated history to increase confidence after sufficient evidence is
  recorded.

| Evidence category | Primary source | Freshness requirement | What it must establish | Sufficient evidence |
| --- | --- | --- | --- | --- |
| Instruction and product authority | Root and nearest `AGENTS.md`, `.agents/PLANS.md`, `docs/source-brief.md`, canonical specs, `.agents/design/DESIGN.md` | Current checkout | Whether a document or visual source can influence future work and which source wins conflicts | Direct content inspection plus all mandatory links from the instruction graph |
| Implemented relevance | `.agents/Documentation.md`, production scenes/scripts/resources, `project.godot`, `export_presets.cfg`, tests | Current checkout | Whether a file represents current behavior, a required fallback, or delivery proof | A current owner or consumer is identified, or current implemented-state text explicitly requires the artifact |
| Document lifecycle | Frontmatter, document content, canonical indexes, inbound Markdown links | Current checkout | Primary type, truthful status, authority ambiguity, duplicates, and safe lifecycle repair | Type/status are supported by content and every canonical or protected claim is resolved |
| Asset use graph | `res://` references in `.tscn`, `.tres`, `.gd`, `.gdshader`, Theme/config/export files, tests, and Godot import metadata | Current checkout after a normal import state exists | Runtime, editor, test, export, or generated-source use | Every exact path and import source has been checked; dynamic or directory-based loading is either traced or recorded as a blocker |
| Provenance and license | `docs/asset-licenses.md`, `assets/**/LICENSE*`, `SOURCE.md`, `GENERATED_ASSETS.md`, file hashes | Current checkout | Whether retention is required for attribution, regeneration, or source identity | Ledger entry, license/source companion, and current file hash agree, or the mismatch is recorded as a blocker |
| Historical and visual evidence | Evidence READMEs, design reference maps, completed plans, targeted `git log --follow --` queries for each exact candidate path | Current checkout; history only when current sources do not settle the role | Whether an artifact is required evidence, a superseded concept, a duplicate, or recoverable history | The artifact's present authority and all inbound references are known; age alone is never sufficient |
| Storage value | Tracked file sizes, exact SHA-256 groups, generated-output classification | Same commit as the disposition report | Exact reclaimable bytes and byte-identical duplicates | Exact path list and hash/size evidence are recorded per proposed batch |

## Viable Options

Apply one option to every candidate. Do not force a repository-wide single
choice.

| Option | Why materially viable | Decision criteria | Disqualifier |
| --- | --- | --- | --- |
| Retain as current | Preserves a canonical source, current runtime dependency, license/provenance record, reproducibility input, or required evidence | Current authority or a verified consumer requires the exact artifact | None; required artifacts are not cleanup candidates |
| Retain with lifecycle repair | Preserves useful content while preventing stale status or authority claims | Content remains useful, but type/status/links or mixed-role sections misstate how future agents should use it | Repair would silently change product authority, evidence into policy, or an active spec without approval |
| Archive or move | Keeps unique history while removing it from active working surfaces | Artifact is unique and historically useful but should not drive current work; every link and index update is known | The repository has no approved destination, the move would create a new taxonomy, or current consumers require the path |
| Delete after approval | Removes proven redundant, obsolete, unreferenced, or regenerated material | Exact path is non-authoritative, has no runtime/export/test/license obligation, adds no unique evidence, and is recoverable from Git or deterministic regeneration | Any unresolved dynamic reference, provenance need, unique evidence, protected status, or owner uncertainty |
| Block and retain pending evidence | Avoids a risky guess when authority, loading, provenance, or unique value cannot be settled | One exact missing source or owner decision is named | General uncertainty without bounded prior checks; continue the planned checks first |

## Tasks

### Phase 1: Establish current truth

- [x] Record the commit, worktree state, tracked-file inventory, ignored
  project-local output categories, and byte totals without modifying files.
- [x] Build the instruction graph from protected instructions through the
  canonical product, architecture, design, implemented-state, test, and asset
  provenance sources.
- [x] Classify all agent-relevant documents by primary lifecycle type and
  truthful status; flag mixed roles, duplicate canonical claims, active
  historical evidence, dead links, and protected-file concerns.
- [x] Build the asset inventory by role: runtime, editor/import metadata,
  generated source, license/provenance, test fixture, delivery evidence,
  exploratory concept, prototype, and ignored local output.
- [x] Remove any disposition option that conflicts with a verified authority,
  runtime/export/test consumer, license duty, or design-reference obligation.

Phase gate:

- Every in-scope path belongs to exactly one inventory role, every current-state
  claim cites inspected evidence, and no deletion candidate exists only because
  of age, size, naming, or line-of-sight non-use.

### Phase 2: Gather decisive evidence

- [x] Trace inbound Markdown links and canonical index claims for every
  document proposed for repair, archive, or deletion.
- [x] Trace exact and dynamic asset loading across scenes, Resources, Theme,
  scripts, shaders, tests, project settings, export settings, and import
  metadata; record unresolved dynamic loaders as blockers.
- [x] Compare exact hashes and content roles to identify byte-identical or
  semantically duplicated media without assuming that resized comparisons or
  captures are interchangeable.
- [x] Verify license, source, generated-asset, and reproducibility obligations
  for every non-project-original asset candidate.
- [x] Use targeted Git history only when current content and references cannot
  establish why a candidate exists or whether history alone is an adequate
  recovery path.
- [x] Populate the evidence report with one row per candidate: path, role,
  authority/consumer evidence, provenance, bytes, recommended disposition,
  confidence, exact approval boundary, and blocker if any.

Phase gate:

- Every candidate has enough evidence for one disposition, or one exact missing
  input or authority is identified. Proposed delete batches have complete exact
  path lists and byte totals.

### Phase 3: Decide and record

- [x] Summarize counts and bytes for retain, lifecycle repair, archive/move,
  delete-after-approval, and blocked categories without changing the tree.
- [x] Separate non-destructive lifecycle corrections from move/delete batches
  so approval for one category cannot authorize another.
- [x] Record rejected cleanup candidates when the rationale prevents the same
  risky proposal from recurring.
- [x] Present the exact proposed move/delete batches and optional ignored-output
  reclaim as separate user approval decisions.
- [x] If the user approves implementation, create a new Mode 3 execution
  contract with exact paths, link/index updates, asset-import consequences,
  validation commands, rollback behavior, and scoped commits. Do not convert
  this research checklist into the cleanup implementation plan.

Phase gate:

- The advisory disposition is complete or the single specific blocker is
  named; no cleanup action is implied or authorized.

## Progress and Next Steps

- Canonical progress: the task checkboxes in this checklist.
- Current phase: Complete.
- Next task: Execute the non-destructive repairs in
  `2026-08-10-repository-maintenance-corrections.md`; request exact approval
  before any delete or local-output reclaim batch.
- Last completed gate: The disposition report records retained, repair,
  blocked, and exact delete-after-approval paths with byte totals.
- Update rule: Check an item only when its evidence exists. Do not repeat a
  completed repository-wide pass unless the commit, authority graph, or
  candidate set changes materially.

## Verification

- Validate the evidence report's exact paths against `git ls-files` and the
  current filesystem.
- Recompute SHA-256 and byte totals for only the proposed duplicate/delete
  batches before requesting approval.
- Run `git diff --check` for the research-report change. Do not run Godot or
  mutate imports merely to complete document-only classification; run
  `scripts/verify.ps1` later only if an approved asset cleanup changes project
  inputs.

## Risks

- Godot resources can be loaded indirectly, so a simple text-reference count is
  not proof that an asset is unused.
- Historical captures can be large yet still be the only evidence behind an
  accepted visual decision.
- License and source files may be required even when the corresponding media is
  small or apparently unused.
- Lifecycle repair, archival, and deletion are distinct actions with distinct
  authority; combining them would make approval ambiguous.

## Completion and Stop Conditions

Complete when:

- Every required primary source has been inspected, or its unavailability after
  the bounded fallback is recorded as the exact blocker.
- Every in-scope path has a role and every non-retain candidate has direct
  authority/reference/provenance evidence.
- The named evidence report contains the final disposition, exact proposed
  batches, byte totals, supporting rationale, confidence, and any evidence that
  can expire after a later commit.
- The user has been asked for separate approval of exact move/delete and local
  output-reclaim batches; lack of approval leaves the checklist decision
  complete but authorizes no file change.
- Frontmatter status changes to `done` after the decision or one specific
  blocker is recorded.

Escalate when:

- A required authority, dynamic loader, provenance record, or license source
  remains unresolved after the bounded checks.
- Primary sources materially conflict and the established authority order does
  not resolve them.
- A proposed disposition needs protected-file edits, active-spec supersession,
  a new folder taxonomy, or deletion/move authority.

If cleanup implementation follows, invoke `$goal-checklist-builder` in Mode 3,
`$doc-lifecycle-steward` in repair mode, `$uiux-gate` for any player-facing
asset effect, and `$codebase-quality-auditor` after any cross-module reference
change.
