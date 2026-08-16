---
type: evidence
status: active
created: 2026-08-10
last_reviewed: 2026-08-10
scope: final combined visual review of the approved-image fidelity correction
source: ../../../docs/reports/screen-audit-2026-08-10/index.html
related:
  - README.md
  - ../../execplans/2026-08-10-approved-image-fidelity-correction.md
  - ../../design/ART_DIRECTION.md
  - ../../design/UIUX_GUIDELINES.md
---

# Approved Image Fidelity Correction — Design QA

## Purpose

Judge the exported Windows runtime against the seven approved refined images
after correcting the earlier implementation's material, scale, typography,
icon, control, spacing, and world-occupancy differences. Each judgment used a
single combined image with the approved source on the left and the final
1280x720 Korean runtime on the right.

## Sources

- Approved images: `docs/reports/screen-audit-2026-08-10/assets/refined/`
- Final runtime captures: `runtime/`
- Combined comparison sheets: `comparisons/`
- Exported executable: `builds/windows/PaintMountain.exe`
- Shared visual rules: `.agents/design/ART_DIRECTION.md` and
  `.agents/design/UIUX_GUIDELINES.md`

## Findings

Severity definitions: P0 blocks use, P1 breaks the primary flow, P2 is an
actionable visual mismatch against the approved direction, and P3 is a
non-blocking polish or content-level difference.

| Screen | P0 | P1 | P2 | P3 | Final judgment |
| --- | ---: | ---: | ---: | ---: | --- |
| Main Menu | 0 | 0 | 0 | 1 | The title/action lane and large right-side faceted mountain are recognizable. The ground seam and full-screen wash are gone. The real Stage 01 silhouette and dressing differ from the generated topology by design. |
| Stage Select | 0 | 0 | 0 | 1 | The warm field, eight large cards, selected state, detail hierarchy, paging, and low Start action match the approved composition. The runtime uses slightly denser cards so eight stages remain legible and reachable at the baseline size. |
| Briefing | 0 | 0 | 0 | 1 | The real terrain now owns the central frame, while identity, Back/Start, Gear, and the single interaction guide remain clear. Real Stage 02 topology and glyph placement replace the generated illustrative mountain. |
| Aim View | 0 | 0 | 0 | 1 | HUD geometry remains stable and the terrain is neutral rather than blue. Glyphs, trajectory, paint, target area, and the small cannon remain readable. Terrain topology is authoritative runtime content, not copied pixels. |
| Settings | 0 | 0 | 0 | 1 | The two-column rhythm, seven real icons, three live values, blue sliders, full-size switch states, selectors, and actions match the approved screen without clipping. Captured preference values remain authoritative runtime state rather than the sample values shown in the generated image. |
| Manual Result | 0 | 0 | 0 | 1 | The compact right panel now has the approved title/value/fact/action hierarchy and leaves the mountain unobstructed. The real result terrain and paint location differ from the illustrative source. |
| Timeout Result | 0 | 0 | 0 | 1 | The shared result hierarchy, coral clock reason, coverage value, facts, and action stack match the approved direction. The real timeout paint path remains authoritative gameplay evidence. |

The P3 items are expected content differences caused by using the actual stage,
paint, preferences, and generated topology. None indicates a missing asset,
wrong layout owner, clipping, overlap, decorative seam, repeated shortcut, or
rejected material cast.

## Recommendations

- Keep explanatory copy in a future guidebook, first-run tutorial, or UI guide;
  do not restore it to normal play screens.
- Preserve the shared Stage Card, Settings control, and Result semantic roles
  when later screens are added.
- Re-run the same combined-image gate after a material, camera-safe-rectangle,
  shared Theme, or baseline-resolution change.

## Limitations

- Generated reference terrain is art direction, not stage geometry. The runtime
  must keep its baked playable terrain, real mechanisms, paint, and coverage.
- The capture runner records deterministic screen states, but preference values
  and fullscreen state remain truthful to the capture environment.
- This review covers the seven approved screens plus Stage Select and Settings
  fit at Korean 1600x900 and English 1920x1080. It does not redesign Map View,
  Shot Follow, Pause, tutorial, or guidebook surfaces.

final result: passed
