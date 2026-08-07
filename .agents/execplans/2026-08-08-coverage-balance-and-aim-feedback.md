---
type: plan
status: active
created: 2026-08-08
last_reviewed: 2026-08-08
scope: target-coverage feasibility and responsive first-impact prediction, preserving the approximate marker and post-contact physics
related:
  - ../PLANS.md
  - ../Documentation.md
  - ../../AGENTS.md
  - ../../docs/source-brief.md
  - ../../docs/design-spec.md
  - ../../docs/technical-architecture.md
  - ../../docs/test-checklist.md
  - ../design/DESIGN.md
  - 2026-08-07-truthful-coverage-and-responsive-aiming.md
  - ../evidence/2026-08-07-aim-performance-product-audit.md
---

# Attainable Coverage and Responsive First-Impact Prediction - Research Checklist

## Purpose

- Decision or research question: choose the smallest evidence-backed combination
  of clear targets, star thresholds, shot capacity, and paint footprint tuning
  that makes the current v10 stages mechanically feasible and ordinarily
  clearable; also choose the smallest predictor change that keeps the existing
  approximate first-impact marker responsive during aim adjustment.
- Why it matters: the projectile and paint footprint stay approximately constant
  while the required new target area per available shot rises from about 90.8
  square metres on Stage 01 to about 480.7 square metres on Stage 30. The later
  burden is 5.29 times the Stage 01 burden before overlap, misses, non-target
  paint, or failed mechanism contact are considered. Separately, current
  prediction can spend up to 720 fixed steps on main-thread collision queries,
  and a newer aim can wait behind an obsolete active job.
- Decision owner: the Paint Mountain product owner. The implementing agent may
  recommend exact values from bounded runtime evidence but must not invent a
  permanent balance curve without that evidence and owner acceptance.
- Final output: an exact 30-stage table for clear and star targets, any approved
  shot or footprint changes, an automated all-stage feasibility result from the
  canonical runtime, an accepted prediction-latency and frame-cost contract, the
  chosen predictor remediation, the files and migration boundary that own those
  changes, and a separate Mode 3 implementation contract. This checklist is not
  itself an implementation contract.

## Locked Boundaries

Use these terms consistently:

- **Mechanical feasibility** means at least one deterministic shot sequence can
  clear a stage through the real `StageController`, projectile physics,
  mechanisms, and authoritative `PaintSystem`. It can be established by test
  automation; it does not require a person to operate the controls.
- **Ordinary playability** means a player can understand and execute a useful
  plan without a hidden answer or near-perfect input. This requires a bounded
  human feel/readability check after mechanical feasibility is established.
- **First-impact contract** means the approximate point where free flight first
  contacts the world. Its continued presence is a product decision.
- **Prediction responsiveness** means the frame cost and elapsed time from the
  latest canonical aim/wind context to its matching approximate marker. It is an
  implementation problem and is in scope.

- Preserve `StageController` as the only clear, failure, shot-progression, and
  Fire-admission authority.
- Preserve `PaintSystem` and physical Target Area surface coverage metric 2 as
  the only mutable paint and score authority. Do not return to screen-space or
  raw projected-texel scoring.
- Preserve the stationary cannon, manual yaw/elevation/power planning, no
  in-flight steering, current target masks, and v10 terrain geometry during the
  balance decision.
- Treat the complete preview as advisory. Fire remains available whenever the
  canonical game rules allow it, whether preview work is current, stale, or
  pending.
- Preserve the approximate first-impact marker. The marker remains useful for
  choosing where the projectile first reaches the terrain even though the
  post-contact roll, bounce, mechanisms, and paint path determine most of the
  result. This plan does not remove it or extend prediction past first impact.
- Remove normal-operation `CALCULATING TRAJECTORY` / `UPDATING` messaging and
  their Korean equivalents from the eventual implementation. Do not replace
  them with a spinner or another wait-state cue. A subdued retained preview can
  communicate staleness without telling the player to wait.
- Do not reopen whether the marker exists or redesign its visual form. Predictor
  scheduling, collision sampling, stale-work cancellation, and first-impact
  computation are in scope only as needed to remove the measured lag while
  preserving prediction parity and the same visible marker contract.
- Do not revive the archived exhaustive target-wide certificate, authored
  product success route, or all-stage manual-clear requirement. A bounded
  test-only feasibility runner may search and replay witnesses through the real
  runtime, but it stores only metrics and never becomes a shipping solver,
  stage resource, hint, or durable answer path.

## Verified Current Baseline

The current catalog and projectile resource establish this diagnostic baseline:

| Stage | Target surface (m2) | Clear target | Shots | Required target paint (m2) | Required per shot (m2) | Versus Stage 01 |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| 01 | 9,081.3 | 4.0% | 4 | 363.3 | 90.8 | 1.00x |
| 10 | 14,275.1 | 8.5% | 5 | 1,213.4 | 242.7 | 2.67x |
| 20 | 20,832.5 | 12.0% | 6 | 2,499.9 | 416.6 | 4.59x |
| 30 | 22,433.9 | 15.0% | 7 | 3,365.1 | 480.7 | 5.29x |

The basic projectile has a 1.20 m physical radius, a 1.40 m continuous paint
radius, and a 1.75 m impact paint radius. Under an intentionally optimistic flat
strip model with no overlap and every mark on target, one impact plus continuous
contact would still need about 29 m of new target travel per Stage 01 shot, 83 m
per Stage 10 shot, 145 m per Stage 20 shot, and 168 m per Stage 30 shot. This is
not a gameplay measurement; it is an upper-bound warning that the current clear
curve scales much faster than the paint tool.

Current ownership is also known:

- `StageProgressionData.target_for()` owns the generated clear-target curve and
  `shots_for()` owns the shot ladder. The build script derives star thresholds
  as the clear target plus fixed offsets and materializes the fixed catalog.
- `basic_paintball.tres` owns physical radius and paint footprint tuning.
- `TrajectoryPreview` currently renders the world-space `preview.updating`
  status. `fire.pending` remains in the translation table without a production
  Fire-path consumer.
- `TrajectoryPredictionJob` advances the same 1/60-second flight model used by
  offline prediction for as many as 720 steps. Each step performs a
  `PhysicsDirectSpaceState3D.cast_motion()` query and can also perform one or
  more `get_rest_info()` queries.
- `TrajectoryPredictionScheduler` advances at most 24 prediction steps per
  physics tick, so one worst-case job needs 30 ticks, or 0.5 seconds at 60 Hz,
  before publication. When a different context is nominated during an active
  job, the scheduler stores one newest pending request but normally finishes the
  obsolete active job before starting it. A newest result can therefore wait
  for the remaining obsolete work plus its own job.
- Existing prediction tests bound steps, job count, and publication correctness.
  They do not measure main-thread milliseconds, input-to-current-marker latency,
  discarded stale work, query count, or running-game frame pacing. The 96-dot
  `MultiMesh` presentation is already structurally bounded and is not the first
  suspected hitch owner.
- The canonical generated terrain already exposes one sampled top topology and
  local surface queries. This is a viable source for a cheaper first-impact
  candidate, subject to parity checks against the authoritative physics query.
- The completed 2026-08-07 plan intentionally stopped before stage targets,
  projectile tuning, and mechanism balance. It did not establish that the
  current stages are practically clearable, and its structural scheduler budget
  did not establish responsive frame time or current-context publication.

## Scope and Evidence Contract

- In scope: the current v10 burden curve; automated mechanical feasibility;
  actual new target paint per shot; clear and star target curves; shot-count and
  paint-footprint alternatives; mechanism contribution as measured rather than
  assumed; predictor main-thread cost; latest-context publication latency;
  stale-job policy; collision-query count and parity; misleading pending copy;
  resource, catalog, replay, persistence, localization, and test impacts.
- Out of scope: removing or visually redesigning the approximate first-impact
  marker; predicting post-contact roll, bounce, mechanisms, or paint path;
  terrain regeneration; cannon placement; target mask edits; wind-rule changes;
  mechanism placement or behavior changes; a shipping aim solver; authored
  product success routes; full 30-stage manual certification; visual restyling;
  implementation.
- Destructive or irreversible actions: none. Evidence runs use the current
  fixed catalog and task-owned output only.
- Approval required before: changing gameplay, resource, translation, catalog,
  replay, save, or test files; accepting exact permanent tuning or predictor
  latency values; expanding into geometry, mechanisms, or post-contact preview.
- Search budget or reassessment point: first inspect Stages 01, 02, 03, 10, 20,
  and 30 through deterministic automation. Use bounded test-only aim search or
  supplied aim tuples only to produce feasibility evidence; do not ship or
  preserve them as product routes. After feasibility, run at most one cold-read
  and one informed human attempt per representative stage for readability and
  feel. Once one balance family passes the representative gate, run one bounded
  automated feasibility pass across all 30 stages and replay each successful
  witness once; retain metrics, not shot sequences, as evidence. Profile
  first-impact prediction on Stages 01, 10, and 30 under idle aim, continuous
  drag, release, and changing wind. Evaluate no more than three materially
  different balance families and three predictor remediations.
- Conflict-resolution rule: the effective source brief wins over working design
  documents; current v10 runtime and authoritative coverage observations win
  over theoretical estimates; recent user play evidence wins over historical
  plan assumptions; preserving the core planning loop wins over making every
  shot independently sufficient.
- Stop rule for unproductive exploration: stop comparing balance families when
  one satisfies representative feasibility/playability and alternatives are
  materially worse, then run the single all-stage automated pass. Stop predictor
  comparison when one remediation meets the accepted latency/frame-cost
  contract with parity and alternatives are materially worse. If either side
  cannot pass without an out-of-scope change, report that exact scope decision
  instead of widening the task silently.

| Evidence category | Primary source | Freshness requirement | What it must establish | Sufficient evidence |
| --- | --- | --- | --- | --- |
| Product authority | Effective `docs/source-brief.md`, `.agents/Documentation.md`, current user feedback | Re-read before the decision | Core loop, supersessions, and what is actually implemented | No surviving option contradicts the effective brief or claims an absent feature |
| Numeric burden | Current `resources/stages/catalog.tres`, v10 manifest, `StageProgressionData`, and `basic_paintball.tres` | Same catalog hash and projectile resource as the evidence build | All 30 target areas, clear/star targets, shots, paint radii, and progression breakpoints | A reproducible table identifies area per shot and every curve discontinuity |
| Mechanical feasibility and actual paint yield | Test-only deterministic actions through the real `StageController`, projectile physics, mechanisms, `PaintSystem`, `ShotObservation`, and `AttemptObservation` | Same catalog, physics settings, projectile resources, and build as the candidate | Whether a real runtime sequence can clear every stage; deep new-target, overlap/non-target, mechanism, final-result, and unused-shot diagnostics on the six representative stages | At least one candidate sequence clears each of all 30 stages and replays to the same authoritative result; only metrics persist. Failed bounded search is missing evidence, not proof of impossibility, and blocks a positive all-stage claim |
| Player path | Running-game captures and concise notes for one cold-read and one informed attempt after automated feasibility | Same accepted candidate build as the feasibility data | Whether an ordinary player can identify and execute a useful route without a hidden solution | Stage 01 teaches the scale; later samples become understandable after normal learning, without near-perfect input or consulting the test witness |
| Visual scale | Running-game captures of impact, rolling contact, and result coverage | Same candidate footprint values being judged | Paint remains visually connected to the ball and terrain rather than becoming an invisible score multiplier | Product owner can compare baseline and candidate at identical camera states and accept the footprint relationship |
| Predictor performance | Task-owned production-build diagnostics around `TrajectoryPredictionScheduler` and `TrajectoryPredictionJob` on Stages 01, 10, and 30 | Same build and graphics/physics settings for baseline and candidate | Main-thread prediction time per physics tick, input-to-current-marker latency, collision-query count, stale steps discarded, and frame pacing for idle, drag, release, and changing wind | Baseline and up to three candidates are directly comparable; one candidate meets exact owner-accepted frame-cost and latest-marker latency limits without waiting UI |
| Prediction parity | Existing predictor fixtures plus representative physics-versus-candidate comparison on terrain, bounds exit, wind transition, and grazing contact | Same fixed catalog and Godot runtime as implementation | The faster path preserves approximate first-impact kind, endpoint tolerance, normal/identity needs, projectile radius, damping, gravity, and wind inputs | Every required fixture passes the agreed endpoint/kind tolerance and no stale context publishes as current |
| Migration and regressions | Current catalog builder, replay/save contracts, localization table, and focused tests | Current branch immediately before implementation planning | Whether a candidate needs a progression version/catalog rematerialization and which contracts change | Exact owner files, compatibility behavior, and focused validation commands are recorded |

## Decision Criteria

- Clearing is an ordinary success state; one-star or clear cannot be calibrated
  as a near-perfect theoretical maximum.
- Stage 01 must teach that sustained target contact matters without requiring a
  restart merely to discover the scale of the goal.
- Later representative stages may require visible mechanism use and improved
  planning, but they must not require every shot to produce an exceptional,
  overlap-free, all-target run.
- Higher stars must preserve room for stronger routing and cleaner execution.
  Lowering clear targets must not collapse every result into three stars.
- The painted footprint must remain visually credible for the ball. If the
  footprint changes, its target and non-target visuals must reveal the same
  physical area that the score counts.
- Added shots cannot be the only remedy when individual shots still look
  ineffectual; excessive shot count also weakens the short planning loop.
- Prefer a data/resource change over new runtime policy, but do not prefer a
  smaller diff if it leaves the user-visible impossibility intact.
- The marker shown during interaction must correspond to the newest nominated
  aim context inside the accepted latency limit; obsolete prediction work must
  not consume the budget merely because it started first.
- Prediction work must fit inside an accepted share of the 60 Hz frame budget in
  the production build. A step-count cap without measured main-thread cost is
  not sufficient evidence.
- Faster prediction must preserve the approximate first-impact contract and
  must not predict or imply the post-contact outcome.

## Viable Options

| Option | Why materially viable | Decision criteria | Disqualifier |
| --- | --- | --- | --- |
| A. Retune clear and star targets only | It directly corrects required area while preserving projectile feel, physics, and run length | Representative cold-read/informed attempts separate clear, one-star, and high-skill results | Required targets become visually trivial, later stages still depend on exceptional rolls, or mechanisms cease to matter |
| B. Increase continuous and/or impact paint footprint only | It makes each successful contact visibly and numerically more productive | Paint remains credibly related to the 1.20 m ball and does not erase route separation | The needed footprint looks detached from the ball, paints across unrelated routes, or makes early stages automatic |
| C. Increase shot capacity only | It preserves the current percentage and footprint scales while giving more recovery | Runs remain short and each extra shot creates a meaningful new plan | The player must repeat many weak shots, early failures lose consequence, or later stages remain dependent on exceptional yield |
| D. Use a restrained hybrid | Small coordinated changes can avoid extreme target, footprint, or shot adjustments | Every component has a demonstrated job: target fixes burden, footprint fixes felt impact, shots provide limited recovery | Any component lacks evidence, duplicates another component, or expands into geometry/mechanism work |

The current values with UI copy removal only are not a viable option because the
user's direct play evidence and the 5.29x per-shot burden escalation already
contradict the claim that the balance is acceptable.

### First-impact prediction performance options

| Option | Why materially viable | Decision criteria | Disqualifier |
| --- | --- | --- | --- |
| P1. Scheduler-only latest-work repair | Cancel or supersede obsolete active work, start the newest nominated context promptly, and use a measured time budget instead of assuming 24 queries are cheap | Meets the accepted latest-marker latency and frame-cost limits without changing prediction math | Per-step physics queries still exceed the frame budget or cancellation thrashes so no current result completes during normal interaction |
| P2. Canonical-terrain fast candidate with narrow physics confirmation | The fixed terrain already owns canonical top-surface samples, so most free-flight steps can avoid direct-space queries and only a bounded candidate contact needs authoritative confirmation | Preserves first-impact kind and endpoint tolerance for terrain, shell/apron, bounds, wind, grazing, and projectile radius while materially reducing queries | It creates a second terrain truth, misses non-terrain first contacts, or parity requires nearly the original query count |
| P3. Dual-fidelity interaction | While aim is moving, publish a cheap approximate first-impact result from canonical terrain data; on release or a stable context, refine with the authoritative predictor and atomically replace it | The immediate marker is visibly useful, the settled result arrives inside its limit, and both use the same aim/wind context without claiming post-contact certainty | Approximate/settled marker jumps are misleading, implementation duplicates prediction ownership, or settled refinement still causes a hitch |

Moving `PhysicsDirectSpaceState3D` queries to a background thread is not a viable
option unless the current Godot 4.7.1 primary documentation and a bounded probe
establish that every required query is thread-safe. Do not treat threading as a
default escape from main-thread cost.

## Tasks

### Phase 1: Establish current truth

- [ ] Re-read the effective source-brief supersessions and current implemented
  status, then record the exact requirements that constrain clear difficulty,
  stars, projectile scale, mechanisms, and runtime evidence.
- [ ] Generate a task-owned all-stage diagnostic table from the fixed v10
  catalog: target surface area, clear/star thresholds, shots, required square
  metres, required square metres per shot, route count, route width, and
  mechanism count. Do not write these diagnostics into product resources.
- [ ] Trace all consumers of `target_for()`, `shots_for()`, star thresholds,
  projectile paint radii, catalog version/hash, replay/save compatibility,
  `preview.updating`, and `fire.pending`. Separately trace aim nominations,
  prediction jobs, direct-space queries, context publication, and preview status.
- [ ] Confirm what `ShotObservation` and `AttemptObservation` already record.
  Propose the smallest task-owned evidence hook only if authoritative per-shot
  target gain or mechanism contribution is unavailable.
- [ ] Define a test-only deterministic action/witness format that drives the
  canonical gameplay API and can replay a candidate sequence without becoming
  a shipping solver, stage resource, authored route, or gameplay hint.
- [ ] Add a diagnostic design for production-build predictor measurements:
  per-tick main-thread time, current-context publication latency, query count,
  stale work, and frame pacing. Keep wall-clock thresholds out of ordinary CI;
  pair task-owned benchmark evidence with deterministic structural regressions.
- [ ] Inspect the canonical terrain-top query boundary and every collision kind
  the first-impact predictor must preserve. Remove any performance option that
  would create a second terrain truth or silently ignore a valid first contact.
- [ ] Remove any option that fails a locked boundary before runtime trials.

Phase gate:

- Every surviving option is materially viable, every current-state claim points
  to inspected evidence, and the baseline build/catalog identity is recorded.

### Phase 2: Gather decisive runtime evidence

- [ ] Use bounded test-only action search or supplied candidate tuples to find
  and replay a successful sequence on Stages 01, 02, 03, 10, 20, and 30 through
  the real runtime owners. Automation establishes mechanical feasibility; do
  not require a person to discover the witness and do not persist it as product
  data.
- [ ] For every automated shot, record authoritative new target coverage, final
  coverage, target/non-target loss, overlap, mechanism contact/contribution when
  present, remaining shots, and replay determinism. Treat bounded-search failure
  as inconclusive unless an independent upper bound proves impossibility.
- [ ] Compare the four option families against the same observed attempts.
  Target-only and star-only candidates can be evaluated from existing results;
  rerun only candidates that change paint yield or shot capacity.
- [ ] After one balance family passes the six representative stages, run one
  bounded automated feasibility pass over all 30 stages. Replay each successful
  witness once through the same runtime, retain only aggregate/shot metrics, and
  block the claim that the game is mechanically clearable if any stage lacks a
  replayed witness.
- [ ] After automation establishes feasibility, run only one cold-read and one
  informed human attempt per representative stage to judge route readability,
  footprint credibility, and ordinary difficulty. Do not use human play as the
  sole evidence that a stage can or cannot be cleared.
- [ ] Capture the predictor baseline in a production-style build on Stages 01,
  10, and 30 for idle aim, continuous drag, release, and changing wind. Record
  main-thread prediction time, input-to-current-marker latency, direct-space
  query count, stale steps, and visible frame pacing.
- [ ] Evaluate at most three predictor remediations against the same contexts.
  Reject scheduler-only tuning if it merely trades hitch size for longer stale
  markers, and reject any fast path that fails agreed physics parity.
- [ ] Stop balance and predictor candidate exploration after three materially
  different families on each side. Collect only the captures needed for marker
  usefulness, hitch perception, route readability, and footprint scale.
- [ ] Record source/build identity, access date, observed fact, inference, and
  confidence separately. Do not convert the optimistic strip estimate into a
  balance guarantee.

Phase gate:

- Each balance criterion has deep automated evidence across the six
  representative stages, a replayed success witness for each of all 30 stages,
  and bounded representative human feel evidence. Each predictor criterion has
  comparable production-build measurements and parity evidence, or one exact
  missing owner judgment is identified.

### Phase 3: Decide and record

- [ ] Compare surviving options against the same criteria and recommend one.
- [ ] Produce the exact proposed 30-stage clear/star table and any exact shot or
  footprint changes. Check monotonic progression and every break at mechanism,
  shot-count, route-count, and terrain-size transitions.
- [ ] Select one predictor remediation and record exact accepted limits for
  production-build per-tick prediction cost and latest-context marker latency,
  plus deterministic CI guards for stale publication, query bounds, and parity.
- [ ] Show the product owner identical-camera baseline/candidate evidence for
  every proposed footprint change and before/after aim-performance evidence;
  obtain the balance and predictor acceptance decisions.
- [ ] Record rejected alternatives only where their rationale prevents the same
  unsupported approach from returning later.
- [ ] Record the expected implementation boundary: progression/resource owner,
  catalog version or compatibility decision, prediction owner and algorithm,
  translation cleanup, focused contracts, production build, and representative
  rendered/performance QA.
- [ ] Change this checklist to `status: done`, then create a separate Mode 3
  implementation contract. Do not append implementation tasks here.

Phase gate:

- Exact balance values, prediction remediation, performance limits, parity
  tolerances, and ownership are approved, or one specific missing decision and
  its owner are named. No implementation readiness is implied before that gate.

## Expected Implementation Boundary After the Decision

This section identifies likely owners but does not authorize edits.

- Progression tuning belongs in `src/stage_generation/stage_progression_data.gd`
  and the versioned progression/catalog build path, not ad hoc per-stage runtime
  code. Star policy belongs with catalog materialization unless the decision
  creates a new typed resource field.
- Paint footprint tuning belongs in typed projectile resources. The physical
  ball radius must not be changed merely to enlarge score unless the owner
  explicitly chooses a physical-scale change.
- The normal pending text belongs to `TrajectoryPreview` presentation and the
  localization table. Removing it must not alter prediction ownership, preview
  fidelity, the approximate first-impact marker, or Fire readiness. Remove dead
  translation entries only after a repository-wide consumer check.
- Predictor scheduling belongs in
  `src/cannon/trajectory_prediction_scheduler.gd`; fixed-flight integration and
  contact resolution belong in `trajectory_prediction_job.gd` or a narrower
  task-owned predictor boundary selected by the decision. If canonical terrain
  sampling is selected, reuse `TerrainSurface` / `TerrainTopTopology`; never copy
  the height grid into a competing runtime authority.
- The implementation must eliminate obsolete work according to the selected
  latest-context policy, publish no stale result as current, retain the last
  complete marker while newer work is pending, and keep Fire independent of
  preview readiness.
- Focused contracts must cover the chosen progression endpoints and transitions,
  catalog/schema compatibility, clear/star ordering, projectile footprint
  resource values when changed, no calculation/updating text in the running Aim
  View, Fire remaining independent of preview readiness, current-context
  publication, stale-work cancellation/supersession, first-impact parity, and
  deterministic query/work bounds. Production-build evidence separately covers
  real frame cost and latency; ordinary CI does not use flaky wall-clock limits.
- Final handoff must use `scripts/verify.ps1`, a Windows release export or the
  documented production-style equivalent, and directly inspected running-game
  captures for the affected Aim and result states.

## Progress and Next Steps

- Canonical progress: the task checkboxes in this checklist.
- Current phase: Phase 1.
- Next task: re-read the effective product authority, generate the all-stage
  diagnostic table, and define the automated feasibility and predictor
  performance evidence hooks.
- Last completed gate: artifact scope, locked boundaries, viable options, and
  evidence contract defined from current repository evidence.
- Update rule: check an item only when its evidence exists. Do not repeat a
  completed run unless the catalog, projectile resource, predictor candidate,
  accepted performance context, or another decision-changing input changes.

## Completion and Stop Conditions

Complete when:

- The deep six-stage automated evidence, replayed all-stage feasibility pass,
  and bounded representative human playability evidence are complete, or one
  exact unavailable input is recorded after the stated fallback.
- Each surviving option is evaluated against the same criteria.
- The owner accepts exact 30-stage clear/star values and any exact shot or paint
  footprint changes, plus one predictor remediation, exact performance limits,
  and parity tolerances; or one specific missing authority is named.
- The final decision records implementation owners, migration implications,
  focused validation, predictor performance evidence, rejected alternatives,
  and evidence freshness.
- Frontmatter status is changed to `done`.

Escalate when:

- No viable option passes without changing target masks, terrain geometry,
  mechanism behavior, wind, or the post-contact gameplay contract.
- Runtime observations conflict with authoritative coverage output or current
  catalog identity cannot be established.
- No predictor remediation meets the accepted production frame-cost and
  current-marker latency limits without violating first-impact parity or adding
  a second terrain authority.
- Paint footprint credibility requires a visual/product decision the owner has
  not accepted.
- A destructive migration, dependency change, or unrelated worktree cleanup
  appears necessary.
