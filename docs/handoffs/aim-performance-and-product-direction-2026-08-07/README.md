---
type: handoff
status: active
created: 2026-08-07
last_reviewed: 2026-08-07
scope: next-session continuation for aim freedom, interaction latency, plan cleanup, and bounded product expansion
source: user feedback on 2026-08-07 and .agents/evidence/2026-08-07-aim-performance-product-audit.md
related:
  - ../../../.agents/evidence/2026-08-07-aim-performance-product-audit.md
  - ../../../.agents/Documentation.md
  - ../../source-brief.md
  - ../../../.agents/design/UIUX_GUIDELINES.md
  - ../../../.agents/execplans/2026-08-03-gameplay-visual-reset.md
  - ../../../.agents/execplans/2026-08-07-target-coverage-and-safe-aim-framing.md
---

# Aim and Responsiveness Next-Session Handoff

## Current State

The user is deliberately ending the long session. The next session should fix
the current gameplay feel, not continue old reachability or solver work.

- Implementation baseline before this documentation handoff: `6e820b2`.
- There is no relevant active ExecPlan. The recent aim-framing plan is `done`,
  the earlier aim-view plan is `archived`, and all Aug 3-5 recovery/redesign plans
  are `superseded`.
- The user rejects the current running build's aiming freedom and reports severe
  stutter plus one-to-two-second stalls during top/map interaction and ordinary
  button clicks.
- The current tuple range is already yaw `-80..80`, elevation `10..68`, and power
  `0..100`. The main restriction is the mutually exclusive interaction model:
  Aim Lock can aim/Fire but cannot navigate the camera; Map Inspection can
  orbit/zoom/refocus but blocks aim/Fire.
- The highest-confidence latency cause is the prediction loop, not UI styling:
  running wind emits 60 Hz snapshots, each snapshot dirties prediction, and the
  scene can synchronously execute a predictor with up to 720 shape casts at
  20 Hz. The pre-existing dirty predictor adds endpoint rest probes to that loop.
- Fire also calls the full predictor synchronously before checking readiness.
  This regressed the older Phase 10 constant-work Fire rule.
- Map-to-Aim recomputes full top/summit interest data instead of using one cached
  stage framing result. Stage 30 can scan up to 12,288 top triangles.
- Stage selection has a separate possible cold-path hitch: preview geometry and
  a 256-square preview texture still build on the main thread. Existing exported
  entry measurements were about 1.0 s for Stage 01 and 2.1 s for Stage 30.
- Two current Stage 30 screenshots were captured and inspected. Aim Lock contains
  the whole mountain but makes useful detail tiny; a reachable Map Inspection
  pose loses orientation and gives the mountain little screen area. See the
  linked audit for the images and exact evidence.
- The shared Command Columns HUD, target-area coverage semantics, authoritative
  paint mask, prepared v8 thirty-stage catalog, persistent wind/ball loop, and
  bounded default/summit witnesses remain current unless direct evidence shows a
  separate defect.

### Correction: "trajectory/reachability incomplete changes"

That phrase means **pre-existing uncommitted recovery experiments**, not an
unfinished game feature. Do not tell the user that exhaustive target-wide
certification or successful solution routes are still required.

The following six files were already modified before the latest aim/UI work and
must not be staged, reverted, or bundled without a separate provenance decision:

- `.agents/evidence/2026-08-05-gameplay-contract-gap-audit.md`
- `.agents/execplans/2026-08-05-gameplay-contract-recovery.md`
- `src/cannon/trajectory_predictor.gd`
- `src/stage_generation/direct_reachability_certificate.gd`
- `src/stage_generation/direct_reachability_validator.gd`
- `tests/target_mask_test.gd`

There are also untracked v7 catalog directories, recovery screenshots, and
Stage 30 probe UID files. The committed production pointer is v8. Prior session
logs prove that the v7 recovery run remained partial and dirty; no clean session
committed these six files as one ready change.

## Recommended Direction

Use this as the default proposal when the user asks the next session to proceed:

1. Preserve the stationary cannon, manual yaw/elevation/power, no post-fire
   steering, shared paint authority, and real first-impact preview.
2. Do not add click-to-target inverse solving. It reintroduces the expensive and
   ambiguous solver direction the user has already rejected.
3. Keep left-drag aim and wheel power. Add a separate, discoverable Aim Lock
   camera-navigation gesture, such as right- or middle-drag orbit with a zoom
   modifier, plus one-action recenter. Preserve the aim tuple while navigating.
4. Map Inspection can remain the whole-board overview, but mode switches must use
   cached framing data and acknowledge immediately.
5. Restore constant-work Fire: it reads a ready canonical prediction only. If
   stale, the control responds immediately as prediction-pending; it never
   computes prediction inside the click callback.
6. Split 60 Hz wind presentation from launch-relevant prediction invalidation.
   Schedule/cache prediction by canonical aim plus a bounded wind epoch or time
   bucket instead of dirtying it for every HUD snapshot.

The extra Aim Lock gesture is recommended, not yet user-approved. If the user
instead requests Fire in Map Inspection or click-to-target placement, update the
source brief and create a different interaction contract before coding.

## Next Steps

1. Read root `AGENTS.md`, `.agents/design/DESIGN.md`, this handoff, the linked
   audit, `docs/source-brief.md`, `.agents/Documentation.md`, and the current
   worktree status. Do not read superseded plans as active instructions.
2. Run one bounded diagnostic pass only. Measure these five paths separately:
   wind-running idle, one-second `+/-` hold, Fire, map refocus/orbit, and
   Map-to-Aim. Add stage selection only if the user's "placement" refers to that
   screen. Record prediction count/duration, input-to-visible-response time, and
   camera solve count. Stop once the causal paths are confirmed.
3. Create a new decision-complete ExecPlan under `.agents/execplans/` after the
   measurement and camera gesture decision close discovery. Do not merge into a
   `done`, `archived`, or `superseded` plan.
4. Implement in this order:
   - remove Fire-time synchronous prediction;
   - separate wind display snapshots from prediction invalidation;
   - reduce or gate the dirty endpoint-rest probe on the gameplay path;
   - cache top/summit Aim framing per layout;
   - reduce safety rays to dirty camera poses;
   - then add independent Aim Lock camera navigation;
   - profile stage-preview construction only if a separate selection hitch
     remains.
5. Keep validation proportional. While coding, use the single timing probe and
   focused prediction/camera checks. After the code surface is stable, run one
   `scripts/verify.ps1`, one release export, and fresh Aim Lock/Map Interaction
   captures. Do not run exhaustive target-texel workers, solver clears, all-stage
   playthroughs, or the broad suite merely for reassurance.
6. Ask for foreground user play after the final capture. Passing headless checks
   or fitting all terrain points is not gameplay-feel acceptance.
7. After P0 responsiveness and aiming freedom are accepted, expand in this order:
   - target-area map/heat view and clearer prediction-pending feedback;
   - short practice/tutorial stages and last-shot comparison;
   - aim sensitivity, key remapping, and explicit controller support;
   - optional stage challenges and seeded local challenge presets;
   - only after an explicit scope revision, a local editor; new mechanism
     families remain a separate later product decision.
8. Mark this handoff `done` after the new ExecPlan owns current progress; do not
   keep both documents as competing active task authorities.

## Risks

- Do not send `PhysicsDirectSpaceState3D` work to a thread without current
  primary Godot documentation proving that exact use is safe. A main-thread
  budgeted scheduler is the safer default.
- Do not remove endpoint-rest logic blindly; it was added for concave collision
  parity. First reduce how often it runs or guard it by cheap terrain proximity,
  then retain a focused parity check.
- Do not solve responsiveness by widening FOV. The current Stage 30 screenshot is
  already too distant; wider FOV reduces usable route and impact detail.
- Do not make prediction visually stale without a truthful pending state and a
  canonical aim/wind key. Replay, human, agent, and debug Fire share one
  admission contract.
- Do not revive `phase6_solution_test.gd` as a required success-route gate. The
  normal `scripts/test.ps1` still includes it and needs later cleanup or explicit
  optional classification.
- Do not clean the existing dirty worktree by reset, checkout, or broad commit.
  Its recovery files and v7 artifacts require a separate owner decision.

## Files Touched

This documentation session intentionally changes no Godot production code. Its
owned files are:

- `docs/source-brief.md`
- `docs/design-spec.md`
- `.agents/design/UIUX_GUIDELINES.md`
- `.agents/Documentation.md`
- `.agents/evidence/2026-08-07-aim-performance-product-audit.md`
- `.agents/evidence/aim-performance-handoff-2026-08-07/01-stage-30-aim-lock.png`
- `.agents/evidence/aim-performance-handoff-2026-08-07/02-stage-30-map-inspection.png`
- `docs/handoffs/aim-performance-and-product-direction-2026-08-07/README.md`

## Verification

- The two screenshots were generated from the current Windows release in a
  background capture run and inspected at their native 1280x720 size.
- Root-cause paths were independently traced through current source, `git blame`,
  plan history, and bounded prior-session searches.
- Official comparator research uses current developer/publisher sources and is
  advisory only.
- The document-lifecycle audit recognized the new evidence and handoff with the
  intended types and reported no finding against this task-owned document set;
  its repository-wide nonzero result comes from 12 pre-existing findings outside
  this handoff.
- All relative Markdown links in the task-owned documents resolve, and the
  staged task-owned diff passes `git diff --cached --check`.
- No gameplay test suite, solver worker, stage regeneration, or production-code
  mutation was performed in this documentation session.
