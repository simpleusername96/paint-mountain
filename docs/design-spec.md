---
type: spec
status: active
created: 2026-08-02
last_reviewed: 2026-08-11
scope: gameplay, content, presentation, performance, and deliverables
source: source-brief.md
related:
  - source-brief.md
  - technical-architecture.md
  - test-checklist.md
  - ../.agents/Plan.md
  - ../.agents/execplans/2026-08-03-gameplay-visual-reset.md
  - ../.agents/execplans/2026-08-03-core-interaction-redesign.md
  - ../.agents/execplans/2026-08-05-gameplay-contract-recovery.md
  - ../.agents/execplans/2026-08-06-ballistic-terrain-preparation.md
  - ../.agents/execplans/2026-08-06-wind-driven-coverage-loop.md
  - ../.agents/execplans/2026-08-06-fast-stage-entry-and-fire-capacity.md
  - ../.agents/execplans/2026-08-08-projectile-scale-balance-and-aim-performance.md
  - ../.agents/execplans/2026-08-07-target-coverage-and-safe-aim-framing.md
  - ../.agents/execplans/2026-08-07-cannon-shot-observation.md
---

# Paint Mountain Design Specification

## Purpose

Define the compact working interpretation of the effective `source-brief.md`
for a polished thirty-stage 3D gravity-driven paintball puzzle game. Its dated
supersessions replace finite-payload/flow behavior, locked progression, serial
Fire, rejected paint scale, synchronous navigation generation, and the original aiming-HUD placement while
preserving manual launch planning, measured physical contacts, Korean-first
presentation, and the rest of the baseline directive.

## Scope

The player inspects a distant mountain, sets a stationary cannon's
yaw/elevation/power, fires a rigid-body paintball, and watches gravity,
real surface contact, rolling, and mechanisms produce coverage. Every valid
Playable Terrain Surface area physically traversed while in contact is painted;
only its overlap with the immutable Target Area mask counts toward coverage. The
Support Shell, bottom, apron, decorations, and mechanisms remain unpainted. There is no paint
reservoir, depletion, or autonomous flow. The first actual launch starts the
stage timer; the player finishes the run or the timer ends it.

The vertical slice includes a main menu, stage select, briefing/inspection,
aiming, projectile observation, coverage result, pause, settings, saving,
debug tooling, audio/visual feedback, thirty all-open stages, one ball type, and
exactly three mechanism types.

## Requirements

### Experience pillars

- Large readable terrain; predictable but learnable physics; strong causal feedback; sub-second confirmed restart; restrained presentation.
- The challenge is launch planning. The player cannot steer a fired ball.
- An effective shot should produce a legible downhill route or chain reaction and encourage immediate parameter refinement.

### Spatial and camera composition

- Cannon length is roughly 2–3 m. The current terrain family widens from roughly
  210 to 280 m across thirty stages while its nominal summit progression stays
  within roughly 64 to 92 m. The nearest playable mountain front remains at least 70 m from the
  cannon across stage sizes instead of advancing toward it as the board grows.
- The actual projected playable silhouette is a lower, wider mountain range,
  not a narrow tower inside a wide empty grid. In Aim View, target roughly `3:4`
  height-to-width with several lateral rises and readable route layers. This is
  a loose visual reference, not a projection gate; shared physical topology,
  depth, terraces, valleys, and support faces remain mandatory.
- In the perspective `Aim View`, the cannon is a clearly identifiable
  lower-foreground anchor and the mountain's main mass is readable across the
  middle and upper frame. Minor peripheral terrain cropping is acceptable when
  it keeps the cannon, muzzle, trajectory, major rises, and aiming context clear.
  Keep the authored 48-degree FOV and one shared composition; do not solve the
  view with per-stage camera repairs or geometry changes made only for a ratio.
- Briefing begins in `Map View` with a limited three-quarter spherical orbit and
  zoom around the immutable center of the visible terrain mass. `Aim View`
  uses one authored, recoverable cannon composition and terrain-targeted aiming;
  it does not add independent camera navigation. Map View remains the deliberate
  whole-board inspection mode and never changes the stored aim or launch target.
- Each stage has one baked cannon transform at least 70 m in front of its
  nearest playable terrain edge. The player changes yaw, elevation, and power,
  but cannot orbit or move the launch position around the mountain. Map View
  orbit changes only the inspection camera.
- An accepted Fire action enters `Shot Follow`, which follows that newly launched
  root paintball rather than averaging every resident ball. It shows first
  terrain contact, holds the impact for 0.8 seconds, then returns to Aim View.
  The player may return early without changing the projectile or stored aim.
  Result uses a restrained three-quarter reveal.

### Controls and information

- Briefing starts in Map View: left-drag changes yaw/pitch around the fixed
  terrain visual center, wheel changes radius, Enter/Start enters Aim View, and
  Escape pauses. Terrain and mechanism clicks never pan or refocus the camera.
- Gameplay has Aim View and Map View interaction modes while Board Phase remains
  `AIMING`. In Aim View, click selects a valid Playable Terrain Surface top point
  and drag retargets to the latest valid top point; invalid drag gaps retain the
  last valid target. Elevation controls and W/S pin elevation while solving yaw/
  power for that target; existing power controls and wheel pin power while
  solving yaw/elevation. A/D is not a human target-mode control. Map View
  left-drag changes yaw/pitch around the same fixed terrain visual center, wheel
  changes radius, and aim/Fire input is blocked. It has no pan or click-refocus.
  Tab and one visible focusable toggle switch modes without changing the stored
  aim or preview, and the switch never performs terrain-scale work in the input
  callback.
- Show the selected target, current coverage, shots, elevation, power, a dotted
  initial ballistic arc, and a first-impact marker. The selected target is
  independent of an exact prediction: show a confirmed impact only for matching
  target and aim revisions; keep only permitted stale arc dots subdued and
  hide stale impact or exit markers. Use shape with the existing blue role.
  Never preview post-impact solution paths or exact coverage.
- The complete pre-impact preview uses the same radius, active fixed-step
  gravity, damping, launch origin, speed, shared collision geometry, and
  collision layers as the real ball. Active board play uses a fixed two-times
  time scale on the 60 Hz physics tick, so prediction uses the matching 1/30
  simulation step. It ends at the first physical collision or open-bounds exit.
  It is advisory: preview pending or a predicted miss never blocks Fire. A Human
  target selection or target-preserving elevation/power edit commits the best
  bounded approximate inverse candidate immediately, without an exact collision
  query. Rejected approximate requests preserve the prior canonical aim. Direct
  agent and debug tuple actions remain atomic. No post-impact route is shown.
- Firing enters Shot Follow for the new root ball. A visible `대포로 돌아가기`
  / `RETURN TO CANNON` control and context-sensitive Tab return immediately to
  Aim View; the ball continues physically and no post-fire steering is added.
  Aim remains editable after the return while earlier balls move. There is no
  persistent Follow/Wide/Cannon preset rail, gameplay speed, or gameplay Pause
  strip.
- There is no ambient wind or equivalent hidden external force. Pre-impact
  planning and live motion use gravity, damping, collision, and the same
  projectile geometry; after terrain contact, only collision and explicit
  mechanism impulses may reactivate a resting ball.

### Stage state

- Authoritative Board Phases are `LOADING`, `BRIEFING`, `AIMING`, `PAUSED`,
  `FINISHING`, and `RESULT`. Active projectile families, resident balls, paint
  drain, and camera presentation mode are orthogonal typed activity, not
  competing stage phases.
- Two root-shot families may coexist. Fire alone disables at two-family capacity,
  an illegal canonical aim, no shots, terminal pending, or modal lock. Prediction readiness never
  changes Fire admission. Aim controls remain editable while prior families move.
- An initial Fire slot releases when its generation-0 root first authoritatively
  traverses valid Playable Terrain Surface or terminates. Family observation
  waits until every current body has reached that surface or terminated;
  resident terrain balls may therefore
  remain physically active without permanently exhausting Fire capacity.
- Coverage remains visible in its authoritative nonmodal gauge. There is no
  temporary per-shot summary or mechanism briefing/activation message card.
  Reaching target coverage or spending all shots neither clears nor fails the
  run. After the first shot, Finish may end the run; otherwise the stage duration
  ends it. Final unique target coverage is the sole score and star thresholds
  remain grades.
- Restart removes projectiles, paint, particles, temporary mechanism state, timers, and camera transitions.
- The current catalog shares one canonical terrain-family seed. Stage and
  profile identity still make the thirty stages distinct, and each stage has
  one versioned persisted baked layout. Stage entry, retry, and process
  restart reuse that exact layout; gameplay performs no terrain seed roll,
  candidate search, or reconstruction.
  The offline generator is authoring infrastructure only. Future randomness may
  be introduced only through separately baked and reviewed catalog variants.

### Projectile and paint

- Rigid bodies use gravity, CCD, low ordinary-terrain rebound, rolling/sliding
  friction, angular motion, damping, bounds, and fixed-timestep behavior. Once
  a ball has reached valid Playable Terrain Surface, age, low speed, and engine sleeping do
  not delete it; it may sleep naturally and collision or a mechanism impulse may move it
  again. Explicit mechanism consumption, real escape, a never-contacted miss
  timeout, unrecoverable invalid geometry, and stage cleanup are the only
  pre-result termination families.
- Projectile data owns physical and paint tuning plus activation capacity. It
  owns no paint amount, payload, depletion rate, lifetime, slow-stop threshold,
  or flow budget. The root physical/visible radius is `2.40 m`; continuous and
  impact paint radii are `2.80 m` and `3.50 m`. Split children retain the `0.78`
  scale multiplier. The ball centre starts one radius beyond the visible muzzle
  with only the additional vertical lift needed to clear the cannon apron.
- A representative default shot should feel close to three seconds before first
  terrain contact, but elapsed flight time is not a legal-shot gate or an exact
  per-stage contract. Physical standoff and launch tuning prevent both an
  immediate adjacent hit and a needlessly prolonged arc. A root that has never
  contacted Playable Terrain Surface terminates at 6.0 seconds, except that a
  complete current matching prediction of a first Playable Terrain Surface
  contact may grant bounded lifetime through that promised contact. A normal
  unmatched miss retains the 6.0-second timeout and an open-bounds exit remains
  immediate.
- Runtime power uses `0.1%` increments over `0..100` and maps linearly to
  `32..160 m/s`. Whole-power keys and offline generated identities remain
  unchanged. Generated summit height/range,
  predictor, rigid body, and open play bounds use that same curve; maximum-power
  rescue through a second velocity constant is forbidden.
- Airborne travel uses no paint. A verified Playable Terrain Surface first
  contact may create a radial impact mark, and consecutive real contacts on
  that surface create a continuous 3D surface sweep. A stationary ball does not repeatedly paint one
  point; resumed motion paints only its new physical path. Terrain embedding is
  recovered against the authoritative surface and physical radius, not treated
  as an ordinary deletion outcome.
- One 512×512 paint mask is the mutable visual and scoring source. One immutable
  512×512 `target_mask`, rasterized from the accepted shared terrain triangles,
  defines every configured scoreable Target Area texel through the target-shoulder
  boundary. After generation, slope, decorations, camera visibility, expected
  difficulty, and ballistic failure never cut holes in that footprint.
- During that target raster pass, every included sample must also remain inside
  the shared projectile-center yaw, damped horizontal-horizon, and lower/upper
  reachable-height envelope. One failure rejects the whole seed candidate; it
  never removes a target pixel. At least one canonical Summit Region sample
  must pass the same pure analytic gate. Bounded generated default and summit
  aims receive real first-hit checks; exhaustive per-target-texel certification
  is not a product or release requirement.
- Persistent paint is written only by verified Playable Terrain Surface sweeps and
  defined impact and Burst radial marks reconstructed on the exact
  rendered/collidable triangle. Visual paint and scored paint cannot diverge;
  paint outside the target mask remains visible but does not increase coverage.
- Target surface coverage is the unique painted physical Target Area area divided
  by its total physical area. Each target texel uses the canonical terrain
  triangle's projected area multiplied by `1 / abs(normal.y)`; overlap counts
  once. Camera and viewport state never affect score. Dry Target Area terrain is
  perceptibly but neutrally distinguished before firing, while `목표 영역`/`TARGET
  AREA` names the authoritative HUD/result percentage without a second mutable
  coverage representation. Painted non-target terrain remains visible in a
  lighter, less saturated blue and contributes zero.

### Mechanisms

- All mechanisms are terrain-conforming flat circular glyphs. A real Playable
  Terrain Surface contact inside the visible glyph footprint activates their data-driven effect;
  raised 3D obstacle bodies and hidden trigger volumes are not used.
- Burst applies one large authoritative paint effect, consumes the ball, and
  visibly enters a spent state.
- Splitter consumes the incoming ball and emits exactly three readable,
  fan-distributed useful branches.
- Uphill Rebound redirects the ball toward the locally highest meaningful
  terrain direction rather than acting as a merely punitive random bounce.
- Glyph icons, arrows, and state treatment distinguish Burst, Splitter, and
  Uphill Rebound without relying on color alone.
- No fourth mechanism is implemented in the vertical slice.

### Stages

- Generate one immutable variable-size height grid per stage from a
  deterministic route graph, canonical stage ID/version, the shared canonical
  terrain-family seed, and a complete typed progression profile. Stage 01 begins
  at `210 × 120 m` and `84 × 48` cells; Stage 30 ends at `280 × 160 m` and
  `96 × 64` cells, while nominal peak progression stays within `64..92 m`.
  Adjacent steps remain bounded by the typed progression formulas. The
  resulting Playable Terrain Surface has exactly one height per XZ and
  may form broad rollable slopes, terraces, ridges, valleys, and pads, never
  caves, overhangs, tunnels, stacked tops, detached pieces, or literal stairs.
- Emit the indexed top-triangle list once with one fixed diagonal. The render
  `ArrayMesh`, top `ConcavePolygonShape3D`, hit classification, height/normal
  queries, target rasterization, and paint reconstruction consume those exact
  vertices, triangles, and IDs. A `HeightMapShape3D`, bilinear query, independent
  triangulation, visual displacement, or query-only playable surface is not an
  acceptable substitute.
- The mountain is an independently closed, lit, physically collidable 3D mass
  with a perimeter Support Shell and bottom cap. The visible/collidable rear
  backstop and artificial side containment walls are absent and have no hidden
  replacements. A restrained collider-matched non-target apron may remain as
  open ground; explicit open play bounds and the never-contacted timeout end
  misses without wall banks.
- All thirty stages are selectable from first launch. Per-stage bounds, cells,
  nominal peak, macro undulation, decorations, targets, and seeds change
  gradually; routes, reversals, ridges, passes, basins, station counts, and
  mechanisms increase in staggered bounded steps rather than at one shared band
  boundary. Adjacent layouts must have unique checksums, a profile-score delta
  of `0.35..5.00`, and a normalized height RMS of `1.0..18.0 m`; Stages 04 and
  05 are explicit distinctness canaries.
- Small stages may have no glyph or one or two glyphs. Larger stages contain
  more glyph opportunities, using only Burst, Splitter, and Uphill Rebound.
- Glyphs use a deterministic generic search of visible Playable Terrain Surface and
  must pass footprint, spacing, slope presentation, visibility, and
  effect-usefulness checks. A failed placement rejects or changes the candidate
  through the generation contract; production resources contain no hand-authored
  X/Z repair fallback.
- Stage start and restart use one generated legal default aim whose real first
  hit reaches the Target Area near the target-mask centroid. Every accepted
  stage also carries a separate generated legal first hit on its global highest
  region of the Playable Terrain Surface. Neither witness is exposed as auto-aim.
- Each StageData includes identity and translation keys, generation profile/seed,
  cannon transform, camera bookmarks, target/shots/color, mechanism loadout,
  open play bounds, star thresholds, best data, and tutorial keys. The generated
  layout owns the route graph, height samples, fixed triangle identities,
  target mask, bounded default/summit witnesses, optional diagnostic certificate
  metadata, decorations, and resolved placements.
- Stage generation derives the fixed cannon transform and open play bounds so
  the nearest playable front stays at least 70 m away at every supported board
  size. The next promoted catalog records that placement contract; a camera-only
  scale adjustment is not an acceptable substitute.
- Stages do not require a prescribed successful route, solver clear, exhaustive
  target-wide first-hit proof, or all-stage manual playthrough. Generated route
  data shapes terrain and supports readability without defining a player
  solution. Open-bound admission, analytic range admission, bounded witnesses, and
  representative gameplay regressions remain required.
- Clear targets are `4.0..8.5%` through Stages 01-10, then use shot-tier
  plateaus: `8.5%` for 11-15, `9.0%` for 16-20, `9.5%` for 21-25, and `10.0%`
  for 26-30. Two- and three-star grades remain `+2.5/+5.0` points above clear.

### Results and persistence

- The first actual launch starts a wall-clock stage duration of 60, 90, or 120
  seconds for Stages 01-10, 11-20, or 21-30. The active simulation runs at a
  fixed two-times pace, but the real-time clock does not scale with it. Finish
  ends an active run after that first shot; timer expiry also ends it. Results
  use final unique target coverage as the sole score, with existing star
  thresholds as grades.
- Results show stage, final coverage, time outcome, shots used/remaining,
  previous best, new best, rank/stars, final mountain, retry, next, and stage
  select. They do not present target coverage or spent shots as an automatic
  clear/failure result.
- Save version, coverage-metric-separated best coverage/stars, unlocks, and
  settings including mouse sensitivity locally.
- The player-facing replay and its recording, playback, input-lock, speed, UI,
  localization, capture, and compatibility formats are absent. Independent shot
  and attempt observations remain available only to the agent/debug contracts.

### UI, art, audio, and debug

- Separate full-screen menu, stage-select, briefing, gameplay, coverage-result,
  pause, and settings interfaces; anchors/containers support common 16:9 desktop
  resolutions.
- Use a panel-free sparse gameplay instrument layout: stage and interaction at
  upper-left, a shallow icon/number status row at upper-right, a thin coverage
  gauge at left, yaw/elevation/power instruments at the lower edge, and Fire
  alone at bottom-center. Keep the mountain and high trajectory arcs clear.
  Show shots as remaining / maximum. Do not expose resident-ball activity or
  counts in the HUD. Attach compact S/W tokens to their actual elevation step buttons, a mouse-wheel glyph
  to power, and Space, Tab, F, and Escape tokens directly to their actions. Do
  not advertise A/D in terrain-target mode or draw literal square brackets.
  Normal play has no persistent prose instruction strip, aiming-state Restart,
  second Fire control, or direct R restart shortcut.
- During Shot Follow, show one compact focusable return-to-cannon action at the
  edge of the screen and hide controls that imply in-flight steering. Do not
  restore the old multi-preset observation strip.
- Gear and Escape open the same fully input-capturing paused game menu with
  Continue, Restart, Settings, Stage Select, and Main Menu. Continue/Escape
  restores the exact pre-pause state without advancing simulation. Settings is a
  separate child form above the still-paused menu; closing it returns focus to
  Settings in the menu, and the Settings form never contains Restart. Passive
  Settings synchronization and non-display changes never set window mode or
  size; fullscreen and resolution apply only from their explicit actions or a
  defaults restore.
- Mouse aiming uses unscaled `screen_relative` motion, retains fractional
  yaw/elevation remainder across canonical 0.1-degree updates, and applies a
  persisted mouse-only 50-150% sensitivity setting. Keyboard steps remain fixed.
- Use off-white panels, navy text, one saturated blue accent, rounded restrained
  controls, real icons, visible keyboard focus, and no aiming-state center modal
  other than the intentionally opened paused game menu.
- Bundle Pretendard, default fresh and migrated V1 saves to Korean, support immediate persistent Korean/English switching, and store translation keys rather than visible text in gameplay resources. Interactive controls remain at least 40 px high with visible keyboard focus and no clipped Korean at the three supported resolutions.
- Use low-poly faceted neutral terrain, sparse scale cues, bright glossy
  non-emissive blue paint, a dark stylized readable foreground cannon, and readable flat
  terrain glyphs with distinct icons and directional cues. Use soft daylight,
  one main directional light, lightweight effects, and a restrained cannon-side
  flag or streamer to support visible wind.
- Project eligible surface-glyph anchors into the canonical 48-degree, 16:9 Aim
  View and prefer vertical fraction 0.38..0.62 inside the projected Playable
  Terrain Surface silhouette; use 0.28..0.74 as the bounded second band before
  deterministic fallback. Within a band, preserve mechanism suitability and
  prefer a complete camera-facing assignment whose terrain-draped perimeter
  stays inside the Aim View safe frame.
- Provide the specified compact sound set, impact/muzzle/mechanism/result
  particles, and small non-continuous shake.
- Release-disabled debug overlay exposes state, FPS, projectile/velocity,
  coverage gains and masks, paint-command ordering, preview/collision,
  mechanisms, seed, reachability/open-bound identities, bounds, camera, and
  restart timing plus the specified debug actions. No payload metric remains.

### Performance and automation

- Target stable 60 FPS at 1920×1080 on modest Windows hardware, restart under one second, and load preferably under three seconds.
- Page navigation never performs a cold terrain reconstruction synchronously.
  AppRoot schedules one pure layout worker, keeps the initiating page responsive
  with a truthful preparing state, retains at most three accepted layouts for
  selected/current/next use, and materializes scene/render/physics state only on
  the main thread. Heavy preview artifacts retain at most one stage.
- Aim, map, and ordinary button input acknowledge without a main-thread stall.
  Fire admission reads only canonical aim and stage-rule state and never
  calculates or waits for prediction. One latest-only resumable prediction job
  advances by at most 12 fixed simulation steps and approximately 1 ms per
  physics tick; a newer nominated context replaces obsolete active work. Aim
  nominations are bounded. A stale preview remains visible but subdued while
  bounded scheduled work catches up, stale jobs never publish, and normal Aim
  View shows no calculation/update wait text.
- The cannon-standoff, flight-feel, and camera-flow change uses deterministic
  gameplay contracts and rendered review. It does not require a performance
  timing or profiling pass.
- Use one low-poly principal terrain mesh (preferably under ~50k triangles),
  batched mask updates, effect pooling, lightweight shadows, a 21-resident-ball
  hard cap, and one split generation.
- Provide a UI-independent in-process observation/action/event interface with
  stage/aim/terrain/mechanism/projectile/attempt data and set aim, Fire,
  Finish, restart, interaction-mode, and next-stage actions.

## Non-Goals

- Shops, currencies, monetization, customization, upgrades, gacha, dailies, ads, story/dialogue, inventory, multiple cannon/projectile collections, leaderboards, multiplayer, UGC, backend, online service, Docker, and live-service systems.
- Orthographic tabletop primary gameplay, fixed side-view gameplay, cannon
  position orbit or launch-station selection, direct projectile steering, paint
  or score on the Support Shell, full exterior-face coverage atlases, full fluid
  simulation, photorealism, caves, overhangs, or high-end rendering requirements.

## Acceptance Criteria

- The complete observable checklist is `test-checklist.md`.
- No feature is accepted from documentation, mockups, or scene structure alone; it must run in the project.
- The active implementation has passed its production-style verification,
  Windows release export, and running-game captures as
  listed in `test-checklist.md`; older screenshot sets remain historical
  evidence. This does not replace user-owned gameplay, balance, feel, or
  aesthetic QA.

## Historical Evidence and Current Implementation

The 2026-08-02 and earlier 2026-08-03 runs remain historical evidence for the
superseded implementation. They do not establish conformance with the current
contact, persistent-ball, timed-result, surface-glyph, retired replay, or
interaction-mode contracts above.

The 2026-08-05 gameplay-recovery plan is superseded history. The completed
`.agents/execplans/2026-08-06-ballistic-terrain-preparation.md` records the
generation-range and responsive-preparation change; this specification and the
source brief remain requirement authorities, while `.agents/Documentation.md`
remains the implemented-truth boundary.

The active catalog pointer is `resources/stages/catalog.tres`. It selects the
format-5 persisted thirty-stage bundle at
`resources/generated_stage_catalogs/v10-701b3b63feeee0dc1ce064cc91953fbdab91d90db1f004ef247dc4b8b22d1b4e`.
Each accepted layout carries default and summit witnesses. Runtime loads this
bundle through `StageLayoutRepository`; it asynchronously serves the selected
layout, may prefetch nearby work, retains three entries, and never substitutes
runtime generation or aim solving.

Glyph placement uses a generic deterministic search of visible Playable Terrain Surface
surface and spacing, not authored stage coordinates. The fast-entry,
Fire-capacity, and localized loading/retry implementations passed their prior
production checks. The Fire owner itself enforces the two-root cap; resident
terrain bodies do not hold that capacity. The retired wind implementation and
its cannon-side flag remain documented only in historical plans and evidence;
the current build has no ambient-force or wind-presentation contract.

The concept board under `docs/concepts/execplan-outcome-2026-08-03/` is useful
only for composition, palette, faceting, apparent thickness, and readability.
Its exact HUD placement, literal geometry, seed/silhouette, mechanism positions,
and painted still states are not runtime or acceptance authority.

The prior Windows release and screenshots remain historical evidence only. The
current format-5 implementation passed `scripts/verify.ps1`, exported
`builds/windows/PaintMountain.exe`, and produced eight reviewed 1280x720
background running-game captures with exit-0 runs and empty final stderr logs
under `.agents/evidence/fast-stage-entry-and-fire-capacity/`. Exported entry
readiness was `1035.5 ms` for Stage 01 and `2068.4 ms` for Stage 30. The render
review found no clipping, overlap, or gross terrain obstruction; Settings is
exactly 1280x720. Persisted default/summit witnesses and the analytic range gate
are the current stage-admission baseline; exhaustive target-wide certification
is not a release gap.
