---
type: policy
status: active
created: 2026-08-04
last_reviewed: 2026-08-04
canonical_for: Paint Mountain world-art, UIUX, and visual-reference product documentation
scope: world art, camera, paint, mechanisms, effects, HUD, menus, typography, and player-facing layout
related:
  - ART_DIRECTION.md
  - UIUX_GUIDELINES.md
  - VISUAL_REFERENCES.md
  - ../../.agents/design/DESIGN.md
  - ../source-brief.md
  - ../design-spec.md
---

# Paint Mountain Visual Direction

## Purpose

This folder is the durable product-design documentation entry point for Paint
Mountain. It separates accepted art and UI requirements from concept images,
rejected captures, implementation state, and temporary execution plans.

Agents begin with `.agents/design/DESIGN.md`, which maps task scope to this
folder and to the actual Godot production owners without copying either.

## Scope

Use these documents for any change that can alter what the player sees or how a
player-facing screen behaves. This includes procedural mountain shape, mesh
thickness, materials, lighting, camera composition, cannon presentation, paint,
mechanisms, dressing, effects, HUD, menus, typography, icons, and layout.

Purely non-visual domain, persistence, tooling, or test work does not need this
folder unless it changes a player-facing state or message.

## Rules

### Required reading by task

| Task scope | Read before deciding or editing |
| --- | --- |
| World, terrain, camera, materials, lighting, cannon, paint, mechanisms, dressing, or effects | This file, `ART_DIRECTION.md`, and `VISUAL_REFERENCES.md` |
| HUD, menu, typography, icon, localization fit, or player-facing interaction layout | This file, `UIUX_GUIDELINES.md`, and `VISUAL_REFERENCES.md` |
| Work spanning world and interface | All documents in this folder |
| Work based on a screenshot, mockup, generated image, or external visual | All documents in this folder, including the source classification in `VISUAL_REFERENCES.md` |

### Authority order

1. The effective `docs/source-brief.md`, including explicit later user
   revisions, remains the highest product authority.
2. `ART_DIRECTION.md` is the canonical world-art and presentation spec.
3. `UIUX_GUIDELINES.md` is the canonical player-facing UI/UX spec.
4. The active ExecPlan controls implementation order but is not visual proof.
5. `VISUAL_REFERENCES.md` and its linked images are comparative evidence.
6. Current scenes, resources, screenshots, and builds describe implementation;
   they do not override intended direction.

When a newly accepted user decision changes a durable visual rule, update the
relevant spec in this folder in the same coherent change. Do not leave the new
decision only in chat, a plan, a screenshot, or code.

### Reference interpretation

- Use references to compare composition, hierarchy, mass, depth, faceting,
  palette, paint readability, and restraint.
- Never copy a reference's literal terrain topology, mechanism placement, HUD
  coordinates, language, painted state, or apparent physics unless a current
  spec explicitly requires it.
- A generated concept cannot become canonical without explicit user approval.
- A still image cannot prove real 3D depth, collision, paint continuity,
  interaction, performance, or acceptance.
- Rejected captures are anti-references. Do not normalize their implementation
  merely because it already exists.

### Implementation discipline

- Reuse shared materials, themes, components, and approved local assets before
  introducing one-off styling.
- Do not add or download an asset, font, plugin, or dependency without the
  approval required by root `AGENTS.md`.
- Visual polish must clarify the live puzzle state and may not disguise missing
  geometry, collision, feedback, or interaction.
- Follow the active ExecPlan's current rule for whether visible Godot validation
  is authorized. Reading this folder never grants permission to launch a visible
  process or claim visual approval.

## Exceptions

An explicit later user instruction may override a rule for a named surface or
task. Record that change in the relevant spec before relying on it beyond the
current task. Temporary experiments remain non-canonical until accepted.

## Related

- `../../.agents/design/DESIGN.md`: canonical agent-facing design context and
  runtime-owner map.
- `../source-brief.md`: baseline product directive and effective user revisions.
- `../design-spec.md`: broader working product interpretation.
- `../../.agents/execplans/2026-08-03-gameplay-visual-reset.md`: current
  implementation sequence.
- `../asset-licenses.md`: approved asset provenance and license record.
