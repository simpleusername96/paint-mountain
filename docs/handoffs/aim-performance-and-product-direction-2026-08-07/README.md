---
type: handoff
status: done
created: 2026-08-07
last_reviewed: 2026-08-07
scope: consumed next-session handoff for aim freedom, interaction latency, and plan cleanup
source: user feedback on 2026-08-07 and .agents/evidence/2026-08-07-aim-performance-product-audit.md
related:
  - ../../../.agents/evidence/2026-08-07-aim-performance-product-audit.md
  - ../../../.agents/Documentation.md
  - ../../source-brief.md
  - ../../../.agents/design/UIUX_GUIDELINES.md
  - ../../../.agents/execplans/2026-08-03-gameplay-visual-reset.md
  - ../../../.agents/execplans/2026-08-07-target-coverage-and-safe-aim-framing.md
  - ../../../.agents/execplans/2026-08-07-cannon-shot-observation.md
---

# Aim and Responsiveness Next-Session Handoff

This handoff was consumed on 2026-08-07. The later user direction rejects the
suggested extra Aim Lock gesture and timing pass, and adds a cannon-side wind
flag, physical cannon standoff, a foreground-cannon/distant-mountain Aim View,
and automatic Shot Follow with early return. The active authority is
`.agents/execplans/2026-08-07-cannon-shot-observation.md`; the notes below are
historical context only.

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

The abandoned recovery edits to the gap audit, recovery ExecPlan, and direct
certificate classes were restored to the committed baseline. Obsolete v7
catalog copies, the authored-solution test/runner, the exhaustive-certificate
runner, and orphan UID files were removed. The pre-existing
`src/cannon/trajectory_predictor.gd` and `tests/target_mask_test.gd` edits remain
outside this cleanup and must not be staged or reverted without a separate
provenance decision. The committed production pointer remains v8.

## Disposition

- Preserve stationary manual yaw/elevation/power and no post-fire steering.
- Keep Map View for deliberate orbit/zoom; do not add the proposed independent
  Aim Lock camera gesture.
- Replace debris with a cannon-side flag, restore at least 70 m of physical
  standoff, and compose a large foreground cannon against the complete distant
  mountain.
- Follow the newly launched root paintball automatically and provide one visible
  return-to-cannon action. Do not average all resident balls.
- Treat roughly three seconds as flight-feel guidance, not an exact rule. Do not
  run the previously proposed timing/profiling pass.
- Do not restore click-to-target solving, exhaustive target-wide certificates,
  authored success routes, or all-stage solution playthroughs.

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
- Do not revive `phase6_solution_test.gd` as a required success-route gate. It
  and its `scripts/test.ps1` entry were removed during handoff cleanup.
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
