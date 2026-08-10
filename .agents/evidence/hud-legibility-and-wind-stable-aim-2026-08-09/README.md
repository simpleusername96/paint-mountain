---
type: evidence
status: archived
created: 2026-08-09
scope: rendered Aim View HUD legibility and wind-stable target-preserving aim edits
source: ../../execplans/2026-08-09-hud-legibility-and-wind-stable-aim.md
related:
  - ../../design/UIUX_GUIDELINES.md
  - ../../../docs/test-checklist.md
---

# HUD Legibility and Wind-Stable Aim Evidence

## Purpose

Record the actual-game visual comparison, external interaction references,
independent AGY review, focused regression results, and canonical Windows-build
captures for the 2026-08-09 Aim View refinement.

## Sources

- User-provided 1280x720 Stage 30 screenshot showing the previous status and aim
  controls.
- Source-game captures in this directory:
  `source-aim-stage30-1280x720-ko.png` and
  `source-low-arc-stage30-1280x720-ko.png`.
- Canonical Windows-build captures in this directory:
  `release-low-arc-stage30-1280x720-ko.png` and
  `release-aim-stage30-1920x1080-en.png`. Both capture processes reported `OK`;
  their retained stderr logs are empty.
- Apple Human Interface Guidelines, Game Controls:
  <https://developer.apple.com/design/human-interface-guidelines/game-controls>
- Microsoft Xbox Game Bar Widget UI:
  <https://learn.microsoft.com/en-us/xbox/game-bar/designguide/widgetui>
- Epic UMG Widgets equipped-item example:
  <https://dev.epicgames.com/documentation/fortnite/umg-widgets-in-unreal-editor-for-fortnite?lang=en-US>
- Hades screenshot reference:
  <https://interfaceingame.com/screenshots/hades-in-game-2/>
- Overwatch 2 screenshot reference:
  <https://kotaku.com/overwatch-2-servers-blizzard-tips-tank-support-damage-1849630441>
- AGY discovery review job
  `20260809T003808289Z-24dc961f-5081-415e-9061-bca78fb7dcef` and comparison
  review job `20260809T005333082Z-f75ddf00-42b9-4646-a3e1-c0c80eb16e38`.
  Their immutable answers remain under the local model-helper job logs.

## Findings

- The prior bare `7` and `0` values made shots and resident activity ambiguous.
- Literal bracketed key names looked like debug annotations, and A/D was a false
  affordance in terrain-target mode.
- Elevation and power values were visually detached from their step controls.
- AGY independently identified the same ammo ambiguity, bracketed legends,
  fragmented aim controls, and redundant A/D prompt.
- The implementation now shows remaining / maximum shots, separates resident
  activity, uses compact filled tokens attached to real actions, and keeps each
  aim value in an inline stepper.
- A Stage 30 selected-target capture shows a successful elevation edit changing
  `28.4 degrees / 100.0%` to `28.9 degrees / 93.4%` while retaining the selected
  terrain point. Focused tests additionally preserve explicit elevation and
  power constraints across later wind epochs.
- AGY's after-review passed mountain dominance, shortcut-to-action association,
  and bottom-control legibility; final spacing adjustments separated the power
  glyph and coverage target from adjacent values.

## UI/UX Gate Result

- Invocation level: 3, screen/flow change.
- Before state: user-provided screenshot plus current source capture.
- Target contract: compact remaining / maximum ammo, separate resident status,
  truthful action-adjacent tokens, inline aim steppers, and no added panels.
- Required final states: selected-target Korean 1280x720 and English 1920x1080
  from the canonical Windows build.
- Result: passed. Both final images were reviewed at original resolution. The
  mountain remains dominant; control tokens are attached to actions; the bottom
  instruments are legible; and no control is clipped or outside the viewport.

## Verification

- Focused Godot checks passed for aim interaction, shortcut prompts, wind/status
  HUD, localization/UI, shot feedback, and phase-7 UI structure.
- `scripts/verify.ps1` passed import, parsing, and main-scene startup with Godot
  `4.7.1.stable.official.a13da4feb`.
- The `Windows Desktop` release export replaced
  `builds/windows/PaintMountain.exe` and both running-release capture states
  completed with empty stderr.
- `git diff --check` passed. The diff-scoped code-quality audit found no
  competing owner, catch-all responsibility, or changed-contract consumer left
  unverified in the task-owned surface.

## Recommendations

- Keep the current token treatment shared and state-aware; do not reintroduce
  bracket syntax or prompts for actions unavailable in the current mode.
- Preserve the selected target as the primary aim intent and keep wind
  compensation invisible unless an explicit edit is no longer feasible.

## Limitations

- Still captures demonstrate hierarchy and selected-target state but cannot by
  themselves prove multi-epoch wind behavior; focused runtime tests own that
  regression evidence.
- External screenshots are advisory references only. No external layout, asset
  pack, or unsupported action is copied into the project.
