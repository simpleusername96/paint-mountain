---
type: evidence
status: active
created: 2026-08-10
scope: validation and release-render evidence for two-times active gameplay, wall-clock duration tiers, and passive message UI retirement
related:
  - ../../execplans/2026-08-10-double-pace-and-quiet-feedback.md
  - ../../../docs/source-brief.md
  - ../../../docs/test-checklist.md
---

# Double Pace and Quiet Feedback Evidence

## Purpose

Record the automated, release, and visual evidence for two-times active
gameplay, wall-clock duration tiers, and removal of passive message UI.

## Sources

- The completed execution contract linked in frontmatter.
- Focused Godot 4.7.1 checks, `scripts/verify.ps1`, the Windows release export,
  and the task-owned release captures below.

## Findings

The stabilized Godot 4.7.1 source, Windows release export, and three release
capture processes passed. Active board play uses time scale 2.0 on the retained
60 Hz wall-clock physics callback rate. Prediction uses the matching 1/30
simulation step, and stage durations resolve to 60/90/120 wall-clock seconds.
The two passive message components and their exclusive wiring/localization are
absent while sealed shot and mechanism facts remain.

## Automated validation

The following direct Godot checks exited 0:

- `gameplay_pace_test.gd`, `stage30_progression_test.gd`, and
  `phase4_state_test.gd`: fixed 60 Hz, active 2.0 scale, normal briefing/pause/
  result scale, real-tick clock, 60/90/120 tiers, and timeout behavior.
- `prediction_scheduler_test.gd`, `terrain_aim_solver_test.gd`,
  `aim_interaction_test.gd`, `projectile_range_constraint_test.gd`,
  `prediction_projectile_parity_test.gd`, `stage10_prediction_readiness_test.gd`,
  and `predicted_contact_long_flight_test.gd`: bounded 1/30 prediction,
  unchanged catalog readiness, and predicted/live long-flight contact within
  0.165 simulation seconds.
- `phase3_projectile_paint_test.gd`, `fixed_mountain_catalog_test.gd`, and
  `baked_stage_layout_test.gd`: representative live paint and retained v10
  catalog/layout loading.
- `shot_follow_camera_test.gd`: 24-callback/0.4-wall-second impact hold and
  camera-only Return to Cannon.
- `shot_feedback_test.gd`, `phase7_ui_test.gd`, `phase8_hud_truth_test.gd`,
  `phase7_user_qa_contract_test.gd`, and `localization_ui_test.gd`: removed
  nodes/keys, retained actions, non-overlap, and retained mechanism descriptions.
- `phase8_debug_test.gd`: debug slow motion derives from the active baseline and
  does not change briefing time; diagnostic shot export remains intact.
- `scripts/verify.ps1`: import, global-class registration, script parsing, and
  main-scene startup passed after the final quality corrections.

The repository-wide `scripts/test.ps1` was not rerun because its two known
unchanged baseline defects remain outside this task: `phase6_content_test.gd`
expects legacy stage IDs and `camera_safety_test.gd` references an absent
camera constant. Every test reached by this change was run directly.

## Quality audit

The diff-scoped `$codebase-quality-auditor` pass found two local failure paths:
Pause had been grouped with Result camera handling, and debug slow-motion release
could restore active pace outside Aiming. The final source separates Pause from
Result camera mutation, makes debug scale state-aware, and adds regression
assertions. The corrected focused tests and repository verification passed.
No competing production pace owner, stale message consumer, clock/prediction
mismatch, or unrelated responsibility expansion remains. Delivery-capture-only
time-scale overrides remain isolated fixtures.

## Release validation

Command:

```powershell
& $env:GODOT_BIN --headless --path . --export-release 'Windows Desktop' 'builds/windows/PaintMountain.exe'
```

The final export exited 0. The exported executable then ran the delivery-only
`briefing`, `aiming`, and `shot_follow_impact_hold` captures at 1280x720 in
Korean. All three processes exited 0 with empty stderr.

## Visual inspection

- [release-briefing-stage02-1280x720-ko.png](release-briefing-stage02-1280x720-ko.png)
  (`20D07FF6F1E74A6D85AD9D85B5C7A9B30F639E822DC2CBF6E5CCC006A6A325D5`):
  the former upper-left mechanism card is absent; the central objective,
  Back/Start, world glyph label, Gear, and context legend remain unclipped.
- [release-aiming-stage02-1280x720-ko.png](release-aiming-stage02-1280x720-ko.png)
  (`19FA2F9C6DC09303683AB55090FF305AC810DF81AE3A4D6B8A22F2880B20742F`):
  no top-center shot summary or mechanism message appears; time starts at 01:00,
  shots show 4/4, and coverage, Fire, aim/power, Finish, Gear, and the context
  legend remain aligned without replacement whitespace or overlap.
- [release-impact-hold-stage01-1280x720-ko.png](release-impact-hold-stage01-1280x720-ko.png)
  (`040E1D066925695AAD0D273787F3C50D8FD8C449F2AFC8B9946C871140007B63`):
  the physical impact, paint, 0.4% coverage, 3/4 shots, Finish, Gear, and Return
  to Cannon are readable with no passive summary overlay.

All captures are native 1280x720 release frames. No screenshot proves measured
performance or player outcomes; pace and clock behavior are established by the
runtime contracts and focused tests above.
