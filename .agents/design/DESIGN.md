---
type: spec
status: active
created: 2026-08-04
last_reviewed: 2026-08-04
canonical_for: Agent-facing map of approved Paint Mountain design direction, preserved experience contracts, and production design owners
scope: visual world and player-facing surfaces in this repository
source: ../../docs/visual-direction/README.md
related:
  - ../../docs/source-brief.md
  - ../../docs/design-spec.md
  - ../../docs/technical-architecture.md
  - ../Documentation.md
  - ../execplans/2026-08-03-gameplay-visual-reset.md
---

# Paint Mountain Design Context

## Purpose

Give agents one concise map from approved product design to the files that own
the running Godot experience. This document is not a production asset, runtime
dependency, visual spec, token file, screenshot library, or substitute for the
linked design authorities.

## Scope

Read this before work that can change terrain appearance, camera composition,
materials, paint, mechanisms, effects, HUD, menus, typography, icons,
localization fit, or another player-facing state.

Every visual task first reads `docs/visual-direction/README.md`; its task table
then routes world work to `ART_DIRECTION.md`, interface work to
`UIUX_GUIDELINES.md`, and reference-led work to `VISUAL_REFERENCES.md`. Work
spanning world and interface reads all documents that README marks required.

## Authority

Use this order without silently blending conflicts:

1. The effective `docs/source-brief.md`, including recorded later user
   revisions, owns product requirements.
2. `docs/visual-direction/ART_DIRECTION.md` and
   `docs/visual-direction/UIUX_GUIDELINES.md` own their distinct visual and UI
   product scopes.
3. `docs/design-spec.md` is the broader working product interpretation.
4. `docs/technical-architecture.md` maps technical ownership, while
   `.agents/Documentation.md` records implemented reality and known gaps.
5. The relevant active ExecPlan under `.agents/execplans/` controls work order;
   it is neither design authority nor proof of implementation.
6. `docs/visual-direction/VISUAL_REFERENCES.md` classifies comparative evidence;
   images are not literal geometry, behavior, layout, or acceptance proof.

When these sources disagree materially, surface the conflict and correct the
appropriate authority. Do not resolve it by inventing a compromise in code or
in this map.

## Product and Surface Intent

- Primary task: inspect a distant target, choose yaw, elevation, and power,
  predict the first impact, fire once, and understand the physical and painted
  result before the next shot.
- Surface character: a bright, faceted, tactile 3D puzzle mountain with a
  visually secondary Korean-first interface.
- Preserve: no post-fire steering; one authoritative paint/coverage state;
  readable route, contact, mechanism, and result feedback; immediate restart;
  Korean default with persistent English switching.
- Hierarchy: the mountain and live cause-and-effect chain dominate; status hugs
  the edges; Fire is the sole aiming primary action; menus interrupt play only
  when intentionally opened.

## Runtime Source Map

| Concern | Canonical production owner | Agent use |
| --- | --- | --- |
| Application flow | `scenes/app/app.tscn`, `src/app/app_root.gd` | Keep menu, stage-select, settings, gameplay creation, and cross-screen navigation here; keep gameplay rules outside. |
| HUD composition | `scenes/ui/hud/*.tscn`, `src/ui/hud/*.gd`, `src/ui/hud_controller.gd` | Scenes own visible hierarchy; components display supplied state and emit typed intent; the controller is the façade, not a rule owner. |
| App screens | `scenes/ui/screens/*.tscn`, `src/ui/screens/*.gd` | Each screen owns its visible tree, focus, and local signals; `AppRoot` wires navigation. |
| UI tokens and styles | `resources/ui/paint_mountain_theme.tres`, `project.godot` | The shared Theme owns Pretendard, common palette, focus, panels, buttons, and progress styling; scene overrides are local hierarchy exceptions, not new global tokens. |
| Font and icons | `assets/fonts/pretendard/`, `assets/ui/icons/`, `docs/asset-licenses.md` | Reuse approved local assets through the Theme or component scenes; do not copy them into `.agents/design/`. |
| Copy and locale | `translations/ui.csv`, `src/autoload/game_state.gd`, `src/autoload/save_system.gd`, `project.godot` | The CSV owns localized keys and copy; `GameState` owns the current setting and application; `SaveSystem` owns defaults, migration, and persistence. Component-scene defaults are placeholders, not a second authority. |
| Gameplay composition | `scenes/gameplay/gameplay.tscn`, `src/gameplay/gameplay_scene.gd` | Integrate existing owners only; delegate stage state, paint, camera, mechanisms, and HUD behavior. |
| Stage shape and data | `src/stage_generation/`, `resources/stage_generation/*.tres`, `resources/stages/*.tres` | Generators own construction policy; typed Resources own route/profile constraints plus per-stage paint, camera, and loadout data. |
| Terrain and world | `src/terrain/`, `scenes/gameplay/gameplay.tscn`, `src/gameplay/gameplay_scene.gd`, `scenes/gameplay/backstop_environment.tscn` | Terrain owners change playable mass; the gameplay scene owns environment, light, lens, and composition nodes; keep visible geometry, collision, queries, and paint identity aligned. |
| Camera | `src/camera/camera_director.gd`, `resources/stages/*.tres`, `scenes/gameplay/gameplay.tscn` | Stage Resources own bookmarks; `CameraDirector` owns mode, safety, occlusion, orbit, and follow policy; the scene owns active lens settings. |
| Paint presentation | `src/paint/paint_system.gd`, `src/paint/terrain_paint.gdshader`, `resources/paint/default_paint_surface_tuning.tres`, `resources/stages/*.tres` | `PaintSystem` remains the only mutable mask and coverage owner; shader, tuning Resource, and stage color are its configured visual view. |
| Cannon and trajectory | `scenes/gameplay/cannon.tscn`, `src/cannon/`, `resources/projectiles/` | Scene owns cannon form, Resources own tuning, and cannon/trajectory owners calculate aim and first impact; HUD only displays and requests. |
| Mechanisms and effects | `scenes/mechanisms/`, `src/mechanisms/`, `resources/mechanisms/*.tres`, `src/effects/presentation_effects.gd` | Prefabs own collider-matched form, typed Resources own kind/copy/tuning, and effects explain events without deciding game state. |

World palette and material values are currently distributed across gameplay,
backstop, cannon, mechanism, dressing, trajectory, and effect owners. No shared
world-material Resource is canonical yet. Use
`docs/visual-direction/ART_DIRECTION.md` for intended roles and change only the
responsible production owner; do not create a second palette registry in this
folder.

`AppRoot` also builds a noninteractive menu preview world. Treat it as a menu
preview owner, not a gameplay-world owner, and review intentional parity when a
gameplay visual change affects what the preview communicates.

## Experience Contracts

- Reachable player surfaces are Main Menu, Stage Select, Briefing, Aiming,
  Projectile/Paint Observation, Clear, Failure, Pause, and Settings.
- `AppRoot` owns application navigation; `StageController` owns shot and result
  state; `HUDController` reflects those states and emits intents.
- The logical baseline is 1280x720 with a Windows desktop 16:9 target. Preserve
  anchors, containers, safe margins, Korean text fit, and focus states rather
  than relying on a single captured viewport.
- Gear and Escape open the same paused input barrier. Restart belongs there,
  not in Aiming or Settings; Fire remains the sole aiming primary action.
- The implementation record may report a surface as incomplete even when its
  scene exists. Never infer visual conformance from file presence, a plan
  checkbox, a mockup, or a historical screenshot.

## Requirements

- Start visual and substantial UI work with `$uiux-gate`, this map, and the
  task-relevant product specs.
- Inspect the listed production owners before editing and keep each change in
  its existing responsibility boundary.
- Reuse Theme, component, font, icon, material, and asset owners where they
  already exist; do not create agent-context copies.
- Update the relevant `docs/visual-direction/*` spec after an approved durable
  direction change. Update this map only when authority, ownership, preserved
  flow, reachable states, or responsive behavior changes.
- Keep active work, alternatives, QA logs, captures, and implementation claims
  in the active ExecPlan or evidence location, not in `.agents/design/`.

## Repeated Failures to Prevent

- Treating current scenes, mockups, plans, or captures as intended direction or
  completion proof, thereby preserving rejected world or HUD behavior.
- Using camera, color, UI, or effects to disguise missing geometry, collision,
  state, or feedback instead of correcting the responsible production owner.
- Copying a generated or user reference literally instead of naming the
  approved quality it demonstrates.
- Creating parallel palette, paint, coverage, state, layout, or copy
  authorities in scripts, scenes, documentation, or agent context.

## Acceptance Criteria

This context is healthy when a new agent can identify, without session history:

- the highest intended-design authority and the relevant visual spec;
- the actual Godot owner to inspect or change for each visual concern;
- the experience contracts that must survive the change;
- whether a source is production truth, intended direction, execution order, or
  comparative evidence; and
- where to record a durable decision without duplicating runtime resources or
  task progress.

## Non-Goals

- A copy of the art/UI specs, theme tokens, component inventory, image archive,
  page-by-page design, visual QA report, or active implementation plan.
- A new runtime material, font, icon, component, or asset location.
- Proof that the current game matches the approved direction.

## Maintenance

- Update only after an approved durable change to direction, authority,
  production ownership, preserved flow, reachable states, or responsive
  behavior.
- If a production owner moves, update this source map in the same coherent
  governance change.
- Do not add `visual-guide.md`, `references/`, `tokens.json`, `components.json`,
  or screenshots unless a later `$uiux-gate` decision proves a distinct reusable
  need that links back to production owners.

## Related

- `../../docs/visual-direction/README.md`: product-design documentation router.
- `../../docs/visual-direction/ART_DIRECTION.md`: world-art contract.
- `../../docs/visual-direction/UIUX_GUIDELINES.md`: interface contract.
- `../../docs/visual-direction/VISUAL_REFERENCES.md`: evidence classification.
- `../Documentation.md`: implemented-truth record.
- `../execplans/2026-08-03-gameplay-visual-reset.md`: current execution sequence.
