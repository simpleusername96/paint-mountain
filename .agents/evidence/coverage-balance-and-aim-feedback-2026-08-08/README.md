---
type: evidence
status: archived
created: 2026-08-08
last_reviewed: 2026-08-08
scope: two-times projectile, attainable coverage curve, and latest-only first-impact prediction
related:
  - ../../execplans/2026-08-08-coverage-balance-and-aim-feedback.md
  - ../../execplans/2026-08-08-projectile-scale-balance-and-aim-performance.md
  - ../../../docs/source-brief.md
  - ../../../docs/test-checklist.md
---

# Projectile Scale, Coverage Balance, and Aim Performance Evidence

## Implemented Candidate

- Root physical/visible radius: `2.40 m`.
- Continuous/impact paint radii: `2.80 m` / `3.50 m`.
- Clear targets: Stages 01-10 `4.0..8.5%`; Stages 11-15 `8.5%`;
  16-20 `9.0%`; 21-25 `9.5%`; 26-30 `10.0%`.
- Active catalog:
  `v10-d508dd69d5a1e23085aeb7415dafa9b574fac62e2e691db9571292fbdb4ad665`.
- Runtime predictor: one replaceable active job, at most 12 exact steps and
  approximately 1 ms per physics callback, current-context publication only.

## Balance Bound

The old Stage 30 target required about `480.7 m2` per available shot and an
idealized `79 m` of new, overlap-free contact after doubling the paint radii.
The new `10%` target requires about `320.5 m2` and roughly `50 m` per shot. Stage
01 remains a low-precision teaching target at about `90.8 m2` and `9 m` per
shot. These are comparison bounds, not authored routes or solver guarantees.

## Prediction Measurements

All probes used Godot `4.7.1.stable.official.a13da4feb`, the production stage
worlds, their current baked layouts, and the default launch context.

Before:

| Stage | Steps | 24-step batches | Total work | Slowest batch |
| --- | ---: | ---: | ---: | ---: |
| 01 | 71 | 3 | 3.414 ms | 1.987 ms |
| 10 | 70 | 3 | 2.050 ms | 0.911 ms |
| 30 | 84 | 4 | 2.156 ms | 0.622 ms |

After, direct 12-step batches:

| Stage | Steps | Batches | Total work | Slowest batch |
| --- | ---: | ---: | ---: | ---: |
| 01 | 68 | 6 | 2.101 ms | 0.531 ms |
| 10 | 68 | 6 | 1.969 ms | 0.513 ms |
| 30 | 81 | 7 | 2.462 ms | 0.530 ms |

After, actual scheduler:

| Stage | Settled | Physics ticks | Nominal fixed-tick latency | Observed max callback |
| --- | --- | ---: | ---: | ---: |
| 01 | yes | 6 | 100 ms | 0.498 ms |
| 10 | yes | 6 | 100 ms | 0.726 ms |
| 30 | yes | 9 | 150 ms | 1.089 ms |

The 1.089 ms Stage 30 observation is the permitted one-step overrun after the
time check; the scheduler guarantees forward progress and checks the budget
after each exact collision step. The retained probe is
[`prediction_performance_probe.gd`](prediction_performance_probe.gd).

## Completed Validation

- New catalog generation and content-addressed promotion: passed, 30 stages.
- v9 physical terrain, Target Area mask, cannon transform, and placement
  comparison: passed. Bounded witnesses were intentionally rematerialized for
  the larger body.
- Projectile range admission and Stage 01/30 reconstruction: passed.
- 100 exact top/ramp/ridge/shell CCD contacts: passed.
- Persistent rest/wake, surface recovery, miss cleanup, and continuous paint:
  passed.
- Mechanisms, rapid two-family Fire, wind wake, Stage 10 Fire independence,
  scheduler replacement, and no pending text: passed.
- `scripts/verify.ps1` passed import, parsing, and main-scene startup after the
  final production changes.
- The repository-wide historical suite is not wholly green because five
  unrelated stale contracts remain: `phase6_content_test.gd` expects retired
  legacy IDs/save semantics; `camera_safety_test.gd` references the absent
  `CameraDirector.AIM_FRAME_MARGIN`; `phase8_hud_truth_test.gd` expects an old
  standalone HUD visibility rule; `phase8_debug_test.gd` expects retired debug
  actions/checksums; and `phase8_replay_process_test.gd` assumes the old shot
  settlement sequence. The focused tests for this change and the remaining
  current gameplay, UI, localization, replay-presentation, and persistence
  checks passed. None of the stale files is task-owned.

## Delivery Evidence

- The `Windows Desktop` release export produced
  `builds/windows/PaintMountain.exe`; a separate hidden normal start remained
  alive for five seconds and was then stopped by its exact task-owned PID.
- The exported executable produced these Korean Compatibility-renderer captures
  at 1280x720, and each was opened and inspected at native resolution:
  - [`stage-01-aiming-ko-1280x720.png`](stage-01-aiming-ko-1280x720.png): the
    enlarged launch setup, complete arc, first-impact marker, controls, and HUD
    are legible without clipping.
  - [`stage-10-aim-change-ko-1280x720.png`](stage-10-aim-change-ko-1280x720.png):
    changing aim retains a subdued prior arc without calculation/update copy or
    spinner, and Fire remains enabled.
  - [`stage-30-scale-contact-ko-1280x720.png`](stage-30-scale-contact-ko-1280x720.png):
    the doubled live body is clearly readable during an authoritative terrain
    paint contact, with no HUD overlap or clipping.
