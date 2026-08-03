---
type: handoff
status: active
created: 2026-08-03
last_reviewed: 2026-08-03
scope: paste-ready English instruction for Claude
related:
  - README.md
  - current-state.md
  - source-map.md
  - constraints-and-decisions.md
  - external-review-raw.md
---

# Claude Review Instruction

## Current State

The repository contains a partially implemented Godot game whose structure has
some useful boundaries, but whose central terrain, paint behavior, visual
composition, and interaction feedback do not match the user's intended game.
The handoff package records a newer user correction that invalidates the current
finite-payload paint model.

## Next Steps

Give Claude read-only access to `D:\npjt\paint-mountain`, then paste the complete
instruction below. Preserve Claude's raw answer before translating it into any
implementation plan.

## Risks

Claude may reproduce stale assumptions if it reads the old ExecPlan or checked
test checklist before the handoff. It may also overfit to a screenshot and
recommend a reskin. The instruction therefore fixes the authority order and
requires a joined gameplay, geometry, physics, and presentation response.

## Paste-Ready Instruction

```text
You are an external senior Godot gameplay engineer, technical game designer, and real-time 3D art-direction reviewer. Perform a read-only design and architecture review of the Paint Mountain repository at:

D:\npjt\paint-mountain

Do not modify any file. Do not launch the Godot editor or the game, do not open visible application windows, and do not run a long solver or broad test suite. You may use read-only repository inspection. Return your answer as a self-contained Markdown document.

Mission

Produce a decisive, implementation-ready correction guide for the game. This is not a request for code, a generic critique, a reskin, or another status report. Resolve the important design and technical choices before implementation begins. Short pseudocode or data-shape examples are welcome only when they remove ambiguity.

Authority order

1. The newest explicit user corrections in docs/handoffs/gameplay-visual-reset-2026-08-03/current-state.md are highest authority for the points they revise.
2. docs/source-brief.md governs requirements not subsequently revised by the user.
3. AGENTS.md governs repository architecture and operating constraints.
4. Current code is evidence of what exists, not proof that the product requirement is satisfied.
5. Existing specs, plans, test checklists, and completion records are fallible historical evidence.

Critical correction you must preserve

The ball must paint every eligible target-terrain surface area traversed by its contact footprint while it rolls or slides. Painting continues for the entire valid surface-contact path until the ball settles, leaves the target, or is removed. Paint does not run out. The trail must be continuous rather than a series of visibly separated stamps. Overlap counts once toward coverage. Splitter children follow the same rule. This explicitly supersedes every finite-payload, remaining-payload, shrinking-trail, and deposit-budget rule in the source brief, current docs, resources, code, replay fields, debug UI, and tests.

Required reading order

1. docs/handoffs/gameplay-visual-reset-2026-08-03/README.md
2. docs/handoffs/gameplay-visual-reset-2026-08-03/current-state.md
3. Compare visuals/01-target-reference.png and visuals/02-current-build.png inside that package.
4. docs/handoffs/gameplay-visual-reset-2026-08-03/source-map.md
5. docs/handoffs/gameplay-visual-reset-2026-08-03/constraints-and-decisions.md
6. Inspect the source brief, current derived docs, code, scenes, resources, and targeted tests referenced by the source map.

Product model

Paint Mountain is a focused desktop 3D physics puzzle. A small stationary foreground cannon launches a physics ball toward a large distant mountain-shaped 3D puzzle target. Before firing, the player manually chooses yaw, elevation, and power; there is no in-flight steering. A preview may show the ballistic path only through its predicted first collision. After impact, gravity, momentum, target geometry, and mechanisms determine the route. The target is a thick, bright, low-poly mountain-shaped puzzle board with readable slopes, terraces, ledges, valleys, rises, descents, branches, and mechanism opportunities. It is not a realistic mountain simulator, a flat backdrop, or a noise-first landscape.

Technical constraints

- Godot 4.x, typed GDScript where practical, Compatibility renderer, fixed 60 Hz physics, Windows desktop first.
- Keep StageController as the sole owner of stage state, shot progression, and clear/failure decisions.
- Keep PaintSystem as the sole owner of the authoritative mutable paint mask used by visuals and coverage.
- Keep tuning in typed Resources and keep game rules independent of HUD and human input.
- Preserve narrow typed interfaces and signals; do not turn gameplay_scene.gd or another file into a catch-all.
- Do not recommend a new engine, production dependency, plugin, network service, Docker setup, or asset pack.
- Do not solve defects by lowering coverage targets, inflating marks arbitrarily, revealing the full route, or rewriting the entire project without file-specific evidence.
- Default UI language is Korean; English is selectable in settings.

Required output

Use the following numbered sections and make each recommendation concrete.

1. Correct game model
Restate the game in 8–12 unambiguous bullets. Explicitly distinguish the newest user correction from stale repository assumptions. State what the player controls, what is simulated, what is painted, and what makes a stage difficult.

2. Evidence-backed diagnosis
Compare the target and current screenshots using observable composition, scale, silhouette, depth layering, route readability, mechanism visibility, paint appearance, trajectory feedback, typography, spacing, and hierarchy. Then connect those visible symptoms to likely current code/data decisions. Label inference as inference.

3. Procedural mountain design
Choose one recommended representation and pipeline. Define a route-graph-first generator: node/edge data, elevations, edge widths, terraces, shelves, branches, merge rules, uphill/downhill reversals, outer mountain mass, thickness, deterministic seeded variation, mesh/collider derivation, and rejection/validation metrics. Give specific Stage 1–3 complexity budgets and numeric starting ranges. Explain exactly how this avoids the current wall-like result and remains readable from the aiming camera. Prefer the current closed-shell/single-layout architecture if it can satisfy the result; justify any replacement.

4. Continuous surface-paint algorithm
Define the exact runtime contract for painting the full path of a rolling/sliding ball with no payload depletion. Cover previous/current valid contacts, ball footprint radius, swept segment or capsule rasterization, high speed, steep triangles/slopes, surface normals, collider identity, disconnected surfaces, brief contact loss, re-contact, impact splash, rest puddle, mechanisms, Splitter children, overlap, determinism, and coverage accounting. Explain how the 3D contact sweep maps to the existing 512x512 authoritative mask without gaps or painting through unrelated surfaces. Identify which current point-deposit concepts survive and which must be deleted.

5. Geometry, collision, and contact contract
Specify how visible terrain, shell thickness, top/skirt/bottom collision, mechanisms, and decorations derive or pair their render and collision geometry. Define CCD/contact requirements and concrete diagnostics for tunneling, fabricated contacts, mesh/body mismatch, ambiguous hits, and mechanism activation. Include visual/audio feedback that makes the exact impact and subsequent surface interaction understandable.

6. Camera, art direction, mechanisms, and HUD
Provide measurable initial ranges for mountain and cannon screen occupancy, camera perspective, depth layers, route width readability, mechanism projected size, trajectory-dot size/spacing, paint width and material response, UI margins, type scale, control sizes, and safe-area behavior at the supported desktop resolution. Match the target reference's hierarchy without requiring pixel-perfect copying. Define mouse yaw/elevation interaction, power adjustment, Fire/Restart states, Korean labels, and the English language switch.

7. Architecture migration map
Name the current files or modules to preserve, revise, split, or delete. Pay particular attention to seeded_stage_generator.gd, stage route/profile Resources, terrain_geometry_factory.gd, paint_projectile.gd, projectile_contact.gd, projectile_manager.gd, paint_deposit_request.gd, paint_system.gd, the shader, mechanisms, camera, HUD components, StageController, replay, agent observations, debug telemetry, and tests. Remove obsolete payload semantics coherently rather than leaving compatibility fields with misleading names.

8. Vertical implementation sequence
Give a small sequence of end-to-end slices. The first slice must prove one simple generated 3D route, real ball contact, continuous painted traversal, matching coverage, and reference-aligned camera composition before rebuilding all stages. For each slice state scope, owner files, objective exit criteria, screenshot evidence, and a stop/go gate. Do not defer visual proof until the end.

9. Verification strategy
Separate static checks, headless deterministic tests, focused physics tests, and running-build visual/manual evidence. Replace obsolete finite-payload tests. Include tests for no trail gaps at maximum expected speed, no painting during airborne gaps, steep-slope mapping, collision parity, mechanism response, fixed-seed repeatability, camera safety, Korean/English layout, and one meaningful successful route per stage. Do not treat a solver clear as proof of acceptable design.

10. Decisions, contradictions, and residual risks
List contradictions you found, choose a recommended default for each, and explain why. Identify any fact that truly cannot be decided from the repository, but still provide one low-risk default. End with a concise MUST / SHOULD / AVOID checklist that a future ExecPlan can copy as acceptance policy.

Quality bar

- Use precise MUST, SHOULD, and AVOID language.
- Cite repository paths for code and document claims.
- Give numeric starting ranges where they make advice testable, while identifying them as tuning baselines rather than eternal constants.
- Distinguish verified facts, screenshot observations, and inferences.
- Preserve useful existing ownership boundaries when possible.
- Do not repeat checked boxes as evidence.
- Do not provide generic advice such as “improve the UI” or “make collisions better.” State the mechanism, owner, and acceptance evidence.
- Make the response detailed enough that a separate engineer can create a decision-complete replacement ExecPlan without inventing product behavior during implementation.
```
