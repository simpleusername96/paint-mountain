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
- Testing state: after implementation-ready state, stop and wait for explicit
  user authorization. Do not run tests, visible QA, export, performance,
  replay, reliability, or capture work before that instruction.
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
    continuous span, adjacent spans overlap, and no internal cell void exists.

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

## Deferred QA Backlog - Inactive

This work has no active checkboxes and may not start automatically:

- all focused tests and scripts/test.ps1;
- generation, target, terrain, containment, contact, paint, mechanism, state,
  UI, localization, replay, persistence, agent, debug, and reliability suites;
- exhaustive reachability and certificate generation;
- predictor/rigid-body tolerance and repeated-process determinism;
- solution search and target/shot balance confirmation;
- load, memory, frame-time, allocation, and stress measurement;
- migration/deletion of obsolete test fixtures and runner registrations;
- Windows export and fastrun executable verification;
- visible resolution/locale QA, screenshots, manifests, and reference comparison;
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
| A visible launch would help | Record the untested assumption and continue | Only the user authorizes visible testing |
| New asset/dependency seems necessary | Stop that branch and request approval | Existing assets/procedural geometry are default |
| User changes visible/function contract | Update this plan before continuing | Do not bury the decision in code |

## Progress and Next Steps

- Canonical progress: task checkboxes in this document.
- Current phase: implementation-ready handoff; tasks 1.1 through 5.4 are
  complete.
- Next task: wait for explicit user authorization before visible or formal QA.
- Baseline: ea9d28c supplies reusable physical/paint foundations but no accepted
  visual result.
- User gate: the 2026-08-04 running screen is rejected; do not polish or expand
  the existing slab.
- A checked task means implemented by production inspection, not tested or
  user-approved.
- Do not run formal tests until the user explicitly activates deferred QA.
- Godot 4.7.1 headless import/script parsing, main-scene startup, direct
  gameplay-scene startup through `BRIEFING`, release export, and exported-build
  headless startup passed on 2026-08-04 without a visible window.
- `scripts/verify.ps1` now treats Godot `SCRIPT ERROR:` and `ERROR:` output as
  failure because this engine can return exit code zero after such errors.
- `builds/windows/PaintMountain.exe` was rebuilt from the current source and
  the existing exact-directory fastrun entry points to it.

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

Then stop. Do not run formal tests, launch visibly, export, capture screenshots,
claim approval, or mark this plan done.

Replan only when user feedback changes the visible object, gameplay rule, UI
hierarchy, asset boundary, or testing boundary, or when the locked closed-mass
architecture requires another material decision.

Do not replan or stop for stale tests, missing certificates, unchecked
performance, replay/persistence coverage, or implementation-local organization.
