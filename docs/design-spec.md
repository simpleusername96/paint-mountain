---
type: spec
status: active
created: 2026-08-02
last_reviewed: 2026-08-07
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
yaw/elevation/power, fires a rigid-body paintball, and watches gravity, wind,
real surface contact, rolling, and mechanisms produce coverage. Every valid
playable-top area physically traversed while in contact is painted; only its
overlap with the immutable target mask counts toward coverage. There is no paint
reservoir, depletion, or autonomous flow. The first actual launch starts the
stage timer; the player finishes the run or the timer ends it.

The vertical slice includes a main menu, stage select, briefing/inspection,
aiming, projectile observation, coverage result, pause, settings, saving, replay,
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
  an approximate composition target; shared physical topology, depth, terraces,
  valleys, and support faces remain mandatory.
- In the perspective `Aim View`, the cannon is a substantial lower-foreground
  anchor at roughly 20–30% of viewport height. The complete playable mountain is
  a smaller distant subject in the middle and upper frame, with its silhouette,
  summit headroom, muzzle, trajectory, and first-impact marker inside the safe
  view. Keep the authored 48-degree FOV unless runtime visual review proves the
  shared bookmark itself must change; do not solve the composition with
  per-stage camera repairs.
- Briefing begins in `Map View` with limited three-quarter orbit/zoom. `Aim View`
  uses one authored, recoverable cannon composition and the established aim
  controls; it does not add a second pointer gesture for independent camera
  navigation. Map View remains the deliberate whole-board inspection mode and
  never changes the stored aim.
- An accepted Fire action enters `Shot Follow`, which follows that newly launched
  root paintball rather than averaging every resident ball. It shows first
  terrain contact, holds the impact for 0.8 seconds, then returns to Aim View.
  The player may return early without changing the projectile or stored aim.
  Result uses a restrained three-quarter reveal.

### Controls and information

- Briefing starts in Map View: terrain click changes inspection focus, left-drag
  orbits, wheel zooms, Enter/Start enters Aim View, and Escape pauses.
- Gameplay has Aim View and Map View interaction modes while Board Phase remains
  `AIMING`. In Aim View, left-drag changes yaw/elevation, wheel or explicit `−/+`
  controls adjust power, A/D/W/S use the same aim path, and Space/Fire launch. In
  Map View, terrain click changes inspection focus, left-drag orbits,
  wheel zooms, and aim/Fire input is blocked. Tab and one visible focusable
  toggle switch modes without changing the stored aim or preview, and the switch
  never performs terrain-scale work in the input callback.
- Show target, current coverage, shots, angle, power, a dotted initial ballistic arc, and an approximate first impact. Never preview post-impact solution paths or exact coverage.
- Terrain clicks never solve or alter aim. The complete pre-impact preview uses
  the same radius, fixed-tick gravity, damping, launch origin, speed, shared
  collision geometry, and collision layers as the real ball. It ends at the
  first physical collision. Bounds exits and timeouts are non-fireable errors;
  no post-impact route is shown.
- Firing enters Shot Follow for the new root ball. A visible `대포로 돌아가기`
  / `RETURN TO CANNON` control and context-sensitive Tab return immediately to
  Aim View; the ball continues physically and no post-fire steering is added.
  Aim remains editable after the return while earlier balls move. There is no
  persistent Follow/Wide/Cannon preset rail, gameplay speed, or gameplay Pause
  strip.
- One deterministic stage-seeded wind changes on a readable 30-second rhythm
  with a natural three-second transition. The preview and physics use the same
  wind. A cannon-side flag or streamer is the primary world cue and points in
  the direction projectiles are pushed; motion amplitude communicates strength.
  The concise HUD cue remains a secondary numeric and transition reference.

### Stage state

- Authoritative Board Phases are `LOADING`, `BRIEFING`, `AIMING`, `PAUSED`,
  `FINISHING`, and `RESULT`. Active projectile families, resident balls, paint
  drain, and camera presentation mode are orthogonal typed activity, not
  competing stage phases.
- Two root-shot families may coexist. Fire alone disables at two-family capacity,
  invalid/pending prediction, no shots, terminal pending, or modal lock. Aim
  controls remain editable while prior families move.
- An initial Fire slot releases when its generation-0 root first authoritatively
  traverses valid playable top or terminates. Family observation waits until every current
  body has reached valid top or terminated; resident terrain balls may therefore
  remain physically active without permanently exhausting Fire capacity.
- Family coverage feedback is nonmodal. Reaching target coverage or spending all
  shots neither clears nor fails the run. After the first shot, Finish may end
  the run; otherwise the stage duration ends it. Final unique target coverage is
  the sole score and star thresholds remain grades.
- Restart removes projectiles, paint, particles, temporary mechanism state, timers, and camera transitions.
- The current catalog shares one canonical terrain-family seed. Stage and
  profile identity still make the thirty stages distinct, and each stage has
  one versioned persisted baked layout. Stage entry, retry, replay, and process
  restart reuse that exact layout; gameplay performs no terrain seed roll,
  candidate search, or reconstruction.
  The offline generator is authoring infrastructure only. Future randomness may
  be introduced only through separately baked and reviewed catalog variants.

### Projectile and paint

- Rigid bodies use gravity, CCD, low ordinary-terrain rebound, rolling/sliding
  friction, angular motion, damping, bounds, and fixed-timestep behavior. Once
  a ball has reached valid playable top, age, low speed, and engine sleeping do
  not delete it; it may sleep naturally and collision or strong wind may move it
  again. Explicit mechanism consumption, real escape, a never-contacted miss
  timeout, unrecoverable invalid geometry, and stage cleanup are the only
  pre-result termination families.
- Projectile data owns physical and paint tuning plus activation capacity. It
  owns no paint amount, payload, depletion rate, lifetime, slow-stop threshold,
  or flow budget. The ball must read materially larger than the old version,
  while its continuous paint mark remains a natural, visibly narrower midpoint
  than the old oversized mark.
- A representative default shot should feel close to three seconds before first
  terrain contact, but elapsed flight time is not a legal-shot gate or an exact
  per-stage contract. Physical standoff and launch tuning prevent both an
  immediate adjacent hit and a needlessly prolonged arc. A root that has never
  contacted playable top terminates at 6.0 seconds.
- Power `0..100` maps linearly to `32..160 m/s`. Generated summit height/range,
  predictor, rigid body, and containment use that same curve; maximum-power
  rescue through a second velocity constant is forbidden.
- Airborne travel uses no paint. A verified valid-top first contact may create a
  radial impact mark and consecutive real valid-top contact samples create a
  continuous 3D surface sweep. A stationary ball does not repeatedly paint one
  point; resumed motion paints only its new physical path. Terrain embedding is
  recovered against the authoritative surface and physical radius, not treated
  as an ordinary deletion outcome.
- One 512×512 paint mask is the mutable visual and scoring source. One immutable
  512×512 `target_mask`, rasterized from the accepted shared terrain triangles,
  defines every configured scoreable top texel through the target-shoulder
  boundary. After generation, slope, decorations, camera visibility, expected
  difficulty, and ballistic failure never cut holes in that footprint.
- During that target raster pass, every included sample must also remain inside
  the shared projectile-center yaw, damped horizontal-horizon, and lower/upper
  reachable-height envelope. One failure rejects the whole seed candidate; it
  never removes a target pixel. At least one canonical Summit Region sample
  must pass the same pure analytic gate. Bounded generated default and summit
  aims receive real first-hit checks; exhaustive per-target-texel certification
  is not a product or release requirement.
- Persistent paint is written only by verified playable-top surface sweeps and
  defined impact and Burst radial marks reconstructed on the exact
  rendered/collidable triangle. Visual paint and scored paint cannot diverge;
  paint outside the target mask remains visible but does not increase coverage.
- Coverage is target-mask texels at or above the paint threshold divided by all
  target-mask texels. Overlap counts once. Dry Target Area terrain is
  perceptibly but neutrally distinguished before firing, while `목표 영역`/`TARGET
  AREA` names the authoritative HUD/result percentage without a second coverage
  representation.

### Mechanisms

- All mechanisms are terrain-conforming flat circular glyphs. A real valid-top
  contact inside the visible glyph footprint activates their data-driven effect;
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

- Generate one accepted immutable variable-size height grid per stage from a
  deterministic route graph, canonical stage ID/version, fixed accepted seed,
  and complete typed progression profile. Stage 01 begins at `180 × 120 m` and
  `72 × 48` cells; Stage 30 ends at `240 × 160 m` and `96 × 64` cells, with
  bounded adjacent steps and the exact typed progression formulas. The
  resulting surface has exactly one playable top height per XZ and
  may form broad rollable slopes, terraces, ridges, valleys, and pads, never
  caves, overhangs, tunnels, stacked tops, detached pieces, or literal stairs.
- Emit the indexed top-triangle list once with one fixed diagonal. The render
  `ArrayMesh`, top `ConcavePolygonShape3D`, hit classification, height/normal
  queries, target rasterization, and paint reconstruction consume those exact
  vertices, triangles, and IDs. A `HeightMapShape3D`, bilinear query, independent
  triangulation, visual displacement, or query-only playable surface is not an
  acceptable substitute.
- The mountain is a closed, lit, physically collidable 3D mass with perimeter
  skirts and bottom cap. A visible bright off-white rear wall and a faceted,
  collider-matched non-target apron close the board so legal shots cannot pass
  through or over the playable scene.
- All thirty stages are selectable from first launch. Per-stage bounds, cells,
  nominal peak, macro undulation, decorations, targets, and seeds change
  gradually; routes, reversals, ridges, passes, basins, station counts, and
  mechanisms increase in staggered bounded steps rather than at one shared band
  boundary. Adjacent layouts must have unique checksums, a profile-score delta
  of `0.35..5.00`, and a normalized height RMS of `1.0..18.0 m`; Stages 04 and
  05 are explicit distinctness canaries.
- Small stages may have no glyph or one or two glyphs. Larger stages contain
  more glyph opportunities, using only Burst, Splitter, and Uphill Rebound.
- Glyphs use a deterministic generic search of visible playable-top surface and
  must pass footprint, spacing, slope presentation, visibility, and
  effect-usefulness checks. A failed placement rejects or changes the candidate
  through the generation contract; production resources contain no hand-authored
  X/Z repair fallback.
- Stage start and restart use one generated legal default aim whose real first
  hit reaches playable target top near the target-mask centroid. Every accepted
  stage also carries a separate generated legal first hit on its global highest
  playable top region. Neither witness is exposed as auto-aim.
- Each StageData includes identity and translation keys, generation profile/seed,
  cannon transform, camera bookmarks, target/shots/color, mechanism loadout,
  containment, star thresholds, best data, and tutorial keys. The generated
  layout owns the route graph, height samples, fixed triangle identities,
  target mask, bounded default/summit witnesses, optional diagnostic certificate
  metadata, decorations, and resolved placements.
- Stage generation derives the cannon transform and containment relationship so
  the nearest playable front stays at least 70 m away at every supported board
  size. The next promoted catalog records that placement contract; a camera-only
  scale adjustment is not an acceptable substitute.
- Stages do not require a prescribed successful route, solver clear, exhaustive
  target-wide first-hit proof, or all-stage manual playthrough. Generated route
  data shapes terrain and supports readability without defining a player
  solution. Containment, analytic range admission, bounded witnesses, and
  representative gameplay regressions remain required.

### Results, persistence, and replay

- The first actual launch starts the stage duration, which is 90, 120, or 180
  seconds according to progression. Finish ends an active run after that first
  shot; timer expiry also ends it. Results use final unique target coverage as
  the sole score, with existing star thresholds as grades.
- Results show stage, final coverage, time outcome, shots used/remaining,
  previous best, new best, rank/stars, final mountain, retry, next/select, and
  replay. They do not present target coverage or spent shots as an automatic
  clear/failure result.
- Save version, unlocks, best coverage/stars, and settings locally.
- Replay format 8 stores stage/profile/layout/certificate versions, accepted
  seed, terrain identities, generated default aim, wind schedule identity,
  fixed-tick aim/Fire/Finish actions, attempt outcome, and final paint-mask
  checksum. Replay presentation locks normal input and accepts only replay-origin
  actions; older incompatible formats are rejected deterministically.

### UI, art, audio, and debug

- Separate full-screen menu, stage-select, briefing, gameplay, coverage-result,
  pause, and settings interfaces; anchors/containers support common 16:9 desktop
  resolutions.
- Use the sparse edge-aligned HUD with stage and current interaction mode at
  upper-left, time, shots, resident-ball activity, wind, Finish, and a labeled
  gear at the edge, a vertical coverage gauge at left, angle/power at lower-left,
  and Fire alone at bottom-center. The wind cue shows the direction projectiles
  are pushed, strength, time to change, and approaching direction during the
  transition. Keep the top-center clear for the mountain and high trajectory
  arcs. No aiming-state Restart or second Fire control exists; `R` remains the
  quick-restart shortcut.
- During Shot Follow, show one compact focusable return-to-cannon action at the
  edge of the screen and hide controls that imply in-flight steering. Do not
  restore the old multi-preset observation strip.
- Gear and Escape open the same fully input-capturing paused game menu with
  Continue, Restart, Settings, Stage Select, and Main Menu. Continue/Escape
  restores the exact pre-pause state without advancing simulation. Settings is a
  separate child form above the still-paused menu; closing it returns focus to
  Settings in the menu, and the Settings form never contains Restart.
- Use off-white panels, navy text, one saturated blue accent, rounded restrained
  controls, real icons, visible keyboard focus, and no aiming-state center modal
  other than the intentionally opened paused game menu.
- Bundle Pretendard, default fresh and migrated V1 saves to Korean, support immediate persistent Korean/English switching, and store translation keys rather than visible text in gameplay resources. Interactive controls remain at least 40 px high with visible keyboard focus and no clipped Korean at the three supported resolutions.
- Use low-poly faceted neutral terrain, sparse scale cues, bright glossy
  non-emissive blue paint, a dark stylized readable foreground cannon, and readable flat
  terrain glyphs with distinct icons and directional cues. Use soft daylight,
  one main directional light, lightweight effects, and a restrained cannon-side
  flag or streamer to support visible wind.
- Provide the specified compact sound set, impact/muzzle/mechanism/result
  particles, and small non-continuous shake.
- Release-disabled debug overlay exposes state, FPS, projectile/velocity,
  coverage gains and masks, paint-command ordering, preview/collision,
  mechanisms, seed, reachability/containment identities, bounds, camera, and
  restart timing plus the specified debug actions. No payload metric remains.

### Performance and automation

- Target stable 60 FPS at 1920×1080 on modest Windows hardware, restart under one second, and load preferably under three seconds.
- Page navigation never performs a cold terrain reconstruction synchronously.
  AppRoot schedules one pure layout worker, keeps the initiating page responsive
  with a truthful preparing state, retains at most three accepted layouts for
  selected/current/next use, and materializes scene/render/physics state only on
  the main thread. Heavy preview artifacts retain at most one stage.
- Aim, map, and ordinary button input acknowledge without a main-thread stall.
  Fire admission reads a ready canonical prediction and never calculates a
  trajectory in the action callback. Wind presentation may update every fixed
  tick, but it does not automatically trigger a full collision prediction every
  tick. A stale preview becomes a truthful pending state while bounded scheduled
  work catches up.
- The cannon-standoff, flight-feel, and camera-flow change uses deterministic
  gameplay contracts and rendered review. It does not require a performance
  timing or profiling pass.
- Use one low-poly principal terrain mesh (preferably under ~50k triangles),
  batched mask updates, effect pooling, lightweight shadows, a 21-resident-ball
  hard cap, and one split generation.
- Provide a UI-independent in-process observation/action/event interface with
  stage/aim/terrain/wind/mechanism/projectile/attempt data and set aim, Fire,
  Finish, restart, interaction-mode, and next-stage actions.

## Non-Goals

- Shops, currencies, monetization, customization, upgrades, gacha, dailies, ads, story/dialogue, inventory, multiple cannon/projectile collections, leaderboards, multiplayer, UGC, backend, online service, Docker, and live-service systems.
- Orthographic tabletop primary gameplay, fixed side-view gameplay, direct projectile steering, full fluid simulation, photorealism, caves, overhangs, or high-end rendering requirements.

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
contact, persistent-ball, wind, timed-result, surface-glyph, replay-format-8, or
interaction-mode contracts above.

The 2026-08-05 gameplay-recovery plan is superseded history. The completed
`.agents/execplans/2026-08-06-ballistic-terrain-preparation.md` records the
generation-range and responsive-preparation change; this specification and the
source brief remain requirement authorities, while `.agents/Documentation.md`
remains the implemented-truth boundary.

The active catalog pointer is `resources/stages/catalog.tres`. It selects the
format-4 persisted thirty-stage bundle at
`resources/generated_stage_catalogs/v8-ac0a370baddb6355fe3a7a6715de563273817f727c124106d4580d2192cc3994`.
Each accepted layout carries default and summit witnesses. Runtime loads this
bundle through `StageLayoutRepository`; it asynchronously serves the selected
layout, may prefetch nearby work, retains three entries, and never substitutes
runtime generation or aim solving.

Glyph placement uses a generic deterministic search of visible playable-top
surface and spacing, not authored stage coordinates. The fast-entry,
Fire-capacity, and localized loading/retry implementations passed their prior
production checks. The Fire owner itself enforces the two-root cap; resident
terrain bodies do not hold that capacity. The currently implemented wind debris
is superseded presentation and remains only until the cannon-side flag work in
the active ExecPlan replaces it.

The concept board under `docs/concepts/execplan-outcome-2026-08-03/` is useful
only for composition, palette, faceting, apparent thickness, and readability.
Its exact HUD placement, literal geometry, seed/silhouette, mechanism positions,
and painted still states are not runtime or acceptance authority.

The prior Windows release and screenshots remain historical evidence only. The
current format-4 implementation passed `scripts/verify.ps1`, exported
`builds/windows/PaintMountain.exe`, and produced eight reviewed 1280x720
background running-game captures with exit-0 runs and empty final stderr logs
under `.agents/evidence/fast-stage-entry-and-fire-capacity/`. Exported entry
readiness was `1035.5 ms` for Stage 01 and `2068.4 ms` for Stage 30. The render
review found no clipping, overlap, or gross terrain obstruction; Settings is
exactly 1280x720. Persisted default/summit witnesses and the analytic range gate
are the current stage-admission baseline; exhaustive target-wide certification
is not a release gap.
