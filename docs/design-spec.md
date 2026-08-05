---
type: spec
status: active
created: 2026-08-02
last_reviewed: 2026-08-05
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
---

# Paint Mountain Design Specification

## Purpose

Define the compact working interpretation of the effective `source-brief.md`
for a polished thirty-stage 3D gravity-driven paintball puzzle game. Its dated
supersessions replace finite-payload/flow behavior, locked progression, serial
Fire, rejected paint scale, and the original aiming-HUD placement while
preserving manual launch planning, measured physical contacts, Korean-first
presentation, and the rest of the baseline directive.

## Scope

The player inspects a distant mountain, aims a stationary cannon by
yaw/elevation/power, fires a rigid-body paintball, and watches gravity, real
surface contact, rolling, and mechanisms produce coverage. Every scoreable
target-top area physically traversed while in contact is painted; there is no
paint reservoir, depletion, or autonomous flow. After all projectiles and paint
commands settle, the stage clears at its target or continues/fails according to
shots remaining.

The vertical slice includes a main menu, stage select, briefing/inspection,
aiming, projectile observation, clear/failure, pause, settings, saving, replay,
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
- Briefing uses limited three-quarter orbit/zoom; aiming uses roughly 45–55° FOV; observation supports follow, wide terrain, and cannon views; result uses a restrained three-quarter reveal.
- Transitions use smooth 0.3–0.7 second interpolation, avoid terrain clipping and rapid cuts, and widen when split children cannot be read together.

### Controls and information

- Briefing: left-drag orbit, wheel zoom, mechanism selection, Enter/Start to aim, Escape back.
- Aiming: drag empty 3D space to change yaw/elevation independently; wheel or explicit `−/+` controls adjust power; Space fires; R restarts; Escape pauses; Tab inspects. A/D change yaw and W/S change elevation through the same manual command path.
- Show target, current coverage, shots, angle, power, a dotted initial ballistic arc, and an approximate first impact. Never preview post-impact solution paths or exact coverage.
- Terrain clicks never solve or alter aim. The complete pre-impact preview uses
  the same radius, fixed-tick gravity, damping, launch origin, speed, shared
  collision geometry, and collision layers as the real ball. It ends at the
  first physical collision. Bounds exits and timeouts are non-fireable errors;
  no post-impact route is shown.
- Firing never hides or disables the next aim. The default camera remains on the
  cannon with a visible next-shot trajectory while prior balls move. Follow and
  wide observation are explicit modes; any new aim input returns to the cannon.

### Stage state

- Authoritative Board Phases are `LOADING`, `BRIEFING`, `AIMING`, `PAUSED`,
  `STAGE_CLEAR`, and `STAGE_FAILED`. Active projectile families, paint drain, and
  terminal pending are orthogonal typed activity, not input-blocking phases.
- Two root-shot families may coexist. Fire alone disables at two-family capacity,
  invalid/pending prediction, no shots, terminal pending, or modal lock. Aim
  controls remain editable while prior families move.
- Family coverage feedback is nonmodal. Clear/failure resolves only after every
  admitted family and authoritative paint command settles.
- Restart removes projectiles, paint, particles, temporary mechanism state, timers, and camera transitions.

### Projectile and paint

- Rigid bodies use gravity, CCD, low ordinary-terrain rebound, rolling/sliding
  friction, angular motion, damping, bounds/lifetime/slow-stop termination, and
  fixed-timestep behavior. A backstop hit stops immediately; Bumper is the only
  intentional strong-redirect exception.
- Projectile data owns radius, mass, bounce, friction, damping, lifetime, stop
  thresholds, contact footprint, impact/settle radii, and activation cap. It owns
  no paint amount, payload, depletion rate, or flow budget.
- The parent ball uses one `0.90 m` visible/collision/prediction radius. Continuous
  and settlement paint use `1.50 m`; first impact uses `2.10 m`. Splitter children
  scale both physical and paint radii uniformly by `0.78`.
- Power `0..100` maps linearly to `32..150 m/s`. Generated summit height/range,
  predictor, rigid body, and containment use that same curve; maximum-power
  rescue through a second velocity constant is forbidden.
- Airborne travel uses no paint. A verified target-top first contact may create a
  radial impact mark; consecutive real target-top contact samples create a
  continuous 3D surface sweep; final target-top settlement may create an
  idempotent radial mark. Short sampled gaps may bridge only after explicit
  same-surface and clearance checks; real airborne gaps remain blank.
- One 512×512 paint mask is the mutable visual and scoring source. One immutable
  512×512 `target_mask`, rasterized from the accepted shared terrain triangles,
  defines every scoreable top texel. It excludes only the non-target outer band,
  apron/shell/bottom, and physical mechanism footprints; slope, decorations,
  camera visibility, and expected difficulty never cut scoring holes.
- Persistent paint is written only by verified target-top surface sweeps and the
  defined impact, settle, and Burst radial marks reconstructed on the exact
  rendered/collidable triangle. Visual paint and scored paint cannot diverge.
- Coverage is target-mask texels at or above the paint threshold divided by all
  target-mask texels. Overlap counts once and the UI presents that authoritative
  percentage without a second coverage representation.

### Mechanisms

- All mechanisms share data-driven activation, state, cooldown/charges where applicable, feedback, and reset behavior. Their visible silhouettes have matching compound `StaticBody3D` collision; no gameplay `Area3D` trigger is used.
- Burst Node: physical hit, one charge, one terrain-aware authoritative radial
  mark, strong feedback, and a visibly spent state.
- Splitter Node: consumes the incoming ball and emits exactly three
  fan-distributed generation-one children. Children retain the fixed speed and
  smaller contact-footprint multipliers, not divided payload.
- Bumper Node: applies a visible directional impulse without consuming the ball and uses a cooldown to prevent repeated instability.
- Active Burst, Splitter, and Bumper read as amber, violet, and coral respectively
  and also differ by silhouette/icon/outlet/arrow cues. Their visible interactive
  mass matches named physical collision shapes; color is never the only cue.
- No fourth mechanism is implemented in the vertical slice.

### Stages

- Generate one accepted immutable variable-size height grid per stage from a
  deterministic route graph, canonical stage ID/version, fixed accepted seed,
  and complete typed progression profile. Stage 01 begins at `180 × 120 m` and
  `72 × 48` cells; Stage 30 ends at `240 × 160 m` and `96 × 64` cells, with
  bounded adjacent steps and the exact formulas in the active ExecPlan. The
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
- Stage 01 has no mechanism; Stage 02 introduces Burst; Stage 03 uses Splitter
  plus Bumper. Later stages grow to six visible, collider-matched mechanisms by
  Stage 25–30 without adding a fourth kind.
- Mechanisms sit at the exact owning-route centerline shelf transform and must pass slope, spacing, bounds, visibility, projected-size, tangent, and clearance checks. A failed fixed placement rejects the candidate; production resources contain no authored X/Z fallback or placement scoring alternative.
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
  the deterministic reliable-solution search defined in the active ExecPlan; no
  manual terrain repair, hidden target deletion, or balance choice is deferred
  to implementation.

### Results, persistence, and replay

- Clear uses coverage only; failure occurs after the last settled shot below target. Stars use stage data and remain understandable.
- Results show stage, final/target coverage, shots used/remaining, previous best, new best, rank/stars, final mountain, retry, next/select, and replay. Failure emphasizes missing coverage and Retry.
- Save version, unlocks, best coverage/stars, and settings locally.
- Replay format 7 stores stage/profile/layout/certificate versions, accepted seed plus height,
  target/reachability/containment checksums, the generated default aim,
  fixed-tick canonical manual actions, expected ordered contacts/effects, and the
  final paint-mask checksum. Replay presentation locks normal input and accepts
  only replay-origin actions; older formats are rejected because they cannot
  prove the version-7 generated layout and summit certificate.

### UI, art, audio, and debug

- Separate full-screen menu, stage-select, briefing, gameplay, clear, failure, pause, and settings interfaces; anchors/containers support common 16:9 desktop resolutions.
- Use the sparse edge-aligned HUD with stage and aim-mode at upper-left, shots
  plus a labeled gear at upper-right, a vertical coverage gauge at left,
  angle/power at lower-left, and Fire alone at bottom-center. The left gauge is
  the sole coverage display: it shows absolute coverage and the target while its
  rail fills bottom-to-top. Keep the top-center clear for the mountain and high
  trajectory arcs. No aiming-state Restart or second Fire control exists; `R`
  remains the quick-restart shortcut.
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
  non-emissive blue paint, a dark stylized small cannon, and readable mechanisms
  whose active amber/violet/coral colors and distinct silhouettes follow the
  mechanism contract above. Use soft daylight, one main directional light, and
  lightweight effects.
- Provide the specified compact sound set, impact/muzzle/mechanism/clear particles, and small non-continuous shake.
- Release-disabled debug overlay exposes state, FPS, projectile/velocity,
  coverage gains and masks, paint-command ordering, preview/collision,
  mechanisms, seed, reachability/containment identities, bounds, camera, and
  restart timing plus the specified debug actions. No payload metric remains.

### Performance and automation

- Target stable 60 FPS at 1920×1080 on modest Windows hardware, restart under one second, and load preferably under three seconds.
- Use one low-poly principal terrain mesh (preferably under ~50k triangles), batched mask updates, effect pooling, lightweight shadows, at most eight balls, and one split generation.
- Provide a UI-independent in-process observation/action/event interface with stage/aim/terrain/mechanism/previous-shot data and set aim/fire/restart/camera/next-stage actions.

## Non-Goals

- Shops, currencies, monetization, customization, upgrades, gacha, dailies, ads, story/dialogue, inventory, multiple cannon/projectile collections, leaderboards, multiplayer, UGC, backend, online service, Docker, and live-service systems.
- Orthographic tabletop primary gameplay, fixed side-view gameplay, direct projectile steering, full fluid simulation, photorealism, caves, overhangs, or high-end rendering requirements.

## Acceptance Criteria

- The complete observable checklist is `test-checklist.md`.
- No feature is accepted from documentation, mockups, or scene structure alone; it must run in the project.
- The final evidence includes seven separate full-resolution, debug-free screenshots with the exact required names.

## Historical Evidence and Active Reset

The 2026-08-02 and earlier 2026-08-03 runs remain historical evidence for the
superseded implementation. They do not establish conformance with the physical
contact, closed-terrain, manual-aim, mechanism-body, replay-format-7, or rebuilt-UI
contracts above.

The sole active implementation contract is
`.agents/execplans/2026-08-05-gameplay-contract-recovery.md`. It supersedes the
three contradictory 2026-08-05 physical/progression/interface plans where their
progress claims or contracts differ. `.agents/Documentation.md` remains the
implemented-truth boundary.

The concept board under `docs/concepts/execplan-outcome-2026-08-03/` is useful
only for composition, palette, faceting, apparent thickness, and readability.
Its exact HUD placement, literal geometry, seed/silhouette, mechanism positions,
and painted still states are not runtime or acceptance authority.

The prior Windows release and screenshots remain historical evidence only.
They must be replaced with fresh production-build evidence after all automated
gates pass and after the user explicitly approves a desktop-occupation window.
