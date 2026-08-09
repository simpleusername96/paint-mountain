---
type: evidence
status: done
created: 2026-08-09
scope: projected Aim View terrain-glyph placement and representative Windows-release review
source: ../../execplans/2026-08-09-aim-view-centered-glyphs.md
related:
  - ../../design/ART_DIRECTION.md
  - ../../../docs/test-checklist.md
---

# Aim-View-Centered Glyph Evidence

## Purpose

Record the rejected ridgeline-heavy baseline, the corrected screen-space
placement contract, deterministic catalog validation, and direct review of
representative running-release Aim Views.

## Sources

- Rejected prior release captures:
  `../sparse-instrument-hud-2026-08-09/final-release-aim-stage_02-1280x720-ko.png`,
  `stage_03`, `stage_08`, and `stage_30` in the same directory.
- User clarification on 2026-08-09: “middle” means where the user sees the
  middle of the mountain while aiming, not normalized world elevation.
- Current runtime camera owner: `AimCameraComposer` through
  `CameraDirector._composed_aiming_bookmark()`.
- Current placement owner: `MechanismLoadoutPlanner`.

## Findings

- The rejected implementation ranked local surface Y `0.55..0.85` first. On
  the steep distant mountain this mapped to the skyline instead of the visual
  middle.
- The corrected implementation projects eligible anchors with the canonical
  48-degree, 16:9 composed Aim View and normalizes them inside the projected
  Playable Terrain Surface silhouette.
- The first preference band is `0.38..0.62` from silhouette top to bottom,
  centered at `0.50`; `0.28..0.74` is the bounded fallback band. Mechanism
  score then preserves useful variation inside the band. A complete assignment
  with face-to-camera dot `>= 0.50` is preferred before deterministic fallback,
  and the terrain-draped perimeter must remain inside the symmetric Aim View
  safe frame.
- Stage 30's middle-band median slope is `56.2` degrees, so the former
  `42`-degree center-slope cap excluded nearly every visible middle face. The
  bounded cap is `60` degrees while the stricter `32`-degree footprint
  normal-variation guard remains unchanged.
- Focused placement, exact Stage 30 generation, active bundle verification,
  v10 materialization, baked layout, Stage 02 Burst, Stage 03 route, Stage 08
  Uphill, and representative Aim View composition contracts pass.
- The promoted complete bundle is
  `701b3b63feeee0dc1ce064cc91953fbdab91d90db1f004ef247dc4b8b22d1b4e`.
- `scripts/verify.ps1`, the Windows release export, and all four release capture
  processes exit zero. The implementing agent inspected every capture at native
  size. Stage 30's six glyphs occupy fractions `0.386..0.557`; the two Burst
  glyphs are complete circles rather than grazing crescents.

Final captures:

- `release-aim-stage_02-1280x720-ko.png`
- `release-aim-stage_03-1280x720-ko.png`
- `release-aim-stage_08-1280x720-ko.png`
- `release-aim-stage_30-1280x720-ko.png`

## Recommendations

- Treat “visual middle” as the Aim View silhouette band in future placement
  work. Do not substitute world height, route progress, or viewport center.
- Keep screen-space placement as ordered candidate selection; never weaken
  mechanism truthfulness, footprint consistency, or separation to force a
  visual band.

## Limitations

- Representative captures cover the first Burst, first mixed route set, first
  Uphill, and the densest late-stage mix. They do not replace all-stage manual
  play.

## UI/UX Gate Result

- Level: 3, normal-game world-composition change across representative stages.
- Primary task: read and aim toward terrain glyphs without scanning the foot or
  skyline.
- Viewport/state: Korean 1280x720 Aim View, 24-frame evidence settle.
- Required captures: Stage 02, 03, 08, and 30 from the canonical Windows build.
- Result: passed. All four canonical Windows-release captures show complete,
  readable glyphs on the visual middle of the mountain without skyline/foot
  drift, clipping, or HUD/trajectory obstruction.
