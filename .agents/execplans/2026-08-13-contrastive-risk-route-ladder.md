---
type: plan
status: active
created: 2026-08-13
scope: implement and validate the thirty-stage Contrastive Risk-Route Ladder
related:
  - ../PLANS.md
  - ../../docs/source-brief.md
  - ../../docs/design-spec.md
  - ../../docs/technical-architecture.md
  - ../design/DESIGN.md
  - ../../project-specs/paint-mountain-difficulty-progression/PRD.md
  - ../../project-specs/paint-mountain-difficulty-progression/DECISIONS.md
---

# Contrastive Risk-Route Ladder — Execution Contract

Paint Mountain will replace an implicit one-number difficulty curve with an
authored, typed challenge ladder. The thirty all-open stages remain the same
deterministic game: inspect a distant mountain, choose a launch, fire without
in-flight steering, and accumulate authoritative target paint. Difficulty will
come from visible route contrast, transfer, reversal, mechanism sequencing, and
multi-shot planning rather than a new control or score.

## Purpose

- Objective: implement the active PRD's five-band, six-role progression and
  readable safe/high-leverage route opportunities.
- Deliverable: versioned challenge metadata and comparison contracts, thirty
  re-authored materialized profiles and baked layouts, one compact localized
  Stage Select label, focused and production validation, and updated durable
  implementation evidence.
- Completion state: the promoted catalog passes every structural and regression
  gate; representative Windows release stages are readable in running captures
  and the fixed playtest protocol; Windows/Web release artifacts pass; no new
  gameplay rule, score authority, save field, dependency, or service exists.

## Scope

In scope:

- Stage challenge identity, band/role/reference metadata, and pure comparison
  rules derived from current stage and route data.
- Role-aware retuning of current progression and route profiles for all thirty
  stages.
- Exact canonical-seed regeneration and atomic promotion of a new catalog
  contract version.
- A short Korean/English focus label in the selected-stage preview.
- Deterministic structural tests, representative running-game playtests and
  captures, release exports, and active-spec/implementation-record updates.

Out of scope:

- New controls, post-fire steering, physics forces, mechanisms, projectiles,
  cannons, upgrades, random stages, prescribed routes, runtime solvers, route
  arrows, or solution hints.
- Adaptive difficulty, player-skill estimation, network telemetry, attempt
  history persistence, challenge contracts, mastery badges, or a second score.
- Re-pagination or redesign of Stage Select, gameplay HUD additions, result
  panel additions, deployment, or publishing.

Constraints and invariants:

- `StageController` remains the only stage-state, shot, timer, clear, and result
  owner.
- `PaintSystem` remains the only mutable paint mask and coverage owner.
- The thirty stages remain all-open and keep their canonical IDs and legacy
  aliases.
- Current target, shot, duration, star, canonical-seed, and mechanism-kind
  contracts remain unchanged.
- Stage 01 remains mechanism-free; Stage 02 remains the first Burst example;
  Stage 03 remains the three-route Splitter example; Stage 08 remains the first
  Uphill Rebound example.
- Safe/challenge routes are authoring opportunities, not certified solutions.
  No route outcome mapping enters the catalog, save, HUD, or diagnostics.
- Catalog build and promotion remain complete and atomic. No partial set of new
  stages may become the active pointer.

Destructive or irreversible actions:

- Catalog promotion replaces the active generated bundle pointer. The previous
  content-addressed bundle remains recoverable in git and generated history.
  Do not promote until the full dry build and representative inspection pass.

Required approvals:

- No new dependency, external service, deployment, or destructive cleanup is
  authorized. Ask before any such expansion.
- Before the final broad gate, tell the user that it runs the complete catalog
  build, test suite, two release exports, and capture matrix; state the expected
  machine cost and stopping condition, then obtain alignment as required by the
  repository validation policy.

## Discovery Closure

| Concern | Verified evidence | Locked decision | Task |
| --- | --- | --- | --- |
| Current curve | `StageProgressionData` controls target, shots, time, terrain, routes, reversals, relief, width, and mechanisms; `difficulty_score_for()` has no runtime consumer | Retire scalar monotonicity as the product contract; keep current resource/tier ownership | 1.2, 2.1 |
| Route authoring | `StageRouteProfile` already has `PRIMARY`, `SAFE`, `SPLITTER`, and `BUMPER` roles, widths, grade signs, bends, and ordered mechanism slots | Express the new tradeoff through current typed route data | 2.2 |
| Catalog path | Materializer and offline builder create one exact canonical layout and atomically publish a versioned bundle | Increment the generation contract to v11; dry-build before one promotion | 3.1-3.3 |
| Player explanation | Current geometry/glyphs are the primary teaching surface; Stage Select already owns selected-stage facts | Add one focus label to Stage Select only | 4.1-4.2 |
| Diagnostics | Shot/attempt observations already contain aim, contact, mechanism, settlement, coverage, and checksum facts; saves do not hold attempts or skill | Use local observations for the playtest worksheet; do not change save schema | 5.2 |
| Selection evidence | Twelve candidates were frozen and scored; C12 leads because it joins contrastive sequencing and in-stage route choice without a new runtime rule | Implement the active PRD without reopening rejected systems | All |

Readiness statement:

- Product behavior, data ownership, UI scope, persistence, catalog versioning,
  acceptance thresholds, and fallback behavior are closed.
- Numeric terrain tuning may move within the locked structural contracts during
  authored calibration; it is not a product-scope decision.

## Locked Stage Structure

| Stages | Band focus | Lesson roles in stage order | Required learning outcome |
| --- | --- | --- | --- |
| 01-06 | Contact and Descent | Anchor, Contrast A, Contrast B, Transfer, Interleave, Fusion | Predict how first contact, slope, Burst, and Splitter distribute continuous paint |
| 07-12 | Route Choice | Anchor, Contrast A, Contrast B, Transfer, Interleave, Fusion | Compare a robust corridor with a narrower high-leverage route; Stage 08 introduces Uphill Rebound |
| 13-18 | Reversal and Recovery | Anchor, Contrast A, Contrast B, Transfer, Interleave, Fusion | Plan grade reversals and useful continuation after an imperfect landing |
| 19-24 | Mechanism Chains | Anchor, Contrast A, Contrast B, Transfer, Interleave, Fusion | Predict ordered multi-mechanism consequences on different route shapes |
| 25-30 | Fusion and Robustness | Anchor, Contrast A, Contrast B, Transfer, Interleave, Fusion | Choose complementary launches across the accumulated paint state and combine prior route skills |

Stages 11, 12, 17, 18, 23, 24, 29, and 30 must contain one `SAFE` route and one
non-`SAFE` challenge route. The safe route is at least 4 m wider. The challenge
route has at least one additional mechanism slot or one additional grade
reversal. Both must be visible from the authored inspection/aim camera, but
neither is guaranteed to clear.

## Architecture Ownership

| Owner | Change | Must not absorb |
| --- | --- | --- |
| New `StageChallengeProfile` at `src/stage/stage_challenge_profile.gd` | Typed Band, LessonRole, Axis, localized focus key, reference stage ID, and held axes | Geometry copies, mutable state, result logic, or UI formatting |
| New `StageChallengeContract` at `src/stage_generation/stage_challenge_contract.gd` | Pure facts/comparisons derived from `StageData`, generation profiles, and route profiles; band sequence and route-pair validation | Runtime solving, player modeling, or stored coverage |
| `StageData` | Reference one immutable challenge profile | Difficulty decisions or mutable attempt state |
| `StageProgressionData` | Map each stage number to band, role, focus, reference, declared axes, and current numeric tiers | Runtime adaptation or a replacement paint/geometry representation |
| `StageCatalogMaterializer` | Materialize challenge profile and role-aware route values into typed stage data | Candidate search or hand-authored runtime repair |
| `StageCatalogData` and v11 generation contract | Reject incomplete challenge metadata and invalid thirty-stage ordering | Route outcome certification or partial catalog admission |
| `StageSelectScreen` and its scene | Present one localized two-to-four-word focus label in the selected-stage preview | Lesson-role prose, route hints, score changes, or gameplay state |
| Existing observations | Supply local evidence for the representative worksheet | Save progression, replay, adaptive state, or UI messages |

The comparison fact set is fixed: mechanism-kind sequence, route count and
endpoint span, minimum route width, maximum route reversal count, maximum
ordered mechanism slots on one route, and target coverage per available shot.
Contrast A, Contrast B, and Transfer profiles must reference an earlier stage,
change their declared primary axis, and declare at least two held axes that the
pure contract confirms. This fact set is derived at validation time and is not
serialized as a second truth.

## Tasks

### Phase 1: Establish typed challenge ownership

- [ ] **1.1** Add `StageChallengeProfile`, reference it from `StageData`, and
  define the five bands, six lesson roles, comparison axes, focus keys,
  reference-stage rule, and held-axis rule.
  - Accept: all new data is immutable stage configuration; no runtime or save
    state changes.
- [ ] **1.2** Add `StageChallengeContract` and
  `tests/stage_challenge_ladder_test.gd`. Replace the scalar monotonic assertion
  in `tests/stage30_progression_test.gd` with the typed band/role and derived
  comparison contracts. Remove `difficulty_score_for()` after all references
  are gone.
  - Accept: a deliberately wrong role order, reference, varied axis, held axis,
    or safe/challenge route pair fails the focused test.
- [ ] **1.3** Bump `StageGenerationContract.CONTRACT_VERSION` and related typed
  catalog/profile identities from v10 to v11. Keep `SaveSystem.SAVE_VERSION` at
  5 because no persisted player data changes.

### Phase 2: Author the thirty-stage ladder

- [ ] **2.1** Make `StageProgressionData` and the materializer emit the locked
  five-band/six-role table while preserving current target, shot, duration,
  star, canonical-seed, and early mechanism contracts.
  - Accept: 30/30 profiles have the expected band and role; 15/15 Contrast A,
    Contrast B, and Transfer entries pass primary/held-axis comparisons.
- [ ] **2.2** Retune route profiles for the five focus bands. Add the required
  `SAFE`/challenge pairs to Stages 11, 12, 17, 18, 23, 24, 29, and 30 using the
  4 m width and one-slot-or-reversal rules.
  - Accept: 8/8 pairs pass on materialized profiles; no route result or solution
    metadata exists.
- [ ] **2.3** Run exact-stage diagnostics and inspect generated graybox renders
  for Stages 01, 06, 12, 18, 24, and 30. Retune only route/profile values until
  the intended focus and advanced route pair are visible from the authored
  cameras.
  - Stop: if legibility would require overlays, new cameras, or a source-brief
    change, use the predetermined fallback instead of expanding scope.

### Phase 3: Build and promote one complete v11 catalog

- [ ] **3.1** Run a complete `--dry-build` and bundle verification. Record any
  exact stage/profile rejection before changing content.
- [ ] **3.2** Correct only task-owned profile, placement, camera, or admission
  failures. Do not loosen canonical geometry, prediction parity, target-mask,
  paint, resident-capacity, or atomic-bundle safeguards.
- [ ] **3.3** Run one complete `--write` after the dry build is green, verify the
  staged bundle, and promote the v11 pointer atomically.
  - Accept: 30/30 stages hydrate with matching identities, checksums,
    mechanisms, target masks, entry witnesses, and challenge profiles.

### Phase 4: Add restrained Stage Select context

- [ ] **4.1** Add one `PreviewFocus` label to the selected-stage preview and
  localize the five focus values in Korean and English. Do not change card
  pagination, gameplay HUD, result panel, or saved data.
- [ ] **4.2** Extend focused localization, essential-copy, stage-select, and
  responsive UI tests.
  - Accept: the label is two-to-four words, updates immediately with selection
    and locale, and fits at 1280x720, 1600x900, and 1920x1080 without clipping.

### Phase 5: Validate gameplay, presentation, and release contracts

- [ ] **5.1** Run focused challenge/catalog/early-mechanism/UI checks during the
  inner loop, then `scripts/verify.ps1` after source/resource/scene changes
  stabilize.
- [ ] **5.2** Run the representative protocol on Stages 01, 06, 12, 18, 24, and
  30 with at least three hypothesis/retry attempts per stage. Save an English
  worksheet containing intended route, launch change, first contact, mechanism
  sequence, coverage gain, failure cause, and next-shot change from current
  observations.
  - Accept: every failed attempt has a specific visible cause and specific
    next-shot change; the tester identifies both advanced route opportunities
    before firing on Stages 12, 18, 24, and 30.
- [ ] **5.3** After the required user alignment for broad validation, run the
  complete test suite once, export Windows and Web release builds, validate the
  Web artifact, and use the task-owned background delivery runner for Korean
  Stage Select plus Stages 01, 06, 12, 18, 24, and 30 at 1280x720. Capture
  Stage 30 at 1920x1080 in English as the high-resolution localization guard.
  - Accept: all processes exit cleanly, no Godot error appears, and the
    implementing agent inspects every running-game image.
- [ ] **5.4** Run `$codebase-quality-auditor` over the multi-file, shared-data,
  generator, and UI change. Fix only small task-scoped ownership, contract,
  reachable-failure, or validation gaps; rerun affected focused gates.

### Phase 6: Preserve durable truth and hand off

- [ ] **6.1** Update `docs/design-spec.md`, `docs/technical-architecture.md`, and
  `.agents/design/UIUX_GUIDELINES.md` with the implemented challenge and compact
  focus-label contracts. Do not rewrite the effective source brief.
- [ ] **6.2** Update `.agents/Documentation.md` and `docs/test-checklist.md` with
  the exact v11 catalog identity, commands, results, playtest worksheet, and
  separate running-game capture paths.
- [ ] **6.3** Commit only task-owned files in coherent scoped commits and mark
  this plan `done` only after all acceptance checks pass. Deployment remains a
  separate user request.

## Validation Commands

Use the shared Godot 4.7.1 console executable resolved by `GODOT_BIN` or
`D:\tools\Godot\4.7.1-stable\Godot_v4.7.1-stable_win64_console.exe`.

Focused examples:

```powershell
& $env:GODOT_BIN --headless --path . --script res://tests/stage_challenge_ladder_test.gd
& $env:GODOT_BIN --headless --path . --script res://tests/stage30_progression_test.gd
& $env:GODOT_BIN --headless --path . --script res://tests/phase7_ui_test.gd
& $env:GODOT_BIN --headless --path . --script res://tests/localization_ui_test.gd
```

Catalog gates:

```powershell
& $env:GODOT_BIN --headless --path . --script res://scripts/build_stage_catalog.gd -- --dry-build
& $env:GODOT_BIN --headless --path . --script res://scripts/build_stage_catalog.gd -- --write
```

Broad final gate, run once after stabilization and user alignment:

```powershell
pwsh -NoProfile -File scripts/verify.ps1 -GodotPath $env:GODOT_BIN
pwsh -NoProfile -File scripts/test.ps1 -GodotPath $env:GODOT_BIN
& $env:GODOT_BIN --headless --path . --export-release 'Windows Desktop' 'builds/windows/PaintMountain.exe'
& $env:GODOT_BIN --headless --path . --export-release 'Web' 'builds/web/index.html'
pwsh -NoProfile -File scripts/verify-web-release.ps1 -ReleaseDirectory builds/web
```

Representative production capture template:

```powershell
& builds/windows/PaintMountain.exe --capture-screen=aiming --capture-stage=stage_12 --capture-output=<task-evidence-path> --capture-size=1280x720 --capture-language=ko --capture-background
```

## Validation and Rework Controls

| Cadence | Check | Run when |
| --- | --- | --- |
| Inner loop | Challenge ladder, progression, exact affected stage, early mechanism, and Stage Select tests | Relevant data, generation, or UI changes |
| Phase gate | `scripts/verify.ps1` and representative graybox/running render | Source/resources/scenes and representative content stabilize |
| Catalog gate | Full dry build, bundle verification, then one write/promotion | All thirty materialized profiles are stable |
| Final gate | Complete suite, Windows/Web exports, Web validator, capture matrix, representative worksheet | Implementation and docs are stable and the user aligns with the cost |

Do not repeatedly run the full suite, exports, or complete catalog build for
small tuning changes. Use exact-stage diagnostics and focused tests until the
content set is substantially complete.

## Predetermined Contingencies

| Trigger | Response |
| --- | --- |
| A safe/challenge pair is structurally valid but unreadable | Retune width, endpoint separation, route bend, mechanism slot, or authored camera within the existing profile; do not add overlays |
| The dual-route rule cannot be made readable for a named stage | Keep its band/role and contrast sequence, relax the dual-route requirement for that stage through an explicit PRD/decision update, and use its primary structural axis; do not silently waive validation |
| A complete v11 build rejects one stage | Diagnose that exact stage and correct its task-owned profile; do not promote a partial catalog or weaken shared geometry/prediction/paint guards |
| Representative attempts fail for opaque or different reasons | Reduce simultaneous secondary changes or revise the declared reference/held axes, then regenerate the affected stage |
| Stage Select focus text clips | Shorten the localized focus value or adjust the existing preview layout token; do not redesign cards or add scrolling prose |
| Save migration appears necessary | Stop; challenge metadata is catalog configuration and must not require a save version change under this plan |

## Regression Guards

- No change to `StageController` decision ownership or `PaintSystem` paint and
  coverage ownership.
- No fourth mechanism, post-fire steering, runtime randomness, wind, replay,
  resident-ball HUD, passive shot/mechanism messages, or sensitivity setting.
- No stage locks or change to canonical IDs, legacy aliases, target/shot/time
  tiers, star thresholds, or all-open selection.
- No second terrain, coverage, or solution representation.
- No runtime catalog generation or partial/fallback catalog activation.
- No solution arrows, hidden assists, route scoring, or compulsory route.

## Progress

- Current phase: ready for implementation; no implementation task has started.
- Completed discovery: local owner map, direct precedents, distant analogues,
  four exploration rounds, twelve-candidate ledger, weighted comparison,
  selected PRD, and Korean explanation.
- Next task: Phase 1.1 after implementation is requested.
- Canonical progress: this checklist only; `project-specs/.../TASKS.md` is a
  derived milestone index.

## Next Steps

- Begin Phase 1.1 only after the user requests implementation.

## Completion and Stop Conditions

Complete when every task passes, the active v11 catalog and release artifacts
meet all PRD acceptance criteria, separate running-game evidence has been
inspected, durable implementation truth is updated, task-owned changes are
committed, and this plan is marked `done`.

Stop and ask if implementation requires a new dependency/service, save schema,
source-brief change, deployment, destructive cleanup, weakened safeguard, or a
player-facing system outside the locked scope.
