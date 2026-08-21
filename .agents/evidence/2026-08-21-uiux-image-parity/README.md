---
type: evidence
status: active
created: 2026-08-21
last_reviewed: 2026-08-21
topic: Production Windows render evidence for the approved icon-first UIUX TO-BE parity pass
scope: Korean 1280x720 reference states, 640x360 stress states, Aim score fixtures, special-ball details, and same-viewport comparisons
source: ../../../builds/windows/PaintMountain.exe
related: ../../execplans/2026-08-21-uiux-image-parity.md
---

# UIUX Image Parity Evidence

This folder retains full-viewport images from the production Windows export.
Run `recapture.ps1` from the repository root to recreate the deterministic batch.

The comparison sheets place each selected TO-BE reference beside the matching
production frame at the same 1280x720 viewport. Score/result captures use the
existing delivery-only deterministic presentation fixtures; gameplay rules and
authoritative runtime owners are unchanged.

## Source and totals

- Implementation commit: `311d3d6` (`feat: implement approved icon-first UIUX`)
- Runtime: Godot 4.7.1 stable, Compatibility renderer, Korean locale
- Windows executable: `119,314,240` bytes
- Windows SHA-256:
  `6FFD498F6679295B72F5A1176C5288B5DB959431B9676EB2E1800D235D99CF39`
- Evidence: 40 PNG files, 24,090,923 bytes total
- Batch: 27 full-viewport production captures, 10 reference/current comparison
  sheets, and 3 compact overview sheets
- Process cleanup: no `PaintMountain` process remained after the sweep

## Coverage

- `01-12`: the complete selected 1280x720 composition set—Main Menu hover,
  Stage Select plus Briefing, Aim entry/center/overflow, special-ball detail,
  Map, Shot Follow, Pause, Settings, Clear, and Failure.
- `13-22`: compact 640x360 focus/stress captures for all selected surfaces.
- `23-27`: Stage 12/24 ball details, Stage 09 negative score, Stage 06 zero
  weight, and the Stage 30 rail window.
- `compare-01` through `compare-10`: TO-BE on the left and production on the
  right. Each source was normalized to the same 1280x720 viewport before being
  joined; production images were not stretched or cropped.

## Visual inspection

- Actions: pass. Visible action text is absent; routine actions do not introduce
  white button surfaces; one filled-blue primary is retained per state.
- Aim score: pass. The only live bar is the authored minimum-to-maximum success
  range with internal star tiers and an authoritative marker. Total paint stays
  numeric, and the red/green roles use distinct real icon shapes plus signs.
- Ball detail: pass. One white queue-anchored information surface appears at
  Stages 08, 12, and 24 and remains inside both standard and compact viewports.
- Alignment and overflow: pass. The 24/12 px safe-margin presets, action rails,
  score/result spines, Settings header, and compact content stay inside the
  complete viewport without visible clipping or overlap.
- Flow: pass. Stage Select contains briefing truth, and the production capture
  enters Aim without showing a standalone Briefing surface.
- Selected-reference parity: pass for composition, hierarchy, surface use, and
  action language. Expected pixel differences are limited to authoritative live
  terrain/camera data, deterministic fixture values, and Godot font/render
  rasterization; they do not add or remove UI regions.

## Validation

See `validation-summary.txt`. The full ordered suite, focused post-audit checks,
final verification, release export, and all 27 production captures exited 0.
