---
type: plan
status: active
created: 2026-08-06
last_reviewed: 2026-08-06
scope: truthful initial-launch Fire capacity and baked deterministic stage-layout loading
source: user-reported disabled Fire with ammunition remaining and excessive stage preparation latency, diagnosed against the 2026-08-06 repository state
related:
  - ../PLANS.md
  - ../Documentation.md
  - ../../AGENTS.md
  - ../../docs/source-brief.md
  - ../../docs/design-spec.md
  - ../../docs/technical-architecture.md
  - ../../docs/test-checklist.md
  - ../design/DESIGN.md
  - 2026-08-06-ballistic-terrain-preparation.md
  - 2026-08-06-wind-driven-coverage-loop.md
---

# Fast Stage Entry and Truthful Fire Capacity - Execution Contract

Paint Mountain will keep its two concurrent initial-launch limit, but a
Splitter child or wind-woken resident will no longer hold that Fire slot. Stage
entry will stop rebuilding terrain and searching for default/summit aims at
runtime; it will asynchronously load one validated, content-addressed baked
layout instead. The current Stage 30 placement failure will be resolved by the
offline catalog builder selecting and persisting the first fully valid candidate
from the existing deterministic candidate domain, never by weakening placement
rules at runtime.

## Purpose

- Objective: make Fire availability match the intended initial-root-launch rule
  and reduce cold stage entry from the current roughly 10-11 seconds to the
  existing under-three-second product target.
- Deliverable: separated launch-slot and shot-observation lifecycles, one baked
  layout resource/codec, a format-4 content-addressed catalog bundle, a threaded
  runtime layout repository, bounded offline default/summit witnesses, truthful
  loading/failure UI, and focused regression evidence.
- Completion state: ammunition is consumed only by an accepted Fire; descendants
  and reawakened residents never occupy a released launch slot; normal app,
  gameplay, and delivery paths contain no terrain generation or aim solving;
  all 30 catalog entries load their exact baked layouts; representative cold
  Stage 01 and Stage 30 entry complete within three seconds on the current
  Windows test machine; and the production build starts with the baked bundle.

## Scope and Boundaries

In scope:

- `ProjectileManager` initial-root-launch capacity, separate shot-family
  observation completion, and current resident-cap admission.
- `StageController` Fire-readiness integration and capacity reason text.
- Lossless baked persistence of accepted `GeneratedStageLayout` data.
- Offline candidate selection, two bounded real first-hit entry witnesses, and
  atomic generated-catalog publication.
- Asynchronous selected/prefetch loading, three-layout LRU retention, explicit
  load failure/retry, and runtime fallback removal.
- Focused code checks, one explicit all-stage artifact build, representative
  runtime timing/render evidence, docs, and production export/start.

Out of scope:

- Raising or removing the two concurrent initial-launch limit.
- Deleting terrain-resident paintballs, changing ammunition, wind, paint,
  scoring, stage duration, glyph effects, or camera interaction.
- Proving a first-hit witness for every target-mask texel. The stronger
  target-wide `DirectReachabilityCertificate` requirement remains a separately
  recorded unfinished guarantee; this plan produces only the default and summit
  witnesses required to remove runtime searches and does not claim that the
  target-wide certificate exists.
- Weakening target, range, route, slope, glyph-kind, placement, containment, or
  summit validators to make a candidate pass.
- Serializing meshes, collision shapes, scene nodes, textures, mutable paint,
  preview artifacts, or runtime physics state.
- A broad live-generation sweep, exhaustive per-pixel physics run, multi-
  resolution matrix, or micro-tolerance test suite.
- Removing unrelated dirty-worktree evidence, generated bundles, screenshots,
  probes, or user-authored changes.

No production dependency, plugin, service, asset pack, network access, or save
data migration is required.

## Verified Root Cause and Discovery Closure

| Concern | Current evidence | Root cause | Locked correction | Tasks |
| --- | --- | --- | --- | --- |
| Fire is disabled while shots remain | The captured Stage 04 state shows `남은 탄 2` with disabled Fire and `포탄 2개 진행 중`. `StageController.fire_readiness_snapshot()` correctly checks ammunition separately from `ProjectileManager.active_root_count()` | `ProjectileManager` retains one launch slot while **any** non-resting projectile with the same `shot_id` exists. Splitter children keep their root `shot_id`, so descendant motion is incorrectly counted as root-launch capacity | Keep the two-slot policy and make capacity depend only on each root's one-time initial launch | 1.1-1.3 |
| A simple slot fix could truncate shot records | `shot_family_finished` currently drives `ShotObservation` sealing after paint queues drain | One dictionary and one completion signal currently represent two different lifecycles: root launch admission and all first-flight family bodies | Maintain separate initial-root and unsettled-family registries. Release Fire from the first; keep observation completion on the second | 1.1-1.3 |
| Cold preparation takes about ten seconds | Current focused execution measured Stage 01 generation at 10,242 ms | The worker removes a main-thread freeze but still performs full height synthesis, 512x512 route/target scans, connected-component work, placement, decoration, and ballistic-domain sampling on every cold process | Persist accepted immutable outputs once and load them; do not tune the runtime loops as the primary solution | 2.1-4.4 |
| Stage 30 does not merely load slowly | The same current run rejected Stage 30 after 11,370 ms with `UPHILL_REBOUND`, `mechanism_placement`, and `kind_suitability` | The hand-maintained accepted-candidate index is stale after the version-8 keyed sampler/glyph contract changed | Search the fixed candidate indices 0-31 only in the explicit offline build, persist the first full-valid seed/index, and fail publication if none passes | 3.1-3.3 |
| An urgent selected stage can wait behind irrelevant work | `StageLayoutPreparer` has one active `Thread`; a running menu preview or next-stage prefetch cannot be preempted | Urgent and speculative work share one serial generation worker | Replace preparation with independent threaded resource requests: at most one current selection and one prefetch may be pending, and selected loading starts immediately | 4.1-4.2 |
| Prepared layout is not a complete runtime handoff | `GameplayScene` regenerates synchronously when preparation identity fails, searches for a default aim when missing, and always searches for a summit aim | Runtime still owns recovery generation and bounded physics solving | Fail closed before scene entry and consume baked layout/default/summit data only | 2.1-4.3 |
| Current bundle cannot supply the handoff | Active format-3 manifest `v8-1170.../manifest.json` has no layout paths and no certificates | The content-addressed bundle persists inputs, not accepted layout outputs | Add binary baked layouts and positional paths to format 4 while keeping generation contract version 8 | 2.1-3.3 |
| Disabled-state wording is ambiguous | `fire.capacity` says `포탄 2개 진행 중`, which can look like ammunition exhaustion beside the remaining-shot count | The UI does not name the initial-root-launch rule; calling it a general flight limit would also be false while descendants or reawakened residents move | Report `초기 발사 동시 한도 2/2` / `INITIAL LAUNCH LIMIT 2/2`; retain the authoritative remaining-shot display | 1.2, 4.4 |

Readiness statement:

- The two reported symptoms have independent, code-confirmed causes.
- Optimizing the generator alone is rejected because it leaves candidate search,
  target work, runtime fallback, and two physics aim searches on the entry path.
- Removing or raising Fire capacity is rejected because it hides the lifecycle
  error and weakens the planning rule.
- The remaining implementation choices are local encoding and integration work;
  they do not require a product decision.

## Domain Alignment and Ownership

| Term | Exact meaning in this plan | Owner |
| --- | --- | --- |
| Initial root launch | The one-time period from admission of a generation-0 root until that root first rests on valid terrain or terminates | `ProjectileManager` |
| Initial-launch slot | One of two admission slots occupied only by an active initial root launch | `ProjectileManager`; read by `StageController` |
| Descendant | A Splitter-created projectile with `split_generation > 0` and the parent's `shot_id`; never a launch-slot owner | `ProjectileManager` and Splitter |
| Resident | Any still-present projectile, moving or resting, including descendants and wind-woken bodies | `ProjectileManager` |
| Unsettled shot family | Same-`shot_id` bodies whose first-flight observation still has a non-resting member | `ProjectileManager`; consumed by `StageController` observation sealing |
| Accepted candidate | The first candidate in deterministic index order 0-31 that passes the existing complete structural/layout validators and this plan's two bounded entry-witness checks | Offline catalog builder |
| Baked layout | Schema-versioned immutable primitive payload reconstructed into one runtime `GeneratedStageLayout` without generation or physics search | `BakedStageLayoutData` and `StageLayoutBakeCodec` |
| Runtime-ready layout | A hydrated layout whose stage identity, structural data, target mask, checksums, and bounded default/summit witnesses validate | `GeneratedStageLayout` and codec |
| Layout repository | App-owned asynchronous loader and three-entry hydrated-layout cache; it never generates | `StageLayoutRepository` |

Invariants:

1. `StageController` remains the only Fire admission and ammunition owner.
2. `ProjectileManager` remains the only initial-launch/resident lifecycle owner.
3. A rejected Fire action consumes zero ammunition.
4. A root launch releases its slot permanently at first valid-terrain rest or any
   terminal stop. Later root wake cannot reacquire it.
5. Descendants never add, retain, or reacquire an initial-launch slot.
6. Shot-family observation completion remains later than or equal to the last
   first-flight family member's rest/termination; releasing Fire must not seal a
   moving Splitter child's observation.
7. Current stages remain within the hard 21-resident bound before admission.
8. Runtime uses exactly the accepted seed and baked artifact referenced by the
   active catalog. It never searches, substitutes, repairs, or regenerates.
9. `PaintSystem`, terrain geometry, target mask, and gameplay state ownership do
   not change.
10. A missing, malformed, mismatched, or corrupt artifact fails closed and leaves
    the current page usable; it never triggers a generator fallback.

## Locked Technical Design

### A. Separate Fire capacity from shot-family observation

- Replace the current overloaded tracking with two explicit registries:
  `_active_initial_launch_shot_ids` for Fire capacity and
  `_unsettled_shot_family_ids` for observation completion.
- Generation-0 spawn adds the `shot_id` to both registries. Child spawn adds no
  capacity entry and continues under the existing family entry.
- When a generation-0 projectile first enters `RESTING_ON_TERRAIN`, remove its
  capacity entry, emit one `initial_root_launch_finished(shot_id)` signal, and
  publish activity/readiness. Waking that root does not add it again.
- When a generation-0 projectile stops for any reason, perform the same permanent
  release. Splitter consumes the parent before admitting children, so both the
  root-stop activity publication and the family-completion refresh occur at one
  deferred post-admission boundary. Capacity may be released at that boundary,
  but family completion must scan the three already-admitted children and must
  not emit between parent consumption and child spawn.
- Independently scan all same-`shot_id` bodies for first-flight family
  completion. `shot_family_finished(shot_id)` retains its current observation
  meaning and fires only when no family body remains non-resting.
- Invalid-instance pruning refreshes both registries using their different
  predicates. Cleanup clears both without re-enabling Fire after terminal entry.
- Keep `StageController.fire_readiness_snapshot()` as the canonical gate. Its
  two-slot, shots, state, terminal, aim, prediction-currentness, and prediction-
  fireability checks remain intact.
- Make `ProjectileManager` the single resident-expansion policy owner. It exposes
  the runtime replacement check used by Splitter instead of leaving
  `_active.size() - 1 + child_count` arithmetic in `SplitterNode`, and exposes
  the matching stage upper-bound helper used by catalog admission. Per-root
  maximum is `1` without a valid Splitter, otherwise
  `child_count ^ maximum_split_generation` because each split consumes its
  parent. The locked current data therefore requires
  `maximum_shots * 3 <= 21`. This is a bounded current-policy check, not a
  general branching simulator.

### B. Persist accepted layout outputs, not runtime objects

- Add `BakedStageLayoutData extends Resource` with
  `BAKED_LAYOUT_SCHEMA_VERSION := 1`, and keep serialization/hydration logic in
  `StageLayoutBakeCodec` rather than converting runtime graph/topology classes to
  `Resource`.
- Add an immutable runtime `StageEntryAimWitness` value for the bounded default
  and summit evidence. The baked Resource still stores only its primitive fields.
- Save each artifact as binary `.res` to avoid a very large textual target mask:

  ```text
  res://resources/generated_stage_catalogs/v8-<content-hash>/
    catalog.tres
    manifest.json
    stages/stage_01.tres
    profiles/stage_01_profile.tres
    layouts/stage_01_layout.res
  ```

- The payload contains only immutable accepted primitives:
  - stage/profile/layout identity, requested/accepted seed, candidate index, and
    generation attempt;
  - cell count, local bounds, height samples, footprint cells, height checksum,
    target mask, and target checksum. Hydration derives the runtime
    `maximum_height` metric from the height array; arbitrary generation
    diagnostic Dictionaries are not persisted or integrity-bearing;
  - route-node and route-edge fields in canonical order;
  - containment checksum and the fixed containment contract;
  - mechanism loadout index plus placement transform/route/tangent/branch data,
    so the artifact does not duplicate `MechanismData` tuning;
  - decoration model ID, local XZ, yaw, and scale arrays;
  - default and summit aim tuples; predictor and physical hit identity primitives
    (`contact_owner_id`, `contact_shape_id`, body-shape index, terrain cell,
    triangle, and barycentric coordinates); predicted/physical local impacts;
    target point; target pixel or summit-region identity; and the existing
    distance/range/height margin context; and
  - one canonical semantic `payload_sha256` covering the ordered integrity-
    bearing primitive payload. Schema 1 defines a fixed field order,
    length-prefixed UTF-8 strings/arrays, little-endian signed 64-bit integers,
    IEEE-754 little-endian float32 grid arrays, and float64 scalar/vector/
    transform fields. The codec rejects non-finite values, normalizes negative
    zero, and feeds footprint/target bytes exactly. No `Dictionary`, Resource
    byte serialization, platform iteration order, or raw `.res` file bytes enter
    this hash. The manifest repeats the semantic hash.
- Hydration reconstructs route objects, mechanism/decor placements, the fixed
  containment object, and `TerrainTopTopology` from the baked grid. It installs
  the exact footprint and target mask and then checks stage identity, structural
  validity, height/target/placement/containment checksums, payload hash, and both
  aim-witness identities.
- Add `generated_summit_aim` and a summit-aim accessor to
  `GeneratedStageLayout`, backed by the two `StageEntryAimWitness` values.
  `is_runtime_ready()` requires valid structural/mask data and valid generated
  default/summit witnesses. With no certificate, accessors use those generated
  witnesses. A present complete, valid, matching `DirectReachabilityCertificate`
  is authoritative; a present invalid/incomplete/mismatched certificate rejects
  the artifact and never silently falls back. Certificate absence does not
  become a false certification claim.
- Continue to use `copy_for_runtime()` so cached immutable source layouts cannot
  receive mutable gameplay annotations.

### C. Make the catalog builder the only generation/search/solve path

- Bump only `BUNDLE_FORMAT_VERSION` from 3 to 4. Keep the current generation and
  replay contract versions unchanged because persistence transport alone does
  not change gameplay semantics.
- Add positional `layout_paths: Array[String]` and canonical
  `get_layout_path(stage_id)` lookup to `StageCatalogData`. Do not store direct
  layout Resource references, because that would eagerly load all 30 artifacts.
- Compute the bundle content hash from a canonical ordered feed of bundle/schema
  versions, stage/profile descriptors, relative artifact names, and each layout
  payload hash. Exclude final content-addressed paths, the manifest pointer, and
  serialized Resource file bytes so the address does not depend on itself or on
  editor serialization details.
- Remove the hand-maintained accepted-candidate map from
  `StageProgressionData`. Keep only the deterministic base/candidate seed
  formula. During explicit publication, process candidates in index order 0-31,
  run the existing full layout validation for each, select the first pass, and
  persist its seed in `StageData` and its index in the layout/manifest.
- Add one explicit `SeededStageGenerator.generate_candidate_once(stage,
  candidate_seed)` (or exact equivalent) that builds and finalizes exactly that
  seed. The outer builder loop must not call `generate_structural_sequence()`,
  whose internal attempt loop would create a nested search. Before acceptance,
  assert `generation_attempt == 0` and
  `stage.terrain_seed == profile.base_seed == terrain_seed == accepted_seed ==
  candidate_seed_for(stage, index)`.
- Do not alter `kind_suitability` or special-case Stage 30. If Stage 30's current
  index 6 fails, the next full-valid candidate wins by the same rule as every
  other stage.
- After layout acceptance, construct one temporary physics fixture and produce:
  1. a target-mask first-hit aim selected nearest the target centroid; and
  2. a separate first-hit aim for the canonical highest terrain band.
- Reuse the current predictor and real Rigidbody validation path for those two
  witnesses only. A default fallback is valid only if its predicted and physical
  first contact is playable top and lies on the target mask; never persist the
  current fabricated `AimTuple(0, 38, 68)` fallback or a collision with another
  body. Summit validation must hit the canonical summit region.
- Do not enumerate or certify every target texel in this plan.
- The bounded path may call `solve_one_target()`, summit validation, and one
  single-witness Rigidbody validation for each role. It must not call the target-
  wide `validate_predictor()` path or `build_reachability_certificates.gd`.
- Build the bundle in staging, save all 30 binary layouts, reload/hydrate each,
  verify its semantic checksum and witnesses, write the manifest/catalog, then
  atomically promote the immutable bundle before promoting the root catalog
  pointer. Any stage failure leaves the current bundle and pointer intact.
- The long `--write` path is explicit artifact production and runs once after
  the schema and validators stabilize. The no-argument path is a fast check that
  branches before `_build_catalog()`, loads/validates the active catalog and
  artifacts directly, and never materializes candidate data, generates,
  searches, or opens a physics fixture.

### D. Load baked layouts without a serialized priority bottleneck

- Rename `StageLayoutPreparer` to `StageLayoutRepository`; update AppRoot, tests,
  and architecture terms together.
- Use `ResourceLoader.load_threaded_request()` for catalog-provided `.res` paths
  and poll completion from `_process()`. Do not keep the manual generator
  `Thread`, `LayoutJob`, injectable generation strategy, or `wait_to_finish()`
  path.
- Allow at most one selected-stage request and one low-priority prefetch request
  to be pending independently. A new selected stage starts immediately even if
  a menu-preview/next-stage request is already loading. Obsolete results may be
  validated and cached but may not enter the wrong stage.
- Retain at most three hydrated immutable layouts using the current LRU policy.
  Retain at most one main-thread preview artifact as today.
- Load completion validates the Resource script/schema, path/stage identity,
  payload hash, hydrated layout, and both baked witnesses before emitting
  `layout_ready`. Any mismatch emits `layout_failed` and is never cached.
- AppRoot keeps the visible page interactive while loading. The selected Start/
  Play action reports loading; on failure it becomes an explicit retry action.
- `GameplayScene` requires the exact prepared layout. Remove its synchronous
  `SeededStageGenerator.generate()` fallback and both runtime
  `DefaultAimSolver` calls. The delivery capture path also consumes the baked
  summit witness rather than solving one at runtime.
- `DefaultAimSolver` remains an offline builder helper only. Production
  `src/app`, `src/gameplay`, and `src/delivery` code may not call generation or
  aim solving.

### E. Keep the UI change small and truthful

This is UIUX Level 2: existing primary actions and readiness surfaces change
state/copy, but no new screen, theme, HUD composition, or interaction model is
introduced.

- Replace `ui.preparing_stage` semantics with `ui.loading_stage`:
  `LOADING STAGE...` / `스테이지 불러오는 중…`.
- Use `STAGE LOAD FAILED` / `스테이지 불러오기 실패` and an explicit
  `RETRY LOAD` / `다시 불러오기` action after failure.
- Format the Fire capacity reason from authoritative counts as
  `INITIAL LAUNCH LIMIT %d/%d` / `초기 발사 동시 한도 %d/%d`.
- Keep the remaining-ammunition display unchanged and visible beside this state.
- Verify the affected loading/failure and aiming-capacity surfaces at 1280x720
  in Korean. One focused production capture per changed surface is sufficient;
  do not create a broad visual regression matrix.

## Tasks

### Phase 0: Preserve the current baseline and authority

Goal: start from the completed version-8 wind/glyph implementation without
absorbing unrelated worktree changes or reopening superseded plans.

Source owners: this plan, current git state, `.agents/Documentation.md`, effective
product/spec documents

- [ ] **0.1** Record the implementation baseline and protect unrelated changes.
  - Change: inspect `git status --short`, the active catalog pointer/manifest,
    the current `trajectory_predictor` and reachability-validator edits, and the
    latest implementation record before touching overlapping files. Stage and
    commit only task-owned files.
  - Accept: no unrelated evidence, screenshot, probe, generated bundle, or user
    hunk is reverted, staged, or claimed.
- [ ] **0.2** Align current docs with this bounded repair.
  - Change: record baked runtime loading and the two separate projectile
    lifecycles without marking target-wide certification complete.
  - Accept: source brief remains authoritative; design, architecture, status,
    checklist, and this plan use the same definitions.

Batch gate:

- The baseline and dirty ownership are explicit, and no implementation file has
  been changed before conflicts are understood.

### Phase 1: Correct Fire-slot semantics

Goal: Fire capacity follows generation-0 initial launches while shot observation
continues to include moving Splitter descendants.

Source owners: `src/projectile/projectile_manager.gd`,
`src/stage/stage_controller.gd`, `src/stage/stage_catalog_data.gd`, translations,
projectile/rapid-fire tests

- [ ] **1.1** Split launch-slot and family-observation tracking.
  - Change: add the two registries and distinct completion paths described in
    Locked Design A; release capacity once on root rest/stop; retain
    `shot_family_finished` until all first-flight family bodies rest/terminate.
  - Accept: a consumed root with moving Splitter children frees one Fire slot,
    while that shot observation stays open for later child events; no
    `shot_family_finished` or observation seal occurs between parent consumption
    and admission of all three children.
- [ ] **1.2** Keep authoritative Fire admission and resident capacity truthful.
  - Change: keep StageController's existing gate, publish the updated count in
    readiness/activity snapshots, move Splitter's runtime expansion arithmetic
    behind the manager-owned capacity API, add the same current-policy
    21-resident catalog admission bound, and apply the dynamic capacity copy.
  - Accept: two active roots reject a third Fire without spending ammunition;
    one released root makes Fire ready as soon as the current prediction permits;
    resident/wind activity never reacquires capacity.
- [ ] **1.3** Replace the regression that currently codifies the defect.
  - Change: update `projectile_family_capacity_test.gd` and the existing rapid-
    fire contract test for root rest/wake, Splitter-child motion, capacity
    rejection/no-ammo-consumption, and one representative terminal root.
  - Accept: these focused contracts pass and `shot_observation_test.gd` still
    seals only after its proper family boundary.

Batch gate:

- Initial launch, descendant motion, observation sealing, ammunition, and the
  21-resident guard pass together before stage-loading integration.

### Phase 2: Add the baked layout schema and lossless codec

Goal: one accepted layout can survive save/load/hydration without generation,
scene objects, or ambiguous identity.

Source owners: new `src/stage_generation/baked_stage_layout_data.gd`, new
`src/stage_generation/stage_layout_bake_codec.gd`,
new `src/stage_generation/stage_entry_aim_witness.gd`,
`src/stage_generation/generated_stage_layout.gd`, route/topology/placement data,
`src/stage/stage_catalog_data.gd`, new codec test

- [ ] **2.1** Implement the schema-1 primitive payload and codec.
  - Change: encode the exact fields in Locked Design B, compute the canonical
    semantic SHA-256, save binary `.res`, hydrate runtime graph/topology/
    placements, and reject malformed or mismatched payloads.
  - Accept: a fixture layout round-trips with identical core arrays, route IDs,
    target/height/placement/containment checksums, decorations, and witness
    tuples; one corrupted payload fails closed.
- [ ] **2.2** Make runtime readiness include the two bounded witnesses.
  - Change: add the generated summit witness alongside the current generated
    default aim, reconstruct both full `StageEntryAimWitness` identities, copy
    both through runtime isolation, apply the explicit absent/valid/invalid
    certificate policy, and validate their stored target/summit top identities.
  - Accept: a hydrated layout missing either witness cannot enter gameplay; a
    future complete certificate can still override/validate the same roles.
- [ ] **2.3** Add lazy artifact paths to catalog identity.
  - Change: add and validate one canonical positional layout path for every
    ordered stage without eagerly loading the Resources.
  - Accept: duplicate, missing, noncanonical, wrong-stage, or out-of-bundle paths
    invalidate the catalog/artifact handoff.

Batch gate:

- Schema, semantic hash, exact round trip, runtime-copy isolation, and lazy
  catalog lookup pass before the active bundle is rebuilt.

### Phase 3: Produce and atomically publish the accepted bundle

Goal: all generation, candidate search, and entry-witness solving happen once in
the explicit offline build, including a valid replacement for Stage 30's stale
candidate.

Source owners: `scripts/build_stage_catalog.gd`,
`src/stage_generation/stage_progression_data.gd`, offline aim/validator helpers,
generated catalog resources and manifest, catalog/progression tests

- [ ] **3.1** Replace the stale accepted map with bounded build-time selection.
  - Change: use the exact one-candidate generator for indices 0-31 in
    deterministic order, persist the first full-valid seed/index, assert the
    exact candidate identity/attempt, and remove runtime/StageProgressionData
    reliance on a hand-maintained accepted map.
  - Accept: Stage 30 no longer attempts the rejected index-6 layout; the selected
    candidate passes the unchanged `UPHILL_REBOUND` kind-suitability and all
    existing finalization checks. No valid candidate means no publication.
- [ ] **3.2** Bake one real default and one real summit witness per stage.
  - Change: after structural acceptance, use one temporary fixture to select and
    validate only the two bounded first-hit witnesses, then encode their stable
    identities with the layout.
  - Accept: each default first-hits playable target top near the target centroid;
    each summit aim first-hits the canonical highest band; predictor and real
    body identities/impacts agree under the existing functional contract. No
    target-wide validator or certificate-builder path runs.
- [ ] **3.3** Publish format 4 as one transaction.
  - Change: generate all 30 layouts once under `--write`, save/reload/hydrate and
    validate every staged artifact, compute the bundle hash, write manifest and
    catalog paths, promote the immutable bundle, then promote the root pointer.
  - Accept: the manifest lists 30 canonical layout paths, payload hashes,
    accepted seeds/indices, and witness identities; a fast no-argument check
    takes its early load-only branch without catalog materialization, generation,
    search, or physics; old bundles remain recoverable and are not rewritten in
    place.

Batch gate:

- One complete format-4 bundle is active, every artifact hydrates, Stage 30 is
  valid under unchanged rules, and the normal check path performs no generation.

### Phase 4: Replace runtime preparation with bounded artifact loading

Goal: selected stages load promptly and independently of speculative prefetch,
and gameplay has no hidden recovery generation or aim solve.

Source owners: renamed `src/app/stage_layout_repository.gd`, `src/app/app_root.gd`,
`src/gameplay/gameplay_scene.gd`, `src/delivery/delivery_capture_runner.gd`, main
menu/stage-select scripts, translations, renamed repository test

- [ ] **4.1** Implement threaded artifact requests and the three-entry LRU.
  - Change: replace the generator worker with `ResourceLoader` threaded requests,
    independently track current selection and one prefetch, validate/hydrate
    completed data, and retain at most three source layouts.
  - Accept: a selected request starts while a deliberately delayed prefetch is
    pending; wrong/obsolete results cannot enter another stage; missing/corrupt
    resources emit failure; retention never exceeds three.
- [ ] **4.2** Integrate AppRoot loading, preview, failure, and retry.
  - Change: route selected/menu-preview/next-stage requests through the repository,
    retain the one-preview-artifact bound, show the exact loading/failure copy,
    and let the failed primary action retry the same artifact.
  - Accept: navigation remains usable during a cold request, Start cannot enter
    with a mismatched layout, and retry never invokes generation.
- [ ] **4.3** Remove every production generation/solver fallback.
  - Change: require prepared runtime-ready data in gameplay and delivery capture;
    consume baked default/summit aims; delete calls to `SeededStageGenerator` and
    `DefaultAimSolver` from app/gameplay/delivery paths.
  - Accept: a source guard finds no such call in those production subtrees, and
    missing data produces a truthful load failure before gameplay construction.
- [ ] **4.4** Prove the changed runtime boundary and visible states.
  - Change: replace the old injectable-generation preparer test with a repository
    test; run representative Stage 01/30 entry timing; capture Korean loading or
    failure and two-flight capacity states at 1280x720.
  - Accept: both representative cold entries meet the existing under-three-
    second target on the current Windows machine; the implementing agent inspects
    the focused captures for copy fit, remaining-shot clarity, clipping, and
    button state.

Batch gate:

- Stage requests load independently, runtime fallback is absent, representative
  entry latency meets the product target, and the changed UI states are truthful.

### Phase 5: Audit, verify, export, and close the plan

Goal: hand off one coherent implementation and current evidence without turning
this repair into an exhaustive certification or visual program.

Source owners: all task-owned code/resources/tests/docs,
`scripts/verify.ps1`, export preset, `.agents/Documentation.md`,
`docs/test-checklist.md`, this plan

- [ ] **5.1** Run the cross-module quality audit and make only scoped fixes.
  - Change: invoke `codebase-quality-auditor` over slot/family ownership, artifact
    codec/catalog boundaries, runtime fallback removal, failure handling, and
    stale preparer terminology.
  - Accept: no competing capacity, generation, layout cache, or default-aim
    owner remains; no catch-all file absorbs unrelated work.
- [ ] **5.2** Run focused checks and the mandatory repository gate once.
  - Change: run the named task tests while implementing, then the fast catalog
    check and `scripts/verify.ps1` once after integration.
  - Accept: all pass without changing validators, adding dependencies, or
    absorbing unrelated files.
- [ ] **5.3** Export and inspect the production boundary.
  - Change: export `builds/windows/PaintMountain.exe`, start only that executable
    through the existing background capture path, enter representative Stage 01
    and Stage 30, and capture the corrected Fire-capacity state.
  - Accept: the exported build contains/loads the format-4 artifacts, starts
    cleanly, meets the coarse entry target, and the focused running-game evidence
    matches the behavioral checks.
- [ ] **5.4** Close status and plan truthfully.
  - Change: record exact artifact hash, timing, tests, capture paths, and known
    remaining target-wide certification gap; mark this plan `done` only after all
    required work passes.
  - Accept: implementation status and checklist distinguish this completed
    repair from the unimplemented exhaustive certificate; the final commits
    contain only task-owned changes.

## Validation and Rework Controls

Resolve the approved Godot console executable without assuming it is on `PATH`:

```powershell
$paintMountainGodot = 'D:\npjt\cardborne-platformer\.codex-runtime\godot-4.7.1-stable\Godot_v4.7.1-stable_win64_console.exe'
if (-not (Test-Path -LiteralPath $paintMountainGodot)) {
    throw 'Approved Godot executable is unavailable.'
}
```

Focused checks:

```powershell
& $paintMountainGodot --headless --path . --script res://tests/projectile_family_capacity_test.gd
& $paintMountainGodot --headless --path . --script res://tests/rapid_fire_contract_test.gd
& $paintMountainGodot --headless --path . --script res://tests/shot_observation_test.gd
& $paintMountainGodot --headless --path . --script res://tests/baked_stage_layout_test.gd
& $paintMountainGodot --headless --path . --script res://tests/stage_layout_repository_test.gd
```

Artifact production and final gates:

```powershell
# Run once after schema, generation, placement, and witness inputs stabilize.
& $paintMountainGodot --headless --path . --script res://scripts/build_stage_catalog.gd -- --write

# Fast check: load and validate only; no generation or physics.
& $paintMountainGodot --headless --path . --script res://scripts/build_stage_catalog.gd

powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\verify.ps1 -GodotPath $paintMountainGodot
& $paintMountainGodot --headless --path . --export-release 'Windows Desktop' 'builds\windows\PaintMountain.exe'
& '.\builds\windows\PaintMountain.exe' --capture-background --capture-screen=progression_aiming --capture-stage=stage_30 --capture-size=1280x720 --capture-output=res://.agents/evidence/fast-stage-entry-and-fire-capacity/stage_30_aiming-1280x720.png
& '.\builds\windows\PaintMountain.exe' --capture-background --capture-screen=two_family --capture-size=1280x720 --capture-output=res://.agents/evidence/fast-stage-entry-and-fire-capacity/two_family-1280x720.png
```

Cadence and stopping rules:

- Run the narrowest affected test during each task.
- The explicit all-30 `--write` command is required artifact production, not an
  inner-loop test. Run it only after its inputs stabilize; rerun only after a
  relevant artifact input changes.
- The no-argument catalog check must stay fast and generation-free.
- Run `scripts/verify.ps1`, export, production start, and focused captures once
  after integration. Explain their cost and stopping condition before starting
  the broad gate.
- Do not add a per-pixel target certificate, exhaustive trajectory grid, every-
  stage live playthrough, repeated performance sampling, fine numeric tolerance
  matrix, or redundant screenshot set to this plan.
- A failure is re-run only after a relevant code/data change or a new hypothesis.

## Predetermined Contingencies and Change Control

| Trigger | Required response | Forbidden shortcut |
| --- | --- | --- |
| No candidate 0-31 passes for a stage | Stop bundle publication, retain the active pointer, report per-validator rejection counts, and request a separate generation-policy decision | Loosening validators, cropping target, hand-authoring X/Z, or runtime substitution |
| Default or summit witness cannot be physically validated | Reject that candidate and continue the same bounded candidate order; if the domain exhausts, stop as above | Persisting a guessed/default tuple or running a runtime solver |
| Baked load/hydration still exceeds three seconds | Profile load, hydration, topology, mesh, and collider stages once; optimize only the measured owner while preserving the baked boundary | Restoring runtime generation or eager-loading all 30 layouts |
| Artifact missing/corrupt/mismatched | Keep the current screen usable, show load failure, log stable identity details, and allow explicit retry | Entering gameplay with partial data or silently using another seed |
| Fire fix causes early observation sealing | Restore/repair the separate unsettled-family registry and prove child events remain in the observation | Making descendants hold Fire capacity again |
| A complete target-wide certificate already exists for a stage | Attach and validate it against the baked layout; keep the bounded generated witnesses consistent | Claiming absent certificates were produced by this plan |
| Payload shape changes after schema 1 ships | Bump the baked schema and bundle format, rebuild atomically, and keep old bundle recovery | Reinterpreting old bytes under the same schema |
| Task implementation overlaps an unrelated dirty hunk | Preserve and merge around the user-owned hunk; stop and ask only if intent truly conflicts | Revert, reset, blanket staging, or claiming the unrelated change |

Any change to ammunition, the two-slot policy, resident cap, target mask,
generation validator thresholds, candidate-domain size, full-certification scope,
dependencies, or external assets requires an explicit plan update before code.

## Progress

- [x] Confirmed the Fire-disabled symptom against the running-game evidence and
  traced the authoritative readiness path.
- [x] Confirmed descendant-retained capacity and the existing test that encodes
  the wrong behavior.
- [x] Confirmed current generation timings, Stage 30's exact placement rejection,
  serialized worker bottleneck, gameplay fallback, and runtime aim searches.
- [x] Compared the current format-3 bundle, catalog builder, progression seed
  map, layout data model, export policy, and relevant product/design contracts.
- [x] Locked the split lifecycle and baked-layout architecture.
- [ ] Implementation complete.
- [ ] Focused checks, artifact build/check, repository verification, and quality
  audit pass.
- [ ] Production export/start, representative timing, rendered evidence, docs,
  and scoped commits complete.

## Stop Conditions

Stop and report rather than broadening this plan if candidate indices 0-31 are
exhausted for any stage, either bounded witness cannot be obtained, binary
artifacts cannot be loaded in the Windows export, a required dirty hunk has
conflicting ownership, or completion would require a validator change,
target-wide certificate, dependency, asset, save migration, gameplay-rule
change, or destructive cleanup.
