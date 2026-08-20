---
type: plan
status: superseded
created: 2026-08-18
last_reviewed: 2026-08-20
scope: stabilize and publish the delivered six-stage three-ball target-band prototype: first input, special-ball lifecycle, responsive UI, foreground Web performance, and exact itch artifact verification
superseded_by: 2026-08-20-cross-stage-ui-theme.md
supersedes: 2026-08-13-queued-ball-paint-ownership.md
related:
  - ../PLANS.md
  - ../../docs/source-brief.md
  - ../../docs/design-spec.md
  - ../../docs/technical-architecture.md
  - ../../docs/test-checklist.md
  - ../Documentation.md
  - ../design/DESIGN.md
  - ../design/ART_DIRECTION.md
  - ../design/UIUX_GUIDELINES.md
  - ../design/VISUAL_REFERENCES.md
  - ../evidence/three-ball-target-band-prototype-2026-08-18/README.md
  - ../evidence/2026-08-20-local-itch-stability-audit/README.md
  - ../evidence/2026-08-20-m8-web-latency/README.md
---

# Three-Ball Target-Band Prototype Stabilization — Execution Contract

## Purpose

Fix the defects found in the published six-stage Red/Green target-band
prototype: the untouched first Space press must fire, special balls must have an
atomic and readable lifecycle, UI must remain bounded at supported desktop and
itch canvas sizes, and measured foreground Web stalls must be corrected at
their actual owner. Then verify production Windows/Web artifacts and, only
after explicit user approval, publish and exercise the exact itch artifact.

M1-M5 delivery history is intentionally absent from this active contract. Its
implemented truth lives in the canonical docs and `.agents/Documentation.md`;
its test, export, commit, CI, and Butler evidence lives in
`.agents/evidence/three-ball-target-band-prototype-2026-08-18/README.md`. The two
unfinished historical browser checks are carried forward under M9.

## Verified evidence and working model

- The public baseline is `alpha.9+2edb4c4`. GitHub Actions run `32135545451`
  published both itch channels. Its CI and deployed `index.pck` SHA-256 are both
  `7594074F4AEE82BF53F96398549DC9C4C915BB4715355DE0CA34C8FBC6156BF5`.
- The page uses itch click-to-load and `start_maximized`; the Godot shell uses
  `focusCanvas: true`. The host launcher gesture is not a Fire action.
- `GameplayScene` presents Aiming to the HUD before `CameraDirector` leaves Map
  Inspection. HUD focus remains on the interaction button; `AimInputController`
  correctly refuses Space while that secondary Button owns focus. The target,
  deal, and cannon launch path are already ready.
- Existing first-use warm-up creates render resources only. A live projectile
  still constructs physics material, collision shape, mesh, and intrinsic
  silhouette. Paint raster work and texture-upload fallback are synchronous
  contact-path candidates. A foreground trace must select the fix branch.
- Current accepted-size captures show no hard clipping, but Aim captions and the
  context legend have weak contrast. Fixed root offsets, an out-of-parent
  readiness label, a non-wrapping legend, and fixed Stage Select/Settings
  columns are fragile at stress sizes.
- Apex Split consumes the root followed by the camera, so the next physics frame
  returns to Aim instead of framing the family. Parent replacement can become
  partial after a child-spawn failure, and the zero-horizontal case can silently
  suppress a legal split.
- Impact Burst and Apex Split currently dispatch the same mechanism cue. Burst
  presentation/consumption is not tied to authoritative radial paint admission.
- Full audit facts and fifteen baseline captures are in
  `.agents/evidence/2026-08-20-local-itch-stability-audit/README.md`.

## Locked decisions and ownership

- `StageController` remains the sole owner of shot admission, deal/token
  progression, board/Finish readiness, and terminal state.
- `PaintSystem` remains the sole mutable paint/coverage authority. Canonical
  intent order and latest-writer Red/Green ownership do not change.
- A **root projectile** is generation zero. A **shot family** is that root plus
  derived children sharing its shot ID. `ProjectileManager` owns family
  membership and replacement; `CameraDirector` consumes typed presentation
  events and never decides gameplay state.
- An **effect request** follows a valid intrinsic trigger; **paint acceptance**
  is authoritative admission into the existing manager/PaintSystem path;
  **presentation** is the matching visual/audio cue. Rejected or duplicate work
  must not get a success cue.
- `HUDController` owns whole-HUD presentation and focus. Input adapters do not
  synthesize retries or weaken Fire admission.
- Preserve the approved Quiet Context system, Korean-first copy, 24 px logical
  safe margin, world-center visibility, sole-primary Fire action, and existing
  Theme/component owners. This task is responsive correction, not redesign.
- Performance markers are opt-in observation only. They cannot mutate gameplay
  or claim a rendered frame before `frame_post_draw`.
- No production dependency, new asset pack, threaded Web/PWA change, visibility
  change, or all-30-stage migration is in scope.

## Tasks

### M6 — Deterministic first input and special-ball lifecycle

- [x] **6.1 Close the Aiming focus race.** Derive Fire focus from the settled
  `(stage=AIMING, camera=AIMING, interaction=AIM_LOCKED)` presentation tuple.
  Defer exactly one transfer on initial Aiming entry and explicit return to Aim
  View. Test the real Gameplay/HUD path: one untouched Space produces one
  admitted root, one token/shot decrement, and Shot Follow; pointer Fire does
  not double-activate; deliberately focused secondary buttons retain native
  Space behavior.
- [x] **6.2 Add split-family observation.** After successful replacement,
  `ProjectileManager` publishes a typed event with shot ID and three admitted
  child identities. `CameraDirector` switches from the consumed root to a
  smooth bounded family composition, starts the existing hold on the first
  relevant valid child contact, and still honors early Return/Tab. Test root,
  family, contact, return, completion, and unrelated-family isolation.
- [x] **6.3 Make Apex replacement atomic.** Snapshot immutable parent identity,
  transform, velocity, and legal launch-forward basis; pre-admit/construct all
  children; then replace the parent as one manager-owned operation. On any
  failure admit none and keep the parent on an explicit Standard fallback.
  Test capacity edge, missing terrain, forced construction failure, signal
  order, exactly three children, no token cost/recursion, and zero-horizontal
  fan fallback.
- [x] **6.4 Align intrinsic acceptance and presentation.** Return an explicit
  manager admission result for Burst radial intent while preserving command
  order. Publish observation, distinct Burst/Split presentation, and Burst
  consumption exactly once only for the valid accepted sequence. Test accepted,
  duplicate, stale, wrong-surface, restart, and simultaneous-contact cases.

Gate: focused input, lifecycle, camera, paint-order, and effect tests pass. A
running Windows sequence proves untouched first Space and both special-ball
flows before UI restructuring.

### M7 — Container-owned responsive UI

- [x] **7.1 Add one safe-area gameplay composition.** Put top-left status/rule,
  top-right run/queue, bottom-center actions, bottom-right AimControls, and the
  lower legend into anchored Containers with a 24 px logical safe margin.
  Remove only fixed root offsets whose ownership moves to those groups.
- [x] **7.2 Repair component interiors.** Convert AimControls to consistent
  label/value/button rows; keep readiness copy inside ActionButtons; give
  ContextLegend bounded wrapping/priority behavior; make target/queue/result
  cards honor real minimum geometry. Test English/Korean longest copy, focus,
  disabled states, queue variants, signed roles, and Result variants.
- [x] **7.3 Make Stage Select and Settings responsive.** Replace fixed screen
  rectangles with safe-margin content regions. Preserve eight-card balance;
  keep Settings two-column when it fits and provide a bounded single-column/
  scroll fallback otherwise. Preserve actions and focus order.
- [x] **7.4 Correct only evidenced contrast failures.** Raise Aim caption and
  ContextLegend readability using existing Theme roles or quiet-panel language.

Validation sizes are 1280x720, 1280x800, 1366x768, 1600x900, and 1920x1080 in
English and Korean. Stress-check 1024x576, 1024x768, and restored 640x360; those
sizes must keep primary status/action bounded without redefining the
Windows-first minimum.

Gate: automated bounds/copy/focus contracts pass and the implementing agent
personally compares current running-game captures with the stored baseline for
every affected state. Headless checks alone cannot close this gate.

### M8 — Attribute and remove visible Web stalls

- [x] **8.1 Publish truthful latency boundaries.** Record input received, Fire
  accepted, root construction start/end, root admitted, first root frame
  presented, first contact, paint batch start/end, texture publish start/end,
  and effect frame presented. Rename the current muzzle-flash marker that
  falsely implies first paint visibility. Test ordering and once semantics for
  cold Standard/Burst/Split and one warm shot.
- [x] **8.2 Capture one foreground release-Web trace before optimization.** Use
  cold/warm stage entry, untouched first Space, first/second Standard, first
  Burst contact, and first Apex split/child contact. Correlate Chrome frame data
  with runtime markers and keep the worst frame.
- [x] **8.3 Apply only measured owner branches, then trace once more.** Available
  branches are shared immutable projectile resources; deterministic budgeted
  paint cursors; one dirty texture publication per rendered frame with the
  supported partial path; or exact missing-family render warm-up. Do not run a
  hidden physics shot or create parallel paint state.

Target on the same foreground setup: p95 <= 16.7 ms, p99 <= 33.3 ms, maximum <=
50 ms, and Fire-to-first-visible <= 100 ms. If an indivisible engine/GPU call
exceeds the target, record that exact boundary before proposing a budget or
fidelity change.

### M9 — Production, approval, and exact itch proof

- [x] **9.1 Run the final local gate.** Run `codebase-quality-auditor`, the full
  ordered suite once, `scripts/verify.ps1`, Windows/Web release exports, Web
  static validation, and separate Windows/Web captures. Update specs,
  `.agents/Documentation.md`, and `docs/test-checklist.md` with implemented
  truth only. Evidence names commit, Godot 4.7.1, renderer, locale, viewport,
  and build hash.
- [x] **9.2 Run local Web interaction.** Load `npjt-port-guard`, use the protected
  codex-lane server and approved browser path, then exercise launcher-equivalent
  activation, untouched Space, pointer Fire, resize/fullscreen, both special
  balls, pause/settings, save/reload, audio unlock, background/resume, and
  console/network health.
- [x] **9.3 Commit and stop for publish authorization.** Create coherent scoped
  commits with explanatory bodies, stop the task-owned local server, and do not
  push, merge, invoke the publication workflow, or change itch state without
  explicit approval in this turn.
- [ ] **9.4 Publish and prove the exact artifact after approval.** Invoke only
  the authorized workflow, require the deployed PCK to match the CI PCK hash,
  then repeat the M9.2 journey on the public page/iframe without changing
  visibility.

Gate: the exact fixed artifact, not only a version label or successful upload,
passes the real itch journey. Otherwise this plan stays active with the failing
boundary recorded.

## Focused validation

- Real-scene untouched-Space and pointer no-double-Fire regression.
- Split-family observation and atomic-replacement regression.
- Intrinsic effect acceptance/presentation ordering regression.
- Safe-area, component-minimum, locale-overflow, and focus matrix.
- Delivery-marker ordering and one bounded first-use Web scenario.
- Existing aim interaction, rapid fire, paint order, Burst, Apex, queue,
  target-band, camera, UI, stage runtime, save, agent parity, and legacy-stage
  checks affected by the edited owners.

After all implementation is stable, announce the broad gate and run once:

```powershell
pwsh -NoProfile -File scripts/test.ps1 -GodotPath $env:GODOT_BIN
pwsh -NoProfile -File scripts/verify.ps1 -GodotPath $env:GODOT_BIN
& $env:GODOT_BIN --headless --path . --export-release 'Windows Desktop' 'builds/windows/PaintMountain.exe'
& $env:GODOT_BIN --headless --path . --export-release 'Web' 'builds/web/index.html'
pwsh -NoProfile -File scripts/verify-web-release.ps1 -ReleaseDirectory builds/web
```

## Acceptance checks

- [x] Fresh Briefing-to-Aim accepts one untouched Space as exactly one legal
  Fire, without a terrain/canvas/control click; pointer Fire is also once-only.
- [x] Apex Split atomically produces exactly three Standard children, frames
  that family through a relevant child contact, and never changes simulation.
- [x] Impact Burst and Apex Split have distinct once-only cues that agree with
  accepted paint/lifecycle/observation state.
- [x] Gameplay HUD, Stage Select, Settings, Pause, and Result pass the viewport/
  locale matrix with bounded content, truthful focus, and readable contrast.
- [ ] Foreground local Web and post-deploy traces meet the budgets above, or the
  exact indivisible exception is documented before any contract change.
- [ ] The deployed PCK equals the approved CI artifact and the public journey
  passes input, resize/fullscreen, special balls, save, audio, resume, and
  console/network checks.

## Regression guards and contingencies

- Keep Fire admission, token consumption, stage transitions, paint authority,
  deterministic ordering, and human/agent parity out of HUD/camera/effects.
- If canvas focus still fails after the internal focus race is fixed, add only a
  project-owned shell bridge that gives the existing canvas `tabindex=0` and
  restores focus after engine start/window focus/visibility change. Do not add
  a second activation overlay or synthesize Fire.
- If any Apex child cannot be constructed, admit no children, present no split,
  and retain the parent as Standard. Never publish a partial family.
- If paint acceptance cannot be acknowledged synchronously, keep the intrinsic
  request pending at the existing owner boundary until accepted; do not infer
  success from the visual cue.
- At stress sizes, wrap or suppress only lowest-priority duplicate shortcut
  copy; never shrink accepted-size essential text or hide primary status/action.
- If the remote PCK differs from the authorized CI hash, stop remote claims and
  inspect the channel/version/CDN boundary. Do not republish without authority.

## Progress and checkpoints

- [x] 2026-08-20 discovery: traced the focus race, special-ball lifecycle,
  first-use/paint hot paths, fixed-layout owners, live itch shell, deployed PCK,
  and captured fifteen Windows baseline frames.
- [x] 2026-08-20 lifecycle repair: removed completed M1-M5 work and duplicate
  delivery history from this active plan; canonical docs and the existing
  prototype evidence remain their owners.
- [x] M6 — first input and special-ball lifecycle. Focused and adjacent tests,
  `scripts/verify.ps1`, and three personally inspected Windows/Compatibility
  captures pass; evidence is under
  `../evidence/2026-08-20-m6-input-special-lifecycle/README.md`.
- [x] M7 — responsive UI and contrast. Locale/viewport contracts, focused UI
  regressions, `scripts/verify.ps1`, and twelve personally inspected
  Windows/Compatibility captures pass; evidence is under
  `../evidence/2026-08-20-m7-responsive-ui/README.md`.
- [x] M8 — foreground Web attribution and measured correction. The blocking
  radius-14 Burst raster is now 33 deterministic slices with a 13.6 ms measured
  maximum; immutable projectile visuals put root construction at 1.0-1.3 ms
  and Apex replacement at 12.3 ms. Whole-window Chrome percentiles remain
  polluted by multi-second automation-window scheduling stalls, and the exact
  construction-to-`frame_post_draw` boundary is recorded under
  `../evidence/2026-08-20-m8-web-latency/README.md`.
- [ ] M9 — local gate, production-Web journey, scoped commit `16c9e96`, and
  task-owned server shutdown pass; explicit publish authorization and deployed
  itch proof remain. Evidence is under
  `../evidence/2026-08-20-m9-local-release/README.md`.

## Stop conditions and next step

Ask before adding/upgrading a dependency or asset pack, changing the token
horizon/kinds/channels/stage access, deleting legacy catalog owners, weakening a
performance/fidelity contract, force-pushing, publishing, or changing itch
visibility. Failed tests or difficult debugging are not stop conditions.

Request publish authorization. Mark this plan `done` only after all
non-conditional checks are supported by current evidence and the explicitly
authorized deployed artifact passes the remote journey.
