---
type: plan
status: done
created: 2026-08-09
scope: gameplay HUD legibility, contextual input prompts, and wind-stable target-preserving aim edits
source: ../../docs/source-brief.md
related:
  - ../design/DESIGN.md
  - ../design/UIUX_GUIDELINES.md
  - 2026-08-08-instant-approximate-landing-feedback.md
---

# HUD Legibility and Wind-Stable Aim - Execution Contract

## Purpose

Refine the sparse Aim View HUD from the inspected Windows build without
restoring panels or prose, and make an explicit elevation or power edit remain
the player's visible intent while the selected terrain target is compensated
for changing wind.

## Verified Evidence

- The 1280x720 Windows capture shows ambiguous `7` and `0` status values,
  bracketed developer-looking key legends, a false `A/D` affordance, and
  aim values separated from their step buttons.
- AGY independently identified the same ambiguity and fragmented aim-control
  grouping. Its verbatim response is stored by the delegate job
  `20260809T003808289Z-24dc961f-5081-415e-9061-bca78fb7dcef`.
- Overwatch 2 examples attach compact key names to the ability they operate;
  Hades uses a small input glyph plus concise contextual action; Epic's UMG
  equipped-item model separates ammo icon, ammo count, and surplus.
- `RunStatusCard` discards the stage maximum after reset and publishes only the
  remaining-shot integer.
- `ShortcutHint` writes literal square brackets into every keycap. Aim View
  advertises `A/D` even though `AimInputController` and the current design
  contract intentionally do not accept A/D in terrain-target mode.
- Stage 30 release capture proves a valid `+0.5 degree` target-preserving edit
  changes elevation from `28.4` to `28.9` and compensates power from `100.0` to
  `93.4`. The opposite direction can be infeasible at the 100% power boundary.
- While the clock runs, `WindController` publishes every physics tick and
  `TerrainAimController` periodically re-solves with an unconstrained target
  request. That request can replace the elevation or power the player just
  pinned, making the control appear ineffective.

## Locked Decisions

- Show shots as `remaining / maximum`; keep resident-ball activity as a
  separate, lower-emphasis metric.
- Remove literal brackets from input legends. Use compact Theme-owned key
  tokens and a local mouse-wheel glyph attached to the controlled action.
- Remove the false A/D shortcut. Yaw remains a passive derived readout because
  terrain selection owns horizontal direction.
- Put minus, value, and plus on one line for elevation and power. Attach `S`
  and `W` to their real decrement/increment buttons and the wheel glyph to
  power. Keep every real button at least 40 px.
- Preserve target-selected aiming. An explicit elevation edit pins elevation;
  an explicit power edit pins power. Wind refresh first preserves that last
  explicit constraint and falls back to any legal same-target solution only
  when the pinned value becomes temporarily infeasible.
- A failed player adjustment retains the last valid aim and uses the existing
  rejected-target shape state. Direct numeric bounds also disable the matching
  visible step button.
- Reuse the existing Theme, Pretendard, icons, HUD component owners, and
  Compatibility renderer. Add no dependency or external asset pack.

## Scope

In scope:

- sparse Aim View status, coverage goal placement, shortcut component styling,
  Fire shortcut integration, and lower-right aim instrument layout;
- `TerrainAimController` preference ownership across wind epochs;
- Stage 30 and shared HUD regression coverage;
- current source brief, design/architecture records, implementation record,
  evidence, and canonical Windows build.

Out of scope:

- projectile physics, wind schedule tuning, target selection semantics,
  in-flight steering, new gameplay actions, menus, Settings layout, terrain,
  paint, mechanisms, or imported UI packs.

## Architecture Ownership

- `StageController` continues to own Fire admission and stage state.
- `TerrainAimController` owns selected-target compensation and the player's
  last explicit target-preserving constraint.
- `AimInputController` owns device routing and exposes no A/D target-mode path.
- HUD components display supplied authoritative state and emit narrow intents;
  they do not calculate shots, wind, or ballistic validity.
- The shared Theme owns reusable key-token and control state styling.

## Tasks

- [x] Preserve the last successful elevation or power constraint across wind
  refresh and add Stage 30 coverage for clicks, both controls, bounds, and wind.
- [x] Publish shot maximum to `RunStatusCard` and render `remaining / maximum`.
- [x] Restyle `ShortcutHint`, add a local wheel glyph, remove A/D, and attach
  input tokens directly to real actions.
- [x] Recompose elevation and power as inline steppers, improve the coverage
  goal marker, and keep Fire centered and unobstructed.
- [x] Update affected specs/records/tests, run focused checks and verification,
  export the canonical Windows build, and inspect Korean 1280x720 plus English
  1920x1080 Aim View captures and a selected-target/wind-relevant state.

## Acceptance Criteria

- Shots read as an unambiguous `n / N` at a glance; resident activity remains
  distinct and truthfully updates.
- No visible key legend contains square brackets or names an unavailable A/D
  target-mode action.
- Angle and power buttons, values, and their input hints read as two coherent
  instrument groups without overlap or clipping.
- A successful manual elevation or power edit remains pinned after a subsequent
  wind epoch refresh when a legal same-target solution exists.
- A bound or infeasible direction does not mutate the last valid aim and does
  not present an enabled direct-bound button.
- The mountain, target marker, high trajectory, cannon, coverage, Fire, Finish,
  gear, and interaction toggle remain legible at both supported capture sizes.

## Regression Guards

- Do not restore normal-play panels, context prose, direct R restart, A/D target
  steering, duplicate Fire, or UI-owned gameplay formulas.
- Preserve keyboard focus, accessible tooltips, 40 px targets, Korean/English
  fit, Map View input separation, and Shot Follow prompt behavior.
- Preserve exact-prediction advisory ownership and immediate Fire readiness.

## Verification

- Focused: `aim_interaction_test.gd`, `shortcut_prompt_test.gd`,
  `wind_result_hud_test.gd`, `localization_ui_test.gd`,
  `shot_feedback_test.gd`, and `phase7_ui_test.gd`.
- Project: `scripts/verify.ps1` and `git diff --check`.
- Production: export `Windows Desktop` to
  `builds/windows/PaintMountain.exe`, run task-owned off-screen capture states,
  and inspect every final PNG directly.

## Risks

- Preserving one manually pinned dimension can become infeasible under a later
  wind state. The safe fallback is a legal same-target solution; never publish
  an illegal aim or block Fire on exact prediction.
- More shortcut decoration can recreate clutter. Keep tokens small, contextual,
  and absent for non-actions such as derived yaw.

## Contingencies And Stop Conditions

- If the Stage 30 fixture shows that a pinned constraint cannot survive even a
  nearby wind epoch, retain the last valid aim and surface the limitation rather
  than changing physics or target semantics.
- Stop before adding a package, importing an asset pack, changing projectile
  tuning, or regenerating stages; none is required by this task.

## Progress

- Read-only discovery, current-build capture inspection, AGY review, external
  reference search, and Stage 30 low-arc/rejection reproduction are complete.
- Wind-stable explicit elevation/power preference, HUD recomposition, focused
  regression checks, `scripts/verify.ps1`, Windows export, and direct review of
  both final running-release captures are complete.
- The diff-scoped quality audit found no competing gameplay or presentation
  owner and no task-owned reachable failure path after the final regression run.

## Next Steps

No implementation step remains. User-owned foreground play may continue to
judge feel and aesthetic preference from the canonical Windows build.
