---
type: plan
status: active
created: 2026-08-13
scope: replace terrain glyph mechanisms with a limited-preview ball queue, nine intrinsic ball behaviors, and two-color paint objectives
supersedes: 2026-08-13-shared-propellant-progression.md
related:
  - ../PLANS.md
  - ../../docs/source-brief.md
  - ../../docs/design-spec.md
  - ../../docs/technical-architecture.md
  - ../design/DESIGN.md
  - ../design/ART_DIRECTION.md
  - ../design/UIUX_GUIDELINES.md
  - ../design/VISUAL_REFERENCES.md
---

# Queued Ball Types and Paint Ownership — Execution Contract

## Purpose

Replace the current rule "one basic ball is changed by terrain glyphs" with a
planning rule in which each queued ball already owns a visible behavior and
paint color. The player sees the current ball and the next three balls, aims
and fires the current ball, and plans around an unseen fifth position and later
tail. Terrain glyph UI, world art, runtime scripts, generator contracts, and
serialized mechanism data are removed after their ball-owned replacements are
working.

This plan also replaces Shared Propellant. It does not combine propellant with
the queue.

## Verified Context

| Concern | Current evidence | Consequence |
| --- | --- | --- |
| Projectile source | `CannonController` currently uses one hardwired `basic_paintball.tres`; `ProjectileManager` can already spawn supplied `ProjectileData` | Add queue identity at the launch boundary instead of branching inside the cannon |
| Rule owner | `StageController` owns stage state, accepted Fire, shot progression, reset, and terminal decisions | It owns the queue cursor, preview snapshot, and clear/failure result |
| Paint owner | `PaintSystem` owns one L8 paint mask used by terrain visuals and coverage | Evolve that one mask to carry paint ownership; never add a parallel color mask |
| Prediction | Prediction caches by aim context and assumes the basic ball | Current ball identity must be part of cache validity and solver input |
| Split capacity | Resident capacity is 21, while the maximum stage has seven root shots | A three-child, non-recursive split remains within 21 residents when a root is replaced by its children |
| Catalog | Active catalog generation is v10 and serializes glyph loadouts, placements, roles, and checksums | Queue migration is a v11 catalog schema change, not a hand edit of active v10 data |
| Persistence | Save schema v5 stores one scalar best coverage and cannot prove per-color completion | Migrate to v6; archive v5 bests as legacy rather than claiming a color clear |
| UI | The right edge between Run Status and Aim controls is available; the world center must stay clear | Add one compact vertical queue rail, not a new dashboard or center overlay |
| Agent parity | Human and future in-process AI must use the same actions and observations | Public observations expose only the same four visible queue positions, never the hidden tail |
| Glyph reach | Glyph contracts span `src/mechanisms`, scenes/resources, gameplay wiring, generation, catalog serialization, observations, UI, localization, audio/effects, and tests | Removal must replace the complete data path; hiding glyph meshes is insufficient |

## Locked Product Decisions

### Queue rule

- A stage has a finite queue with exactly `maximum_shots` entries.
- The visible horizon is four entries: one large **NOW** ball and three smaller
  **NEXT** balls. The fifth entry and all later entries are absent from the UI
  and public agent observation.
- A successful root launch consumes the current entry and advances the queue
  immediately. Rejected launch attempts consume neither a shot nor a queue
  entry. Derived children do not consume queue entries.
- There is no Hold, swap, reroll, ball selection, purchase, or skip action.
- The full queue is materialized from an authored stage bag by the catalog
  builder and stored deterministically. Stages 01-09 use authored teaching
  sequences. Stages 10-30 use a seeded bag shuffle during catalog generation.
  Restart reproduces the same stage queue, so a failed attempt remains
  learnable and replayable.
- The player may know which behavior types can occur in a stage from Stage
  Select, but not their hidden order. Runtime debug tooling may inspect the
  full queue only in debug builds.
- Queue tokens show two independent facts: the ball silhouette/icon identifies
  behavior, while the filled center and `A`/`B` accessible label identify paint
  color. Color never identifies behavior by itself.

### Ball roster: nine total

The stable behavior IDs below are product data. Numeric tuning starts with the
listed defaults and may move inside typed Resources after play evidence; the
trigger, number of uses, child count, and strategic job may not change without
revising this plan.

| ID and player name | Exact behavior | Planning job |
| --- | --- | --- |
| `standard` — Standard | Current paintball behavior: continuous contact painting, ordinary bounce and roll, no special trigger | Baseline route coverage and readable comparison |
| `impact_burst` — Impact Burst | On its first valid terrain-top contact, publishes one paint stamp with radius `3.0 ×` the Standard trail radius, plays a burst effect, and removes the body. It does not push other balls | Trade route length for a large precise first-contact patch; replaces Burst glyph |
| `apex_split` — Apex Split | On the first airborne vertical-velocity crossing from positive to non-positive before terrain contact, replace the root with three non-recursive Standard children. Child yaw offsets are `-12°`, `0°`, `+12°`; each inherits `92%` horizontal speed, adds `1.5 m/s` upward speed, uses `72%` scale, and keeps the parent paint channel and shot family | Cover separated ridges from one planned apex; replaces Splitter glyph |
| `hyper_bounce` — Hyper Bounce | Uses initial bounce `0.93`, friction `0.08`, and linear damping `0.02`. It can enter the ordinary resting state only after staying below `3.0 m/s` for `0.75 s` on a surface within `16°` of horizontal; otherwise it keeps rebounding normally | Forces a high, flat landing plan or risks leaving the useful terrain |
| `anchor` — Anchor | First valid terrain-top contact converts the ball to zero bounce and high friction, preserves a small precise contact mark, and leaves the resident body asleep at that point | Guarantees a precise stop on a narrow shelf or steep route junction |
| `climber` — Climber | On first valid terrain-top contact only, redirect once toward the local steepest uphill tangent at `65%` of pre-impact speed with a `5.0 m/s` upward component; then behave as Standard | Reach terrain above the first contact; replaces Uphill Rebound glyph |
| `wide_roller` — Wide Roller | Uses `1.65 ×` paint-trail radius, `1.8 ×` mass, high ground friction, and Standard launch speed; no discrete trigger | Paint broad, gentle shelves efficiently but lose distance on steep climbs |
| `triple_skimmer` — Triple Skimmer | For exactly its first three valid terrain-top contacts, redirect along the incoming surface tangent at a `12°` lift angle while retaining `78%` speed; three visible shell fins disappear one per skip. After the third skip it becomes Standard | Cross three small gaps with a countable, bounded ricochet budget |
| `contact_fuse` — Contact Fuse | First valid terrain-top contact arms a `0.8 s` fuse. The ball continues ordinary physics, then paints a `2.0 ×` radial stamp at its current valid terrain-top contact and removes itself. If airborne when the fuse expires, the burst waits until the next valid terrain-top contact | Make the player predict where momentum carries an armed ball, distinct from immediate Impact Burst |

All special triggers are deterministic, generation-one, and represented in a
typed behavior Resource or narrow behavior component. `PaintProjectile` must
not become a switch statement that owns all nine rules. Every child and effect
retains the root `shot_id`, paint channel, and observation family.

### Ball progression and bag composition

- Introduction order is fixed: Stage 01 Standard, 02 Impact Burst, 03 Apex
  Split, 04 Anchor plus the second paint color, 05 Hyper Bounce, 06 Climber,
  07 Wide Roller, 08 Triple Skimmer, and 09 Contact Fuse.
- On Stages 02-09, the introduced ball occurs at least twice and Standard fills
  remaining entries. The first visible horizon contains the introduced ball.
- Stages 10-15 use Standard plus two rotating non-standard types; Stages 16-21
  use Standard plus three; Stages 22-27 use Standard plus four; Stages 28-30
  use Standard plus five. Every included type appears once before the bag may
  repeat a type.
- From Stage 04 onward, both paint colors occur at least twice when the shot
  count permits, and the first four visible entries include both colors.
- Catalog validation rejects a queue with an unknown type/color, wrong length,
  recursive split payload, missing required color, more than three split
  children, or a teaching-stage order that violates the rules above.

## Color Rule Alternatives

| Candidate | Player rule | Strength | Failure mode | Decision |
| --- | --- | --- | --- | --- |
| Fixed color quotas plus latest-writer overwrite | Meet total, blue, and orange minimums; later paint owns an overlap | Sequence matters, final state is visible, no hidden history | Repainting can reduce one color quota | **Selected** |
| Total coverage plus complementary cancellation | Any color counts, but blue-over-orange or orange-over-blue erases the overlap | Dramatic and easy to state | Non-monotonic coverage makes contact edges punitive and hidden future balls can invalidate a good shot | Reject |
| Neutral blend | Overlap becomes a third neutral color that counts partially | Softer than erasure and visually expressive | Adds a third score state and ambiguous threshold math | Reject |
| Color-locked terrain zones | Blue and orange score only on matching authored zones | Strong spatial routing puzzle | Requires a second immutable target classification, more world markup, and renewed symbol-like terrain presentation | Reject |
| Color as behavior decoration only | All colors contribute to one scalar total | Lowest implementation risk | Queue order matters much less and color carries no planning meaning | Reject |

### Selected paint and clear rule

- The stage palette is fixed, not randomized: Paint A is blue `#2584FF` and
  Paint B is orange `#FF8A3D`. The pair is visually distinct, but `A`/`B`
  labels and behavior silhouettes ensure no decision relies on hue alone.
- Stages 01-03 use Paint A only and keep the existing total target coverage
  rule. Stages 04-30 require all three conditions at Finish or timeout:
  `total >= stage_target`, `A >= A_min`, and `B >= B_min`.
- Per-color minimums are derived from the stage's existing total target:
  Stages 04-09 use `A_min = B_min = 30% × stage_target`; Stages 10-18 use
  `35%`; Stages 19-30 use `40%`. Values are materialized as exact floats in
  stage resources and displayed as percentages of the complete Target Area.
- Thresholds and the queue are stable for a stage. Random clear requirements
  are prohibited because attempts, results, and best records must be directly
  comparable.
- Later paint overwrites the owner/color at touched pixels. Coverage strength
  becomes `max(existing_strength, incoming_strength)`, so repainting can move
  area from A to B or B to A but cannot reduce total painted area. There is no
  cancellation, mixing, additive coat depth, or hidden paint history.
- Meeting the thresholds does not auto-end the run. The existing Finish action
  or timeout requests terminal evaluation. `StageController` returns Clear only
  if every threshold is met; otherwise it returns Failed with the unmet totals.
- Stars and score continue to use total target coverage. A failed result cannot
  outrank a cleared result even if its raw total is higher.

## Paint Representation and Ownership

- Replace the single-channel mutable paint image with one authoritative
  multi-channel image/byte buffer owned by `PaintSystem`. It stores coverage
  strength and current owner channel per target pixel and publishes the one
  runtime texture consumed by the terrain shader.
- Do not create separate A and B masks. Per-color physical-area totals are
  derived counters maintained from changes to the authoritative buffer and are
  rebuildable from it.
- Every paint command carries a typed `PaintChannel` plus the existing contact
  geometry. Split children inherit the parent channel. Behavior effects publish
  through the same paint command boundary as trails.
- The terrain shader selects the stage palette color from the owner channel and
  coverage strength. Non-target paint remains visible but does not contribute
  to total or per-color objective values.
- `PaintSystem` publishes one immutable coverage snapshot containing total,
  Paint A, and Paint B percentages. `StageController`, results, observations,
  and HUD consume that snapshot; none recalculates pixels.

## UI and Visual Direction

This is a Level 3 flow change under the current UI gate because it adds a
repeated HUD component, changes result information, changes Stage Select
content, and removes world interaction markers.

- Add a compact vertical queue rail at the right edge, below Run Status and
  above Aim controls. NOW is a 52 px token; the three NEXT tokens are 36 px.
  Use the existing quiet edge-aligned visual language and no large backing
  card. Keep the mountain center and top center open.
- Show the queue during Briefing, Aim View, and Map View. Hide it during Shot
  Follow and terminal screens. Empty end-of-queue positions disappear rather
  than display fake unknown balls.
- A token uses a behavior silhouette plus paint-colored center. Accessible
  names and tooltips use the form `Impact Burst · Paint A`; color alone and a
  terrain-rune pattern are never the sole cue.
- Replace the left scalar coverage readout with total coverage plus two compact
  rows: blue `current / required` and orange `current / required`. Keep one
  coverage component; do not add a second dashboard panel.
- Stage Select removes mechanism names and shows the unordered set of possible
  ball behaviors for the stage. It does not show the hidden queue tail.
- On each first-introduction stage only, Briefing may show one learning-surface
  line such as `Impact Burst — bursts on first ground contact`. It disappears
  on Start and never becomes an in-play toast or floating world label.
- Remove every terrain glyph mesh, label, charge ring, cooldown indicator, and
  mechanism selection cue. Terrain composition must read through shelves,
  slopes, gaps, landings, paint, balls, and trajectory rather than runes.
- Use non-symbolic 3D silhouettes: smooth Standard, compact spiked Burst,
  three-lobed Split, ring-caged Hyper Bounce, weighted Anchor, finned Climber,
  oversized Roller, three-fin Skimmer, and capped Fuse. Paint color remains a
  separate material channel.
- The initial trajectory remains an initial-flight aid. Apex Split may show one
  small apex/split marker on the existing dotted arc, but child paths and all
  post-contact outcomes remain unpredicted.
- Render QA must check Korean and English at 1280×720, 1600×900, and 1920×1080,
  including four queue tokens, final one/two/three-token tails, both paint rows,
  all nine icons, and Clear/Failed results.

## Architecture Ownership

| Owner | Change | Must not absorb |
| --- | --- | --- |
| New `BallQueueData` / `QueuedBallData` typed Resources | Immutable ordered behavior and paint-channel entries plus validation | Runtime cursor, HUD nodes, or launch acceptance |
| Existing/new typed projectile behavior Resources | Physics tuning and one bounded intrinsic trigger | Stage progression, queue order, paint metrics, or UI copy |
| `StageController` | Queue cursor, preview snapshot, accepted-launch advance, objective evaluation, and clear/failure | Projectile physics, pixel writes, or HUD layout |
| Cannon/prediction boundary | Use the current entry's projectile data and include ball identity in prediction validity | Queue mutation or hidden-tail access |
| `ProjectileManager` | Generic root/child spawning, family capacity, and typed behavior event routing | Stage clear rules or per-type queue policy |
| Narrow behavior components | One deterministic behavior trigger each | Global stage state or a nine-kind catch-all switch |
| `PaintSystem` | One owner-aware mask, overwrite semantics, shader publication, and coverage snapshot | Clear decision, result ranking, or UI text |
| Catalog v11 owners | Materialize queues/objectives, remove glyph schemas, validate all thirty stages, and promote one active catalog | Runtime randomness or fallback repair |
| HUD child components | Display supplied queue/objective state and emit narrow intent | Reading gameplay singletons or calculating thresholds |
| Observation/API owners | Expose current plus next three, fired behavior/color, effects, and objective snapshot | Exposing hidden entries or a separate simulation |
| `GameState` save owner | v6 migration and clear-first best-result comparison | Paint calculations or stage locking |

## Glyph Replacement and Removal Inventory

Removal happens only after queue, intrinsic behaviors, and v11 catalog
materialization pass focused checks. Git history is the recovery path.

### Delete after replacement

- `src/mechanisms/`, `scenes/mechanisms/`, and `resources/mechanisms/`, including
  Burst, Splitter, Uphill Rebound, resolver, base glyph, materials, `.uid` files,
  labels, charges, and cooldowns.
- Glyph-only generation owners:
  `mechanism_glyph_anchor.gd`, `mechanism_loadout_planner.gd`,
  `mechanism_placement_generator.gd`, and `mechanism_placement.gd`.
- Glyph-only tests:
  `glyph_aim_view_composition_test.gd`, `mechanism_placement_test.gd`,
  `stage2_burst_glyph_contract_test.gd`, `stage3_glyph_route_contract_test.gd`,
  `stage8_uphill_glyph_contract_test.gd`, and the obsolete mechanism-only
  portions of `phase5_mechanism_test.gd`.
- Generated v9/v10 catalog bundles after a promoted v11 bundle no longer reads
  or references them. Do not remove them before the v11 hydration and checksum
  gates pass.

### Rewrite in place

- Remove `mechanism_loadout`, placements, mechanism counts, glyph anchors,
  `BURST`/`SPLITTER`/`UPHILL_REBOUND`/`BUMPER` serialized roles, tangents, and
  mechanism checksum inputs from stage data, route profiles, generated layouts,
  bake codec, bundle store, materializer, catalog validation, seeded generator,
  route graph owners, and progression scoring.
- Replace terrain role `BUMPER` with the behavior-neutral `LANDING_SHELF` in
  v11. Preserve useful terrain geometry while deleting the old serialized
  mechanism vocabulary and compatibility aliases.
- Remove gameplay mechanism scene loading, spawn/registration, selection,
  reset, signals, node paths, debug toggles, and result/attempt wiring.
- Replace generic presentation event name `mechanism` with `ball_effect`; replace
  mechanism effect IDs and audio cue names with behavior-owned IDs.
- Remove mechanism lists/descriptions from Stage Select and normal UI,
  localization, debug UI, shot/attempt observations, and agent API. Replace only
  facts that remain relevant with queued-ball and `ball_effect_triggered` facts.
- Replace or extend affected generation, content, observation, UI, localization,
  family-capacity, and test-runner checks. Do not leave ignored mechanism fields
  or dummy empty arrays as compatibility state.
- Update active design, architecture, implementation-status, and test-checklist
  documents to describe ball-owned behavior and glyph-free terrain. Historical
  evidence remains historical and must be labeled as such rather than used as
  current visual authority.

## Tasks

### Phase 1 — Establish queue and objective contracts

- [ ] Add `BallQueueData`, `QueuedBallData`, stable behavior IDs, paint-channel
  IDs, and `PaintObjectiveData` as typed Resources with validation.
- [ ] Give every stage exactly `maximum_shots` queue entries and materialized
  objective values. Implement `StageController` queue cursor, four-entry public
  snapshot, reset, accepted-launch advance, and empty-queue rejection.
- [ ] Update cannon/prediction requests so the current entry's physics and
  stable identity participate in trajectory calculation and cache invalidation.
- [ ] Add focused tests proving rejected launches consume nothing, accepted
  launches consume exactly one entry, restart is exact, and public state cannot
  access entry five or later.

### Phase 2 — Evolve authoritative paint and terminal results

- [ ] Replace the L8 paint storage and shader contract with the one owner-aware
  buffer, latest-writer ownership, monotonic coverage strength, and physical
  total/A/B snapshot.
- [ ] Carry paint channel through root launch, residents, children, trail
  contacts, radial stamps, shot observations, and effects.
- [ ] Make `StageController` evaluate total/A/B thresholds on Finish and timeout.
  Add truthful Clear/Failed terminal data and unmet-threshold reasons.
- [ ] Bump saves to v6. Move v5 scalar bests to existing legacy-best storage;
  compare new bests with clear status first, then preserve existing total-score
  and tie-break behavior. Keep all stages open.

### Phase 3 — Implement the nine intrinsic behaviors

- [ ] Preserve Standard as the common reference, then implement Impact Burst,
  Apex Split, Hyper Bounce, Anchor, Climber, Wide Roller, Triple Skimmer, and
  Contact Fuse behind narrow typed behavior boundaries.
- [ ] Add an authoritative first-airborne-apex event to the projectile lifecycle
  and prove it cannot fire after terrain contact or recur in split children.
- [ ] Reuse the current family/shot ID and capacity contracts. Prove seven
  three-child splits cannot exceed 21 residents and no split recursively splits.
- [ ] Add behavior-level deterministic tests for trigger count, trigger timing,
  color inheritance, reset, invalid-contact behavior, exit behavior, and
  observation events.

### Phase 4 — Build the Level 3 player flow

- [ ] Create one reusable queue rail and one owner-aware coverage component;
  connect them through the HUD controller's supplied state.
- [ ] Add Stage Select unordered ball-set presentation, first-introduction
  Briefing copy, queue visibility rules, accessible names, apex marker, and
  Clear/Failed result metrics.
- [ ] Create the nine non-symbolic world silhouettes and matching queue icons
  through shared assets/resources. Do not print terrain glyphs or rely on paint
  hue to identify behavior.
- [ ] Inspect running-game before/after captures for Briefing, Aim, Map, Shot
  Follow, late queue, Clear, Failed, Stage Select, Korean, and English at the
  required sizes.

### Phase 5 — Materialize progression and remove glyphs

- [ ] Change the catalog schema to v11, implement the locked introduction and
  bag rules, materialize all thirty queues/objectives, and add checksum inputs.
- [ ] Add validators for queue length, visible-horizon teaching, color supply,
  behavior repertoire, split bounds, objective feasibility, and deterministic
  rematerialization.
- [ ] Promote one verified v11 catalog. Then execute the rewrite/delete inventory
  above, remove old catalog/runtime references, and rerun imports before deleting
  superseded v9/v10 generated bundles.
- [ ] Replace glyph tests with queue, behavior, clean-terrain composition, and
  catalog-v11 contracts; remove obsolete localization and test-runner entries.

### Phase 6 — Validate feasibility and publish implemented truth

- [ ] Add offline witness checks using current projectile prediction and stage
  evidence. Each stage needs at least one queue-valid objective witness; this is
  test tooling and never a runtime solver or player hint.
- [ ] Playtest Stages 01-09 once each for introductions and Stages 10, 15, 20,
  25, 28, 29, and 30 for mixed queues. Record queue, launch parameters, behavior
  effects, A/B/total results, clear/failure, and any hidden-tail dependency.
- [ ] Reject a stage calibration if success requires knowing entry five before
  it becomes visible. Change the authored bag, objective, or terrain evidence;
  do not expose more preview slots as a quick fix.
- [ ] Run focused checks while implementing and `scripts/verify.ps1` after every
  script, scene, Resource, project-setting, or localization batch stabilizes.
- [ ] Before the broad final gate, explain its full-suite, export, and capture
  cost and obtain the alignment required by repository policy. Run it once after
  the feature set is stable and stop on the first material shared failure.
- [ ] Run `$codebase-quality-auditor`, make only small task-owned corrections,
  build production-style Windows and Web exports, inspect running-build captures,
  and update `.agents/Documentation.md`, active specs, and `docs/test-checklist.md`.
- [ ] Commit coherent task-owned implementation and evidence. Mark this plan
  `done` only after all acceptance checks pass.

## Acceptance Checks

- Current plus next three are visible; entry five and later are absent from
  human UI and public agent observation.
- Accepted root Fire advances shots and queue once; every rejection and derived
  child advances neither.
- Restart restores the same deterministic queue and objectives.
- All nine behaviors match their bounded trigger contracts, inherit paint
  channel and shot family, and remain independent of HUD/input.
- One authoritative PaintSystem representation drives visuals and total/A/B
  coverage; latest paint changes owner without reducing total painted strength.
- Finish and timeout return Clear only when every materialized threshold is met.
- Stage 01-03 remain single-color introductions; Stage 04-30 visibly and
  feasibly require both colors.
- No terrain glyph, mechanism label, charge/cooldown UI, mechanism scene/script,
  serialized mechanism field, or active mechanism localization remains.
- Catalog v11 deterministically materializes 30/30 valid queues and objectives;
  active resources do not refer to deleted glyph classes or v9/v10 bundles.
- Save v6 never upgrades an unverifiable v5 scalar best into a color clear.
- Korean/English running-build captures show no clipping, overlap, color-only
  meaning, center obstruction, or hidden-tail disclosure at supported sizes.
- Windows and Web production builds launch the same rule set; focused and
  complete validation gates pass.

## Validation Commands

Use existing harness conventions and the shared Godot runtime. Expected focused
entry points are:

```powershell
& $env:GODOT_BIN --headless --path . --script res://tests/ball_queue_test.gd
& $env:GODOT_BIN --headless --path . --script res://tests/projectile_behavior_test.gd
& $env:GODOT_BIN --headless --path . --script res://tests/paint_ownership_test.gd
& $env:GODOT_BIN --headless --path . --script res://tests/color_objective_test.gd
& $env:GODOT_BIN --headless --path . --script res://tests/generation_v11_materialization_test.gd
& $env:GODOT_BIN --headless --path . --script res://tests/save_migration_test.gd
& $env:GODOT_BIN --headless --path . --script res://tests/localization_ui_test.gd
pwsh -NoProfile -File scripts/verify.ps1 -GodotPath $env:GODOT_BIN
```

Final gate after the required alignment:

```powershell
pwsh -NoProfile -File scripts/test.ps1 -GodotPath $env:GODOT_BIN
& $env:GODOT_BIN --headless --path . --export-release 'Windows Desktop' 'builds/windows/PaintMountain.exe'
& $env:GODOT_BIN --headless --path . --export-release 'Web' 'builds/web/index.html'
pwsh -NoProfile -File scripts/verify-web-release.ps1 -ReleaseDirectory builds/web
```

## Regression Guards

- Preserve the stationary cannon, pre-shot yaw/elevation/power planning, no
  in-flight steering, fixed 60 Hz physics, two-times active pace, wall-clock
  limits, persistent resident balls, target-only score, all-open stage select,
  Finish action, and browser/Windows delivery.
- `StageController` remains sole stage/shot/queue/clear owner. `PaintSystem`
  remains sole mutable paint and coverage owner.
- Do not add propellant, Hold, inventory, upgrades, shops, adaptive odds,
  unseeded runtime randomness, projectile steering, post-contact path previews,
  color cancellation, or a second paint representation.
- Do not keep empty compatibility mechanism arrays, unused aliases, hidden glyph
  nodes, or stale active docs after v11 promotion.
- Do not alter collision layers, time scale, stage locks, or input bindings to
  make a ball behavior easier.

## Predetermined Contingencies

| Trigger | Response |
| --- | --- |
| A hidden tail is the only winning line | Change that stage's bag/objective/terrain calibration; keep the four-slot horizon |
| A queue change leaves stale trajectory data | Include stable behavior Resource identity and queue revision in prediction context; hide stale impact markers |
| A split can recursively split or exceed capacity | Force children to Standard behavior and reject invalid catalog data before runtime |
| Per-color totals disagree with the shader | Rebuild counters from the authoritative owner buffer and fix the write path; never add comparison masks |
| Latest overwrite feels too punitive | Lower per-color minima within the locked progression band; do not switch to cancellation or random thresholds during implementation |
| Ball type is confused with paint color | Strengthen silhouette/icon/name cues; do not reserve one hue per behavior |
| Removing v9/v10 breaks hydration before v11 promotion | Restore them from Git and complete v11 reference removal first |
| One behavior requires a global projectile switch | Extract a typed behavior component/strategy before adding the next type |
| Save migration would claim a legacy clear | Keep the value in legacy history and start active v6 bests un-cleared |

## Progress

- Repository, design, architecture, glyph owner graph, projectile boundary,
  paint ownership, save state, and current progression plans were inspected.
- Nine ball behaviors, the four-slot preview, deterministic bag policy,
  two-color overwrite rule, objective bands, UI placement, migration, and glyph
  removal boundary are decided.
- Shared Propellant and its product spec are superseded.
- No runtime code, scene, Resource, catalog, save, or UI implementation has
  started.

## Next Steps

- Begin Phase 1 only after the user requests implementation.

## Stop Conditions

Stop and ask before adding a dependency or asset pack, changing the four-slot
preview, adding a third paint color, changing child count, changing the selected
overwrite rule, weakening one authoritative PaintSystem mask, force-pushing,
deploying, or deleting files beyond the explicit glyph/catalog inventory. A
failed test, difficult tuning task, or large owner graph is not by itself a
reason to stop.
