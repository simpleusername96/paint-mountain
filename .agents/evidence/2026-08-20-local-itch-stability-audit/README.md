---
type: evidence
status: active
created: 2026-08-20
scope: local code, tests, Windows runtime renders, and remote itch static deployment baseline for the reopened three-ball prototype stabilization plan
related:
  - ../../execplans/2026-08-18-three-ball-target-band-prototype.md
  - ../../execplans/2026-08-11-web-runtime-responsiveness.md
  - ../../../docs/test-checklist.md
---

# Local and itch stability audit — 2026-08-20

## Outcome

The current build has one confirmed first-Fire focus race, several reachable
special-ball lifecycle/presentation defects, and layout owners that are too
dependent on fixed 1280x720 coordinates. The accepted-size Windows captures do
not show hard clipping, but Aim captions/context copy are too faint and smaller
Web stress sizes expose shrinkage and unbalanced fixed-column composition.

The public itch deployment is reachable and its PCK is exactly the artifact
reported by the successful `alpha.9+2edb4c4` workflow. Static deployment health
does not close input, frame-pacing, resize, audio, save, or special-ball behavior:
the approved interactive browser connection was unavailable in this session, so
those checks remain mandatory after fixes.

## Revisions and environment

- Inspected worktree HEAD: `89e04f4` on
  `codex/three-ball-target-band-prototype`; it is documentation-only after the
  deployed runtime commit.
- Deployed runtime commit: `2edb4c42e3de0ceaa9358dbfc5e5b58094cbe5a9`.
- Godot/runtime capture: `4.7.1.stable`, Compatibility/OpenGL 3.3, Intel Iris Xe,
  fixed 60 Hz project physics.
- Windows artifact: `builds/windows/PaintMountain.exe`, built 2026-08-18.
- Public page: https://itchioprofile1351321.itch.io/paint-mountain
- Deployed iframe at inspection time:
  https://html-classic.itch.zone/html/18752891-1893930/index.html?v=1787055898
- Publish workflow: GitHub Actions run `32135545451`, successful on 2026-08-18.

## Sources inspected

- Product authority: `docs/source-brief.md`, `docs/design-spec.md`,
  `docs/technical-architecture.md`, `.agents/Documentation.md`, the active
  ExecPlan, and the UI/art direction documents under `.agents/design/`.
- Input/state/focus: `gameplay_scene.gd`, `hud_controller.gd`,
  `aim_input_controller.gd`, `camera_director.gd`, `stage_controller.gd`, and
  the real HUD scenes/tests.
- Projectile/paint/effects: `paint_projectile.gd`, `projectile_manager.gd`, both
  intrinsic behavior components, `paint_system.gd`,
  `presentation_effects.gd`, and focused projectile/camera tests.
- Delivery/performance: the current render-only warm-up and telemetry owners,
  `export_presets.cfg`, the Web export, release validator, publishing workflow,
  and the archived 2026-08-11 Web responsiveness plan/evidence.
- Current official platform guidance: Godot 4.7 Web export and custom HTML shell
  documentation plus itch HTML5 upload/iframe documentation. These support the
  existing single-thread Compatibility export and canvas-focus/gesture gates.

## Local correctness checks

The following current targeted tests passed under Godot 4.7.1:

- `aim_interaction_test.gd`
- `rapid_fire_contract_test.gd`
- `impact_burst_ball_test.gd`
- `apex_split_ball_test.gd`
- `ball_queue_progression_test.gd`
- `hud_target_band_truth_test.gd`
- `target_band_layout_test.gd`
- `phase7_ui_test.gd`
- `prototype_stage_runtime_smoke_test.gd`

They prove their existing headless contracts but do not send the first Space
through the full Briefing-to-Aim GUI focus path, measure a foreground Web frame,
or inspect a split family over time. That explains why they pass while the
reported issues remain reachable.

## Confirmed code findings

### P1 — first Space is lost until focus changes

1. `GameplayScene._on_state_changed()` calls `HUDController.show_state(AIMING)`
   before it calls `CameraDirector.set_mode(AIMING)`.
2. The camera is still in Briefing/Map Inspection presentation, so the HUD gives
   focus to `CameraInteractionControl`, not Fire.
3. Interaction-mode and camera-mode callbacks later update visibility, but the
   final camera callback does not request a focus correction.
4. `AimInputController` rejects Space whenever a non-Fire Button owns focus.

The target, default aim, deal, and Fire readiness already exist. There is no
cannon collider that could trap the ball. This is an ordering/focus defect, not
a terrain-click requirement or barrel-physics defect.

### P1/P2 — cold shot and contact work remain unqualified

- The prior real itch baseline measured an 849.8 ms first-shot frame, eighteen
  frames over 20 ms, and four over 50 ms. The warmed next shot peaked at 33.5 ms.
- Current warm-up renders terrain/projectile/effect resources but intentionally
  creates no live RigidBody, collision shape, or gameplay shot.
- The first live projectile still allocates/configures physics material, sphere
  shape, mesh, material, and special silhouette nodes.
- Paint radial/sweep rasterization loops over pixel candidate regions in
  GDScript. Impact Burst uses radius 14.0. Texture publication can fall back from
  partial update to a full texture upload.
- Current telemetry calls a muzzle-flash request `first_paint_effect_visible` and
  marks projectile spawn as visibility; neither is a renderer-presented-frame
  boundary.

These are ranked hypotheses with identified owners. The active plan requires one
foreground trace to select the locked remediation branch before performance code
changes.

### P2 — fixed layout and contrast risk

- Gameplay root composition, AimControls internals, Stage Select columns,
  Settings columns, and several result/briefing components use absolute offsets.
- `ActionButtons` places readiness copy at a negative vertical offset outside its
  parent. `ContextLegend` is a non-wrapping row with a 520 px minimum.
- 1280x720, 1280x800, 1366x768, and 1600x900 captures show no hard clipping.
- 1024x768 remains functional, but text scales down and Stage Select retains a
  wide fixed-column composition with unused vertical space.
- Aim `ANGLE`/`POWER` captions and the bottom context legend are visibly weak on
  dark terrain in both languages.

The correction is container/safe-area ownership inside the existing design
system, not a new visual direction.

### P2 — special-ball lifecycle and presentation

- Apex Split consumes the exact root that CameraDirector follows. The next
  physics update sees an invalid follow target and returns to Aim View; children
  cannot start the root-only impact hold. This conflicts with the source brief's
  split-family wide-view rule.
- Apex replacement deactivates the parent before reading its fields to spawn
  three children, and child admission occurs one by one. Capacity is prechecked,
  but another spawn failure can produce a consumed parent plus partial family.
- The apex behavior marks itself resolved before its zero-horizontal guard, so a
  degenerate input can permanently skip the intended split.
- Impact Burst and Apex Split both dispatch to the generic mechanism burst/audio
  presentation even though `effect_id` is available.
- Impact Burst ignores the radial-intent validity result when it publishes the
  visible effect and consumes the projectile; later authoritative paint
  rejection can therefore disagree with the presented success.

## Runtime captures reviewed

Every PNG below was captured from the Windows export with the Compatibility
renderer, saved after `RenderingServer.frame_post_draw`, and visually inspected
at original resolution. Task-local capture logs were scanned before handoff and
contained no `ERROR`, `WARNING`, or `SCRIPT ERROR`; they remain excluded by the
repository log-file ignore policy.

| Files | State and purpose |
| --- | --- |
| `01-main-menu.png`, `02-stage-select.png` | Entry and stage selection at 1280x720 Korean |
| `03-briefing.png`, `04-aiming.png`, `05-map-inspection.png` | Main prototype path at 1280x720 Korean |
| `06-impact-burst.png`, `07-apex-split.png` | Special-ball Shot Follow visual baseline; still images do not prove trigger/child timing |
| `08-late-queue.png` | Late queue at 1366x768 English |
| `09-clear.png`, `10-failed.png` | Both target-band result variants |
| `11-settings.png` | Settings at 1600x900 English |
| `12-aiming-1600x900-en.png`, `13-aiming-1280x800-ko.png` | Accepted-size Aim composition |
| `14-aiming-1024x768-en.png`, `15-stage-select-1024x768-en.png` | Narrow/aspect stress, not a new Windows support minimum |

## Remote itch static evidence

The public page returned HTTP 200 with title `Paint Mountain by
itchioprofile1351321`. Its HTML identifies an HTML5 game, a 640x360 pending frame,
`start_maximized: true`, and a click-to-load iframe placeholder. The deployed
Godot entry returned HTTP 200 with a canvas and this material configuration:

```text
canvasResizePolicy=2
focusCanvas=true
index.pck bytes=10,905,360
index.wasm bytes=39,513,091
```

All checked runtime endpoints returned HTTP 200 with correct material MIME
types: `index.html`, `index.js`, `index.pck`, `index.wasm`, and
`index.audio.worklet.js`.

| Artifact | Local bytes | Deployed bytes | Local/deployed SHA-256 |
| --- | ---: | ---: | --- |
| `index.js` | 279,815 | 279,815 | equal |
| `index.wasm` | 39,513,091 | 39,513,091 | equal |
| `index.audio.worklet.js` | 7,298 | 7,298 | equal |
| `index.pck` | 10,899,216 | 10,905,360 | different local rebuilds; deployed hash verified against CI |

Deployed PCK SHA-256:

```text
7594074F4AEE82BF53F96398549DC9C4C915BB4715355DE0CA34C8FBC6156BF5
```

GitHub Actions run `32135545451` recorded exactly the same PCK hash while
publishing version `alpha.9+2edb4c4`. This proves deployed artifact identity for
the baseline. It does not prove behavior inside a foreground browser.

## Limits and required follow-up

- No remote iframe keyboard/mouse interaction, fullscreen transition, save,
  audio unlock, console/network, background/resume, or frame trace is claimed.
- The in-app browser client failed before a browser session could be created.
  Direct alternate automation was not used as a policy bypass.
- Still screenshots cannot prove first-Fire input admission, Apex child creation,
  Burst paint acceptance, or temporal camera behavior. M6 tests and running
  sequences must prove them.
- A local PCK generated outside CI is not the deployed-identity source of truth.
  Future publication evidence must compare the remote PCK to the exact hash
  recorded by the authorized CI run.

The active ExecPlan remains `status: active` until M6–M9 and the real deployed
journey pass.
