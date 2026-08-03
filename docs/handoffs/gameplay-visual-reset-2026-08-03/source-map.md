---
type: evidence
status: active
created: 2026-08-03
last_reviewed: 2026-08-03
scope: evidence index and trust guidance for external review
related:
  - README.md
  - current-state.md
  - constraints-and-decisions.md
---

# Source Map

## Purpose

Direct Claude to the smallest complete evidence set and prevent stale completion
claims from being mistaken for the corrected product contract.

## Sources

All paths are relative to `D:\npjt\paint-mountain` unless marked as package
paths.

## Findings

### Required reading sequence

| Order | Path | Use | Trust guidance |
| --- | --- | --- | --- |
| 1 | `docs/handoffs/gameplay-visual-reset-2026-08-03/current-state.md` | Newest user intent and observed gap | Highest for the explicit corrections it records |
| 2 | `docs/handoffs/gameplay-visual-reset-2026-08-03/visuals/01-target-reference.png` | Desired composition, hierarchy, paint readability, and low-poly art direction | Product target, not literal geometry to copy |
| 3 | `docs/handoffs/gameplay-visual-reset-2026-08-03/visuals/02-current-build.png` | Current visible failure | Direct visual evidence for this build only |
| 4 | `docs/source-brief.md` | Full original game directive | Highest original source except where the user explicitly revised paint behavior |
| 5 | `AGENTS.md` | Engine, ownership, verification, and workflow guardrails | Binding repository constraint |
| 6 | `docs/handoffs/gameplay-visual-reset-2026-08-03/constraints-and-decisions.md` | Fixed constraints and decisions Claude must make | Review contract |
| 7 | Current code paths below | Actual implementation | Ground truth for implementation, not proof of product quality |
| 8 | Derived docs and tests below | Prior intent and attempted implementation | Stale where they retain finite payload or unsupported completion claims |

### Visual evidence provenance

| Package file | SHA-256 | Meaning |
| --- | --- | --- |
| `visuals/01-target-reference.png` | `1E32C82DF16DBE0809458DC7A7D9385C7EB3A61D0240BD8551B40F02190E4538` | Original design reference supplied by the user |
| `visuals/02-current-build.png` | `AEDE8587A122B1977AE4C87FA551E8CE6383AC94B0A9D3EE39024E29F184E173` | Current running-build capture supplied by the user |

### Product and historical documents

| Path | Why inspect it | Known caveat |
| --- | --- | --- |
| `docs/source-brief.md` | Complete original loop, controls, camera, paint, stages, mechanisms, presentation, and acceptance criteria | Its finite-payload clauses were explicitly superseded by the user |
| `.agents/Prompt.md` | Compact prior product routing summary | Still inherits finite payload and therefore cannot stand alone |
| `docs/design-spec.md` | Current compact mechanics and presentation interpretation | Describes finite payload, shrinking stamps, and old stage balance |
| `docs/technical-architecture.md` | Current runtime owners and data flow | Deposit and observation contracts assume consumable amount |
| `.agents/Plan.md` | Prior remediation decisions and visual diagnosis | Completed historical plan; its success claims are not current acceptance evidence |
| `.agents/execplans/2026-08-03-core-interaction-redesign.md` | Detailed prior implementation contract | Active label does not make its obsolete paint assumptions correct |
| `.agents/Documentation.md` | Implemented-state record and known verification blocker | Useful inventory, not visual proof |
| `docs/test-checklist.md` | Existing acceptance and test record | Checks finite payload and includes unchecked solution gates |

### Terrain generation and geometry

| Path | Review question |
| --- | --- |
| `src/stage_generation/seeded_stage_generator.gd` | Why do route inputs still produce a wall-like, weakly layered target, and what pipeline should replace the mass/noise-first parts? |
| `src/stage_generation/stage_generation_profile.gd` | Which difficulty and topology parameters belong in typed stage data? |
| `src/stage_generation/stage_route_profile.gd` | Can this become a genuine route-graph contract rather than a height pattern hint? |
| `src/stage_generation/generated_stage_layout.gd` | Which authoritative geometric queries and metadata should remain? |
| `src/stage_generation/mechanism_placement_generator.gd` | How should placement follow meaningful route nodes and camera readability? |
| `resources/stage_generation/*.tres` | Which stage-specific numbers encode obsolete topology or balance? |
| `src/terrain/terrain_geometry_factory.gd` | Preserve or revise the single-source mesh/collider shell construction. |
| `src/terrain/terrain_surface.gd` | Preserve the narrow runtime surface-query and collision ownership where useful. |
| `src/terrain/environment_dressing.gd` | Define an explicit collision and readability policy for decorations. |

### Projectile, contact, and paint

| Path | Review question |
| --- | --- |
| `src/projectile/paint_projectile.gd` | Replace payload-limited timed/distance stamps with authoritative continuous contact-path reporting. |
| `src/projectile/projectile_contact.gd` | Verify what contact sample data is sufficient for a swept surface footprint. |
| `src/projectile/projectile_data.gd` | Remove consumable-payload tuning while preserving physical tuning. |
| `src/projectile/projectile_manager.gd` | Remove amount acceptance and keep lifecycle/signal ownership narrow. |
| `resources/projectiles/basic_paintball.tres` | Delete stale payload and deposit-rate values after the new contract is chosen. |
| `src/paint/paint_deposit_request.gd` | Decide whether to replace point deposits with a segment/sweep request or add a distinct path command. |
| `src/paint/paint_deposit_tuning.gd` | Separate footprint/visual tuning from obsolete amount economics. |
| `src/paint/paint_system.gd` | Preserve the one authoritative mask and coverage count while implementing gap-free surface writes. |
| `src/paint/terrain_paint.gdshader` | Make the same mask read as thick, glossy, surface-bound paint. |
| `tests/projectile_contact_test.gd` | Retain useful contact and tunneling tests; add surface-path invariants. |
| `tests/phase3_projectile_paint_test.gd` | Replace finite-payload assertions with continuous sweep and contact-loss cases. |

### Mechanisms, camera, input, and presentation

| Path | Review question |
| --- | --- |
| `scenes/mechanisms/*.tscn` and `src/mechanisms/*.gd` | Establish visible-mesh/collision parity, size, placement, silhouette, activation feedback, and split behavior. |
| `src/camera/camera_director.gd` | Match the reference's readable mountain composition without clipping or hiding the route. |
| `src/input/aim_input_controller.gd` | Preserve manual yaw/elevation/power and a first-collision-only preview. |
| `scenes/gameplay/cannon.tscn` | Correct foreground scale, silhouette, aim feedback, and screen occupancy. |
| `scenes/gameplay/gameplay.tscn` and `src/gameplay/gameplay_scene.gd` | Review scene composition and cross-system wiring; avoid turning this file into a new catch-all. |
| `scenes/ui/hud/*.tscn` and `src/ui/hud/*.gd` | Rebuild hierarchy and layout against the target while preserving component ownership. |
| `resources/ui/paint_mountain_theme.tres` | Establish coherent typography, scale, spacing, color, and control states. |
| `translations/ui.csv` | Preserve Korean as default and English as a setting. |

### State, replay, observation, and verification

| Path | Review question |
| --- | --- |
| `src/stage/stage_controller.gd` | Keep sole stage-state ownership while removing payload-dependent observations. |
| `src/replay/*` | Migrate or version replay data after payload fields disappear. |
| `src/agent/gameplay_agent_api.gd` | Expose the same aim/fire/restart rules without stale payload state. |
| `src/debug/debug_overlay.gd` | Replace payload telemetry with contact-path and paint-sweep diagnostics. |
| `tests/stage_generation_test.gd` | Add topology/readability assertions rather than validating only height statistics. |
| `tests/terrain_geometry_test.gd` | Preserve render/collision derivation checks. |
| `tests/phase5_mechanism_test.gd` | Add visible/body alignment and actual response evidence. |
| `tests/camera_safety_test.gd` | Preserve camera safety while adding composition checkpoints. |
| `scripts/verify.ps1` | Required static/headless verification after future code changes. |

## Recommendations

Claude should cite paths from this map when recommending ownership changes. If a
claim comes only from a plan, checklist, or screenshot, label that limitation.
Do not infer that an `[x]` checkbox establishes acceptable running-game quality.

## Limitations

This map intentionally excludes `.godot/`, exported builds, save data, local
Codex configuration, fastrun configuration, credentials, and unrelated logs.
No remote repository was configured when the package was created.
