---
type: plan
status: done
created: 2026-08-08
last_reviewed: 2026-08-08
scope: decision record for projectile scale, attainable coverage, and responsive first-impact prediction
related:
  - ../PLANS.md
  - ../Documentation.md
  - ../../docs/source-brief.md
  - ../../docs/design-spec.md
  - ../../docs/technical-architecture.md
  - ../design/DESIGN.md
  - 2026-08-08-projectile-scale-balance-and-aim-performance.md
  - ../evidence/coverage-balance-and-aim-feedback-2026-08-08/prediction_performance_probe.gd
---

# Projectile Scale, Coverage Balance, and Aim Feedback - Decision Record

## Outcome

The product owner delegated the remaining tuning choices and ordered the work to
start from an approximately two-times larger ball. The implementation will use
the exact values below, then rematerialize the fixed catalog with a more
attainable clear curve.

- Root physical and visible ball radius: `1.20 m -> 2.40 m`.
- Continuous paint radius: `1.40 m -> 2.80 m`.
- Impact paint radius: `1.75 m -> 3.50 m`.
- Mass, launch speed, damping, bounce, friction, wind, terrain, target masks,
  mechanisms, shot counts, and stage durations remain unchanged.
- Stages 01-10 retain their current clear targets. Stages 11-30 use stable
  shot-tier plateaus instead of continuing the old area burden escalation:
  Stages 11-15 use `8.5%`, 16-20 use `9.0%`, 21-25 use `9.5%`, and 26-30 use
  `10.0%`.
- Two- and three-star thresholds remain exactly `clear + 2.5` and `clear + 5.0`.
- The approximate first-impact marker remains. Preview computation never blocks
  Fire and never predicts post-contact motion.
- Normal Aim View shows no `CALCULATING TRAJECTORY` or `UPDATING` text. A
  retained old trajectory and marker use only subdued opacity while newer work
  is pending.

## Evidence and Reasoning

The active v10 catalog requires about `90.8 m2` of new target paint per available
shot on Stage 01 and `480.7 m2` on Stage 30. With the chosen two-times paint
radii, the idealized Stage 30 contact length under the old `15%` clear target is
still about `79 m` per shot before overlap, non-target travel, or misses. The new
`10%` endpoint reduces that idealized burden to about `50 m` per shot while
preserving a substantial increase from Stage 01's roughly `9 m` teaching burden.
This arithmetic is a tuning bound, not an authored solution or a proof that a
specific route must be played.

The production-world probe on the current Godot 4.7.1 build measured the default
first-impact prediction as follows:

| Stage | Prediction steps | 24-step batches | Total work | Slowest batch |
| --- | ---: | ---: | ---: | ---: |
| 01 | 71 | 3 | 3.414 ms | 1.987 ms |
| 10 | 70 | 3 | 2.050 ms | 0.911 ms |
| 30 | 84 | 4 | 2.156 ms | 0.622 ms |

The predictor currently also lets a newer aim wait behind obsolete active work.
The selected repair keeps the exact fixed-step collision predictor but limits a
physics callback to 12 steps and approximately 1 ms, and replaces obsolete work
at the next bounded nomination. It avoids a second terrain representation and
preserves current collision identity and endpoint behavior.

## Rejected Alternatives

- Removing the first-impact marker: rejected by the product owner because the
  initial terrain contact remains useful even though later rolling dominates.
- Showing only a partial parabola: rejected because it removes useful contact
  information without fixing the main-thread work policy.
- Increasing only shots: rejected because it repeats weak shots and lengthens
  the short planning loop.
- Retaining the old Stage 11-30 clear curve after the scale change: rejected
  because late-stage per-shot burden still grows too sharply.
- A terrain-only approximate predictor or background physics queries: rejected
  for this pass because the bounded exact predictor can be repaired without a
  second collision truth or thread-safety risk.
- Exhaustive target certificates, persisted solution routes, or an all-stage
  manual clear checklist: excluded by the effective source brief.

## Implementation Boundary

`ProjectileData` and `basic_paintball.tres` own scale. `StageProgressionData`
and the content-addressed catalog builder own clear/star values.
`TrajectoryPredictionScheduler` owns work replacement and budgets;
`TrajectoryPredictionJob` remains the sole integration/contact implementation.
`TrajectoryPreview` owns the subdued pending presentation. The separate active
execution contract records implementation and validation.
