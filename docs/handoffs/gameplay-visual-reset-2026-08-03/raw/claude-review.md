# Paint Mountain — Correction Guide

**Read-only design and architecture review.** No repository file was modified; Godot was not launched; no solver or broad suite was run. All claims are labelled **[verified]** (read directly from a repository file), **[screenshot]** (observed in the two supplied PNGs), or **[inference]** (reasoned consequence, not directly proven).

Baseline reviewed: `15bac6405e79767df55552d0113dd906fb2a6c94` (`master`).

---

## 0. Evidence caveats you must carry forward

Three things constrain how far this review can go, and an ExecPlan must not paper over them.

1. **`visuals/02-current-build.png` is a pre-fire aiming frame.** Shots read `남은 탄 4` (all four remaining) and coverage reads `0`. **It therefore contains no evidence at all about paint appearance.** The handoff's claim that "there is no convincing thick, continuous paint route in this frame" is literally true but carries no information. Every paint-behaviour finding below rests on code reading plus the recorded balance numbers in `.agents/Documentation.md`, not on this image. **A new capture taken mid-roll and post-settle is a prerequisite for slice 1's gate.**
2. **The capture's bottom-centre coverage widget does not obviously match `scenes/ui/hud/coverage_meter.tscn` at baseline** (which renders `현재 %.1f%% / 목표 %.1f%%` right-aligned *below* the bar, per `translations/ui.csv:37`). The capture may predate the baseline. Re-capture at the baseline commit before acting on HUD pixel details.
3. **The most load-bearing single piece of evidence in this repository is not a screenshot or a test.** It is `.agents/Documentation.md`, "Task 09 is stopped at its locked balance-contract gate": *best isolated Burst `2.689%`, best Splitter `1.293%`, `0%` for each of eight exact Bumper strikes, five/six-shot sequences reaching `4.533% / 3.443%` against `27% / 70%` targets, First Descent's best single shot `5.335%`.* **[verified]** That is a ~20× shortfall, and it is the number that proves the paint model and the terrain topology are both wrong — not merely unpolished.

---

## 1. Correct game model

1. **The player controls three numbers and one button.** Yaw (`±28°`), elevation (`18°–68°`), power (`0–100%` → `32–72 m/s`), then Fire. **[verified: `src/cannon/cannon_controller.gd:10-14`, `src/projectile/projectile_data.gd:13-14`]** There is no in-flight steering, no target-click solver, no aim assist beyond the preview.
2. **The preview ends at the first predicted collision and nowhere further.** It shows the ballistic arc and an impact marker; it MUST NOT show post-impact route, bounces, splits, or mechanism activations. That route *is* the puzzle answer.
3. **What is simulated:** one `RigidBody3D` per ball at a fixed 60 Hz with CCD, gravity, bounce, friction, rolling, sliding, angular motion, damping, bounds, lifetime, and rest detection. Determinism: identical (stage seed, yaw, elevation, power) MUST reproduce an identical painted mask.
4. **What is painted — the newest correction, which supersedes everything else:** while a ball is in valid contact with an eligible target surface, it paints **the entire swept area of its contact footprint**, continuously, for the whole contact path, until it settles, leaves the target, or is removed. **Paint never runs out.** Overlap counts once. Splitter children obey the identical rule.
5. **Stale assumption being deleted, explicitly:** `remaining_payload`, `initial_payload = 520`, `deposit_rate = 32`, payload-scaled trail width (`lerpf(0.48, 1.0, payload_ratio)`), the `&"empty_payload"` stop reason, and the `30% child payload / 10% split loss` economy. **[verified: `src/projectile/paint_projectile.gd:15,100-101,230-231`, `src/projectile/projectile_data.gd:22-25`, `resources/mechanisms/splitter_node.tres`]** These are superseded product requirements, not a refactor preference. They must be removed, not renamed.
6. **Stale assumption #2:** paint as a *quantity in units* converted to alpha (`amount / paint_units_per_full_alpha`). **[verified: `src/paint/paint_system.gd:275`]** Paint has no quantity. It has a **footprint radius** and an **opacity profile**.
7. **Stale assumption #3:** discrete stamps gated by `TRAIL_MINIMUM_TRAVEL = 0.8 m` or `TRAIL_MAXIMUM_INTERVAL = 0.12 s`. **[verified: `src/projectile/paint_projectile.gd:11-12,221-238`]** Replaced by a per-physics-tick **swept capsule** between the previous and current valid contact.
8. **What makes a stage hard:** route *topology* — corridor width, branch count, meaningful uphill reversals, the vertical distance between a high-value entry shelf and the forgiving low route, and how much of the board a single traversal can reach. Not noise, not camera obstruction, not narrower coverage tolerance.
9. **Coverage is the union of painted eligible pixels over total eligible pixels**, from one authoritative 512×512 mask that also drives the terrain shader. A second coverage representation stays prohibited.
10. **The eligible surface is the designed play surface, not the whole landmass.** This is the single most important product clarification in this document and is developed in §4.6. Today the denominator includes back slopes and near-vertical canyon walls the ball can never occupy. **[verified: `src/stage_generation/seeded_stage_generator.gd:415-421`]**
11. **The target is a thick, bright, low-poly puzzle board shaped like a mountain**, with visible shell thickness, readable terraces and chutes, and a silhouette that reads as a designed massif from the aiming camera.
12. **The cannon is small, foreground, stationary, and never competes with the target for attention.** Korean is the default UI language; English is a settings toggle.

---

## 2. Evidence-backed diagnosis

### 2.1 What the two images actually show

| Dimension | Target reference | Current build | Delta |
|---|---|---|---|
| Mountain apex, % from top edge | ~8% | ~12% | **acceptable** |
| Mountain base line, % from top edge | ~74% | ~66% | slightly low |
| Featureless flat ground | ~0% (faceted rock plateau) | **~34% of frame** | **fails** |
| Silhouette local maxima (ridge count) | 6–8, layered at 3 depths | **2, one smooth arc** | **fails** |
| Lit-vs-shaded face separation | strong, plane-by-plane | **near zero** | **fails** |
| Visible shell/board thickness | reads as a thick object | **none visible** | **fails** |
| Cannon bounding box, % of frame area | ~3.2% | ~4.1% | **acceptable** |
| Cannon readability | silver/white body, blue accent, visible pivot | **near-black silhouette** | **fails** |
| Route legibility (shelves, chutes, branches) | immediate | **absent** | **fails** |
| Mechanisms | 3, large, distinct, labelled on route nodes | none in this stage | untested here |
| Trajectory dots | small, uniform, occluded by terrain | **large, size-varying, drawn through the ridge** | **fails** |
| Type hierarchy | small grey label + large value | **single uniform 18 px string** | **fails** |

**This is the most important correction to the handoff's own diagnosis: the camera framing is not the primary failure.** I measured the current aiming camera analytically and it lands close to the reference. `aiming_camera_position = (5, 3.2, 18)`, `aiming_camera_target = (0, 18, -102)`, `fov = 50` **[verified: `resources/stages/first_descent.tres`, `scenes/gameplay/gameplay.tscn`]** gives a camera pitch of `atan(14.8/120) ≈ 7.0°`, a peak elevation angle of `atan(66.8/150) ≈ 24°` → apex at ~16% from the top edge, and a near-terrain-edge angle of `atan(-5.2/70) ≈ -4.3°` → base at ~73%. **[verified by computation]** Those numbers are already inside a reference-like envelope.

**Do not spend a slice re-aiming the camera.** The mountain reads as a wall because of *what it is*, not *where it is seen from*.

### 2.2 Symptom → code, with the mechanism named

**A. "Broad gray wall or mound."** The generator is mass-first despite taking route inputs.
- The massif is 3–5 elliptical quadratic lobes combined by `_smooth_max`, producing one smooth dome. **[verified: `seeded_stage_generator.gd:125-168`]**
- Terracing is `terraced = round(h/4)*4; h = lerp(h, terraced, 0.35)` — a maximum deviation of 2 m applied at 35% strength, i.e. **steps of ≤ 0.7 m**. At 150 m with a 50° FOV that is under 3 screen pixels. **[verified: `seeded_stage_generator.gd:170-171`; screen size by computation]** The stepped depth the reference is built on does not exist.
- `noise_amplitude` is 1.2–2.0 m **[verified: profiles]** — also sub-pixel at gameplay distance, so it contributes surface *noise* without contributing *form*.
- Routes are then **carved into** that dome: `influence = 1` inside `width/2`, falling to 0 at `width`. For First Descent (`width = 28`), the corridor floor at mid-route sits ≈ 44 m while the surrounding lobe mass is ≈ 72 m — a **28 m drop cut over a 14 m transition, i.e. ~63° canyon walls**. **[verified: `seeded_stage_generator.gd:173-186` + profile values; slope by computation]**

The result is exactly what is on screen: a smooth dome with deep slots hidden inside it. From a near-horizontal camera you see the dome silhouette; the slots are invisible.

**B. "Weak route readability / no shelves."** The route validator checks only the **spine**: max slope 58°, p95 50°, net descent ≥ 30 m, reversal count. **[verified: `seeded_stage_generator.gd:7-8,249-299`]** Nothing validates corridor wall slope, terrace count, landing area, silhouette complexity, or visibility from the aiming camera. A layout that is a smooth dome with hidden slots passes every gate.

**C. "Mechanisms are tiny or ambiguous."** `MechanismPlacementGenerator._projected_horizontal_pixels()` computes horizontal pixels using the **vertical** half-FOV: `diameter / (2*tan(25°)*depth) * 1280`. **[verified: `mechanism_placement_generator.gd:137-147`]** Godot `Camera3D` defaults to `KEEP_HEIGHT`, so `fov` is vertical; the correct horizontal term is `tan(25°) * 16/9 = 0.829`, not `0.466`. **The gate overestimates projected width by 1.78×**, so its "≥ 18 px" acceptance is really ≈ 10 px at 1280×720. **[inference from verified code]** A 4.2 m Burst node at 130 m projects ≈ 25 px wide — borderline, and the gate cannot catch worse.

**D. "The flat foreground consumes depth."** A 380×380 m `PlaneMesh` sits at `y = -2.55`, `z = -92`. **[verified: `scenes/gameplay/gameplay.tscn`]** It fills the bottom ~34% of the frame with a single flat khaki value and its edge cuts the mountain's base. Simultaneously, the terrain shell base is `DEFAULT_BASE_Y = -12` under a terrain centred at `y = -2` **[verified: `terrain_geometry_factory.gd:4`, `first_descent.tres`]**, so the shell's bottom is at world `y = -14` while the ground top is `y = -2.55`. **Only ~0.55 m of the closed shell is ever above the ground plane.** The thickness the architecture correctly builds is buried. **[verified by computation]**

**E. "The image is flat / no plane separation."** `ambient_light_energy = 0.68` against `light_energy = 0.88`, and the shader's dry-rock term is `mix(shadow_tint, rock, 0.35 + 0.65*upwardness)` — a total albedo luminance range of ~0.23 between a vertical face and a horizontal one. **[verified: `scenes/gameplay/gameplay.tscn`, `src/paint/terrain_paint.gdshader:32`]** With ambient nearly matching key light, faceted geometry produces almost no value separation, so even correct terraces would not read.

**F. "The dotted arc dominates and draws through the ridge."** Trajectory dots are 3D spheres of fixed 0.52 m diameter with `no_depth_test = true`. **[verified: `src/cannon/trajectory_preview.gd:120-134,175`]** Near dots render large, far dots tiny, and the whole arc plus the impact ring draw over terrain. The source brief requires the impact marker only "when it is not hidden by terrain" — `no_depth_test` violates that and leaks route information.

**G. Paint per shot is ~20× too small. Three independent causes, all verified.**

*Cause 1 — alpha starvation.* A trail stamp fires every 0.8 m of travel with `amount = max(1.0, 32 × elapsed)`. At 30 m/s, `elapsed ≈ 0.033 s` → `amount ≈ 1.07`, and `alpha = 1.07 / 22 × 1.0 = 0.049` against a `painted_threshold` of `0.18`. **[verified: `paint_projectile.gd:230-232`, `paint_system.gd:275,288`, `default_paint_deposit_tuning.tres`]** With `radial_weight = 1 − 0.7·(d/r)²`, integrating the overlapping stamps gives an accumulated centreline alpha of ≈ 0.36 (crosses threshold) but only ≈ 0.17 at 3 m off-centre (**does not cross**). **[computed]** So the *effective painted band is ≈ 5.8 m, not the nominal 8 m* — a 27% area loss — the leading edge of the trail lags the ball by ~3 m, and the band width varies uncontrollably with speed.

*Cause 2 — the denominator is the whole landmass.* Eligibility is `height ≥ 4 m` and `normal.y ≥ cos(75°)`, minus mechanism and decoration footprints. **[verified: `seeded_stage_generator.gd:415-421`]** Measured eligible ratios are `0.423 / 0.447 / 0.415` **[verified: `.agents/Documentation.md`]** → ≈ 110,000 pixels ≈ **9,072 m² of XZ-projected surface** at 0.0824 m²/pixel. **[computed]** That includes the far side of the massif, the outer flanks, and **63° canyon walls a ball can never occupy** (75° is far too permissive a rollability threshold).

*Cause 3 — traversal paths are short.* Back-solving the recorded 5.335% single-shot best: 5.335% × 110,900 px × 0.0824 m² ≈ 487 m² painted; subtracting a ~250 m² impact splash leaves ≈ 240 m², which at a 5.8 m band is **≈ 40 m of rolling**. **[computed from verified figures]** The ball is being trapped by the canyon geometry, damped out (`friction 0.5`, `linear_damp 0.12`, stop at `1.4 m/s` for `1.0 s`), or bounced off the map long before it can traverse a route.

**H. Coverage targets were adjusted downward around the broken model.** `first_descent.target_coverage = 4.0`, `star_thresholds = (4, 7, 10)`. **[verified: `resources/stages/first_descent.tres`]** A 4% target with 4% one-star is not a design; it is a defect being accommodated. Stages 2 and 3 correctly refused to follow and ship with empty `reliable_solution` arrays and a truthfully failing `phase6_content_test.gd`. **That failing gate is the healthiest artefact in the repository — preserve its spirit.**

**I. Latent contact defect: only one contact per tick is ever reported.** `_integrate_forces` collects one primary contact **per collider:shape key** into `begun_contacts`, then reduces the whole array to a single `primary` and emits only that. **[verified: `paint_projectile.gd:143-173`]** `GimmickBase._on_projectile_contact_reported` filters on `contact.collider == _mechanism_body` **[verified: `gimmick_base.gd:153-155`]**, so **on any tick where the ball touches both a mechanism and the terrain and the terrain impulse sorts higher, the mechanism never activates.** **[inference from verified code]** This is a plausible contributor to the "0% for eight exact Bumper strikes" result and must be fixed regardless.

**J. Decorations are non-solid but do subtract from the denominator.** `EnvironmentDressing` instantiates GLB meshes with no `StaticBody3D` **[verified: `src/terrain/environment_dressing.gd:26-41`]**, yet `_exclude_footprints` clears eligible-mask circles beneath each one **[verified: `seeded_stage_generator.gd:426-430`]**. A ball rolls straight through a tree over pixels that can never count. The summit flag is neither solid nor excluded.

**K. The HUD is frozen to 1280×720 with no anchors.** Every HUD component uses `layout_mode = 0` with absolute offsets **[verified: `scenes/ui/hud/*.tscn`]**, and `project.godot` sets `window/stretch/mode="canvas_items"` but never sets `window/stretch/aspect` **[verified]**, so the engine default applies and the layout only scales uniformly. `AimControls` and `CoverageMeter` are `PanelContainer`s whose single child is a bare `Control` with zero minimum size, so each panel collapses to its `custom_minimum_size` and its absolutely-positioned children float inside — the mechanism behind the "awkward proportions." **[verified + inference]**

---

## 3. Procedural mountain design

### 3.1 Representation decision

**KEEP the heightfield + closed shell.** **Do not replace it.** It satisfies `HeightMapShape3D` collision, makes the world-XZ paint mask exact, and matches the explicit non-goals (no caves, no overhangs). `TerrainGeometryFactory` **[verified: `src/terrain/terrain_geometry_factory.gd`]** already produces flat-shaded per-triangle normals, a closed skirt + bottom, and a matching collider from one layout — that is the correct architecture and the reference's look is achievable inside it.

**REPLACE the interior of `SeededStageGenerator`.** The failure is the height *synthesis*, not the representation.

### 3.2 The route graph is the primary artefact

Promote `StageRouteProfile` from "a height pattern hint" to a real graph contract. Two new typed Resources under `src/stage_generation/`:

```gdscript
class_name RouteNodeProfile extends Resource
enum Kind { ENTRY_SHELF, LANDING, TERRACE, BRANCH, MERGE, BASIN, REVERSAL_CREST, EXIT }
@export var id: StringName
@export var kind: Kind
@export var local_xz: Vector2                # nominal; seeded jitter applies
@export var elevation: float                 # metres above terrain base
@export var pad_radius: float = 0.0          # >0 => flat landing pad, slope <= 6 deg
@export var jitter_xz: Vector2 = Vector2(3.0, 3.0)
@export var jitter_elevation: float = 1.5

class_name RouteEdgeProfile extends Resource
enum Kind { RAMP, CHUTE, TERRACE_RUN, REVERSAL }
@export var from_id: StringName
@export var to_id: StringName
@export var kind: Kind
@export var width: float                     # full corridor width in metres
@export var bank_height: float = 4.0         # rise at the corridor lip
@export var lateral_bend: Vector2 = Vector2(-6.0, 6.0)   # seeded range
@export var blend_run: float = 8.0           # corridor lip -> massif transition
```

`GeneratedStageLayout` keeps `heights`, `eligible_mask`, checksums, mechanism/decoration placements, and gains `route_nodes: Array[Vector3]`, `route_edges: PackedInt32Array` (pairs), `route_edge_widths`, `route_edge_kinds`, `terrace_landings: Array[Vector3]`. **Preserve `GeneratedStageLayout` as the single accepted immutable layout.** Every downstream consumer keeps working.

### 3.3 Height synthesis pipeline (replaces `_generate_lobes` + `_synthesize_height`)

```
1. RESOLVE GRAPH
   Apply seeded jitter to node XZ and elevation. Resample each edge into
   N = ceil(length / 2.0) polyline samples with a Catmull-Rom elevation spline
   and a sin(pi*t) lateral bend.

2. MASSIF FIELD  (replaces elliptical lobes)
   For each cell (x,z):
     d, e, t = nearest edge sample, its edge, its parameter
     floor   = elevation_along(e, t)
     shoulder_t = clamp((d - e.width*0.5) / shoulder_run, 0, 1)
     mass    = max over all edges of ( floor_e + shoulder_height * pow(shoulder_t, 0.7) )
   The massif now GROWS OUT OF the graph instead of the graph being cut into a dome.
   shoulder_height 16..26 m, shoulder_run 18..30 m  ->  flank slope ~ 35-42 deg.

3. OUTER FALLOFF
   Beyond hull(graph) + shoulder_run + 10 m, fall linearly to 0 over outer_run
   (28..40 m). Keep the existing edge-zero requirement (12 m band, heights == 0).

4. TERRACE QUANTISATION  (mass only, BEFORE corridor carving)
   terraced = round(mass / terrace_step) * terrace_step
   mass     = lerp(mass, terraced, terrace_blend)
   terrace_step 3.5..4.5 m,  terrace_blend 0.85..0.95   <-- currently 4.0 / 0.35
   With a 2.5 m cell this produces one-cell risers at ~55-61 deg and flat landings
   between them. THIS is the reference's stepped depth.

5. CORRIDOR CARVE
   half   = e.width * 0.5
   bank   = e.bank_height * pow(clamp((d - 0.7*half) / (0.3*half), 0, 1), 2)
   target = min over influencing edges of (floor_e + bank)          # merges form valleys
   infl   = max over influencing edges of (1 - smoothstep(half, half + e.blend_run, d))
   height = lerp(mass, target, infl)
   Because the massif adjacent to a corridor is only `shoulder_height * small`
   above it, the corridor lip is a 4 m bank, NOT a 28 m cliff.

6. PADS
   For every node with pad_radius > 0, flatten to node.elevation with a
   smoothstep(0.85*r, r) blend. Assert realised slope <= 6 deg over the pad.

7. MICRO-RELIEF
   Value-cubic noise, amplitude <= 0.6 m, applied only where infl < 0.15,
   so it never perturbs a rolling corridor.
```

### 3.4 Stage complexity budgets (tuning baselines, not constants)

| | Stage 1 First Descent | Stage 2 Burst Basin | Stage 3 Split Ridge |
|---|---|---|---|
| Nodes | 5–6 | 7–8 | 9–12 |
| Edges | 4–5 | 7–9 | 11–14 |
| Branch / merge nodes | 0 / 0 | 1 / 1 | 2 / 1 |
| Reversal edges | 0 | 1 | 2 |
| Corridor width | 22–28 m | 16–22 m | 11–16 m |
| Total graph path length | 110–140 m | 140–180 m | 180–240 m |
| Net drop entry→exit | 45–60 m | 55–70 m | 65–85 m |
| Terrace step | 3.5 m | 4.0 m | 4.5 m |
| Shoulder height / run | 16 / 28 m | 20 / 24 m | 24 / 20 m |
| Entry shelf pad radius | ≥ 16 m | ≥ 12 m | ≥ 10 m |
| Mechanism shelf pads | — | 1 × ≥ 9 m | 2 × ≥ 8 m |
| Reversal rise | — | 3.5–5.0 m | 4.0–6.0 m |
| Peak height above base | 68–78 m | 76–88 m | 84–98 m |
| Target eligible ratio | 0.14–0.20 | 0.15–0.21 | 0.16–0.22 |

Keep `cell_count = (72, 48)` over `local_bounds = Rect2(-90,-60,180,120)` (2.5 m square cells, 6,912 top triangles). It is well inside the 50k-triangle budget and the square-cell assertion in `TerrainGeometryFactory` depends on it.

### 3.5 Rejection / validation metrics (replaces `_validate_routes`)

`SeededStageGenerator` MUST reject a candidate unless **all** hold. Every value goes into `layout.metrics` so a rejection is diagnosable.

| Metric | Accept range | Why |
|---|---|---|
| Realised corridor centreline slope: mean | 12–26° | `tan(26°) ≈ 0.49 ≈ friction 0.5` → near-terminal rolling, not a luge run |
| Realised corridor centreline slope: p95 / max | ≤ 32° / ≤ 40° | Currently 50° / 58° — uncontrollable **[verified: `seeded_stage_generator.gd:7-8`]** |
| Corridor lip slope (0.5w → 0.5w + blend_run) | ≤ 34° | Prevents the 63° canyon walls |
| Terrace landings ≥ 40 m² with slope ≤ 8° | ≥ 6 / 9 / 12 (S1/S2/S3) | Stepped depth actually exists |
| Terrace riser projected height, aiming camera | ≥ 6 px @ 1280×720 | Steps are *visible*, not just present |
| Silhouette local maxima from aiming bookmark | ≥ 4, each ≥ 3% frame-height prominence, ≥ 6% frame-width apart | Kills the smooth-arc "wall" |
| Route centreline samples visible (ray-clear) from aiming bookmark | ≥ 85% | The player can read the route they are aiming at |
| Branch divergence at BRANCH node | ≥ 35°, centrelines ≥ 1.5·mean-width apart within 25 m | The choice is legible |
| Reversal climbability | simulated point mass from the previous node arrives with `v ≥ sqrt(2·g·rise·1.6)` | A reversal is a choice, not a wall |
| Eligible ratio after exclusions | per table above | Coverage means something |
| **Coverage feasibility** | `(max_shots · expected_path · band_width + mechanism_area) ≥ 1.25 × target × eligible_area` | **A stage can never ship unclearable** |
| Edge heights = 0 within 12 m band | unchanged | Shell closes cleanly |
| Skirt visible height at near edge | ≥ 8 m above foreground | Board thickness reads |

Keep the existing determinism structure verbatim: 32 derived attempt seeds by `ATTEMPT_STRIDE`, then one pinned `fallback_seed`, then fail closed with `push_error`. **[verified: `seeded_stage_generator.gd:17-36`]** Keep `_height_checksum` and `_byte_checksum` — replay and tests depend on them.

### 3.6 Why this stops producing a wall

- The dome is gone: mass is generated *from* the graph, so there is no 28 m mass-to-corridor differential to cut through.
- Terrace steps move from ≤ 0.7 m to 3.0–4.3 m — from sub-pixel to 12–18 screen pixels at 130 m.
- Flanks at 35–42° with one-cell risers give the faceted staircase silhouette; the silhouette metric enforces ≥ 4 ridge maxima.
- Corridors at 12–26° with 4 m banks read as *channels on a face*, exactly like the reference's blue paint routes, instead of slots hidden inside a dome.
- The visibility metric guarantees the route the player is asked to read is actually visible from where they aim.

---

## 4. Continuous surface-paint algorithm

### 4.1 The runtime command

Add `src/paint/surface_paint_sweep.gd` — an immutable typed `RefCounted`, sibling to the retained `PaintDepositRequest`:

```gdscript
class_name SurfacePaintSweep extends RefCounted
var projectile_id: int          # get_instance_id()
var spawn_index: int            # monotonic, for deterministic ordering
var physics_tick: int
var sequence: int               # per-projectile monotonic
var from_point: Vector3         # previous valid surface contact, world
var to_point: Vector3           # current  valid surface contact, world
var from_normal: Vector3
var to_normal: Vector3
var radius: float               # paint footprint radius, constant per projectile
var collider_id: int            # paintable-surface body identity, must match both ends
var continuous: bool            # false => paint a disc at to_point only
```

**MUST** be constructed inside `PaintProjectile._integrate_forces`, from `PhysicsDirectBodyState3D` contact data, in the same tick both endpoints exist. **AVOID** deriving it from `global_position` in `_physics_process` — that is a rendered-transform approximation and reintroduces fabricated coordinates.

### 4.2 Valid contact definition

A contact is a **valid paintable surface contact** iff:
1. `_terrain_surface.is_top_collider(contact.collider)` is true (skirt, bottom, ground plane, mechanism bodies, and decorations are **never** paintable), and
2. `contact.normal.dot(Vector3.UP) ≥ cos(78°)`, and
3. `contact.collider_instance_id` is recorded on the sweep.

Mechanisms are surfaces the ball *interacts with*, not surfaces it *paints*. Burst paints through its own authoritative deposit; that is the sanctioned exception.

### 4.3 Contact lifecycle and continuity rules

| Event | Sweep behaviour | Additional |
|---|---|---|
| Airborne (no valid contact) | **nothing emitted** | `ticks_since_contact++` |
| First valid contact of the ball's life | disc at `to_point` | IMPACT splash disc if `relative_normal_speed ≥ 8 m/s` |
| Sustained rolling/sliding | `continuous = true`, `from` = previous tick's contact | one sweep per tick per ball |
| Brief contact loss (chatter) | bridge if **all**: `ticks_since_contact ≤ 3`, same `collider_id`, `‖to − from‖ ≤ 2.5 · radius` | closes visible chatter gaps |
| Real bounce (gap > 3 ticks, or chord > 2.5r, or different collider) | `continuous = false` → disc at `to_point` only | **never paints across an airborne arc** |
| High speed | unchanged | capsule sweep is gap-free while `2·radius > speed·dt`; at `r = 4 m` that holds to **480 m/s**, vs. a `72 m/s` launch cap **[computed]** |
| Steep slope | unchanged | handled by 3D distance-to-segment, not XZ distance |
| Splitter consumes parent | parent emits nothing further | children are airborne until their own first contact |
| Bumper impulse | ball becomes airborne | next contact is a fresh disc; bridging is refused (gap > 3 ticks) |
| Settle (`&"settled"`) | FINAL_PUDDLE disc at the rest contact, radius `1.45 · r` | no amount, no payload check |
| Out of bounds / lifetime / penetration guard | **no puddle** | record the reason in `ShotObservation` |

`RECONTACT_ABSENCE_TICKS = 2` and the existing `_contact_missing_ticks` debounce **[verified: `paint_projectile.gd:10,147-157`]** are the right primitive — reuse them, and set `MAX_BRIDGE_TICKS = 3`, `MAX_BRIDGE_DISTANCE_RATIO = 2.5`.

### 4.4 Rasterisation into the existing 512×512 mask

New `PaintSystem.apply_surface_sweep(sweep) -> Dictionary`. `PaintSystem` remains the **sole** owner of the mutable mask and coverage.

```
1. If not sweep.continuous: treat as a segment of zero length at to_point.
2. Bounding box: XZ AABB of the segment, grown by radius, clipped to the mask.
3. Candidate pass, row-major over the box:
     if eligible[i] < 128: continue
     s = surface_point[i]                       # PRECOMPUTED 3D array, see 4.5
     d = distance_point_to_segment_3d(s, from_point, to_point)
     if d > radius: continue
     candidate[i] = 1
4. Connected component (8-neighbour, existing algorithm) seeded from the pixels
   under from_point and to_point, restricted to the box.
   THIS is what prevents painting a shelf that is 4 m away in 3D but across a
   riser the ball never touched.
5. Write:
     alpha = 1.0                               for d <= 0.85 * radius
           = smoothstep(radius, 0.85*radius, d) * 0.5 + 0.5   for d in (0.85r, r]
     paint[i] = max(paint[i], alpha)            # idempotent, order-independent
     if crossed painted_threshold (0.50): painted_eligible_pixels += 1
6. Union the dirty rect. DO NOT upload the texture here.
```

**Why this maps correctly on steep slopes without gaps and without bleeding:** the radius test is performed in **3D against the reconstructed surface point**, so a 60° face is foreshortened in the mask exactly as much as its true area is foreshortened; and the connected-component constraint means a disconnected surface must be reachable through eligible pixels inside the same box before it can be painted. Both mechanisms already exist in `_connected_component` **[verified: `paint_system.gd:221-269`]** — they are being *retargeted* from a point to a segment, not invented.

**Determinism.** `max()` writes are order-independent, and a threshold crossing happens exactly once per pixel, so the final mask **and** the coverage count are independent of the order in which several balls' sweeps land in one tick. Sort sweeps by `(physics_tick, spawn_index, sequence)` anyway so `deposit_applied` event order is stable for replay and observation.

**Overlap counts once**, by construction of step 5.

### 4.5 Two mandatory performance changes

Both are prerequisites, not optimisations. At 8 balls × 60 Hz the current shapes are not viable.

1. **Precompute per-pixel surface geometry once in `_create_masks()`**: `_surface_y: PackedFloat32Array` (512², 1 MB), `_pixel_world_x` and `_pixel_world_z` (512 floats each). This removes a bilinear `height_at_local` from the inner loop. **[the current `_surface_position_at_pixel` does two lerps plus a bilinear sample per candidate pixel — `paint_system.gd:345-356`]**
2. **Stop allocating a full 512×512 `PackedByteArray` per deposit.** `_connected_component` allocates and fills 262 KB every call **[verified: `paint_system.gd:234-236`]**. At 480 sweeps/s that is ~126 MB/s of churn. Allocate one scratch buffer at configure time and clear only the bounding box.
3. **Batch texture upload.** `_upload_dirty_images` calls `Image.set_data` on the full buffer plus `ImageTexture.update` per deposit **[verified: `paint_system.gd:385-392`]**. Move it to `_process`, at most once per rendered frame, and only when the dirty rect is non-empty.

Per-tick cost after these changes: a 4 m radius sweep at 40 m/s spans a ~9.3 × 9.3 m box ≈ 1,080 pixels; 8 balls × 60 Hz ≈ 518k candidate tests/s at ~15 float ops each. **[computed]** Comfortable in GDScript.

### 4.6 The eligible surface — the other half of the fix

**This is a product decision, not a tuning knob.** Coverage must mean "you painted the puzzle board," not "you painted the landmass."

`_build_eligible_mask` MUST require **all** of:
1. **Rollable:** `normal.y ≥ cos(42°)` — replacing `cos(75°)` **[verified: `seeded_stage_generator.gd:419`]**. 75° admits 63° canyon walls and terrace risers that a ball can never occupy.
2. **Inside the designed play region:** XZ distance to the route graph ≤ `edge.width·0.5 + play_margin`, where `play_margin` is 12–18 m, **unioned** with terrace-landing polygons and node pads that the graph reaches.
3. Height ≥ 4 m above base, ≥ 2.5 m inside the bounds (both retained).
4. Not under a mechanism footprint.
5. **Decoration footprints are removed from the exclusion list.** See §5.5 — either decorations become solid, or they stop punching holes in the denominator. Do not keep both.

Expected effect: eligible ratio `0.42 → 0.14–0.22`; eligible area `9,072 m² → 3,000–4,800 m²`. **[computed]**

**Resulting coverage arithmetic** (the number that must be true before any implementation starts): an 8 m band over a 150 m traversal paints ≈ 1,200 m² ≈ **30% of a 4,000 m² eligible surface in one good shot.** Six such shots on distinct lanes plus a Burst (`π · 14² ≈ 616 m² ≈ 15%`) and a Splitter (three 0.78-width children) comfortably exceed 70% with headroom. Today one shot yields 5.3%. **[computed]**

### 4.7 Consequent stage rebalance

`first_descent.target_coverage = 4.0` with `star_thresholds = (4, 7, 10)` is an artefact of the broken model. Raising it is not "lowering a target to hide a defect" — it is restoring the brief's Stage 1 intent of "low target coverage" that a player "can clear without precision."

| Stage | Target | Shots | Stars |
|---|---|---|---|
| First Descent | **4 → 35%** | 4 | 35 / 50 / 65 |
| Burst Basin | **27 → 50%** | 5 | 50 / 62 / 74 |
| Split Ridge | **70%, unchanged** | 6 | 70 / 82 / 92 |

The generator's coverage-feasibility metric (§3.5) enforces these at build time, so `phase6_content_test.gd`'s solution requirement stops depending on a slow beam search to *discover* whether a stage is possible.

### 4.8 What survives, what dies

**SURVIVES — `PaintDepositRequest` as the radial/disc command.** It is the correct shape for IMPACT splash, BURST, and FINAL_PUDDLE, which are genuinely radial one-shot marks, not paths. Keep `source_kind`, `world_position`, `world_normal`, `radius`, `source_instance_id`, `physics_tick`, `sequence_number`. Keep `_connected_component`, `_surface_position_at_pixel`, `_surface_normal_at_pixel`, the coverage accounting, the shader binding, `terrain_surface_position/normal`, and `clear()`.

**DIES — every trace of a paint quantity.**

| Delete | File:line **[verified]** |
|---|---|
| `PaintDepositRequest.amount` + its `is_valid()` clause | `src/paint/paint_deposit_request.gd:23-25,79` |
| `PaintDepositTuning.paint_units_per_full_alpha`, `*_intensity` as amount multipliers | `src/paint/paint_deposit_tuning.gd:5-9` |
| `flow_amount_ratio`, `flow_decay`, `flow_radius_ratio`, `minimum_flow_alpha`, `allow_flow`, `maximum_flow_steps` | same file + `paint_deposit_request.gd:26-31` |
| `PaintSystem._apply_steepest_descent_flow()` entirely | `src/paint/paint_system.gd:298-342` |
| `ProjectileData.initial_payload`, `deposit_rate` | `src/projectile/projectile_data.gd:22,25` |
| `PaintProjectile.remaining_payload`, `accept_deposit_amount`, `_request_surface_trail`, `TRAIL_MINIMUM_TRAVEL`, `TRAIL_MAXIMUM_INTERVAL`, `_trail_elapsed`, `_last_trail_position`, `&"empty_payload"` | `src/projectile/paint_projectile.gd:11-12,15,23-24,100-101,184-185,221-238` |
| `ProjectileManager.spawn_projectile(payload_override)`, `resolve_paint_deposit` amount plumbing | `src/projectile/projectile_manager.gd:30-52,74-85` |
| `MechanismData.child_payload_ratio`, `burst_paint_amount`, `burst_maximum_flow_steps` | `src/mechanisms/mechanism_data.gd` + `resources/mechanisms/*.tres` |
| `SplitterNode` child payload computation | `src/mechanisms/splitter_node.gd:25,44` |
| `ShotObservation.{initial,current,consumed}_payload`, `record_payload`, dict keys | `src/stage/shot_observation.gd:14-16,66-70,103-105` |
| `StageController._settled_unconsumed_payload`, `_aggregate_remaining_payload` | `src/stage/stage_controller.gd:51,278,317,323,325,380-384` |
| `HUDController.update_payload`, `_last_payload`; `ObservationControls` payload bar + scene nodes; `hud.payload` CSV row | `src/ui/hud_controller.gd:42,60,88-90,190`, `src/ui/hud/observation_controls.gd:8-9,21-24`, `translations/ui.csv:36` |
| `DebugOverlay` payload readout | `src/debug/debug_overlay.gd:69-85` |
| `GameplayScene._process` payload aggregation + `_ready` payload seeding | `src/gameplay/gameplay_scene.gd:76,80-86` |
| `solution_search.gd` `remaining_payload` tie-break | `scripts/solution_search.gd:136-138,182,197,260-261` |

**RENAME (not compatibility-alias):** `ProjectileData.paint_stamp_radius → paint_footprint_radius` (default **4.0 m**, range 3.2–4.6). Justification for a footprint 7.7× the 0.52 m ball: the reference's own paint channels measure ~3.4% of the mountain width, i.e. 5–7 m on a 180 m board **[screenshot + computation]**, and 8 m projects to ~47 px at 1280×720 from the aiming bookmark **[computed]**. It is a declared stylisation constant, tied to a stated coverage budget — not an arbitrary inflation.

**Downhill flow: delete it.** The source brief marks it "optional." It costs a determinism surface, competes with the corridor route as a coverage source, and risks painting surfaces the ball never reached — explicitly prohibited. Burst instead paints a **geodesic disc**: `_connected_component` at `burst_radius = 14 m` from its own surface point, which is already terrain-aware and already implemented.

---

## 5. Geometry, collision, and contact contract

### 5.1 Render/collision derivation (preserve)

One accepted `GeneratedStageLayout` → `TerrainGeometryFactory.build()` → `{render_mesh, top_shape: HeightMapShape3D, skirt_shape: ConcavePolygonShape3D}` → `TerrainSurface` wires them onto `TerrainMesh`, `TerrainTopBody` (layer 1), `TerrainShellBody` (layer 1). **[verified: `src/terrain/terrain_geometry_factory.gd`, `src/terrain/terrain_surface.gd`]** **Keep all of it.** It is the single-source property the handoff asks to preserve and it works.

### 5.2 Parity diagnostics you do not yet have

The render mesh splits each cell along the `(x0,z1)–(x1,z0)` diagonal **[verified: `terrain_geometry_factory.gd:94-101`]**. `HeightMapShape3D` uses its own fixed triangulation. Vertex-height parity — which is what `terrain_geometry_test.gd` currently proves ("≤0.01 m heightmap parity") — **cannot detect a diagonal mismatch**, because vertices agree in both triangulations while cell interiors differ by up to half the cell's height variation.

**MUST add:** sample 4 interior points per cell across ≥ 200 deterministically-chosen cells; compare a downward `intersect_ray` against `TerrainTopBody` with a barycentric evaluation of the render mesh; assert `|Δy| ≤ 0.02 m`. If the diagonals differ, flip the factory's diagonal to match — do not "fix" it by smoothing.

### 5.3 Contact contract changes

1. **Emit one `contact_reported` per begun contact key, not one per tick.** Fixes the dropped-mechanism defect in §2.2-I. `StageController` and `GimmickBase` already filter by collider, so they need no change. `_primary_contact` stays, but it selects the primary *within a manifold*, not across colliders. **Owner: `src/projectile/paint_projectile.gd:143-173`.**
2. **Add `impulse_is_measured: bool` to `ProjectileContact`.** The code fabricates `impulse = normal · Δv_n · mass` when Jolt reports a zero-impulse speculative manifold **[verified: `paint_projectile.gd:162-166`]**. Keep the fallback; make it visible to diagnostics rather than indistinguishable.
3. **Add `surface_class: enum {TERRAIN_TOP, TERRAIN_SHELL, GROUND, MECHANISM, DECORATION, UNKNOWN}`** resolved once at contact construction. Painting keys off `TERRAIN_TOP` only. A test asserts `UNKNOWN` never occurs during a full reliable-solution run.
4. **Stop letting the penetration guard hide tunnelling.** `_penetration_ticks >= 2 → deactivate(&"terrain_penetration_guard")` **[verified: `paint_projectile.gd:85-92`]** silently deletes the ball. Keep the guard, but also increment `ShotObservation.penetration_guard_count` and **fail the test suite if it ever fires during a reliable-solution replay.** A silent guard converts a physics bug into a mysterious coverage loss.
5. **CCD stays as configured** (`continuous_cd = true`, `contact_monitor = true`, `max_contacts_reported = 8`) **[verified: `paint_projectile.gd:70-74`]**. Add an explicit high-speed test at the 72 m/s launch cap plus a 1.5× margin.

### 5.4 Shell thickness must become visible

Currently ~0.55 m of a 12 m shell clears the foreground plane (§2.2-D). Fix as a pair:
- **Delete the 380×380 m `PlaneMesh`/`BoxShape3D` foreground** and replace it with a faceted low-poly apron in the same visual language: a 200×140 m plate at `y ≈ -12`, flat-shaded, 40–70 triangles, with 6–10 scattered rock forms, so the foreground carries facets and shadow instead of one flat value.
- **Set the terrain shell base so 8–14 m of skirt stands above the apron** at the near edge, and give the skirt a distinct darker "cut rock" band in the shader (`paintable_surface == 0` already flags it — `terrain_geometry_factory.gd:188`). The board then reads as a thick object.

Acceptance: from the aiming bookmark, the skirt band occupies ≥ 2% of frame height across ≥ 60% of the mountain's screen width.

### 5.5 Decoration policy (pick one, not both)

**Recommended: decorations are non-solid and are NOT excluded from the eligible mask.** They are visual scale cues; a 3 m tree does not credibly stop a 1 m paintball. Delete `_exclude_footprints`' decoration loop **[verified: `seeded_stage_generator.gd:429-430`]** and `_decoration_footprint_radius`. Keep mechanism exclusions (mechanisms *are* solid). Add the summit flag to the same non-solid, non-excluded class. Assert in `decoration_placement_test.gd` that no decoration owns a `CollisionObject3D` and that no eligible pixel is cleared by one.

### 5.6 Mechanism geometry parity

`GimmickBase._ready` already asserts a `Visual` node, a `MechanismBody` on layer 3 (`4`), and a separate `SelectionBody` on layer 4 (`8`). **[verified: `gimmick_base.gd:24-39`]** Keep that contract and add a headless test that, for each mechanism scene, the union AABB of `MechanismBody`'s shapes covers ≥ 80% of the union AABB of `Visual`'s meshes in each axis, and exceeds neither by more than 15%. Today Burst's visual is a 1.3 m sphere with two 1.83 m torus rings on a 2.1 m pedestal while its body is a 1.05 m sphere plus a 1.8 m cylinder **[verified: `scenes/mechanisms/burst_node.tscn`]** — the rings are visually prominent and physically absent.

### 5.7 Impact and surface feedback

| Moment | Visual | Audio | Camera |
|---|---|---|---|
| First terrain impact | splash particles scaled by `clamp(v_n/32, 0.7, 1.5)` + an IMPACT paint disc | soft/hard impact by `v_n` threshold at 8 m/s | shake `clamp(v_n/80, 0.12, 0.42)` |
| Sustained rolling | continuous trail growing from the ball's contact point (no lag) + a small contact-point dust puff every ~0.4 s | looped rolling layer, gain by speed | **no shake** |
| Contact loss > 3 ticks | trail visibly stops at the departure point | rolling loop fades in 80 ms | — |
| Re-contact | new disc, then the trail resumes | soft impact | — |
| Mechanism strike | mechanism-specific burst + a 0.6 s name/icon pulse | per-mechanism cue | shake 0.32 |
| Settle | puddle disc + a short spread tween | — | — |

The rolling loop plus the trail's leading edge tracking the ball with **zero lag** is what makes "the ball is painting right now" legible. Today the trail's threshold crossing lags the ball by ~3 m **[computed, §2.2-G]**, which reads as disconnected stamps.

---

## 6. Camera, art direction, mechanisms, and HUD

### 6.1 Composition envelope (1920×1080; identical fractions at 1280×720 and 1600×900)

Measure on a real running-build capture, from the aiming bookmark, before firing.

| Metric | Accept | Current **[screenshot]** |
|---|---|---|
| Mountain apex, % from top edge | 6–18% | ~12% ✔ |
| Mountain/foreground boundary, % from top edge | 68–80% | ~66% ~ |
| Mountain silhouette width | ≥ 85% of frame width | ~100% ✔ |
| Sky area | ≤ 22% of frame | ~14% ✔ |
| **Featureless flat ground** | **≤ 8% of frame** | **~34% ✘** |
| **Silhouette local maxima** | **≥ 4** | **2 ✘** |
| **Lit-landing : shaded-riser median luminance** | **≥ 1.8 : 1** | **~1.15 : 1 ✘** |
| **Visible shell band** | **≥ 2% frame height over ≥ 60% of mountain width** | **~0 ✘** |
| Cannon bounding box | 2.5–5.0% of frame area | ~4.1% ✔ |
| Cannon height | 22–32% of frame height | ~33% ~ |
| Cannon horizontal centre | 24–38% from left | ~28% ✔ |
| Cannon overlaps mountain silhouette | yes | yes ✔ |

**Camera parameters (keep, do not rebuild):** perspective, `fov = 50` (envelope 46–54), camera 12–18 m behind and 3–6 m above the cannon base, pitch +5° to +9°, near-terrain-edge 65–85 m out, apex 145–175 m out, peak 68–98 m. `far = 460`. Retain `CameraDirector`'s 1.5 m clearance, line-of-sight correction, overhead fallback, and the 96 m split-framing latch **[verified: `src/camera/camera_director.gd:128-153,195-233`]**; they are correct and tested.

**One data defect to fix:** `burst_basin.tres` sets `aiming_camera_position = (-50, 100, -30)` — a 100 m-high bird's-eye that cannot place the cannon in the lower foreground. **[verified]** Stages 1 and 3 use `(5, 3.2, 18)`. Bring Stage 2 into the same envelope and add a `camera_safety_test.gd` assertion that **every** stage's aiming bookmark satisfies the composition envelope, so a copy-paste error cannot ship again.

### 6.2 Lighting and material

| Parameter | Set to | Currently **[verified]** |
|---|---|---|
| `DirectionalLight3D.light_energy` | 1.05–1.25 | 0.88 |
| `ambient_light_energy` | 0.28–0.40 | **0.68** |
| Sun elevation / azimuth | 34–42° / 30–50° off camera forward | −48° pitch, −28° yaw |
| Shadows | enabled, `directional_shadow_max_distance` 260 | ✔ keep |
| Rock albedo | `#C9CDD3` lit face | ✔ close |
| Shader dry-rock term | remove the `mix(shadow_tint, rock, 0.35+0.65*upwardness)` fake-shading; let real lighting and flat facets do the work; keep a subtle terrace-edge darkening | `terrain_paint.gdshader:32` |
| Paint core | `#0A5FFF`, `ROUGHNESS 0.16–0.22`, `SPECULAR 0.70–0.80` | 0.24 / 0.72 ~ |
| Paint edge | 6–10 px darker rim (the existing `dark_rim` term is right) | ✔ keep |
| Cannon body | `#8E959C` with `#1A63FF` accent bands, visible yaw/elevation pivots | **`#0B0F13`, near-black ✘** |
| Skirt band | 0.75× the top albedo, flat | present but buried |

The ambient/key ratio is the single highest-leverage art fix: at 0.68/0.88 the geometry cannot cast readable value structure no matter how well it is terraced.

### 6.3 Mechanisms

- **Fix `_projected_horizontal_pixels`** to `diameter / (2 · tan(fov_v/2) · aspect · depth) · viewport_width`. **[owner: `mechanism_placement_generator.gd:137-147`]**
- **Gates:** ≥ 26 px projected width at 1280×720 from the aiming bookmark; ≥ 40 px from briefing; ray-clear from both.
- **Sizes:** visual diameter **6.0–7.5 m**, height 5.0–6.0 m (Burst 4.2 m today, Splitter 5.0, Bumper 5.2 **[verified]**). At 130 m that is 31–39 px — comfortably legible, and 3.3–4.2% of the 180 m board, matching the reference ratio **[screenshot measurement]**.
- **Silhouettes:** Burst = sphere + double ring on a round pedestal (keep); Splitter = triangular prism with a visible directional outlet (keep, enlarge); Bumper = capsule with an explicit direction arrow whose length equals the impulse magnitude at a fixed scale. Palette white/grey/blue only.
- **Labels:** `Label3D` billboards visible in BRIEFING only. `GimmickBase._build_label` positions the label at `Vector3(0, -5, 0)` — **below** the device **[verified: `gimmick_base.gd:177`]**. The reference places labels below the device too, so keep it, but raise `font_size` to 30 and set `pixel_size` so the label renders 13–15 px tall at 1280×720 regardless of distance (`fixed_size = true` is already set).
- **Activation:** 0.6 s icon pulse + name chip, then it disappears. No persistent text over the mountain during flight — `GameplayScene._set_mechanism_labels_visible(false)` on `PROJECTILE_IN_FLIGHT` already does this **[verified: `gameplay_scene.gd:252`]**. Keep.

### 6.4 Trajectory preview

| Property | Set to | Currently **[verified: `trajectory_preview.gd`]** |
|---|---|---|
| Dot screen diameter | constant **5–7 px** at 1280×720 (scale by `distance / reference_distance`, as `_set_marker_scale` already does for markers) | fixed 0.52 m world → **6.7 px at 60 m, ~20 px at 20 m ✘** |
| Dot screen spacing | 14–20 px | fixed 2.2 m world ✘ |
| Max dots | 60 | 96 |
| Depth test | **ON** — the arc and impact ring must be occluded by terrain | `no_depth_test = true` ✘ (violates the brief and leaks route information) |
| Impact ring | screen-constant 26–34 px, aligned to the measured normal | ✔ aligned, but size varies |
| Bounds-exit cross | screen-constant 24–30 px, camera-facing | ✔ camera-facing |

### 6.5 HUD system — Korean-first

**Structural fixes first (these cause the "awkward proportions"):**
1. Set `display/window/stretch/aspect = "expand"` in `project.godot`.
2. Replace `layout_mode = 0` + absolute offsets in every `scenes/ui/hud/*.tscn` with anchors + a root `MarginContainer` of **24 px** on all edges.
3. Fix the `PanelContainer` → bare `Control` collapse in `AimControls` and `CoverageMeter`: the panel's single child must be a `MarginContainer` → `VBox/HBox` with real minimum sizes.

**Layout at 1280×720 logical (reference hierarchy, not pixel copy):**

| Region | Content | Type |
|---|---|---|
| Top-left | `스테이지 01` chip, 44 px tall; below it the mode chip (`조준`, dark, 36 px) | label 13 px / value 20 px |
| Top-centre | `목표 면적` + `35%` chip, 48 px tall | label 14 px `#67707E` / value **26 px** `#2585FF` |
| Top-right | `남은 탄` + `4` chip, 44 px | label 14 px / value 24 px |
| Bottom-left | aim card 320×128: `각도` + `34°` (30 px), divider, `파워` + `68%` (30 px) + a **10-segment power bar** | ± buttons demoted to 28×28 secondary at the card's right edge |
| Bottom-centre | coverage card 520×64: `칠한 면적` label, 340×12 bar with an 8 px radius and a target tick, value **26 px** right-aligned | |
| Bottom-right | `다시 시작` 96×112 secondary + `발사` 128×112 primary, 12 px gap | primary label 20 px |

Theme changes to `resources/ui/paint_mountain_theme.tres`: add `CaptionLabel` (13–14 px, `#67707E`, weight 600) and `ValueLabel` (24–30 px, `#17253A`, weight 700) variations. `default_font_size` stays 16 for body copy. **The current build renders label and value at one uniform 18 px** **[verified: `top_status_bar.tscn`]** — restoring the label/value contrast is what produces the reference's hierarchy, more than any size change.

**Korean/English rules:** Korean is default and must never be uppercase-transformed (uppercase styling applies to English only). Every chip must fit both locales at 1280×720, 1600×900, and 1920×1080 with **no ellipsis and no clipping** — extend `localization_ui_test.gd` to assert `Label.get_line_count() == 1` and `size.x ≤ parent.size.x - margins` for every HUD label in both locales at all three sizes. Delete the `hud.payload` row.

**Interaction (preserve — it is correct):** left-drag → yaw/elevation at `0.15 / −0.12 °/px` with viewport scaling; `A/D/W/S` fixed `0.5°` steps with 0.30 s delay / 0.08 s repeat; wheel `±1%` power, buttons `±2%`; `Space` or Fire; `R` restart; `Tab` briefing; `Esc` pause. **[verified: `src/input/aim_input_controller.gd`]** Fire stays disabled while `is_aim_valid()` is false, driven by `aim_validity_changed`. Restart returns to AIMING in < 1 s.

---

## 7. Architecture migration map

### 7.1 Preserve unchanged

`src/stage/stage_controller.gd` (sole state authority — remove only the payload members), `src/stage/stage_catalog.gd`, `src/stage/stage_data.gd`, `src/autoload/{game_state,save_system}.gd`, `src/app/app_root.gd`, `src/terrain/terrain_surface.gd`, `src/terrain/terrain_geometry.gd`, `src/camera/camera_director.gd`, `src/cannon/{cannon_ballistics,trajectory_predictor,trajectory_prediction}.gd`, `src/input/aim_input_controller.gd`, `src/mechanisms/gimmick_base.gd`, `src/agent/gameplay_agent_api.gd`, `src/replay/replay_presentation_controller.gd`, `src/effects/presentation_effects.gd`, `src/audio/audio_director.gd`, `scripts/verify.ps1`, `scripts/test.ps1`.

### 7.2 Revise

| Path | Change |
|---|---|
| `src/stage_generation/seeded_stage_generator.gd` | Replace `_generate_lobes` + `_synthesize_height` with §3.3. Replace `_validate_routes`/`_validate_shelves`/`_validate_branch_separation` with §3.5. Rewrite `_build_eligible_mask` per §4.6. Drop the decoration exclusion loop. Keep `generate()`'s attempt/fallback/fail-closed structure and both checksums verbatim. |
| `src/stage_generation/stage_route_profile.gd` | Becomes `RouteEdgeProfile`; new sibling `RouteNodeProfile`. |
| `src/stage_generation/stage_generation_profile.gd` | Drop `lobe_*`, `smooth_max_k`, `nominal_peak`. Add `nodes`, `edges`, `terrace_step`, `terrace_blend`, `shoulder_height`, `shoulder_run`, `outer_run`, `micro_relief_amplitude`, `play_margin`. Bump `profile_version` to 4 and make `is_valid()` reject 3. |
| `src/stage_generation/generated_stage_layout.gd` | Add `route_nodes`, `route_edges`, `route_edge_widths`, `route_edge_kinds`, `terrace_landings`. Replace `route_distance()`'s per-z scan with a nearest-point-on-edge query. |
| `src/stage_generation/mechanism_placement_generator.gd` | Fix the FOV math; raise gates to 26/40 px; place on graph nodes rather than an interpolated `shelf_t`. |
| `src/terrain/terrain_geometry_factory.gd` | Parameterise `base_y` from the profile so shell thickness is a design value; keep everything else. |
| `src/projectile/paint_projectile.gd` | Emit one `contact_reported` per begun key. Delete all payload and trail-stamp machinery. Add `_last_valid_surface_contact`, `_ticks_since_surface_contact`, and `surface_paint_swept` emission. Keep CCD config, `_primary_contact`, `_select_incoming_velocity`, `_contact_missing_ticks`, the bounds/lifetime/penetration guards. |
| `src/projectile/projectile_contact.gd` | Add `surface_class`, `impulse_is_measured`. |
| `src/projectile/projectile_data.gd` | Delete `initial_payload`, `deposit_rate`; rename `paint_stamp_radius → paint_footprint_radius`. Keep body/launch/lifetime tuning. |
| `src/projectile/projectile_manager.gd` | Drop `payload_override` and the amount plumbing; add a `surface_paint_swept` relay and a monotonic `spawn_index`. |
| `src/paint/paint_system.gd` | Add `apply_surface_sweep()`; retarget `_connected_component` to a segment; precompute per-pixel surface arrays; scratch-buffer the candidate map; dirty-rect batched upload in `_process`; delete `_apply_steepest_descent_flow`. |
| `src/paint/paint_deposit_request.gd` | Delete `amount`, `allow_flow`, `maximum_flow_steps`; add `alpha`. |
| `src/paint/paint_deposit_tuning.gd` | Replace the amount economy with `{trail_core_alpha, trail_rim_alpha, impact_alpha, burst_alpha, puddle_alpha, painted_threshold}`. |
| `src/paint/terrain_paint.gdshader` | Raise the paint threshold to match `painted_threshold = 0.50`; strengthen thickness cues (rim + a 1-texel height offset illusion); remove the fake `upwardness` shading term; add terrace-edge darkening. |
| `src/mechanisms/{burst,splitter}_node.gd` + `resources/mechanisms/*.tres` | Burst → geodesic disc, no amount, no flow. Splitter → no payload split; keep `child_count 3`, `child_speed_multiplier 0.78`, `MAXIMUM_SPLIT_GENERATION 1`, the 0.78 footprint multiplier. |
| `scenes/mechanisms/*.tscn` | Scale visuals to 6.0–7.5 m diameter; bring `MechanismBody` shapes into ≥ 80% AABB parity. |
| `src/stage/stage_controller.gd` | Remove the four payload members/methods only. |
| `src/stage/shot_observation.gd` | Replace the three payload fields with `swept_path_length: float`, `painted_area_m2: float`, `airborne_gap_count: int`, `penetration_guard_count: int`. |
| `src/debug/debug_overlay.gd` | Replace the payload line with: swept path length, live sweep rate, last sweep chord, airborne gaps, bridged gaps, dirty-rect size, mask-upload rate. |
| `src/ui/hud_controller.gd`, `src/ui/hud/observation_controls.gd`, `scenes/ui/hud/observation_controls.tscn` | Remove the payload bar; show swept path length or nothing. |
| `scenes/ui/hud/*.tscn`, `resources/ui/paint_mountain_theme.tres`, `project.godot` | §6.5. |
| `scenes/gameplay/gameplay.tscn` | Faceted apron replaces the plane; lighting per §6.2. |
| `scenes/gameplay/cannon.tscn` | Light grey body, blue accents, visible pivots. |
| `resources/stages/*.tres`, `resources/stage_generation/*.tres` | New profile shape, new targets/stars, Stage 2 aiming bookmark. |
| `src/replay/replay_recorder.gd` | Bump `FORMAT_VERSION` to 4; drop payload from expected observations; add `painted_pixel_checksum` per shot. Reject format 3 — do not migrate. |
| `scripts/solution_search.gd` | Drop the `remaining_payload` tie-break; add swept path length. |

### 7.3 Delete

`src/paint/paint_system.gd::_apply_steepest_descent_flow` and every flow field; all `remaining_payload` state and its transport; `PaintDepositRequest.SourceKind` stays but loses nothing else. **No compatibility fields, no `@deprecated` aliases, no "renamed but still means paint units."** A field named `paint_budget_remaining` is the same defect with a nicer name.

### 7.4 Documents that must change in the same change as the code

`docs/source-brief.md` (add a superseding note at §9/§10/§12-B — do **not** edit the verbatim directive), `docs/design-spec.md:29,65-67,77,106`, `docs/technical-architecture.md:46,48,56,72,105,121`, `docs/test-checklist.md:58-59,66,143,155`, `.agents/Prompt.md`, `.agents/Plan.md`, `.agents/execplans/2026-08-03-core-interaction-redesign.md` (mark superseded; do not silently edit a completed record), `.agents/Documentation.md`. **[all verified locations]**

---

## 8. Vertical implementation sequence

Six slices. Every slice ends with a **running-build screenshot**, not only a headless pass. No slice defers visual proof.

---

### Slice 1 — One route, real contact, continuous paint, matching coverage, reference-aligned frame

**Scope.** Stage 1 only. Single-chain route graph (5 nodes, 4 edges, no branches, no reversals, no mechanisms). New height pipeline with terracing. New eligible mask. `SurfacePaintSweep` end to end. Camera/lighting/apron composition baseline. **No HUD rebuild, no Stage 2/3, no mechanism work.**

**Owner files.** `seeded_stage_generator.gd`, `stage_generation_profile.gd`, new `route_node_profile.gd`/`route_edge_profile.gd`, `generated_stage_layout.gd`, new `surface_paint_sweep.gd`, `paint_system.gd`, `paint_deposit_request.gd`, `paint_deposit_tuning.gd`, `paint_projectile.gd`, `projectile_data.gd`, `projectile_manager.gd`, `terrain_paint.gdshader`, `scenes/gameplay/gameplay.tscn`, `resources/stages/first_descent.tres`, `resources/stage_generation/first_descent_profile.tres`.

**Exit criteria.**
1. Generation accepts First Descent within 32 attempts; height and eligible checksums are recorded and reproduce byte-identically across two fresh processes.
2. Realised corridor slope mean 12–26°, p95 ≤ 32°, max ≤ 40°; ≥ 6 terrace landings ≥ 40 m²; ≥ 4 silhouette maxima; ≥ 85% route visibility. All from `layout.metrics`.
3. Eligible ratio in `0.14–0.20`.
4. A scripted shot at a fixed (yaw, elevation, power) produces ≥ 90 m of swept path and ≥ 25% coverage in one shot.
5. **No trail gap:** along the swept path, every 0.25 m sample within `0.8 · footprint_radius` of the centreline is painted above threshold. Zero exceptions.
6. **No airborne paint:** for every tick with no valid surface contact and no bridge, zero mask writes.
7. Two identical scripted shots produce identical `paint_bytes` checksums.
8. 60 FPS at 1920×1080 through the full shot; mask upload ≤ once per rendered frame.
9. `scripts/verify.ps1` passes.

**Screenshot evidence (running build, 1920×1080, Korean, no debug overlay).** `s1_01_aiming.png` (pre-fire composition), `s1_02_rolling.png` (mid-roll, trail's leading edge at the ball), `s1_03_settled.png` (full route painted end to end), `s1_04_debug_mask.png` (labelled debug: paint mask over eligible mask).

**Stop/go gate.** GO only if `s1_03` shows one **unbroken** paint route from impact to rest with no visible stamp separation, **and** the measured coverage equals the mask-derived coverage to within 0.05 percentage points, **and** the aiming frame meets ≥ 8 of the 11 composition metrics in §6.1 including all four currently failing ones. Otherwise stop — do not start slice 2.

---

### Slice 2 — Contact and collision contract hardening

**Scope.** Multi-contact reporting; `surface_class`; render/collider interior parity; tunnelling and penetration diagnostics; impact/rolling/settle feedback.

**Owner files.** `paint_projectile.gd`, `projectile_contact.gd`, `terrain_geometry_factory.gd`, `terrain_surface.gd`, `shot_observation.gd`, `presentation_effects.gd`, `audio_director.gd`, `tests/{projectile_contact_test,terrain_geometry_test}.gd`.

**Exit criteria.** Interior parity ≤ 0.02 m over ≥ 800 samples. 20 repetitions each of flat / 35° ramp / high-speed graze / skirt contact retain exact collider and shape identity. A tick with simultaneous terrain and mechanism contact reports **both**. Zero `UNKNOWN` surface classes and zero penetration-guard firings across the Stage 1 reliable solution. Launch at 108 m/s (1.5× the cap) produces no tunnelling.

**Evidence.** `s2_01_impact.png`, `s2_02_contact_debug.png` (labelled overlay showing the contact point, normal, surface class, and swept capsule).

**Gate.** GO only if the penetration guard never fires and multi-contact reporting is proven by a test that fails on the old single-primary code.

---

### Slice 3 — Massif art direction and readability

**Scope.** Lighting ratio, apron, shell visibility, shader rework, cannon materials, trajectory dots.

**Owner files.** `scenes/gameplay/gameplay.tscn`, `scenes/gameplay/cannon.tscn`, `terrain_paint.gdshader`, `trajectory_preview.gd`, `environment_dressing.gd`.

**Exit criteria.** All 11 composition metrics in §6.1 pass. Lit-landing : shaded-riser luminance ≥ 1.8:1, measured by a script sampling the capture. Featureless flat ground ≤ 8%. Shell band ≥ 2% frame height over ≥ 60% of the mountain's width. Trajectory dots 5–7 px, occluded by terrain. Decorations own no `CollisionObject3D` and clear no eligible pixels.

**Evidence.** `s3_01_aiming.png`, `s3_02_briefing.png`, `s3_03_result.png` beside `01-target-reference.png` for side-by-side review.

**Gate.** GO only if an independent reviewer, shown `s3_01` and the reference without labels, describes both as "a stepped low-poly puzzle mountain" rather than "a mound."

---

### Slice 4 — Mechanisms under the new paint rule

**Scope.** Mechanism scale, AABB parity, FOV gate fix, Burst geodesic disc, Splitter without payload, Bumper direction arrow, activation feedback.

**Owner files.** `scenes/mechanisms/*.tscn`, `src/mechanisms/*.gd`, `resources/mechanisms/*.tres`, `mechanism_placement_generator.gd`, `tests/{phase5_mechanism_test,mechanism_placement_test}.gd`.

**Exit criteria.** Each mechanism's projected width ≥ 26 px (aiming) and ≥ 40 px (briefing) with the corrected FOV math. Body/visual AABB parity within 80–115%. Burst paints a connected geodesic disc of radius 14 m and adds ≥ 12% coverage in isolation on Stage 2. Splitter emits exactly 3 generation-1 children, each painting continuously at 0.78 footprint, and adds ≥ 20% in isolation. Bumper redirects with a measurable heading change ≥ 25° and its downstream traversal paints. No duplicate activation from one collision; no recursion past generation 1; the 8-ball cap holds.

**Evidence.** `s4_01_burst.png`, `s4_02_splitter.png`, `s4_03_bumper.png`, each showing the activation and its painted consequence.

**Gate.** GO only if every mechanism's isolated coverage contribution is ≥ 10× its recorded pre-reset value (Burst 2.689%, Splitter 1.293%, Bumper 0%).

---

### Slice 5 — Korean-first HUD rebuild

**Scope.** Stretch aspect, anchors, container fixes, type scale, theme variations, chip contents, aim card, coverage card, action buttons, language switch, payload removal from every UI surface.

**Owner files.** `project.godot`, `scenes/ui/hud/*.tscn`, `src/ui/hud/*.gd`, `src/ui/hud_controller.gd`, `resources/ui/paint_mountain_theme.tres`, `translations/ui.csv`.

**Exit criteria.** Zero clipped or ellipsised labels in Korean **and** English at 1280×720, 1600×900, 1920×1080. All HUD roots anchored with a 24 px safe margin. Label/value type contrast ≥ 1.7× in every chip. No occurrence of `payload` in `src/ui/`, `scenes/ui/`, or `translations/`. Fire disabled state, focus rings, and hover states visible.

**Evidence.** `s5_01_aiming_ko.png`, `s5_02_aiming_en.png`, `s5_03_observation.png`, `s5_04_result.png`, plus one 1600×900 Korean capture.

**Gate.** GO only if the HUD reads correctly at all three sizes in both locales.

---

### Slice 6 — Stages 2 and 3, balance budget, full verification

**Scope.** Full route graphs for both stages, mechanism placement on graph nodes, feasibility metric enforcement, target/star rebalance, replay format 4, complete suite.

**Owner files.** `resources/stage_generation/*.tres`, `resources/stages/*.tres`, `seeded_stage_generator.gd` (feasibility metric), `replay_recorder.gd`, `tests/*`, `docs/*`, `.agents/*`.

**Exit criteria.** Every stage passes its complexity budget and the coverage-feasibility metric with ≥ 25% headroom. Each stage has one recorded `reliable_solution` that clears its target in ≤ `maximum_shots`, replays deterministically from a fresh process, and is **understandable when watched** — not merely numerically successful. Full `scripts/test.ps1` green. All seven brief-mandated screenshots recaptured.

**Gate.** GO to delivery only if a human watching each reliable solution can state, before it lands, roughly where the ball will go — the puzzle must be *readable*, not merely solvable.

---

## 9. Verification strategy

### 9.1 Static

`scripts/verify.ps1` unchanged: headless editor import/parse, then a 3-second main-scene start. **Add a grep gate** that fails the build if `payload`, `deposit_rate`, `paint_stamp_radius`, or `remaining_payload` appears anywhere under `src/`, `scenes/`, `resources/`, `translations/`, or `tests/` after slice 1. This is what prevents the concept from returning under a new name.

### 9.2 Headless deterministic

| Test | Assertion |
|---|---|
| `stage_generation_test.gd` (revise) | Seed/attempt/checksum determinism across two fresh processes; **plus** every §3.5 metric per stage; **plus** the coverage-feasibility metric. Do not accept height statistics alone. |
| `terrain_geometry_test.gd` (revise) | Watertight shell, flat winding, **cell-interior** render↔collider parity ≤ 0.02 m over ≥ 800 samples, triangle counts, shader constraints. |
| `mechanism_placement_test.gd` (revise) | Corrected FOV projection; 26/40 px gates; graph-node placement; occlusion; separation; deterministic transforms. |
| `decoration_placement_test.gd` (revise) | Deterministic counts; **no `CollisionObject3D`**; **no eligible pixels cleared**. |
| `paint_sweep_test.gd` (**new**) | The seven invariants in §9.5. |
| `phase3_paint_test.gd` (revise) | Overlap counts once; coverage equals a recomputed mask scan; `clear()` restores zero. |
| `phase3_projectile_paint_test.gd` (**replace**) | Delete every finite-payload assertion (`:66,71-72,84`). Replace with: continuous sweep across a scripted roll, no gap, no airborne paint, bridged chatter, disc-only after a real bounce, puddle on settle. |
| `phase5_mechanism_test.gd` (revise) | Body/visual AABB parity; simultaneous-contact activation; isolated coverage contributions; no duplicate activation; generation cap; 8-ball cap. |
| `camera_safety_test.gd` (revise) | Existing clearance and line-of-sight checks **plus** the §6.1 composition envelope for **every** stage bookmark. |
| `localization_ui_test.gd` (revise) | Single-line, non-clipped labels in ko and en at 3 sizes; no `hud.payload`. |
| `phase6_content_test.gd` (revise) | Three stages, targets 35/50/70, one recorded reliable solution each; **the solution must be a recorded seed+action sequence, not a live search.** |
| `phase8_replay_process_test.gd` (revise) | Format 4; rejects format 3; painted-pixel checksum matches across processes. |

### 9.3 Focused physics

| Test | Assertion |
|---|---|
| `projectile_contact_test.gd` (extend) | Keep 20× flat/ramp/graze/skirt and the recontact debounce. Add: multi-contact reporting; `surface_class` never `UNKNOWN`; `impulse_is_measured` flagged correctly. |
| High-speed tunnelling (**new**) | Launch at 108 m/s at 20 fixed angles into terrain; zero misses, zero penetration-guard firings, contact reported within 1 tick of geometric intersection. |
| Steep-slope mapping (**new**) | Roll along 20°, 30°, and 38° faces; assert painted band width in the **surface tangent plane** is `2 · footprint_radius ± 8%`, and that XZ mask coverage matches the projected expectation. |
| Max-speed continuity (**new**) | Slide at 60 m/s across a smooth face; assert zero unpainted samples along the centreline. This is the gap test at maximum expected speed. |
| Reversal climbability (**new**) | For each stage's reversal edges, a ball entering at the designed speed clears the crest; at 60% of that speed it rolls back. Both are valid puzzle outcomes, but the *designed* one must work. |

### 9.4 Running-build visual and manual

Headless Godot's dummy renderer cannot produce a viewport texture, which is why the previous cycle produced no render capture. **[verified: `.agents/Documentation.md`, Task 08]** Every slice gate therefore requires a **windowed** capture via `DeliveryCaptureRunner`, at 1920×1080, in Korean, without the debug overlay, checked into `screenshots/`. Separate full-resolution images only — never a contact sheet, collage, or poster.

A capture-analysis script (headless, on the PNG) measures: mountain apex %, base %, sky area, featureless-ground area, silhouette maxima count, lit:shaded luminance ratio, shell band height, cannon bbox %. These are the §6.1 numbers, machine-checked.

### 9.5 The seven paint invariants (the heart of the new suite)

1. **No gap.** Every 0.25 m sample along the swept centreline, at any speed up to 108 m/s, is painted above threshold.
2. **No airborne paint.** Zero mask writes on any tick without a valid surface contact and without an active bridge.
3. **No bleed.** Zero painted pixels whose surface point is > `footprint_radius` from the swept capsule, and zero painted pixels not connected to a seed through eligible pixels.
4. **Overlap once.** Re-traversing a painted segment yields zero coverage gain.
5. **No depletion.** A ball rolling for 15 s paints its entire path; a synthetic 400 m traversal paints 400 m.
6. **Determinism.** Two identical scripted shots yield an identical `paint_bytes` checksum; multiple balls in one tick yield the same checksum regardless of spawn order.
7. **Coverage identity.** `painted_eligible_pixels` equals a full independent scan of `paint_bytes` against `eligible_bytes`, to the pixel, after every shot.

### 9.6 What is not proof

- **A solver clear is not proof of acceptable design.** `scripts/solution_search.gd` finding a sequence proves reachability, not readability. The slice 6 gate is a human able to predict the ball's route *before* it lands.
- **A checked box in `docs/test-checklist.md` is not evidence.** Rewrite lines 58-59, 66, 143, 155 to describe the new contract and reset them to unchecked.
- **`.agents/Documentation.md`'s "Superseded Remediation Claims" section stays quarantined.** Do not resurrect its seeds, checksums, or coverage figures.

---

## 10. Decisions, contradictions, and residual risks

### 10.1 Decisions (each has one recommended default)

| # | Decision | Ruling |
|---|---|---|
| D1 | Mountain representation | **Heightfield + closed shell, kept.** Replace only the height synthesis. Justification: `HeightMapShape3D` collision, exact world-XZ paint mapping, and no-caves/no-overhangs non-goal. |
| D2 | Generation pipeline | **Route-graph-first.** Massif grows outward from the graph; terraces quantised at 3.5–4.5 m with 0.85–0.95 blend; corridors carved with 4 m banks and 6–10 m lips. |
| D3 | Route graph shape | Typed `RouteNodeProfile` + `RouteEdgeProfile` in stage Resources; realised graph stored on `GeneratedStageLayout`. |
| D4 | Continuous paint command | **`SurfacePaintSweep`**: previous contact → current contact, per physics tick, from `_integrate_forces`. Discs retained only for impact, burst, and puddle. |
| D5 | Rasterisation | 3D **capsule distance** against precomputed per-pixel surface points, gated by an 8-neighbour connected component seeded at both endpoints. |
| D6 | Contact lifecycle | Bridge ≤ 3 ticks, same collider, chord ≤ 2.5·r. Otherwise disc-only. Never paint across an airborne arc. |
| D7 | Paint look | Core alpha 1.0 to 0.85·r, rim to 0.5 at r; `painted_threshold` 0.50; roughness 0.16–0.22; specular 0.70–0.80; dark rim retained. Splash and puddle are additive marks, never substitutes. |
| D8 | Downhill flow | **Deleted.** The brief marks it optional; it costs determinism and risks painting unreached surfaces. Burst uses a geodesic disc instead. |
| D9 | Eligible surface | **Rollable (≤ 42°) ∧ inside the designed play region ∧ not under a mechanism.** Target ratio 0.14–0.22. Decorations no longer subtract. |
| D10 | Footprint radius | **4.0 m** (3.2–4.6), named `paint_footprint_radius`, declared as a stylisation matched to the reference's ~3.4%-of-width paint channels and to the coverage budget. |
| D11 | Coverage targets | **35 / 50 / 70%.** Stage 1's 4% was a defect accommodation, not a design. Enforced by a build-time feasibility metric. |
| D12 | Collision contract | One layout → one factory → mesh + `HeightMapShape3D` + shell. Cell-**interior** parity is the test, not vertex parity. |
| D13 | Decorations | **Non-solid, non-excluded.** One coherent policy. |
| D14 | Camera | **Keep the current framing envelope.** Fix Stage 2's bookmark; add composition assertions to `camera_safety_test.gd`. |
| D15 | Art direction | Ambient 0.28–0.40 against key 1.05–1.25; sun 34–42° elevation, 30–50° azimuth off camera; faceted apron replaces the flat plane; 8–14 m of shell visible. |
| D16 | Mechanisms | 6.0–7.5 m visual diameter; corrected FOV gate at 26/40 px; ≥ 80% body/visual AABB parity. |
| D17 | Trajectory preview | Screen-constant 5–7 px dots, 14–20 px spacing, ≤ 60 dots, **depth test on**. |
| D18 | HUD | `stretch/aspect = "expand"`; anchors + 24 px safe margins everywhere; label 13–14 px / value 24–30 px contrast; Korean default, never uppercase-transformed. |
| D19 | Migration style | **Delete, do not alias.** A grep gate enforces it. |
| D20 | Replay | Format **4**, rejects format 3, adds a per-shot painted-pixel checksum. |

### 10.2 Contradictions resolved

| Contradiction | Ruling |
|---|---|
| Source brief §9/§10 mandate finite payload, shrinking marks, and depletion-based stopping; the user's correction forbids all three | **User correction wins.** Annotate the brief with a superseding note; do not edit the verbatim text. |
| Brief §12-B specifies 30% child payload with 10% split loss | **Void.** Children paint at full opacity; only footprint scale (0.78) and count (3) are bounded. |
| Brief §11 specifies optional downhill flow; the corrected model forbids painting unreached surfaces | **Flow deleted.** Optionality is exercised in the negative. |
| Brief §22 caps the paint mask at 512² and forbids per-frame full-texture reads; the current code re-uploads the full 262 KB image per deposit | **512² kept; upload batched to ≤ once per rendered frame.** |
| `AGENTS.md:4` still describes the game as launching "finite-payload paintballs" | **Amend that line.** It is the top-of-file project statement and will mislead every future agent. |
| `docs/test-checklist.md` records finite-payload behaviour as verified `[x]` | Rewrite and reset those lines; a checked box for a deleted requirement is worse than no box. |
| Stage 1's 4% target vs. the brief's "the player can clear the stage without precision" | **Raise to 35%.** 4% is unmeasurable as a design intent. |
| `.agents/execplans/2026-08-03-core-interaction-redesign.md` is labelled `active` but encodes the obsolete model | **Mark superseded; do not silently rewrite.** It is a truthful record of a superseded decision. |
| `burst_basin.tres`'s 100 m-high aiming camera vs. "cannon in the lower foreground" | Bring into the shared envelope; add a per-stage assertion. |

### 10.3 Residual risks

| Risk | Likelihood | Mitigation |
|---|---|---|
| GDScript cannot hold 60 Hz for 8 concurrent sweeps even after the three performance changes | Medium | Slice 1 exit criterion 8 measures it directly. Fallback: cap concurrent sweeps at 4/tick with a deterministic round-robin over `spawn_index` — deterministic and testable. Do **not** fall back to reducing the footprint or skipping ticks. |
| Terrace risers at 55–61° create ledges that trap balls and shorten traversals | Medium-High | The mean/p95 corridor slope metric plus the coverage-feasibility metric catch it at generation time. Corridors are carved *through* terraces as smooth ramps precisely to prevent this. |
| The connected-component constraint refuses legitimate paint at a corridor lip where eligibility flips | Medium | Invariant 3's "no bleed" test has a paired "no starvation" companion: assert the painted band width in the tangent plane is within 8% of `2·r` on 20°/30°/38° faces. |
| The stricter 42° eligibility threshold drops the ratio below 0.14 and makes coverage jumpy | Medium | The `play_margin` (12–18 m) is the tuning lever. The ratio is a generation rejection metric, so a bad profile fails closed rather than shipping. |
| 26 px mechanism gates are unsatisfiable at 180 m board width without oversized devices | Low-Medium | 6.0–7.5 m gives 31–39 px at 130 m **[computed]** with margin. If a placement still fails, it means the node is too far — move the node, not the gate. |
| Multi-contact reporting causes duplicate mechanism activations | Low | `_activated_projectile_ids` plus `cooldown_remaining` already guard this **[verified: `gimmick_base.gd:66-69,91-92`]**. Add an explicit duplicate test. |
| Replay format 4 invalidates saved attempts | Certain, accepted | The recorder already rejects mismatched formats; no user-facing replay library exists. |
| Deleting flow changes Burst's feel | Low | Burst's geodesic disc at 14 m covers ~15% of a 4,000 m² eligible surface — stronger than today's flow-assisted 2.689%. |
| **The supplied build capture may not match the baseline commit** | Medium | Re-capture at `15bac64` before acting on any HUD pixel detail. Composition and terrain findings are code-derived and unaffected. |
| The composition script's luminance metric is renderer-dependent | Medium | Pin it to Compatibility at 1920×1080 and record the reference thresholds from the first passing capture, not from theory. |

### 10.4 Acceptance policy — copy this into the ExecPlan verbatim

```
PAINT-01  Painting MUST be a per-physics-tick swept capsule between the previous and
          current valid surface contact, produced in _integrate_forces from real contact
          data. AVOID deriving it from a rendered transform.
PAINT-02  Paint MUST NOT deplete. No field, resource, observation, replay entry, debug
          readout, HUD element, or test may represent a remaining paint quantity, under
          any name. A static grep gate enforces this.
PAINT-03  The painted trail MUST have no gap at any speed up to 108 m/s, verified by
          0.25 m centreline sampling.
PAINT-04  Painting MUST NOT occur on any tick without a valid surface contact or an
          active bridge (<= 3 ticks, same collider, chord <= 2.5 x footprint radius).
PAINT-05  Painting MUST NOT reach a pixel whose reconstructed surface point is farther
          than the footprint radius from the capsule, or that is not connected to a seed
          through eligible pixels.
PAINT-06  Overlap MUST count once. Re-traversal yields zero coverage gain.
PAINT-07  Coverage MUST equal a full independent scan of the paint mask against the
          eligible mask, to the pixel, after every shot.
PAINT-08  Identical inputs MUST yield an identical paint-mask checksum across fresh
          processes; multi-ball ordering MUST NOT affect it.
PAINT-09  Splitter children MUST obey PAINT-01..08. Only count (3), generation (1), and
          footprint scale (0.78) may be bounded.

GEN-01    Generation MUST be route-graph-first. Realised corridor slope: mean 12-26 deg,
          p95 <= 32 deg, max <= 40 deg. Corridor lip slope <= 34 deg.
GEN-02    Each stage MUST realise its terrace-landing, silhouette-maxima, branch-
          divergence, reversal-climbability, and route-visibility budgets.
GEN-03    Eligible ratio MUST fall in [0.14, 0.22] and MUST exclude surfaces steeper
          than 42 deg and everything outside the designed play region.
GEN-04    A stage MUST fail generation unless
          (max_shots * expected_path * band_width + mechanism_area)
          >= 1.25 * target_coverage * eligible_area.
GEN-05    Generation MUST remain 32 derived seeds + 1 pinned fallback, then fail closed.

GEO-01    Render and collision MUST derive from one accepted layout, verified by CELL-
          INTERIOR sampling within 0.02 m. Vertex parity alone is insufficient.
GEO-02    Every begun contact MUST be reported. A tick with simultaneous terrain and
          mechanism contact MUST report both.
GEO-03    The penetration guard MUST NOT fire during any recorded reliable solution.
GEO-04    Decorations MUST be non-solid AND MUST NOT be excluded from the eligible mask.

VIS-01    The aiming frame MUST satisfy: apex 6-18% from top; base 68-80%; silhouette
          width >= 85%; featureless ground <= 8%; silhouette maxima >= 4; lit:shaded
          luminance >= 1.8:1; shell band >= 2% frame height over >= 60% of width;
          cannon bbox 2.5-5.0% of frame area.
VIS-02    Mechanisms MUST project >= 26 px (aiming) and >= 40 px (briefing) at
          1280x720, computed with the HORIZONTAL field of view.
VIS-03    The trajectory preview MUST end at the first predicted collision, MUST be
          occluded by terrain, and MUST use screen-constant 5-7 px dots.
VIS-04    Korean MUST be default; no HUD label may clip or ellipsise in ko or en at
          1280x720, 1600x900, or 1920x1080.

PROC-01   Every slice MUST produce running-build screenshots at its gate. Headless
          passes alone MUST NOT close a slice.
PROC-02   A solver clear MUST NOT be accepted as proof of readable design.
PROC-03   Coverage targets MUST NOT be lowered, paint marks MUST NOT be inflated beyond
          the declared footprint range, and the route MUST NOT be revealed, to close any
          gate.
PROC-04   Obsolete requirements MUST be deleted, not renamed or aliased.
```

---

### Closing note

The repository's ownership boundaries are sound — `StageController`, `PaintSystem`, `TerrainSurface`, `GeneratedStageLayout`, `GimmickBase`, and the componentised HUD are all the right shapes, and none of them needs replacing. What is wrong sits *inside* three functions and one mask definition: `_synthesize_height`, `_request_surface_trail`, `_write_component`, and `_build_eligible_mask`. Fix those four, delete the paint economy that surrounds them, restore the ambient/key light ratio, and the architecture already in place will carry the corrected game.