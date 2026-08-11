---
type: evidence
status: active
created: 2026-08-11
topic: Stage Select readiness and production transition
source: builds/windows/PaintMountain.exe
related:
  - ../../../.agents/execplans/2026-08-11-stage-selection-readiness-deployment.md
  - ../../test-checklist.md
---

# Stage Selection Readiness Evidence

## Purpose

Verify the repaired path where the player selects a stage that differs from the
persisted current stage, waits for truthful readiness, and starts that exact
stage. The timing begins at the real Stage Select card press and ends when the
selected stage becomes Start-ready or visible.

## Root cause and correction

- Stage Select intentionally kept its choice local until Start, but AppRoot
  accepted layout and artifact completion only when it matched the older
  `GameState.selected_stage_id`.
- The requested artifact reached the cache while matching hidden Gameplay was
  never installed. Start therefore stayed disabled indefinitely.
- AppRoot now owns a separate latest-requested stage identity. Layout,
  artifact, Gameplay success, failure, and stale-completion guards use that
  identity; GameState still changes only through the existing Start path.

## Production evidence

- `stage_01-to-stage_30-release.log`: Godot 4.7.1 Windows/Compatibility release
  telemetry from real Stage Select page/card/button interaction.
- `stage_01-to-stage_30-briefing-1280x720.png`: settled Korean Stage 30
  Briefing after the transition.
- Stage 01 to Stage 30 card press → Start-ready: **679.278 ms**.
- Stage 01 to Stage 30 card press → visible Briefing: **695.411 ms**.
- The largest Stage 30 artifact slice was 12.015 ms.
- The implementing agent inspected the 1280x720 capture at native size. The
  Stage 30 terrain, ground, sky, mechanisms, Korean copy, buttons, and framing
  are complete; no loading state, clipping, or debug overlay remains.

## Validation

- New focused regression: passed; Stage 02 prepared while GameState remained
  Stage 01, then entered immediately after Start.
- Existing Stage Select/UI, layout repository, and runtime preparer checks:
  passed.
- `scripts/verify.ps1` and the complete ordered test suite: passed.
- Fresh Windows and Web release exports: passed.
- Web static validator: 12 files, 49,714,835 raw bytes, 17,301,788 gzip bytes;
  passed the itch.io and project payload limits.
- Local Chrome WebGL2/Compatibility single-thread smoke: Main Menu loaded,
  Stage 02 changed from loading to Start-ready and entered its Briefing; no
  browser console warning or error was observed. Background automation timing
  is not used as a Web performance claim.
- Canonical Windows executable SHA-256:
  `3827C12BAB6082FF33F65CCE41A40D508AEC40C679B48F92AD5E52B4746DFB3C`.
