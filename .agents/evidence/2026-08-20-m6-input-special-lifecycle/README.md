---
type: evidence
status: active
created: 2026-08-20
last_reviewed: 2026-08-20
topic: M6 first-input and special-ball lifecycle correction
related:
  - ../../execplans/2026-08-18-three-ball-target-band-prototype.md
  - ../../../docs/source-brief.md
  - ../../design/ART_DIRECTION.md
  - ../../design/UIUX_GUIDELINES.md
---

# M6 Input and Special-Ball Evidence

## Subject

Local Godot 4.7.1 Compatibility-renderer evidence for the first untouched
Space action, Impact Burst admission/presentation, atomic Apex Split
replacement, and the three-child Shot Follow presentation.

## Method

- Exercised the real baked Gameplay/HUD path with a synthetic untouched Space
  event and a separate pointer Fire activation.
- Exercised accepted and rejected Burst paint admission at ProjectileManager's
  canonical command boundary.
- Exercised Apex behavior, detached all-or-none replacement, event order,
  inherited identity, degenerate launch fallback, child camera hold, early
  return, and unrelated-projectile isolation.
- Ran the focused regressions plus adjacent aim, rapid-fire, paint, mechanism,
  queue, observation, and projectile-settling checks.
- Ran `scripts/verify.ps1` with `D:\tools\Godot\4.7.1-stable`.
- Captured the live game off-screen at 1280x720, Korean, Compatibility renderer,
  then personally inspected each PNG at original resolution.

## Results

- `first_fire_focus_test.gd` passes: settled Aiming focuses Fire; one untouched
  Space admits one root, decrements one token/shot, and enters Shot Follow; one
  pointer activation does not double-fire; secondary Button Space remains
  available to native GUI behavior.
- `impact_burst_ball_test.gd` passes: ordinary impact precedes Burst admission;
  accepted work publishes one effect and consumes once; rejected Burst work
  publishes no success cue and preserves the root as Standard fallback.
- `apex_split_ball_test.gd` passes: exactly three generation-one Standard
  children are admitted before one family/effect publication; invalid detached
  input leaves the root and publishes neither; near-zero apex horizontal speed
  uses the stored legal launch vector.
- `shot_follow_camera_test.gd` passes: root follow changes to only the published
  three-child family; a relevant child starts the 24-tick hold; stale/unrelated
  projectiles do not; camera-only return leaves simulation intact.
- `aim_interaction_test.gd`, `rapid_fire_contract_test.gd`,
  `ball_queue_progression_test.gd`, `shot_observation_test.gd`,
  `phase3_projectile_paint_test.gd`, `phase5_mechanism_test.gd`,
  `paint_queue_determinism_test.gd`, and `projectile_settling_test.gd` pass.
- `scripts/verify.ps1` passes after the script and capture-runner changes.

Rendered evidence:

- `impact-burst-effect-1280x720-ko.png`: accepted Burst shows a dense ground
  paint pulse/radial result while Shot Follow remains active.
- `apex-split-effect-1280x720-ko.png`: the trigger shows the non-painting
  three-glint cue and retains Shot Follow rather than snapping to Aim View.
- `apex-split-family-1280x720-ko.png`: all three child bodies are separately
  readable in the manager-bounded wide family composition.

The inspected captures contain no error overlay, clipping, debug HUD, or stale
Aim controls during Follow. Burst and Split no longer reuse the mechanism cue.

## Limitations

- These captures prove the Windows Compatibility path, not Web frame budgets or
  itch iframe input. M8 and M9 own those checks.
- The Apex render witness uses a legal high sideways aim so Stage 03 terrain
  cannot intercept the root before apex. It proves intrinsic lifecycle and
  family presentation, not that every player-selected Apex trajectory splits.
- The headless secondary-button assertion verifies the input adapter leaves the
  event unconsumed. Godot headless GUI dispatch does not synthesize a native
  Button click from `Input.parse_input_event`; full keyboard focus traversal is
  retained for local Web/itch smoke.
