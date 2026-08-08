---
type: evidence
status: active
created: 2026-08-08
scope: terrain-targeted aiming, same-target ballistic adjustment, and protected long-flight release QA
source: ../../execplans/2026-08-08-terrain-targeted-aiming.md
related:
  - ../../execplans/2026-08-08-terrain-targeted-aiming.md
  - ../../../docs/test-checklist.md
  - ../../Documentation.md
---

# Terrain-Targeted Aiming Release Evidence

## Purpose

Preserve the final running Windows-release images and the measured focused
results used to accept terrain click/drag targeting, same-target angle and power
adjustment, truthful target states, and predicted-contact lifetime protection.
This is consult-only evidence; the source brief and active specs remain the
product authorities.

## Sources

- Windows release: `builds/windows/PaintMountain.exe`, exported with Godot
  `4.7.1.stable.official.a13da4feb` and the Compatibility renderer.
- Focused contracts: `tests/aim_interaction_test.gd`,
  `tests/terrain_aim_solver_test.gd`, `tests/terrain_target_preview_test.gd`,
  `tests/prediction_projectile_parity_test.gd`,
  `tests/projectile_lifetime_test.gd`,
  `tests/predicted_contact_long_flight_test.gd`, and
  `tests/replay_fractional_contact_test.gd`.
- Final repository gate: `scripts/verify.ps1`.

## Findings

- Terrain-top click creates a selected target and continuous drag moves it to
  the latest valid surface point. Map Inspection retains orbit/zoom semantics.
- The low and high captures retain the same target ring with distinct
  `20.0° / 91.5%` and `57.5° / 54.1%` ballistic combinations.
- Pending disables Fire and hides a stale impact promise; rejected shows an X
  and restores the last committed target/aim.
- The deterministic protected fixture predicted contact at `8.384 s` and the
  live body reached the same terrain/top contact at `8.417 s`, rather than
  terminating at the ordinary 6-second miss deadline. Unmatched and bounds-exit
  controls retained their prior terminal reasons.
- Fractional-power replay reproduced first contact and the authoritative paint
  checksum without serializing target coordinates or solver state.
- All eight final capture processes exited 0 with empty stderr. Direct review
  found no clipped or overlapping controls, false Fire readiness, stale impact
  confusion, or missing protected projectile.

## Verification

Native-size running-release captures inspected individually:

- `terrain_target_selected-ko-1280x720.png`
- `terrain_target_dragged-ko-1280x720.png`
- `terrain_target_low_arc-ko-1280x720.png`
- `terrain_target_high_arc-en-1920x1080.png`
- `terrain_target_pending-ko-1280x720.png`
- `terrain_target_rejected-ko-1280x720.png`
- `protected_long_flight_impact-ko-1280x720.png`
- `map_inspection-en-1920x1080.png`

The code-quality audit also checked responsibility boundaries, stale gesture and
setting consumers, schema/API compatibility, and reachable invalid or stale
states. Its only local finding was Human wind-refresh work entering a replay
action lock; the guard and focused replay assertion now pass.
