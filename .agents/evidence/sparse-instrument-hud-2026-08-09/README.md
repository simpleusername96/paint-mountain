---
type: evidence
status: archived
created: 2026-08-09
scope: sparse gameplay instruments, immediate terrain aiming, and display-setting stability
related:
  - ../../execplans/2026-08-08-instant-approximate-landing-feedback.md
  - ../../../docs/source-brief.md
  - ../../../docs/test-checklist.md
---

# Sparse Instrument HUD and Immediate Aim Evidence

## Visual direction

- ImageGen mode: edit.
- Inputs: the implemented Stage 30 Aim View and the approved mountain-first
  hierarchy comparator.
- Final prompt intent: preserve the game world, remove tall side and bottom
  cards, use a top icon/number status row, a thin coverage rail, integrated
  A/D, W/S, wheel, Space, Tab, F, and Escape hints, and no persistent prose.
- Output: `imagegen-target-reference.png`.
- Independent AGY review: `agy-review.md`. Its useful findings were the large
  right-card obstruction, fixed-offset bunching, display reapplication in
  Settings, sparse top-row hierarchy, and height-normalized glyph preference.

## Running-game inspection

- `runtime-aim-1280x720-ko.png`
- `runtime-aim-1920x1080-en.png`
- `runtime-settings-1280x720-ko.png`
- `release-aim-1280x720-ko.png`
- `release-aim-1920x1080-en.png`
- `final-release-aim-stage_02-1280x720-ko.png`
- `final-release-aim-stage_03-1280x720-ko.png`
- `final-release-aim-stage_08-1280x720-ko.png`
- `final-release-aim-stage_30-1280x720-ko.png`

The source captures and the two final Windows release captures use the
Compatibility renderer and the actual baked Stage 30 gameplay scene. Both
release processes exited 0 with empty stderr. Direct inspection found:

- the mountain is no longer covered by left/right status cards or a bottom aim
  panel;
- the normal-play prose strip is absent;
- top status, left coverage, centered Fire, and lower-right aim instruments stay
  inside both supported viewports;
- shortcut keycaps are attached to their controlled value/action;
- the first pass exposed a Fire/Space overlap, which was corrected by moving the
  keycap above the Fire button;
- the final Stage 02, 03, 08, and 30 release captures use promoted manifest
  `c45d547056e5421953571cb7aadf07341df02023334754087a3622c97a519c25`;
- Burst, Splitter, and Uphill glyphs sit across the middle/upper and upper
  terrain instead of clustering at the mountain foot;
- a 24-frame evidence-only settle override lets the Aim camera finish without
  allowing unrelated live state to replace the inspected frame.

## Focused runtime facts

- The original synchronous pure inverse pass measured 191,392 microseconds.
- Caching the wind horizon and nominating every eight fixed steps reduced the
  focused deterministic solve below one 60 Hz frame (2,495 microseconds in the
  final focused run; earlier post-change runs measured 6,263 to 7,820).
- Terrain click/drag, target-preserving angle/power edits, immediate Fire
  readiness, and Map View input separation pass in `aim_interaction_test.gd`.
- Passive settings synchronization and non-display setting application leave
  the display mutation count unchanged in `localization_ui_test.gd`.
- Preferred middle/upper-middle glyph ranking passes in
  `mechanism_placement_test.gd`.

## Catalog and delivery verification

- The approved all-30 build completed in 784.2 seconds with exit 0 and empty
  stderr. It promoted one v10 bundle with 30 stages, 30 profiles, and 30 layouts.
- The generation-free catalog check, v10 materialization, baked-layout,
  mechanism placement, and Stage 02/03/08 glyph contracts pass.
- Godot 4.7.1 import/startup verification and the final Windows release export
  pass. All four final glyph captures exited 0 with empty stderr.

UIUX gate evidence:

- Surface: normal-play Aim View and baked terrain glyph composition.
- Invocation depth: Level 4 continuation and final rendered evidence.
- Files/screens touched: sparse HUD, Stage 02/03/08/30 Aim View, Settings.
- Primary task checked: mountain-first hierarchy, integrated controls, and
  middle/upper glyph placement.
- Viewports checked: 1280x720 Korean and 1920x1080 English.
- States checked: Aim View, selected target, Settings, and representative Burst,
  Splitter, Uphill, and mixed-glyph stages.
- Accessibility checks: real controls, visible focus styles, tooltips/localized
  names, and at least 40 px interactive targets remain covered by focused tests.
- Screenshots: the runtime, release, and final-release PNGs named above.
- Exceptions accepted: panels remain only for modal briefing/pause/result and
  the settings form; the normal-play surface stays borderless.
- Remaining warnings: none in the inspected task surface.
- Result: passed.

This completed evidence remains active as consult-only implementation evidence.
