---
type: evidence
status: active
created: 2026-08-10
topic: essential-ui-fidelity
scope: Windows release captures and reference comparisons for EUI-13
source: ../../reports/screen-audit-2026-08-10/assets/refined/
related:
  - ../../../.agents/execplans/2026-08-10-essential-ui-fidelity.md
  - ../../../design-qa.md
  - ../../test-checklist.md
---

# Essential UI Fidelity Evidence

## Purpose

Index the exported-runtime captures and normalized comparisons used to close
EUI-13. Generated reference images are design sources; only the Windows release
captures are implementation evidence.

## Sources

- Approved design sources:
  `docs/reports/screen-audit-2026-08-10/assets/refined/`.
- Shipped implementation commit:
  `3fe50727e89002ebc49adc244dd73ad9de144a3f`.
- Exported executable: `builds/windows/PaintMountain.exe`, created through the
  canonical `Windows Desktop` release preset, SHA-256
  `13D098963544B4878D648370E35C9402139D0AE1D75D81A66A4AE1D97611E2DB`.

## Runtime Capture Matrix

Korean `1280x720`:

- `runtime/ko-1280x720-main-menu.png`
- `runtime/ko-1280x720-stage-select.png`
- `runtime/ko-1280x720-briefing.png` (Stage 02)
- `runtime/ko-1280x720-aiming.png` (Stage 02 matrix state)
- `runtime/ko-1280x720-map-inspection.png`
- `runtime/ko-1280x720-shot-follow-impact.png`
- `runtime/ko-1280x720-pause.png`
- `runtime/ko-1280x720-settings.png`
- `runtime/ko-1280x720-manual-result.png`
- `runtime/ko-1280x720-timeout-result.png`
- `runtime/ko-1280x720-aiming-stage30.png` (additional same-state Aim QA)

English `1920x1080`:

- `runtime/en-1920x1080-main-menu.png`
- `runtime/en-1920x1080-stage-select.png`
- `runtime/en-1920x1080-aiming.png`
- `runtime/en-1920x1080-settings.png`
- `runtime/en-1920x1080-manual-result.png`

Korean `1600x900`:

- `runtime/ko-1600x900-stage-select.png`
- `runtime/ko-1600x900-settings.png`

## Comparison Sheets

- `comparisons/01-main-menu-comparison.png`
- `comparisons/02-stage-select-comparison.png`
- `comparisons/03-briefing-comparison.png`
- `comparisons/04-aim-view-comparison.png` (Stage 30 on both sides)
- `comparisons/08-settings-comparison.png`
- `comparisons/09-manual-result-comparison.png`
- `comparisons/10-timeout-result-comparison.png`

Each comparison is `2560x764`: a 44 px label band above equal `1280x720`
halves. References were resized proportionally and centered with at most one
padding pixel; runtime images remain native and unstretched.

## Findings

- All 18 capture processes exited with code 0 and produced the expected native
  dimensions.
- The seven final comparison sheets and all responsive/supporting captures were
  opened and inspected directly.
- Visible copy, shortcut ownership, semantic boundary use, hierarchy, action
  prominence, safe margins, focus/disabled/selected states, localization fit,
  and world obstruction satisfy the ExecPlan.
- The initial Aim sheet used different source/runtime stages. The additional
  Stage 30 runtime capture corrected that evidence mismatch before final review.
- No actionable P0, P1, or P2 design difference remains. The full decision and
  accepted P3 differences are recorded in `design-qa.md`.

## Verification

- Focused Godot UI, localization, shortcut, HUD, and camera checks: passed.
- `scripts/verify.ps1`: passed.
- Windows Desktop release export: passed.
- Product Design QA: `final result: passed`.

## Limitations

- Static captures do not demonstrate animation timing. Focused behavior tests
  retain that responsibility.
- Procedural world pixels intentionally differ from the generated references;
  the references govern UI hierarchy and composition rather than terrain mesh
  identity.
