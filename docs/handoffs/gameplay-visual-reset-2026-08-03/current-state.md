---
type: evidence
status: archived
created: 2026-08-03
last_reviewed: 2026-08-03
scope: corrected product intent, implementation state, and visible failure
related:
  - README.md
  - source-map.md
  - constraints-and-decisions.md
  - visuals/01-target-reference.png
  - visuals/02-current-build.png
---

# Current State and Corrected Product Intent

## Purpose

Separate the game the user now wants from stale interpretations and from what the
current code merely claims to support.

## Sources

- The user's explicit corrections in the 2026-08-03 conversation.
- The original target reference and the user's current-build capture copied into
  `visuals/`.
- `docs/source-brief.md`, root `AGENTS.md`, and the derived design documents.
- Targeted inspection of current terrain, projectile, paint, mechanism, camera,
  input, UI, and test code at baseline commit
  `15bac6405e79767df55552d0113dd906fb2a6c94`.

## Findings

### 1. The game that must be built

Paint Mountain is a desktop 3D physics puzzle. A small stationary cannon sits in
the foreground and fires a ball toward a large, distant, mountain-shaped puzzle
target. Before firing, the player chooses yaw, elevation, and power. The player
does not steer the ball in flight.

The target is not intended to be a realistic terrain simulation. It is a thick,
bright, low-poly 3D puzzle board shaped like a mountain. Its broad slopes,
terraces, ledges, basins, ridges, rises, and descents should expose readable
routes. Gravity, momentum, surface geometry, and mechanisms determine where the
ball travels after impact.

The trajectory preview may show the predicted ballistic path through its first
collision. It must not reveal the complete post-impact route, because that route
is the puzzle outcome.

### 2. Newest explicit paint correction

The following behavior is fixed and supersedes every finite-payload statement in
the source brief, current specs, resources, code, and tests:

> While the ball rolls or slides on the target terrain, it paints every target
> surface area traversed by its contact footprint. It continues doing so for its
> entire valid contact path until it settles, leaves the target, or is otherwise
> removed. Paint does not run out.

Consequences:

- There is no consumable paint amount and no shrinking trail caused by payload
  depletion.
- The persistent path must be continuous. Sparse circular stamps with visible
  gaps are not acceptable.
- The paint operation should sweep between the previous and current valid
  surface contact every physics step, or use an equivalent gap-free method.
- Coverage counts the union of painted eligible target surface once; overlap does
  not multiply coverage.
- Splitter children each obey the same continuous painting rule. Their number,
  scale, and energy may remain bounded for readability and performance, but not
  through a consumable paint budget.
- An impact splash or resting puddle may be an additional visual/gameplay mark,
  provided it does not replace continuous route painting.

### 3. Procedural target correction

Generation should begin with the puzzle routes and only then build a coherent
mountain mass around them. A noise-first heightfield that happens to contain
slopes is the wrong abstraction.

Required progression:

- Early stages: one broad, forgiving downhill route with large landing and
  rolling surfaces.
- Middle stages: branches, basins, a small number of meaningful uphill/downhill
  reversals, and one clearly readable mechanism opportunity.
- Later stages: narrower choices, more rises and drops, multiple branches, and
  mechanism-assisted high-value routes, while still remaining readable from the
  aiming camera.

The generated result must have visible thickness and a believable mountain
silhouette from every allowed camera. It may remain a heightfield if a reviewer
can show that the chosen topology, mesh shell, camera, and shading satisfy these
requirements; caves and overhangs are not required.

### 4. Visual target versus current capture

`visuals/01-target-reference.png` establishes the desired composition:

- the mountain dominates the frame but has several readable depth layers;
- routes are formed by shelves, stair-like terraces, valleys, and sloped faces;
- the cannon is small enough to leave the target readable;
- mechanisms are large, bright, distinct, and placed on meaningful route nodes;
- thick glossy blue paint clearly follows surfaces and connects into routes;
- the HUD is sparse, edge-aligned, high-contrast, and visually secondary to the
  mountain.

`visuals/02-current-build.png` shows the unacceptable result:

- the target reads as a broad gray wall or mound rather than a designed 3D puzzle
  mountain;
- the flat foreground consumes depth and disconnects the cannon from the target;
- the cannon is oversized and visually crude;
- intended paths, shelves, branches, and mechanism choices are not legible;
- mechanisms are tiny, ambiguous, or absent at gameplay scale;
- the dotted arc and impact marker dominate without clarifying surface response;
- the HUD uses undersized typography, awkward proportions, weak grouping, and a
  hierarchy unlike the reference;
- there is no convincing thick, continuous paint route in this frame.

### 5. Current implementation facts

These are code facts, not acceptance claims:

- `SeededStageGenerator` produces a deterministic `72 × 48` cell heightfield
  from route profiles, randomized mountain lobes, noise, terracing, and
  validation. Despite route inputs, the resulting visual composition remains
  mass/noise-led and wall-like in the supplied build.
- `TerrainGeometryFactory` derives a rendered closed shell, a
  `HeightMapShape3D` top collider, and skirt/bottom collision from one generated
  layout. Preserving a single geometry source is desirable.
- `PaintProjectile` extends `RigidBody3D`, enables continuous collision detection
  and contact monitoring, and records contacts. It currently gates trail writes
  by distance/time and deducts `remaining_payload`; this directly conflicts with
  the corrected rule.
- `PaintSystem` owns one `512 × 512` runtime paint mask used for rendering and
  coverage. That single-authority boundary should be preserved, but its input
  contract needs a swept continuous path operation rather than payload-limited
  point deposits.
- Burst, Splitter, and Bumper scenes contain physical `StaticBody3D` nodes and
  separate selection bodies. Code presence does not prove visible geometry and
  collision are aligned or that contact feedback is understandable in the
  running game.
- The HUD is split into reusable scenes and Korean translations exist. The
  supplied capture nevertheless fails composition, scale, type, spacing, and
  readability expectations.
- Existing automated checks exercise geometry, contacts, paint deposits,
  mechanisms, camera safety, and generated stages. A late solution search still
  fails for some target stages, and the current tests encode obsolete payload
  assumptions.

### 6. Stale authority that must be handled explicitly

The following files still specify finite paint and discrete deposits:

- `docs/source-brief.md` sections concerning payload depletion;
- `.agents/Prompt.md`;
- `docs/design-spec.md`;
- `docs/technical-architecture.md`;
- `docs/test-checklist.md`;
- `.agents/Plan.md` and
  `.agents/execplans/2026-08-03-core-interaction-redesign.md`;
- projectile resources, observation/replay fields, debug UI, and tests that track
  remaining payload.

For this review, the user's newer correction wins. Claude should identify the
minimum coherent document, data-model, runtime, replay/observation, debug, and
test migration needed to remove the obsolete concept rather than preserving it
under a renamed field.

## Current State

The repository has useful system boundaries but the central terrain/paint model
and visible composition are not acceptable. This should be treated as a focused
gameplay-and-presentation reset, not as a polishing pass and not automatically as
a total rewrite.

## Recommendations

- Decide the target topology and generator pipeline before proposing code tasks.
- Define continuous surface painting mathematically enough to implement and test.
- Decide which existing owners survive, which contracts change, and which stale
  payload fields and tests are deleted.
- Specify camera, scale, silhouette, paint, mechanism, and UI acceptance ranges
  that can be checked in running-build screenshots.
- Order the work as small vertical slices that prove the corrected interaction
  early.

## Limitations

- This package was assembled by static inspection and the two supplied images.
- No Godot editor or game window was launched while packaging, to avoid taking
  over the user's desktop.
- The current image alone cannot prove whether every collision succeeds or fails;
  runtime claims must therefore be stated as hypotheses unless supported by code
  and focused test evidence.
