---
type: plan
status: active
created: 2026-08-18
scope: deliver, stabilize, and publish a six-stage Paint Mountain prototype with deterministic three-ball deals, red/green latest-writer paint ownership, signed target-band scoring, reliable first input, responsive UI, readable special-ball observation, and truthful human/agent/UI parity
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
  - ../evidence/2026-08-20-local-itch-stability-audit/README.md
  - 2026-08-11-web-runtime-responsiveness.md
---

# Three-Ball Red/Green Target-Band Prototype — Execution Contract

## Purpose

Replace the current scalar blue-coverage rule in the first six stages with one
planning system: a finite constrained-random deal of Standard, Impact Burst,
and Apex Split balls; Red and Green latest-writer paint ownership; and a signed
Paint Score that must finish inside an inclusive target band. Ship the six-stage
prototype through the existing Windows and single-thread Web export paths, push
the task-owned commits, and verify the resulting itch.io alpha build.

This plan is the executable refinement of
`C:\Users\BK\Downloads\paint-mountain-three-ball-red-green-target-band-plan.md`.
The user's 2026-08-18 instruction approves this direction and supersedes the
2026-08-14 hold recorded in the special-ball handoff. Record that bounded
authority change in `docs/source-brief.md` before runtime integration.

The user reopened this plan on 2026-08-20 after exercising the published itch
build and reporting a first-Fire click dependency, visible stutter, layout and
clipping defects, and special-ball interaction problems. Those reports concern
the same six-stage prototype and its unfinished Web gate, so this document is
extended in place rather than creating a second active ExecPlan. Completed M1–M5
history remains evidence; M6–M9 below are the current stabilization contract.

## Plan validation and scope correction

The supplied design is coherent, but its document was not executable as-is:

- `status: proposed` is not a valid lifecycle state.
- It simultaneously says to ship a six-stage prototype, not to migrate all
  thirty stages in the first pass, and later lists catalog-v11/all-stage work.
- The all-stage work is conditional on human prototype approval and one witness
  clear for each of 96 generated deals. Those facts do not exist at baseline
  and must not be fabricated or replaced by unit tests.
- “Same input on every platform” needs an explicitly versioned integer PRNG;
  Godot's implementation-specific random stream is not a durable cross-version
  product contract.
- “New Deal selects another validated seed” cannot be a release guarantee until
  a validated seed bank exists. The prototype therefore uses generated deals
  that pass structural constraints, labels the feature as prototype behavior,
  and records seed/inputs/result for later physical validation.
- The prior queued-ball plan is already `superseded`; no further lifecycle edit
  to it is needed.

This active plan therefore owns only the six-stage prototype, its compatibility
with the remaining legacy catalog entries, production exports, and itch alpha
verification. Catalog v11, all-thirty-stage glyph retirement, population
playtest targets, and a validated-seed-bank guarantee are a later plan whose
activation requires prototype evidence and user approval. No task below may
silently expand into that rollout.

## Verified baseline and evidence

### Local authority and implementation

- Baseline is clean `master`/`origin/master` at `155c401`.
- `scripts/verify.ps1` passes with Godot `4.7.1.stable` before changes.
- `StageController` currently owns stage state, root-shot admission, restart,
  timeout, Finish, and terminal sequencing; it has no deal or band rule.
- `PaintSystem` owns one authoritative L8 strength mask and physical target-area
  metric; it has no owner channel. It must evolve in place, not gain a parallel
  scoring mask.
- `ProjectileManager` already owns deterministic paint-intent ordering, two
  initial-flight roots, 21 residents, and parent-to-child replacement.
- Existing Burst/Splitter mechanisms provide reusable command/spawn behavior,
  but the new balls must not activate hidden glyphs.
- Save schema v5, agent/attempt schemas, HUD, result ranking, and active specs
  all expose scalar coverage and require coordinated migration.
- Catalog v10 contains 30 generated terrains with glyph data. The prototype
  must preserve hydration for stages 7–30 while stages 1–6 use the new rule.

### External platform evidence

- Godot 4.7 Web supports only the Compatibility renderer and requires WebGL 2;
  the current project already uses Compatibility.
- The current Web preset is single-threaded, adaptive, and non-PWA, which avoids
  SharedArrayBuffer/COOP/COEP requirements and matches itch.io's broadest path.
- itch HTML builds require `index.html`, relative exact-case references, and
  documented file/path/size limits. The existing validator checks those facts.
- Butler can push the Web directory and Windows package, but the html5 upload
  still needs account-side “Playable in browser”/HTML project settings.
- Local export checks cannot prove CDN headers, iframe launch, channel state,
  or account visibility. Those require remote post-upload verification.

Primary sources:

- https://docs.godotengine.org/en/4.7/tutorials/export/exporting_for_web.html
- https://docs.godotengine.org/en/4.7/classes/class_editorexportplatformweb.html
- https://itch.io/docs/creators/html5
- https://itch.io/docs/butler/pushing.html

The evidence preserves the current no-thread Web pipeline. PWA, threaded Web,
new dependencies, and a new deployment service are rejected as unnecessary.

### 2026-08-20 reopened stability audit

The local and remote inspection record is
`.agents/evidence/2026-08-20-local-itch-stability-audit/README.md`. The audit
inspected the current source and tests, fifteen Windows/Compatibility runtime
captures, the public itch page, the deployed iframe shell and static files, the
publishing workflow, and the archived foreground-Web measurements. It did not
complete interactive remote input or frame profiling because the approved
browser-control connection was unavailable in this session; this is an explicit
acceptance gap, not evidence that the deployed runtime is healthy.

| Concern | Confirmed current behavior and owner | Severity | Locked correction | Task IDs |
| --- | --- | --- | --- | --- |
| First Fire needs a click | `GameplayScene` publishes `AIMING` to HUD before `CameraDirector` has changed from Map Inspection to Aim View. `HUDController.show_state()` therefore leaves focus on the camera-mode button. The later camera signal updates visibility but does not refocus Fire, and `AimInputController` deliberately refuses Space while another Button owns focus. The target and deal are already valid; terrain selection is not the gate. | P1 | Resolve the effective camera/interaction presentation first, then defer one focus transfer to Fire. One Space press from the untouched default aim must admit exactly one root. Keep the itch launcher click distinct from in-game canvas/control focus. | 6.1, 9.2 |
| Browser activation boundary | The public itch page is live, starts from a 640x360 click-to-load placeholder with `start_maximized: true`, and loads a Godot shell with `focusCanvas: true`. No project-owned custom shell is configured. | P1 validation gap | First fix the deterministic in-game focus race. Do not add another activation overlay. If the post-fix iframe still lacks canvas focus after the itch launcher gesture, use the predetermined minimal custom-shell focus bridge in the contingency table. | 6.1, 9.2 |
| First-shot and contact hitch | The 2026-08-11 itch baseline recorded an 849.8 ms first-shot frame and eighteen frames over 20 ms. The current warm-up renders materials and effects but intentionally does not create live rigid-body/collision resources. Live spawn still allocates physics material, shape, mesh, and special silhouettes; paint rasterization and a possible full texture-upload fallback remain synchronous hot-path candidates. Current three-ball Web timing has never been measured at normal foreground refresh. | P1 | Add truthful input/spawn/render/paint/upload markers, profile one cold and one warm sequence, then apply the predetermined fix for the measured owner without simulating a hidden shot or duplicating paint state. Retain the existing frame and response budgets. | 8.1–8.3 |
| HUD and screen layout | Accepted-size captures at 1280x720, 1280x800, 1366x768, and 1600x900 show no hard clipping, but Aim labels and the context legend have weak contrast. A 1024x768 stress capture remains functional but shrinks text and exposes unbalanced fixed-column composition. Gameplay HUD, AimControls, Stage Select, Settings, and several child components use baseline-fixed offsets; the readiness label is positioned outside its parent and the legend is a non-wrapping row. | P2 | Preserve the current visual system, but replace baseline composition with safe-area edge groups and container-owned component interiors. Keep primary actions/status readable at accepted sizes and bounded at Web stress sizes. Raise only the deficient caption/legend contrast. | 7.1–7.4 |
| Apex Split observation | `CameraDirector` follows only the root. Apex Split consumes that root before contact, so the next physics update returns to Aim View and none of the three children can trigger the impact hold. This conflicts with the source brief requirement to widen the camera when a ball splits and keep important children visible. | P2 | Publish a typed split-family presentation event from `ProjectileManager`; `CameraDirector` switches to a bounded wide family composition until the first relevant child contact/hold or early return. Simulation never depends on camera state. | 6.2 |
| Apex Split replacement integrity | The manager deactivates the parent and then reads its fields while spawning children one by one. Deferred free makes this usually work, but a non-capacity spawn failure can leave a consumed parent and a partial family. Near-zero horizontal velocity can also resolve the apex without children. | P2 | Snapshot immutable replacement inputs first, pre-admit the complete family, and perform an all-or-none replacement. Use the stored legal launch-forward basis as the degenerate fan fallback. | 6.3 |
| Special-ball presentation and Burst acceptance | Both intrinsic ball effects dispatch to the generic mechanism burst/audio regardless of `effect_id`. Impact Burst emits its visible effect and consumes itself without using the radial-intent validity result or a paint-queue acknowledgment. | P2 | Give Impact Burst and Apex Split distinct existing-style presentation dispatch. Make valid-contact intent admission explicit and prove effect/observation/consumption occur exactly once with accepted authoritative paint work; reject stale/duplicate work without a false success presentation. | 6.4 |
| Deployment identity | The public page reports `alpha.9+2edb4c4`; all static endpoints return 200. The deployed `index.pck` SHA-256 exactly matches Actions run `32135545451`, and the JS/Wasm/worklet match the local engine artifacts. A separately generated local PCK is not byte-identical, so channel labels alone are insufficient for future verification. | P2 release control | Record the CI PCK hash and version, compare the remote PCK to that exact published hash, and keep build evidence separate from interactive iframe evidence. | 9.1–9.3 |

### Domain and ownership alignment for stabilization

- **Host launch activation** is the outer itch click that creates/maximizes the
  iframe. It is not a game action and must not consume Fire.
- **Game input focus** is canvas plus Godot GUI focus after the iframe starts.
  `HUDController` owns focus presentation; `StageController` still owns whether
  Fire is legal, and `AimInputController` remains the human shortcut adapter.
- **Root projectile** is the generation-zero admitted ball. **Shot family** is
  that root plus derived children sharing the same shot ID. ProjectileManager
  owns family membership and replacement; CameraDirector consumes only typed
  presentation signals and never calculates gameplay outcomes.
- **Effect request** is a valid intrinsic-ball request; **paint acceptance** is
  authoritative admission by the existing PaintSystem path; **presentation** is
  effect-specific visual/audio feedback. These may be staged, but the player and
  attempt record must not receive a success cue for rejected or duplicate work.

## Locked domain language and invariants

- **Ball token**: immutable pair `(kind, channel)`, where kind is Standard,
  Impact Burst, or Apex Split and channel is Red or Green.
- **Deal**: the immutable token array generated from stage ID, deal seed,
  maximum shots, and `BallDealProfile`.
- **Visible horizon**: current token plus the next two. Later tokens are private
  to runtime/attempt evidence and never enter human or public-agent state.
- **Paint ownership**: one current value per eligible pixel: Unpainted, Red, or
  Green. Latest valid command owns the pixel; strength remains monotonic.
- **Coverage snapshot**: immutable physical target-area percentages for Red,
  Green, and Total plus the authoritative paint checksum. It is measurement,
  not a clear decision.
- **Paint Score**: `red_percent * red_weight + green_percent * green_weight`.
- **Target band**: inclusive `[target_min, target_max]` with `min < max`.
- **Board quiet**: no initial-flight root, no moving resident, no queued manager
  paint intent, and no pending PaintSystem work.
- **Finish ready**: run started, score in band, board quiet, and no terminal
  transition in progress. `StageController` alone decides this state.

Preserve the stationary cannon, pre-shot yaw/elevation/power planning, no
in-flight steering, 60 Hz fixed physics, existing time scale, physical-area
scoring denominator, persistent resident balls, all-open stage selection, and
Windows/Web delivery.

## Locked product contracts

### Ball and paint rules

- Roster is exactly Standard, Impact Burst, and Apex Split. Do not add Hold,
  skip, swap, draft, inventory, upgrades, shops, or a fourth kind.
- Channels are exactly Red and Green. Projectile material, trail, impact,
  radial paint, split children, queue token, observation, and score channel
  must agree. Use a secondary pattern/letter cue so hue is never the only cue.
- Incoming paint owns each pixel once it reaches the existing painted threshold,
  even when its strength is below an existing coat. Strength becomes
  `max(existing, incoming)`; ownership becomes the incoming channel.
- The authoritative paint buffer is one interleaved/multi-channel representation
  owned by `PaintSystem`. Maintain rebuildable Red/Green area counters from it.
- Canonical command order resolves simultaneous writes and must be included in
  the checksum: same physics/command sequence means same final owner.

### Score, band, stars, and terminal rule

- Signed weights are only `-1`, `0`, or `+1` and use the five reusable rules:
  `both_add`, `green_add_red_subtract`, `red_add_green_subtract`,
  `green_add_red_neutral`, and `red_add_green_neutral`.
- One star means score is in band. Two stars require distance from center no
  more than 50% of half-width; three stars require no more than 25%.
- Finish is enabled only at Finish ready. Unused shots are permitted.
- Queue exhaustion auto-finishes at the next board-quiet state. Timeout commits
  accepted paint and clears only if the final score is in band.
- Result ranking is clear first, then smaller absolute center error, then the
  existing stable tie breakers. Higher raw coverage is no longer intrinsically
  better for prototype stages.

### Intrinsic ball behavior

- Standard retains current first-flight physics and continuous own-channel
  impact/contact trail.
- Impact Burst, on first valid terrain-top contact, commits ordinary impact,
  submits one same-channel radial stamp of radius `14.0`, emits its effect, and
  consumes itself before any rolling trail.
- Apex Split triggers on the first positive-to-nonpositive vertical-velocity
  crossing before valid terrain contact, generation zero only. It consumes the
  root without mid-air paint and creates three non-recursive Standard children
  with the same shot/channel, generation one, deterministic yaw fan
  `[-12°, 0°, +12°]`, horizontal speed `0.92`, upward addition `1.5 m/s`, and
  existing generation-one physical/paint scale `0.78`.
- If Apex Split touches valid terrain before apex, it becomes Standard and may
  never split after bounce. A split child can never split.
- Prediction remains initial-flight only. Apex Split adds one apex marker;
  child paths, post-contact travel, score delta, and hidden deal remain absent.

### Deal and retry rule

- Queue length equals `maximum_shots`. Successful generation-zero admission
  consumes one shot/token exactly once; rejection and children consume none.
- Implement a small explicitly versioned integer PRNG with fixed unsigned
  arithmetic. Generator inputs are `(stage_id, deal_seed, maximum_shots,
  profile)` and its test vectors are platform-independent.
- For at least four shots, reserve final Red Standard and Green Standard tokens
  in deterministic shuffled order. Generate the prefix with a maximum of 128
  attempts, then use a deterministic valid fallback.
- Prefix constraints: allowed kinds/channels only; both colors when length is
  at least two; no three consecutive same color or kind; at most two Burst and
  two Split roots; at least one Standard when length is at least three; and
  `ordinary_roots + 3 * split_roots <= 21`.
- Retry Same Deal preserves geometry/rule/seed/order. New Deal advances to the
  next structurally valid deterministic seed. Both clear paint, projectiles,
  cursor, observations, effects, and timer through the authoritative restart.
- Full deal may be in debug/attempt evidence. UI, accessibility, tooltips,
  prediction, logs exposed to the public agent, and agent observations expose
  only the three-token horizon.

### Six prototype stages

Map prototype profiles onto catalog stages 1–6 while preserving their terrain:

| Stage | Kinds | Weights (Green/Red) | Shots | Band |
| --- | --- | ---: | ---: | ---: |
| P1 | Standard | `+1 / +1` | 4 | `7–11` |
| P2 | Standard, Burst | `+1 / +1` | 5 | `9–13` |
| P3 | Standard, Split | `+1 / +1` | 5 | `10–14` |
| P4 | All three | `+1 / -1` | 6 | `6–10` |
| P5 | All three | `-1 / +1` | 6 | `7–11` |
| P6 | All three | `+1 / 0` | 6 | `8–12` |

Stages 7–30 retain their v10 scalar/glyph behavior in this prototype build.
UI, persistence, observations, and results must truthfully branch on stage rule;
they must not present legacy stages as target-band stages. Stage selection must
visibly identify stages 1–6 as the new prototype set without locking others.

## Ownership boundaries

| Owner | Owns | Must not absorb |
| --- | --- | --- |
| Typed ball/score/deal Resources | stable IDs, validation, tuning, pure calculations | runtime cursor, pixels, UI |
| `StageController` | deal seed/cursor, accepted consumption, retry mode, score snapshot, Finish readiness, terminal reason | projectile physics, pixel writes, layout |
| `PaintSystem` | one owner/strength buffer, command application, shader texture, physical coverage snapshot/checksum | band decision, star rule, UI copy |
| Projectile behavior components | one bounded trigger and effect each | stage rules, queue generation, HUD |
| `ProjectileManager` | generic root/child admission, family capacity, board activity, deterministic intent routing | per-stage score or hidden queue policy |
| HUD child components | render supplied band/queue/result state and emit narrow intents | singleton reads, score calculations |
| Save/GameState | v6 migration and stage-rule-aware best records | paint calculation or stage mutation |
| Agent/attempt owners | same action boundary and visible observation as human; full deal only in private attempt evidence | alternate simulation or hidden-token leak |

## Tasks

### M1 — Authority, data, and score contracts

- [x] Append the approved six-stage direction and deferred all-stage gate to
  `docs/source-brief.md`; reconcile active design/architecture language.
- [x] Add typed BallKind, PaintChannel, BallToken, BallDealProfile,
  ColorScoreRuleData, TargetBandData, coverage snapshot, and score snapshot
  contracts with validation and pure unit tests.
- [x] Add the deterministic integer PRNG/deal generator, correction reserve,
  bounded fallback, capacity checks, cross-platform test vectors, and 16
  structurally valid seed fixtures per prototype stage.

Gate: pure tests prove score signs/overwrite deltas, inclusive band/star edges,
generator reproducibility, constraints, fallback termination, and no hidden
state mutation.

### M2 — Authoritative paint and intrinsic projectiles

- [x] Evolve `PaintSystem` and terrain shader to one owner-aware representation;
  carry channel through all paint commands and publish immutable percentages.
- [x] Include owner transitions in deterministic command ordering/checksum and
  prove same-channel/overwrite/threshold/non-target semantics.
- [x] Carry token identity through root launch and residents; render matching
  Red/Green projectiles and trails.
- [x] Implement narrow Impact Burst and Apex Split behaviors, authoritative
  pre-contact apex event, child inheritance, and capacity/non-recursion guards.
- [x] Add only focused owner/order/behavior/family tests while building, then run
  `scripts/verify.ps1` once this batch stabilizes.

Gate: one authoritative buffer drives both rendered ownership and coverage;
each behavior triggers at most once and cannot mutate shots/deal directly.

### M3 — Stage rule, retry, persistence, and parity

- [x] Extend StageData with an explicit legacy-or-target-band rule boundary and
  materialize the six prototype profiles without changing stages 7–30.
- [x] Make `StageController` own deal generation/cursor, three-token public
  snapshot, root admission, Same/New Deal restart, quiet readiness, exhaustion,
  timeout, score/star/result evaluation, and terminal reason.
- [x] Update cannon/prediction cache identity and Apex marker without exposing
  child paths or hidden tokens.
- [x] Migrate save schema v5 to v6. Archive v5 scalar bests as legacy; never
  infer a target-band clear. Store clear-first, center-error-aware results.
- [x] Version shot/attempt observations and agent API for kind, channel, visible
  horizon, seed where authorized, score/coverage deltas, effects, and retry
  actions. Keep human/agent authority identical.
- [x] Add focused queue progression, rejection, exhaustion, quiet-state,
  timeout, retry, migration, observation, and hidden-tail tests.

Gate: a scripted attempt can play/retry a prototype stage deterministically,
while a legacy stage still starts, scores, finishes, saves, and observes under
its existing rule.

### M4 — Level-3 player flow and six-stage calibration

- [x] Replace the scalar prototype HUD with a reusable target-band meter showing
  fixed band/current marker and visible `+`, `−`, or `0` channel badges.
- [x] Add a quiet right-edge queue rail: 52 px NOW token and two 36 px NEXT
  tokens, kind silhouette plus Red/Green pattern/letter. Show in Briefing/Aim/
  Map; hide in Shot Follow and terminal; omit empty tail slots.
- [x] Add first-introduction Briefing copy, Apex marker, disabled Finish truth,
  Same Deal/New Deal result actions, and Clear/Failed result metrics.
- [x] Create shared non-symbolic Standard/Burst/Split silhouettes for projectiles
  and queue icons. Preserve center-world visibility and existing Quiet Context.
- [x] Update Stage Select to identify the six prototype stages and their
  unordered allowed kinds/rule without exposing deals. Retain truthful legacy
  glyph descriptions for stages 7–30 until the later migration.
- [x] Add English/Korean localization and focused component/state tests.
- [x] Exercise 16 seeds per prototype stage through structural/runtime smoke;
  record actual playable witness attempts where achieved, but do not claim the
  later 96-deal clearability/human-rate gate.
- [x] Capture and personally inspect running-game Briefing, Aim, Map, Shot
  Follow, late queue, Clear, Failed, and Stage Select in English/Korean at
  1280×720, 1600×900, and 1920×1080. Correct clipping, overlap, color-only
  meaning, stale state, and center obstruction.

Gate: all six stages are playable with the new loop; all supported desktop
sizes and both languages remain readable; stages 7–30 remain truthfully usable.

### M5 — Final audit, compact performance, production, and publication

- [x] After feature completeness, run `codebase-quality-auditor`; make only
  small task-owned corrections for competing owners, catch-alls, contract drift,
  reachable failures, and missing validation.
- [x] Run the broad functional suite once. Stop at the first shared material
  failure, repair, and rerun only the affected gate before one final suite.
- [x] Only now run one compact performance scenario: six representative roots
  including two Apex Split families on a painted prototype stage, record physics
  frame health, resident peak (must be `<= 21`), paint queue drain, partial
  upload cadence, restart completion (`< 1 s` target), and no unbounded growth.
- [x] Build production-style Windows and Web exports with Godot 4.7.1. Validate
  Web exact-case references, required artifacts, itch file/path/size limits,
  single-thread mode, and launch the Windows build.
- [ ] Serve the Web build through the repo's protected codex-lane workflow,
  browser-smoke startup/input/canvas/fullscreen/save/audio, and retain captures.
- [x] Update implemented truth, design/technical specs, and test checklist with
  exact scope, evidence, legacy-stage boundary, and deferred rollout.
- [x] Commit coherent task-owned changes with explanatory bodies; push the
  branch. Use the existing release workflow or an intentional fast-forward of
  `master` only after all local gates pass.
- [x] Confirm the GitHub workflow and Butler pushes use the same commit-derived
  version for `html5` and `windows-alpha`.
- [ ] Verify itch project kind/HTML5 play flag without changing visibility,
  then remotely smoke the iframe/CDN build.

Gate: local and remote artifacts run the same committed rules. A missing secret,
account permission, or itch setting is reported as an external blocker rather
than disguised as success.

The two unchecked M5 browser items are historical delivery gaps. Do not close
them against `alpha.9+2edb4c4`; M9 carries them forward and must exercise the
stabilized revision.

### M6 — Make first input and special-ball lifecycle deterministic

Goal: the untouched default aim accepts the first keyboard Fire, and intrinsic
balls complete one atomic, readable lifecycle.

Source owners: `src/gameplay/gameplay_scene.gd`, `src/ui/hud_controller.gd`,
`src/input/aim_input_controller.gd`, `src/projectile/projectile_manager.gd`,
`src/projectile/paint_projectile.gd`, ball behavior components,
`src/camera/camera_director.gd`, `src/effects/presentation_effects.gd`, and their
focused tests.

- [ ] **6.1** Close the Aiming presentation/focus race.
  - Change: make the HUD derive focus from the effective tuple `(stage=AIMING,
    camera=AIMING, interaction=AIM_LOCKED)` after camera signals have settled.
    Defer exactly one Fire focus transfer on initial Aiming entry and on explicit
    return to Aim View. Do not make prediction readiness or terrain selection a
    Fire precondition, and do not let a focus change call StageController.
  - Test: instantiate the real Gameplay/HUD path, enter Aiming from Briefing,
    send one Space event without any pointer event, and assert one accepted Fire,
    one generation-zero root, one token/shot decrement, and Shot Follow. Repeat
    with mouse Fire and assert no double activation. Preserve Space activation
    for deliberately focused secondary buttons.
  - Accept: after the itch host launch gesture, the first in-game Space press
    from the authored default aim fires exactly once without a canvas, terrain,
    or Fire-button click.
- [ ] **6.2** Add split-family observation without changing game rules.
  - Change: after a successful Apex replacement, ProjectileManager publishes a
    typed presentation event containing shot ID and the three admitted child
    identities. CameraDirector stops tracking the consumed root and frames the
    bounded family with a smooth wide composition. The first valid child terrain
    contact starts the existing hold; early Return/Tab still restores Aim View.
  - Guard: do not average arbitrary resident balls, expose steering, change
    StageController state, or let CameraDirector decide family membership.
  - Test: replace the stale assertion that children never affect root follow
    with root-before-split, three-child wide framing, first-child contact hold,
    early return, family completion, and unrelated-family isolation cases.
  - Accept: Apex Split never snaps straight to Aim View at the split and all
    three children remain materially visible through the readable outcome.
- [ ] **6.3** Make Apex replacement atomic and total for legal shots.
  - Change: snapshot parent data, position, shot/channel identity, and launch-
    forward basis before mutation. Validate capacity and construct all three
    detached children before publishing replacement; then consume the parent
    and admit the full child set as one manager-owned operation. On any failure,
    admit none and leave the parent on its explicit Standard-fallback path.
  - Test: capacity edge, missing terrain, forced child-construction failure,
    signal ordering, exactly three children, no token consumption, no recursive
    split, and near-zero-horizontal fan fallback.
  - Accept: there is no reachable consumed-parent/partial-family state and no
    legal Apex token silently loses its split.
- [ ] **6.4** Align intrinsic effect acceptance and presentation.
  - Change: preserve canonical paint ordering while returning an explicit
    manager-level admission result for the Burst radial intent. Publish effect
    observation and consume the Burst exactly once only for its valid accepted
    contact sequence. Dispatch Impact Burst and Apex Split to distinct effect
    methods and cues inside the existing presentation owner.
  - Test: accepted, duplicate, stale, wrong-surface, restart, and simultaneous-
    contact cases; assert paint/effect/observation/terminal ordering and channel
    identity. Render-capture each effect at its trigger, not only pre-trigger
    midflight silhouettes.
  - Accept: every accepted special effect has one matching paint/lifecycle event
    and a visually distinguishable cue; rejected work has none.

Gate: focused input, lifecycle, camera, paint-order, and effect tests pass. A
running Windows sequence with input/event evidence proves the untouched first
Space and both special-ball flows before UI restructuring begins.

### M7 — Replace fragile fixed layout with container-owned composition

Goal: preserve the approved visual hierarchy while making component interiors
and screen-edge groups resilient to desktop and itch canvas sizes.

Source owners: `scenes/ui/hud/hud.tscn`, HUD components and scripts,
`scenes/ui/screens/stage_select.tscn`, `scenes/ui/screens/settings.tscn`, shared
Theme resources, and targeted UI/layout tests. This is a Level-3 UIUX change;
use current captures as the visual reference and do not redesign the palette,
typography, iconography, or information architecture.

- [ ] **7.1** Introduce one 24 px safe-area gameplay composition.
  - Change: group top-left status/interaction/target rule, top-right run/queue,
    bottom-center Fire/return/briefing actions, bottom-right AimControls, and the
    bottom legend under anchored Containers. Remove only the root fixed offsets
    whose ownership moves into those groups. Keep world center and the cannon-
    mountain composition unobstructed.
  - Test: numeric rect assertions for overlap, bounds, safe margins, visibility,
    and state transitions in Briefing, Aim, Map, Follow, Pause, and Result.
- [ ] **7.2** Rebuild component interiors that can clip or drift.
  - Change: convert AimControls to label/value/button rows with consistent
    minimums and baselines; keep the readiness label inside ActionButtons; give
    ContextLegend a bounded wrap/priority policy; let target/queue/result cards
    report and receive their real minimum geometry. No child may be assigned a
    smaller rect than its content contract.
  - Test: English/Korean longest-copy fixtures, disabled/readiness copy, visible
    focus, three-token/one-token queue, signed target-band roles, and Result
    variants at every validation size.
- [ ] **7.3** Make Stage Select and Settings use responsive content regions.
  - Change: replace fixed left/right screen rectangles with safe-margin container
    composition. Stage Select keeps the eight-card grid and selected-stage detail
    balanced; Settings keeps two columns when they fit and a bounded single-
    column/scroll fallback when they do not. Preserve all current actions.
  - Test: navigation/focus order, longest localized stage metadata, settings
    controls, dropdowns, and primary-button visibility without overlap or crop.
- [ ] **7.4** Correct only evidenced contrast failures.
  - Change: raise Aim caption and ContextLegend contrast against bright sky and
    dark terrain using existing Theme roles or the existing quiet panel language.
    Preserve restrained disabled controls and keyboard focus distinction.
  - Accept: primary labels, values, and contextual shortcuts remain readable in
    inspected runtime captures without adding decorative copy.

Validation matrix:

- Accepted desktop/Web sizes: 1280x720, 1280x800, 1366x768, 1600x900, and
  1920x1080, in English and Korean.
- Web stress sizes: 1024x576, 1024x768, and itch restored embed 640x360. At
  stress sizes the test requires visible primary action/status and bounded
  content; it does not redefine the Windows-first minimum or require mobile UI.

Gate: automated rect/copy contracts pass and the implementing agent inspects
new running-game captures beside the 2026-08-20 baseline for every affected
screen/state. Headless layout checks alone cannot close this gate.

### M8 — Attribute and remove user-visible Web stalls

Goal: replace misleading first-use markers with frame-correlated evidence and
remove the measured cold owner without changing physics, paint authority, or
visual meaning.

Source owners: `src/delivery/runtime_delivery_telemetry.gd`, gameplay/cannon/
projectile/paint/effect owners identified by markers, existing warm-up, one
bounded performance harness, and Web evidence.

- [ ] **8.1** Publish truthful latency boundaries.
  - Change: distinguish input received, Fire accepted, root construction start/
    end, root admitted, first root frame presented, first contact, paint batch
    start/end, texture publish start/end, and effect frame presented. Rename the
    current marker that labels muzzle flash as first paint visibility. Markers
    remain local/opt-in JSON lines and cannot mutate gameplay.
  - Test: ordering/once semantics for cold Standard, Impact Burst, Apex Split,
    and one warm follow-up shot; no marker claims renderer presentation before
    `frame_post_draw`.
- [ ] **8.2** Capture one foreground Web trace before optimization.
  - Change: on the local release Web build, record cold/warm stage entry, initial
    Aim, first untouched Space, first/second Standard, first Burst contact, and
    first Apex split/child contact. Correlate Chrome Performance/rAF/LoAF data
    with runtime markers; record the worst individual frame instead of averaging
    it away.
  - Accept: the trace selects one or more predetermined owner branches below;
    an unmeasured cache or broad rewrite is not permitted.
- [ ] **8.3** Apply the measured owner branch and rerun once.
  - Spawn allocation branch: prepare/share immutable physics material, shape,
    mesh, and special-silhouette resources by `(kind, channel, generation)` before
    readiness; live bodies remain real and no hidden physics shot is simulated.
  - Paint CPU branch: drain radial/sweep raster work through a deterministic,
    budgeted cursor while preserving canonical command order; Board quiet waits
    for completion and PaintSystem remains the sole mask/coverage owner.
  - Texture branch: coalesce dirty publication to at most one upload per rendered
    frame and use the supported partial path; if the Web backend forces a full
    upload, record that exact fallback and prevent duplicate full uploads.
  - Shader/effect branch: extend the existing render-only warm-up with the exact
    missing material family. Do not add physics, paint, signals, or shots.
  - Accept: first and second representative shots both reach p95 at most 16.7 ms,
    p99 at most 33.3 ms, maximum at most 50 ms, and Fire-to-first-visible-response
    at most 100 ms on the same foreground Chrome/Windows reference setup.

Gate: one after-trace meets the budgets or records the exact indivisible Godot/
GPU call that exceeds them and triggers the existing escalation rule. Do not run
repeated broad performance loops during M6–M7.

### M9 — Production verification, publish approval, and itch proof

Goal: prove the fixed committed revision locally, publish it only with explicit
user authorization, and then prove the exact deployed revision interactively.

- [ ] **9.1** Run the final local functional and production gate.
  - Change: after M6–M8 stabilize, run `codebase-quality-auditor`, the complete
    ordered suite once, `scripts/verify.ps1`, Windows/Web release exports, Web
    static validation, and separate Windows/Web runtime captures. Update active
    specs, `.agents/Documentation.md`, and `docs/test-checklist.md` only with
    implemented truth and reconcile their stale prototype/legacy wording.
  - Accept: all local gates pass from a clean task-owned commit and evidence names
    the commit, Godot 4.7.1, renderer, locale, viewport, and build hash.
- [ ] **9.2** Run local Web interaction and focus/performance smoke.
  - Change: use the protected npjt codex-lane server path and the approved browser
    workflow. Exercise launcher-equivalent canvas activation, untouched first
    Space, mouse Fire, resize/fullscreen, both special balls, pause/settings,
    save/reload, audio unlock, background/resume, and console/network health.
  - Accept: no second canvas/control click, double Fire, clipping, tofu, stale
    focus, stuck key, silent unlocked audio, save loss, or material console error.
- [ ] **9.3** Commit, request publish authorization, and verify itch.
  - Change: create coherent scoped commits with explanatory bodies. Stop for the
    user's explicit approval before push/merge/workflow publication. After the
    authorized workflow succeeds, record its version and CI `index.pck` SHA-256,
    fetch the deployed PCK and require an exact hash match, then repeat the full
    M9.2 journey on the public itch page and iframe. Do not change visibility.
  - Accept: the page, `html5`, and `windows-alpha` identify the same committed
    revision; remote input/layout/special-ball/performance evidence is separate
    from local evidence and all open M5 browser checks are closed.

Gate: the exact fixed artifact, not only a successful upload or version label,
passes the real itch journey. Otherwise keep this plan active and report the
failing boundary.

## Focused tests to create or update

- `color_score_rule_test.gd`
- `target_band_result_test.gd`
- `paint_ownership_test.gd`
- `paint_owner_command_order_test.gd`
- `ball_deal_generation_test.gd`
- `ball_queue_progression_test.gd`
- `queue_retry_seed_test.gd`
- `impact_burst_ball_test.gd`
- `apex_split_ball_test.gd`
- `stage_finish_readiness_test.gd`
- `save_v6_migration_test.gd`
- `agent_visible_queue_test.gd`
- `hud_target_band_truth_test.gd`
- real-scene untouched-first-Space and pointer no-double-Fire regression
- split-family observation and atomic-replacement regression
- intrinsic effect acceptance/presentation ordering regression
- safe-area/component-minimum/locale-overflow layout matrix
- delivery-marker ordering and bounded first-use Web performance scenario
- Existing scalar/glyph/catalog tests that prove stages 7–30 compatibility.

Test names may consolidate when one responsibility-shaped harness proves
multiple adjacent facts. Do not create placeholder tests or a second simulator.

## Acceptance checks

### Product and rule truth

- [x] Prototype stages use exactly three kinds, two channels, current plus next
  two visible tokens, and no hidden-tail leak.
- [x] Successful root admission consumes one shot/token; every rejection and
  derived child consumes neither. Same Deal is exact; New Deal is deterministic.
- [x] Latest valid writer changes owner even under stronger existing paint;
  strength never decreases; Red/Green never double-count target area.
- [x] Five signed rules, inclusive band edges, center-distance stars, Finish
  readiness, exhaustion, and timeout behave exactly as locked above.
- [x] Burst uses ordinary impact plus one 14-unit radial stamp and disappears.
  Split occurs only at first pre-contact apex and makes three Standard children.
- [x] Player and public agent share action authority and visible information.

### Compatibility and presentation

- [x] Stages 1–6 use the specified profiles; stages 7–30 retain functional and
  truthfully presented v10 scalar/glyph behavior.
- [x] Save v6 preserves settings/unlocks, archives legacy bests, and never
  upgrades an unverifiable scalar best into a target-band clear.
- [x] English/Korean runtime captures at all three sizes show readable band,
  score, signs, current/next tokens, shots, Finish state, and results without
  clipping or reliance on color alone.
- [x] Active docs clearly distinguish implemented prototype, legacy stages, and
  deferred 30-stage migration.

### Delivery and bounded performance

- [x] Targeted implementation checks, one final suite, and one post-feature
  compact performance scenario pass with saved evidence.
- [x] Windows production export launches and the single-thread Web production
  export validates from the committed tree against official itch limits and
  exact-case references.
- [x] Pushed runtime commit is visible remotely and both itch channels report
  version `alpha.9+2edb4c4`.
- [ ] Remote HTML iframe starts, accepts input, scales, saves, and has no
  material console/network/audio error.

### Reopened stability acceptance

- [ ] From a fresh Briefing-to-Aim transition, one untouched Space press fires
  exactly one root without terrain, canvas, or Fire-button click; mouse Fire also
  fires exactly once and secondary-button Space behavior remains native.
- [ ] Apex Split atomically replaces its root with exactly three Standard
  children, the camera widens to keep the family readable, and one relevant
  child contact completes the hold/return contract without affecting physics.
- [ ] Impact Burst and Apex Split publish distinct, once-only presentation that
  agrees with accepted paint/lifecycle/observation state.
- [ ] Gameplay HUD, Stage Select, Settings, Pause, and Result pass the accepted
  viewport/locale matrix with 24 px logical safe margins, no overlap/clipping,
  truthful focus, and readable caption/context contrast; Web stress sizes keep
  primary action/status bounded.
- [ ] A foreground local Web trace and the post-deploy itch trace meet p95
  16.7 ms, p99 33.3 ms, maximum 50 ms, and Fire-to-first-visible 100 ms for the
  defined shot sequence, or the exact indivisible engine/GPU exception is
  documented before any budget or fidelity change.
- [ ] The deployed PCK hash equals the CI-published PCK hash for the approved
  fixed commit, and the public itch journey passes startup, first input, resize/
  fullscreen, special balls, save, audio, background/resume, and console/network
  checks without changing project visibility.

## Validation commands and cost policy

During M1–M4 run only the directly affected headless scripts plus one stabilized
`scripts/verify.ps1` per coherent script/scene/resource batch. Do not run load,
long-seed, exhaustive, or repeated full-suite tests while implementing.

After M4 is complete, announce the final gate's purpose and expected scope, then
run:

```powershell
pwsh -NoProfile -File scripts/test.ps1 -GodotPath $env:GODOT_BIN
pwsh -NoProfile -File scripts/verify.ps1 -GodotPath $env:GODOT_BIN
& $env:GODOT_BIN --headless --path . --export-release 'Windows Desktop' 'builds/windows/PaintMountain.exe'
& $env:GODOT_BIN --headless --path . --export-release 'Web' 'builds/web/index.html'
pwsh -NoProfile -File scripts/verify-web-release.ps1 -ReleaseDirectory builds/web
```

The reopened compact performance command/harness may be added during M8 only.
It must be bounded to one representative scenario and produce a concise
machine-readable record under `.agents/evidence/`.

## Rejected alternatives and contingencies

- Do not implement nine kinds, paired bags, per-color quotas, color cancellation,
  mixing, a third channel, nonlinear weights, runtime adaptive odds, or hand-
  authored ordered queues. They dilute or contradict the approved MVP.
- If an RG8/owner texture is unreliable in Compatibility, keep one authoritative
  CPU owner/strength buffer and derive one runtime visual texture from it; never
  create a second score mask.
- If apex integration timing is ambiguous, publish one typed lifecycle event
  from the physics owner and test the exact velocity/contact ordering.
- If Split misses frequently, tune only fan angle/speed/upward addition within
  typed resources; do not show child paths or change root ballistics.
- If a generated prototype deal has no witnessed clear, retain its evidence as
  unvalidated and tune profile/band/terrain in the later feasibility workflow;
  do not claim every structural deal is physically guaranteed.
- If legacy-stage compatibility forces duplicate rule logic, extract an explicit
  stage-rule strategy instead of spreading `if stage <= 6` through consumers.
- If itch CDN compression documentation conflicts with Godot guidance, inspect
  live `Content-Type` and `Content-Encoding`; local gzip size is budget evidence
  only.
- If the itch launcher works but the canvas is not focused after start, add one
  project-owned custom Web shell that gives the existing canvas `tabindex=0` and
  reasserts focus after engine start, `window.focus`, and `visibilitychange`.
  Retain pointer focus; do not add a second activation overlay, forward keys
  across origins, or change itch settings to hide the defect.
- If first Fire still fails while Fire owns focus, record the StageController
  readiness snapshot, effective camera/interaction tuple, and input event, then
  fix the first rejecting owner. Do not weaken admission, require terrain
  selection, or synthesize a second Fire.
- If Apex child construction fails after pre-admission, admit no children and
  retain the parent on the explicit Standard fallback. Never consume the parent
  or publish a split effect for a partial family.
- If effect admission cannot be acknowledged synchronously, keep the request
  pending until the existing canonical manager/PaintSystem boundary accepts it,
  then present/consume once. Do not create a second paint path or infer success
  from visuals.
- If a 1024/640 Web stress size cannot show every secondary legend item, preserve
  the primary action/status and wrap or suppress lowest-priority duplicate
  shortcut copy. Do not shrink accepted-size typography or silently change the
  Windows-first minimum.
- If more than one performance owner exceeds budget, apply the locked branches
  in descending measured frame cost and capture one after-trace after the batch.
  Do not run repeated full suites/traces between small edits.
- If the remote PCK hash differs from the authorized CI hash, stop remote claims,
  inspect Butler channel/version and CDN URL, and republish only an already
  authorized verified artifact or request new authorization. Matching UI
  version text is not artifact identity.

## Stop conditions

Stop and ask before adding/upgrading a production dependency or asset pack,
changing the three-token horizon, adding a kind/channel, changing stage access,
deleting legacy glyph/catalog owners, force-pushing, changing itch visibility,
or starting the all-thirty-stage migration. A difficult implementation, failed
test, or tuning iteration is not by itself a stop condition.

## Progress

- [x] Validated supplied proposal against baseline repository, active authority,
  implementation owners, current tests, and official Godot/itch requirements.
- [x] Confirmed clean baseline `155c401` and passing `scripts/verify.ps1`.
- [x] Corrected lifecycle, scope, deterministic-randomness, evidence, testing,
  and remote-publication gaps in this active execution contract.
- [x] M1 — Authority, data, and score contracts. Focused score/band/deal tests,
  96 structural prototype seeds, and stabilized verification pass.
- [x] M2 — Authoritative paint and intrinsic projectiles. Owner/order, Burst,
  Split, family-capacity, and stabilized verification checks pass.
- [x] M3 — Stage rule, retry, persistence, and parity. Six profiles and their
  legacy boundary, queue/retry/finish flow, save v6, observation parity,
  prediction identity, and catalog materialization pass focused runtime checks.
- [x] M4 — Player flow and six-stage calibration. Forty-eight raw runtime frames
  plus six contact sheets cover all required states, sizes, and locales; all six
  default deals have bounded physical clear witnesses.
- [ ] M5 — Audit, compact performance, production, push, and remote verification.
- [x] 2026-08-20 reopened discovery — traced the deterministic first-Fire focus
  race; inspected first-use/projectile/paint hot paths, fixed-layout owners, and
  special-ball lifecycle; captured and reviewed fifteen current Windows frames;
  inspected the live itch page/iframe/static files; and matched the remote PCK
  to Actions run `32135545451`.
- [ ] M6 — First input and special-ball lifecycle correctness.
- [ ] M7 — Container-owned responsive UI and contrast correction.
- [ ] M8 — Foreground Web attribution and bounded performance correction.
- [ ] M9 — Final local gate, user-authorized publication, and deployed itch proof.

## Decision log

- 2026-08-18: User approved the downloaded three-ball/red-green/target-band
  direction and asked for implementation, push, and itch verification.
- 2026-08-18: Six-stage prototype is the active definition of done because the
  source proposal explicitly forbids all-thirty rollout before evidence and
  approval. Human outcome rates and catalog v11 remain future evidence/work.
- 2026-08-18: Keep stages 7–30 operational under v10 during the prototype; do
  not delete glyph owners or misrepresent those stages.
- 2026-08-18: Use a versioned integer PRNG and structural seed fixtures now;
  physical validated-seed banks require the deferred offline validator.
- 2026-08-18: Chrome enterprise policy blocks approved automation against
  `127.0.0.1`. Static Web validation remains local; interactive Web checks move
  to the published itch origin rather than bypassing browser policy.
- 2026-08-18: Commits `8e819dc`, `ebe18b9`, and `2edb4c4` were pushed to the
  task branch and fast-forwarded to `master`. GitHub Actions run `32135545451`
  passed verification, the complete suite, Windows/Web exports, GitHub Pages,
  and Butler publication. Both itch channels used `alpha.9+2edb4c4`.
- 2026-08-18: The managed Chrome policy also blocks the itch project and GitHub
  Pages origins. Publication is proven by the successful workflow and Butler
  output, but project-kind/playable settings and iframe interaction remain an
  external manual browser gate; no alternate browser path will bypass policy.
- 2026-08-20: The public itch page and iframe are reachable without account-side
  mutation. The page uses a click-to-load 640x360 placeholder and starts
  maximized; the Godot shell has `focusCanvas: true`. The deployed PCK hash is
  `7594074F4AEE82BF53F96398549DC9C4C915BB4715355DE0CA34C8FBC6156BF5`, exactly
  matching Actions run `32135545451` for `alpha.9+2edb4c4`.
- 2026-08-20: Code tracing closes the reported first-Fire symptom as an internal
  presentation-order/focus race, not a missing target, empty deal, or cannon
  collider. The fix must preserve the host launch gesture while eliminating any
  second in-game activation click.
- 2026-08-20: Apex Split makes the existing root-only Shot Follow contract
  unreachable before first terrain contact. The older source-brief rule to widen
  on split remains applicable; ProjectileManager owns the family and
  CameraDirector owns only its bounded presentation.
- 2026-08-20: The current visual baseline is retained. The UI task is responsive
  composition, component geometry, and evidenced contrast correction, not a new
  aesthetic direction.

## Next Steps

Execute M6 first because it closes the reported first input and special-ball
correctness failures without UI restructuring. Then execute M7 with before/after
runtime evidence, add and use M8 instrumentation once for measured Web fixes,
and run M9 only after the feature set stabilizes. Publication remains a separate
explicit approval gate; the current `alpha.9+2edb4c4` build is evidence of the
reported baseline, not the fixed definition of done.

## Handoff rule

Mark this plan `done` only when every non-conditional acceptance check above is
supported by current local or remote evidence, all task-owned work is committed
and pushed, and the itch build for that commit has been exercised. If remote
credentials or account settings block publication after three task turns,
record the exact blocker and leave the plan active or mark it blocked only under
the goal-status policy. Do not claim the deferred catalog rollout or human-study
results as part of completion. The existing M1–M5 checks cannot substitute for
the reopened M6–M9 acceptance evidence.
