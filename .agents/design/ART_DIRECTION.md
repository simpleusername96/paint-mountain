---
type: spec
status: active
created: 2026-08-04
last_reviewed: 2026-08-07
canonical_for: Paint Mountain world art style, visual composition, and gameplay-object legibility
scope: procedural mountain, open environment, camera, lighting, materials, cannon, paint, mechanisms, dressing, and effects
source: ../../docs/source-brief.md
related:
  - DESIGN.md
  - UIUX_GUIDELINES.md
  - VISUAL_REFERENCES.md
  - ../../docs/handoffs/gameplay-visual-reset-2026-08-03/visuals/01-target-reference.png
  - ../execplans/2026-08-03-gameplay-visual-reset.md
  - ../execplans/2026-08-06-wind-driven-coverage-loop.md
  - ../execplans/2026-08-07-target-coverage-and-safe-aim-framing.md
  - ../execplans/2026-08-07-cannon-shot-observation.md
---

# Paint Mountain Art Direction

## Purpose

Define the durable visual language for the playable 3D world. The intended
result is a bright, tactile, low-poly physics-puzzle diorama whose routes,
contacts, paint, and mechanisms are readable before decorative realism.

## Scope

This spec governs the mountain and open environment, visible support geometry, camera
composition, lighting, materials, paint appearance, cannon, mechanisms,
dressing, and gameplay effects. UI composition and interaction presentation are
owned by `UIUX_GUIDELINES.md`.

## Product Feel

- Designed puzzle mountain, not a natural-landscape simulation.
- Bright, calm, sculpted, and tactile rather than dark, gritty, or photoreal.
- Substantial 3D mass rather than a card, backdrop, height strip, or gray test
  mound.
- Restrained enough that trajectory, contact, route choice, paint, and
  mechanisms remain the visual story.

## Requirements

### Mountain form and route language

- The target is one connected, visibly thick, independently closed 3D mountain
  mass in an open environment. It does not protrude from or join a rear wall.
- Its visible boundary and silhouette are irregular and expose the Playable
  Terrain Surface plus real front, rear, and lateral Support Shell faces. The mesh and matching
  collision must not rely on a billboard, visual-only duplicate, hidden plane,
  or full rectangular slab. The effective source brief and technical
  architecture decide the underlying surface representation.
- Build the mountain around designed routes: broad slopes, terraces, shelves,
  stair-like transitions, valleys, basins, ridges, and meaningful branches.
- Favor a lower, laterally spread mountain-range silhouette over a narrow central
  tower. Several readable rises and secondary summits should carry the eye
  across the target; later stages gain route and mechanism complexity without
  continuously inflating the highest peak.
- In the authored Aim View, use roughly `3:4` height-to-width as the initial
  silhouette target. Treat it as a composition range to review with the actual
  projected playable mass, not as a ratio for the rectangular height grid and
  not as permission to flatten terraces, valleys, or support faces.
- Stage 1 has the broadest, clearest path. Later stages add readable rises,
  drops, route reversals, narrower shelves, and mechanism opportunities without
  becoming visual noise.
- Facets should be large enough to read at the aiming camera. Avoid both a
  smooth blob and dense noisy triangulation.

### Composition and depth

- The Aim View reads as a deliberate foreground-to-distance composition: the
  cannon is a large readable anchor in the lower frame and the complete mountain
  is a smaller distant subject in the middle and upper frame.
- Preserve at least 70 m of physical standoff from cannon to the nearest playable
  mountain front. Aim View starts from one authored 48-degree pose that contains
  the full playable silhouette, summit headroom, cannon, muzzle, trajectory, and
  first-impact marker. Never frame the support shell, widen FOV to hide scale,
  or add per-stage camera repairs.
- Show several front-to-back route layers and enough top, front, and side area
  to communicate volume.
- Perspective, occlusion, face-value changes, cast shadows, and camera parallax
  must reinforce real depth. Camera framing may reveal geometry but never fake
  geometry that is absent.
- Keep the background open. No visible, collidable, or hidden rear/side
  containment wall may frame the mountain as a boxed board. Misses leave the
  composition rather than banking from an enclosure.
- Keep the cannon silhouette and barrel at roughly 20–30% of viewport height in
  Aim View while preserving a clear relationship between muzzle, trajectory,
  impact point, and the full distant target.
- The apron is subordinate. It must not become a flat band occupying the lower
  half or visually disconnect the cannon from the mountain.
- Dressing establishes scale and depth but never hides a route, target face,
  impact marker, paint trail, or mechanism.

### Material and color hierarchy

- Open background and ground: warm, bright, low-contrast values that separate
  the mountain silhouette without reading as a wall or horizon-sized panel.
- Dry mountain: slightly darker warm off-white with flat-shaded facets.
- Dry Target Area: a perceptible but neutral surface distinction on playable
  top, subordinate to blue paint, the trajectory, and mechanisms; it explains
  score eligibility without reading as a second paint state or an outline.
- Support Shell faces: visibly separated in value from the Playable Terrain Surface so the
  mass reads as thick.
- Paint: saturated glossy blue, surface-bound, readable at distance, and not
  dependent on emission.
- Cannon: dark navy, off-white, and blue; avoid a featureless pure-black
  silhouette.
- Burst, Splitter, and Uphill Rebound: amber, violet, and coral respectively,
  expressed as flat circular terrain glyphs with icons and direction cues that
  remain distinct without color.
- Reserve saturated color for paint, trajectory, interactive mechanisms, and
  meaningful state feedback. Keep environment dressing subdued.
- Shared material Resources own implemented values. Do not scatter duplicate
  palette constants through scripts or individual scenes.

### Lighting

- Use one readable daylight key with restrained ambient fill.
- Preserve visible face-value changes, contact shadows, self-shadow, and the
  wall/mountain join.
- Avoid flat ambient wash, crushed black shadows, heavy fog, uncontrolled bloom,
  or effects that erase facet readability.

### Gameplay objects and feedback

- Every raised visible gameplay mass has matching collision. Mechanism glyphs
  are the explicit exception: they are terrain-conforming markings, do not act
  as projectile obstacles, and keep the visible and activation footprints in
  agreement.
- Burst uses a radial explosion icon, Splitter three readable arrow spokes, and
  Uphill Rebound one explicit uphill arrow. Color is supplementary.
- Glyphs must be large enough to identify from the aiming and inspection cameras.
  The shared generator searches the actual Playable Terrain Surface, keeps each
  full circle inside the terrain with boundary and inter-glyph spacing, and may
  retain nearby route identity only for mechanism behavior. It does not use a
  stage-specific world coordinate or require the visible center to be a
  pre-authored route pad. Larger stages may carry more glyphs; small stages may
  have few or none.
- The predicted trajectory uses blue depth-tested marks and ends at the first
  real collision with a readable impact ring.
- A ball's valid Playable Terrain Surface contact produces a continuous blue
  route over its real traversal, including outside the Target Area. Only Target
  Area overlap affects coverage. The Support Shell, bottom, apron, decorations,
  mechanisms, and airborne travel remain unpainted.
- A tall cannon-side pole carries a simple flag, streamer, or windsock. Its free
  end points in the direction projectiles are pushed, and its bend/flap amplitude
  gives a restrained strength cue. It is readable from Aim View, has no gameplay
  collision or paint authority, never crosses the muzzle/trajectory silhouette,
  and yields to reduced-motion settings without hiding its static direction.
  Generic airborne leaves or debris are not the primary wind cue.
- Shot Follow keeps the newly launched root paintball readable through flight,
  then holds its first terrain contact briefly so impact, paint, and terrain
  response form one legible cause-and-effect beat.
- Muzzle, contact, mechanism, Finish, and timeout effects are brief and bounded.
  They explain cause and effect rather than covering it.

### Asset use

- Use only assets already approved and recorded in `docs/asset-licenses.md`.
- Match imported assets to the faceted, simplified scale and palette of the
  world; an approved asset is not automatically visually suitable.
- Decorations remain non-gameplay and lower contrast than targets, paint,
  trajectory, and mechanisms.

## Acceptance Criteria

A future visual review can call the world conformant only when:

- the aiming view reads immediately as a thick, stepped 3D puzzle mountain;
- the complete playable silhouette reads as a lower, wider mountain range with
  several lateral rises rather than one dominant vertical spike;
- the independently closed mountain reads clearly against an open background
  with no rear/side enclosure or wall-bank implication;
- camera movement changes overlap, side exposure, highlights, and shadows;
- routes and stage difficulty are legible before firing;
- cannon, trajectory, impact, ball contact, continuous paint, and mechanisms
  form a clear cause-and-effect chain;
- the cannon-side flag communicates wind direction without competing with the
  mountain, and the Aim View retains the full mountain at distant scale;
- no full-width slab, card-like target, dominant flat apron, enclosing wall,
  gray test-scene wash, black cannon blob, hidden gameplay mass, or decorative
  obstruction is visible; and
- the primary target image and concept board are recognizable in direction,
  while no image has been copied literally.

These criteria define a later review; they do not authorize starting Godot,
capturing a screen, or claiming approval during the current implementation
stage.

## Non-Goals

- Photoreal terrain, caves, overhangs, realistic erosion, dense foliage, or
  cinematic post-processing.
- A literal reconstruction of any reference mountain or painted still state.
- Decorative complexity that competes with route planning or physics feedback.
- A visual-only mountain that does not share gameplay collision and paint
  topology.
- Paint or score on the Support Shell, bottom, apron, decorations, mechanisms,
  or other non-playable faces.

## Related

- `VISUAL_REFERENCES.md` classifies target, concept, and rejected images.
- `UIUX_GUIDELINES.md` owns player-facing interface hierarchy.
- `../../docs/asset-licenses.md` owns asset provenance and licensing.
