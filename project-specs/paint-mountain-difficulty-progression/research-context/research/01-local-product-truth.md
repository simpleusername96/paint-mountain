---
type: evidence
status: active
created: 2026-08-13
topic: implemented Paint Mountain difficulty surface
scope: current requirements, owners, controls, observations, and validation
related:
  - ../../../../docs/source-brief.md
  - ../../../../docs/technical-architecture.md
  - ../../../../.agents/Documentation.md
---

# Local Product Truth

## Purpose

Fix the current product and implementation boundary before generating new
difficulty ideas. This note reports what exists; it does not select a future
direction.

## Sources

- `docs/source-brief.md`, including its later supersessions.
- `docs/design-spec.md` and `docs/technical-architecture.md`.
- `.agents/Documentation.md` for implemented status.
- `.agents/design/DESIGN.md`, `ART_DIRECTION.md`, and
  `UIUX_GUIDELINES.md` for player-facing constraints.
- Current code and focused tests named below.

## Findings

### Fixed product contract

- The cannon is stationary. Before firing, the player chooses a terrain target
  that resolves to yaw, elevation, and power. The projectile cannot be steered
  after launch.
- Physics and the baked terrain are deterministic. An unchanged stage and
  launch state must remain comparable across retries.
- Paint is cumulative during an attempt. `PaintSystem` owns the only mutable
  paint mask and the coverage calculated from it.
- All thirty stages are open. Difficulty may guide choice but must not impose a
  lock or mandatory completion order.
- The only terrain mechanisms are Burst, Splitter, and Uphill Rebound. The
  normal HUD must stay quiet; it must not add passive shot or mechanism prose.
- Clear is based on target coverage. The current star thresholds are clear,
  clear plus 2.5 points, and clear plus 5.0 points.

### Existing difficulty controls

`src/stage_generation/stage_progression_data.gd` is the current formula owner.
Across stages 1-30 it changes:

- target coverage from 4.0% to 10.0%;
- maximum shots from 4 to 7 and duration from 60 to 120 wall-clock seconds;
- terrain size from 210x120 m to 280x160 m and the cell grid from 84x48 to
  96x64;
- stations, routes, reversals, ridges, basins, passes, undulation, route width,
  and mechanism count;
- one weighted `difficulty_score_for()` value, which the current progression
  test requires to be nondecreasing.

The stage mechanism tiers already create useful six-stage boundaries: stages
1-6 contain zero to two mechanisms, 7-12 contain three, 13-18 contain four,
19-24 contain five, and 25-30 contain six.

### Existing structures that can express route difficulty

- `StageGenerationProfile` owns stage-shape parameters, route Resources, and
  geometric acceptance gates.
- `StageRouteProfile` already expresses `PRIMARY`, `SAFE`, `SPLITTER`, and
  `BUMPER` roles, width, grade signs, rise/drop ranges, bends, and mechanism
  slots. `reversal_count()` is derived from grade changes.
- `StageCatalogMaterializer` and `scripts/build_stage_catalog.gd` materialize
  the thirty typed stages, generate one exact canonical layout per stage,
  validate it, bake it, and publish an all-or-nothing catalog bundle.
- `StageData` stores immutable identity, rules, generation profile, world
  configuration, mechanism loadout, and camera bookmarks.

This means route choice, contrast, reversals, and mechanism opportunity can be
authored without adding a new runtime rule or a second terrain model.

### Existing observation and persistence surface

- `ShotObservation` records commanded aim, contacts, mechanism activations,
  child spawns, settlements, paint commands, coverage before/after/gain, and
  final mask checksum.
- `AttemptObservation` and `AttemptRecorder` record the ordered local attempt
  log and final result. They are diagnostic data, not a replay or progression
  system.
- `GameState` persists the selected stage and only the best coverage result,
  stars, elapsed time, shots used, and finish reason. It does not estimate a
  player skill model.

The current data is enough for local playtest summaries. It is not a calibrated
item bank and cannot justify opaque automatic difficulty changes.

### Existing player-facing surface

- `StageSelectScreen` shows target, shots, time, mechanisms, and best result.
  It uses eight cards per page and keeps every card enabled.
- Results show coverage, grade, best, time, and shots. Normal gameplay does not
  show resident projectile accounting, replay, wind, or passive mechanism
  messages.
- Current running-game evidence shows that the distant mountain, route forms,
  glyphs, and trajectory are the primary explanation surface. New difficulty
  therefore has to be visible in geometry first.

### Current validation surface

- `tests/stage30_progression_test.gd` checks all thirty formula outputs,
  catalog order, current endpoints, and scalar monotonicity.
- `tests/stage3_glyph_route_contract_test.gd` and
  `tests/stage8_uphill_glyph_contract_test.gd` protect early teaching examples.
- Generation, catalog, mechanism-placement, camera-safety, UI, localization,
  and save migration tests cover adjacent contracts.
- `scripts/verify.ps1` is required after script, scene, Resource, or project
  setting changes.

## Limitations

- Automated tests prove deterministic structure, not perceived difficulty,
  player learning, or enjoyment.
- The repository has no current live-player cohort or network telemetry.
- Entry witnesses prove bounded reachability conditions; they do not prescribe
  a full solution or prove that every intended route will clear a stage.
