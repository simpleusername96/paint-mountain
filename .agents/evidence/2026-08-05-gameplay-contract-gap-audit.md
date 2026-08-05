---
type: evidence
status: active
created: 2026-08-05
last_reviewed: 2026-08-05
topic: stage progression, summit reachability, live re-aiming, and projectile-to-paint scale
scope: static code, document, session-history, and git audit of commit f13927a
source: user reports and directives through 2026-08-05
related:
  - ../execplans/2026-08-05-gameplay-contract-recovery.md
  - ../execplans/2026-08-05-physical-gameplay-mvp.md
  - ../execplans/2026-08-05-rapid-fire-thirty-stage-progression.md
  - ../execplans/2026-08-05-runtime-grounded-interface.md
  - ../../docs/source-brief.md
---

# Gameplay Contract Gap Audit

## Purpose

Establish whether the three 2026-08-05 ExecPlans were actually implemented and
explain the four player-visible failures reported after commit `f13927a`. This is
consult-only evidence for the replacement execution contract; it does not itself
authorize implementation.

## Sources

- The effective product authority in `docs/source-brief.md`, especially the
  2026-08-03 paint/reachability clauses, the 2026-08-04 progression/repeat-fire/
  scale clauses, and the 2026-08-05 clarification.
- The three former active ExecPlans under `.agents/execplans/`.
- Current implementation in `src/`, `resources/`, `scenes/`, and focused tests.
- `.agents/Documentation.md` and the execution evidence recorded for commit
  `f13927a` (`feat: execute gameplay and interface plans`).
- The active-session user directive preserved in
  `C:/Users/BK/.codex/history.jsonl:4949`, which explicitly requires immediate
  repeat fire, a larger ball/narrower paint midpoint, and gradual thirty-stage
  terrain/item growth.
- The current-session user report preserved in
  `C:/Users/BK/.codex/history.jsonl:4963`.

No Godot editor, foreground game window, rendered test, or broad automated test
was run for this audit. The reported symptoms are the user's direct runtime
observations; the causes below were traced statically through the production
paths and the implementing commit.

## Findings

### 1. Overall plan execution status

The plans were not applied as written. Commit `f13927a` implemented a bounded
approximation, then changed progress prose and `Documentation.md` to describe
that approximation as completion while leaving every task checkbox unchecked.

| Former active plan | Checked tasks | Unchecked tasks | Static conclusion |
| --- | ---: | ---: | --- |
| `2026-08-05-physical-gameplay-mvp.md` | 0 | 16 | Some tuning/contact work exists; full reachability and accepted scale evidence do not |
| `2026-08-05-rapid-fire-thirty-stage-progression.md` | 0 | 21 | Catalog enumeration and controller admission are partial; version-6 terrain/content build and usable repeat aim do not exist |
| `2026-08-05-runtime-grounded-interface.md` | 0 | 20 | Static screens were changed, but the live repeat-aim/readiness contract is not wired |

The progress claims in those files therefore cannot be used as implementation
evidence. Their lifecycle is now superseded by the recovery plan.

### 2. Stages 04 and 05 are the same terrain design with small random variation

- `src/stage/stage_catalog.gd:55-83` chooses one of three legacy `StageData`
  templates and duplicates it. `StageProgressionData.profile_band()` returns the
  same band `0` for Stages 04 and 05 (`stage_progression_data.gd:48-53`), so both
  clone First Descent.
- The duplicated profile changes only identity, nominal peak, broad acceptance
  ranges, and requested seed. It preserves the same route array, route width,
  reversal pattern, mechanism-pad model, terrain bounds, cell count, route
  stations, camera bookmarks, and cannon transform.
- The only height progression is `88.0 + (n - 3) * 0.60`
  (`stage_progression_data.gd:29-36`): Stage 04 is `88.6 m` and Stage 05 is
  `89.2 m`, a difference too small to establish a new map structure.
- Both stages have zero mechanisms (`stage_catalog.gd:121-125`) and ten
  decorations (`seeded_stage_generator.gd:435-442`).
- `StageGenerationContract` remains fixed version 5 at `180 × 120 m`, `72 × 48`
  cells, eight route stations, and 6,912 maximum top triangles
  (`stage_generation_contract.gd:4-13`). It cannot consume the former plan's
  variable version-6 sizes, stations, routes, ridges, passes, basins, or pads.
- The height synthesizer derives macro feature counts from only the legacy route
  count (`route_graph_height_synthesizer.gd:128-267`), so every First Descent
  clone receives the same feature-count class.
- `tests/stage30_progression_test.gd` checks only catalog size, positive rules,
  successful generation, and that a peak does not drop by more than `8 m`. It
  does not assert adjacent-stage structural changes, the version-6 formulas,
  mechanism bands, unique profiles, or visible differences.

Root cause: Phase 2 and Phase 3 of the former progression plan were replaced by
a shortcut that enumerates 30 IDs while retaining three terrain templates. The
test was written to accept that shortcut rather than the planned contract.

### 3. Summit reachability is neither required nor certified

- The legal input domain exists: yaw `-45..45°`, elevation `10..68°`, and power
  `0..100` (`src/cannon/aim_tuple.gd:4-9`).
- `DefaultAimSolver.find_runtime_aim()` deliberately targets the target-mask
  sample nearest its centroid (`default_aim_solver.gd:18-37`). It does not search
  the global maximum-height top region.
- `SeededStageGenerator` records only `maximum_height`
  (`seeded_stage_generator.gd:138-149`). It does not identify summit triangles,
  solve a summit witness, reject an occluded summit, or retain summit proof.
- `TargetMaskRasterizer` scores route cores/shoulders/pads. The global summit is
  not guaranteed to be in that mask, so target-wide reachability would not imply
  summit reachability even if it were complete.
- The current power curve ends at `72 m/s` while linear damping remains `0.55`,
  and generation records no summit height/range envelope against that curve.
  Stage admission therefore cannot reject a summit that lies outside the actual
  damped ballistic envelope; this audit does not claim which current seed first
  crosses that boundary without a fresh runtime certificate.
- `DirectReachabilityValidator` can solve legal first-hit witnesses and compare
  predictor/rigid-body identity, but the current runtime layout is admitted with
  a bounded centroid default rather than a complete certificate. The current
  record itself still says Stage 1 has only an MVP permit
  (`.agents/Documentation.md:422-427`).

Root cause: the former plans described target-wide certification but never added
the user's distinct highest-terrain constraint or matched the generated summit
envelope to the power curve, and the implementation retained the temporary
runtime-centroid admission path.

### 4. Repeat fire exists at controller level but immediate re-aiming is not usable

- `StageController.set_aim()` and `request_fire()` accept AIMING,
  PROJECTILE_IN_FLIGHT, and PAINT_SETTLING, preserve cannon input, and allow two
  active root families (`src/stage/stage_controller.gd:186-246`).
- `AimInputController` permits mouse, wheel, keyboard, power, and Space in those
  same states (`src/input/aim_input_controller.gd:41-74,170-178`).
- However, Fire changes the camera to FOLLOW or WIDE and hides the trajectory
  preview (`src/gameplay/gameplay_scene.gd:316-339`). A player can mutate numbers
  while looking away from the cannon trajectory, which does not satisfy visible
  immediate re-aiming.
- Every aim change clears the current prediction
  (`src/cannon/cannon_controller.gd:44-50`); prediction is recomputed later at a
  20 Hz cap (`gameplay_scene.gd:133-139,256-270`). Fire remains invalid until
  that replacement prediction arrives (`cannon_controller.gd:72-79`), but the
  HUD shows no pending/invalid/capacity reason.
- `GameplayScene` wires Fire enabled directly to cannon prediction validity
  (`gameplay_scene.gd:219-222`). It does not subscribe the HUD to
  `shot_family_activity_changed` or `terminal_pending_changed`, and
  `StageController.activity_snapshot()` reports the constant maximum `2` rather
  than remaining capacity (`stage_controller.gd:135-147,543-558`).
- `tests/rapid_fire_contract_test.gd:23-30` calls `StageController.request_fire()`
  twice with the same already-valid aim. It does not exercise human input, a
  changed next aim, prediction pending, camera/preview visibility, HUD readiness,
  or keyboard/button parity.

Root cause: the implementation broadened old serial-state guards but did not
perform the planned orthogonal board-phase refactor or connect the real human
aiming presentation/readiness path.

### 5. The numeric scale changed, but the accepted visual midpoint did not

- `resources/projectiles/basic_paintball.tres` changed from a `0.52 m` ball and
  `4.0/6.0/4.0 m` paint radii to `0.60 m` and `2.25/3.20/2.25 m`.
- The current `1.20 m` ball diameter is still paired with a `4.50 m` traversed
  diameter (`3.75×` diameter and `14.06×` area) and a `6.40 m` impact diameter
  (`5.33×` diameter and `28.44×` area).
- The same physical radius correctly drives mesh, sphere collision, CCD,
  predictor, and contact offsets, and the same paint resource drives impact,
  sweep, and settlement. This is not a duplicate-owner bug; it is a rejected
  tuning choice and an evidence gap.
- The former physical plan locked those exact values before rendered player
  acceptance, and its scale evidence task remains unchecked. The user's current
  QA explicitly rejects the result.

Root cause: the implementation made the smallest numeric change allowed by the
old plan, not a visually material convergence, and treated resource equality as
acceptance without a controlled contact-width capture.

## Recommendations

- Replace the three contradictory active plans with one recovery ExecPlan that
  owns the four interacting contracts and their evidence.
- Regenerate all 30 stages from per-stage typed inputs; remove three-template
  cloning and the weak peak-only progression test.
- Extend the reachability certificate with an explicit global-summit witness in
  addition to target-wide witnesses.
- Make active shot families orthogonal to the board's AIMING phase, preserve the
  cannon view/next trajectory after Fire, and expose one authoritative readiness
  snapshot to HUD and every action origin.
- Retune the parent ball and paint radii to the exact replacement values in the
  recovery plan, then measure both the physical sphere and authoritative mask in
  one real-contact scenario.
- Do not claim completion from catalog count, direct controller calls, resource
  text, concepts, or plan prose. Require the focused contract checks and named
  production-style off-screen evidence.

## Recovery checkpoint (2026-08-05)

The implementation resumed from the replacement ExecPlan after this audit. The
following hidden/headless checks now provide new evidence beyond the original
static snapshot:

- `scripts/verify.ps1 -GodotPath <Godot 4.7.1 console>` passed import, script
  parsing, and main-scene startup.
- `tests/stage30_progression_test.gd` passed the serialized version-7 catalog,
  canonical numeric IDs, legacy aliases, Stage 04/05 canaries, endpoints, and
  all adjacent difficulty-score deltas. Its `--full-generation` mode remains a
  longer offline guard rather than a routine check.
- Persisted-seed generation passed for stages 01–03 and 04–30 in separate
  headless sweeps. The generated layouts reported distinct stage dimensions,
  cell counts, route/mechanism bands, target masks, and decoration counts.
- `tests/projectile_contact_test.gd` passed the locked 0.90 m physical radius,
  32–150 m/s endpoints, 1.50/2.10/1.50 m paint radii, and 100 exact contacts.
- `tests/rapid_fire_contract_test.gd` passed two immediate root families,
  side-effect-free third-family rejection, and settlement. The Phase 7 user-QA
  contract also passed latest-aim refresh.

The recovery is not complete: no thirty-stage summit/target-wide predictor plus
rigid-body certificate bundle or named background Compatibility captures have
been produced, and the content bundle currently contains serialized stage and
profile resources only. These are explicit remaining gates, not inferred
completion claims.

## Recovery checkpoint 2 (2026-08-05)

The next implementation slice closed the progression and live-board gaps that
were still open in the previous checkpoint:

- The serialized bundle pointer now targets manifest
  `71bbf219aec5688f3515230aa3384b2adfc6909ccdbb09877ff668dd4bff9072`. Its
  transaction writer emits stages, profiles, empty certificate/preview folders,
  and an explicit `previews_ready=false` manifest flag; no certificate or
  preview is being represented as complete.
- The full `stage30_progression_test.gd --full-generation` gate passed in
  `163.5 s`. It rebuilt all thirty persisted seeds and checked adjacent
  normalized height RMS, bounded dimensions, unique height checksums, summit
  identity, containment, macro counts, mechanism pads, route slope bounds, and
  decoration counts.
- The live board now stays in `AIMING` while families move and after the final
  paint drain; the former 0.7-second serial result wait is bypassed. The rapid
  fire contract still passed with two accepted families, capacity rejection,
  per-family observations, and an editable board after settlement.
- `ActionButtons` now renders the authoritative disabled reason adjacent to
  Fire. Hidden Compatibility captures inspected by the implementing agent show
  `궤적 계산 중` in `next_aim_pending`, `포탄 2개 진행 중` in `two_family`, and a
  blue ready Fire state in `next_aim_ready`.
- The terrain shader's mountain albedo was lowered to a readable cool mid-value
  while the wall/apron remained bright. A real Stage 04 background capture now
  shows faceted 3D mass, side support faces, mechanisms, and trajectory without
  the previous white clipping.
- The delivery runner now accepts the named recovery screens
  `progression_aiming`, `summit_hit`, `next_aim_pending`, `next_aim_ready`,
  `two_family`, and `scale_contact`, plus canonical `--capture-stage` IDs.

Remaining gates are unchanged in substance: persisted target-wide and summit
predictor/rigid-body certificates, a measured rendered-width scale fixture,
the full baseline/recovery capture set and metadata, one production export,
the quality audit, and lifecycle reconciliation.

## Recovery checkpoint 3 (2026-08-05)

The reachability boundary was exercised against canonical serialized `stage_01`
rather than the legacy `first_descent` fixture. The old fixture used the
pre-catalog bounds and passed the wrong apron join height, so it could not prove
the current runtime contract. `tests/target_reachability_test.gd
--summit-only` now passes with a real predictor witness and one production
`PaintProjectile` witness (region `12`, predictor checksum `1575122968`,
rigid-body checksum `2777136852`, worst summit height margin `0.171 m`).

The target acceptance boundary now matches the live paint contract: a first
top-surface contact is accepted when its authoritative `2.10 m` impact mark
covers the target texel. The former `0.50 m` point-distance plus exact-triangle
gate rejected adjacent-facet contacts whose actual impact mark already covered
the intended surface. A candidate positive-Z front-envelope raster filter was
measured and then rolled back: its per-stage generation cost exceeded the
bounded window, and deleting hidden target pixels would violate the locked
no-target-deletion contingency. A full thirty-layout regeneration therefore
remains unchanged; after the rollback it passed in `254.2 s` and the catalog
pointer was not changed. The target-wide predictor/rigid-body certificate gate
is still open.

The live-board path also removed the remaining competing Fire owner: the
cannon's partial `aim_validity_changed` signal no longer writes the Fire button
directly. `StageController.fire_readiness_snapshot()` and
`activity_snapshot()` now publish remaining root capacity (`0` at two active
families, `2` after settlement), while the existing origin matrix and
per-family sealing proof now pass in the changed-aim rapid-fire contract; the
complete input-origin matrix remains open.

## Recovery checkpoint 4 (2026-08-05)

The matching-key readiness boundary is now wired end-to-end. `CannonController`
records the aim key associated with each prediction and reports `pending`,
`fireable`, or `invalid`; changing aim clears the key, so a stale prediction
cannot launch. `StageController` is the sole Fire owner and republishes the
snapshot when the matching prediction arrives. The HUD/AimInput path and the
primitive `GameplayAgentApi` observation consume the same fields; replay and
debug requests call the same StageController admission method. The synchronous
Fire-time prediction refresher was removed, and the phase-7 contract was
updated to assert pending rejection followed by one coalesced latest-aim solve.

Focused evidence after this change:

- `scripts/verify.ps1` passed.
- `tests/rapid_fire_contract_test.gd` passed with real HUD pending/ready state,
  changed-aim two-family firing, remaining capacity, and distinct sealed aim
  tuples.
- `tests/phase7_user_qa_contract_test.gd` passed with pending Fire rejected,
  one later prediction solve, and latest-aim launch.
- `tests/replay_presentation_test.gd` passed the replay-origin aim/fire path on
  the live AIMING board, and `tests/phase8_debug_test.gd` passed a Debug-origin
  Fire plus sealed shot-log export. The second changed-aim family in the rapid
  contract is admitted through `GameplayAgentApi`; Space shares the same
  `AimInputController.request_fire()` path as the button.
- Background captures `stage_04_progression_aiming.png`,
  `stage_04_next_aim_pending_ui.png`, `stage_04_next_aim_ready_ui.png`,
  `stage_04_two_family_ui3.png`, `stage_04_summit_hit.png`, and
  `stage_04_scale_contact_ui.png` were regenerated at `1280x720` with no
  foreground Godot window. The ready frame shows an enabled Fire button; the
  two-family frame shows only Fire disabled while the next trajectory remains.

## Recovery checkpoint 5 (2026-08-05)

The summit reachability failure found while preparing the Stage 30 evidence was
an actual coordinate-contract defect, not a bad seed. `CannonController` rotates
the visual muzzle with Godot's positive Y convention, while
`CannonBallistics.launch_direction()` and the reachability yaw nomination had
used the opposite X sign. Near the distant summit this produced a large
perpendicular miss and zero analytic candidates. The ballistic vector, validator
horizontal direction, and target-bearing recovery now share the visual muzzle
convention. `projectile_contact_test.gd` includes a regression assertion across
the legal yaw/elevation extrema.

Focused evidence after this correction:

- `tests/projectile_contact_test.gd` passed, including the visual/ballistic
  direction contract, locked scale values, 100 exact contacts, CCD, recontact,
  and simultaneous-contact ordering.
- `tests/target_reachability_test.gd --stage=stage_01 --summit-only` passed with
  region `12`, predictor checksum `2477889882`, rigid-body checksum `208192991`,
  and height margin `0.565 m`.
- `tests/target_reachability_test.gd --stage=stage_30 --summit-only` passed with
  region `6`, predictor checksum `117277691`, rigid-body checksum `1161348872`,
  and height margin `0.620 m`.
- The bounded Stage 01 reachability sample passed with `256` visited target
  texels, `51` witnesses, `205` reused assignments, and a `2.956 s` elapsed
  sample. This is not the full target-wide certificate.
- `scripts/build_stage_catalog.gd --check` still passed unchanged with manifest
  `71bbf219aec5688f3515230aa3384b2adfc6909ccdbb09877ff668dd4bff9072`.
- Fresh hidden Compatibility captures for Stage 04, 05, 10, 20, and 30 show
  distinct mountain silhouettes and mechanism counts. The refreshed Stage 04
  live frames show summit trajectory, pending/ready Fire states, two active
  projectile families, and the scale-contact runner state without opening a
  foreground window.

## Recovery checkpoint 6 (2026-08-05)

The post-pass ownership audit found one certificate-boundary defect: the first
summit fields required the summit aim to be an index in the target witness
table. That would reject a valid global summit outside the scoreable route mask,
contradicting the locked separation between centroid/default targeting and
summit proof. `DirectReachabilityCertificate` now serializes a dedicated summit
angle/elevation/power tuple, and `GeneratedStageLayout.is_certified()` validates
that tuple independently. The legacy index field remains read-compatible but is
not emitted by new certificates.

Evidence after the correction:

- `tests/target_reachability_test.gd --stage=stage_01 --summit-only` passed and
  its serialization guard round-tripped a summit tuple distinct from a target
  witness.
- `scripts/verify.ps1` passed after the certificate and test changes.
- The focused contact, projectile/paint, rapid-fire, phase-7, phase-8, replay,
  and default-aim checks passed as a final regression batch.
- The Windows release export completed with exit code `0` and no Godot process
  remained afterward.

This does not close the remaining Phase 3/5 gates: target-wide predictor and
rigid-body certificates for all thirty stages, certificate-linked previews,
controlled rendered/mask width measurement, the complete baseline capture set,
and lifecycle completion are still unverified.

At checkpoint 5 the remaining release gates were target-wide predictor/rigid-body
certificates for all thirty stages, certificate-linked previews, controlled
rendered/mask width measurement, the complete baseline capture set, production
export, quality audit, and lifecycle reconciliation. Checkpoint 6 records the
export and quality-audit results; the certificate, preview, width, baseline, and
lifecycle gates remain open.

## Recovery checkpoint 7 (2026-08-05)

The delivery capture runner had one evidence-only race: it required the
projectile manager to still report an active body when the late-physics paint
drain published a sweep. A settled body can be removed one tick earlier even
though its authoritative paint command is valid. The runner now records an
active sweep at the canonical intent boundary, captures the real ball/paint
relationship, and waits for the actual terminal transition after coverage or
shot exhaustion.

Fresh background captures were produced without opening a foreground Godot
window:

- `01_main_menu.png` through `07_stage_failed.png` at `1920×1080`.
- `stage_04_progression_aiming.png`, `stage_05_progression_aiming.png`,
  `stage_10_progression_aiming.png`, `stage_20_progression_aiming.png`, and
  `stage_30_progression_aiming.png` at `1280×720`.
- The named Stage 04 summit, pending, ready, two-family, and scale frames plus
  `05_projectile_and_continuous_paint.png` at the same background size.

`stage_clear` now reaches `4.3187%` against the `4.0%` target in three legal
runtime-solved shots, and `stage_failed` exhausts four legal repeated shots at
`0.6437%`. These are delivery captures, not a substitute for the still-open
thirty-stage target-wide certificate and controlled width gates.

A bounded Stage 01 throughput sample visited `512` of `67,729` target pixels in
`9,803 ms` and projected `1,296,772 ms` for the full target pass. It is recorded
as a cost estimate only (`is_certificate=false`); no representative sample is
being promoted to a target-wide certificate.

## Limitations

- This audit does not claim fresh runtime reproduction; it explains the user's
  reported runtime symptoms from the current production paths.
- Balance quality beyond the locked monotonic structural metrics remains a user
  play judgment after implementation evidence is ready.
