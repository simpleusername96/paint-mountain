---
type: plan
status: active
created: 2026-08-03
last_reviewed: 2026-08-03
scope: terrain generation and geometry, projectile contact, paint deposition and coverage, physical mechanisms, manual aiming, trajectory preview, camera safety, replay isolation, Korean-first UI, test migration, and release evidence
source: user-directed static code and design audit dated 2026-08-03
related:
  - ../Plan.md
  - ../Documentation.md
  - ../../docs/source-brief.md
  - ../../docs/design-spec.md
  - ../../docs/technical-architecture.md
  - ../../docs/test-checklist.md
  - ../../docs/remediation-report.html
---

# Paint Mountain Core Interaction Redesign — Execution Contract

This is the only active execution plan for the redesign. The completed
`.agents/Plan.md` remains historical evidence of the prior remediation, but its
claims are not proof that the current implementation satisfies them. The code
audit summarized below found structural contradictions in terrain, collision,
aiming, paint, mechanism, UI, replay, and test design. An executor must follow
this document without reopening product or architecture choices.

## Purpose

Rebuild the existing vertical slice around one coherent physical model:

- a large, closed, lit 3D mountain whose render geometry, collision, height
  queries, paint coordinates, placement, replay metadata, and agent observation
  all derive from one immutable generated layout;
- a real rigid-body paintball that reports actual contact position, normal,
  collider, impulse, and incoming velocity, then deposits finite paint only on
  physically reached terrain;
- three visibly solid mechanisms that are struck through their physical
  collision bodies rather than invisible trigger volumes;
- manual yaw, elevation, and power controls, with a first-collision preview
  calculated from the same projectile radius, gravity, launch speed, tick rate,
  and collision layers as the real shot;
- a responsive Korean-first interface that follows the supplied aiming
  reference in hierarchy, edge placement, typography, spacing, and restraint;
- deterministic stage progression in which route topology contains more
  uphill/downhill reversals in later stages; and
- truthful automated and running-build evidence that replaces the stale
  completion claims in the current records.

The three stage targets and shot limits remain `4% / 4`, `27% / 5`, and
`70% / 6`. The implementation is complete only when deterministic solution
verification clears all three without using oversized hidden paint radii,
direct-target auto-solving, authored production terrain, or nonphysical
mechanism triggers.

## Authority and Non-Negotiable Constraints

The authority order is:

1. `docs/source-brief.md`;
2. the user's feedback and static-design correction dated 2026-08-03;
3. active product and architecture specifications, once Task 00 aligns them
   with that correction;
4. this plan, as the ordered execution record for that aligned scope;
5. historical plans, reports, screenshots, and records.

The following constraints are locked:

- Godot 4.7.1, typed GDScript where practical, Compatibility renderer, Windows
  desktop first, and fixed 60 Hz physics remain explicit. The existing 3D
  physics-backend selection is preserved; this plan does not switch it.
- `StageController` remains the only owner of stage state, shots, settlement,
  clear, and failure.
- `PaintSystem` remains the only authoritative paint mask and the only owner of
  coverage calculation. No second coverage texture, geometry overlay, or decal
  accounting system may be introduced.
- A stage has one immutable `GeneratedStageLayout`. Every terrain consumer
  receives that same instance or a read-only reference to it.
- The production mountain remains a heightfield without caves or overhangs.
  Visual depth is supplied by a closed shell, lighting, facets, skirts, and a
  bottom cap—not by changing the terrain model into voxels.
- The player always chooses yaw, elevation, and power. Clicking terrain must
  never solve or modify aim.
- The trajectory preview ends at the first predicted collision or the first
  playable-bounds exit. It never predicts post-impact motion, mechanism
  activation, paint spread, or final coverage.
- No new package, plugin, asset pack, network service, or production dependency
  is authorized. Reuse only the already committed Pretendard and approved
  Kenney assets recorded in `docs/asset-licenses.md`.
- No visible Godot editor or game window may be launched during normal
  implementation or automated verification. All iterative checks are headless.
  The final running-build inspection and screenshots require an explicit,
  user-coordinated time window because they occupy the user's desktop.
- The registered fastrun command already starts
  `builds/windows/PaintMountain.exe`; do not edit fastrun-manager configuration.
- Do not preserve obsolete sandbox or solver code merely to keep old tests
  passing. Replace those tests and remove the obsolete owner once production
  references are gone.

## Discovery Closure

All material design decisions are closed before implementation. Runtime
validation may measure whether the selected design satisfies its acceptance
thresholds, but it may not be used to choose a different architecture.

| Evidence | Static finding | Locked response |
| --- | --- | --- |
| `src/terrain/terrain_mesh_factory.gd`, `TerrainMeshFactory.build_from_layout()` | The production mesh emits only top triangles. It has no side walls or bottom, so distant or low-angle views expose a thin sheet. Legacy fixed height functions still share the file. | Replace it with `TerrainGeometryFactory`, which emits a top surface, perimeter skirts, and bottom cap from the generated layout. Remove the legacy factory after test migration. |
| `src/gameplay/gameplay_scene.gd`, `_build_stage_world()` | Rendering and a hollow concave collision shape are created directly in a coordinator script. | Add a responsibility-shaped `TerrainSurface` node that owns render/collision construction and exposes narrow layout queries. `GameplayScene` only supplies the accepted layout. |
| `src/paint/terrain_paint.gdshader` and `scenes/gameplay/gameplay.tscn` | Terrain is unshaded and shadow-disabled, flattening depth and making the mountain read like a board. | Use a lit opaque shader, flat-facet normals, shadows, high rock roughness, glossy paint, and a restrained paint-edge highlight. |
| `src/projectile/paint_projectile.gd`, `_integrate_forces()` | CCD is enabled, but reported impacts are fabricated from projectile center minus world up. Collider, shape, real point, real normal, and impulse are discarded. | Preserve shape CCD and extract real contacts from `PhysicsDirectBodyState3D`; publish an immutable `ProjectileContact`. |
| `src/mechanisms/gimmick_base.gd` | Mechanisms activate through an `Area3D` sphere. Visible mechanism meshes have no matching solid body, so preview queries can hit an area that a rigid body passes through. | Make each mechanism a `Node3D` with a compound `StaticBody3D`. Physical-body contact is the only gameplay activation path. |
| `src/mechanisms/bumper_node.gd` | Bumper behavior overwrites velocity without being tied to contact normal or a physical strike. | On the first real mechanism contact, calculate a route-aligned desired outgoing velocity and apply the exact delta as a central impulse. |
| `src/paint/paint_system.gd` | Paint is stamped as an X/Z circle, height mismatch tolerance is approximately 4.5 m, and visible writes can differ from eligible-score writes. | Gate persistent mask writes by the eligible mask, reconstruct candidate surface points from the shared layout, and accept pixels by 3D distance to the physical contact. Every persistent visible pixel is score-eligible. |
| `src/projectile/paint_projectile.gd`, `paint_radius_multiplier()` | Split children multiply radius by `6.0`, making hidden footprint size substitute for physical routing. | Remove the special multiplier. Child radius becomes `0.78` of the parent and coverage comes from three physical downhill paths. |
| `src/input/aim_input_controller.gd` and `src/cannon/impact_target_solver.gd` | A terrain click raycasts a target and auto-solves yaw/elevation; changing power re-solves elevation to preserve that target. | Delete the production target solver and implement manual two-axis drag plus keyboard angle controls, wheel/buttons for power, and Space/button fire. |
| `src/cannon/trajectory_preview.gd` | A fixed 72-dot pool at fixed spacing can stop before a long trajectory reaches collision, and the impact ring is always horizontal. | Predict the complete pre-impact path, arc-length-resample into at most 96 dots, always retain the endpoint, and orient the impact marker to the actual predicted normal. |
| `src/stage_generation/seeded_stage_generator.gd` and `resources/stage_generation/*.tres` | The generator is seeded, but production topology is authored as fixed route control points over three fixed broad lobes. Randomness is mostly jitter/noise, and reversal validation is not per route. | Generate route sign patterns, vertical magnitudes, lateral bends, and mountain lobes from the seed. Validate the realized height grid per route and per role. |
| `src/ui/hud_controller.gd`, `src/ui/ui_factory.gd`, `project.godot` | UI styling is duplicated in code, most placement assumes a 1920-wide logical canvas, and the actual 1280 window shrinks type and spacing. | Move styles into one Theme and UI structure into scene-based components at a 1280×720 logical viewport. Keep scripts behavioral. |
| `src/ui/hud_controller.gd` | The HUD omits yaw, payload, target-position context in the coverage meter, readable shot causality, and mechanism descriptions. | Add compact direction feedback, absolute coverage with a target marker, in-flight aggregate payload, localized mechanism cards, and a structured shot summary. |
| `src/camera/camera_director.gd` | Follow framing can enter terrain and simply averages split-child positions. | Add terrain-aware clearance and frame an active-projectile bounding sphere with speed-weighted focus. |
| `src/replay/replay_recorder.gd` | Replay can coexist with normal aiming and gameplay input. | Introduce an explicit replay presentation state that disables human/gameplay actions and exposes only replay controls and exit. |
| Existing phase tests and `docs/test-checklist.md` | Several tests exercise the obsolete fixed sandbox or call methods directly; the checklist claims hover, target solving, closed-looking terrain, and physical solutions despite contradictory code. | Replace behaviorless tests, uncheck/correct unsupported claims before implementation, and regenerate all evidence from the final build. |

External engine behavior is already resolved from official Godot 4.6
documentation:

- [`PhysicsDirectBodyState3D`](https://docs.godotengine.org/en/4.6/classes/class_physicsdirectbodystate3d.html)
  exposes collider position, local normal, collider object, shape index, impulse,
  and velocity data for reported contacts.
- [3D collision-shape guidance](https://docs.godotengine.org/en/4.6/tutorials/physics/collision_shapes_3d.html)
  describes concave/trimesh shapes as hollow and appropriate for static level
  geometry, while warning that small fast bodies can clip through them.
- [`HeightMapShape3D`](https://docs.godotengine.org/en/4.6/classes/class_heightmapshape3d.html)
  is the terrain-specialized fixed-grid shape. This plan uses square cells and
  uniform scale on a static terrain body; it never places a scaled heightmap on
  a dynamic body.
- [`PhysicsDirectSpaceState3D`](https://docs.godotengine.org/en/4.7/classes/class_physicsdirectspacestate3d.html)
  supplies `cast_motion()` travel fractions and `get_rest_info()` contact point
  and normal for the preview contract.

## Canonical Language and Ownership

These terms must be used consistently in code, documentation, debug output,
signals, and tests:

| Term | Meaning | Owner |
| --- | --- | --- |
| Generated layout | Immutable accepted height grid, route spines, eligible mask inputs, accepted seed, bounds, and generation metrics. | `SeededStageGenerator` creates it; consumers read it. |
| Terrain surface | The paintable top heightfield represented by the generated layout. | `TerrainSurface` |
| Render shell | Top facets plus perimeter skirts and bottom cap used only for visual mass. | `TerrainGeometryFactory` |
| Collider set | Heightmap top collider plus side/bottom skirt collider derived from the same layout. | `TerrainSurface` |
| Projectile contact | One measured physics contact containing point, normal, collider, shape, impulse, incoming velocity, and physics tick. | `PaintProjectile` creates; consumers do not mutate. |
| Mechanism strike | First projectile contact with a mechanism body after contact debounce. | Mechanism instance handles it. |
| Paint deposit request | A request to write finite paint at a physically justified terrain point. | Projectile or mechanism creates; `PaintSystem` validates and applies. |
| Eligible surface | Any playable top-terrain pixel permitted to receive persistent paint and count toward coverage, excluding only the source-brief exclusions. | Generated layout defines; `PaintSystem` enforces. |
| Coverage | Eligible pixels at or above the painted threshold divided by total eligible pixels. | `PaintSystem` only |
| Shot observation | Structured facts accumulated during one shot: contacts, mechanisms, children, payload, settlement reasons, and coverage delta. | `StageController` owns lifecycle; producers emit facts. |
| Shot settled | No active projectile and no pending paint-flow work for two consecutive physics ticks. | `StageController` |
| Replay presentation | Orthogonal input/UI-locked playback session, not a `StageController` gameplay state. | `ReplayPresentationController` |

Cross-system flow is fixed:

```text
manual aim action
  -> CannonController
  -> TrajectoryPredictor (read-only preview)
  -> StageController.fire()
  -> ProjectileManager / PaintProjectile
  -> ProjectileContact
     -> TerrainSurface contact -> PaintDepositRequest -> PaintSystem
     -> Mechanism body contact -> mechanism effect
                              -> mechanism-specific deposit / child spawn / impulse
  -> StageController waits for projectile and flow settlement
  -> ShotObservation + authoritative coverage
  -> HUD / replay / agent API consume the same facts
```

HUD, replay UI, camera, and the future AI interface never calculate gameplay
outcomes. They consume typed signals and read-only observations.

## Locked Implementation Design

### 5.1 Terrain data, render shell, and collision

All three stages retain local bounds `Rect2(-90, -60, 180, 120)`. Generation
profiles move to schema version 3 and use `Vector2i(72, 48)` cells, yielding
`73 × 49` samples at exactly `2.5 m` spacing on both X and Z.

`src/terrain/terrain_geometry.gd` is a typed `RefCounted` result containing:

- `render_mesh: ArrayMesh`;
- `top_shape: HeightMapShape3D`;
- `skirt_shape: ConcavePolygonShape3D`;
- `local_bounds: Rect2`;
- `cell_size: float = 2.5`;
- `base_y: float = -12.0`;
- vertex and triangle counts used by validation.

`src/terrain/terrain_geometry_factory.gd` is the only builder:

1. Emit two consistently wound top triangles for every cell.
2. Duplicate triangle vertices so each face has a stable flat normal.
3. Emit two vertical triangles for every perimeter segment from its edge sample
   to `base_y`.
4. Emit two bottom-cap triangles across the full bounds.
5. Build a `HeightMapShape3D` with width `73`, depth `49`, and row-major height
   values divided by `2.5`; place it under `TerrainTopBody` using a uniformly
   scaled `CollisionShape3D` with scale `(2.5, 2.5, 2.5)`.
6. Build a separate backface-enabled concave shape from only the skirt and
   bottom-cap faces under `TerrainShellBody`. The heightmap remains the sole top
   collision surface.

This produces exactly `6,912` top triangles, `480` skirt triangles, and `2`
bottom triangles: `7,394` total, below the `50,000`-triangle requirement.
Render and collision heights must match within `0.01 m` at every sample.

`TerrainTopBody` and `TerrainShellBody` are distinct `StaticBody3D` children.
Object identity therefore classifies top versus shell contact without inferring
from normals or collision-shape ordering. Only `TerrainTopBody` can accept a
paint deposit.

`src/terrain/terrain_surface.gd` owns the generated nodes and exposes only:

- `configure(layout: GeneratedStageLayout)`;
- `world_surface_point(world_xz: Vector2) -> Vector3`;
- `world_surface_normal(world_xz: Vector2) -> Vector3`;
- `contains_world_xz(world_xz: Vector2, margin: float = 0.0) -> bool`;
- `is_top_collider(object: Object) -> bool`;
- `is_skirt_collider(object: Object) -> bool`;
- `layout_read_only() -> GeneratedStageLayout`.

Collision layers are standardized:

- bit 1 `terrain`: top, skirts, bottom, and foreground ground;
- bit 2 `projectile`: paintballs;
- bit 3 `mechanism`: mechanism `StaticBody3D` nodes;
- bit 4 `selection`: mechanism selection queries only.

Projectiles mask terrain and mechanism. Preview shape casts mask terrain and
mechanism. Briefing selection rays mask selection. Mechanism bodies mask
projectiles and also expose selection on bit 4; they do not use gameplay
`Area3D` triggers.

As a diagnostic fail-safe, a projectile deactivates with
`terrain_penetration_guard` and deposits no paint when it is inside terrain X/Z
bounds and more than `3.0 m` below the sampled top for two consecutive physics
ticks. A projectile outside stage bounds by more than `4.0 m` deactivates with
`out_of_bounds`. The intended stage solutions must produce zero
`terrain_penetration_guard` events; the guard is not accepted as a collision
substitute.

The terrain shader becomes a lit opaque spatial shader:

- dry rock base `#C9CDD3`, shadow-side tint `#8E959F`, roughness `0.88`;
- paintable top terrain uses the base rock color; excluded boundary geometry is
  `8%` darker and less saturated, without drawing artificial route stripes;
- stage paint color is saturated blue by default, roughness `0.24`;
- a one-to-two-mask-pixel dark rim plus interior specular highlight suggests
  paint thickness without geometry displacement;
- no emissive paint, transparency, or per-stamp decal nodes;
- terrain casts and receives shadows.

### 5.2 Deterministic stage topology

Production route control points are removed from `StageRouteProfile`.
`StageRouteProfile` version 3 stores generation rules:

- `role`: `PRIMARY`, `SAFE`, `SPLITTER`, or `BUMPER`;
- `endpoint_x`;
- `width`;
- `target_reversals`;
- seven-element `grade_pattern`, where `-1` is downhill and `+1` is uphill;
- `downhill_drop_range`;
- `uphill_rise_range`;
- `lateral_bend_range`;
- mechanism shelf `t` and radius, using `-1.0 / 0.0` when the route has none.

Every route uses eight evenly spaced Z stations from `-46 m` through `54 m`.
For each generation attempt a fresh `RandomNumberGenerator` is seeded with the
attempt seed. Random draws occur in this exact order:

1. For each route in resource-array order, draw its seven vertical magnitudes
   in station order, then one lateral bend, then one X jitter for each interior
   station 1 through 6.
2. For each lobe in index order, draw center-X offset, center-Z offset, X
   radius, Z radius, and peak multiplier.
3. Draw one unsigned integer for `FastNoiseLite.seed`.

All float draws use `randf_range(minimum, maximum)`. Endpoint jitter is zero and
does not consume a random draw. Adding or reordering a draw requires a
profile-version increment.

Vertical sign patterns are exact:

- zero reversals: `D D D D D D D`;
- two reversals: `D D U U D D D`;
- four reversals: `D U D U D D D`.

The start height equals the profile's `nominal_peak`. Each signed segment
samples only within its profile range, so randomization changes amplitude but
cannot change reversal count. Route X uses:

`smoothstep(t) * endpoint_x + sin(PI * t) * seeded_bend`

with a bounded `±1.5 m` station jitter that is zero at the first and last
station. Route Y receives no independent noise.

The mountain is path-first:

1. Generate and freeze route spines.
2. For lobe index `i`, use `t = (i + 0.5) / lobe_count`, base Z
   `lerp(-46, 54, t)`, and base X equal to the mean route X at `t`. Add the
   drawn X `±12 m` and Z `±6 m` offsets.
3. A lobe contributes
   `nominal_peak * peak_multiplier * pow(max(0, 1 - q), 2)`, where
   `q = pow((x-cx)/radius_x, 2) + pow((z-cz)/radius_z, 2)`.
4. Combine lobes in index order with polynomial smooth maximum
   `max(a,b) + pow(max(0, k - abs(a-b)), 2) / (4*k)`, using
   `k = smooth_max_k`.
5. Add `FastNoiseLite.TYPE_VALUE_CUBIC` noise with frequency `0.035`, no
   fractal octaves, and the profile's amplitude.
6. Compute `terraced = round(height / 4.0) * 4.0` and set
   `height = lerp(height, terraced, 0.35)`.
7. Carve generated routes after noise and terracing. For each route,
   `route_target = spine_y + bank_height *
   pow(abs(x-spine_x)/(width*0.5), 2)`. Influence is `1.0` inside half-width,
   then falls with `1 - smoothstep(width*0.5, width, abs(x-spine_x))`.
   Overlapping corridors use the lowest target and greatest influence. This
   keeps each centerline deterministic while producing raised shoulders.
8. For every mechanism shelf, sample route height at shelf `t`; inside shelf
   radius set `height = lerp(height, shelf_height,
   1 - smoothstep(0.65*radius, radius, distance))`. This provides a flat inner
   placement region and a fixed transition ring.
9. Clamp height to `0..accepted_height_range.y`, then multiply by edge falloff
   `smoothstep(0, 12, edge_distance)`, where
   `edge_distance` is the minimum X/Z distance to local bounds.
10. Recompute normals, per-route metrics, mechanism/decorative placement,
   eligible mask, shelves, and visibility from the final grid.

The frozen profiles are:

| Field | First Descent | Burst Basin | Split Ridge |
| --- | --- | --- | --- |
| base / fallback seed | `845479992 / 1820876501` | `1692108109 / 976673696` | `671499753 / 1995119364` |
| nominal / accepted height | `72 / 68–78 m` | `80 / 76–88 m` | `88 / 84–98 m` |
| lobes | `3` | `4` | `5` |
| lobe X radius | `48–62 m` | `44–60 m` | `40–56 m` |
| lobe Z radius | `34–46 m` | `30–42 m` | `26–38 m` |
| lobe peak multiplier | `0.86–1.00` | `0.88–1.04` | `0.90–1.08` |
| smooth-max K | `6 m` | `6 m` | `6 m` |
| noise amplitude | `1.2 m` | `1.6 m` | `2.0 m` |
| route bank height | `5 m` | `7 m` | `9 m` |
| lateral bend draw | `-8..8 m` | `-7..7 m` | `-6..6 m` |
| interior station jitter | `-1.5..1.5 m` | `-1.5..1.5 m` | `-1.5..1.5 m` |
| routes / reversals | `PRIMARY=0` | `PRIMARY=2`, `PRIMARY=2` | `SAFE=2`, `SPLITTER=4`, `BUMPER=4` |
| endpoint X | `0 m` | `-26 / +26 m` | `-48 / 0 / +48 m` |
| route width | `28 m` | `18 / 18 m` | `16 / 12 / 12 m` |
| downhill draw | `7–9 m` | `9–14 m` | `10–16 m` |
| uphill draw | unused | `3.5–6.5 m` | safe `3.5–6.5 m`; high `5–9 m` |
| mechanism shelf | none | Burst: route 0, `t=.36`, `r=8 m` | Splitter: route 1, `t=.60`, `r=10 m`; Bumper: route 2, `t=.72`, `r=9 m` |
| eligible ratio | `0.30–0.68` | `0.35–0.75` | `0.40–0.82` |

The eligible mask represents all playable top terrain, not intended routes.
For each of the 512×512 mask pixels, bilinearly sample the final layout and mark
it eligible when height is at least `4.0 m`, the X/Z point is at least `2.5 m`
inside local bounds, and `normal.y >= cos(75°)`. Clear pixels inside each
mechanism's largest physical X/Z radius plus `1.0 m`, each decorative object's
manifest footprint plus `0.5 m`, and all nonplayable ground/background/shell
geometry. Persistent paint is visible on every eligible top location;
routes are terrain form, not a scoring stencil.

Generation uses a mutable candidate only inside the generator. After terrain
validation, `MechanismPlacementGenerator` and `DecorationPlacement` produce
deterministic placements; the eligibility builder applies their exclusions;
then the constructor freezes heights, routes, placements, mask, metrics, seed,
attempt, and checksum into one `GeneratedStageLayout`. Gameplay never modifies
that result. Stage 3's safe route is deliberately direct and mechanism-free;
the deterministic safe-route-only solution guard, rather than a hidden mask,
proves that it cannot reach 70%.

Mechanism placement does not search within a shelf. Each mechanism is placed
exactly on its owning route centerline at the profile shelf `t`:

- position is
  `TerrainSurface.world_surface_point(route_position(route_index, shelf_t)) +
  surface_normal * 0.05`;
- local Y aligns with the sampled surface normal;
- forward is the X/Z projection of the normalized difference between surface
  points at `t+0.02` and `t-0.02`;
- Bumper stores that same tangent as its redirect direction.

If this exact point fails slope, visibility, physical clearance, branch
separation, or tangent validation, the whole candidate layout is rejected.
`MechanismPlacementGenerator` validates and constructs this transform; it does
not score or choose an alternate grid cell.

Each generation attempt validates the realized height grid, not the source
spine:

- exact route count and role;
- each route's reversal count equals its configured target after ignoring
  changes smaller than `1.5 m`;
- net route descent is at least `30 m`;
- the 95th-percentile intended-route segment slope is `≤ 50°`;
- no intended route segment exceeds `58°`;
- route center remains at least `6 m` from the terrain boundary;
- mechanism shelves contain a connected region of radius
  `0.60 × shelf_radius` at `≤ 8°`;
- separate Stage 2 branches are at least `24 m` apart at `t ≥ 0.45`;
- Stage 3 high routes are at least `20 m` apart at both mechanism shelves;
- maximum height and eligible ratio are inside the exact profile-table ranges;
- a mechanism shelf has no terrain occluder before the final `0.5 m` of the
  camera ray, projects to at least `18 px` diameter in aiming and `24 px` in
  briefing at 1280×720, and respects a `3.0 m` route-edge clearance;
- the exact centerline placement passes slope, branch separation, downstream
  tangent, and clearance; there is no alternate placement tie break.

Generation uses exactly 32 deterministic candidates with zero-based
`attempt_index` and
`attempt_seed = int((requested_seed + attempt_index * 7919) & 0x7fffffff)`.
If none passes, it tries the pinned fallback seed once. A failed fallback is a
hard stage-load error and test failure; production must not silently use
authored geometry or an unvalidated partial result.

### 5.3 Real contact and paint-deposit contracts

`src/projectile/projectile_contact.gd` is an immutable `RefCounted` carrying:

- `world_position`;
- normalized world `normal`;
- `incoming_velocity`;
- `relative_normal_speed`;
- `impulse`;
- `collider`;
- `collider_instance_id`;
- `local_shape_index` and `collider_shape_index`;
- `physics_tick`;
- `is_first_contact`.

Before entering active simulation, `PaintProjectile` sets
`continuous_cd = true`, `contact_monitor = true`, and
`max_contacts_reported = 8`. It also sets `linear_damp_mode =
RigidBody3D.DAMP_MODE_REPLACE`, `linear_damp = 0.12`, and
`gravity_scale = 1.0`, so preview damping does not depend on a project default
or an Area override. In `_integrate_forces(state)` it converts
`get_contact_local_normal()` through the body's current basis and reads the
collider position/object/shape and impulse from the direct body state. If
multiple contacts begin in one tick, the primary impact is the one with
greatest impulse; ties use collider instance ID then collider shape index.
`incoming_velocity` is the projectile velocity cached at the end of the
immediately preceding physics tick, or launch velocity on its first tick.
Relative normal speed subtracts the collider's velocity at the contact point.

Contact debounce is keyed by collider instance ID plus collider shape index. A
contact may begin again only after it is absent for two consecutive physics
ticks. This prevents duplicate mechanism activation from solver jitter without
blocking a later genuine bounce.

`src/paint/paint_deposit_request.gd` carries:

- source kind `TRAIL`, `IMPACT`, `FINAL_PUDDLE`, or `BURST`;
- world position and world normal;
- radius and paint amount;
- flow permission and maximum flow steps;
- source projectile/mechanism ID;
- physics tick and deterministic sequence number.

`src/paint/paint_deposit_tuning.gd` is a typed Resource instantiated at
`resources/paint/default_paint_deposit_tuning.tres` with:

- `painted_threshold = 0.18`;
- `paint_units_per_full_alpha = 22.0`;
- intensity multipliers `TRAIL=1.0`, `IMPACT=1.15`,
  `FINAL_PUDDLE=0.90`, and `BURST=1.0`;
- `flow_amount_ratio = 0.36`, `flow_decay = 0.72`,
  `flow_radius_ratio = 0.42`, and `minimum_flow_alpha = 0.02`.

Paint amount is a per-request payload cost, not a conserved sum across pixels.
For an accepted pixel with normalized squared 3D surface distance `q`,
`radial_weight = max(0, 1 - 0.7*q)` and
`delta_alpha = clamp((request.amount / 22.0) *
kind_multiplier * radial_weight, 0, 1)`.
The authoritative value becomes `min(1, existing_alpha + delta_alpha)`.

Only these events can create a request:

- a terrain-top contact with at least `0.8 m` travel since the prior trail stamp
  or `0.12 s` elapsed, whichever occurs first;
- a newly begun terrain-top contact with relative normal speed at least
  `8 m/s`;
- final settlement while still contacting terrain top and retaining payload;
- a physically struck Burst Node projecting its center to the terrain.

Skirt, bottom, foreground-ground, decoration, and mechanism contacts do not
directly write persistent terrain paint. A contact at relative normal speed
`≥ 8 m/s` shows a transient splash; slower excluded contacts show no paint.
The effect has no mask or score authority.

For every candidate mask pixel inside a request's X/Z bounding box,
`PaintSystem` reconstructs the corresponding 3D surface point from the shared
layout. Pixel `(x,y)` maps to normalized center
`((x+0.5)/512, (y+0.5)/512)` and then to the layout's X/Z bounds. A pixel is
written only when:

- it is eligible;
- its 3D distance from the requested contact point is no greater than radius;
- its surface normal faces within `75°` of the request normal for an impact or
  Burst request; and
- it is connected to the seed pixel by the local heightfield neighborhood.

This prevents a top-down circle from painting a nearby opposite cliff or a
surface several meters below the actual contact. `PaintSystem.apply_deposit()`
returns the accepted amount and written-pixel count. If the seed is eligible
and at least one connected candidate exists, the projectile consumes the full
request amount, including paint deposited over already-painted pixels. If the
seed is ineligible or no connected candidate exists, accepted amount is zero.
Airborne movement consumes nothing.

Flow is an eight-neighbor, steepest-descent pass on the same surface grid. It
starts with `request.amount * 0.36` and radius
`max(0.8 m, request.radius * 0.42)`. After each cell, amount is multiplied by
`0.72`. It stops after `12` cells, at a local minimum, at an ineligible pixel,
or when center delta alpha is below `0.02`. It cannot cross a rise, teleport
across a saddle, or paint outside the request-connected component.

The narrow paint fixture is a flat, fully eligible `64 × 64 m` world mapped to
512×512 pixels. One centered `TRAIL` request with radius `4 m` and amount `22`
must cross threshold on exactly `3,228` pixels (`1.231384%` coverage); applying
the identical request again adds zero coverage while increasing/clamping alpha.
This fixture freezes amount-to-mask conversion independently of stage balance.

Persistent paint writes are eligible-only, and eligibility covers every
playable top surface rather than route corridors. Excluded platform,
background, underside, mechanism, decoration, and boundary impacts receive only
short-lived particles. As a result, every persistent visible paint pixel
participates in coverage, and coverage remains:

`painted eligible pixels / all eligible pixels * 100`.

Coverage is recalculated from incremental threshold crossings in the
authoritative mask and published at 5 Hz while a shot is active, then finalized
only after projectile and flow settlement.

### 5.4 Physical mechanisms

`GimmickBase` changes from `Area3D` to `Node3D`. Each mechanism scene contains:

- `MechanismBody: StaticBody3D` on collision layer 3;
- compound primitive `CollisionShape3D` children sized to the visible base and
  activation silhouette;
- the existing visual meshes;
- a separate selection query path on layer 4;
- one typed `struck(projectile, contact)` entry point;
- duplicate-contact, cooldown, charge, reset, snapshot, and localization data.

No invisible oversized gameplay trigger is allowed. Preview and the real ball
query the same physical mechanism body.

Physical shape dimensions are frozen:

- Burst: base cylinder radius `1.8 m`, height `0.7 m`; orb sphere radius
  `1.05 m`, center Y `1.35 m`.
- Splitter: base cylinder radius `1.75 m`, height `0.65 m`; center sphere radius
  `0.58 m`, center Y `1.65 m`; three outlet capsules radius `0.24 m`, total
  height `2.5 m`, transformed to match the three visible outlet arms.
- Bumper: base cylinder radius `1.9 m`, height `0.65 m`; upper cylinder radius
  `1.3 m`, height `0.5 m`, center Y `0.86 m`.

Mechanism tuning is frozen:

- Burst has one charge, `0.35 s` cooldown, radius `14 m`, paint amount `140`,
  and at most `12` flow steps. It creates one terrain-aware deposit at the
  projected shelf center; the incoming ball continues through normal rigid-body
  collision response.
- Splitter has unlimited stage-lifetime charges subject to `0.30 s` cooldown,
  but a projectile instance activates it once. It removes the parent and emits
  exactly three generation-1 children. Each receives `30%` of remaining
  payload, for `90%` total, speed multiplier `0.78`, minimum route speed
  `22 m/s`, physical radius multiplier `0.78`, and paint-radius multiplier
  `0.78`. Generation-1 children cannot split again. The global eight-projectile
  cap remains.
- Bumper has unlimited charges subject to `0.80 s` cooldown. Its placement
  stores a normalized downstream terrain tangent. On first strike, desired
  velocity is
  `normalize(downstream_tangent + UP * 0.22) *
  clamp(max(incoming_speed * 0.85, 18), 18, 32)`.
  The mechanism queues this desired velocity on the projectile. At the next
  `_integrate_forces`, after the ordinary static-body response, the projectile
  applies `mass * (desired - state.linear_velocity)` as a central impulse.
  Desired speed is based on `ProjectileContact.incoming_velocity`; the
  corrective impulse is based on the post-contact direct-body velocity. It
  does not teleport or directly set the rigid body's transform.

The Splitter child destinations and Bumper tangent derive from the generated
route role and shelf, not stage-specific node paths. A mechanism's orientation,
collision shape, icon arrow, and actual redirection direction must agree.

For Split Ridge, Splitter children indexed `0,1,2` target route roles
`SAFE`, `SPLITTER`, and `BUMPER`, respectively, all at `t=0.82`. These role
names, target `t`, and lift `5.0 m` are stored in `MechanismData`. Let
`child_radius = parent_radius * 0.78` and let the lateral fan axis be
`contact.normal.cross(owning_route_downhill_tangent).normalized()`. Child `i`
spawns at:

`contact.world_position + contact.normal *
(parent_radius + child_radius + 0.05) +
fan_axis * (i - 1) * (2 * child_radius + 0.10)`.

Its target is the selected route's generated surface point at `t=0.82` plus
`Vector3.UP * 5.0`; launch direction is the normalized target-minus-spawn
vector, and speed is `max(incoming_speed * 0.78, 22.0)`. No node path,
coverage query, or runtime score chooses a destination.

The new mechanism values are deliberate preimplementation balance constraints,
not claims of prior runtime validation. Burst radius `14 m` is `3.5×` the
ordinary trail radius and `1.56×` the ordinary `9 m` impact radius, while its
`140` paint amount is less than 27% of one `520`-unit payload; it is useful but
cannot replace routing. Splitter loses 10% payload and removes the former
sixfold hidden footprint. If the fixed-target solution gate fails after defects
are excluded, execution stops for a contract revision rather than silently
retuning these values.

### 5.5 Manual aiming and first-collision preview

`ImpactTargetSolver` is removed from production. `AimInputController` maps
human input to the same narrow actions used by replay and the agent API:

- drag on empty 3D viewport: horizontal delta changes yaw by `0.15°/px`;
  vertical delta changes elevation by `-0.12°/px`;
- `A/D`: yaw by `0.5°`;
- `W/S`: elevation by `0.5°`;
- mouse wheel: power by `1%`;
- power minus/plus buttons: `2%` per click, with `300 ms` hold delay and `80 ms`
  repeat;
- Space or the Fire button: one fire request on press, never on repeat;
- Tab: switch between briefing and aiming through `StageController`;
- click a mechanism in briefing: select it and show its localized description.

Pointer input that begins over UI is consumed by UI and never changes aim.
A non-echo A/D/W/S press applies one step immediately; a held key repeats after
`300 ms` and then every `80 ms`, independent of operating-system key repeat.
Aiming drag changes both axes simultaneously and is clamped to yaw
`-28°..28°`, elevation `18°..68°`, and power `0..100%`. Fire is valid whenever
the stage is in AIMING, shots remain, no modal/pause/replay state is active, and
the predicted path has either a first collision or a defined bounds-exit
result. An out-of-bounds prediction is shown red and remains fireable; it is a
planning choice, not an invalid hidden state.

`src/cannon/trajectory_prediction.gd` is an immutable result with kind
`COLLISION`, `BOUNDS_EXIT`, or `TIMEOUT`, endpoint, sampled points, duration,
and collider; normal exists only for `COLLISION`.
`src/cannon/trajectory_predictor.gd` becomes the shared pre-impact predictor.
For up to `12 s` or `720` fixed steps it:

1. obtains launch origin and velocity from `CannonController` and
   `CannonBallistics`;
2. for `dt = 1/60`, applies
   `velocity *= max(1 - 0.12 * dt, 0)`, then
   `velocity += project_gravity * dt`, then
   `next_position = position + velocity * dt`, matching the locked rigid-body
   damping/force order;
3. calls `cast_motion()` with the actual projectile sphere against terrain and
   mechanism masks;
4. when safe fraction is below 1, moves the query transform to the safe
   endpoint plus `0.01 m` along normalized motion and calls `get_rest_info()`
   with the same shape, mask, and body/area flags; `rest_info.point` and
   normalized `rest_info.normal` become the collision result;
5. stops at that point, or stops at the first stage-bounds crossing.

An empty rest-info result after a cast hit is `TIMEOUT` with predictor failure
diagnostics, not a fabricated normal. `GameplayScene` recomputes prediction
synchronously on every `CannonController.aim_changed`, even when preview
rendering is hidden, and calls `CannonController.set_prediction()`. Collision
and bounds-exit results are fireable; timeout is not.

The predictor is read-only: it never invokes a mechanism or paint effect.
`TrajectoryPreview` draws the full result with no more than 96 pooled dots.
After prediction it computes total arc length and uses effective spacing
`max(2.2 m, arc_length / 95)`. It always places the launch dot and the
collision/exit endpoint. A collision ring is tangent to the predicted normal
and blue-white. A bounds exit uses a camera-facing red cross and no normal.
Preview error must be no more than `2.0 m` between predicted and measured
first-contact points over the frozen regression set.

### 5.6 Shot observation, camera, and replay

`src/stage/shot_observation.gd` is a typed data object with:

- shot number and commanded yaw/elevation/power;
- first terrain/mechanism contact point and normal;
- ordered mechanism activation kinds;
- spawned child count and peak active-projectile count;
- initial, current, and consumed aggregate payload;
- per-reason projectile settlement counts;
- coverage before, after, and gain;
- penetration-guard count.

`StageController` creates one at fire time, accepts facts through typed signals,
and seals it only after all projectiles and paint flow are inactive for two
physics ticks. HUD, replay, debug, and agent observations receive the sealed
object; none reconstruct it from nodes.

`CameraDirector` keeps briefing, aiming, follow, wide, and result modes. It adds:

- a terrain shape/ray query from desired camera position to focus point;
- minimum camera-to-terrain clearance `1.5 m`;
- a `0.20 s` critically damped correction when desired position violates that
  clearance;
- split framing from the active-projectile bounding sphere plus `15%` margin;
- speed-weighted focus toward the fastest ball, capped to `35%` of focus
  contribution;
- `follow_camera_max_distance: float = 96.0` in `StageData`, set to `96.0` in
  all three stage resources;
- a one-way transition to wide view when required follow distance exceeds
  `96 m`, retained until the active-projectile bounds shrink below `81.6 m`
  (`0.85 × 96`) to prevent mode thrashing;
- no position behind or inside terrain.

Replay format increments to 3 and is deterministic-action-only. Its persisted
schema is:

- header: format version, stage ID/version, generation profile ID/version,
  accepted seed, height checksum, and physics FPS `60`;
- ordered actions: physics tick and action kind; aim actions carry
  yaw/elevation/power, camera-change actions carry camera mode, and fire/restart
  actions carry no unused value fields;
- expected observations per shot: first contact point, ordered mechanism kinds,
  coverage gain/total, settlement reasons, and result state.

Format 3 does not contain transform samples. A fresh-process replay passes only
when first contact differs by at most `0.5 m`, every shot's coverage differs by
at most `0.1` percentage point, mechanism order is exact, and final result state
matches. Failure blocks completion rather than selecting another playback
architecture. Format-2 replays are rejected with a localized incompatibility
message because terrain and aim semantics changed.

Add `src/replay/replay_presentation_controller.gd`. Its active flag is
orthogonal to `StageController.State`; there is no `REPLAY_PRESENTATION` stage
state. `ReplayRecorder` owns recording and action scheduling.
`ReplayPresentationController` owns input/UI lock, replay controls, and exit.
Every aim/fire/restart action carries `StageController.ActionOrigin`
(`HUMAN`, `REPLAY`, `AGENT`, or `DEBUG`). While replay presentation is active,
`StageController` accepts only `REPLAY` origin through the same normal state and
shot guards and rejects every other origin. Aim input, Fire, Restart, stage
navigation, and debug mutation are disabled; only play/pause, restart playback,
`1×/2×`, and Exit are active. Exit requests a replay-origin clean restart,
returns to briefing, releases the origin lock, then restores normal input/UI.

### 5.7 Korean-first UI and reference layout

Set `display/window/size/viewport_width=1280`,
`display/window/size/viewport_height=720`,
`display/window/size/window_width_override=1280`,
`display/window/size/window_height_override=720`, and
`display/window/stretch/mode="canvas_items"`. Supported release checks are
1280×720, 1600×900, and 1920×1080 at 16:9. UI is built with anchors and
Containers; no gameplay HUD control uses a hardcoded 1920-pixel position.

`resources/ui/paint_mountain_theme.tres` becomes the sole visual token owner:

- Pretendard Variable throughout;
- background `#F3EEE8`;
- panel `#FFFDFC` at 96% opacity;
- primary text/navy `#172538`;
- secondary text `#687384`;
- accent/paint blue `#2584FF`;
- focus `#70AAFF`;
- danger `#D94C4C`;
- panel corner radius `12 px`, primary action radius `16 px`;
- outer safe margin `24 px` at 1280;
- minimum body type `16 px`, labels `14 px`, top status `18 px`, metric values
  `28 px`, primary action `20 px`;
- minimum ordinary control height `40 px`, primary action height `96 px`;
- keyboard focus uses a visible `2 px` outline and never color alone.

The aiming HUD follows the supplied reference:

- top-left stage chip `Rect2(24,16,128,44)`;
- top-center target chip `Rect2(497,16,286,44)`;
- top-right shots chip `Rect2(1086,16,170,44)`;
- left mode chip `Rect2(24,72,128,40)`;
- bottom-left aim panel `Rect2(24,586,300,110)`;
- bottom-center coverage panel `Rect2(410,640,460,56)`;
- bottom-right Restart `Rect2(1028,584,88,112)` and Fire
  `Rect2(1128,584,128,112)`;
- all are edge anchored with at least `24 px` margin;
- the central mountain and predicted path remain free of modal cards.

These are 1280×720 logical rectangles. For a supported physical viewport,
`scale = physical_width / 1280 = physical_height / 720`; expected physical
position and size are `roundi(logical_component * scale)` independently for X,
Y, width, and height. This gives scale `1.0`, `1.25`, and `1.5` at the three
supported resolutions and is the only cross-resolution geometry formula used
by UI tests.

The bottom-left panel shows compact direction/yaw plus large elevation and
power. Power minus/plus controls sit beside the power value. The coverage meter
uses an absolute `0..100%` fill, a distinct target marker, and the text
`현재 {current}% / 목표 {target}%`. This retains comparable coverage across
stages while making Stage 1's small target explicit.

Scene-based UI components replace code-built panels:

- `scenes/ui/hud/top_status_bar.tscn`;
- `scenes/ui/hud/aim_controls.tscn`;
- `scenes/ui/hud/coverage_meter.tscn`;
- `scenes/ui/hud/action_buttons.tscn`;
- `scenes/ui/hud/observation_controls.tscn`;
- `scenes/ui/hud/shot_summary.tscn`;
- `scenes/ui/hud/result_panel.tscn`;
- `scenes/ui/hud/replay_bar.tscn`;
- `scenes/ui/hud/mechanism_info_card.tscn`;
- `scenes/ui/screens/main_menu.tscn`;
- `scenes/ui/screens/stage_select.tscn`;
- `scenes/ui/screens/settings.tscn`;
- `scenes/ui/screens/pause_overlay.tscn`.

Each scene has a responsibility-matched script under `src/ui/hud` or
`src/ui/screens`. `HudController` only coordinates component visibility and
typed state updates. Delete `UIFactory` after its final caller is migrated.
Scripts may not construct StyleBoxes or duplicate palette/font constants.

During flight, observation controls show aggregate remaining payload as a small
icon and bar; Splitter children are summed. After settlement, a nonmodal shot
summary remains for `1.2 s` and states coverage gain plus observed causes, for
example `+8.4% · 분열 1회 · 공 3개`. Mechanism activation shows its name for
`1.2 s`. Stage 1 shows one four-second session-only hint:
`드래그/A·D·W·S로 조준 · 휠/−·+로 파워 · Space로 발사`.

Mechanism briefing copy is frozen:

- Burst: `명중하면 주변 유효 경로에 페인트를 퍼뜨립니다.`
- Splitter: `남은 페인트를 세 공으로 나눠 여러 경로로 보냅니다.`
- Bumper: `공을 화살표 방향의 다음 경사로 되돌려 보냅니다.`

English equivalents are added under the same translation keys. Korean remains
the fresh-save default and the settings locale switch remains immediate and
persistent. `translations/ui.csv` is the editable source; Godot regenerates
`translations/ui.ko.translation` and `translations/ui.en.translation`, which
are never hand-edited. Ordinary gameplay has no persistent tooltip over the
mountain.

Use existing approved assets only:

- Pretendard: `assets/fonts/pretendard/PretendardVariable.woff2`;
- UI icons: `assets/ui/icons/{minus,plus,restart,pause,settings,target}.png`;
- sparse noncolliding dressing:
  `rock_largeA.glb`, `rock_smallA.glb`, `tree_pineSmallA.glb`,
  `tree_pineSmallB.glb`, and `tree_pineTallA.glb`;
- VFX: `glint.png`, `impact_ripple.png`, `muzzle_ring.png`,
  and `paint_mist.png`.

No screenshot, report mockup, or candidate image becomes a runtime asset.

## Scope and Boundaries

### In scope

- Correct the misleading current docs before relying on them.
- Replace production terrain geometry and collision while keeping the
  heightfield model.
- Replace fixed authored route control points with seeded, validated topology.
- Add measured contact and deposit contracts.
- Convert all three mechanisms to solid physical bodies and retune them to the
  frozen values.
- Replace auto-targeting with manual aim and complete first-impact preview.
- Make persistent paint and score visibly consistent.
- Add terrain-safe camera framing and isolated replay presentation.
- Rebuild user-facing screens/HUD with the frozen Korean-first layout and
  existing assets.
- Replace obsolete tests, add missing structural/behavior tests, remove dead
  sandbox/solver/UI-factory code, export, and regenerate evidence.

### Out of scope

- caves, overhangs, destructible/deformable terrain, voxel terrain, or fluid
  simulation;
- direct control of a projectile after firing;
- post-impact route, mechanism, or coverage prediction;
- additional stages, mechanisms, paint colors, projectiles, currencies,
  achievements, online features, analytics, mobile controls, or multiplayer;
- new external assets, dependencies, plugins, render pipelines, or shaders that
  require a renderer change;
- changes to the fastrun-manager registration;
- redesign of the future AI contract beyond adapting it to the same manual aim
  actions and new observation object.

## Tasks

Tasks must be implemented in order. Each task ends with its acceptance and
regression checks before the next task starts. Each completed task is a
coherent scoped commit; do not mix unrelated user changes.

### Task 00 — Reset documentation to the audited baseline

Change:

- Update `docs/design-spec.md` to replace direct-target aiming, open-looking
  terrain, invisible-trigger mechanisms, and ambiguous visible/scored paint
  with this contract.
- Update `docs/technical-architecture.md` with the owners and typed flow in
  Section 4.
- Update `README.md` controls and architecture; remove hover/target-solver
  claims.
- Change invalid checked items in `docs/test-checklist.md` back to unchecked
  redesign gates. Preserve the dated observed evidence as historical, clearly
  labeled as belonging to the superseded build.
- Update `.agents/Documentation.md` with a 2026-08-03 static-audit correction
  that links this plan and distinguishes claimed prior evidence from current
  code truth.

Accept:

- Active docs agree that aim is manual, terrain is a closed visual shell over a
  heightfield collider set, mechanisms are physically struck, and the new gates
  are not yet passed.
- Historical artifacts remain available and are not rewritten as current
  proof.

Guard:

- Do not modify `docs/source-brief.md`.
- Do not mark any implementation task complete in docs during this task.

### Task 01 — Introduce typed contracts and the terrain owner

Add:

- `src/terrain/terrain_geometry.gd`;
- `src/terrain/terrain_geometry_factory.gd`;
- `src/terrain/terrain_surface.gd`;
- `src/projectile/projectile_contact.gd`;
- `src/paint/paint_deposit_request.gd`;
- `src/paint/paint_deposit_tuning.gd`;
- `src/stage/shot_observation.gd`;
- `src/cannon/trajectory_prediction.gd`.

Change:

- Give `GameplayScene`, `StageController`, `ProjectileManager`, and
  `PaintSystem` the narrow typed interfaces described above without changing
  visible behavior yet.
- Add collision-layer names and preserve the existing 60-Hz setting in
  `project.godot`; do not change `physics/3d/physics_engine`.

Accept:

- New types parse under Godot 4.7.1.
- No new type mutates stage state or coverage outside its designated owner.
- The existing main scene still loads headlessly.

Guard:

- Do not place UI strings, stage-specific node paths, or per-stage tuning in the
  new types.

### Task 02 — Replace authored topology with the frozen generator

Change:

- Replace `StageRouteProfile.control_points` with the version-3 rules.
- Implement the path-first algorithm and fixed random-consumption order in
  `SeededStageGenerator`.
- Extend `GeneratedStageLayout` with route roles, per-route reversal metrics,
  accepted attempt, checksum, deterministic placements, and eligible mask.
- Update `MechanismPlacementGenerator` to place by route role and frozen shelf.
- Rewrite the three profile resources with every field in the Section 5.2
  table, including the square `72 × 48` grid.
- Increment the three profile and `StageData.stage_version` values to 3.

Tests:

- Extend `tests/stage_generation_test.gd` to run every base/fallback seed twice,
  compare checksums, and assert every acceptance metric per route.
- Extend `tests/mechanism_placement_test.gd` for physical shelf dimensions,
  visibility, role mapping, exact centerline transform, downstream tangent, and
  candidate rejection when that fixed point fails.

Accept:

- Every stage accepts within the 32-attempt sequence or its pinned fallback.
- Repeated runs match accepted seed, attempt, layout checksum, route roles,
  placement transforms, and eligible-mask checksum.
- Stage 1 has no reversal; Stage 2 has two per route; Stage 3 has two on safe
  and four on each high route.

Guard:

- No production `.tres` contains route `control_points`.
- No fallback uses hand-authored X/Z positions or fixed height formulas.

### Task 03 — Replace terrain mesh and collision

Change:

- Build the `7,394`-triangle closed render shell and separate top/shell
  collider bodies.
- Update `scenes/gameplay/gameplay.tscn` to contain the stable `TerrainSurface`,
  `TerrainTopBody`, and `TerrainShellBody` node structure.
- Reduce `src/gameplay/gameplay_scene.gd` to layout orchestration.
- Replace `src/paint/terrain_paint.gdshader` with the frozen lit material.
- Enable terrain shadow casting and receiving.

Add tests:

- `tests/terrain_geometry_test.gd` checks exact counts, winding, quantized
  watertight edges, bounds, sample parity, collider object identity, and direct
  sphere-cast classification against the top/shell bodies.
- Update `tests/phase2_physics_test.gd` to verify the generated fixture scene
  loads both colliders. The fixture is a `12 × 12`-cell,
  `Rect2(-15,-15,30,30)` layout. Flat height is `0`; ramp height is
  `tan(35°) * (x + 15)`. Shots are: flat `(start=(0,10,0),
  velocity=(0,-100,0))`; ramp `(start=(0,ramp_y(0)+10,0),
  velocity=(0,-100,0))`; flat graze `(start=(-10,1,0),
  velocity=(80,-20,0))`; and flat skirt `(start=(20,-4,0),
  velocity=(-100,0,0))`. Task 03 exercises these as direct shape casts; Task 04
  repeats them with real projectiles after authoritative contact extraction.

Accept:

- Render/collision sample error is `≤ 0.01 m`, every quantized render-shell
  edge is shared by exactly two faces, and all four direct fixture casts
  classify the expected top/shell body.
- Headless geometry gates prove closure; the named camera-bookmark visual check
  remains in Task 10.

Guard:

- Do not add a second terrain height formula.
- Do not make a dynamic rigid body use a concave collision shape.

### Task 04 — Make physics contact authoritative and unify paint

Change:

- Extract and debounce real contacts in `PaintProjectile`.
- Route terrain contacts through `PaintDepositRequest`.
- Add `resources/paint/default_paint_deposit_tuning.tres` with the frozen mask
  conversion values.
- Implement 3D surface-distance stamps, eligible-only persistence, connected
  steepest-descent flow, and accepted-payload accounting in `PaintSystem`.
- Bind paint and eligible textures from `PaintSystem` to the terrain shader.
- Add transient nonauthoritative effects for rejected/noneligible contacts.
- Publish structured contact and paint facts to `StageController`.

Tests:

- Add `tests/projectile_contact_test.gd` for point, normal, collider, impulse,
  first-contact ordering, and recontact debounce.
- Repeat each of Task 03's four exact high-speed fixtures 20 times with real
  `PaintProjectile` instances at 60 Hz.
- Rewrite `tests/phase3_paint_test.gd` and
  `tests/phase3_projectile_paint_test.gd` against generated layout fixtures.
- Assert the exact `3,228`-pixel narrow-fixture result and zero second-stamp
  coverage gain.
- Assert persistent visible pixels equal score-eligible written pixels, overlap
  is not double-counted, opposite cliffs are not stamped, and airborne travel
  consumes no payload.

Accept:

- For the Task 03 terrain fixtures, reported point is within `0.05 m` of the
  known surface, `dot(reported_normal, expected_normal) ≥ 0.98`, and collider
  object identity is exact across all 80 shots; projectile-center distance is
  physical radius `±0.05 m`. For mechanism fixtures, the point is within
  `0.05 m` of the contacted primitive and collider/shape identity matches the
  predictor.
- Terrain, shader, debug mask, and coverage all use the same runtime paint
  image.
- Coverage changes only from accepted deposits and finalizes only on settlement.

Guard:

- Remove the `4.5 m` height tolerance and world-up fabricated impact.
- Do not add decals or a second coverage representation.

### Task 05 — Convert mechanisms to physical bodies

Change:

- Rebuild the three mechanism scenes with the frozen compound shapes.
- Change `GimmickBase` to the physical strike interface.
- Apply exact Burst, Splitter, and Bumper values from Section 5.4.
- Add localized display and description keys to `MechanismData` resources.
- Feed activation and child-spawn facts into `ShotObservation`.

Tests:

- Rewrite `tests/phase5_mechanism_test.gd` to use real rigid-body contacts.
- Assert preview and ball hit the same body/shape within `0.25 m`.
- Assert one contact cannot double-activate; later separated contact can.
- Assert Burst writes only through `PaintSystem`, Splitter conserves exactly
  90% payload and stops at generation 1, Bumper impulse matches the displayed
  tangent, reset restores all states, and active balls never exceed 8.

Accept:

- Every named Burst base/orb, Splitter base/center/outlet, and Bumper
  base/upper mesh has its frozen primitive; each collision AABB remains inside
  the corresponding visual AABB expanded by `0.10 m`.
- There is no gameplay activation `Area3D`.
- Every activation appears exactly once in the sealed shot observation; visual
  legibility is checked at the named Task 10 bookmarks.

Guard:

- Do not enlarge hidden collision beyond the frozen primitive dimensions.
- Do not restore the split-child `6.0` paint-radius multiplier.

### Task 06 — Replace auto-targeting with manual aim and full preview

Change:

- Add `TrajectoryPrediction` and `TrajectoryPredictor`, then update
  `TrajectoryPreview`.
- Replace `AimInputController` with the exact manual mapping.
- Remove solver calls from `GameplayScene`, `CannonController`, replay, debug,
  and agent paths.
- Update input actions, button semantics, and the AI action interface.
- Record raw yaw/elevation/power actions rather than target points.

Tests:

- Rewrite `tests/aim_interaction_test.gd` to dispatch actual mouse/key/wheel/UI
  events through the scene tree.
- Test UI-consumption boundaries, clamps, increments, hold timing, Space
  single-fire, and Tab state transition.
- For each stage compare preview classification/endpoints with runtime for this
  exact ten-tuple set `(yaw,elevation,power)`:
  `(-28,18,0)`, `(-28,43,50)`, `(-28,68,100)`, `(-14,28,75)`,
  `(-14,58,25)`, `(0,18,100)`, `(0,43,50)`, `(0,68,0)`,
  `(14,28,25)`, `(28,58,75)`. This produces 30 frozen stage/aim cases.
- Add one isolated mechanism-body sphere-cast fixture per mechanism and one
  explicit bounds-exit fixture; these verify collider/normal and exit-cross
  behavior without depending on generated placement.

Accept:

- Terrain click never changes aim.
- Every control path changes only the requested axis/value.
- Preview always reaches and includes its first collision or bounds exit with at
  most 96 nodes and `≤ 2.0 m` collision error; timeout remains non-fireable.

Guard:

- Delete `src/cannon/impact_target_solver.gd` and its UID only after `rg` shows
  zero production/test references.
- Do not preview post-impact behavior.

### Task 07 — Add shot causality, safe camera, and isolated replay

Change:

- Complete `ShotObservation` collection and sealed signal.
- Add terrain-clearance and multi-projectile framing to `CameraDirector`.
- Add `follow_camera_max_distance` to all stage resources.
- Increment replay format to 3 and add `ReplayPresentationController` plus
  action-origin locking.
- Update `GameplayAgentApi` to expose the same aim actions and observation
  fields without HUD coupling.

Tests:

- Add `tests/shot_observation_test.gd`.
- Add `tests/camera_safety_test.gd`. For each stage it samples every physics tick
  through briefing yaw `-22°/0°/+22°`, briefing zoom `-22/+28`, all aiming,
  wide, and result bookmarks, every mechanism focus, the Task 03 top/skirt
  fixtures, and a deterministic three-child spread.
- Add `tests/replay_presentation_test.gd` proving gameplay input cannot mutate
  state during playback.
- Update replay/persistence tests for format-3 metadata and format-2 rejection.

Accept:

- At each sampled tick where camera X/Z lies in terrain bounds,
  `camera.y - sampled_surface_y ≥ 1.5 m`. A camera-to-focus ray may intersect
  terrain only within the final `0.25 m` before a terrain focus point.
- All shot-summary facts match source signals and coverage.
- Fresh-process replay meets the fixed `0.5 m / 0.1 percentage-point` tolerance,
  exact mechanism order, and final-state match; normal input remains fully
  disabled until exit.

Guard:

- Camera and replay must not call paint or mechanism effects directly.
- Save migration must preserve locale, unlocks, results, and settings.

### Task 08 — Rebuild the Korean-first interface

Change:

- Set the project logical viewport to 1280×720.
- Implement the frozen Theme tokens and component scenes.
- Make `HudController` a coordinator and migrate menu, select, settings, pause,
  gameplay, result, and replay states.
- Add Korean/English mechanism descriptions, shot copy, payload copy, target
  marker, direction readout, focus states, and first-session hint.
- Use only the approved committed assets.
- Delete `UIFactory` and ad hoc `_style` helpers after the final caller moves.

Tests:

- Update `tests/localization_ui_test.gd` and `tests/phase7_ui_test.gd`.
- Programmatically assert min font/control sizes, anchors, focus visibility,
  selected-stage state, Korean/English key completeness, and no overflow at the
  three supported resolutions.
- Assert mechanism callout lifetime is `1.2 ± 0.1 s`, shader code contains no
  `EMISSION` write, and bound dry/paint roughness values are `0.88 ± 0.01` and
  `0.24 ± 0.01`.
- Capture headless render artifacts only where the existing runner supports
  them without opening a window; do not treat them as final visual approval.

Accept:

- At 1280×720 every aiming-HUD component's global rectangle matches the frozen
  edge region within `2 px`; at 1600×900 and 1920×1080 the same normalized
  anchors and aspect-scaled gaps match within `3 px`.
- No supported resolution has clipping, overflow, offscreen actions, or body
  text below 16 logical pixels.
- Korean is the fresh-save default; English switching remains immediate and
  persistent.
- The result panel uses at most 35% of screen width at 1280 and does not obscure
  the painted mountain.

Guard:

- Do not build panels or StyleBoxes in GDScript.
- Do not add persistent labels/tooltips over ordinary gameplay terrain.

### Task 09 — Retire false fixtures and build one truthful verification path

Change:

- Add `scripts/test.ps1` with a deterministic ordered list of all active test
  scripts and a required `-GodotPath` argument.
- Migrate remaining phase/content/reliability/performance tests to generated
  layouts and production entry points.
- Update performance assertions to stage load `≤ 3,000 ms`, average
  `≥ 60 FPS`, worst frame `≤ 33.3 ms`, static memory `≤ 128 MiB`, restart
  `≤ 50 ms`, and active projectiles `≤ 8`.
- Remove `scenes/sandbox/projectile_sandbox.tscn`,
  `src/stage/projectile_sandbox.gd`, their UIDs, and legacy
  `TerrainMeshFactory` only after all production/tests use replacements.
- Update delivery capture automation to use manual aim tuples and format-3
  replay facts.
- Run deterministic solution search and commit the measured successful shot
  arrays to the three `StageData.reliable_solution` fields.

`scripts/test.ps1` runs these ordinary scripts in this exact order, one fresh
headless process per script, stopping at the first nonzero exit:

1. `tests/terrain_geometry_test.gd`
2. `tests/stage_generation_test.gd`
3. `tests/mechanism_placement_test.gd`
4. `tests/decoration_placement_test.gd`
5. `tests/phase2_test.gd`
6. `tests/phase2_physics_test.gd`
7. `tests/projectile_contact_test.gd`
8. `tests/phase3_paint_test.gd`
9. `tests/phase3_projectile_paint_test.gd`
10. `tests/phase4_state_test.gd`
11. `tests/phase5_mechanism_test.gd`
12. `tests/phase6_content_test.gd`
13. `tests/aim_interaction_test.gd`
14. `tests/shot_observation_test.gd`
15. `tests/camera_safety_test.gd`
16. `tests/phase7_ui_test.gd`
17. `tests/localization_ui_test.gd`
18. `tests/shot_feedback_test.gd`
19. `tests/replay_presentation_test.gd`
20. `tests/phase8_debug_test.gd`
21. `tests/phase8_reliability_test.gd`
22. `tests/phase8_performance_test.gd` with `--resolution 1920x1080`
23. `tests/phase6_solution_test.gd`

The runner then executes these fresh-process matrices:

- persistence:
  `phase8_persistence_test.gd -- --mode=cleanup`, then `write`, then `read`,
  then `cleanup`;
- replay:
  `phase8_replay_process_test.gd -- --mode=cleanup`, then `record`, then
  `replay`, then `cleanup`.

Every invocation uses
`Godot --headless --path <project-root> --script res://tests/<script>`.
Cleanup runs in a PowerShell `finally` block even after a failed read/replay.
Pass means every process exits `0`, both final cleanup processes exit `0`, and
no test leaves a game/editor process or fixture file behind.

The solution search is deterministic rather than a design choice:

1. Evaluate a coarse lattice in ascending tuple order: yaw every `4°`,
   elevation every `4°`, power every `10%`.
2. Keep the best 12 states after each shot by, in order: coverage, required
   mechanism activations, remaining payload, then lexicographic shot tuple.
3. Refine every retained tuple in `±4° / ±4° / ±10%` using
   `1° / 1° / 2%` steps.
4. Continue to each stage's shot limit.
5. Record the shortest sequence that reaches target; ties choose higher final
   coverage, then lexicographically smaller sequence.
6. Separately run six Stage 3 safe-route-only shots and require failure below
   70%.

Accept:

- `scripts/test.ps1`, `scripts/verify.ps1`, export, and final production
  validation all use the same Godot executable and project root.
- Every active test exercises a production owner or an explicitly named narrow
  fixture.
- The three deterministic solutions clear `4/27/70%` within `4/5/6` shots,
  Stage 3 high-route solution activates both Splitter and Bumper, and
  safe-route-only fails.
- No obsolete sandbox, target solver, duplicated terrain factory, or UIFactory
  reference remains.

Guard:

- Do not lower targets, increase shot counts, restore oversized paint, or
  hand-author terrain to make solution search pass.

### Task 10 — Production evidence and documentation closeout

Automated work, which must remain headless:

- Run the complete test script.
- Run project import/parse/main-scene smoke.
- Export the Windows release to the already registered fastrun target.
- Review console output for parser errors, invalid calls, orphan nodes,
  penetration guards, and replay divergence.
- Record generation attempts/checksums, load/restart times, average FPS, worst
  frame, memory, active-ball peak, preview error, camera clearance, and
  solution coverage.

User-coordinated visible work:

- Ask the user for a desktop-occupation window before starting the release
  executable.
- Start only `builds/windows/PaintMountain.exe`; do not open the Godot editor.
- Inspect the real running build at 1280×720, 1600×900, and 1920×1080.
- At each resolution inspect the exact briefing, aiming, first terrain impact,
  each mechanism impact, three-child follow, result, and replay bookmarks.
- Record these visual gates:
  - briefing mountain bounds stay inside a 5% screen inset and occupy at least
    55% width and 45% height;
  - aiming mountain bounds occupy 55–82% width and 48–78% height, while cannon
    bounds occupy no more than 16% width and 24% height;
  - no bookmark reveals an open terrain edge, background through the mountain,
    camera clipping, or a mechanism collision response outside its visible
    primitive;
  - impact splash center is within 8 screen pixels of the visible ball/surface
    contact; each activation callout shows the correct localized name for
    `1.2 ± 0.1 s`; Burst shows one centered radial ripple and a mask delta;
    Splitter shows exactly three child balls within two physics ticks, each
    moving toward its assigned route; Bumper's visible arrow and outgoing X/Z
    velocity have dot product at least `0.95`;
  - shader evidence records no emission write, dry roughness `0.88 ± 0.01`,
    paint roughness `0.24 ± 0.01`, and the running capture shows a specular
    paint highlight without a glow halo;
  - the HUD matches the frozen edge hierarchy, central trajectory/mountain is
    unobscured, and the result panel remains at most 35% of viewport width.
- Replace all seven required screenshots with separate 1920×1080 running-game
  captures: `01_main_menu.png`, `02_stage_select.png`,
  `03_stage_briefing.png`, `04_aiming.png`,
  `05_projectile_and_paint_flow.png`, `06_stage_clear.png`, and
  `07_stage_failed.png`.
- Stop the task-owned game process after capture.

Close:

- Update `docs/test-checklist.md` only with gates actually observed.
- Update `.agents/Documentation.md`, `README.md`, design spec, and architecture
  with final measured behavior and known limitations.
- Set this plan to `status: done` only after every completion condition below
  passes.
- Keep `.agents/Plan.md` as historical and point it to this completed successor.

Accept:

- The release export starts through the existing fastrun target and all seven
  screenshots are from that running executable, not a mockup.
- The 1920×1080 Iris Xe running-build workload meets the frozen load, frame,
  memory, restart, and projectile-cap thresholds.
- The executor records pass/fail for every named bookmark and metric above;
  geometry/layout assertions and visual inspection remain separate evidence.
- Evidence explicitly records the tested Godot build and any remaining
  limitation.

Guard:

- If the user has not approved a visible capture window, leave the visual gates
  incomplete and the plan active; do not launch anyway and do not substitute
  synthetic screenshots.

## Validation and Rework Controls

The verified current-machine prerequisite is Godot
`4.7.1.stable.official.a13da4feb`. Its console executable currently exists at:

`D:\npjt\cardborne-platformer\.codex-runtime\godot-4.7.1-stable\Godot_v4.7.1-stable_win64_console.exe`

The path is an external execution prerequisite, not a project dependency and
must not be written into project settings or scripts. At the start of an
implementation session:

```powershell
$env:PAINT_MOUNTAIN_GODOT = (Resolve-Path 'D:\npjt\cardborne-platformer\.codex-runtime\godot-4.7.1-stable\Godot_v4.7.1-stable_win64_console.exe').Path
```

An executor may use this headless parser command as a fast precheck:

```powershell
& $env:PAINT_MOUNTAIN_GODOT --headless --path . --editor --quit
```

After every script, scene, resource, shader, or project-setting change, the
required check is:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\verify.ps1 -GodotPath $env:PAINT_MOUNTAIN_GODOT
```

After Task 09 creates the test entry point:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\test.ps1 -GodotPath $env:PAINT_MOUNTAIN_GODOT
```

Release export:

```powershell
& $env:PAINT_MOUNTAIN_GODOT --headless --path . --export-release 'Windows Desktop' 'builds\windows\PaintMountain.exe'
```

Production-style start is intentionally deferred to the coordinated visual gate.
The already registered fastrun command is equivalent to:

```powershell
& '.\builds\windows\PaintMountain.exe'
```

Documentation-only checks:

```powershell
git diff --check
git status --short
```

The plan-readiness review must find no unresolved design placeholder or
executor-owned product choice.

Each task remains in progress until its own acceptance and guard checks pass,
then receives one scoped commit. A failure before commit is corrected within
that task's owned files. A regression discovered after a task commit is fixed
with a new scoped follow-up commit; never reset, clean, or revert unrelated user
work. Store long test logs and measurement JSON under
`.agents/evidence/core-interaction-redesign/`; only final summarized evidence is
linked from `docs/test-checklist.md` and `.agents/Documentation.md`.

## Predetermined Contingencies and Change Control

These are execution branches, not invitations to redesign.

| Failure | Required response |
| --- | --- |
| A base seed does not pass generation in 32 attempts | Run the pinned fallback seed once. If it fails, correct the generator or validation implementation against Section 5.2. Do not add an authored layout. |
| Render and collision samples differ | Stop the milestone and make both factories consume the same `GeneratedStageLayout.heights`; never compensate with offsets in gameplay. |
| A projectile triggers `terrain_penetration_guard` on an intended solution | First verify collision layers and shape CCD, then heightmap scale/data order, then contact reporting. The task cannot pass while the guard occurs; do not enlarge paint to hide it. |
| Preview error exceeds `2.0 m` | Align predictor integration order, projectile radius, launch origin, gravity, collision mask, and fixed tick with runtime in that order. Do not add an aim-specific correction offset. |
| Mechanism preview and physical strike disagree | Remove selection/trigger geometry from the preview mask and query only the physical body. Selection remains a briefing-only ray layer. |
| Paint appears without score or score appears without paint | Reject the deposit and fix eligible-mask gating/texture binding. Do not add a HUD explanation for contradictory state. |
| Deterministic solution search cannot clear a target | Treat it as a gameplay defect. Verify contact and settlement first, then route-role placement, then intended-route eligibility. The fixed targets, shot limits, payload conservation, and mechanism values remain unchanged. |
| Performance falls below 60 FPS average or worst frame exceeds 33.3 ms on the established Iris Xe workload | First batch paint texture uploads to at most one per physics tick; then cache height/normal lookups for stamp bounds; then reuse predictor arrays and pooled VFX. Geometry resolution, mask resolution, and gameplay values stay fixed. |
| Camera clearance test fails | Clamp desired camera position along the terrain normal before smoothing. Do not hide the failure with near-clip changes or by shrinking the mountain. |
| UI clips at a supported resolution | Correct container size flags, anchors, wrapping, or minimum size. Do not reduce body text below 16 px or remove required controls. |
| Replay diverges after deterministic action playback | Trace accepted seed/checksum, fixed tick, action ordering, contact ordering, and settlement ordering in that order. Completion remains blocked while `0.5 m / 0.1 percentage-point` tolerance or event order fails; transform-sample playback requires a separate contract revision. |
| The user declines or postpones a visible final check | Complete headless gates, leave running-build screenshots and visual QA unchecked, keep this plan active, and stop without launching a GUI. |
| The configured Godot executable is absent | Stop before implementation; ask the owner for a Godot 4.7.1 console path. Do not download or copy an engine binary into the repository. |

## Completion and Stop Conditions

The redesign is complete only when all of the following are true:

- active docs describe the implemented manual-aim, physical-contact design;
- one generated layout feeds render, collision, paint, placement, replay, and
  agent height observations;
- the mountain is a closed, lit 3D render shell and all intended top/edge shots
  register real contacts without penetration guards;
- deterministic route metrics prove `0`, `2`, and `2/4/4` reversal progression;
- all mechanisms are visible solid bodies and their effects follow the frozen
  contact/tuning contract;
- persistent visual paint and coverage cannot disagree;
- the player independently controls yaw, elevation, and power;
- preview includes the exact first-collision/bounds endpoint, never post-impact
  behavior, and stays within `2.0 m` of measured contact;
- camera clearance, shot causality, replay isolation, reset, save migration,
  projectile cap, and settlement pass;
- the Korean-first interface passes structure and visual checks at all three
  supported resolutions, passes the frozen layout metrics, and passes the named
  reference-comparison bookmarks;
- deterministic solutions clear all three fixed targets while Stage 3's safe
  route alone fails;
- obsolete sandbox, auto-solver, duplicate terrain factory, and code-built UI
  styling are removed;
- headless tests, smoke verification, and Windows export pass;
- the established 1920×1080 Iris Xe workload loads within 3 seconds, averages
  at least 60 FPS, has no frame over 33.3 ms, uses at most 128 MiB static
  memory, restarts within 50 ms, and never exceeds eight active balls;
- after explicit user coordination, the release executable is visually
  inspected and all seven separate screenshots are regenerated;
- final docs contain measured evidence and known limitations; and
- `git diff --check` is clean and task-owned commits contain no unrelated user
  changes.

Stop immediately and report rather than widening scope when completion would
require a new dependency, new asset, new stage/mechanism, target reduction,
shot-count increase, source-brief change, destructive operation, or an
unapproved visible application launch.

## Progress

This checklist is the single canonical progress source for the redesign:

- [x] Task 00 — Reset documentation to the audited baseline.
- [x] Task 01 — Introduce typed contracts and the terrain owner.
- [ ] Task 02 — Replace authored topology with the frozen generator.
- [ ] Task 03 — Replace terrain mesh and collision.
- [ ] Task 04 — Make physics contact authoritative and unify paint.
- [ ] Task 05 — Convert mechanisms to physical bodies.
- [ ] Task 06 — Replace auto-targeting with manual aim and full preview.
- [ ] Task 07 — Add shot causality, safe camera, and isolated replay.
- [ ] Task 08 — Rebuild the Korean-first interface.
- [ ] Task 09 — Retire false fixtures and build one truthful verification path.
- [ ] Task 10 — Complete production evidence and documentation closeout.

## Next Steps

Begin Task 02. Do not implement any later task until its predecessor's
acceptance and regression guards pass.
