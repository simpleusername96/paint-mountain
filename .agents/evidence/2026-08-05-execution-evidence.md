---
type: evidence
status: active
created: 2026-08-05
last_reviewed: 2026-08-05
scope: execution proof for the physical, progression, and runtime-interface ExecPlans
related:
  - ../execplans/2026-08-05-physical-gameplay-mvp.md
  - ../execplans/2026-08-05-rapid-fire-thirty-stage-progression.md
  - ../execplans/2026-08-05-runtime-grounded-interface.md
  - ../Documentation.md
---

# ExecPlan execution evidence

This record is the handoff index for the user-authorized execution pass. Every
rendered image listed here came from the Godot 4.7.1 Compatibility renderer in
an off-screen, non-focusable window; no foreground Godot window was opened.

## Runtime captures

All paths are relative to `.agents/evidence/current/`.

| Artifact | What it proves |
| --- | --- |
| `aiming_execution.png` | Korean-first aiming composition: mountain-dominant world, left vertical coverage, lower-left aim/power, centered Fire, top-right shots/settings, full trajectory preview |
| `observation_execution3.png` | Airborne observation controls, visible ball/trajectory, aim and Fire retained while a family is active |
| `stage_select_execution.png` | Numeric 11–20 page with all cards enabled, real selected-stage detail, and preview without live terrain generation |
| `main_execution_final.png` | Main menu and generated mountain hero |
| `paint_execution_final.png` | Real projectile contact and visible blue paint on the closed faceted mountain |
| `settings_execution_final.png` | Paused settings surface, Korean default, language and Fast Progress controls |
| `briefing_execution_final.png` | Briefing world/terrain entry state |
| `pause_execution_final.png` | In-game pause overlay with the active world behind it |
| `stage_clear_execution_final.png` | Natural Stage 01 clear after the committed four-shot solution drains |
| `stage_failed_execution_final.png` | Natural failure after four legal contained non-target shots |
| `aiming_exported_final.png` | Same aiming contract from the exported Windows build |
| `responsiveness_final.json` | Passing rendered/off-screen responsiveness telemetry |

## Measured runtime contract

`responsiveness_final.json` reports `acceptance.passed: true` with no failures.
The run measured dirty Fire `0.004 ms`, ready Fire `0.986 ms`, nonempty paint
drain p95 `1.37 ms`, maximum drain `2.309 ms`, camera movement ratio `1.0`,
and 120 continuous surface sweeps. The dirty-region texture upload keeps the
authoritative 512² CPU mask while limiting GPU publication to changed regions.

## Focused validation

The following checks passed during this execution pass (all with the pinned
Godot 4.7.1 executable):

- physical contact/paint: `phase3_projectile_paint_test`, `phase4_state_test`,
  `projectile_contact_test`, `containment_wall_test`, `mountain_range_mvp_test`,
  `aim_interaction_test`, `shot_observation_test`;
- family/progression: `rapid_fire_contract_test`, `stage30_progression_test`,
  `phase6_content_test`;
- interface/camera/localization: `phase7_ui_test`, `phase8_hud_truth_test`,
  `phase8_aiming_composition_test`, `camera_safety_test`,
  `localization_ui_test`, `shot_feedback_test`;
- project import/parse/startup: `scripts/verify.ps1` passed after the final
  code/documentation edits; the Windows release export produced
  `builds/windows/PaintMountain.exe` (145,835,312 bytes), and the exported
  aiming capture also passed.

## Bounded deviations

- Late-stage mechanism loadout is 0/1/2 (intro, Burst, Splitter+Bumper) rather
  than the six-object future-capacity concept. This is an intentional readability
  and difficulty decision for the user's requested gradual MVP; it is called
  out in both active plans rather than hidden in the implementation.
- The canonical `ShotObservation` map seals all admitted families at the
  shared terminal drain boundary, while each family retains its own contacts,
  paint commands, and gain. There is no second paint mask or fabricated result
  state.

## Reproduction commands

```powershell
$godot = 'D:\npjt\cardborne-platformer\.codex-runtime\godot-4.7.1-stable\Godot_v4.7.1-stable_win64_console.exe'
& $godot --path . --rendering-method gl_compatibility -- --responsiveness-output=.agents/evidence/current/responsiveness_final.json --capture-background
& $godot --path . --rendering-method gl_compatibility -- --capture-screen=projectile_and_continuous_paint --capture-output=.agents/evidence/current/paint_execution_final.png --capture-background
```

The user may run the canonical fastrun command for foreground play review after
the release build is handed off; the agent must not open a desktop-blocking
window as part of this record.
