---
type: plan
status: active
created: 2026-08-08
last_reviewed: 2026-08-08
scope: target-coverage balance and non-blocking aim feedback, preserving the approximate first-impact marker and excluding its implementation
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

# Attainable Coverage and Non-Blocking Aim Feedback - Research Checklist

## Purpose

- Decision or research question: choose the smallest evidence-backed combination
  of clear targets, star thresholds, shot capacity, and paint footprint tuning
  that makes the current v10 stages realistically clearable, while removing UI
  language that falsely suggests Fire must wait for a calculation.
- Why it matters: the projectile and paint footprint stay approximately constant
  while the required new target area per available shot rises from about 90.8
  square metres on Stage 01 to about 480.7 square metres on Stage 30. The later
  burden is 5.29 times the Stage 01 burden before overlap, misses, non-target
  paint, or failed mechanism contact are considered.
- Decision owner: the Paint Mountain product owner. The implementing agent may
  recommend exact values from bounded runtime evidence but must not invent a
  permanent balance curve without that evidence and owner acceptance.
- Final output: an exact 30-stage table for clear and star targets, any approved
  shot or footprint changes, the files and migration boundary that own those
  values, the rejected alternatives, and a separate Mode 3 implementation
  contract. This checklist is not itself an implementation contract.

## Locked Boundaries

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
  result. This plan does not remove or replace it.
- Remove normal-operation `CALCULATING TRAJECTORY` / `UPDATING` messaging and
  their Korean equivalents from the eventual implementation. Do not replace
  them with a spinner or another wait-state cue. A subdued retained preview can
  communicate staleness without telling the player to wait.
- Do not redesign the preserved marker or decide arc length, arc fidelity,
  prediction scheduling, collision sampling, or landing-point computation in
  this plan. Those implementation questions remain separate from balance work.
- Do not revive the archived exhaustive target-wide certificate, authored
  success-route, or all-stage manual-clear requirement. Balance evidence is a
  bounded representative sample, not a new solver or product route asset.

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
- The completed 2026-08-07 plan intentionally stopped before stage targets,
  projectile tuning, and mechanism balance. It did not establish that the
  current stages are practically clearable.

## Scope and Evidence Contract

- In scope: the current v10 burden curve; actual new target paint per shot;
  clear and star target curves; shot-count and paint-footprint alternatives;
  mechanism contribution as observed rather than assumed; misleading pending
  copy; resource, catalog, replay, persistence, localization, and test impacts.
- Out of scope: removing or redesigning the approximate first-impact marker;
  trajectory or landing-preview implementation; predictor performance work;
  terrain regeneration; cannon placement; target mask edits; wind-rule changes;
  mechanism placement or behavior changes; a new solver; full 30-stage manual
  certification; visual restyling; implementation.
- Destructive or irreversible actions: none. Evidence runs use the current
  fixed catalog and task-owned output only.
- Approval required before: changing gameplay, resource, translation, catalog,
  replay, save, or test files; accepting exact permanent tuning values; expanding
  into geometry, mechanisms, or trajectory work.
- Search budget or reassessment point: first inspect Stages 01, 02, 03, 10, 20,
  and 30. Run three ordinary manual attempts per stage, then expand only a
  disputed stage to five attempts. Evaluate no more than three materially
  different tuning families. Do not inspect all 30 stages unless the six-stage
  evidence reveals a progression discontinuity that cannot be resolved from
  resource data.
- Conflict-resolution rule: the effective source brief wins over working design
  documents; current v10 runtime and authoritative coverage observations win
  over theoretical estimates; recent user play evidence wins over historical
  plan assumptions; preserving the core planning loop wins over making every
  shot independently sufficient.
- Stop rule for unproductive exploration: stop when one tuning family satisfies
  the evidence criteria across the representative stages and the alternatives
  are materially worse or disqualified. If none does so without changing an
  out-of-scope system, report that single scope decision instead of widening the
  task silently.

| Evidence category | Primary source | Freshness requirement | What it must establish | Sufficient evidence |
| --- | --- | --- | --- | --- |
| Product authority | Effective `docs/source-brief.md`, `.agents/Documentation.md`, current user feedback | Re-read before the decision | Core loop, supersessions, and what is actually implemented | No surviving option contradicts the effective brief or claims an absent feature |
| Numeric burden | Current `resources/stages/catalog.tres`, v10 manifest, `StageProgressionData`, and `basic_paintball.tres` | Same catalog hash and projectile resource as the evidence build | All 30 target areas, clear/star targets, shots, paint radii, and progression breakpoints | A reproducible table identifies area per shot and every curve discontinuity |
| Actual paint yield | Authoritative `ShotObservation` / `AttemptObservation` output from a production-style build | Captured after the baseline build and again only for candidates that alter paint yield | New target coverage per shot, overlap loss, non-target loss, mechanism contribution, final result, and unused shots | Three attempts on each representative stage; five only where the observed conclusion conflicts |
| Player path | Running-game captures and concise notes for cold-read and informed attempts | Same build as the paint-yield data | Whether an ordinary player can identify and execute a useful route without a hidden solution | Stage 01 is clearable as onboarding; later samples become clearable after understandable learning, without near-perfect non-overlap or a hidden authored route |
| Visual scale | Running-game captures of impact, rolling contact, and result coverage | Same candidate footprint values being judged | Paint remains visually connected to the ball and terrain rather than becoming an invisible score multiplier | Product owner can compare baseline and candidate at identical camera states and accept the footprint relationship |
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
  `preview.updating`, and `fire.pending`.
- [ ] Confirm what `ShotObservation` and `AttemptObservation` already record.
  Propose the smallest task-owned evidence hook only if authoritative per-shot
  target gain or mechanism contribution is unavailable.
- [ ] Remove any option that fails a locked boundary before runtime trials.

Phase gate:

- Every surviving option is materially viable, every current-state claim points
  to inspected evidence, and the baseline build/catalog identity is recorded.

### Phase 2: Gather decisive runtime evidence

- [ ] Use the production-style build path and capture three ordinary attempts
  each on Stages 01, 02, 03, 10, 20, and 30. Include a cold-read attempt and an
  informed follow-up; do not use a target-wide search or persist a success route
  as product data.
- [ ] For every shot, record authoritative new target coverage, final coverage,
  target/non-target loss, overlap, mechanism contact/contribution when present,
  and remaining shots. Pair the numbers with only the captures needed to judge
  route readability and footprint scale.
- [ ] Compare the four option families against the same observed attempts.
  Target-only and star-only candidates can be evaluated from existing results;
  rerun only candidates that change paint yield or shot capacity.
- [ ] Expand a representative stage from three to five attempts only when the
  initial evidence changes which option would win. Stop candidate exploration
  after three materially different families.
- [ ] Record source/build identity, access date, observed fact, inference, and
  confidence separately. Do not convert the optimistic strip estimate into a
  balance guarantee.

Phase gate:

- Each decision criterion has runtime evidence across the six representative
  stages, or one exact missing human/product judgment is identified for the
  owner.

### Phase 3: Decide and record

- [ ] Compare surviving options against the same criteria and recommend one.
- [ ] Produce the exact proposed 30-stage clear/star table and any exact shot or
  footprint changes. Check monotonic progression and every break at mechanism,
  shot-count, route-count, and terrain-size transitions.
- [ ] Show the product owner identical-camera baseline/candidate evidence for
  every proposed footprint change and obtain the balance decision.
- [ ] Record rejected alternatives only where their rationale prevents the same
  unsupported approach from returning later.
- [ ] Record the expected implementation boundary: progression/resource owner,
  catalog version or compatibility decision, translation cleanup, focused
  contracts, production build, and representative rendered QA.
- [ ] Change this checklist to `status: done`, then create a separate Mode 3
  implementation contract. Do not append implementation tasks here.

Phase gate:

- Exact values and ownership are approved, or one specific missing decision and
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
- Focused contracts must cover the chosen progression endpoints and transitions,
  catalog/schema compatibility, clear/star ordering, projectile footprint
  resource values when changed, no calculation/updating text in the running Aim
  View, and Fire remaining independent of preview readiness.
- Final handoff must use `scripts/verify.ps1`, a Windows release export or the
  documented production-style equivalent, and directly inspected running-game
  captures for the affected Aim and result states.

## Progress and Next Steps

- Canonical progress: the task checkboxes in this checklist.
- Current phase: Phase 1.
- Next task: re-read the effective product authority and generate the all-stage
  diagnostic table.
- Last completed gate: artifact scope, locked boundaries, viable options, and
  evidence contract defined from current repository evidence.
- Update rule: check an item only when its evidence exists. Do not repeat a
  completed run unless the catalog, projectile resource, candidate values, or a
  decision-changing input changes.

## Completion and Stop Conditions

Complete when:

- The bounded six-stage evidence set is complete, or one exact unavailable input
  is recorded after the stated fallback.
- Each surviving option is evaluated against the same criteria.
- The owner accepts exact 30-stage clear/star values and any exact shot or paint
  footprint changes, or one specific missing authority is named.
- The final decision records implementation owners, migration implications,
  focused validation, rejected alternatives, and evidence freshness.
- Frontmatter status is changed to `done`.

Escalate when:

- No viable option passes without changing target masks, terrain geometry,
  mechanism behavior, wind, or the trajectory/impact-preview system.
- Runtime observations conflict with authoritative coverage output or current
  catalog identity cannot be established.
- Paint footprint credibility requires a visual/product decision the owner has
  not accepted.
- A destructive migration, dependency change, or unrelated worktree cleanup
  appears necessary.
