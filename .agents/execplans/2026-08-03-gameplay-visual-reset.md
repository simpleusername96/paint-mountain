---
type: plan
status: active
created: 2026-08-03
last_reviewed: 2026-08-04
scope: implementation-first completion of the visible 3D mountain, physical paintball loop, mechanisms, three stages, Korean-first HUD, and world presentation before user-authorized QA
source: explicit user corrections through 2026-08-04, including rejection of the current running screen and direction to defer testing until functionality and visuals are implemented
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
- Testing state: implementation now includes the bounded Phase 8 invalidation
  checks and non-obstructive real-render inspection requested by the user.
  Performance, broad regression matrices, balance, replay, and tolerance work
  remain deferred until separately requested.
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
- Replay, persistence, agent, debug, localization-matrix, reliability, stress,
  and performance validation.
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
    deterministic byte-array checksum with replay format 5.
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
- load, memory, frame-time, allocation, and stress measurement;
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
- Current phase: Phase 8 implementation and background release evidence are
  complete; the plan remains active for the user's running-build review.
- Next task: respond to that review or, only when explicitly authorized, define
  a bounded QA phase from the deferred backlog.
- Baseline: ea9d28c supplies reusable physical/paint foundations but no accepted
  visual result.
- User gate: the 2026-08-04 running screen is rejected; do not polish or expand
  the existing slab.
- A checked task means implemented by production inspection, not tested or
  user-approved.
- Run only the bounded Phase 7 checks that directly prove the reported failures.
- Earlier release/export evidence is historical. The registered fastrun
  executable now contains the Phase 7 recovery and passed hidden headless startup.
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
