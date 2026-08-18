---
type: spec
status: active
created: 2026-08-04
last_reviewed: 2026-08-18
canonical_for: Agent-facing entry and map for approved Paint Mountain design direction, preserved experience contracts, and production design owners
scope: visual world and player-facing surfaces in this repository
source: ../../docs/source-brief.md
related:
  - ART_DIRECTION.md
  - UIUX_GUIDELINES.md
  - VISUAL_REFERENCES.md
  - ../../docs/design-spec.md
  - ../../docs/technical-architecture.md
  - ../Documentation.md
  - ../execplans/2026-08-03-gameplay-visual-reset.md
  - ../execplans/2026-08-07-cannon-shot-observation.md
  - ../execplans/2026-08-18-three-ball-target-band-prototype.md
---

# Paint Mountain Design Context

## Purpose

Give agents one concise map from approved product design to the files that own
the running Godot experience. This document is not a production asset, runtime
dependency, visual spec, token file, screenshot library, or substitute for the
linked design authorities.

## Scope

Every design task starts here. Continue according to scope:

| Task scope | Required next reading |
| --- | --- |
| World, terrain, camera, materials, lighting, cannon, paint, mechanisms, dressing, or effects | `ART_DIRECTION.md` and `VISUAL_REFERENCES.md` |
| HUD, menu, typography, icon, localization fit, or player-facing interaction layout | `UIUX_GUIDELINES.md` and `VISUAL_REFERENCES.md` |
| Work spanning world and interface | All three sibling documents in this folder |
| Work based on a screenshot, mockup, generated image, or external visual | All three sibling documents in this folder |

Purely non-visual domain, persistence, tooling, or test work does not need the
supplemental design documents unless it changes a player-facing state or
message.

## Authority

Use this order without silently blending conflicts:

1. The effective `docs/source-brief.md`, including recorded later user
   revisions, owns product requirements.
2. `ART_DIRECTION.md` and `UIUX_GUIDELINES.md` own their distinct visual and UI
   product scopes.
3. `docs/design-spec.md` is the broader working product interpretation.
4. `docs/technical-architecture.md` maps technical ownership, while
   `.agents/Documentation.md` records implemented reality and known gaps.
5. The relevant active ExecPlan under `.agents/execplans/` controls work order;
   it is neither design authority nor proof of implementation.
6. `VISUAL_REFERENCES.md` classifies comparative evidence; images are not
   literal geometry, behavior, layout, or acceptance proof.

When these sources disagree materially, surface the conflict and correct the
appropriate authority. Do not resolve it by inventing a compromise in code or
in this map.

A later explicit user direction overrides only the scope it names. Record any
approved durable change in the relevant sibling spec; an unaccepted experiment
remains non-canonical and must not silently alter this context.

## Reference Interpretation

- Use references to compare composition, hierarchy, mass, depth, faceting,
  palette, paint readability, and restraint.
- Do not copy literal terrain topology, mechanism placement, HUD coordinates,
  language, painted state, or apparent physics unless an active spec requires
  it.
- Generated concepts remain exploratory until the user explicitly approves a
  demonstrated rule and the relevant spec records it.
- A still image cannot prove 3D depth, collision, paint continuity,
  interaction, performance, responsive layout, or acceptance.
- Rejected captures are anti-references, never implementation to preserve.

## Product and Surface Intent

- Primary task: inspect a distant target, choose yaw, elevation, and power,
  predict the first impact, fire, follow the launched paintball through contact,
  and understand the physical and painted result before the next shot. A
  one-action return restores the cannon view without changing the projectile.
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
| Terrain and world | `src/terrain/`, `scenes/gameplay/gameplay.tscn`, `src/gameplay/gameplay_scene.gd`, current `scenes/gameplay/backstop_environment.tscn` retirement source | Terrain owners change playable mass; the gameplay scene owns the open environment, light, lens, and composition nodes. The active plan removes rear/side containment walls while keeping visible geometry, collision, queries, paint identity, and open escape rules aligned. |
| Camera | `src/camera/camera_director.gd`, `resources/stages/*.tres`, `scenes/gameplay/gameplay.tscn` | Stage Resources own bookmarks; `CameraDirector` owns mode, safety, occlusion, orbit, and follow policy; the scene owns active lens settings. |
| Paint presentation | `src/paint/paint_system.gd`, `src/paint/terrain_paint.gdshader`, `resources/paint/default_paint_surface_tuning.tres`, `resources/stages/*.tres` | `PaintSystem` remains the only mutable strength/owner and coverage authority; shader, tuning Resource, and stage channel palette are its configured visual view. |
| Cannon and trajectory | `scenes/gameplay/cannon.tscn`, `src/cannon/`, `resources/projectiles/` | Scene owns cannon form, Resources own tuning, and cannon/trajectory owners calculate aim and first impact; HUD only displays and requests. |
| Mechanisms and effects | `scenes/mechanisms/`, `src/mechanisms/`, `resources/mechanisms/*.tres`, `src/effects/presentation_effects.gd` | Prefabs own collider-matched form, typed Resources own kind/copy/tuning, and effects explain events without deciding game state. |

World palette and material values are currently distributed across gameplay,
the retiring backstop environment, cannon, mechanism, dressing, trajectory, and effect owners. No shared
world-material Resource is canonical yet. Use `ART_DIRECTION.md` for intended
roles and change only the responsible production owner; do not create a second
palette registry in this folder.

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
- Update the relevant sibling design spec after an approved durable direction
  change. Update this map only when authority, ownership, preserved
  flow, reachable states, or responsive behavior changes.
- Keep active work, alternatives, QA logs, captures, and implementation claims
  in the active ExecPlan or evidence location, not in `.agents/design/`.
- Follow the active ExecPlan and root instructions for visible-process
  authorization. Design context never authorizes a visible launch or approval
  claim by itself.

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

- `ART_DIRECTION.md`: world-art contract.
- `UIUX_GUIDELINES.md`: interface contract.
- `VISUAL_REFERENCES.md`: evidence classification.
- `../Documentation.md`: implemented-truth record.
- `../execplans/2026-08-03-gameplay-visual-reset.md`: historical visual-reset sequence.
- `../execplans/2026-08-07-cannon-shot-observation.md`: current execution sequence.
