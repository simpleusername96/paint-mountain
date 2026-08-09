---
type: record
status: active
created: 2026-08-02
last_reviewed: 2026-08-09
scope: implemented project state and durable bootstrap decisions
related:
  - Plan.md
  - execplans/2026-08-03-gameplay-visual-reset.md
  - execplans/2026-08-03-core-interaction-redesign.md
  - execplans/2026-08-05-physical-gameplay-mvp.md
  - execplans/2026-08-05-rapid-fire-thirty-stage-progression.md
  - execplans/2026-08-05-runtime-grounded-interface.md
  - execplans/2026-08-05-gameplay-contract-recovery.md
  - execplans/2026-08-06-ballistic-terrain-preparation.md
  - execplans/2026-08-06-wind-driven-coverage-loop.md
  - execplans/2026-08-06-fast-stage-entry-and-fire-capacity.md
  - execplans/2026-08-06-command-columns-hud.md
  - execplans/2026-08-07-target-coverage-and-safe-aim-framing.md
  - execplans/2026-08-07-cannon-shot-observation.md
  - execplans/2026-08-07-truthful-coverage-and-responsive-aiming.md
  - execplans/2026-08-08-projectile-scale-balance-and-aim-performance.md
  - execplans/2026-08-08-terrain-targeted-aiming.md
  - execplans/2026-08-08-casual-shared-ui-refresh.md
  - execplans/2026-08-08-instant-approximate-landing-feedback.md
  - evidence/terrain-targeted-aiming-2026-08-08/README.md
  - evidence/coverage-balance-and-aim-feedback-2026-08-08/README.md
  - evidence/2026-08-07-aim-performance-product-audit.md
  - evidence/target-coverage-and-safe-aim-framing-2026-08-07/design-qa.md
  - ../docs/handoffs/aim-performance-and-product-direction-2026-08-07/README.md
  - evidence/2026-08-05-gameplay-contract-gap-audit.md
  - ../design-qa.md
  - ../docs/design-spec.md
  - ../docs/technical-architecture.md
---

# Project Record

## Current Player-Replay Retirement (2026-08-08)

The user removed player replay after deciding that it did not add enough value
to the planning loop.

- Result panels now expose Retry, Next Stage when available, and Stage Select;
  the Replay button and playback bar are absent.
- `ReplayRecorder`, `ReplayPresentationController`, replay UI scenes/scripts,
  translations, capture routing, replay formats, replay-specific tests, and the
  `REPLAY` action origin/exclusive lock are deleted.
- `AttemptRecorder` preserves only the independent current-run
  `AttemptObservation` and debug JSON shot-log contract. It has no playback or
  persistence API.
- Current verification covers result/HUD state, localization, shot feedback,
  debug export, stage state, project import/startup, and a production result
  capture. Older replay plans and evidence remain historical only.

## Current Immediate Aim and Sparse Instrument Refresh (2026-08-09)

The completed implementation contract is
[`2026-08-08-instant-approximate-landing-feedback.md`](execplans/2026-08-08-instant-approximate-landing-feedback.md).

- Settings state synchronization is passive. Only explicit fullscreen,
  resolution, or defaults actions may change window mode or size.
- Terrain click/drag remains the Human model. `TerrainAimController` now commits
  the first legal deterministic inverse candidate immediately. Its pure solver
  uses a cached 720-tick wind horizon and an eight-tick candidate stride; the
  focused fixture remains below one 60 Hz frame. Exact collision prediction is one
  later advisory job and no Human pending-revision Fire gate remains.
- Normal gameplay uses no left/right status cards, bottom aim panel, or
  persistent prose instruction strip. Stage, coverage, time, shots, resident
  balls, wind, Finish, aim values, and real actions are edge-aligned symbols and
  numbers. A/D, W/S, wheel, Space, Tab, F, and Escape hints are attached to their
  controlled value or action.
- Source and Windows-release 1280x720 Korean and 1920x1080 English Aim View
  captures under
  [`evidence/sparse-instrument-hud-2026-08-09/`](evidence/sparse-instrument-hud-2026-08-09/)
  were inspected directly. Import/startup verification and release export pass.
- New mechanism placement ranks suitable normalized heights 0.55..0.85 first,
  then 0.40 or above. The approved all-30 build promoted v10 manifest
  `c45d547056e5421953571cb7aadf07341df02023334754087a3622c97a519c25`.
  Final Windows-release Stage 02, 03, 08, and 30 captures show Burst, Splitter,
  Uphill, and mixed glyphs across the middle/upper terrain. The fast bundle,
  materialization, bake, and representative glyph contracts pass.

## Historical Casual Shared UI Refresh (2026-08-08)

The implementation and its release evidence are recorded in
[`2026-08-08-casual-shared-ui-refresh.md`](execplans/2026-08-08-casual-shared-ui-refresh.md)
and [`evidence/casual-shared-ui-refresh-2026-08-08/`](evidence/casual-shared-ui-refresh-2026-08-08/).

- The shared Godot Theme now owns tactile neutral, primary, and danger roles
  backed by a narrow CC0 Kenney UI Pack subset. No scene-local token registry or
  executable dependency was added.
- Main Menu is compact, Stage Select uses balanced full-height selection and
  detail surfaces with eight cards per page, and Aim View controls fit a
  lower-right 368x96 component clear of the cannon and centered Fire action.
- Korean 1280x720 Main Menu, Stage Select, Aim, Pause, and Settings captures plus
  an English 1920x1080 Aim capture were inspected directly. Godot verification
  and the Windows Desktop release export passed.
- The nine-image [Casual UI Directions gallery](../docs/concepts/casual-ui-directions-2026-08-08/index.html)
  is exploratory only. The recommended next direction combines Paper Toy menu
  surfaces with Quiet Field Guide HUD restraint; it does not supersede the
  running Theme until the user selects it.

## Historical Exact Terrain-Targeted Aiming Implementation (2026-08-08)

The completed historical execution contract is
[`2026-08-08-terrain-targeted-aiming.md`](execplans/2026-08-08-terrain-targeted-aiming.md).
It supersedes the older pointer-angle gesture, sensitivity-setting, and fixed
six-second miss-lifetime clauses retained in historical sections below.

- Aim View left click and continuous left drag select only canonical Playable
  Terrain Surface top. Pointer input keeps only the latest screen sample; the
  fixed-physics picker rejects shell, apron, mechanism, sky, and invalid gaps
  without moving the last valid target.
- The 2026-08-09 implementation above supersedes this section's asynchronous
  Human revision, pending marker, exact validation wait, and Fire gate. The
  top-only picker, selected/rejected/confirmed marker meanings, branch
  continuity, and Map Inspection input separation remain.
- Exact prediction now separates projectile-centre endpoint from the surface
  `contact_point`. Markers, target validation, generated witnesses, and live
  contact identity use the surface point consistently.
- A matching current terrain-top prediction protects only that generation-zero
  root through `prediction duration + 0.5 s`, capped at 13 seconds. Unmatched
  roots still use the ordinary 6-second miss timeout and real bounds exits stay
  immediate. The deterministic long-flight fixture predicted 8.384 seconds and
  reached live terrain/top contact at 8.417 seconds.
- Runtime power supports 0.1% precision while existing whole-power catalog keys,
  attempt schema 2, save format 5, and direct agent/debug tuple
  APIs remain compatible. Selected-target coordinates and solver revisions are
  not serialized.
- Focused phase gates, `scripts/verify.ps1`, the Windows release export, and
  eight release capture states passed. Korean 1280x720 and English 1920x1080
  evidence was inspected directly with no clipping, false Fire readiness, stale
  impact marker, or premature protected-shot disappearance. See
  [`evidence/terrain-targeted-aiming-2026-08-08/`](evidence/terrain-targeted-aiming-2026-08-08/).

## Current Projectile Scale, Coverage Balance, and Aim Performance (2026-08-08)

The completed implementation contract is
[`2026-08-08-projectile-scale-balance-and-aim-performance.md`](execplans/2026-08-08-projectile-scale-balance-and-aim-performance.md).

- The root ball radius is `2.40 m`; continuous and impact paint radii are
  `2.80 m` and `3.50 m`. Mass and other dynamics are unchanged. A shared
  scale-aware launch origin places the centre beyond the muzzle and above the
  apron for every legal elevation.
- Stage 01-10 clear targets remain `4.0..8.5%`. Stage 11-15 use `8.5%`, 16-20
  use `9.0%`, 21-25 use `9.5%`, and 26-30 use `10.0%`; stars remain clear plus
  `2.5/5.0` points. Shots, terrain, target masks, and mechanisms are unchanged.
- The then-active fixed catalog was v10 at
  `resources/generated_stage_catalogs/v10-d508dd69d5a1e23085aeb7415dafa9b574fac62e2e691db9571292fbdb4ad665`.
  It preserves v9 physical terrain, target, cannon, and placement identities
  and rematerializes bounded entry witnesses for the larger body.
- Advisory prediction owns one replaceable active job. It advances at most 12
  exact steps and approximately 1 ms per physics callback, discards obsolete
  work at the next nomination, and publishes only a current context. The prior
  arc/first-impact marker stays subdued while pending; calculation/update text
  is removed and Fire remains independent.
- Stage 01/10/30 measured settled-marker latency was 6/6/9 physics ticks, with
  an observed slowest callback of `1.089 ms`. Godot verification and Windows
  release export/start passed. Three 1280x720 running-release renders were
  inspected directly: early Aim View, pending Stage 10 aim change, and late
  live scale/contact. The completed plan and evidence record retain details.

## Historical Truthful Coverage and Responsive Aiming Implementation (2026-08-07)

The completed
[`truthful-coverage-and-responsive-aiming` ExecPlan](execplans/2026-08-07-truthful-coverage-and-responsive-aiming.md)
implements the corrections identified during direct Stage 10 play.

- `TargetSurfaceCoverage` metric 2 weights each first-painted target texel by
  its canonical physical triangle area. `PaintSystem` remains the only mutable
  paint/coverage owner and publishes the visible mask and percentage together.
- The then-active fixed catalog was v10 at
  `resources/generated_stage_catalogs/v10-4d9db2c7e4b50b02ccaa33cabc3e8f21f92f1ef21adc76848c86f02d79cb63f0`.
  Its thirty stages retain all v9 physical, target, cannon, placement, and
  bounded-witness identities while adding validated metric-2 metadata.
- Target paint is saturated blue; valid non-target paint stays visible in a
  lighter, desaturated blue. Save format 5 preserves old scores only in the
  legacy envelope. Replay format 10 and the current observation schemas identify
  metric 2 explicitly.
- The 2026-08-07 build used resolution-stable pointer-angle drag and a persisted
  sensitivity setting. The terrain-targeted implementation above supersedes
  that interaction and removes the setting while save format 5 ignores its old
  key.
- Fire admission uses only canonical aim and `StageController` rules. Advisory
  prediction owns one bounded job plus one newest pending request, retains its
  previous arc while updating, and cannot toggle or block Fire.
- Aim, Map, Shot Follow, Fire, Finish, Gear, and Pause now expose contextual
  Space/Tab/F/Escape keycaps. The transient first-session hint and hidden direct
  R restart are removed.
- Focused contracts, Godot 4.7.1 import/start verification, Windows release
  export/start, and five individually reviewed running-release captures passed.
  The evidence is under
  [`evidence/truthful-coverage-and-responsive-aiming-2026-08-07/`](evidence/truthful-coverage-and-responsive-aiming-2026-08-07/).

## Current Open-Mountain Surface Direction (2026-08-07)

The current implementation uses `OpenPlayEnvironment`: it has a restrained
non-target apron and explicit open exit bounds, but no visible, collidable, or
hidden rear/side wall. `BACKSTOP` settlement has been removed. The mountain is
an independently closed 3D mass rather than geometry joined to an enclosure.

- The intended mountain retains real front-to-back depth as one independently
  closed 3D mass. Its perimeter Support Shell and bottom close the body without
  a rear-wall join.
- Playable Terrain Surface means the continuous one-height-per-XZ skin:
  cannon-facing slopes, terraces, valleys, ridges, summits, and far-side slopes.
  Valid traversal paints this surface; only Target Area overlap changes coverage.
- Support Shell, bottom, apron, decorations, and mechanisms remain collidable or
  presentational as appropriate but never write persistent paint or coverage.
- Each stage retains one baked fixed cannon transform with at least 70 m
  standoff. Map View camera orbit is inspection only; cannon orbit and launch
  stations are not part of the current game.
- The rear backstop and artificial side containment walls are removed without
  hidden replacement planes. A restrained non-target apron may remain. Live and
  predicted misses use the same explicit open exit bounds, and `BACKSTOP`
  settlement is retired in favor of real escape or the never-contacted timeout.

## Current Cannon, Wind, and Shot-Observation Direction (2026-08-07)

The active [execution contract](execplans/2026-08-07-cannon-shot-observation.md)
implements the requested lower-cannon/upper-mountain Aim View, a cannon-side
wind flag, and automatic exact-root Shot Follow. The prior
[handoff](../docs/handoffs/aim-performance-and-product-direction-2026-08-07/README.md)
is consumed history. This task includes structural efficiency corrections but
no timing, FPS, or performance-profiling pass.

- This historical build used left drag for yaw/elevation and the wheel for
  power. The terrain-targeted implementation above replaces only the Aim View
  meaning; Map View still owns orbit/zoom. The shared Aim composition keeps the cannon readable below a useful
  lower/wider mountain mass. The user's approximate `3:4` reference is a visual
  guide, not a numeric projected-ratio or complete-silhouette gate.
- Every baked stage keeps one fixed cannon transform at least 70 m from the
  nearest playable front. Stage 01 and Stage 30 use the same qualitative camera
  rule; modest peripheral terrain crop is acceptable when the cannon, muzzle,
  trajectory, and useful mountain mass remain readable.
- `CannonWindFlag` replaces generic wind debris. It is non-colliding and consumes
  the same `WindController` snapshot as physics, prediction, and the exact HUD
  cue.
- Accepted Fire enters Shot Follow for only the newly launched generation-0 root,
  holds first terrain contact for 0.8 seconds, then returns to Aim View. The
  visible return action and Tab return early without changing projectile physics
  or stored aim.
- The target-only coverage meaning, shared HUD Theme/components, persistent
  paint authority, bounded default/summit first-hit witnesses, and open thirty-
  stage production catalog remain valid unless new direct evidence contradicts
  them.
- Obsolete authored-solution and exhaustive-certificate runner scripts, the
  historical solution test, and inactive generated catalog copies were removed.
  Optional schema-compatible certificate classes remain for diagnostics; the
  active v9 admission boundary uses bounded default/summit witnesses and never
  runs a target-wide solver during play.
- The bounded final gate passed: 21 focused scripts, one exact-seed dry build,
  `scripts/verify.ps1`, Windows release export, and seven exported-executable
  background captures. The reviewed evidence is
  [`evidence/2026-08-07-cannon-shot-observation.md`](evidence/2026-08-07-cannon-shot-observation.md).
  No timing/FPS measurement, exhaustive solver, or full-suite run was used.

## Current Target Coverage and Safe Aim Framing (2026-08-07)

The completed execution record is
[`execplans/2026-08-07-target-coverage-and-safe-aim-framing.md`](execplans/2026-08-07-target-coverage-and-safe-aim-framing.md).
This work implemented coverage meaning and a deterministic cannon-view framing
rule without changing
paint, scoring, stage balance, saves, replay, trajectories, generation, or the
catalog. The subsequent user review above rejected the resulting aiming scale
and interaction freedom; implementation completion is not product acceptance.

- Root-cause inspection found no dropped-paint counting defect. `PaintSystem`
  visibly preserves all valid top-surface paint but scores only unique painted
  Target Area texels. Generic `칠한 면적` copy and a nearly invisible dry target
  footprint made that intended target-only denominator look incorrect.
- The terrain shader now gives dry Target Area a restrained neutral value cue
  and begins saturated blue fill at the same `0.5` mask threshold used by the
  authoritative coverage count. Valid non-target paint remains visible and
  unscored. The HUD, Finish tooltip, and result say `목표 영역` / `TARGET AREA`.
- `TerrainSurface` caches deduplicated world points from canonical active-top
  triangles. `CameraDirector` tests the authored Aim Lock pose against those
  exact points, summit points with 8 m headroom, cannon, and muzzle. When they
  do not fit a 1.15 safe margin, `TerrainCameraFramer` moves only along the
  authored view direction, retains the authored focus and 48-degree FOV, and
  never reads live prediction or stage-specific repair data.
- An explored nearest-target focus was rejected because terrain-occlusion
  lifting changed the final direction and broke the safe fit on Stages 10 and
  20. A merged top/cannon AABB was also rejected after its invented extrema
  made Stage 30 unnecessarily small. Exact point projection retains the full
  Stage 30 top while keeping Stage 01 close to its authored scale.
- Paint authority, localization/HUD truth, Stage 01/10/20/30 point-set framing,
  camera lifecycle safety, `scripts/verify.ps1`, Windows release export, and
  three final exported background captures passed with Godot 4.7.1.
- Final evidence is under
  [`evidence/target-coverage-and-safe-aim-framing-2026-08-07/`](evidence/target-coverage-and-safe-aim-framing-2026-08-07/).
  The Level 3 report records `Result: passed`. User gameplay feel and aesthetic
  approval remain explicitly separate from implementation completion.

## Current UI Implementation: Shared Command Columns HUD (2026-08-06)

The completed execution record is
[`execplans/2026-08-06-command-columns-hud.md`](execplans/2026-08-06-command-columns-hud.md).
The user-selected
[`command-columns-hud.png`](../docs/concepts/ui-layout-directions-2026-08-06/command-columns-hud.png)
is the current aiming-HUD visual authority. This UI record does not add or
restore target-wide first-hit certification, prescribed stage success routes,
camera redesign, gameplay approval, or balance approval.

- `resources/ui/paint_mountain_theme.tres` remains the single shared visual
  system. It now owns Pretendard 500/600/700 font variations, semantic HUD label
  roles, command/status panels, mode and icon buttons, Finish, separators,
  absolute coverage progress, target marker, focus, disabled, and icon states.
  The affected HUD scenes contain no local font, color, icon, or StyleBox
  presentation overrides; their remaining overrides are layout-only.
- `HudMetric` is a reusable presentational caption/value component. Time, shots,
  and resident activity instantiate it independently inside `RunStatusCard`;
  the component does not read gameplay state or own timers.
- The 1280x720 Aim Lock composition now uses the joined Stage/mode command card,
  absolute vertical coverage rail, compact lower-left direction/elevation/power
  group, sole centered Fire action, adjacent Gear action, and segmented right
  status rail. Supported real controls omitted by the generated concept remain
  functional.
- Coverage progress displays authoritative 0..100 coverage and positions the
  configured target as a separate marker. It no longer normalizes progress by
  the target threshold.
- Map Inspection keeps the command/status rails and hides aim-only controls.
  Korean and English copy, focus, Finish gating, wind text, Settings intent, and
  existing HUD signals remain connected to their prior owners.
- Focused HUD, localization, wind/result, and shot-feedback checks passed. The
  final `scripts/verify.ps1`, Windows release export, exported hidden start, and
  exported Stage 30 capture passed with Godot
  `4.7.1.stable.official.a13da4feb`.
- The exported 1280x720 capture is
  `.agents/evidence/command-columns-hud-2026-08-06/exported-aim-lock-stage30-ko-1280x720.png`.
  [`design-qa.md`](../design-qa.md) compares it with the selected reference at
  the same viewport/state and records no P0, P1, or P2 finding and
  `final result: passed`.

## Current Gameplay Implementation: Fast Stage Entry and Fire Capacity (2026-08-06)

The completed execution record is
[`execplans/2026-08-06-fast-stage-entry-and-fire-capacity.md`](execplans/2026-08-06-fast-stage-entry-and-fire-capacity.md).
The effective source brief remains the product requirement authority. The
implementation below is current code truth. Final repository verification,
Windows release export, entry-time measurement, and background running-game
capture validation completed on 2026-08-06. This is implementation evidence,
not the user's gameplay, balance, feel, or aesthetic approval.

- `ProjectileRangeConstraint` uses the shared cannon muzzle transform and exact
  60 Hz damp-then-gravity recurrence to build a cached radial lower/upper height
  envelope from the canonical `AimTuple` and `ProjectileData` domain over the
  720-step prediction horizon. Target rasterization checks the projectile
  center for every included sample and rejects the whole candidate on yaw,
  horizontal horizon,
  lower-height, or upper-height failure. It also requires one Summit Region
  sample. This is analytic range admission, not terrain-occlusion or first-hit
  certification. Exhaustive target-wide certification is optional offline
  diagnostic work, not an unfinished product or release guarantee.
- Repeated final non-rendered runs rebuilt persisted Stage 01 in about
  `3.7..4.6 s` and Stage 30 in about `11.1..13.3 s`, verified legal and synthetic
  rejection cases, and
  proved that an out-of-range raster fails as a whole. The envelope uses
  `0.25 m` radial samples plus bounded `0.30 m` range and `0.50 m` height
  discretization tolerance.
- At that milestone, `resources/stages/catalog.tres` selected the
  format-5 persisted bundle
  `resources/generated_stage_catalogs/v9-b0eb55b3e366a7a92b1391a6acd0298bbc854d8c831e8ac57f9b5df5ab44c957`.
  The bundle contains all 30 stages built from canonical terrain seed
  `1347223552`, plus their default/summit witnesses.
- `StageLayoutRepository` replaces the deleted `StageLayoutPreparer`. It loads
  persisted layouts asynchronously, gives the selected stage urgent priority,
  prefetches without blocking, keeps a three-entry LRU, and never falls back to
  runtime terrain generation or aim solving. Gameplay receives a runtime copy
  only after the selected identity is ready.
- Glyph placement searches generic visible playable-top surface with deterministic
  spacing. It uses no authored per-stage coordinates. Small terrain may have no
  glyphs or one or two; larger terrain has more eligible opportunities.
- The initial Fire slot releases on its generation-0 root body’s first
  authoritative valid-top traversal or terminal event. Observation seals only after every
  current family body reaches valid top or terminates. Terrain residents persist
  for the stage and may move again; they do not consume Fire capacity forever.
  `ProjectileManager`, rather than the HUD, enforces the two-root Fire cap.
- The UI and wind-debris changes are implemented: selected-stage loading fails
  closed with a localized retry state, Fire capacity is represented separately
  from resident bodies, and terrain-contained debris uses the shared wind truth.
  The focused wind contract proves direction, motion, and reduced-motion
  behavior; the exported render shows visible debris.
- Final validation passed: `scripts/verify.ps1`; Windows release export at
  `builds/windows/PaintMountain.exe`; and eight 1280x720 capture runs, each exit
  0 with empty final stderr. Exported entry readiness measured `1035.5 ms` for
  Stage 01 and `2068.4 ms` for Stage 30. The captures and stdout/stderr logs are
  under `.agents/evidence/fast-stage-entry-and-fire-capacity/` for
  `stage_30_aiming`, `two_family`, `main_menu`, `stage_select`,
  `stage_select_page_2`, `first_hint`, `pause`, and `settings`.
- Render review found no clipping, overlap, or gross terrain obstruction. Stage
  select pages 1 and 2 retain their footer; the structural UI contract covers
  page 3. Settings is exactly 1280x720. The temporary timing probe found that
  hoisting the summit-vertex snapshot out of the triangle loop reduced profile
  hydration from `1091.2 ms` to `599.5 ms`; caching successful immutable
  readiness reduces repeat readiness from roughly `250..320 ms` to `0`. The
  probe was not retained as a test.
- The user retired exhaustive target-wide exact first-hit certification as a
  product and release requirement. Analytic target-range admission plus bounded
  default/summit first-hit witnesses remain the active baseline. Gameplay,
  balance, feel, and aesthetic QA remain user-directed rather than an inferred
  all-stage solution-route obligation.

## Superseded Recovery Sequence (2026-08-05)

The user's foreground QA invalidated four completion claims made after commit
`f13927a`. A static audit confirmed the reports and is preserved at
[`evidence/2026-08-05-gameplay-contract-gap-audit.md`](evidence/2026-08-05-gameplay-contract-gap-audit.md).
Its execution authority is preserved as superseded history at
[`execplans/2026-08-05-gameplay-contract-recovery.md`](execplans/2026-08-05-gameplay-contract-recovery.md).

The physical, rapid-fire/progression, and runtime-interface plans dated
2026-08-05 are superseded. Their designs remain historical context, but their
progress prose is not current implementation evidence: each still had zero
checked tasks while claiming major phases were implemented.

## Historical wind-driven coverage-loop record (2026-08-06)

### Prior wind-driven coverage-loop record (implementation superseded by current validation state)

The effective `docs/source-brief.md` remains the product requirement authority.
The current implementation now realizes its 2026-08-06 wind-loop supersession;
the earlier clear/failure, finite-lifetime projectile, physical-mechanism, and
camera-preset behavior is historical only.

- Aim and camera: positive yaw moves the preview and real landing point toward
  screen right. `AIM_LOCKED` owns aim/power/Fire input, while
  `MAP_INSPECTION` owns terrain refocus, orbit, and zoom. Tab and the visible
  toggle preserve the current aim and preview; Follow/Wide/Cannon and normal-play
  speed/Pause strips are removed.
- Projectile and paint: the production ball radius is `1.20 m`; continuous and
  impact paint radii are `1.40 m` and `1.75 m`. Valid-top balls have no paint
  payload and remain resident through rest and later motion until the result or
  an explicit terminal reason. Surface recovery replaces ordinary
  penetration-driven deletion, and every new valid-top traversal paints through
  the sole authoritative `PaintSystem` mask.
- Wind: one stage-seeded fixed-tick schedule changes every 30 seconds with a
  three-second transition. Prediction, live physics, replay/agent snapshots, the
  compact direction/strength/countdown UI, and cannon-side flag consume the same
  wind truth. Strong episodes can wake eligible resting balls.
- Results and persistence: the first root launch starts a 90/120/180-second
  stage clock. Only Finish or timeout produces a result, and final unique target
  coverage is the sole score. Save format 4 preserves previous best results;
  replay format 9 and attempt observations record wind and ordered Finish truth.
- Mechanisms: Burst, Splitter, and Uphill Rebound are flat terrain glyphs with
  no projectile collision body. Burst paints then consumes, Splitter launches
  three route-readable children, and Uphill Rebound uses stored local ascent.
  Stage 04's reviewed uphill glyph uses the natural route at `t = 0.30` with no
  artificial shelf.
- This historical closeout's manifest, export, and capture claims no longer
  describe the active format-4 bundle. Its historical evidence remains retained,
  but it is not acceptance evidence for the current implementation.

Historical sections below describe earlier builds and are retained for
traceability only. They must not be used as current implementation evidence.

## Historical Gameplay and Visual Reset Baseline (2026-08-04)

The preceding implementation record was governed by
[`execplans/2026-08-03-gameplay-visual-reset.md`](execplans/2026-08-03-gameplay-visual-reset.md).
Production implementation tasks 1.1 through 5.4 and the bounded headless MVP QA
tasks 6.1 through 7.4 are complete. Phase 10's Fire, audio, and rendered follow-
camera corrections are also complete; its paint refinement passes the direct
drain budget but the hidden rendered-frame comparison remains 0.457 ms over its
locked gate. The plan therefore remains active for root review, the user's
foreground play review, and any separately authorized deferred checks.

The user accepted the standalone `Closed Mountain Lab` result as the intended
terrain MVP and instructed that algorithm to be applied directly to the game.
Generation contract v5 now transfers its broad continuous backbone, elongated
mountain-range silhouette, ordered secondary summits, level-dependent passes,
and rare shallow off-center basin into `RouteGraphMountainSynthesizer` and
`MountainHeightFieldBuilder`. Stage 1 produces four ridge fields and no basin;
Stages 2 and 3 add ridge fields and passes, while only Stage 3 adds one shallow
side basin. The central ridge is never replaced by a crater.

`RouteGraphMountainSynthesizer` produces both that sampled height field and a
connected, irregular row-solid footprint for all three stages. The footprint
joins the rear wall, widens into a substantial body, tapers toward the cannon,
and cannot contain an internal hole. Existing route geometry blends broad,
rollable target lanes into the range without becoming the visible silhouette
or excavating the body. `TerrainTopTopology`
emits top triangles only for those cells and supplies the same indexed faces to
rendering, concave collision, surface queries, target rasterization, and paint
addressing. `TerrainGeometryFactory` closes every exposed contour with thick
support walls and a bottom cap. The mountain is therefore a real closed 3D mass,
not a full-bounds top card with a camera-hidden collider.

Runtime admission no longer depends on `StageMvpPermit`, candidate sweeps, or an
exhaustive certificate. Each stage builds its persisted seed once, installs its
target and mechanism data, and derives a bounded default yaw/elevation/power by
sphere-casting the real projectile toward an eligible point near the target
centroid after physics registration. The existing `StageController`, rigid-body
projectile, measured contact, low-rebound tuning, settlement, result, and
restart owners remain connected to that same terrain.

The paint/coverage contract is now correctly separated. A ball in verified
contact with any real mountain-top triangle emits continuous impact, sweep, and
settle commands, so every traversed top area can become visibly painted.
`PaintSystem` remains the only paint-mask writer. Its separate eligible mask is
used only to decide which threshold crossings increase coverage; wall, apron,
support faces, and empty cells are neither scoreable nor treated as top surface.

Stage 1 uses the broadest route mass, Stage 2 adds Burst, and Stage 3 adds
Splitter plus Bumper and the greatest route complexity. Mechanism placement
still comes from generated route pads. Stage 2's Burst pad now sits on the
visible front ridge rather than behind the secondary rise, and its aiming camera
is raised only enough to preserve the placement visibility contract. Mechanism
solid collision silhouettes remain color-separated as amber, violet, and coral.
Approved trees and rocks remain non-gameplay dressing outside route and
mechanism clearance.

World presentation now separates the warm rear wall from a light faceted
mountain and pale apron. An 80 m front descent plus a 24 m actual-footprint taper
brings the top surface to the apron before the closed shell begins, so no raised
rectangular support skirt remains in the play view. Aiming uses an authored
55-degree cannon-relative view; the lower-left aim panel, cannon, full
pre-impact arc, impact ring, and playable mountain remain visible together. The
white-and-navy cannon,
saturated non-emissive paint, and amber/violet/coral mechanisms retain the same
physical world, with mechanism visual and collision scale increased together to
2x so they remain identifiable at aiming distance. Each mechanism body and
compound shape now publishes a stable kind/shape contact identity, so trajectory
prediction and real projectile contact resolve the same solid object instead of
rejecting it as ambiguous. The Korean-first Pretendard HUD uses a single left
vertical current/target coverage owner, lower-left
aim/power, one
centered Fire button with a crisp local splash icon, and top-right shots plus
gear. Gear/Escape opens the full paused menu; Restart exists there and in
result/replay flows, not in the aiming HUD.

The user's QA of the previous generation-v5 build rejected terrain visibility,
paint feedback, and camera/aim responsiveness. Phase 7 now frames the final
post-safety Briefing, Wide, and Result camera poses against every generated
render AABB on all three stages. Static camera safety is cached at 15 Hz only
while the desired pose changes. Mouse drag is applied once per rendered frame
and trajectory prediction is coalesced to 20 Hz. Phase 10 removed the
synchronous Fire-time refresh: changing aim now invalidates Fire until the next
rendered prediction is ready, and every Human, Replay, Agent, or Debug caller
uses that same admission rule.

`PaintSystem` still owns one 512-square authoritative mask. Production texture
publication is coalesced to 15 Hz and updates one persistent L8 texture in
place, forces the final dirty state before result sealing, and allocates the
recent diagnostic mask only while the F3 overlay is visible. Paint bytes update
a deterministic incremental checksum without rescanning the full mask; replay
format 6 rejects format 5 after that checksum contract change. The current Stage
1 default-shot integration run applied 316 paint commands, including 302
continuous surface sweeps, and produced 10.7419% scoreable coverage without a
second paint authority.

Phase 8 rebuilt the Windows release and ran it as a real windowed Compatibility
renderer at 1280x720, positioned outside the visible desktop and made
non-focusable. The implementing agent directly inspected Stage 1/2/3 aiming and
an active continuous-paint frame under `.agents/evidence/phase8/`. The paint
capture waited for at least 72 applied contact sweeps and 400 written pixels,
then force-published the authoritative mask; the captured left gauge reads 6.7%
and the long downhill blue path is visibly continuous. Focused closed-mountain,
aiming-composition, HUD-state, mountain-range, and Stage 1 physical paint checks
pass, as do `scripts/verify.ps1` and release export. The legacy
`terrain_geometry_test.gd` full-rectangle and exact-count contract was retired;
`mountain_range_mvp_test.gd` and `phase8_front_transition_test.gd` now own the
closed irregular mass and foreground-transition contracts. No broad performance,
replay, balance, exhaustive reliability, or Stage 2/3 playthrough pass was run,
and the screens are implementation evidence rather than user approval.

Phase 10 removes remaining work from the launch and contact hot paths without
changing the gameplay contract. `StageController.request_fire()` no longer asks
the scene to recompute a trajectory, projectiles no longer copy the immutable
target mask, and the contact-gap validator no longer accepts unused eligible-
mask arguments. `AudioDirector` builds the exact six procedural cue streams once
during initialization. `CameraDirector` retains its 15 Hz physics safety solve
but writes the managed camera only from the rendered callback, using each live
projectile's interpolated transform and disabling automatic interpolation on the
camera itself.

`PaintSystem` keeps all 512-square surface samples lazy while caching the two
mask axes and the canonical triangle vertices/normals for only the accepted
64x48 topology cells. Raster counts and nearest-snap selection no longer allocate
temporary dictionaries or sort lists, and the incremental checksum is published
once per complete command. The final canonical hidden probe measured direct
paint drains at 1.922 ms p95 and 6.357 ms maximum, but its off-desktop rendered
paint/non-paint p95 delta was 4.457 ms against the locked 4.0 ms limit. This is an
open delivery gate, not a claim that foreground stutter is resolved. Root source
review found no task-scoped production contract blocker, and the canonical
fastrun executable now contains these Phase 10 changes. Foreground Fire/flight
acceptance remains with the user because no visible process was opened.

## Superseded Core-Interaction Implementation Record (2026-08-03)

The superseded implementation authority was
`execplans/2026-08-03-core-interaction-redesign.md`. A source-level audit after
the prior remediation release found that several reported outcomes were not
supported by the current implementation: the terrain render mesh has no closed
visual shell, projectile contacts fabricate a world-up point, mechanisms use
gameplay trigger areas instead of matching solid bodies, paint stamping is an
X/Z approximation, aiming still solves clicked targets, replay input is not
isolated, and the HUD remains code-built and compositionally inconsistent with
the supplied reference.

The previously recorded run metrics, screenshots, seeds, and solution results
below are retained as historical evidence for the superseded build. They do
not satisfy the active ExecPlan's unchecked acceptance gates. No redesign
feature is considered implemented until its task-specific tests and final
production evidence pass.

Task 00 completed the documentation correction only. Static diff/lifecycle
checks passed; no runtime behavior was changed or claimed. The next executable
milestone is Task 01, which introduces the typed contracts and `TerrainSurface`
owner without changing visible gameplay.

Task 01 added the typed `TerrainGeometry`, `TerrainSurface`,
`ProjectileContact`, `PaintDepositRequest`/tuning, `ShotObservation`, and
`TrajectoryPrediction` contracts plus collision-layer names and narrow owner
interfaces. Godot 4.7.1 registered every class, passed headless import/parse,
and started the existing main scene. The new terrain owner/factory is not wired
into production until Task 03, so this milestone makes no visual-completion
claim.

Task 02 replaced authored route control points with deterministic version-3
route rules, path-first mountain lobes, realized-grid validation, role-owned
mechanism shelves, deterministic decoration placement, and one finalized
eligible mask. Base requests accept First Descent attempt 0
(`845479992`, height checksum `3976121806`, eligible checksum `91346562`),
Burst Basin attempt 1 (`1692116028`, `1331063294`, `2859517061`), and Split
Ridge attempt 6 (`671547267`, `2783769031`, `2129835509`). Repeated base and
fallback-request runs matched seed, attempt, height/mask checksums, route roles,
reversals, mechanism transforms, and decorations. Task 03 is next and will wire
the already-added closed `TerrainGeometry` into production rendering/collision.

Task 03 wired `TerrainSurface` into gameplay and the retained projectile
sandbox. `TerrainGeometryFactory` is now the sole production terrain builder:
it emits `6,912` top, `480` skirt, and `2` bottom triangles, a scaled
`HeightMapShape3D` top collider, and a separate backface-enabled shell collider.
The obsolete `TerrainMeshFactory`, its stage-specific height formulas, and the
legacy PaintSystem eligibility fallback were removed. Headless fixture casts
classified flat, 35-degree ramp, graze, and skirt contacts by distinct body
identity; normalized shell-edge ownership and render/collision parity passed.
The opaque lit shader now uses flat mesh facets, shadows, `0.88 / 0.24`
dry/paint roughness, shell classification, and a restrained paint rim without
emission. Task 04 is next.

Task 04 replaced fabricated world-up impacts and X/Z paint circles with typed
direct-body contacts and one authoritative deposit path. High-speed CCD
manifolds are grouped before collider/shape debounce; the selected contact
retains the measured terrain point, normal, collider identity, shape indices,
incoming velocity, and measured/fallback physical impulse. `PaintSystem`
reconstructs every candidate pixel in 3D, requires connected eligible terrain,
binds its paint and eligibility textures to the terrain shader, applies bounded
steepest-descent flow, and returns the accepted amount before projectile
payload changes. The 80-shot contact matrix, exact 3,228-pixel narrow stamp,
zero-overlap gain, cliff isolation, bounded flow, and live projectile payload
integration passed headlessly. The obsolete Area-based mechanism collision now
fails its historical Phase 5 assertion as expected; Task 05 replaces that path
with matching solid bodies.

Task 05 replaced all gameplay trigger areas with scene-owned compound
`StaticBody3D` mechanisms and a separate selection-only query layer. Burst now
submits one terrain-aware `14 m / 140` deposit through `PaintSystem`; Splitter
removes its parent and emits exactly three route-role children with 90% total
payload, generation-1 radius multipliers, and the frozen contact-normal spawn
formula; Bumper queues the frozen downstream corrective impulse for the next
direct-body integration tick. Real rigid-body fixtures matched preview body,
shape, and impact center, rejected duplicate contacts, accepted a later
separated Bumper strike, restored state on reset, and enforced the eight-ball
cap. The sealed observation recorded four activations and three children.

Task 06 removed `ImpactTargetSolver` and its UID. Empty-viewport drag now maps
directly to yaw/elevation, A/D/W/S apply fixed independent steps with owned
hold timing, wheel and focused `−/+` controls change power only, and Space,
Fire, and Tab enter the same guarded stage actions. `TrajectoryPredictor`
integrates the frozen 60 Hz damping/gravity order, sphere-casts the real ball
radius against terrain/mechanism bodies, stops at the first measured collision
or exact bounds crossing, and leaves timeout non-fireable. The preview
arc-length samples the complete result into at most 96 dots, always preserves
launch/end points, aligns the collision ring to its measured normal, and uses
a camera-facing red cross for bounds exit. Actual UI events, all 30 frozen
stage/aim cases through the Godot physics backend, three isolated mechanism
casts, bounds exit, timeout, and the prior projectile/mechanism/state
regressions passed. Task 07 is next.

Task 07 made `ShotObservation` the single sealed shot summary and corrected
fire-time ordering so spawn/contact signals cannot precede its creation. The
controller now waits for two consecutive inactive physics ticks, conserves
aggregate payload across split and settled balls, and gives replay and the
agent API the same sealed object. Every aim, fire, restart, and debug mutation
now carries or respects an action origin; replay presentation holds an
exclusive `REPLAY` lock until its clean briefing exit. Replay format 3 stores
only ticked actions plus stage/profile/seed/checksum metadata and expected shot
outcomes, rejects format 2, and validates contact, coverage, mechanism order,
settlement reasons, and result state. `CameraDirector` now applies 1.5 m terrain
clearance and line-of-sight correction to all bookmarks, briefing orbit,
mechanism focus, and speed-weighted split framing with a 96 m wide-view latch.
All named camera fixtures passed across the three stages. A fresh-process
record/replay matched first contact and coverage with zero measured delta, and
the independent persistence matrix preserved locale, unlocks, results, and
settings. Task 08 is next.

Task 08 replaced code-built interface panels with scene-owned HUD and screen
components on a 1280x720 logical canvas. One Theme now owns Pretendard,
palette, typography, radii, progress, and keyboard-focus styling;
`HudController` only coordinates typed state. The frozen aiming edge layout,
aggregate payload, direction/elevation, target marker, sealed shot summary,
first-session hint, mechanism callouts, replay controls, result width, and
immediate persistent Korean/English switching passed their headless tests at
all three supported 16:9 sizes. `UIFactory` and its UID were removed, and only
the previously approved committed Kenney/Pretendard files are referenced.
The dummy headless renderer could not provide a viewport texture, so no render
capture was produced or treated as visual approval. Task 09 is next.

Task 09 retired the obsolete projectile sandbox and migrated its projectile-
paint integration check to the production gameplay scene. The new explicit
`scripts/test.ps1` owns the ordered fresh-process suite and unconditional
persistence/replay cleanup; reliability and performance assertions now use the
frozen `50 ms`, `60 FPS`, `33.3 ms`, and `128 MiB` limits. A resumable offline
search tool evaluates production 60 Hz shots and composes their authoritative
paint masks. First Descent now has a normally validated one-shot solution at
`(12, 26, 100)`, reaching `5.335%`.

Task 09 is stopped at its locked balance-contract gate. Precision probes that
physically activated every mechanism measured a best isolated Burst result of
`2.689%`, a best Splitter result of `1.293%`, and `0%` for each of eight exact
Bumper strikes. Sample five/six-shot sequences reached only `4.533% / 3.443%`,
far below the fixed `27% / 70%` targets. Contact, finite-payload paint, mask
authority, and mechanism activation tests pass, so silently lowering targets
or restoring oversized paint would violate the active ExecPlan. Burst Basin
and Split Ridge intentionally retain empty `reliable_solution` arrays, and
`phase6_content_test.gd` remains a truthful failing gate pending an explicit
balance-contract revision or conforming search result.

## Context

The repository was created from a complete vertical-slice brief. The
2026-08-02 baseline established the broad application and gameplay systems.
The first 2026-08-03 remediation produced a generated-stage,
direct-target/Korean-first build, but its completion claims were superseded by
the static-audit correction above.

## Decision

- The project uses Godot 4.x, GDScript, the Compatibility renderer, Windows desktop, and a fixed 60 Hz physics tick.
- The initial runnable entry is an explicitly labeled bootstrap scene that checks project loading, 3D rendering, procedural heightfield geometry, collision generation, and the intended distant-mountain composition.
- Phase 2 replaces the configured main entry with a projectile sandbox while preserving the isolated bootstrap scene. `ProjectileData` owns tuning, `CannonBallistics` is shared by preview and launch, and `ProjectileManager` bounds and cleans up rigid bodies.
- `PaintSystem` owns one 512×512 runtime paint image and its derived texture. The terrain shader samples that texture, while incremental threshold accounting derives coverage from the same pixel writes and an inset eligible mask.
- `StageController` is the sole stage-state authority. Human buttons and cannon input call the same validated fire/restart methods; `CameraDirector` and `HUDController` only react to emitted state.
- `GimmickBase` owns common physical activation, duplicate-projectile rejection, cooldown/charges, state snapshots, and reset. Burst delegates to `PaintSystem`, Splitter delegates bounded child creation to `ProjectileManager`, and Bumper applies one directional rigid-body impulse.
- `StageCatalog` owns the exact three-stage resource list, while `GameState` and `SaveSystem` own selection/unlocks/results/settings and atomic versioned local persistence. Stage scripts contain no stage-specific rule branches.
- `ReplayRecorder` stores format-3 deterministic actions and expected sealed observations. `ReplayPresentationController` exclusively locks gameplay mutations to replay-origin actions until clean exit; `GameplayAgentApi` uses the same validated action and observation boundaries without HUD or mouse coupling.
- Split children are redirected toward the visible downhill face and disperse divided payload over wider lanes. This gives Split Ridge a difficult, high-value route while retaining the one-generation and eight-projectile limits.
- `AppRoot` owns navigation among separate main-menu, stage-select, settings, and active-gameplay interfaces. Gameplay emits narrow navigation signals instead of knowing the application shell.
- Presentation uses approved Kenney low-poly dressing and particle textures, bright faceted terrain, an eight-emitter paint-particle pool, bounded camera shake, and runtime-generated PCM music/SFX routed through Master/Music/SFX buses.
- `DebugOverlay` is debug-build-only and derives four mask views plus metrics/actions from runtime owners; it exports ReplayRecorder-backed JSON rather than maintaining parallel gameplay state.
- `DeliveryCaptureRunner` deterministically reproduces the seven evidence states only when explicit command-line arguments are present. `export_presets.cfg` owns the Windows Desktop release path.
- `PaintSystem` keeps paint, eligible, recent, and derived excluded masks in byte buffers; threshold crossings update coverage incrementally and each dirty batch uploads once. This removed the measured Burst-frame stall without adding a second coverage authority.
- Product behavior, technical ownership, planned work, and implemented status are stored separately to avoid treating plans as working features.

## Rationale

- A small real scene gives the next implementation phase a verified engine baseline without pretending the vertical slice already exists.
- The provided brief already locks the engine, core architecture, mechanisms, scope exclusions, performance target, and acceptance artifacts.
- Compatibility rendering and dependency-free procedural primitives keep the initial project portable on modest Windows hardware.

## Consequences

- The bootstrap remains an isolated validation scene; the obsolete projectile sandbox is retired and the StageData-selected gameplay scene is the only projectile/paint integration entry.
- The complete menu-to-stage-to-result flow, all three stages and mechanisms, persistence/replay, agent actions, debug tooling, presentation, export, performance evidence, and seven release screenshots run and have focused checks.
- Future feature completion claims must cite running-game checks and update this record.

## Superseded Remediation Claims (2026-08-03, Historical)

- `.agents/Plan.md` completed all six earlier phases and is lifecycle `done`.
  Its entries below describe the superseded build and are not current proof.
- `SeededStageGenerator` produces the exact three deterministic layouts from typed profiles. One accepted immutable `GeneratedStageLayout` supplies the 6,144-triangle mesh, collision, paint queries/mask inputs, dressing, mechanism placement, replay checksum, and agent height observations.
- Stage profiles increase route count, reversals, shelves, and vertical complexity. Accepted seeds/checksums are First Descent `845487911/3476095321`, Burst Basin `1692123947/1568157987`, and Split Ridge `671737323/3215880357`.
- Stage 1 has no mechanism, Stage 2 has one Burst, and Stage 3 has one Splitter plus one Bumper. Placement is deterministic and validated; distinct scene-authored 3D silhouettes, compact below-device labels, and validated camera bookmarks keep mechanisms readable.
- `AimInputController` owns pointer/keyboard device input. It raycasts terrain/mechanisms, asks the fixed-tick damped `ImpactTargetSolver` for the lowest valid elevation at current power, exposes explicit invalid aim, and renders at most 72 dots through the real first collision. `CannonController` remains device-independent.
- Power uses visible minus/plus controls, hold repeat, wheel fine tuning, and keyboard fallback; Space or Fire requests the same guarded shot action. A/D/W/S remain the accessible angle fallback.
- The app ships complete `ko`/`en` translations, defaults new/V1-migrated saves to Korean, persists explicit locale choice in save format 2, and applies Pretendard plus shared UI primitives across menu, selection, settings, HUD, pause, and results.
- The approved runtime import is complete: five Kenney Nature Kit GLBs, six Kenney Game Icons PNGs, four Kenney Particle Pack PNGs, Pretendard Variable WOFF2, and four local license files. `docs/asset-licenses.md` records the pinned hashes, provenance, and uses.
- Physical reliable solutions clear `4/27/70%` targets at 5.791%, 33.470%, and 74.359%; Stage 2 activates Burst and Stage 3 activates both Splitter and Bumper. The six-shot Stage 3 left-route-only guard remains below target at 4.353%.
- The final Godot 4.7.1 Windows release and seven Korean-default 1920×1080 screenshots replace the legacy evidence. Separate Korean/English 1280×720 and 1600×900 captures cover responsive settings, pause, menu, stage selection, and aiming.

## Historical Baseline Status (2026-08-02)

- Repository and agent environment: complete.
- Godot project configuration and bootstrap scene: complete.
- Phase 2 cannon and projectile sandbox: complete.
- Phase 3 authoritative paint system: complete.
- Phase 4 stage loop, cameras, and gameplay HUD: complete.
- Phase 5 Burst, Splitter, and Bumper: complete.
- Phase 6 three-stage content, progression/save, replay, and agent API: complete.
- Phase 7 application UI and presentation: complete.
- Phase 8 debugging, delivery, and final QA: complete.

## Historical Redesign Risks (2026-08-03)

- Godot 4.7.1 is shared with Cardborne from
  `D:\tools\Godot\4.7.1-stable`; the user-level `GODOT_BIN` points to its
  console executable. Future work must use this shared runtime and must not
  recreate a project-local Godot copy. Headless verification remains the
  default unless a visible editor or game session is required by the task.
- Stage 1 currently has an MVP permit, not the exhaustive all-target
  `DirectReachabilityCertificate` required for release. Do not label the stage
  fully certified or use the permit to satisfy export/final-delivery gates.
- Stage 2 and Stage 3 have version-4 structural inputs but no accepted permit or
  full certificate. Production generation intentionally rejects them until
  Phase 2 supplies their exact target, reachability, balance, and containment
  evidence.
- The core loop is headlessly proven, but the current terrain composition, HUD,
  camera framing, collision readability, and running paint appearance have not
  passed the user-coordinated visual gate. Do not infer visual acceptance from
  headless physics results or concept images.
- The complete legacy `scripts/test.ps1` matrix is not yet a passing release
  gate: its Stage 2/3 prediction/reliability assumptions predate fail-closed
  admission, and the all-target Phase-5 fixture remains pathologically slow.
  The focused Stage 1/contact/paint/state/schema tests and `scripts/verify.ps1`
  pass; performance and broad test migration remain parked behind the MVP.
- Targets and shot counts remain fixed at `4%/4`, `27%/5`, and `70%/6`.
  Superseded direct-target solutions and old checksums are historical only.
- The generated Windows executable is unsigned and `builds/` is ignored; distribution signing and packaging are outside this vertical-slice scope.
- The imported low-poly models, UI icons, particles, and procedural audio are
  approved inputs, but neither they nor the concept board prove the active
  physical terrain, paint, HUD, or presentation contracts.

## Verification

### Current Stage 1 MVP verification (2026-08-03)

- `stage1_mvp_test.gd` passed against the real gameplay scene and owners: first
  `terrain/top` contact, `5.100 s` target contact, `36.688 m` parent surface
  path, `306` continuous sweeps, `18.8140%` coverage, drain-before-result, and
  deterministic Restart.
- `stage_mvp_permit_producer.gd --verify-only` reproduced accepted seed
  `845487911`, default aim stable key `-6:591:67`, and predictor/rigid-body
  local hits within one millimeter of each other near the target centroid. The
  stored proof checksum binds the exact layout, aim, and both hit witnesses; an
  aim-only substitution fails closed.
- Focused contact and paint gates passed: `projectile_contact_test.gd`,
  `projectile_settling_test.gd`, `containment_wall_test.gd`,
  `paint_queue_determinism_test.gd`, `phase3_paint_test.gd`, and
  `phase3_projectile_paint_test.gd`.
- Focused state and consumer gates passed: `phase4_state_test.gd`,
  `shot_observation_test.gd`, `replay_presentation_test.gd`,
  `shot_feedback_test.gd`, `localization_ui_test.gd`, and
  `phase8_debug_test.gd`. A rejected authoritative paint command is preserved in
  the sealed observation and forces `STAGE_FAILED`.
- `scripts/verify.ps1` passed headless project import/script parsing and
  main-scene startup with Godot `4.7.1.stable.official.a13da4feb`. No visible
  Godot window or retained Godot process was used.

### Phase 9 responsiveness recovery (2026-08-04)

- `AppRoot` now retains one immutable layout and preview artifact per stage for
  the process lifetime. Returning between the main menu and stage selection no
  longer rebuilds the active mountain, textures, material, or dressing, and
  gameplay receives the same accepted layout while creating fresh mutable stage
  and paint owners.
- The runtime default aim no longer performs a 294-trajectory grid. It selects
  the real target pixel nearest the target centroid, uses the bounded ballistic
  nomination owned by `DirectReachabilityValidator`, and accepts it only after
  a matching real first hit. The three measured aim components completed in
  103.13 ms, 129.93 ms, and 100.21 ms.
- `PaintSystem` no longer scans all 262,144 mask bytes on every paint drain or
  samples the entire 512-square terrain surface during scene entry. It maintains
  an incremental format-6 replay checksum, lazily caches exact topology samples
  only around paint footprints, updates one persistent texture at 15 Hz, and
  allocates recent-paint diagnostics only while the F3 overlay is visible.
- In the hidden off-desktop Windows release, main-menu/stage-select calls measured
  1.199 ms and 0.841 ms. Cached Stage 1 entry fell from 739.678 ms to 77.013 ms;
  aim-ready time fell from 1007.062 ms to 273.611 ms. Physics remains fixed at
  60 Hz with interpolation enabled.
- The same bounded rendered run applied 121 surface sweeps, wrote 4,374 pixels,
  and published 23 coalesced texture batches. Because Windows throttled the
  off-desktop window near 30 fps, frame values are comparative only: non-drain
  p95 was 34.060 ms and paint-drain p95 was 39.738 ms (42.381 ms max).
- The final production capture under `.agents/evidence/phase9/` was inspected
  directly and shows the active projectile's continuous blue path and 9.2%
  coverage without a forced texture replacement. `stage1_mvp_test.gd` retained
  first real top contact, 4.983 seconds of contact, 54.887 m of travel, 299
  sweeps, 9.8688% coverage, drain-before-result, and deterministic restart.
- Focused paint ordering, replay format-6/format-5 rejection, Stage 1 physical
  paint, `scripts/verify.ps1`, and Windows release export passed. No visible
  Godot window was opened; the runner used a hidden, non-focusable, off-desktop
  production window.

### Phase 10 Fire-to-flight correction (2026-08-04)

- The canonical Windows probe rejected a dirty-aim Fire in `0.002 ms` with no
  shot or projectile side effect, then accepted ready Fire in `1.255 ms`.
- FOLLOW changed the rendered camera on all `195/195` sampled frames in which
  the interpolated projectile moved; the maximum unchanged-camera run was zero.
- The verified-contact run retained one command per contact interval and fixed
  60 Hz physics. It applied 121 sweeps, wrote 3,949 pixels including 1,049 new
  scoreable pixels, published 21 texture batches, and still had an active
  projectile at the stop point.
- Direct nonempty paint-drain timing passes at `1.922 ms` p95 and `6.357 ms`
  maximum. The hidden window's rendered drain p95 was `38.723 ms` versus
  `34.266 ms` for non-drain frames, leaving a `4.457 ms` delta and therefore one
  unresolved locked acceptance gate.
- `scripts/verify.ps1` passed after the final production change, the canonical
  release executable postdates every changed production source, and the fastrun
  registry entry remains unchanged. Both 1280x720 Compatibility-renderer images
  under `.agents/evidence/phase10/` were opened and inspected; they show the
  airborne projectile and the continuous physical paint trail without UI
  obscuring the projectile/terrain chain. They are implementation evidence, not
  foreground user acceptance.

### Historical verification for superseded or pre-MVP builds

- Superseded redesign Task 02: `stage_generation_test.gd` passed base and
  fallback-request determinism for all stages. Fallback requests accepted at
  attempts `0 / 5 / 28`; eligible ratios remained `0.423386 / 0.446671 /
  0.414547`. `mechanism_placement_test.gd` passed exact role/centerline/shelf,
  transform, tangent, physical-clearance, visibility, and fixed-point rejection
  gates. `decoration_placement_test.gd` passed deterministic `10 / 14 / 18`
  placements. All checks used Godot 4.7.1 headlessly.
- Superseded redesign Task 03: `terrain_geometry_test.gd` proved the exact
  `7,394`-triangle production shell, flat winding, normalized watertight edge
  ownership, `≤0.01 m` heightmap parity, stable gameplay nodes, shader
  constraints, and all four direct fixture casts. The migrated
  `phase2_physics_test.gd`, `phase2_test.gd`, `phase3_paint_test.gd`, and
  `phase5_mechanism_test.gd` passed, followed by `scripts/verify.ps1` and a
  30-frame headless main-project startup.
- Superseded redesign Task 04: `projectile_contact_test.gd` passed 20 repetitions
  each of flat, 35-degree ramp, high-speed graze, and skirt impacts (80/80),
  exact collider/shape identity, measured point/normal/radius tolerances, and
  separated recontact debounce. `phase3_paint_test.gd` produced exactly 3,228
  visible/scored pixels and 1.231384% coverage, zero second-stamp gain, no
  opposite-cliff or ineligible writes, and bounded synchronous flow.
  `phase3_projectile_paint_test.gd` accepted 112/112 physical requests, consumed
  329.4 of 520 payload only after contact, and reached 4.2039% coverage with no
  ineligible pixels. Phase 2 ballistics/fixture and Phase 4 state regressions
  also passed headlessly.
- Superseded redesign Task 09 partial gate: the ordered `scripts/test.ps1` passed
  terrain geometry, generation, placement, decoration, ballistics, contact,
  authoritative paint, production projectile-paint, state, and mechanism
  tests before stopping at the intentional Stage 2/3 empty-solution assertions.
  Its `finally` block then completed both persistence and replay cleanup
  processes. The production integration measured 111/111 accepted requests,
  295.4 consumed payload, and 4.1488% coverage. Separate strengthened probes
  measured a 2.686 ms slowest restart and, at 1920x1080 headlessly, 594.76 ms
  load, 145.05 unpaced average FPS, 10.19 ms worst frame, one active ball, and
  43.19 MiB static memory. `phase6_solution_test.gd` validated the recorded
  First Descent shot at 5.335% under the normal 60 Hz path.

- Final tested engine: Godot `4.7.1.stable.official.a13da4feb`, Windows Compatibility renderer, Intel Iris Xe, fixed 60 Hz physics.
- Final 2026-08-03 regression: every Phase 2–8 check plus `stage_generation_test.gd`, `mechanism_placement_test.gd`, `aim_interaction_test.gd`, and `localization_ui_test.gd` passed. `scripts/verify.ps1` passed after final scene/resource/script changes.
- Generation: First Descent attempt 1/166 ms, Burst Basin attempt 2/236 ms, Split Ridge attempt 30/1,878 ms; repeated checksums matched. Physical clears were 5.791%, 33.470%, and 74.359%; the Stage 3 left-route-only guard failed at 4.353%.
- Persistence/replay: format-2 save preserved explicit English selection across a fresh process; replay first-impact and coverage deltas were both zero.
- Reliability/performance: 30 cycles left no projectile nodes; slowest restart was 2.056 ms. The final 1920×1080 Burst workload loaded in 459.79 ms, averaged 60.00 FPS, recorded a 20.18 ms worst frame, used 50.70 MiB static memory, and kept the observed active count within the tested bound. A confirming verbose run exited without the first run's transient two-instance ObjectDB warning.
- Production: the release preset exported `builds/windows/PaintMountain.exe`; the registered fastrun command `& '.\builds\windows\PaintMountain.exe'` starts it. That executable generated the seven final 1920×1080 Korean-default screenshots, all individually inspected without the debug overlay.
- Run: `powershell -ExecutionPolicy Bypass -File scripts/verify.ps1 -GodotPath <path-to-Godot-console.exe>`
- Phase 2 pure check: `Godot_v4.7.1-stable_win64_console.exe --headless --path . --script res://tests/phase2_test.gd`
- Phase 2 rigid-body check: `Godot_v4.7.1-stable_win64_console.exe --headless --path . --script res://tests/phase2_physics_test.gd`
- Observed 2026-08-02 after final preview validation: 31 deterministic ballistic samples matched exactly; two repeated rigid-body shots physically impacted and settled within 0.01632 m in the final batch (0.25 m tolerance), while the radius-aware preview was within 1.62103 m of the physical first impact.
- Phase 3 mask check: `Godot_v4.7.1-stable_win64_console.exe --headless --path . --script res://tests/phase3_paint_test.gd`
- Phase 3 integration check: `Godot_v4.7.1-stable_win64_console.exe --headless --path . --script res://tests/phase3_projectile_paint_test.gd`
- Observed 2026-08-02 after stage tuning: overlap remained 0.3802%; bounded flow increased a 0.015406% direct stamp to 0.043754%; one physical shot emitted 57 finite requests, accepted 8 terrain-aligned deposits, and produced 1.3274% authoritative coverage.
- Phase 4 state check: `Godot_v4.7.1-stable_win64_console.exe --headless --path . --script res://tests/phase4_state_test.gd`
- Phase 4 render helper: `Godot_v4.7.1-stable_win64_console.exe --path . --resolution 1280x720 --script res://tests/capture_gameplay_frame.gd -- --state=aiming --output=<path>`
- Observed 2026-08-02: the live shot traversed every intermediate state and returned to aim below target; duplicate fire was rejected; restart cleared paint/projectiles/refilled shots in 0.452 ms; pure clear/failure boundary checks passed; 1280×720 briefing and aiming captures showed no HUD clipping after one overlap correction.
- Phase 5 mechanism check: `Godot_v4.7.1-stable_win64_console.exe --headless --path . --script res://tests/phase5_mechanism_test.gd`
- Observed 2026-08-02 after content tuning: physical Burst collision added 24.0171% and spent one charge; Splitter produced three generation-one children totaling 468/520 payload; Bumper redirected one retained projectile; reset, duplicate, recursion, and eight-ball guards passed.
- Phase 6 content check: `Godot_v4.7.1-stable_win64_console.exe --headless --path . --script res://tests/phase6_content_test.gd`
- Phase 6 solution check: `Godot_v4.7.1-stable_win64_console.exe --headless --path . --script res://tests/phase6_solution_test.gd -- --stage=<stage_id>`
- Observed 2026-08-02: the catalog loaded exactly three stages; atomic save fallback, unlock updates, two-shot replay serialization/control, and UI-independent agent actions passed. Final byte-mask physical clears reached 4.128% for First Descent, 27.306% for Burst Basin with Burst activation, and 76.796% for Split Ridge after both Bumper and Splitter activation.
- Phase 7 UI check: `Godot_v4.7.1-stable_win64_console.exe --headless --path . --script res://tests/phase7_ui_test.gd`
- Observed 2026-08-02: menu, stage select, settings return paths, gameplay briefing, pause, clear result, and gameplay cleanup passed through the real app shell. Rendered captures at 1280×720, 1600×900, and fullscreen 1920×1080 showed no panel clipping; the bright faceted mountain, foreground cannon, trajectory, markers, buttons, and hierarchy remained legible.
- Observed 2026-08-02: the post-presentation regression batch passed Phase 2–7 checks and all three physical solutions without recurring headless errors; Phase 4 restart measured 1.080 ms under the concurrent batch.
- Phase 8 debug check: `Godot_v4.7.1-stable_win64_console.exe --headless --path . --script res://tests/phase8_debug_test.gd`
- Observed 2026-08-02: the overlay was hidden by default, exposed every specified live metric, four mask views, and ten actions in debug builds, and exported a complete stage/seed/aim/gain/mechanism/outcome JSON log.
- Phase 8 fresh-process persistence: run `phase8_persistence_test.gd` in `write`, `read`, then `cleanup` modes. Three unlocks, Split Ridge 77.921%/one star, master volume 0.43, and high quality survived the second process.
- Phase 8 fresh-process replay: run `phase8_replay_process_test.gd` in `record`, `replay`, then `cleanup` modes. The replay reproduced first impact with 0.00000 m delta and coverage with 0.00000 percentage-point delta.
- Phase 8 reliability: `phase8_reliability_test.gd` passed 30 fire/restart/out-of-bounds cycles with no projectile nodes, verified empty-payload and lifetime paths, and measured a 1.589 ms slowest restart in the final batch. The Phase 5 test separately retained the one-generation/eight-ball split limits and briefing selection intent.
- Phase 8 performance: fullscreen 1920×1080 Compatibility rendering on Intel Iris Xe loaded Burst Basin in 355.46 ms and averaged 59.84 FPS over 360 frames; the worst frame was 50.83 ms, static memory was 62.80 MiB, and active balls stayed bounded.
- Phase 8 production check: the `Windows Desktop` release preset built `builds/windows/PaintMountain.exe`, the executable started successfully, and it generated seven separately inspected 1920×1080 PNGs under `screenshots/` with no debug overlay.
- Documentation-only fallback: `git diff --check`
