---
type: evidence
status: active
created: 2026-08-08
scope: player-replay retirement validation
source: ../../execplans/2026-08-08-instant-approximate-landing-feedback.md
related:
  - ../../../docs/source-brief.md
  - ../../../docs/test-checklist.md
  - ../../Documentation.md
---

# Player-Replay Retirement Evidence

## Purpose

Record focused runtime, UI, and production evidence for the approved removal of
the player replay feature.

## Sources

- `result-ko-1280x720.png`: Windows release build, Compatibility renderer,
  background capture of the real manual-result state.
- Focused Godot checks: `phase8_hud_truth_test.gd`,
  `localization_ui_test.gd`, `shot_feedback_test.gd`,
  `phase8_debug_test.gd`, and `phase4_state_test.gd`.
- `scripts/verify.ps1` for import, parse, and main-scene startup.

## Findings

- The result panel retains Retry, Next Stage, and Stage Select and contains no
  Replay action or playback bar.
- Direct inspection of the 1280x720 Korean capture found no clipped or
  overlapping result text, controls, or panel bounds.
- The alternate-name Windows release export completed successfully. The
  background capture process exited with code 0 and wrote a 1280x720 PNG.
- Attempt observations and debug JSON export pass without a replay format,
  playback scheduler, or replay-origin action lock.

## Limitations

- The canonical `builds/windows/PaintMountain.exe` was not overwritten because
  Godot could not rename its temporary embedded-PCK file over the existing
  artifact. The identical release preset exported successfully as
  `PaintMountainReplayRemoval.exe`; build outputs remain ignored.
