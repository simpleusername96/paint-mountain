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

## Limitations

- This audit does not claim fresh runtime reproduction; it explains the user's
  reported runtime symptoms from the current production paths.
- Balance quality beyond the locked monotonic structural metrics remains a user
  play judgment after implementation evidence is ready.
