---
type: plan
status: done
created: 2026-08-08
last_reviewed: 2026-08-08
scope: implement the selected two-times projectile scale, attainable target curve, and bounded latest-first aim prediction
related:
  - ../PLANS.md
  - ../Documentation.md
  - ../../AGENTS.md
  - ../../docs/source-brief.md
  - ../../docs/design-spec.md
  - ../../docs/technical-architecture.md
  - ../../docs/test-checklist.md
  - ../design/DESIGN.md
  - 2026-08-08-coverage-balance-and-aim-feedback.md
---

# Two-Times Projectile, Attainable Coverage, and Responsive Aim Prediction

## Purpose

Make each shot visibly and physically more consequential, reduce the late-stage
clear burden, and remove the real Aim View hitch without removing the advisory
first-impact marker.

## Locked Decisions

- Set root radius to `2.40 m`, continuous paint radius to `2.80 m`, and impact
  paint radius to `3.50 m`. Keep mass and all other projectile dynamics.
- Keep existing clear targets for Stages 01-10. Set Stages 11-15 to `8.5%`,
  16-20 to `9.0%`, 21-25 to `9.5%`, and 26-30 to `10.0%`. Keep four/five/six/
  seven-shot tiers and star offsets of `+2.5/+5.0`.
- Rematerialize the immutable thirty-stage catalog; do not change terrain,
  target masks, cannon transforms, mechanisms, or coverage metric 2. Recompute
  bounded default/summit witnesses because physical projectile scale changes
  their launch clearance and first-contact facet.
- Keep the fixed 60 Hz exact prediction job and collision identities. Limit one
  scheduler callback to at most 12 steps and approximately 1 ms, cancel an
  obsolete active job when the next nominated live context replaces it, and
  publish only a result whose context is still current.
- Keep Fire independent from preview readiness. Keep the last complete arc and
  first-impact marker at subdued opacity while pending. Remove the pending
  Label3D and the now-dead aiming calculation/update translation keys.
- Add no dependency, solver, shipping hint, post-impact prediction, or second
  paint/terrain authority.

## Ownership

- `resources/projectiles/basic_paintball.tres` and `ProjectileData`: physical,
  visible, and paint radii.
- `StageProgressionData` plus `scripts/build_stage_catalog.gd`: target/star data
  and content-addressed materialization.
- `TrajectoryPredictionScheduler`: nomination, replacement, bounded per-tick
  work, diagnostics, and current-only publication.
- `TrajectoryPredictionJob`: unchanged fixed-step trajectory/contact truth.
- `TrajectoryPreview` and `translations/ui.csv`: pending presentation copy.
- Existing focused tests: numeric scale/curve, catalog preservation, Fire
  independence, stale-work replacement, work bounds, and no pending text.

## Ordered Tasks

- [x] Change the typed projectile resource and its scale contract tests.
- [x] Change the progression curve and exact endpoint/tier tests.
- [x] Build, verify, and promote the new immutable catalog; confirm all physical
  layouts, target masks, cannon transforms, mechanisms, and bounded witnesses
  remain identical to the prior active v10 bundle.
- [x] Replace stale predictor work, add the 12-step/1 ms callback budget and
  diagnostics, and remove visible calculation/update text while retaining the
  dimmed complete marker.
- [x] Run focused projectile, paint, progression, catalog, prediction, Fire,
  localization, and gameplay startup contracts.
- [x] Measure Stage 01/10/30 prediction batches after the change and confirm the
  default settled marker publishes within 0.5 seconds in the production-style
  build without a stale publication.
- [x] Run `scripts/verify.ps1`, then the codebase quality audit. Correct only
  small task-scoped findings.
- [x] Export the Windows release, start it in the task-owned background path,
  and inspect running-game captures of Aim View and projectile contact at
  representative early/late stages.
- [x] Update implemented-state/test records, mark this plan done, and commit
  only task-owned files.

## Acceptance Checks

- The root ball renders and collides at exactly twice the prior radius; split
  children retain their existing `0.78` multiplier. Paint stays wider than the
  ball in the same prior proportions.
- Active Stage 01 and Stage 30 clear targets are `4.0%` and `10.0%`; every clear
  target is nondecreasing and every star vector is ordered.
- Catalog physical and target-mask identities are unchanged except for
  target/star rule values, scale-valid bounded witnesses, and content-addressed
  identity.
- A new aim never waits for an obsolete job to finish, no stale result publishes,
  Fire stays available under canonical rules, and no normal aiming calculation
  or updating text appears.
- Per callback work is structurally capped at 12 steps and runtime-budgeted near
  1 ms. Stage 01/10/30 default markers settle in at most 0.5 seconds in the
  measured production-style run.
- Godot verification, release export/start, and inspected real renders pass.

## Regression Guards and Contingencies

- If the doubled body starts overlapping the muzzle/world, adjust only the
  shared ballistic launch origin clearance and its tests; do not shrink the ball
  silently.
- If catalog materialization changes physical layout or target masks, stop and
  reject the bundle rather than publishing it.
- If 1 ms cannot complete even one prediction step reliably, keep the one-step
  forward-progress rule, report the observed overrun, and do not fake a lower
  timing claim.
- If a doubled ball breaks contact recovery or glyph behavior, fix only the
  scale-dependent invariant or stop with the exact failing contract; do not
  retune unrelated mechanism behavior.
- Do not alter user-authored dirty files or unrelated untracked evidence.

## Progress

- Canonical progress is the completed task checklist above.
- Completed with Godot 4.7.1 verification, focused runtime contracts, Windows
  release export/start, and direct inspection of three 1280x720 release renders.
- The associated evidence record retains prediction timings, catalog identity,
  capture paths, and unrelated historical-suite test debt.
