---
type: evidence
status: archived
created: 2026-08-08
scope: exploratory ImageGen directions for three Paint Mountain screens
related:
  - index.html
  - ../../../.agents/evidence/casual-shared-ui-refresh-2026-08-08/README.md
---

# Casual UI Direction Prompts

These nine images are exploratory design evidence, not running-game captures or
approved implementation authority. Each image was generated independently with
the built-in ImageGen workflow and grounded in the matching runtime screen plus
the primary Paint Mountain visual reference.

## Shared prompt constraints

- 16:9 desktop game UI composition for Paint Mountain.
- Keep the low-poly mountain or relevant menu world visible and dominant.
- Use only actions and values that exist on the matching runtime screen.
- Keep UI at the edges, with deliberate padding and no overlapping controls.
- Preserve a reusable shared component language across the three screens.
- Avoid mobile UI, fake telemetry, invented modes, placeholder boxes, and
  unreadable microcopy.

## Style recipes and output mapping

### A. Paper Toy Adventure

Prompt recipe: warm off-white paper-cut toy world, soft tactile depth, rounded
chunky shared panels, restrained cobalt controls, gentle shadow, sparse casual
game hierarchy, friendly but not childish.

1. `01-paper-toy-main-menu.png` — Main Menu
2. `02-paper-toy-stage-select.png` — Stage Select
3. `03-paper-toy-aim-view.png` — Aim View

### B. Sticker Arcade

Prompt recipe: bold flat sticker graphics, navy outline, cobalt/coral/lime
accents, energetic arcade clarity, large state shapes, no decorative clutter,
with the gameplay world kept readable behind edge controls.

4. `04-sticker-arcade-main-menu.png` — Main Menu
5. `05-sticker-arcade-stage-select.png` — Stage Select; corrected to the real
   Stage 1 values: target 4%, four shots, no mechanisms, best 0, zero stars.
6. `06-sticker-arcade-aim-view.png` — Aim View

### C. Quiet Field Guide

Prompt recipe: warm cream field-guide layout, slate/sage/cobalt palette, thin
rules, topographic contour and grid accents, almost-flat surfaces, restrained
instrument density, calm editorial spacing.

7. `07-field-guide-main-menu.png` — Main Menu; regenerated without fictional
   coordinates or telemetry.
8. `08-field-guide-stage-select.png` — Stage Select
9. `09-field-guide-aim-view.png` — Aim View; corrected to direction -0.5 degrees,
   elevation 28.4 degrees, and power 100.0%.

## Recommendation

Use Style A's tactile menu surfaces and Style C's restraint and information
density for the gameplay HUD. Reserve Style B's thick outline and strong color
for selected states, rewards, or an optional event skin because it competes
with the mountain when applied to every gameplay control.
