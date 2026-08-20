---
type: evidence
status: active
created: 2026-08-20
last_reviewed: 2026-08-21
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
- `v12-score-calibration.json`: complete. Forty-eight pre-participation
  Stage 07-30 physical samples produced 46 clears and two failures; score range
  was `0.5285..10.8542`, so no authored band moved. Only 12/48 samples painted
  both colors, which exposed why v13 must require real Red/Green and special-kind
  target participation instead of treating an in-band score as sufficient.
- `catalog-migration.txt`: complete. The immutable 92-file v11 bundle remains
  unchanged; the 92-file content-addressed v12 bundle is active and all 30
  world/layout payloads pass semantic migration comparison.
- Active v13 bundle
  `v13-3dc3d250d019c1e699822c6f235beb3fd4917d72cc5a3284bee6857d4bd10b35`
  preserves all compared v12 world/layout/Stage 01-06 inputs and adds 30 sealed
  static feasibility sidecars covering 480 deterministic deals with zero
  gameplay-scene instantiations.
- Final full-viewport production screenshots and current artifact hashes are
  indexed in `../2026-08-21-stage-ui-final/README.md`.
- Local built-Web Stage 03/07/18/30 real-Fire journeys pass. Public itch was not
  changed, and no evidence here proves human difficulty, solution variety, or
  fun.
