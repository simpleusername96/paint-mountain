---
type: evidence
status: done
created: 2026-08-07
last_reviewed: 2026-08-07
scope: fixed v9 terrain, open play bounds, qualitative Aim View, wind flag, Shot Follow, and release capture validation
source: .agents/execplans/2026-08-07-cannon-shot-observation.md
related:
  - ../execplans/2026-08-07-cannon-shot-observation.md
  - ../../docs/source-brief.md
  - ../../docs/test-checklist.md
---

# Cannon Shot Observation Evidence

## Outcome

The version-9 implementation passed its bounded final gate. Stage 01 and Stage
30 use canonical terrain seed `1347223552`, persisted layouts, a fixed cannon at
least 70 m from the nearest playable front, open exit bounds, and no rear or side
wall. The shared Aim View keeps a readable cannon below a useful lower/wider
mountain mass. The user's approximate `3:4` reference was applied as a visual
guide, not as an exact screen-space ratio or complete-silhouette requirement.

The cannon-side flag replaces generic debris. Accepted Fire follows the exact
new root paintball, shows its first terrain contact, and returns automatically or
through the visible action/Tab without changing projectile physics or stored aim.

## Functional Evidence

The following focused Godot scripts passed directly and in fresh processes:

- `prediction_scheduler_test.gd`
- `fixed_mountain_catalog_test.gd`
- `stage_generation_test.gd`
- `stage30_progression_test.gd`
- `generation_v9_materialization_test.gd`
- `baked_stage_layout_test.gd`
- `stage_layout_repository_test.gd`
- `play_bounds_test.gd`
- `open_play_environment_test.gd`
- `terrain_surface_paint_scope_test.gd`
- `phase7_user_qa_contract_test.gd`
- `stage_cannon_standoff_test.gd`
- `phase8_aiming_composition_test.gd`
- `trajectory_preview_efficiency_test.gd`
- `cannon_wind_flag_test.gd`
- `wind_result_hud_test.gd`
- `shot_follow_camera_test.gd`
- `phase7_ui_test.gd`
- `projectile_settling_test.gd`
- `replay_recorder_v9_test.gd`
- `replay_presentation_test.gd`

The exact-seed dry build passed for all 30 stages and reproduced manifest
`b0eb55b3e366a7a92b1391a6acd0298bbc854d8c831e8ac57f9b5df5ab44c957`.
`scripts/verify.ps1` passed project import, script parsing, and main-scene
startup. The Windows Desktop release export passed at
`builds/windows/PaintMountain.exe` with its PCK embedded.

No full-suite run, timing/FPS benchmark, profiler capture, exhaustive target
solver, or all-stage manual playthrough was used as acceptance evidence.

## Running-Release Visual Evidence

The exported executable produced these 1280x720 background captures, each with
exit code 0:

- `cannon-shot-observation/final/stage01_aim.png`
- `cannon-shot-observation/final/stage30_aim.png`
- `cannon-shot-observation/final/wind_flag_weak.png`
- `cannon-shot-observation/final/wind_flag_strong.png`
- `cannon-shot-observation/final/shot_follow_midflight.png`
- `cannon-shot-observation/final/shot_follow_impact_hold.png`
- `cannon-shot-observation/final/shot_follow_returned.png`

Visual review found:

- Stage 01 clearly shows the cannon below the broad mountain and the predicted
  path into the playable surface.
- Stage 30 keeps the cannon readable below a much larger mountain. Some
  peripheral terrain is cropped, which is acceptable under the approved
  qualitative composition rule.
- Weak left wind and strong right wind produce different flag lengths/response,
  and each flag direction agrees with the HUD.
- Mid-flight and impact-hold views keep the blue paintball readable, hide aim and
  Fire controls, and show the return action without implying steering.
- Returned Aim View restores the exact control layout and trajectory while the
  launched ball remains in the world.
- No backstop, side enclosure, generic wind debris, clipped required control, or
  competing Follow/Wide/Cannon camera rail is visible.

## Quality Audit

The task diff passed `git diff --check`. The final ownership scan found
`StageController` still owns Fire and stage outcomes, `CameraDirector` owns
presentation modes and one exact follow target, `WindController` remains the
single wind authority, and trajectory preview uses one `MultiMeshInstance3D`.
Direct-space prediction, map-pick, and camera-safety queries remain on fixed
physics callbacks. No production reference to `WindDebrisField`,
`BackstopEnvironment`, `BACKSTOP`, candidate seed search, or
`reliable_solution` remains. No blocking quality finding remained after the
task-scoped corrections.

User-owned play-feel and aesthetic approval remains separate from this technical
and rendered-evidence closeout.
