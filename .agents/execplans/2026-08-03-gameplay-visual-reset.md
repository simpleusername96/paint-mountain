---
type: plan
status: superseded
created: 2026-08-03
last_reviewed: 2026-08-04
superseded_by: 2026-08-04-rapid-fire-progression-redesign.md
scope: implementation-first completion of the visible 3D mountain, physical paintball loop, mechanisms, three stages, Korean-first HUD, world presentation, and the user-authorized fire-to-flight responsiveness recovery
source: explicit user corrections through 2026-08-04, including rejection of the current running screen, later approval of bounded visual checks, and repeated reports of severe transition and projectile-flight stutter after the Phase 9 export
related:
  - ../PLANS.md
  - ../Documentation.md
  - ../../AGENTS.md
  - ../../docs/source-brief.md
  - ../../docs/design-spec.md
  - ../../docs/technical-architecture.md
  - ../../docs/test-checklist.md
  - ../../docs/concepts/execplan-outcome-2026-08-03/index.html
  - ../../docs/handoffs/gameplay-visual-reset-2026-08-03/README.md
  - 2026-08-03-core-interaction-redesign.md
---

# Paint Mountain Functional and Visual Completion - Execution Contract

This active revision replaces the validation-heavy execution body previously stored in
this file. Git history preserves that version. The active work now builds the
actual game and its visible presentation first. Existing test suites,
certification loops, repeated-process checks, replay matrices, performance
measurement, export evidence, and screenshots are not implementation tasks and
must not run until the user explicitly asks to begin testing.

The starting revision is ea9d28c on master. It contains useful contact,
continuous-paint, coverage, state, and restart foundations, but the user rejected
its running screen on 2026-08-04. The gray rectangular terrain mass, dominant
flat apron, tiny mechanisms, black cannon, and legacy HUD are not a visual MVP.

## Purpose

- Objective: implement the complete functional and visible game before spending
  more time on formal verification.
- Deliverable: three stages built around a bright, closed, visibly thick
  low-poly mountain object attached to a solid rear wall; a stationary cannon
  whose physical ball collides, rolls or slides, and paints every traversed
  target surface; readable Burst, Splitter, and Bumper objects; and the approved
  Korean-first HUD with left coverage, center Fire, and top-right shots plus
  settings.
- Implementation-ready state: every task in Phases 1 through 5 is implemented,
  production contains no competing legacy terrain or HUD path, and the mandatory
  headless launch smoke reaches the main scene.
- Testing state: implementation includes the bounded Phase 8 invalidation checks
  and non-obstructive real-render inspection. The user's 2026-08-04 running-build
  review rejected the Phase 9 result because Fire and projectile observation
  still stutter severely. That report authorizes only the bounded Phase 10
  fire-to-flight correction below. Broad regression matrices, balance, replay,
  stress, and tolerance work remain deferred.
- Final state: keep this plan active until the later user-authorized QA pass is
  added and completed. Implementation alone does not make the plan done.

## Scope and Boundaries

In scope:

- Replace the current rectangle-wide slab with an irregular, connected, closed
  3D mountain mass whose rear boundary joins the wall and whose body protrudes
  toward the cannon.
- Generate broad slopes, ridges, valleys, terraces, shelves, and progressively
  more rises and descents from Stage 1 through Stage 3.
- Keep one runtime surface topology as the source of visible geometry, physical
  collision, surface queries, target classification, and paint placement.
- Preserve and adapt the existing physical projectile, continuous contact paint,
  authoritative coverage, shot result, and restart owners.
- Make all three mechanisms large, color-distinct, physically collidable, and
  readable from the aiming camera.
- Recompose wall, mountain, apron, camera, lighting, cannon, trajectory, paint,
  and dressing around the supplied reference direction.
- Rebuild the HUD to the approved Korean-first layout and move Restart into the
  gear-owned paused game menu.
- Remove obsolete production paths and runtime certification gates after their
  replacements are connected.

Out of scope until the user explicitly requests testing:

- Every script under tests/ and scripts/test.ps1.
- Certifiers, exhaustive reachability, repeated-process checks, checksum
  matrices, solution searches, and candidate-seed sweeps.
- Updating obsolete tests solely to keep them passing after production APIs
  change.
- Replay, persistence, agent, localization-matrix, reliability, and broad stress
  validation. Phases 9 and 10 permit only the named transition, Fire, camera,
  and verified-contact responsiveness checks.
- Visible Godot/editor/game launches, screenshot capture, release export, and
  production evidence manifests.
- Treating an implemented checkbox as proof of user testing or approval.

Constraints and invariants:

- PaintSystem is the sole mutable paint and coverage authority.
- StageController is the sole stage-state, shot-progression, result, and restart
  authority.
- CannonController owns aim and launch calculation; TrajectoryPredictor owns the
  pre-impact prediction; ProjectileManager owns projectile lifecycle.
- UI displays state and emits typed intents only.
- Visible mountain and physical contact surfaces use the same generated
  triangles. No billboard, hidden duplicate collider, or visual-only playable
  mass is allowed.
- The rear wall is bright, visible, solid, non-paintable, and terminates the
  projectile without a bank shot.
- The projectile is never steered after launch and has no paint payload,
  depletion, shrinking footprint, or autonomous downhill flow.
- Korean is the default locale and English remains selectable.
- Use only already approved and committed assets. No new dependency, plugin,
  asset download, or runtime network access is authorized.
- Do not launch a visible Godot process.
- Existing tests are historical QA assets, not product authorities. Never retain
  bad production behavior merely because an old test expects it.
- Preserve one paint command per real contact interval and the fixed 60 Hz
  physics contract. Performance work may remove repeated computation,
  allocations, and diagnostic work; it may not skip contact ticks, decimate the
  visible trail, reduce mask resolution, or change physical shot semantics.

## Session-Derived Validation Removal

Prior sessions showed that validation repeatedly displaced visible work:

- target_mask_test ran eight times in about fourteen minutes;
- one Stage 1 generation command ran three times in about three minutes;
- one stale exhaustive reachability process consumed about fifty-five minutes;
- broad contact, paint, mechanism, state, replay, localization, reliability, and
  debug batches repeated before any running-screen approval;
- the final minutes repeated editor smoke, six isolated tests, permit
  verification, and verify while the rejected terrain and HUD remained.

Therefore:

- no test name appears in an implementation task or phase gate;
- no task acceptance depends on a test fixture;
- no repeated-process, performance, replay, export, or capture gate may interrupt
  Phases 1 through 5;
- only the repository-mandated headless launch smoke remains active;
- formal QA is dormant until a new explicit user instruction activates it.

## Locked Functional and Visual Contract

### Closed 3D mountain object

The current full-bounds y=f(x,z) rectangle is retired. The replacement is built
from an irregular connected footprint around the route graph:

- its rear boundary joins the wall;
- it extends toward the cannon with irregular front and side contours;
- its horizontal footprint is simply connected: contour noise may shape only
  the exterior and must never cut an internal hole, tunnel, or route-shaped
  void through the target;
- a broad mountain-body height floor spans the footprint beneath the route
  features, so valleys remain surface depressions and never read as an empty
  stage shell or a background-colored cutout;
- playable upper faces exist only inside the footprint;
- every exposed boundary closes into real front, side, rear-support, and bottom
  faces, producing one watertight volume;
- no straight full-width front skirt or flat foreground plane may pretend to be
  mountain depth;
- aiming composition shows upper faces, a front support face, and at least one
  lateral support face;
- camera motion changes overlap, visible side area, shadow, and highlight, so
  the target cannot read as a card.

RouteGraphMountainSynthesizer replaces RouteGraphHeightSynthesizer.
GeneratedStageLayout stores the footprint and accepted surface topology.
TerrainGeometryFactory derives render and collision from it. TerrainSurface
exposes read-only triangle queries. GameplayScene composes these owners but does
not create alternate terrain.

The generator constructs valid connected shapes directly. Runtime does not loop
over thirty-two candidates or require an exhaustive certificate before a stage
can appear.

### Stage progression

- Stage 1: one broad forgiving route, large landing regions, a simple overall
  descent, and limited ridge or valley variation.
- Stage 2: two routes, two to three meaningful rise/descent reversals, narrower
  shelves, and one readable Burst opportunity.
- Stage 3: three route choices, four to six rise/descent reversals, the narrowest
  usable shelves, and readable Splitter plus Bumper opportunities.
- Seeded variation may change facets, bends, ridge placement, and terrace
  proportions but may not disconnect the mass or remove a required route.
- Restart reuses the current generated layout.

### Runtime admission and default aim

Formal certificates are QA evidence, not runtime feature gates:

- remove StageMvpPermit and its stored resource/producer from production;
- keep DirectReachabilityCertificate only as optional dormant QA metadata;
- add one runtime-readiness predicate based on complete geometry, target data,
  containment, placements, and a valid default aim;
- make StageController and ReplayRecorder consume runtime readiness;
- select default aim using one bounded deterministic search for the best valid
  first collision near the visible target center;
- never run an all-target proof to choose the default shot.

### Ball and paint

- Yaw, elevation, and power remain independent.
- The trajectory ends at the first real collision with a depth-tested impact
  marker.
- Fire creates a real rigid body from the same launch calculation.
- Mountain contact has low rebound, followed by physical roll, slide, or settle.
- Every real target-contact interval paints the traveled surface continuously;
  airborne travel stays blank.
- One authoritative mask supplies both terrain paint and absolute coverage.
- Shot result waits for all projectiles and pending paint commands.
- Restart clears balls, paint, mechanisms, and transient state while retaining
  the generated layout and default aim.

### Mechanisms

- Burst: amber radial silhouette, real solid contact, one authoritative broad
  paint mark, and a visible spent state.
- Splitter: violet three-pronged silhouette, consumes the parent, and creates
  exactly three smaller independent painters.
- Bumper: coral body with a visible direction arrow and redirection aligned with
  that arrow.
- Each visible gameplay mass has matching collision. Any assisting trigger must
  remain inside the visible body envelope.
- Placement uses generated route shelves and clear aiming-camera sightlines.
- No fourth mechanism exists.

### World presentation

- wall: warm bright off-white;
- dry mountain: slightly darker warm off-white with flat-shaded facets;
- support faces: enough value separation to show thickness;
- paint: glossy saturated blue;
- mechanisms: amber, violet, and coral with shape cues;
- cannon: small dark-navy, white, and blue foreground object rather than a black
  silhouette;
- lighting: one readable key, restrained ambient fill, contact/self-shadow, and
  visible face-value changes;
- apron: subordinate and never a flat band occupying the lower half;
- mountain: dominant middle/upper mass with clear front-to-back route layers;
- trajectory: blue depth-tested dots ending at the real impact ring.

### Korean-first HUD

At 1280x720:

- stage card: 24,24,118,48;
- mode chip: 24,84,110,40;
- target card: 490,24,300,48;
- shots card: 1016,24,180,48 with a 48x48 gear at the top-right safe margin;
- vertical coverage gauge: 24,228,104,324, filling bottom-to-top and displaying
  absolute painted percentage plus target;
- aim and power: 144,592,300,104;
- sole Fire action: 552,624,176,72.

Restart is absent from aiming and Settings. Gear and Escape open the same paused
input barrier with Continue, Restart, Settings, Stage Select, and Main Menu.
Settings returns to that barrier. Pretendard is the project font; Korean is
default; English is switchable.

## Discovery Closure

| Concern | Current owner or behavior | Locked decision | Tasks |
| --- | --- | --- | --- |
| Terrain reads as slab/card | GeneratedStageLayout, RouteGraphHeightSynthesizer, TerrainGeometryFactory | Irregular closed footprint and real support volume | 1.1-1.4 |
| Certificates block iteration | StageMvpPermit, GeneratedStageLayout, StageController, ReplayRecorder | Remove permit from runtime; bounded center aim only | 1.1, 2.1 |
| Contact/paint foundations exist | PaintProjectile, ProjectileManager, PaintSystem, StageController | Preserve and adapt to the new mesh | 2.2-2.4 |
| Mechanisms are unreadable | placement generator and mechanism scenes/scripts | Solid semantic silhouettes placed by route role | 3.1-3.3 |
| World diverges from reference | gameplay scene, camera bookmarks, shader, cannon, trajectory | Recompose around the closed mass and locked palette | 1.4, 5.1-5.2 |
| HUD is rejected | scenes/ui/hud, HUDController, pause/settings | Locked left-gauge/center-Fire/top-right-gear hierarchy | 4.1-4.4 |
| Validation consumed feature time | session history and former plan body | No formal QA before explicit user authorization | all |
| Visible apps disrupt user | explicit user instruction | No visible launch during implementation | all |

Readiness statement:

- Geometry, behavior, UI, ownership, assets, ordering, and the deferred-test
  boundary are fixed.
- Existing approved assets and explicit Godot console path are available.
- A fresh executor can start Task 1.1 without researching another terrain
  algorithm, test strategy, UI layout, or asset pack.

## Implemented Baseline to Preserve, Not Re-Prove

Commit ea9d28c contains reusable foundations:

- typed projectile contacts and stable surface identities;
- low-rebound projectile tuning;
- continuous sweep and radial paint commands;
- one authoritative paint mask and coverage value;
- drain-before-result settlement;
- no payload, depletion, or downhill flow;
- restart plumbing;
- Korean/English translation infrastructure;
- approved assets and fastrun registration.

Do not rerun the tests that originally established these facts merely to regain
confidence. Change a foundation only when replacement geometry, UI, or visible
gameplay requires it.

## Tasks

### Phase 1: Replace the rejected terrain with one visible 3D object

Goal: First Descent has a closed mountain mass that protrudes from the wall and
does not read as a rectangular card, gray wall, or full-width slab.

Source owners: src/stage_generation/generated_stage_layout.gd,
src/stage_generation/route_graph_height_synthesizer.gd,
src/stage_generation/seeded_stage_generator.gd,
src/terrain/terrain_top_topology.gd,
src/terrain/terrain_geometry_factory.gd,
src/terrain/terrain_surface.gd,
src/terrain/backstop_environment.gd, scenes/gameplay/gameplay.tscn

- [x] **1.1 Remove certification-driven runtime admission.**
  - Change: remove StageMvpPermit and its resource/producer from production;
    make certificates optional; add structural runtime readiness; migrate
    StageController, GameplayScene, and ReplayRecorder.
  - Accept by inspection: no production load path requires a permit, certifier,
    all-target loop, or repeated candidate search.

- [x] **1.2 Generate the irregular mountain footprint.**
  - Change: replace RouteGraphHeightSynthesizer with
    RouteGraphMountainSynthesizer; generate one connected footprint and Stage 1
    route features; retire the rectangle-wide path after migration.
  - Accept by inspection: outside-footprint cells create no playable top faces;
    front and side contours are irregular; no whole-bounds top rectangle or
    straight full-width front skirt remains; every occupied depth row is one
    continuous span, adjacent spans overlap, no internal cell void exists, and
    non-route portions retain enough height to make the target read as one
    solid mountain body.

- [x] **1.3 Build one closed render/collision/paint mass.**
  - Change: emit upper triangles only inside the footprint, close every exposed
    boundary into support and bottom faces, and make render, collision, queries,
    target classification, and paint mapping consume this topology.
  - Accept by inspection: the mesh is watertight; top, front, and lateral support
    faces exist; no plane, duplicate collider, alternate formula, or visual-only
    playable shell remains.

- [x] **1.4 Recompose the Stage 1 world around the mass.**
  - Change: narrow/remove the dominant apron, join mountain and wall, apply
    off-white faceted materials and readable shadows, replace camera bookmarks,
    and keep the cannon small.
  - Accept by scene/resource inspection: no visible full-width ground band;
    wall, dry top, and support faces use distinct roles; aiming view is
    perspective and offset; mountain dominates the middle/upper composition.

Checkpoint: run only the mandatory headless launch smoke once after the coherent
Phase 1 migration. Run no test, certifier, export, or visible process.

### Phase 2: Connect the complete Stage 1 physical loop

Goal: cannon, ball, paint, coverage, result, and restart operate on the new mass.

Source owners: src/cannon, src/projectile, src/paint,
src/stage/stage_controller.gd, src/gameplay/gameplay_scene.gd

- [x] **2.1 Add bounded center aim and truthful trajectory.**
  - Change: derive default aim through a fixed-budget center-target search;
    preserve independent manual controls; draw the complete first-impact arc and
    depth-tested ring.
  - Accept by inspection: no authored fallback aim exists in StageData/HUD;
    search budget is finite; endpoint identity comes from collision; Fire
    acceptance remains in StageController.

- [x] **2.2 Adapt real contact, rebound, roll, and settlement.**
  - Change: preserve rigid-body measured contacts and low rebound while adapting
    identity/gap handling to the irregular surface. Wall hits retire without
    paint or bank shots.
  - Accept by inspection: contacts use collision facts and emitted face normals;
    no fake center-minus-up contact, guide force, or post-fire steering exists.

- [x] **2.3 Adapt continuous paint and coverage.**
  - Change: map paint commands onto every traversed mountain-top face, keep
    support/apron/wall unpaintable, use the eligible mask only for scoring, and
    bind the shader to the authoritative paint mask.
  - Accept by inspection: PaintSystem is the only mask writer; visible paint
    and coverage read the same paint bytes while eligibility only filters the
    coverage numerator; no payload, flow, or alternate paint owner exists.

- [x] **2.4 Preserve shot result and Restart.**
  - Change: reconnect aim, Fire, observation, drain, result, shots, clear/fail,
    and Restart after terrain migration.
  - Accept by inspection: StageController remains authority; result waits for
    projectiles and paint; Restart clears transient state and reuses the layout.

Checkpoint: run only the mandatory headless launch smoke once after Phase 2.
Run no physical, paint, state, replay, or reliability test.

### Phase 3: Make all stages and mechanisms visible gameplay content

Goal: all stages use the mountain-mass generator and mechanisms are readable,
collidable, and meaningfully placed.

Source owners: resources/stage_generation, resources/stages,
src/stage_generation, scenes/mechanisms, src/mechanisms

- [x] **3.1 Implement Stage 2 and Stage 3 mass profiles.**
  - Change: encode the locked routes, reversals, shelves, branches, and target
    surfaces through the same by-construction generator.
  - Accept by inspection: all stages use one generator; no permit/certificate
    blocks loading; Stage 1 is broadest and Stage 3 has the most route changes.

- [x] **3.2 Rebuild and place readable mechanism objects.**
  - Change: create solid amber/violet/coral silhouettes and place them on
    generated route shelves with clear aiming-camera sightlines.
  - Accept by inspection: visible meshes match solid collision; placement comes
    from route roles; Stage 2 has Burst and Stage 3 has Splitter plus Bumper.

- [x] **3.3 Connect mechanism effects to real contact.**
  - Change: keep amount-free Burst paint, exactly three Splitter children,
    Bumper redirection aligned with its arrow, the eight-ball cap, and reset.
  - Accept by inspection: only real contact invokes effects; authoritative
    projectile/paint owners remain; no invisible miss, recursive split, fourth
    mechanism, or alternate coverage writer exists.

- [x] **3.4 Add restrained dressing.**
  - Change: place approved trees, rocks, and effects outside route clearance and
    below gameplay-object prominence.
  - Accept by inspection: dressing has no ball-affecting collision, target,
    paint, or score ownership and does not hide routes/mechanisms.

Checkpoint: run only the mandatory headless launch smoke once after Phase 3.
Run no generation, placement, mechanism, solution, or performance test.

### Phase 4: Rebuild the Korean-first HUD

Goal: remove the rejected horizontal coverage and bottom-right Restart/Fire
layout and install the approved hierarchy.

Source owners: scenes/ui/hud, src/ui/hud_controller.gd,
scenes/ui/screens/pause_overlay.tscn, scenes/ui/screens/settings.tscn,
src/app/app_root.gd, translations/ui.csv, project.godot

- [x] **4.1 Replace the aiming HUD tree.**
  - Change: install left vertical CoverageGauge, sole bottom-center Fire,
    top-right shots plus gear, lower-left aim/power, and locked top cards.
  - Accept by scene inspection: one Fire node; no aiming Restart; vertical
    bottom-origin coverage; anchor/container roots; no competing legacy widgets.

- [x] **4.2 Move Restart into the paused gear menu.**
  - Change: gear/Escape open one paused input barrier with Continue, Restart,
    Settings, Stage Select, and Main Menu; Settings returns to it.
  - Accept by scene/signal inspection: Restart is absent from aiming/Settings;
    menu emits typed actions; full-viewport root captures input; Settings close
    returns to the menu.

- [x] **4.3 Finish Korean-first typography and copy.**
  - Change: Korean default, Pretendard shared Theme, concise translation keys,
    English switching, and removal of obsolete payload-era copy.
  - Accept by resource inspection: visible strings exist in both locales; Theme
    owns font; StageData stores keys rather than display text.

- [x] **4.4 Connect authoritative HUD values and actions.**
  - Change: display coverage/target, shots, aim, power, Fire validity, mechanism
    feedback, and sealed result from typed owners; share canonical Fire, gear,
    and Restart paths.
  - Accept by signal inspection: HUD never writes paint, calculates coverage,
    mutates stage state, or predicts post-impact behavior.

Checkpoint: run only the mandatory headless launch smoke once after Phase 4.
Run no UI, localization, input, replay, or navigation test and no visible window.

### Phase 5: Finish composition and remove obsolete production paths

Goal: one coherent production game remains, without the slab, legacy HUD,
certificate gate, or competing presentation path.

- [x] **5.1 Normalize materials, light, cannon, trajectory, and effects.**
  - Change: apply the locked palette, faceting, shadows, small readable cannon,
    depth-tested trajectory, and bounded paint/mechanism effects across stages.
  - Accept by inspection: no gray rejected terrain, black cannon silhouette,
    no-depth marker, flat-card material, or uncontrolled effect owner remains.

- [x] **5.2 Normalize cameras across all stages.**
  - Change: set aiming, briefing, observation, and result bookmarks that show
    mountain depth, routes, mechanisms, wall join, and a small cannon.
  - Accept by inspection: bookmarks are explicit; no camera hides missing
    geometry; mountain dominates and mechanisms stay in intended view.

- [x] **5.3 Delete retired production owners and resources.**
  - Change: remove old rectangular synthesizer, permit resource/producer,
    obsolete HUD, duplicate formulas, and stale scene nodes after replacements
    connect. Do not migrate obsolete tests.
  - Accept by inspection: one mountain generator/topology, one paint owner, one
    aiming HUD, one paused menu, and one runtime-readiness path remain.

- [x] **5.4 Prepare implementation handoff and stop.**
  - Change: update the active implementation record with completed work and an
    explicit list of untested behavior.
  - Accept: progress says implementation-ready and awaiting user authorization;
    no visual/gameplay/balance/performance/replay/export claim is presented as
    tested; this plan remains active.

Final implementation checkpoint: run only the mandatory headless launch smoke,
report implementation-ready state, and stop.

### Phase 6: Bounded MVP QA and headless delivery

Goal: prove only the contracts that can invalidate the accepted mountain-range
MVP, then rebuild the already-registered Windows executable without opening a
visible Godot process.

Preconditions:

- The user explicitly authorized continuation after the v5 terrain integration.
- Godot 4.7.1 console exists at the already approved local path.
- No visible screenshot or manual play session is authorized by this phase.

Source owners: `src/stage_generation`, `src/terrain`, `src/projectile`,
`src/paint`, `src/stage/stage_controller.gd`, `tests`, `export_presets.cfg`,
and the exact paint-mountain entry in the fastrun registry.

- [x] **6.1 Prove every stage builds the accepted mountain mass.**
  - Change: add one v5-focused headless check for all three persisted stages;
    assert row-solid footprint continuity, non-rectangular substantial mass,
    central-backbone height, valid canonical topology, closed render/collision
    geometry, and complete mechanism placement.
  - Accept: `mountain_range_mvp_test.gd` exits zero for all three stages.
  - Guard: do not migrate the old v4 candidate-search, fixed-face-count, or
    exhaustive slope/certificate assertions.
  - Evidence (2026-08-04): `mountain_range_mvp_test.gd` passed all three
    persisted stages. Active-cell/top-triangle/closed-shell results were
    2128/4256/412, 2186/4372/412, and 2404/4808/432; mechanism placement was
    0/0, 1/1, and 2/2. The check also caught and corrected sub-unit route-grade
    sign handling and moved the Stage 2 Burst pad onto its visible front ridge.

- [x] **6.2 Prove the real Stage 1 ball paints its traversed surface.**
  - Change: remove only the obsolete permit assertions from the focused Stage 1
    MVP check and bind admission to `GeneratedStageLayout.is_runtime_ready()`.
  - Accept: one headless default shot reports a real `terrain/top` contact,
    continuous target sweeps, positive authoritative coverage, no penetration,
    drain-before-result settlement, and deterministic Restart.
  - Evidence (2026-08-04): the default shot made a real terrain-top contact,
    remained in contact for 4.400 seconds, traversed 34.045 m through 264
    continuous sweeps, and produced 15.2824% scoreable coverage. Every sampled
    sweep-center texel was painted, the shot had zero penetration guards, paint
    drained before result sealing, and Restart restored the deterministic blank
    state. The terrain shader now displays valid paint outside the score mask
    instead of using that mask to erase physically traversed paint.

- [x] **6.3 Recheck repository startup after QA-owned changes.**
  - Accept: `scripts/verify.ps1` passes import/script parsing and main-scene
    startup through the approved Godot console.
  - Evidence (2026-08-04): `scripts/verify.ps1` passed the Godot 4.7.1 headless
    editor import/script parse and three-second main-scene startup with no
    reported script/runtime error.

- [x] **6.4 Rebuild and validate the canonical Windows start path.**
  - Change: export `Windows Desktop` to `builds/windows/PaintMountain.exe` with
    the existing preset; do not change the registered command when its exact
    directory entry remains `& '.\builds\windows\PaintMountain.exe'`.
  - Accept: the exported executable exists, a hidden headless startup exits
    without script/runtime errors, and the exact fastrun registry entry still
    resolves to it.
  - Evidence (2026-08-04): the release preset rebuilt the 132,482,824-byte
    `PaintMountain.exe`; a hidden `--headless --quit-after 3` launch exited zero
    without script/runtime errors. The exact fastrun entry remains
    `D:\npjt\paint-mountain<TAB>& '.\builds\windows\PaintMountain.exe'`.

Phase gate: record the four results once, update `Documentation.md`, and stop.
Visible composition remains a user-owned manual gate.

### Phase 7: User-QA visibility and responsiveness recovery

Goal: correct the three failures reported from the generation-v5 Windows build:
the mountain merges into the background, physically written paint is not
readable in motion, and mouse/camera movement stalls the game.

Verified starting point:

- The user ran the exported build and rejected its terrain visibility, paint
  feedback, and interaction performance. Phase 6 structural and mask evidence
  remains factual but did not prove rendered usability.
- The terrain is a closed shared mesh; no clipping or missing-mesh path was
  found. The mountain, wall, and horizon instead occupy nearly the same light
  value, while camera bookmarks clear only one focus ray rather than framing
  the generated mass.
- Every mouse aim event currently triggers up to 720 concave-shape casts and a
  96-node preview rebuild. During contact, every physics drain hashes all
  262,144 mask bytes in GDScript and every rendered frame uploads both full
  paint textures; the second texture is unused by the production shader.

Locked decisions:

- Keep generation v5 and the one shared terrain topology. Fix composition and
  update cadence; do not replace geometry with a visual duplicate.
- Frame Briefing, Wide, and Result from the generated render-mesh AABB at a
  1.08 margin. Preserve the authored view direction and keep Aiming anchored to
  the foreground cannon.
- Separate the dry mountain from the warm wall with a light cool-gray top,
  darker support value, lower ambient fill, and stronger daylight key. Paint
  remains saturated blue and does not depend on emission.
- Coalesce mouse drag to one canonical aim update per rendered frame. Coalesce
  trajectory prediction to 20 Hz, preserve the complete 60 Hz sphere-cast path
  to first collision, and synchronously refresh a dirty prediction before any
  Human, Replay, Agent, or Debug fire validation.
- Resolve camera safety at most 15 Hz while a target pose changes and reuse the
  result when settled; do not repeat the current two full correction passes on
  a static camera.
- Retain the authoritative 512-square paint mask. Publish its texture at 15 Hz,
  force the final dirty paint before result sealing, omit the unused recent-mask
  upload in release builds, and replace the per-drain GDScript FNV byte loop
  with Godot's deterministic native `hash(PackedByteArray)`. Historical format-4
  replay payloads are rejected by bumping the in-process replay format to 5.

Source owners: `src/camera`, `src/input/aim_input_controller.gd`,
`src/gameplay/gameplay_scene.gd`, `src/stage/stage_controller.gd`,
`src/terrain/terrain_surface.gd`, `src/paint`, `src/replay/replay_recorder.gd`,
`scenes/gameplay`, and focused Phase 7 checks under `tests`.

- [x] **7.1 Make the generated mountain the readable dominant mass.**
  - Change: add an AABB/FOV camera framer for Briefing, Wide, and Result;
    expose the terrain render bounds; separate mountain, support, apron, wall,
    sky, ambient, and key-light values without changing collision or topology.
  - Accept: a headless framing contract proves every generated terrain AABB
    corner fits inside the three framed camera frusta with the 1.08 margin, and
    source inspection proves the dry mountain and rear wall no longer share the
    same near-white value.
  - Guard: Aiming retains the cannon-relative bookmark and every stage still
    generates the same height, footprint, target, and placement checksums.

- [x] **7.2 Make physically traversed paint publish promptly without stalls.**
  - Change: use a 15 Hz coalesced production paint upload, skip unused recent
    uploads in release, force final upload before sealing, and use the native
    deterministic byte-array checksum with replay format 5. Phase 9 subsequently
    replaces that full-mask checksum with an incremental format-6 contract.
  - Accept: the real Stage 1 default shot still paints every sampled sweep
    centerline, the uploaded paint texture bytes match the authoritative mask
    after forced flush, coverage remains positive, and no paint command is
    rejected.
  - Guard: target classification affects scoring only; it cannot erase valid
    mountain-top paint in the shader.

- [x] **7.3 Remove per-event prediction and repeated static-camera work.**
  - Change: accumulate drag motion once per rendered frame, schedule dirty
    prediction at 20 Hz, synchronously flush it before every fire origin, and
    cache camera safety at 15 Hz until its desired pose changes.
  - Accept: a focused headless interaction check submits multiple aim changes
    in one refresh interval, observes one scheduled prediction, then proves an
    immediate fire uses the latest canonical aim and a fireable first-impact
    prediction. Static Aiming performs no repeated safety solve after settling.
  - Guard: predictor physics step, maximum duration, collision radius, and
    first-hit identity remain unchanged.

- [x] **7.4 Rebuild the user-run path.**
  - Accept: `scripts/verify.ps1`, the Phase 7 focused checks, release export,
    hidden exported startup, and the unchanged exact fastrun entry all pass.

Phase gate: update `Documentation.md`, commit the task-owned change, and stop
without a visible Godot process. The next acceptance evidence is the user's
manual run of the rebuilt fastrun executable.

### Phase 8: Running-screen composition recovery

Goal: replace the rejected 2026-08-04 aiming screen with a readable closed
mountain, cannon-to-target composition, and truthful aiming HUD, then verify the
result from the actual release renderer without obstructing the user's desktop.

Verified starting point:

- The user's 1264x709 capture from commit `787867f` shows a dominant dark front
  shell, a narrow jagged top rim, no readable cannon, an always-visible replay
  bar during ordinary aiming, and an apparently blank Settings button.
- The camera is not inside an open mesh. The front footprint stops at
  `depth_t = 0.93` while the height field reaches its outer falloff only at the
  full local bound; `TerrainGeometryFactory` therefore closes a still-high front
  edge vertically to local `y = -28`.
- Aiming bypasses `TerrainCameraFramer` and uses the low authored bookmark. The
  Phase 7 camera check covered Briefing, Wide, and Result, so it could not
  invalidate the rejected aiming composition.
- `ReplayBar` defaults visible and normal HUD state changes never hide it.
  `settings.png` is white on the shared light button surface.
- `DeliveryCaptureRunner` produces real viewport images but unconditionally
  forces fullscreen, so it cannot yet satisfy the user's non-obstructive direct
  inspection requirement.

Locked decisions:

- Preserve one closed render/collision/paint topology. Extend the connected
  footprint through the front local bound, apply a front-specific 80 m smooth
  height falloff, and use the full 24 m route-support band for the visible side
  contour so the playable route descends into the apron before the shell closes;
  do not hide the shell with culling, fog, color, or a visual duplicate.
- Align the apron top, the terrain's zero-height boundary, and the cannon base
  at world `y = -2`. The shell still closes to world `y = -30`, but that closure
  belongs below the collidable apron instead of standing 28 m above it in the
  play view. This repairs the world-space join rather than visually masking the
  shell.
- Keep Aiming on the authored close cannon-relative perspective and its existing
  terrain safety correction. Reauthor each aiming target above the generated
  foreground approach instead of inside the central peak, preventing focus
  snapping and overhead fallback. Do not fit the complete top AABB and cannon
  into one frustum: the first real Phase 8 capture proved that this flattens
  depth, shrinks the cannon to a dot, and makes the mountain read as a remote
  card.
- Hide ReplayBar in its scene default and HUD initialization, showing it only
  while `ReplayPresentationController.active` is true. Tint the existing
  approved Settings icon navy for every enabled button state.
- Add an explicit background capture option to `DeliveryCaptureRunner`. The
  release process remains a real windowed Compatibility-renderer run at
  1280x720, positioned outside the visible desktop before capture; headless or
  dummy-renderer images are invalid visual evidence.
- The implementing agent must inspect actual aiming and continuous-paint PNGs
  against the user capture and the registered primary comparator. If the
  mountain, cannon, trajectory, paint route, or HUD hierarchy remains
  unreadable, the task stays unchecked and composition is revised before
  export/handoff.
- Preserve the canonical mesh classification already carried in vertex color:
  paintable top triangles must remain within the bright off-white rock family
  even when their normals are steep, while non-paintable skirts and the bottom
  retain the darker support treatment. This is a material truth distinction,
  not a duplicate visual mesh or an attempt to conceal open geometry.
- Aiming may move moderately upward/backward from the rejected near-front pose
  when direct capture shows that the foreground transition hides the range.
  It must still read as a cannon-relative perspective and must not return to the
  failed whole-AABB framing distance.

Source owners: `src/stage_generation/route_graph_mountain_synthesizer.gd`,
`src/terrain`, `src/camera`, `resources/stages`, `scenes/ui/hud`,
`src/ui/hud_controller.gd`, `src/delivery/delivery_capture_runner.gd`,
`scenes/gameplay`, and focused Phase 8 contracts under `tests`.

- [x] **8.1 Replace the high front cut with a rollable foreground transition.**
  - Change: carry every deterministic footprint row through the front bound and
    multiply the generated route/range height by an 80 m front-specific smooth
    falloff before shell closure. Use the existing 24 m route-support band as the
    complete visible side contour instead of concentrating it into 12 m.
  - Accept: all three stages remain one row-solid connected closed mass; the
    front boundary top vertices meet the join elevation; front-facing topology
    no longer concentrates the full descent in the final cells; render and
    collision still derive from the same topology.
  - Guard: route height, target scoring identity, and side/rear support faces
    remain owned by the existing generator and geometry factory.

- [x] **8.2 Make Aiming show the cannon and playable mountain top together.**
  - Change: retain the authored close cannon-relative Aiming bookmark and use
    a stage-authored focus above the foreground approach; camera safety only
    prevents clipping after the foreground slope is fixed.
  - Accept: a focused composition contract places the cannon base, muzzle, and
    predicted first-impact point inside the final post-safety 1280x720 frustum
    for all three stages without backing away to fit the entire mountain AABB.
  - Guard: the final camera stays outside terrain and its focus ray does not
    cross an intervening terrain face.

- [x] **8.3 Restore truthful ordinary-aiming HUD state.**
  - Change: default and initialize ReplayBar hidden; show it only for active
    replay; apply readable navy Settings-icon state colors.
  - Accept: scene/controller inspection and the actual aiming capture show no
    replay controls, one centered Fire action, and a visible Settings glyph.

- [x] **8.4 Capture and inspect the real release renderer.**
  - Change: add the background capture argument, verify argument forwarding,
    export the Windows release, and capture `aiming` plus
    `projectile_and_continuous_paint` at 1280x720 from the actual executable
    positioned off-screen.
  - Accept: both PNGs are non-empty and the implementing agent directly confirms
    that a thick bright mountain dominates the play area, the cannon remains in
    the lower foreground while aiming, the trajectory terminates on a readable
    upper face, traversed surface paint is visibly blue in observation, no dark
    front slab or replay bar dominates the frame, and HUD elements do not clip
    or overlap.
  - Guard: no headless or dummy-renderer image may satisfy this task.

Phase gate: run `scripts/verify.ps1`, the two focused geometry/composition
contracts, `git diff --check`, the release export, and the two real background
runtime captures. Update `Documentation.md`, run `$codebase-quality-auditor`,
commit the task-owned change, and keep the plan active until the user's next
running-build review.

Iteration evidence (2026-08-04): the first real 1280x720 release capture removed
the false replay controls and restored the Settings glyph, but failed world
composition. The full-bounds Aiming framer made the cannon a dot and the last
few metres of height falloff still rendered as a dark front slab. Tasks 8.1 and
8.2 remain unchecked; the locked decisions above replace that failed approach.

The second real release capture carried the footprint to the front bound and
distributed the descent across the then-current 52 m value, superseded by the
final 80 m contract above. It proved that the remaining dominant dark
region is the canonical paintable top transition, not an unclosed hole: the
terrain shader shaded steep top triangles with the same minimum value as shell
triangles. The capture is still rejected because this erases the top/shell
distinction and the near-low Aiming pose lets that one transition occupy most of
the frame. Tasks 8.1, 8.2, and 8.4 therefore remain unchecked until the corrected
material classification and revised close-perspective capture are inspected.

The third real release capture used the corrected top/shell shader distinction
and a moderate cannon-relative pullback. It exposed a second coordinate defect:
the terrain boundary top is world `y = -2`, while the apron was joined to the
shell base at world `y = -30` and the cannon remained near `y = 0`. The lower
dark rectangle is the legitimately closed 28 m front skirt standing above the
floor, and the cannon is unsupported in world space. Phase 8 now aligns the
apron and cannon with the terrain boundary before judging final composition.

The fourth real release capture aligned the apron, terrain boundary, and cannon
base at world `y = -2`; the exposed front skirt is gone and the cannon is
supported. It remains rejected because the cool-gray apron reads too dark, the
then-current 52 m center route is still a broad featureless ramp, and the
superseded 95 m aiming pose makes the cannon too small. The next locked iteration
keeps a majority route height contribution while retaining the generated
mountain-range relief on the route, uses the approved pale neutral apron, and
restores a nearer
cannon-relative bookmark without returning to the original clipping pose.

The fifth real release capture restored valid relief height, generated every
stage, brightened the authored apron material, and used the nearer bookmark. The
large lower dark region remained unchanged, proving it is not the apron top. The
apron currently leaves a rectangular hole for the full 180 x 120 terrain bounds,
while the canonical mountain footprint is irregular inside that rectangle; the
shell is therefore exposed down to its base everywhere outside the footprint.
Production apron geometry must add collidable top cells for every inactive
footprint cell at the world join elevation. This covers only the subterranean
closure while preserving all real above-ground boundary cliffs.

Final Phase 8 implementation evidence (2026-08-04): the height builder now
honors the actual irregular footprint boundary instead of re-raising route and
pad edges from the global rectangle, and applies the captured 80 m front descent
with a 24 m contour taper. All three focused structural runs retain a
single row-solid closed render/collision topology. The authored 55-degree
cannon-relative views keep cannon base, muzzle, first impact, mountain, and high
arc in frame. The HUD has one left-side coverage owner, one bottom-center Fire
action, and no ordinary-aiming ReplayBar or top-center target card. Burst,
Splitter, and Bumper use 2x matching visible/collision scale.

The exported Windows executable produced and the implementing agent directly
inspected all four 1280x720 Compatibility-renderer captures under
`.agents/evidence/phase8/`. `aiming.png`, `aiming_burst.png`, and
`aiming_split.png` show closed faceted masses, staged ridge complexity,
foreground cannon, trajectory, impact, and readable mechanisms.
`projectile_and_continuous_paint.png` was gated on at least 72 applied surface
sweeps and 400 written pixels; it shows a long continuous downhill blue path and
the authoritative 6.7% left gauge while the projectile remains active. These
screens establish implementation evidence, not user acceptance. The plan stays
active for the user's running-build review and any later explicitly requested
broad QA.

The legacy `terrain_geometry_test.gd` asserted the superseded full-rectangle
mesh and exact vertex counts, so it and its broad-runner entry were retired.
`mountain_range_mvp_test.gd` and `phase8_front_transition_test.gd` now own the
material requirements: one closed irregular render/collision mass, connected
mountain-range footprint, and a rollable foreground transition.

The final direct-inspection iteration widened the real front/side transitions,
moved the lower-left aim panel away from the foreground cannon, brought all
three aiming bookmarks forward and laterally off-axis, reduced the impact mark
from 9 m to 6 m so the 4 m rolling trail remains legible, and added restrained
deterministic facet tones. The first camera candidate clipped the cannon, the
first facet-tone candidate produced a checkerboard surface, and a 120-sweep
capture gate outlived the active shot; all three were rejected from actual
running-game images before the final values above were accepted as implementation
evidence. The pale rear wall no longer receives the mountain's slab-like shadow.

The closing contract audit found that the enlarged mechanism scenes had retained
their pre-scale placement envelopes and that mechanism collision bodies exposed
no stable contact metadata. Placement now uses effective 2x collision/visual
bounds and the local typed pad as its support boundary. `GimmickBase` publishes
stable kind/shape IDs consumed by both trajectory prediction and rigid-body
contact. The focused physical mechanism run now completes with matching preview
and contact bodies/shapes, one Burst activation, three Splitter children, two
Bumper activations, and the eight-projectile cap.

### Phase 9: Transition and projectile-flight responsiveness recovery

Goal: remove the synchronous duplicate work that freezes navigation and the
per-contact allocation/upload spikes that make a real paintball visibly stutter,
without changing the accepted mountain, collision, paint, or shot contracts.

Authorization and measured starting point:

- The user explicitly reported severe lag on every page transition and extreme
  visible stutter after pressing Fire on 2026-08-04. This activates only the
  performance work in this phase.
- `AppRoot` currently rebuilds preview geometry, textures, material, and dressing
  when the same stage is shown again. Gameplay then regenerates the same layout
  instead of consuming the preview-owned immutable result.
- `GameplayScene._ready()` runs `DefaultAimSolver.find_runtime_aim()` before the
  scene becomes usable. Its 7 yaw x 7 elevation x 6 power grid executes 294 real
  trajectory predictions, each allowing up to 720 shape casts. The approved
  three-stage headless composition check took 17,116 ms before this phase.
- During sustained contact, `PaintSystem` hashes all 262,144 mask bytes after
  each non-empty physics drain and creates/rebinds a new 512 x 512 texture at
  15 Hz. A representative shot has more than 300 continuous sweeps.
- Debug builds allocate, clear, and upload a second recent-paint mask even while
  the F3 overlay is hidden. Physics interpolation is not enabled in
  `project.godot`, so a healthy 60 Hz rigid body can still step visibly between
  render frames.

Locked decisions:

- `AppRoot` owns an immutable per-stage presentation cache for the process
  lifetime. A cached `GeneratedStageLayout` is passed into gameplay before it
  enters the tree; gameplay validates its stage/seed/profile identity and only
  regenerates when no valid matching cache entry exists. Paint and stage state
  are never cached.
- The default aim remains a physically validated first hit near a real target
  center sample. Replace the 294-trajectory coarse grid with the existing
  deterministic one-target ballistic nomination path and real first-hit
  validation. Do not add authored fallback coordinates or expose solver tuples
  as player assistance.
- `PaintSystem` remains the sole 512 x 512 mutable authority. Replace recurring
  full-mask checksum scans with a deterministic incremental checksum updated on
  each changed byte, and keep one persistent `ImageTexture` updated in place.
  Preserve command order, every contact-tick sweep, overlap-by-maximum writes,
  target-only coverage, and final replay/observation checksum equality.
- Recent-paint diagnostics are allocated and updated only while the debug
  overlay is actually visible. They remain derived debug data and never affect
  paint, coverage, or replay authority.
- Enable Godot physics interpolation and retain the fixed 60 Hz physics tick.
  Do not hide workload by reducing contact cadence, mask size, terrain detail,
  or projectile count.
- All runtime checks remain headless or off-desktop/non-focusable. Never open a
  visible Godot window on the user's desktop.

Source owners: `src/app/app_root.gd`, `src/gameplay/gameplay_scene.gd`,
`src/stage_generation/default_aim_solver.gd`,
`src/stage_generation/generated_stage_layout.gd`, `src/paint/paint_system.gd`,
`src/debug/debug_overlay.gd`, and `project.godot`.

- [x] **9.1 Reuse immutable stage presentation work across navigation.**
  - Change: cache the accepted layout, preview mesh/material/textures, and
    dressing root by stage identity; make repeated selection of the active
    preview a no-op; inject the matching cached layout into gameplay before
    `_ready()`.
  - Accept: source inspection shows one preview artifact per stage/process,
    main-menu to stage-select does not rebuild the same stage, and gameplay uses
    the exact cached layout object while creating fresh paint/state owners.
  - Guard: a missing or identity-mismatched cache entry regenerates through
    `SeededStageGenerator`; no mutable attempt state survives navigation.

- [x] **9.2 Replace the transition-blocking default-aim grid.**
  - Change: resolve an actual target pixel nearest the target-mask centroid,
    nominate damped ballistic tuples with the existing bounded single-target
    solver, and return only a real predictor-confirmed first hit on that target
    sample.
  - Accept: the same three-stage headless composition check returns a valid
    fireable first impact for every stage; its separately reported default-aim
    component completes in no more than 250 ms per stage on the same
    engine/machine that recorded the 17,116 ms aggregate baseline. The test's
    structural-sequence generation time is reported separately because it
    intentionally evaluates multiple candidate seeds that runtime does not.
  - Guard: no stage-authored tuple, target deletion, collision bypass, or
    all-target certification loop enters runtime.

- [x] **9.3 Remove recurring paint hot-path scans and texture allocation.**
  - Change: maintain the authoritative checksum incrementally as bytes increase,
    update the existing paint texture in place at the current coalesced cadence,
    remove per-pixel result dictionaries from the write loop, and make recent
    diagnostics opt-in with the F3 overlay.
  - Accept: a focused deterministic paint check proves identical ordered drains,
    overlap idempotence, positive target coverage, persistent texture identity
    through forced flush, and a stable nonzero checksum. The off-desktop rendered
    capture, rather than unreliable headless GPU readback, proves publication.
  - Guard: 512 x 512 resolution, command cadence/order, continuous footprint,
    target scoring, and PaintSystem authority remain unchanged.

- [x] **9.4 Interpolate visible physics without changing simulation.**
  - Change: enable project physics interpolation so the rigid ball and physics-
    driven follow camera render smoothly between fixed ticks.
  - Accept: project import recognizes the setting, physics remains fixed at
    60 Hz, and the focused real-render flight probe records the projectile in
    flight with no repeated texture allocation path.
  - Guard: do not move projectile physics to `_process`, change time scale, or
    alter launch/contact tuning.

- [x] **9.5 Deliver one bounded non-obstructive responsiveness gate.**
  - Change: relabel the old headless Phase 8 performance check as CPU smoke only;
    use the established off-desktop Compatibility-renderer runner to collect
    transition and verified-contact flight frame deltas from the production-style
    build, partitioned by phase and paint-drain events.
  - Accept: `scripts/verify.ps1` passes; the exported hidden run reaches gameplay,
    applies continuous paint, and records p95/max plus counts over 16.7/33.3 ms
    for transition and flight. Actual paint remains visible in a captured frame.
  - Guard: no broad legacy suite, visible desktop window, dummy renderer, or
    claim that headless timing proves rendered smoothness.

Phase gate: record the before/after three-stage initialization time and the
off-desktop rendered frame telemetry once, inspect the captured paint frame,
update `Documentation.md`, run `$codebase-quality-auditor`, commit only the
task-owned change, and leave this plan active for the user's running-build review.

Phase 9 outcome on 2026-08-04:

- Repeated main-menu/stage-select calls measured 1.199 ms and 0.841 ms. Starting
  cached Stage 1 fell from 739.678 ms before the final surface-cache correction
  to 77.013 ms; aim-ready time fell from 1007.062 ms to 273.611 ms in the same
  off-desktop Compatibility-renderer runner.
- Default-aim derivation measured 103.13 ms, 129.93 ms, and 100.21 ms for the
  three stages. Structural-sequence generation remained separate at 1739.71 ms,
  2620.24 ms, and 3744.53 ms because that check intentionally tried 1, 2, and 30
  candidate seeds rather than the cached accepted runtime seed.
- The final hidden release probe recorded 195 flight frames. The Windows
  off-desktop window was throttled near 30 fps: non-drain frames averaged
  32.435 ms (p95 34.060 ms), while paint-drain frames averaged 36.301 ms
  (p95 39.738 ms, max 42.381 ms). This is comparative rendered evidence, not a
  foreground 60-fps claim.
- The same production build applied 121 surface sweeps, wrote 4,374 pixels in
  23 coalesced texture uploads, and the directly inspected capture shows the
  blue continuous path and 9.2% coverage without a forced texture replacement.
- Focused paint ordering, replay format-6/version rejection, Stage 1 physical
  paint, headless import/startup, and Windows release export passed. The
  quality audit's replay-version, shot-seal texture, and telemetry-partition
  findings were corrected before this outcome was recorded.

### Phase 10: Fire-to-flight main-thread and rendered-motion correction

Goal: remove the remaining launch hitch and continuous visual stepping reported
against the Phase 9 Windows export, while preserving fixed-tick projectile
physics, first-impact aiming, authoritative contact paint, camera safety, and
the accepted screen composition.

#### Root-agent diagnosis and evidence

This diagnosis was completed before delegation. The implementation executor may
not substitute another architecture or reopen the decisions below.

| Evidence inspected on 2026-08-04 | Established cause | Consequence |
| --- | --- | --- |
| `StageController.request_fire()` synchronously emits `fire_prediction_refresh_requested`; `GameplayScene` handles it by calling `TrajectoryPredictor.predict()`, whose loop permits 720 shape casts | A Fire request made in the same render interval as the latest mouse/power change performs collision prediction inside the button/Space call stack | The launch frame can block even though `CannonController` already invalidates Fire until a fresh prediction exists |
| `PaintProjectile.configure()` calls `GeneratedStageLayout.has_valid_target_mask()` and then the duplicating `target_mask` getter; `SurfaceContactGapValidator` names but never reads that mask | Every parent and split child scans and copies 262,144 bytes for data that does not participate in contact validity | Fire and Splitter spawn pay avoidable main-thread work with no gameplay effect |
| `AudioDirector.play_cue()` calls `_tone_stream()` for every cue and fills thousands of PCM samples in GDScript | Fire and first impact synthesize new sound resources synchronously | Discrete launch/impact hitches are added to the physics and scene work |
| `CameraDirector._physics_process()` both reads raw `projectile.global_position` and writes `Camera3D.global_position`; `_process()` only applies shake | Enabling project-wide physics interpolation did not make the manually driven camera consume rendered projectile transforms | On displays rendering above or out of phase with 60 Hz physics, the ball/camera relationship advances in visible steps even when CPU frame time is acceptable |
| Godot 4.7 advanced interpolation guidance states that a manual follow camera should move during rendered `_process()`, read its target with `Node3D.get_global_transform_interpolated()`, and disable automatic interpolation on that Camera3D | The Phase 9 camera implementation used the opposite boundary | The correction below follows the engine's documented camera case rather than adding smoothing constants blindly |
| `.agents/evidence/phase9/responsiveness.json` starts timing only after `request_fire()` returns and partitions frames only by paint-drain signal delivery | The previous probe excluded the launch call and could not detect physics-only camera stepping | Its 32.435 ms non-drain and 36.301 ms drain averages cannot validate the user-visible complaint |
| `PaintSystem` resolves new 512-mask surface samples inside paint drains, allocates result dictionaries, sorts a temporary 25-element snap list, and calls `Vector3.slerp()` for each sweep candidate | Verified contact frames retain avoidable script and allocation cost after Phase 9 | This is a secondary post-impact contributor; it must be reduced without restoring the former eager 512-square scene-entry walk |
| `C:\Users\BK\.config\fastrun\commands.tsv` points this repository to `& '.\builds\windows\PaintMountain.exe'`; the executable was rebuilt after the Phase 9 sources | The user reviewed the intended production path, not a known stale development command | The fix must replace that same executable; changing fastrun is not part of this phase |

Primary official references:

- `https://docs.godotengine.org/en/4.7/tutorials/physics/interpolation/advanced_physics_interpolation.html`
- `https://docs.godotengine.org/en/4.7/classes/class_node3d.html#class-node3d-method-get-global-transform-interpolated`

#### Locked implementation decisions

- Fire never performs trajectory prediction. Aim changes continue to clear the
  cannon's prediction and disable Fire. `GameplayScene._process()` computes the
  latest prediction at its existing bounded cadence; a Fire action arriving
  before that result exists is rejected without consuming a shot. Remove the
  synchronous refresh signal and handler rather than moving the same work to a
  different Fire callback. Human, replay, and agent callers use the same
  readiness rule.
- Remove `_target_mask` from `PaintProjectile` and remove the unused eligible-
  mask parameters from `SurfaceContactGapValidator`. Contact validity continues
  to use stable terrain-top identity plus the canonical topology query. Do not
  weaken `GeneratedStageLayout` or `PaintSystem` target-mask validation; the
  mask remains the immutable scoring input and the runtime coverage authority's
  configured copy, just not projectile state.
- Generate the six procedural cue streams once in `AudioDirector._ready()` and
  reuse them through the existing six-player pool. Store cue volume beside or
  in one narrow cue definition map. Do not add audio files, dependencies, buses,
  or change cue frequencies, durations, envelopes, or volumes.
- Keep fixed 60 Hz projectile physics in physics callbacks. `CameraDirector`'s
  physics callback computes the physics follow pose and the existing 15 Hz
  collision-safe correction only; it never writes the Camera3D transform.
  Record the desired position/focus used by each safety solve. Its rendered
  callback computes the current follow pose from every live projectile's
  `get_global_transform_interpolated().origin`, applies the last solved safety
  position/focus offsets, smooths with rendered `delta`, aims the camera, and
  then applies shake. Static modes use the current safe pose. Set the managed
  Camera3D's `physics_interpolation_mode` to OFF so engine interpolation does not
  compete with this manual rendered camera. Immediate bookmarks still snap and
  reset camera velocity exactly once.
- Do not precompute the entire 512-square paint surface, start a worker thread,
  lower mask resolution, reduce contact cadence, or skip paint commands. Keep
  lazy exact-topology samples, but precompute the 512 column/row mappings from
  mask coordinates to topology cell coordinate/local fraction/world XZ once in
  `PaintSystem.configure()`. At the same boundary, iterate only the accepted
  `64 x 48` topology cells and cache each cell's two canonical triangle vertex
  triples and normals; individual 512-square mask samples remain lazy and must
  interpolate exclusively from those canonical cached triangle values.
  Internally return raster counts as `Vector2i`, pick the nearest 5x5 snap
  candidate in one deterministic scalar pass instead of allocating and sorting,
  and use normalized linear interpolation for sweep normals. The latter is valid
  within the existing 30-degree contact-normal bridge bound and preserves the
  same 75-degree facing threshold.
- Add delivery-only measurements, not a general profiler: immediate dirty-aim
  Fire rejection duration, ready Fire duration, rendered projectile/camera pose
  changes, nonempty paint-drain duration, new surface-sample count, and the
  existing frame partitions. Production owners may expose read-only counters
  needed by this runner; they must not log every frame or change rules.
- UI scope is Level 2 under `$uiux-gate`: no layout, label, control, theme, or
  camera-bookmark redesign. The existing invalid-prediction disabled Fire state
  is the only user-visible control state used while prediction catches up.
- No visible Godot/editor/game process may open. All engine checks use headless
  import/startup or the established 1280x720 off-desktop, no-focus Windows
  Compatibility-renderer path. No broad test suite is authorized.

#### Delegated implementation contract

The root agent owns this diagnosis, the decisions above, acceptance, final
review, and commit. One Luna Max executor implements the checked tasks below
literally, does not spawn another agent, does not modify this phase's decisions,
and stops with evidence if current code makes a locked decision impossible.

- [x] **10.1 Make Fire a constant-work state transition.**
  - Owners: `src/stage/stage_controller.gd`,
    `src/gameplay/gameplay_scene.gd`, `src/projectile/paint_projectile.gd`,
    `src/projectile/surface_contact_gap_validator.gd`, and
    `src/stage_generation/direct_reachability_validator.gd` only where its
    direct projectile construction must follow the production signature.
  - Change: remove Fire-time prediction refresh, remove projectile target-mask
    acquisition/storage, and update narrow call sites. Preserve shot admission,
    launch tuple, contact identity, Splitter limits, and all stage-state owners.
  - Accept: after one aim change, an immediate direct Fire attempt returns false
    in at most 2.0 ms without consuming a shot or spawning a projectile; after
    the next valid rendered prediction, ready Fire succeeds in at most 8.0 ms
    in the hidden release probe.
  - Guard: no prediction approximation, stale-prediction launch, background
    physics query, authored aim, test-only bypass, or second Fire path.

- [x] **10.2 Remove cue synthesis from event hot paths.**
  - Owner: `src/audio/audio_director.gd`.
  - Change: build and retain exactly `ui`, `fire`, `impact`, `mechanism`, `clear`,
    and `fail` streams during audio initialization; `play_cue()` only selects a
    cached stream/player and volume.
  - Accept: source inspection finds no `_tone_stream()` call reachable from
    `play_cue()` and the off-desktop release run reaches Fire and impact without
    an audio error.
  - Guard: headless audio remains disabled; music, buses, pool size, waveform
    parameters, and saved volume behavior are unchanged.

- [x] **10.3 Move the follow camera to rendered interpolation.**
  - Owner: `src/camera/camera_director.gd`.
  - Change: implement the locked physics-safe/rendered-pose split, including
    stored safety-source pose and manual Camera3D interpolation mode.
  - Accept: source inspection finds no camera transform write in
    `_physics_process()` and does find rendered projectile transforms in
    `_process()`. During the hidden default shot, at least 95% of rendered
    frames in which the interpolated projectile moves also change the follow
    camera pose, and no unchanged camera-pose run exceeds one rendered frame
    while the projectile is moving and FOLLOW remains active.
  - Guard: retain bookmarks, FOV, follow/wide latch, 15 Hz safety solve, terrain
    clearance, occlusion fallback, shake limits, and player camera choices.

- [ ] **10.4 Reduce verified-contact paint drain cost without changing paint authority.**
  - Owner: `src/paint/paint_system.gd`.
  - Change: add the locked axis mapping and accepted-topology-cell triangle
    tables, allocation-free internal counts and snap selection, bounded normal
    interpolation, and read-only drain/cache-miss counters. The cell table is
    only `cell_count.x * cell_count.y * 2` triangles and is populated from
    `TerrainTopTopology` once during configure; it is not a second topology or
    an eager mask-sample cache. Keep command sorting, candidate connectivity,
    overlap-by-maximum, authoritative byte writes, incremental checksum, and
    coalesced texture publication.
  - Accept: the hidden release probe observes at least 120 continuous sweeps,
    positive written and newly painted pixels, an active projectile, and texture
    publication. Nonempty drain duration is at most 4.0 ms p95 and 8.0 ms max;
    rendered paint-drain p95 exceeds non-drain p95 by no more than 4.0 ms.
  - Guard: no eager full-mask sample walk, thread, GPU-compute dependency,
    reduced 512 resolution, dropped tick, widened target, or second visual mask.

  Root-owned gate refinement recorded before its post-change probe: the first
  uncontended canonical run after the initial 10.4 implementation measured
  nonempty drain p95 `3.030 ms` but one `8.462 ms` maximum, exceeding the locked
  `8.0 ms` maximum by `0.462 ms`. This triggers only the small accepted-cell
  triangle table named above. After that one correction, rerun verify/export and
  the canonical hidden probe once. If the internal p95 or maximum still fails,
  stop Phase 10 with the evidence; do not add another optimization or change a
  threshold without another root-authored plan revision.

- [ ] **10.5 Produce one bounded production-style proof and replace the registered build.**
  - Owners: `src/delivery/delivery_capture_runner.gd`,
    `.agents/evidence/phase10/`, `.agents/Documentation.md`, and the existing
    Windows export output.
  - Change: extend the established responsiveness runner with Phase 10 fields,
    capture one airborne FOLLOW frame and one verified continuous-paint frame at
    1280x720 off-desktop/no-focus, run `scripts/verify.ps1`, export release to
    `builds/windows/PaintMountain.exe`, run the hidden release probe once, and
    inspect both actual images.
  - Accept: all thresholds in 10.1, 10.3, and 10.4 pass; both images are nonempty
    actual Compatibility-renderer output and show the projectile/terrain chain
    without UI overlap; the executable timestamp postdates every production
    source changed in this phase; the existing fastrun registry entry remains
    byte-for-byte unchanged.
  - Guard: do not run `scripts/test.ps1`, legacy/focused suites unrelated to
    these reported failures, a visible desktop process, or claim the hidden
    timing is the user's foreground acceptance.

Executor outcome on 2026-08-04:

- Tasks 10.1 through 10.3 are implemented and meet their source and hidden-
  release gates. Dirty Fire measured `0.002 ms`, ready Fire `1.255 ms`, and the
  rendered FOLLOW camera changed on `195/195` moving-projectile frames with no
  unchanged run.
- Task 10.4's implementation is present and its direct drain budget passes at
  `1.922 ms` p95 and `6.357 ms` maximum while retaining 121 continuous sweeps,
  3,949 writes, 1,049 newly painted pixels, 21 texture publications, and an
  active projectile. Its checkbox remains open because rendered drain p95
  `38.723 ms` minus non-drain p95 `34.266 ms` is `4.457 ms`, exceeding the locked
  `4.0 ms` gate by `0.457 ms` in the off-desktop window.
- Task 10.5's smoke, export, two 1280x720 captures, direct image inspection,
  artifact timestamp, and unchanged-fastrun checks are complete. Its checkbox
  remains open because it requires every 10.4 threshold to pass. Evidence is
  stored under `.agents/evidence/phase10/`; no threshold was relaxed and no
  foreground acceptance is claimed.

Root review on 2026-08-04:

- Source review found no task-scoped production contract blocker. Fire no
  longer predicts in its call stack, every production gap-validator caller uses
  the reduced signature, the camera has one rendered transform writer, cue
  playback selects cached streams, and paint retains one mask, deterministic
  ordering, incremental checksum, and persistent texture ownership.
- The direct causal gates for the reported launch hitch pass, while the raw
  off-desktop frame comparison remains `0.457 ms` above its locked limit. The
  hidden window runs near 30 fps and groups roughly two 60 Hz drains into each
  draining render frame. This explains why the comparative result is retained
  as an unresolved delivery warning rather than used to authorize another
  speculative production rewrite.
- The Phase 10 executable is ready for the user's separate foreground check.
  Tasks 10.4 and 10.5 remain unchecked until that check or stronger causal
  evidence resolves the rendered-frame gate; the threshold is not redefined
  after measurement.

Phase gate: after the executor finishes, the root agent reviews every task-owned
diff, opens both rendered captures, runs `$codebase-quality-auditor`, corrects
only task-scoped blockers, performs the final hidden smoke/probe if needed, and
commits the plan, production changes, evidence, and documentation as one scoped
commit. The user performs the separate foreground acceptance through the
unchanged fastrun command.

## Mandatory Launch Smoke Only

Repository policy requires launchability after coherent production changes.
The only automated runtime command allowed during Phases 1 through 5 is
scripts/verify.ps1 with the approved Godot console path. It performs:

- headless editor import and script parsing;
- a three-second headless main-scene startup.

It does not prove gameplay, physics, visuals, balance, replay, performance, or
release quality and must never be reported as such.

Cadence:

- run once after each coherent phase checkpoint that changes production scripts,
  scenes, resources, shaders, or settings;
- do not rerun until another coherent production input changes;
- fix only current-phase import/startup defects when it fails;
- do not launch a focused test unless the user opens the testing stage;
- document-only changes use git diff --check and do not run Godot.

## Remaining Deferred QA Backlog - Inactive

This work has no active checkboxes and may not start automatically:

- scripts/test.ps1 and all focused checks except the Phase 6 and Phase 7 checks;
- containment, UI, localization, replay, persistence, agent, debug, reliability,
  and broad mechanism/state suites;
- exhaustive reachability and certificate generation;
- predictor/rigid-body tolerance and repeated-process determinism;
- solution search and target/shot balance confirmation;
- load, memory, and broad stress measurement beyond the bounded Phase 10
  Fire/follow/paint telemetry;
- migration/deletion of obsolete test fixtures and runner registrations;
- broad resolution/locale QA, screenshot matrices, manifests, and reference
  comparison beyond the two Phase 8 runtime captures;
- final release documentation and plan closure.

When the user authorizes testing, revise this plan with a bounded QA phase based
on the completed production behavior. Do not revive every historical test by
default; select only checks capable of invalidating a real function, visible
behavior, or release claim.

## Predetermined Contingencies

| Trigger | Required response | Boundary |
| --- | --- | --- |
| Replacement still uses a full rectangular slab | Correct footprint/support construction | Do not hide it with camera, fog, color, or UI |
| Closed data still lacks visible depth by construction | Increase real footprint depth, contour variation, and support exposure | No billboard, fake-depth texture, or non-collidable duplicate |
| Existing architecture conflicts with irregular footprint | Rewrite the owning production boundary and retire it | Do not preserve it for stale tests |
| A test becomes stale | Leave it for deferred QA | Do not spend implementation time migrating it |
| A stage lacks a certificate | Continue when structural runtime data and bounded default aim exist | Certificate is not a runtime gate |
| Mandatory launch smoke fails | Fix only responsible import/startup defect | Do not begin broad suites |
| A visual/UI task lacks an actual runtime capture | Keep the task incomplete and use the background release capture path | Headless evidence cannot replace rendered inspection |
| New asset/dependency seems necessary | Stop that branch and request approval | Existing assets/procedural geometry are default |
| User changes visible/function contract | Update this plan before continuing | Do not bury the decision in code |

## Progress and Next Steps

- Canonical progress: task checkboxes in this document.
- Current phase: implementation-ready handoff; tasks 1.1 through 5.4 are
  complete.
- 2026-08-04 terrain MVP transfer: the user accepted the standalone Closed
  Mountain Lab as sufficiently close to the intended MVP and instructed direct
  integration. Generation contract v5 now uses the same continuous central
  backbone, ordered broad ridge fields, increasing passes, rare shallow
  off-center basin, spike-free broad variation, and elongated closed mass.
  Existing route data blends playable rolling lanes into that body without
  owning its silhouette or carving out its center.
- Runtime target admission now treats slope distributions as dormant QA metrics
  and retains structural target-area, connectivity, and graph-node gates. This
  follows the locked rule that formal quality certification cannot block the
  implemented MVP from loading.
- Before Phase 7, Godot 4.7.1 headless import, script parsing, and main-scene
  startup passed for generation v5, but no visible approval or current release
  evidence existed.
- Phase 6.1 through 6.4 passed headlessly, but the user's running-build QA then
  invalidated the visible-terrain, paint-feedback, and responsiveness outcome.
- Phase 7 implementation and bounded headless delivery are complete. The final
  safe Briefing/Wide/Result poses frame every generated render AABB on all three
  stages; static Aiming reuses its solved pose; same-interval aim changes perform
  one latest-value prediction at Fire.
- The Stage 1 default physical shot still records 4.400 seconds of real top
  contact, 34.045 m of surface travel, 264 continuous sweeps, and 15.2824%
  coverage. Its final shader-bound texture bytes match the authoritative mask.
- Godot import/startup, `scripts/verify.ps1`, the focused Phase 7 contract,
  generation-v5 closed-mountain check, Windows release export, and hidden
  exported startup passed without opening a visible process.
- The user's 2026-08-04 aiming capture rejected Phase 7: the high front shell,
  low authored Aiming camera, and uninitialized ReplayBar produced an unusable
  screen despite passing headless contracts.
- Phase 9 is implemented but rejected by the user's foreground review: its probe
  omitted the synchronous Fire call and could not detect a physics-tick-driven
  camera. Its checked tasks remain historical implementation facts, not an
  accepted responsiveness outcome.
- Current phase: Phase 10 implementation and bounded evidence are complete
  except for the rendered paint/non-paint p95 delta gate in Task 10.4.
- Next task: the user performs foreground Fire/flight acceptance through the
  unchanged fastrun command. A further production optimization requires new
  foreground evidence or a root-authored causal measurement plan; the existing
  `4.457 ms` hidden-window delta alone does not authorize speculative changes.
- Baseline: ea9d28c supplies reusable physical/paint foundations but no accepted
  visual result.
- User gate: the 2026-08-04 running screen is rejected; do not polish or expand
  the existing slab.
- A checked task means implemented by production inspection, not tested or
  user-approved.
- Run only the Phase 10 smoke, hidden release probe, and two off-desktop captures
  that directly prove the reported failures.
- Earlier release/export evidence is historical. The registered fastrun
  executable now contains the Phase 10 Fire, camera, audio, projectile, and
  paint hot-path changes; it has not yet received the user's foreground
  acceptance.
- `scripts/verify.ps1` now treats Godot `SCRIPT ERROR:` and `ERROR:` output as
  failure because this engine can return exit code zero after such errors.

## Completion and Stop Conditions

Implementation-ready when:

- all stages use one irregular closed mountain mass attached to the wall;
- ball, trajectory, paint, coverage, result, and restart connect to it;
- all three mechanisms are visible, collidable, distinct, and functional;
- world presentation uses the approved bright low-poly hierarchy;
- Korean-default HUD has left coverage, center Fire, top-right shots/gear, and
  paused-menu Restart;
- obsolete production owners and certificate gates are gone;
- latest mandatory headless launch smoke passes;
- implementation record lists every untested behavior.

Phase 8 is complete only after the actual off-screen release capture has been
opened and inspected by the implementing agent. Do not substitute headless
contracts for that visual gate or claim user approval from the agent's capture.

Replan only when user feedback changes the visible object, gameplay rule, UI
hierarchy, asset boundary, or testing boundary, or when the locked closed-mass
architecture requires another material decision.

Do not replan or stop for stale tests, missing certificates, unchecked
performance, replay/persistence coverage, or implementation-local organization.
