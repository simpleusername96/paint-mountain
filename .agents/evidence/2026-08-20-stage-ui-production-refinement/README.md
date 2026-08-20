---
type: evidence
status: active
created: 2026-08-20
last_reviewed: 2026-08-20
scope: physical score samples, catalog migration proof, release artifacts, and full-viewport UI evidence for the active stage/UI production refinement plan
related:
  - ../../execplans/2026-08-20-stage-ui-production-refinement.md
  - ../../../docs/reports/stage-design-analysis-2026-08-20/index.html
  - ../../../docs/reports/ui-refinement-audit-2026-08-20/index.html
---

# Stage and UI Production Refinement Evidence

This directory retains the generated evidence named by the active ExecPlan.
Automated score samples prove only that a deterministic physical attempt ran to
an authoritative result for the named stage and deal seed. They do not prove
human difficulty, comprehension, solution variety, retry rate, or fun.

## Evidence index

- `v11-score-baseline.json`: complete. Forty-eight Stage 07-30 samples using the
  canonical v11 default deal and first New Deal seed; 48 authoritative Results,
  17 clears. Stage 18-30 sampled scores range from 0.6 to 9.0 and directly
  informed the evidence-adjusted initial v12 band table.
- `v12-score-calibration.json`: pending.
- `catalog-migration.txt`: complete. The immutable 92-file v11 bundle remains
  unchanged; the 92-file content-addressed v12 bundle is active and all 30
  world/layout payloads pass semantic migration comparison.
- `captures/`: pending full-viewport production screenshots.
- `release-artifacts.txt`: pending final Windows/Web hashes and sizes.
