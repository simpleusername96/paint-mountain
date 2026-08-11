---
type: plan
status: draft
created: 2026-08-11
scope: correct browser and native focus/orbit behavior, remove stage-entry and first-use stalls, and add Web runtime release evidence
source: https://itchioprofile1351321.itch.io/paint-mountain
related:
  - ../PLANS.md
  - ../Documentation.md
  - ../design/DESIGN.md
  - ../design/UIUX_GUIDELINES.md
  - ../../docs/source-brief.md
  - ../../docs/technical-architecture.md
  - ../../docs/test-checklist.md
---

# Web Runtime Responsiveness and Interaction Correction - Execution Contract

This contract covers the shared Godot behavior reported in native testing and
the browser build currently uploaded to itch.io. It is decision-complete, but
remains `draft` because
`2026-08-10-aggressive-repository-cleanup.md` is the repository's one active
ExecPlan. Activate this contract only after that plan is completed, superseded,
or archived; do not run two active plans implicitly.

## Purpose

- Objective: make Paint Mountain respond like a conventional desktop 3D game,
  enter every selected stage without a visible main-thread freeze, and keep the
  first real shot as smooth as later shots in the single-threaded Web build.
- Deliverable: corrected initial focus transfer and Map Inspection drag
  direction, incremental and reusable stage preparation, first-use rendering
  warm-up, a Web-safe coverage icon, focused regression tests, production-style
  Web/Windows evidence, and a release checklist that measures the actual canvas
  journey rather than only the itch page shell.
- Completion state: the focused and full Godot gates pass, the release exports
  pass their size/reference checks, the Windows build and foreground itch Web
  build meet the interaction and frame-time budgets below, and the final
  evidence contains separate running-game captures at 1280x720 and 1920x1080.

## Scope and Boundaries

In scope:

- Main Menu automatic-focus behavior while the selected stage changes from
  loading to ready.
- Horizontal left-drag semantics in Map Inspection; vertical orbit, Aim View
  targeting, cannon yaw, and camera safety remain unchanged.
- The selected-stage path from baked-layout hydration through terrain,
  collision, paint bootstrap, dressing, mechanisms, gameplay scene readiness,
  and first-use render work.
- Reuse of one prepared stage artifact between menu preview and gameplay without
  creating a second paint/coverage authority.
- Web release checks for referenced files, compression/MIME, payload, canvas
  resizing, console errors, storage/audio smoke, foreground frame pacing, and
  memory growth.
- The coverage caption's missing-glyph presentation in the Web export.

Out of scope:

- New stages, terrain shapes, physics rules, coverage formulas, shot balance,
  camera framing redesign, mobile controls, controller support, or public itch
  visibility.
- Web threads, cross-origin isolation, a custom Godot runtime/template,
  production dependencies, browser-test frameworks, asset packs, or a renderer
  change.
- Removing the shared 2 px keyboard-focus style. It is an approved accessibility
  contract and must remain visible when keyboard focus is meaningful.
- Optimizing Map Inspection safety raycasts without new evidence. The current
  warmed drag path was smooth in the measured browser run.
- Installing Firefox or another browser. Chromium on Windows is the required
  first-delivery browser; Firefox and Safari remain explicitly unverified until
  the owner supplies an approved test environment.
- The unrelated manual-publish branch guard and CI cache-integrity findings from
  the release audit. Track those in a separate CI-hardening task if requested.

Constraints and invariants:

- Keep the Compatibility renderer, official Godot 4.7.1 single-thread Web
  template, fixed 60 Hz physics tick, and adaptive canvas.
- `StageController` remains the only stage-state, shot-progression, and
  clear/failure owner.
- `PaintSystem` remains the sole mutable paint mask and coverage owner. Prepared
  data may contain immutable target/surface bootstrap data, never live paint or
  a second coverage value.
- `StageLayoutRepository` remains baked-layout I/O and LRU only. It must not own
  meshes, collision shapes, scene nodes, paint textures, preview nodes, or
  gameplay state.
- Stage preparation must remain cancellable and identity-checked. An obsolete
  selection must never enter or display another stage.
- Do not hide work behind a frozen loading label. The menu or Stage Select must
  continue to paint and accept navigation while preparation advances.

Destructive or irreversible actions:

- None. Generated exports and evidence can be regenerated. No production
  dependency or external service change is authorized by this contract.

Approval boundary:

- Local code, tests, exports, captures, and a scoped commit are inside the
  implementation task. Pushing, merging, triggering the publish workflow, or
  changing itch visibility still requires the user's explicit instruction.
- After an authorized publish, the post-deploy itch smoke is mandatory before
  this plan can become `done`.

## Current State and Measured Findings

Reference run:

- Uploaded revision: itch `alpha.3+4976298`, Draft/owner preview, measured on
  Windows in foreground Chrome 151 with Intel Iris Xe, 8 logical processors,
  16 GB device memory, and 1920x855 plus 1280x720 canvas viewports.
- The browser run used the real itch iframe. Automation return times include
  browser overhead; foreground `requestAnimationFrame` samples and main-thread
  task deltas are the stronger frame-pacing evidence.

| Surface | Current result | Severity | Evidence and interpretation |
| --- | --- | --- | --- |
| Launch and network | Functional, slow to playable | P2 | Run-to-menu was about 12.1 s. DOM load was about 1.29 s, so page timing alone misses Godot/Wasm initialization. Encoded Wasm/PCK/JS transfer was about 17.7 MiB and the CDN served correct gzip and MIME. |
| Initial Main Menu focus | Fail | P1 | Stage Select showed the approved blue keyboard-focus outline while Play was still loading, making the secondary action look selected. |
| Stage entry | Fail | P1 release blocker | A Stage 2 entry sample contained one 1466.6 ms frame; the surrounding warmed frames returned to 60 Hz. Stage 1 entry also held the main thread for about 4.0 s over a 7.4 s observation window. |
| Warm Map Inspection drag | Pass | — | 240 foreground frames averaged 16.63 ms, p95 16.8 ms, maximum 17.0 ms, with no frame over 20 ms. Camera safety is not the primary reported stall. |
| Map Inspection direction | Fail | P1 | Horizontal camera yaw adds `relative.x`, producing the opposite of the requested grab/turntable convention. No test asserts the on-screen direction. |
| First real shot | Fail | P1 | The first Stage 2 shot had an 849.8 ms maximum frame, 18 frames over 20 ms, and 4 over 50 ms. The next warmed shot peaked at 33.5 ms with no frame over 50 ms, which isolates a cold first-use path. |
| Responsive layout | Mostly pass | P2 defect | The canvas matched 1280x720 and 1920x855 without clipping. At 1280x720 the literal `◎` coverage caption rendered as a missing/fallback glyph in Web. |
| Console/runtime protocol | Pass in measured run | — | No console error or warning was observed. WebGL2 used ANGLE/D3D11; `crossOriginIsolated` was false, as required for the single-thread itch path. |
| Memory and endurance | Not yet qualified | P2 gap | JavaScript heap samples do not include all Wasm and GPU allocations. No multi-stage/restart/paint soak or context-loss gate exists. |
| Browser compatibility | Not yet qualified | P2 gap | Current evidence is Chrome/Windows only. Firefox was not installed and Safari is outside the Windows-first delivery target. |

These grades are project release judgments. Core Web Vitals remain useful for
the itch/page shell, but LCP and INP do not describe when a WebAssembly canvas
game becomes playable or whether a physics/render frame stalls after Fire.

## Discovery Closure

| Requirement or concern | Verified current owner and behavior | Direct evidence | Locked decision | Task IDs |
| --- | --- | --- | --- | --- |
| Initial focus | `AppRoot._show_main_menu()` defers `MainMenuScreen.focus_primary()`. If Play is disabled, `focus_primary()` gives Stage Select fallback focus; later readiness enables Play without transferring focus. Web also focuses the canvas on start. | `src/app/app_root.gd`, `src/ui/screens/main_menu_screen.gd`, `export_presets.cfg`, running itch capture | Keep the shared focus style and canvas focus. Add focus-visible semantics: passive/pointer launch shows no control ring; the first keyboard-navigation input focuses Play when ready or Stage Select while loading. If keyboard fallback still owns focus when Play becomes ready, transfer it to Play unless the player moved focus. | 1.1 |
| Orbit direction | `CameraDirector.orbit_inspection()` adds horizontal mouse delta to inspection yaw. | `src/camera/camera_director.gd`; running interaction; no direction assertion in current tests | Negate the horizontal contribution. Keep pitch, cannon yaw, target selection, zoom, smoothing, and safety policy unchanged. Prove the visible landmark direction, not only the internal yaw sign. | 1.2 |
| Coverage glyph | `coverage_meter.tscn` uses literal `◎`; the Web font path did not render it reliably. | 1280x720 itch capture; approved local `assets/ui/icons/target.png` exists | Replace the font glyph with the approved target texture inside the existing component. Do not introduce another icon or font dependency. | 1.3 |
| Stage-entry stall | `AppRoot._enter_stage()` instantiates and adds Gameplay immediately. `GameplayScene._ready()` synchronously copies the layout, rebuilds terrain mesh/concave collision, initializes 512-square paint data/textures, dresses the environment, and spawns mechanisms before the next useful frame. | `src/app/app_root.gd`, `src/gameplay/gameplay_scene.gd`, `src/terrain/terrain_surface.gd`, `src/paint/paint_system.gd`; 1466.6 ms entry frame | Add a separate, identity-scoped `StageRuntimePreparer` and immutable `StageRuntimeArtifact`. Prepare in bounded phases while the current screen stays interactive; enable entry only when the artifact and a hidden prepared Gameplay scene are ready. | 2.1-2.4 |
| Duplicate preview/gameplay work | `AppRoot` builds and caches a preview `TerrainGeometry`, then clears it when another preview is built; Gameplay independently calls `TerrainGeometryFactory.build()` again. | `src/app/app_root.gd:362-443`, `src/terrain/terrain_surface.gd:19-45` | The runtime artifact owns one immutable geometry result and local presentation points. Preview and Gameplay may share those immutable resources; mutable materials and live paint remain per Gameplay run. | 2.2-2.3 |
| Paint bootstrap | `PaintSystem.configure()` allocates masks, verifies the target checksum, scans all 262,144 pixels for the non-target mask, creates three images/textures, and builds topology-axis caches during entry. | `src/paint/paint_system.gd:743-845` | Prepare immutable target/non-target bytes and topology-axis tables before entry. PaintSystem still allocates its zeroed live mask and publishes coverage; it copies or references only immutable bootstrap inputs. | 2.2-2.3 |
| First-shot cold path | Presentation effect pools exist at `_ready()`, but the first emitted particle/material/projectile/paint-render path is not rendered before the real shot. The second shot removes the large stall. | `src/effects/presentation_effects.gd`, `src/projectile/projectile_manager.gd`, first/warm shot frame samples | Add a no-gameplay-side-effect warm-up stage. Render one representative paint material, projectile visual, and each effect material one family per frame in a temporary stage-owned `SubViewport`; do not emit signals, consume shots, mutate paint, or create physics bodies. | 3.1-3.2 |
| Aim-entry composition | Aim composition calculates and caches interest points, including summit work. It can contribute to Start Aiming latency but is not the measured 1.47 s stage-build owner. | `src/camera/camera_director.gd`, `src/terrain/terrain_surface.gd`, existing caching test | Move immutable presentation/summit points into the runtime artifact and retain one-time camera pose caching. Do not change framing policy. | 2.2, 2.3 |
| Web release validation | CI verifies native tests, export success, four files, and itch archive limits, but not the actual iframe runtime, referenced worklet/icon files, payload regression, or canvas journey. | `.github/workflows/itch-alpha.yml`, `scripts/verify.ps1`, `scripts/test.ps1` | Add dependency-free export/reference/size checks to CI and a required manual foreground runtime evidence gate. Do not add Playwright or another browser dependency in this plan. | 4.1-4.4 |

Readiness statement:

- The three reported symptoms, their owners, the measured Web bottlenecks, the
  accessibility constraint, the single-thread constraint, and the validation
  environment are fixed.
- The large first-use stall is assigned to explicit warm-up work even if a
  trace later shows one family dominates; that fact may reduce the warm-up set
  but cannot move gameplay state or paint ownership.
- No remaining unknown can change product behavior, dependency policy,
  architecture ownership, persistence, safety, or the acceptance budgets.

## Locked Architecture

### StageRuntimePreparer

Add `src/app/stage_runtime_preparer.gd` as an AppRoot-owned coordinator. It
accepts `(StageData, GeneratedStageLayout)`, cancels obsolete selections, and
emits typed ready/failed/progress signals keyed by full stage identity and
layout checksum. It owns an LRU of at most three artifacts: Stage 01 preview,
the selected stage, and the prefetched next stage.

Preparation is cooperative on the main thread because Godot render and physics
resources are not delegated to unsafe worker code. Split work into bounded
steps and yield at least one `process_frame` between them:

1. create the isolated runtime layout copy;
2. incrementally collect terrain vertex/index/normal arrays in row batches;
3. create the ArrayMesh, top collision, and shell collision as separate steps;
4. build local playable/presentation/summit point arrays;
5. build immutable target/non-target bytes and topology-axis tables;
6. create immutable target/non-target textures as separate steps;
7. prepare dressing placement inputs and preload existing PackedScenes;
8. run first-use rendering warm-up one material/effect family per frame.

`TerrainGeometryFactory` must expose a progressive build job rather than
duplicating geometry math in AppRoot. A step uses an elapsed-time budget and
returns incomplete/complete state. The initial row batch may start at four
rows, but the job must stop for the current frame once its measured work reaches
8 ms; batch count is an implementation detail inside that fixed time budget.

### StageRuntimeArtifact

Add `src/app/stage_runtime_artifact.gd` as an immutable `RefCounted` value. It
contains stage identity/checksum, the isolated runtime layout, `TerrainGeometry`,
local playable/presentation points, immutable paint bootstrap arrays/textures,
and validated dressing placement inputs. It contains no Node, live material,
mutable paint bytes, coverage count, timer, shot, camera mode, or stage state.

`AppRoot` replaces the preview dictionary cache with this typed artifact. The
preview uses the artifact's mesh and immutable target texture. `GameplayScene`
accepts the exact same artifact through `prepare_stage()` and must not call
`TerrainGeometryFactory.build()` or repeat the full non-target scan.

### Prepared Gameplay handoff

The selected stage is not reported ready when only the layout has loaded.
`AppRoot` keeps Main Menu or Stage Select visible while it adds a hidden
Gameplay scene and lets bounded preparation finish. The Gameplay scene emits a
typed `stage_prepared` signal only after terrain/collision/paint bindings,
dressing, mechanisms, camera/HUD wiring, and first-use warm-up are complete.
Only then does Play/Start enable. Activating the button performs a visibility
handoff rather than synchronous materialization.

Preparation cancellation frees only the obsolete hidden Gameplay instance and
its per-run mutable objects. Shared immutable artifacts remain subject to the
three-entry LRU. `StageController` does not start or receive player actions
until the visibility handoff.

### Performance observations

Add delivery-only stage markers at these boundaries: layout ready, artifact
ready, Gameplay prepared, Gameplay visible, Aim View visible, Fire accepted,
first projectile visible, first paint/effect visible. Use Godot monotonic time
and emit concise JSON lines only when the existing delivery/debug flag is set.
Record `Performance.MEMORY_STATIC`, `Performance.RENDER_VIDEO_MEM_USED`, active
object counts, artifact-cache entries, and projectile counts at the beginning
and end of the soak. Do not put Web performance telemetry on a network service.

## Tasks

### Phase 1: Correct visible interaction contracts

Goal: remove ambiguous automatic selection, restore direct-manipulation orbit,
and eliminate the Web-only missing glyph without redesigning the interface.

Preconditions:

- This plan is active and the current focus/orbit tests still demonstrate the
  pre-change behavior.

Source owners: `src/ui/screens/main_menu_screen.gd`,
`src/camera/camera_director.gd`, `scenes/ui/hud/coverage_meter.tscn`, existing
Theme and approved icon assets

- [ ] **1.1** Add focus-visible startup semantics and safe loading fallback.
  - Change: do not auto-grab a control on passive or pointer-led application
    launch. On the first keyboard navigation input, focus Play when ready or
    Stage Select while Play is loading. Track whether Stage Select then owns
    keyboard fallback focus; on readiness, move it to Play only when that exact
    fallback still owns focus and no later user navigation occurred.
    Retry/failure keeps its current reachable action. Keep
    `html/focus_canvas_on_start=true` so the canvas receives keyboard input.
  - Test: add a focused case to `tests/phase7_ui_test.gd` for no initial control
    ring, pointer activation, first Tab/arrow focus, cold-loading fallback,
    readiness transfer, user-moved focus preservation, failure/retry, and
    keyboard activation.
  - Accept: no button looks selected on passive/pointer launch; Tab/Shift+Tab or
    directional keyboard navigation shows the shared 2 px accent on the correct
    action and every action remains reachable.
- [ ] **1.2** Reverse horizontal Map Inspection drag and lock screen semantics.
  - Change: subtract horizontal mouse motion in
    `CameraDirector.orbit_inspection()`; leave the vertical equation and all Aim
    View input unchanged.
  - Test: add `tests/map_inspection_direction_test.gd`. Project a stable terrain
    landmark before and after a synthetic drag and assert that right-to-left
    drag produces the requested clockwise/direct-grab screen movement. Also
    assert unchanged pitch and unchanged cannon aim.
  - Accept: runtime left/right drags match the user's convention at both target
    viewports and do not change the committed aim.
- [ ] **1.3** Replace the coverage font glyph with the approved target icon.
  - Change: use `assets/ui/icons/target.png` in the existing CoverageMeter
    component with the current restrained size/alignment; preserve its
    accessible label and tooltip.
  - Test: extend UI structure/localization checks to reject the literal `◎` and
    confirm the texture plus text alternative.
  - Accept: Korean and English Web captures show no tofu/missing glyph, clipping,
    or alignment regression at 1280x720 and 1920x1080.

### Phase 2: Remove selected-stage materialization from the transition

Goal: keep the current screen responsive while building one reusable,
identity-safe artifact, then enter an already-prepared Gameplay scene.

Preconditions:

- Phase 1 focused checks pass.
- `StageLayoutRepository` identity and LRU tests pass before the new owner is
  connected.

Source owners: `src/app/app_root.gd`, new `src/app/stage_runtime_preparer.gd`,
new `src/app/stage_runtime_artifact.gd`, `src/terrain/terrain_geometry_factory.gd`,
`src/terrain/terrain_surface.gd`, `src/paint/paint_system.gd`,
`src/gameplay/gameplay_scene.gd`, `src/terrain/environment_dressing.gd`

- [ ] **2.1** Add the progressive, identity-scoped preparation owner.
  - Change: implement cancellation, 8 ms step budget, typed progress/ready/fail
    signals, full identity/checksum validation, and an at-most-three-entry LRU.
  - Test: add `tests/stage_runtime_preparer_test.gd` for cancellation, obsolete
    completion rejection, LRU eviction, failure, step yielding, and deterministic
    artifact checksums.
  - Accept: selecting another card never publishes the old stage and at least
    one rendered frame occurs between bounded build steps.
- [ ] **2.2** Build the immutable artifact once and reuse it for preview.
  - Change: move preview geometry, local presentation/summit points, immutable
    target/non-target bytes/textures, topology-axis tables, and dressing inputs
    into `StageRuntimeArtifact`; retire AppRoot's untyped preview dictionary and
    duplicate full-mask scan.
  - Test: assert one `TerrainGeometryFactory` job per stage identity and that
    preview activation does not create a second geometry or target texture.
  - Accept: Stage 01 preview, arbitrary selected preview, and cache eviction
    retain exact layout identity and appearance.
- [ ] **2.3** Make Gameplay bind prepared data without rebuilding it.
  - Change: extend `GameplayScene.prepare_stage()`, `TerrainSurface.configure()`,
    and `PaintSystem.configure()` to accept the artifact/bootstrap. Gameplay
    creates only per-run mutable paint/material/state data. Environment dressing
    consumes prepared placement inputs but still owns its nodes.
  - Test: add `tests/prepared_gameplay_entry_test.gd` to fail if Gameplay calls
    the geometry factory, recalculates presentation/summit points, repeats the
    262,144-byte non-target loop, or accepts a mismatched artifact.
  - Accept: paint coverage, collision identity, camera framing, mechanisms, and
    restart behavior remain bit-for-bit/contract equivalent to the current
    prepared layout.
- [ ] **2.4** Switch screens only after hidden Gameplay preparation completes.
  - Change: keep the current menu/select screen visible and interactive, expose
    truthful loading/failure state, add the hidden Gameplay instance, and enable
    Play/Start only after `stage_prepared`. The button then performs an immediate
    visibility/input handoff. Cancel and free obsolete hidden instances safely.
  - Test: extend UI and navigation tests for loading, cancel/reselect, failure,
    rapid double activation, Escape, and exact selected-stage identity.
  - Accept: selection-to-ready may take time, but no foreground frame exceeds
    50 ms; ready-button activation to visible Briefing is at most 100 ms and no
    stage rule advances while hidden.

### Phase 3: Remove the cold first-shot rendering stall

Goal: compile and allocate representative render-only first-use paths before
the stage becomes interactive, with no gameplay side effects.

Preconditions:

- Phase 2 supplies a hidden prepared Gameplay scene and delivery markers.

Source owners: `src/gameplay/gameplay_scene.gd`, new
`src/gameplay/gameplay_first_use_warmup.gd`,
`src/effects/presentation_effects.gd`, `src/projectile/paint_projectile.gd`,
`src/paint/terrain_paint.gdshader`

- [ ] **3.1** Add a stage-owned render-only warm-up component.
  - Change: in a temporary `SubViewport`, render one representative terrain
    paint material, projectile visual, and each existing particle/effect material
    one family per frame. Free the viewport after the rendering server has
    completed the warm-up.
  - Guard: do not add a RigidBody, call `ProjectileManager.spawn_projectile()`,
    emit gameplay/effect signals, consume a shot, write a paint byte, publish
    coverage, or change `StageController`.
  - Test: add `tests/gameplay_first_use_warmup_test.gd` for exact warm-up families,
    idempotence, cleanup, and zero changes to shots/projectiles/paint/state.
  - Accept: warm-up completes before `stage_prepared` and leaves no node/resource
    growth after repeated stage exits.
- [ ] **3.2** Verify the real first Fire path and remove redundant cold work.
  - Change: use delivery markers and a Chrome Performance trace to attribute any
    remaining first-shot long frame. Remove only redundant allocation or compile
    work in the evidenced owner; do not change projectile physics/effects meaning.
  - Accept: first and second representative shots both meet p95 at most 16.7 ms,
    p99 at most 33.3 ms, maximum at most 50 ms, and Fire-to-first-visible-response
    at most 100 ms on the reference Chrome/Windows setup.

### Phase 4: Establish a real Web delivery gate

Goal: validate the foreground game journey, not only native headless behavior
and archive limits.

Preconditions:

- Phases 1-3 focused tests and browser budgets pass on a local release export.

Source owners: `.github/workflows/itch-alpha.yml`, `export_presets.cfg`,
`docs/test-checklist.md`, delivery/debug evidence owner

- [ ] **4.1** Harden dependency-free Web artifact checks.
  - Change: parse references from the exported `index.html` and `index.js`,
    require every referenced icon/worklet/runtime file, record raw and gzip
    sizes for Wasm/PCK/JS and total payload, and verify the no-thread export
    contract. Exclude the v9 migration fixture from the release preset only;
    retain it in the repository and native tests.
  - Accept: no missing reference, incorrect case, thread-enabled artifact, or
    archive-limit violation; encoded initial payload is at most 20 MiB and does
    not grow by more than 10% from the accepted baseline without an explicit
    review.
- [ ] **4.2** Run the foreground interaction/frame gate.
  - Change: capture Chrome Performance plus rAF/Long Animation Frame summaries
    for cold launch, Main Menu, Stage Select, Stage 1 and Stage 2 entry, stable
    Map Inspection drag, Aim transition, first and second Fire, restart, and
    stage exit.
  - Accept: cold click-to-menu at most 10 s and warm at most 6 s on the same
    reference machine/network; interactive segments meet p95 at most 16.7 ms,
    p99 at most 33.3 ms, no frame over 50 ms, and ordinary visible input response
    at most 100 ms. Record failures rather than averaging away a single stall.
- [ ] **4.3** Run responsive, storage, audio, and memory smoke.
  - Change: test 1280x720 and 1920x1080, resize and host fullscreen from a user
    gesture, Korean/English, keyboard/mouse focus, audio unlock, save/reload,
    three stage enter/fire/restart/exit cycles, tab background/resume, and WebGL
    context status.
  - Accept: no clipping/tofu, stuck key, unintended Fire/aim, console error,
    lost save, silent unlocked audio, or WebGL context loss. After returning to
    the same Main Menu state, Godot static/video memory and Chrome memory
    footprint are no more than 10% above the first-cycle settled baseline; the
    artifact cache is at most three and no Gameplay/projectile node leaks.
- [ ] **4.4** Update release evidence and post-deploy itch verification.
  - Change: add the Web matrix and budgets to `docs/test-checklist.md`, update
    `.agents/Documentation.md` only with implemented truth, save separate
    running-game screenshots and concise trace summaries, and run the scoped
    quality audit. After user-authorized publish, repeat the foreground smoke on
    the actual itch page and record the deployed revision.
  - Accept: build and deployed evidence are separate; Draft visibility remains
    unchanged; no claim extends to Firefox, Safari, or mobile.

## Acceptance Criteria

- [ ] On passive/pointer launch no control ring appears. On keyboard navigation,
  Stage Select never retains loading fallback focus after Play becomes ready;
  keyboard focus remains visible and reachable.
- [ ] Right-to-left Map Inspection drag produces the requested clockwise/direct
  grab behavior; vertical orbit and Aim View behavior do not regress.
- [ ] Menu/Stage Select stays responsive while preparing a selected stage, and
  activating a ready stage shows Briefing in at most 100 ms with no frame over
  50 ms.
- [ ] Preview and Gameplay share one identity-matched immutable geometry/paint
  bootstrap artifact; `PaintSystem` remains the single live paint/coverage owner.
- [ ] The first shot and later shots meet the same 50 ms maximum-frame gate and
  show a response within 100 ms.
- [ ] The coverage icon renders consistently at both required viewports in
  Korean and English.
- [ ] The Web export remains official, single-threaded, WebGL2/Compatibility,
  adaptively sized, under the payload budget, and free of missing referenced
  files or console errors.
- [ ] Three lifecycle cycles show no context loss, node leak, artifact-cache
  growth, or more than 10% settled memory growth.
- [ ] Focused tests, the full suite, `scripts/verify.ps1`, Web and Windows release
  exports, built-game visual QA, and post-publish itch QA pass at the declared
  cadence.

## Validation and Rework Controls

Reference commands use the configured Godot 4.7.1 console path:

```powershell
& $env:GODOT_BIN --headless --path . --quit-after 7200 --script res://tests/phase7_ui_test.gd
& $env:GODOT_BIN --headless --path . --quit-after 7200 --script res://tests/map_inspection_direction_test.gd
& $env:GODOT_BIN --headless --path . --quit-after 7200 --script res://tests/stage_runtime_preparer_test.gd
& $env:GODOT_BIN --headless --path . --quit-after 7200 --script res://tests/prepared_gameplay_entry_test.gd
& $env:GODOT_BIN --headless --path . --quit-after 7200 --script res://tests/gameplay_first_use_warmup_test.gd
./scripts/verify.ps1 -GodotPath $env:GODOT_BIN
./scripts/test.ps1 -GodotPath $env:GODOT_BIN
& $env:GODOT_BIN --headless --path . --export-release 'Web' 'builds/web/index.html'
& $env:GODOT_BIN --headless --path . --export-release 'Windows Desktop' 'builds/windows/PaintMountain.exe'
```

| Cadence | Exact check | Run when | Do not rerun until |
| --- | --- | --- | --- |
| Inner loop | One changed-owner test plus `git diff --check` | After a coherent edit | That owner or its contract changes |
| Phase 1 gate | UI, localization, map-direction, and camera-safety focused tests | Interaction fixes are complete | A Phase 1 input changes |
| Phase 2 gate | Layout repository, runtime preparer, prepared entry, terrain, paint, mechanism, and UI navigation focused tests | Artifact handoff is complete | A preparation/identity owner changes |
| Phase 3 gate | Warm-up side-effect test plus one local foreground Web trace | Warm-up is connected | A first-use render owner changes |
| Broad final gate | `scripts/verify.ps1`, full `scripts/test.ps1`, both release exports, then production-style visual/runtime QA | All focused gates pass and the feature set is stable | A final-gate input changes materially |
| Deployment gate | Actual itch foreground smoke and evidence | User authorizes and completes publish | A deployed artifact or itch setting changes |

Before the broad full-suite/export gate, tell the user it is the final expensive
validation pass, what it will run, and that it may recreate `.godot`/`builds`.
Run it once after the implementation stabilizes. For a local Web server under
`D:\npjt`, load `$npjt-port-guard` and use the fastrun manager's `codex` lane;
never invent an ad hoc port.

Runtime evidence rules:

- Keep the measured tab foreground and visible; discard background-throttled
  rAF samples.
- Report p50, p95, p99, maximum, and counts over 20/33.3/50/100/200 ms.
- Keep cold and warm runs separate. Do not merge entry, stable drag, and Fire
  into one average.
- Use Lighthouse/Core Web Vitals only for the host shell. Use game-ready markers,
  Chrome Performance/Frames, Long Animation Frames, Rendering FPS/GPU overlay,
  Godot monitors, and running-game screenshots for the canvas runtime.
- Treat Chrome JS heap as partial evidence; pair it with Godot static/video
  memory and Chrome memory footprint.

## Predetermined Contingencies and Change Control

| Trigger | Required response | Boundary or escalation point |
| --- | --- | --- |
| One progressive step still exceeds 50 ms | Split the owning CPU job further. If an indivisible Godot mesh/shape/texture creation call alone exceeds 50 ms, keep it before stage readiness, record the exact call, and escalate before changing renderer, physics representation, or visual fidelity. | Do not hide the regression by relaxing the budget or averaging it with warm frames. |
| Warm-up changes gameplay state or paint | Reject the implementation and move the operation into a render-only resource path. | Do not simulate a hidden real shot. |
| Prepared artifact duplicates live paint or coverage | Remove the mutable duplicate and retain only immutable bootstrap data. | `PaintSystem` authority is non-negotiable. |
| Artifact identity changes while a job is running | Cancel/ignore the obsolete job and prepare the newest full identity. | Never relabel or reuse a mismatched result. |
| Payload exceeds 20 MiB or grows over 10% | Remove release-only unused resources and review duplicate artifact data. | Do not add a custom Godot template, CDN, dependency, or asset compression format without approval. |
| Chrome passes but an available second browser fails | Record the exact browser/version and classify the defect. | Do not claim support or install/change dependencies without owner approval. |
| A material verified fact contradicts this contract | Stop the affected branch and update this plan before execution continues. | Do not choose a new product, architecture, dependency, safety, persistence, or validation contract silently. |

Implementation-local discoveries may be handled inside the locked contract when
they cannot change scope, visible behavior, ownership, architecture, safety,
dependencies, persistence, or acceptance.

## Progress

- Canonical progress: the task checkboxes in this plan after activation.
- Current phase: discovery and plan drafting complete; implementation has not
  started.
- Current status: draft only because the unrelated repository-cleanup ExecPlan
  remains active with its local-output cleanup task incomplete.
- Evidence complete: source/owner trace, itch launch and viewport inspection,
  foreground rAF frame samples, first/warm shot comparison, network/header
  inspection, and official Web/itch/Chrome guidance review.
- Code, scene, resource, project setting, CI, and test files changed: none.

## Next Steps

1. Resolve the single-active-plan gate by completing, superseding, or archiving
   `2026-08-10-aggressive-repository-cleanup.md`; then change this plan to
   `status: active`.
2. Execute Phase 1 and retain before/after running-game evidence for focus,
   orbit direction, and the coverage icon.
3. Execute Phase 2 with targeted identity/paint/terrain checks before any broad
   test run.
4. Execute Phase 3 and keep cold and warm Chrome traces separate.
5. Run Phase 4 once, complete the scoped `$codebase-quality-auditor` pass, and
   request authorization before any push/publish action.

## Risks

- A hidden Gameplay scene can accidentally begin state processing. The plan
  prevents this by gating `StageController` actions and visibility/input until
  the explicit handoff.
- Sharing Godot Resources is safe only while the artifact is immutable. Tests
  must fail on mutable paint/state storage or identity reuse.
- Shader and particle compilation behavior can differ across GPU drivers. The
  Chrome/Iris Xe budget is a first-delivery gate, not a universal hardware
  claim.
- Boot-to-menu depends on itch CDN, Wasm compilation, cache state, and device.
  Evidence must record cold/warm conditions and may not present one run as a
  population percentile.
- A 10% memory-delta gate detects lifecycle growth but is not an absolute
  low-memory device certification.

## Sources

- Current game: <https://itchioprofile1351321.itch.io/paint-mountain>
- Godot Web export requirements and limitations:
  <https://docs.godotengine.org/en/4.7/tutorials/export/exporting_for_web.html>
- itch HTML5 upload, iframe, limits, and compression guidance:
  <https://itch.io/docs/creators/html5>
- Chrome runtime Performance tooling:
  <https://developer.chrome.com/docs/devtools/performance>
- Chrome Long Animation Frames, where 50 ms is the long-frame boundary:
  <https://developer.chrome.com/docs/web-platform/long-animation-frames>
- Chrome rendering FPS and GPU-memory overlay:
  <https://developer.chrome.com/docs/devtools/rendering/performance>
- Core Web Vitals thresholds for host-page context:
  <https://web.dev/articles/defining-core-web-vitals-thresholds>

## Completion and Stop Conditions

Complete when:

- Every task and acceptance checkbox passes, final evidence is linked from the
  implementation record, the post-deploy itch revision passes, and this plan's
  lifecycle status becomes `done`.

Replan when:

- An indivisible Godot call cannot meet the frame budget without a renderer,
  physics-representation, visual-fidelity, or dependency change.
- A new browser-support requirement extends beyond Chromium on Windows.
- The artifact boundary cannot remain immutable or would create a second paint
  or stage-state authority.

Do not replan or stop for:

- Batch-size tuning inside the fixed 8 ms preparation budget.
- A passing check whose relevant inputs have not changed.
- A first-use trace that shows one of the already-listed warm-up families is the
  dominant cost; fix that owner within Phase 3.
