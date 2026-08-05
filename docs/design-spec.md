---
type: spec
status: active
created: 2026-08-02
last_reviewed: 2026-08-06
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

The player inspects a distant mountain, locks a stationary cannon's
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

- Cannon length is roughly 2–3 m; target distance 70–150 m; mountain width 120–250 m and height 60–140 m.
- In the perspective aiming view, the cannon stays in the lower foreground at no more than about 15–20% of the frame; the mountain dominates the middle and upper frame.
- Briefing begins in map inspection with a limited three-quarter orbit/zoom; Aim Lock restores the authored aiming camera; result uses a restrained three-quarter reveal.
- Map inspection must keep the whole mountain explorable without terrain clipping or rapid cuts. It does not follow projectiles or switch to preset camera views.

### Controls and information

- Briefing starts in Map Inspection: terrain click changes inspection focus, left-drag orbits, wheel zooms, Enter/Start enters Aim Lock, and Escape pauses.
- Gameplay has two interaction modes while Board Phase remains `AIMING`. In Aim Lock, left-drag changes yaw/elevation, wheel or explicit `−/+` controls adjust power, A/D/W/S use the same aim path, and Space/Fire launch. In Map Inspection, terrain click changes inspection focus, left-drag orbits, wheel zooms, and aim/Fire input is blocked. Tab and one visible focusable toggle switch modes without changing the stored aim or preview.
- Show target, current coverage, shots, angle, power, a dotted initial ballistic arc, and an approximate first impact. Never preview post-impact solution paths or exact coverage.
- Terrain clicks never solve or alter aim. The complete pre-impact preview uses
  the same radius, fixed-tick gravity, damping, launch origin, speed, shared
  collision geometry, and collision layers as the real ball. It ends at the
  first physical collision. Bounds exits and timeouts are non-fireable errors;
  no post-impact route is shown.
- Firing never hides or disables the next aim. Aim Lock restores the authored
  cannon view with a visible next-shot trajectory while prior balls move. There
  are no Follow, Wide, Cannon, gameplay speed, or gameplay Pause strips.
- One deterministic stage-seeded wind changes on a readable 30-second rhythm
  with a natural three-second transition. The preview and physics use the same
  wind; restrained leaves or debris supplement, but do not replace, the HUD cue.

### Stage state

- Authoritative Board Phases are `LOADING`, `BRIEFING`, `AIMING`, `PAUSED`,
  `FINISHING`, and `RESULT`. Active projectile families, resident balls, paint
  drain, and camera interaction mode are orthogonal typed activity, not
  competing stage phases.
- Two root-shot families may coexist. Fire alone disables at two-family capacity,
  invalid/pending prediction, no shots, terminal pending, or modal lock. Aim
  controls remain editable while prior families move.
- Family coverage feedback is nonmodal. Reaching target coverage or spending all
  shots neither clears nor fails the run. After the first shot, Finish may end
  the run; otherwise the stage duration ends it. Final unique target coverage is
  the sole score and star thresholds remain grades.
- Restart removes projectiles, paint, particles, temporary mechanism state, timers, and camera transitions.

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
  must pass the same pure analytic gate. Exact terrain occlusion and first-hit
  proof remain the separate certificate contract.
- Persistent paint is written only by verified playable-top surface sweeps and
  defined impact and Burst radial marks reconstructed on the exact
  rendered/collidable triangle. Visual paint and scored paint cannot diverge;
  paint outside the target mask remains visible but does not increase coverage.
- Coverage is target-mask texels at or above the paint threshold divided by all
  target-mask texels. Overlap counts once and the UI presents that authoritative
  percentage without a second coverage representation.

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
- Glyphs use deterministic valid-top route anchors and must pass footprint,
  separation, slope presentation, visibility, and effect-usefulness checks. A
  failed placement rejects or changes the candidate through the generation
  contract; production resources contain no hand-authored X/Z repair fallback.
- Every target-mask texel must have a certified legal manual aim whose first
  physical hit is the same target-top triangle. The certificate is fairness
  evidence and is never exposed as auto-aim. Stage start and restart use the
  certified witness whose impact is nearest the target-mask centroid.
- Every accepted stage also has a separately certified legal first physical hit
  on its global highest playable top region. This summit witness does not replace
  target-wide proof and is not used as the default aim.
- Each StageData includes identity and translation keys, generation profile/seed,
  cannon transform, camera bookmarks, target/shots/color, mechanism loadout,
  containment, star thresholds, best data, and tutorial keys. The generated
  layout owns the route graph, height samples, fixed triangle identities,
  target mask, reachability certificate, default aim, decorations, and resolved
  placements.
- Every accepted stage passes direct target-wide reachability, containment, and
  the deterministic reliable-solution search defined by the active specs; no
  manual terrain repair, hidden target deletion, or balance choice is deferred
  to implementation.

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
  non-emissive blue paint, a dark stylized small cannon, and readable flat
  terrain glyphs with distinct icons and directional cues. Use soft daylight,
  one main directional light, lightweight effects, and small moving leaves or
  debris to support visible wind.
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
- The wind-loop handoff uses the eight inspected exported-build captures listed
  in `test-checklist.md`; older screenshot sets remain historical evidence.

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

The wind-driven coverage loop is implemented across the active version-8
thirty-stage catalog. Its current manifest is
`1170c9db2002828a9f719f16ddc36b7b89ee9af17a24526586a2a2ee78317ca7`.
Stage 04 places Uphill Rebound on its natural route at `t = 0.30`; it does not
add an artificial support shelf.

The concept board under `docs/concepts/execplan-outcome-2026-08-03/` is useful
only for composition, palette, faceting, apparent thickness, and readability.
Its exact HUD placement, literal geometry, seed/silhouette, mechanism positions,
and painted still states are not runtime or acceptance authority.

The prior Windows release and screenshots remain historical evidence only. The
current production export passed. Eight representative exported-build
background captures are stored under `.agents/evidence/wind-driven-coverage-loop/`.
Per user direction, thirty-stage structural materialization plus representative
live/glyph checks replaces a full 30-stage live-generation sweep and an
exhaustive micro-tolerance matrix for this closeout.
