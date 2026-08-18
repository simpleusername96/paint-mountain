---
type: plan
status: active
created: 2026-08-18
scope: deliver and publish a six-stage Paint Mountain prototype with deterministic three-ball deals, red/green latest-writer paint ownership, signed target-band scoring, and truthful human/agent/UI parity
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

The compact performance command/harness may be added during M5 only. It must be
bounded to one representative scenario and produce a concise machine-readable
record under `.agents/evidence/`.

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

## Next Steps

Features, audit, the broad functional gate, compact performance, documentation,
local production exports, push, and matched-channel publication are complete.
Manually open the published itch project and verify project kind/playability,
startup, input, resize/fullscreen, save, audio, and console/network health. Then
record that evidence and close M5; browser policy prevents this agent from
performing or honestly claiming that final interaction.

## Handoff rule

Mark this plan `done` only when every non-conditional acceptance check above is
supported by current local or remote evidence, all task-owned work is committed
and pushed, and the itch build for that commit has been exercised. If remote
credentials or account settings block publication after three task turns,
record the exact blocker and leave the plan active or mark it blocked only under
the goal-status policy. Do not claim the deferred catalog rollout or human-study
results as part of completion.
