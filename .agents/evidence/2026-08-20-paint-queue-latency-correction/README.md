---
type: evidence
status: active
created: 2026-08-20
last_reviewed: 2026-08-20
scope: deterministic continuous-paint queue latency correction before final production Web validation
related:
  - ../../execplans/2026-08-20-cross-stage-ui-theme.md
  - ../../../docs/reports/itch-paint-latency-2026-08-20/index.html
  - ../2026-08-20-m8-web-latency/README.md
  - ../three-ball-target-band-prototype-2026-08-18/compact-performance.json
---

# Continuous-paint queue latency correction evidence

## Finding

The earlier M8 correction bounded one large Burst radial command, but the
interactive `PaintSystem` still completed at most one `SurfacePaintSweep` per
physics tick. Three active Apex children could therefore produce paint faster
than the consumer completed it. The queue preserved correct order while its
oldest command became seconds old.

An old-policy synthetic reproduction generated 108 commands. Only 33 completed
during production, 75 remained at contact end, and maximum oldest age reached
33 physics ticks. The queue was still non-empty after 12 additional drain
ticks. This directly reproduces the throughput failure described in the Korean
latency report; the earlier two-second example remains a load model, not a
measured public-browser duration.

## Implemented correction

- `PaintRasterCursor` incrementally processes radial and sweep commands through
  deterministic scan, connectivity, and write phases. Disconnected sweeps keep
  the exact two-endpoint-radial fallback.
- Radial and sweep cursors share an 8,192-work-unit physics-tick budget, 64-unit
  chunks, and a 14,500 microsecond time ceiling. Remaining budget can complete
  later small commands in canonical order; a command is acknowledged only when
  fully complete.
- A proven single-component row-overlap path skips unnecessary BFS work. Cases
  that do not satisfy that proof use the exact connectivity traversal.
- A root projectile now emits adjacent same-contact sweeps after 1.0 m of
  accumulated travel instead of 0.05 m. This remains below the 2.8 m paint
  footprint radius, preserves continuous coverage, and never merges across
  contact, collider, channel, or command-order boundaries.
- Read-only queue diagnostics report pending/oldest/queued/completed totals and
  maximum drain work without console output or another paint representation.
- Texture publication remains at the measured 10 Hz cadence because its known
  1.5-2.3 ms Web upload was not the root throughput limit.

## Focused measurements

Godot `4.7.1-stable (official)`, Compatibility renderer, fixed 60 Hz physics:

| Scenario | Result |
| --- | --- |
| Synthetic Burst plus three continuous producers | 28/28 commands completed during production; 0 pending at contact end; maximum age 1 tick; maximum 3 completions/drain; maximum drain 14.719 ms |
| Actual Stage 06, six roots including two Apex families | 57/57 commands; 0 pending after flush; maximum age 4 ticks; maximum pending 4; maximum 4 completions/drain; maximum drain 14.818 ms |
| Actual Stage 06 fixed-step cadence | 239 ticks; average callback interval 16.455 ms; diagnostic p95 20.902 ms; maximum 23.501 ms |
| Deterministic equivalence | completion-barrier and incremental mask bytes, owner bytes, checksum, coverage counts, signal order, and disconnected fallback match |

The actual workload stays inside the ExecPlan's 12-tick queue-age and 16.7 ms
paint-drain limits. The queue drains during production instead of leaving a
seconds-long post-contact tail.

## Passing focused checks

- `tests/paint_queue_determinism_test.gd`
- `tests/paint_queue_latency_test.gd`
- `tests/three_ball_compact_performance_test.gd`
- The adjacent paint ownership, command order, projectile contact/settling,
  Impact Burst, Apex Split, score-rule, and result-rule checks listed in Phase
  6.3 of the active ExecPlan passed on the same implementation.

## Remaining proof boundary

This checkpoint is native focused evidence. Phase 8 still owns the complete
suite, repository verification, fresh Windows/Web exports, and built-Web
running-game inspection after the newly approved all-stage target-band catalog
migration. No public itch artifact was uploaded or inspected for this local
correction.
