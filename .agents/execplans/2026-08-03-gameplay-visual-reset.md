---
type: plan
status: active
created: 2026-08-03
last_reviewed: 2026-08-03
scope: route-graph terrain, direct target reachability, solid rear containment, target-surface scoring, continuous contact paint, collision truth, mechanisms, camera and trajectory presentation, Korean-first HUD, replay migration, balance, and production evidence
source: explicit user corrections through 2026-08-03 and the validated Claude gameplay/visual-reset review dated 2026-08-03
related:
  - ../PLANS.md
  - ../Documentation.md
  - ../../AGENTS.md
  - ../../docs/source-brief.md
  - ../../docs/design-spec.md
  - ../../docs/technical-architecture.md
  - ../../docs/test-checklist.md
  - ../../docs/handoffs/gameplay-visual-reset-2026-08-03/README.md
  - ../../docs/handoffs/gameplay-visual-reset-2026-08-03/external-review-validation.md
  - 2026-08-03-core-interaction-redesign.md
---

# Paint Mountain Gameplay and Visual Reset - Execution Contract

This contract turns the user's corrected game rule and the locally validated
Claude review into one executable redesign. It preserves the useful Godot
owners already present, replaces the lobe-first mountain and finite stamp
economy, proves one real Stage 1 roll before expanding content, then rebuilds
the presentation around the supplied reference. The superseded core-interaction
plan remains historical implementation evidence and is not an authority for
paint behavior or completion.

## Purpose

- Objective: deliver a legible low-poly 3D mountain puzzle in which a stationary
  cannon launches an unsteered physical ball and every scoreable target surface
  traversed while the ball is in contact is painted continuously.
- Deliverable: a Godot 4.7.1 Windows desktop build with three deterministic
  generated stages, a directly reachable scoreable surface, a solid visible
  rear backstop, truthful terrain and mechanism collision, continuous surface
  paint, `4 / 27 / 70%` targets, Korean-default responsive HUD, and controlled
  running-build evidence against the supplied reference.
- Completion state: all phase checks, fixed-target solutions, fresh-process
  replay checks, production export, and user-coordinated visual gates pass; no
  unreachable target unit, rear/upper escape, finite-payload, downhill-flow,
  lobe-first, ghost-obstacle, or false-completion path remains active.

The verified implementation baseline is commit
`01e3e35f5ae219f92c878dd5ad177d30c5a120a7` on `master`; the worktree was clean,
no remote was configured, and no runtime/GUI was launched during plan creation.
The documentation commit that installs this plan is not an implementation
baseline and must not be cited as gameplay progress.

## Scope and Boundaries

In scope:

- Align active product and architecture documents with the user's later paint
  correction while preserving the source brief verbatim as historical input.
- Replace lobe-first height synthesis with a deterministic route-graph-first
  target, one contiguous scoreable target footprint, a faceted top mesh, and a
  thick closed support shell derived from one immutable generated layout.
- Reject any generated layout unless every scoreable target texel has a legal,
  reproducible yaw/elevation/power witness whose first physical collision is on
  its target-top neighbourhood; derive the default center aim from that same
  certificate rather than from a hand-authored tuple.
- Build a bright, screen-filling, non-paintable rear backstop as a real 3D mesh
  and collider joined to the mountain/apron; contain the complete current aim
  envelope without an invisible rear or upper kill boundary.
- Report every begun physics contact and create gap-free surface paint sweeps
  from authoritative terrain-top contacts, with deterministic command ordering
  and one `PaintSystem` mask for visuals and coverage.
- Remove payload amount, depletion, shrinking marks, downhill flow, payload UI,
  payload observation, and Splitter payload conservation from active code,
  resources, schemas, tests, and user-facing copy.
- Make mechanism placement, visible geometry, and physical collision agree;
  correct horizontal projection math; preserve Burst, Splitter, and Bumper's
  intended roles, assign distinct semantic colors and tolerance/balance gates,
  and do not add a second category of special terrain.
- Calibrate the normal projectile/terrain interaction for a short first rebound
  followed by readable rolling or sliding; Bumper remains the sole deliberate
  strong-redirection exception.
- Recompose terrain, foreground, camera, cannon, trajectory, lighting, and the
  Korean-first HUD to follow the supplied reference's hierarchy.
- Migrate replay/agent/debug contracts, rebalance only through the locked
  geometry and physical behaviors, prove all fixed targets, and regenerate
  production evidence.

Out of scope:

- New stages, mechanisms, steering after launch, online features, mobile/web
  delivery, multiplayer, narrative systems, shops, accounts, or analytics.
- Ice, sticky, drain, booster, damage, or other new terrain-material effects.
  The current milestone calls the existing Burst, Splitter, and Bumper pads
  special gameplay features; it does not create a new surface-effect taxonomy.
- Shooting over or around the visible rear mountain boundary, hidden terrain
  beyond that boundary, bank shots off the rear backstop, or an open-world
  continuation. Those are explicit future possibilities, not current behavior.
- True geodesic surface-area scoring, per-triangle paint textures, decals as a
  second paint authority, fluid simulation, erosion, voxel terrain, or runtime
  terrain deformation.
- New dependencies, plugins, engines, network services, asset packs, fonts, or
  downloads. Only the already approved and committed Kenney/Pretendard assets
  may be used.
- Changing the fixed target percentages, shot limits, projectile cap, supported
  renderer, or first-collision-only preview boundary.

Constraints and invariants:

- Godot 4.x, typed GDScript where practical, Compatibility renderer, Windows
  desktop first, and a fixed 60 Hz physics tick remain fixed.
- `StageController` alone owns stage state, shot progression, and clear/failure.
  `PaintSystem` alone owns persistent paint bytes, the immutable runtime copy of
  target-mask bytes, the paint texture, and coverage. `ProjectileManager` alone assigns stable projectile
  spawn ordinals and owns projectile lifecycle/caps.
- One immutable `GeneratedStageLayout` feeds render geometry, top collision,
  surface queries, target footprint, direct-reachability certificate, default
  aim, containment specification, placement, replay metadata, and agent
  observations. No consumer regenerates or edits layout data.
- Human input, replay, tests, and the agent API invoke the same yaw, elevation,
  power, fire, and restart commands. A projectile is never steered in flight.
- The user-addressable aim domain is yaw `-45..45 deg`, elevation `10..68 deg`,
  and power `0..100%`; yaw/elevation are canonicalized to `0.1 deg` and power to
  `1%`. Every direct-reachability witness lies on that exact input lattice.
- Every scoreable target texel is within `0.50 m` on its own top triangle of a
  certified first terrain-top collision. The generator rejects a layout when
  this is false; scoring geometry is never hidden or deleted to make it pass.
- Every legal aim has a visible physical first collision before a rear, side,
  upper, or lower bounds exit. The backstop and apron are collision truth but
  never target or paint authority.
- Coverage means thresholded XZ-projected target texels, not true sloped surface
  area. That limitation is explicit in UI-neutral technical docs and replay.
- The fixed stage targets and shot limits remain Stage 1 `4% / 4`, Stage 2
  `27% / 5`, and Stage 3 `70% / 6`.
- Korean is the default locale and English remains selectable. Pretendard is the
  only application font. No visible string is hardcoded in gameplay scripts.
- Normal implementation and testing are headless. No Godot editor or game
  window may be opened implicitly, repeatedly, or merely to inspect progress.

Destructive or irreversible actions:

- No repository-destructive action is authorized. Obsolete scripts, fields,
  resources, tests, and imports may be deleted only after their replacement is
  wired and the narrow migration check passes; git history is the recovery path.
- Replay format 4 intentionally rejects format 3 development replay files. Save
  progression/settings remain supported; this plan does not authorize deleting
  user save data.

Exact actions requiring owner or user approval:

- Before Phase 0 execution, replace only the phrase `finite-payload paintballs`
  in root `AGENTS.md` with `paintballs that continuously paint every target
  surface traversed while in contact`. A future user instruction to execute this
  exact plan counts as approval for that one protected-file edit; it does not
  authorize any other `AGENTS.md` change.
- Visible release execution is limited to two explicitly coordinated sessions:
  the Stage 1 vertical-proof gate and the final delivery gate. If the user does
  not approve a session, stop at that gate without launching Godot or substituting
  synthetic/headless images.

## Discovery Closure

| Requirement or concern | Verified current owner and behavior | Evidence | Locked decision | Task IDs |
| --- | --- | --- | --- | --- |
| Correct game rule | Active source/docs still describe finite paint, but the latest user correction says the ball paints every target surface it traverses while rolling. | `docs/handoffs/gameplay-visual-reset-2026-08-03/current-state.md`, `external-review-validation.md`, current code | Later explicit user correction supersedes only the finite-payload/flow clauses; all other source-brief rules remain. | 0.1, 1.5 |
| Terrain topology | `SeededStageGenerator` generates routes, then builds lobe mass and carves/blends them; the result reads as a wall. | `seeded_stage_generator.gd::_generate_lobes`, `_synthesize_height`; target/current images | Generate a typed route graph first; bounded route support envelopes create the whole mountain. Delete lobe fields and code. | 0.2, 1.1, 2.1 |
| Target surface | `eligible_mask` uses height/normal tests and removes decoration/mechanism circles, which can hide reachable terrain from scoring. | `_build_eligible_mask`, `_exclude_footprints`, validated review | Rename the concept to `target_mask`; construct one filled graph-derived target footprint; never remove terrain by slope or route-distance at paint time. | 1.2, 2.2 |
| Direct ballistic reachability | Target-mask connectivity is only a topology check; current generation never proves a legal unsteered first hit, and yaw `-28..28 deg` cannot address the Stage 3 front shoulders. | `cannon_controller.gd`, `trajectory_predictor.gd`, graph/target bounds; three independent code/design reviews | Expand the canonical aim domain to `-45..45 / 10..68 deg / 0..100%`; generate a fail-closed exact-predictor certificate covering every target texel on the human input lattice. | 0.2, 1.2, 2.1, 6.1 |
| Rear containment and 3D read | The terrain shell closes the mountain but is not a rear wall; the flat Ground and open bounds permit a projectile to read as passing through or over a distant card. | `terrain_geometry_factory.gd`, `gameplay.tscn`, `StageData.stage_bounds`, current image | Add one bright `480x284x4 m` rear `BoxMesh`/`BoxShape3D`, a collidable faceted apron, fixed containment bounds, and render/collider/parallax gates. | 1.2, 2.4, 4.1-4.3, 6.2 |
| Geometry/collision truth | One heightfield, closed shell, top body, shell body, and surface query owner already exist; interior-cell parity is not fully proved. | `terrain_geometry_factory.gd`, `terrain_surface.gd`, `terrain_geometry_test.gd` | Preserve owners and one height source; add deterministic interior triangle/ray parity and collider identity checks. | 1.2, 2.4 |
| Contact completeness | The projectile groups contacts per key but emits one global primary begun contact, so simultaneous terrain/mechanism contacts can be lost. | `paint_projectile.gd::_integrate_forces`, `projectile_contact.gd` | Emit one typed event per begun collider/shape key in deterministic key order and retain measured/estimated impulse provenance. | 1.3, 3.1 |
| Paint continuity | Paint is requested later from spaced, payload-gated point stamps and can flow downhill. | `paint_projectile.gd`, `paint_deposit_request.gd`, `paint_system.gd` | Contact begins with a disc; sustained terrain-top contact emits a 3D surface sweep every physics tick; verified micro-gaps may bridge; real airborne gaps stay blank. | 0.2, 1.3, 1.4 |
| Paint authority and ordering | `GameplayScene` currently applies requests immediately; there is no stable cross-process projectile ordinal or drain boundary. | `gameplay_scene.gd`, `projectile_manager.gd`, `paint_system.gd` | Manager assigns per-shot spawn ordinals; `PaintSystem` queues and drains at one late fixed-physics boundary sorted by tick/ordinal/sequence/type. | 1.4, 1.5 |
| Paint performance | Component buffers, recent-mask clearing, and texture upload work can occur per deposit. | `paint_system.gd`, `phase8_performance_test.gd` | Precompute surface samples, reuse scratch/queue storage, clear only dirty regions, and upload at most once per rendered frame. | 3.5 |
| Decorations | Solid-looking non-colliding dressing can be crossed and its current footprints alter scoring. | `environment_dressing.gd`, `decoration_placement.gd`, current image | Non-solid scale cues exist only outside the target footprint and every route/pad envelope. No collidable decorative obstacle is in this scope. | 2.2 |
| Mechanisms | Physical bodies exist, but projection uses vertical FOV as horizontal FOV and simultaneous contacts can suppress activation; visible/body mapping needs per-part proof. | `mechanism_placement_generator.gd`, `gimmick_base.gd`, mechanism scenes | Correct horizontal FOV; every gameplay-relevant visible mass maps to collision; visual-only parts are explicitly named; all begun contacts reach mechanisms. | 2.3, 3.1-3.4, 4.4 |
| Mechanism semantics and balance | No special-terrain class exists; Burst/Splitter/Bumper are the source-approved physical special features, but their current blue/white styling and placement do not prove readable tolerance or useful trade-offs. | source brief, mechanism resources/scenes, active plan scope | Do not invent surface effects. Give the three mechanisms fixed distinct colors plus silhouette cues, direct activation witnesses, tolerance neighbourhoods, and solution/ablation gates. | 2.3, 3.2-3.4, 4.4, 6.1 |
| Aim/default/preview | Independent manual yaw/elevation/power and first-collision prediction exist; bounds exits are currently fireable, the Stage 1 resource overrides a hand-authored aim, and markers ignore depth. | `aim_input_controller.gd`, `trajectory_prediction.gd`, stage resources | Preserve manual controls, make only physical collisions fireable, derive the restart aim nearest the target centroid from the reachability certificate, classify non-target/backstop hits, and depth-test the arc. | 1.2, 4.2, 4.3 |
| Projectile rebound | Production bounce/friction/damping are `0.24/0.50/0.12/0.22`, with no normal-rebound or settling acceptance fixture. | `basic_paintball.tres`, `paint_projectile.gd`, `projectile_contact_test.gd` | Lock normal terrain tuning to `0.08/0.78/0.18/0.35` and prove bounded rebound, continued surface motion, CCD, and Bumper exception. | 1.3, 3.4, 6.2 |
| Presentation | Current flat foreground, high ambient ratio, oversized cannon, gray mountain, weak target silhouette, and absolute HUD layout diverge from the reference and later white-world direction. | supplied images, `gameplay.tscn`, HUD scenes/theme, latest user correction | Use the exact off-white composition, palette, lighting, scale, 3D depth, and container contract below. Numerical baselines are gates, not executor-selected suggestions. | 4.1-4.5, 5.1-5.3 |
| State/observation/replay | Stage, observation, HUD, debug, agent, tests, and resources propagate payload; replay is format 3. | mapped files in `source-map.md` | Delete payload semantics coherently, bump replay/observation schema to 4, drain paint before sealing, and record the final mask checksum. | 1.5, 5.4 |
| Balance | The previous finite-payload plan failed Stage 2/3 solutions; external `35/50/70` advice is unsupported. | superseded plan Task 09, validation | Keep `4/27/70` and `4/5/6`; prove physical solutions only after topology/paint are correct. Never lower targets or hide terrain to pass. | 6.1 |
| Runtime tooling | Godot 4.7.1 console, headless verification/tests, export preset, release entry, and fastrun command exist. Headless rendering cannot make real viewport evidence; capture runner goes fullscreen. | `scripts/verify.ps1`, `scripts/test.ps1`, `export_presets.cfg`, `delivery_capture_runner.gd` | Use headless checks normally. Use the release executable only during the two approved visible sessions; store interim and final evidence separately. | all gates, 1.6, 7.2 |
| Dependencies/assets | Approved Kenney and Pretendard files are already committed and licensed. | `docs/asset-licenses.md`, current assets | Reuse only those files; do not download or add anything. | 4.1, 4.4, 5.1 |

Readiness statement:

- Every material product, architecture, dependency, data, UX, ownership, safety,
  and validation choice is fixed below. The two remaining approvals govern
  already-defined actions; they do not leave design choices to the executor.
- Godot 4.7.1, the headless scripts, the Windows export preset, and production
  entry were checked in the active PowerShell environment. Exact commands are
  listed under Validation and Rework Controls.
- Numeric values inferred from the reference are deliberately locked as the
  first implementation contract. If a value cannot pass its named objective
  gate after defects are excluded, execution stops for a plan revision; the
  executor does not silently tune the number or redefine the target surface.
- Remaining unknowns are implementation-local mechanics within these contracts
  and cannot change visible behavior, ownership, scope, or acceptance.

## Locked Product and Domain Contract

### Canonical terms

| Term | Meaning | Owner |
| --- | --- | --- |
| Target terrain | The generated low-poly 3D mountain board: scoreable top surface plus visibly distinct non-target support/apron/shell. | `GeneratedStageLayout` and `TerrainSurface` |
| Route graph | Deterministic nodes and directed edges that define intended traversable corridors, branches, reversals, pads, and difficulty before any height is synthesized. | `SeededStageGenerator` output |
| Target footprint / `target_mask` | Immutable 512x512 XZ projection of every scoreable terrain-top texel. It is not painted state. | `GeneratedStageLayout`; copied once into `PaintSystem` |
| Directly reachable target texel | A target texel for which a human-addressable aim tuple makes its first collision on `terrain/top`, on the same rendered/collision triangle and within `0.50 m` surface distance. It never relies on a mechanism, shell, apron, or backstop contact first. | `DirectReachabilityValidator`; certificate stored by `GeneratedStageLayout` |
| Reachability certificate | Immutable per-layout witness tuples, coverage bits, checksum, minimum margin, and failure diagnostics produced in the headless certification scene with the runtime predictor. It is fairness evidence, not an aim hint or solver exposed to the player. | `StageGenerationCertifier` produces; `StageData` references; `GeneratedStageLayout` verifies/stores |
| Default aim | The certificate witness whose first target-top hit is closest to the target-footprint XZ centroid under the fixed tie order. It is applied only at stage start/restart and does not steer a fired ball. | `DefaultAimSolver` derives during certification; `StageController` applies |
| Rear backstop | The bright solid wall physically closing the far side of the current board. It is visible, collidable, non-paintable, non-scoreable, and not target terrain. | `BackstopEnvironment` from `GeneratedStageLayout.containment` |
| Special gameplay feature | One of the three existing physical mechanism pads: Burst, Splitter, or Bumper. Ordinary slopes/reversals are geometry; no special-terrain material class exists in this milestone. | Generated placement plus `GimmickBase` subclasses |
| Surface paint sweep | One continuous terrain-top contact interval from one real contact sample to the next. It has footprint radius but no amount or payload. | `PaintProjectile` produces; `PaintSystem` applies |
| Radial paint mark | A one-point surface-aware mark for first impact, final rest, or Burst. It has radius/intensity but no amount or flow. | Projectile/mechanism produces; `PaintSystem` applies |
| Paint mask | Mutable 512x512 byte mask used by both the terrain shader and coverage calculation. | `PaintSystem` only |
| Coverage | Count of target-mask texels whose paint byte is at least 128, divided by total target-mask texels. Overlap counts once. | `PaintSystem` only |
| Decoration | A non-gameplay visual scale cue. It is never a route obstacle and never changes target-mask eligibility. | `EnvironmentDressing` |

The Korean user-facing vocabulary remains `스테이지`, `목표 면적`, `칠한
면적`, `남은 탄`, `조준`, `각도`, `파워`, `다시 시작`, `발사`, `폭발`,
`분열`, and `범퍼`. No payload term remains.

### Runtime ownership

| Owner | Owns | Must not own |
| --- | --- | --- |
| `StageController` | State machine, shot count, shot lifecycle, settlement gate, clear/failure, sealed observation | Paint bytes, input devices, terrain generation, mechanism effects |
| `SeededStageGenerator` | Pure deterministic graph/layout generation, cheap structural validators, and accepted-seed/certificate identity verification | Physics-world solving, runtime paint, camera, stage outcomes, hand-authored repair coordinates |
| `StageGenerationCertifier` / `DirectReachabilityValidator` / `DefaultAimSolver` | Headless candidate sequence, exact materialized-physics reachability, default aim, and certificate resource emission after a pass | Gameplay-frame work, UI hints, score mutation, or manual repair coordinates |
| `GeneratedStageLayout` | Immutable graph, heights, checksums, target mask, reachability certificate, default aim, containment specification, placement records, route/surface queries | Mutable coverage or scene nodes |
| `TerrainGeometryFactory` / `TerrainSurface` / `BackstopEnvironment` | Terrain mesh/collider derivation, narrow world surface queries, and matching apron/backstop render/collision construction | Independent height data, scoring policy, aim solving, or invisible containment |
| `ProjectileManager` | Projectile cap/lifecycle, per-shot spawn ordinal, ordered command envelopes | Coverage calculation or stage results |
| `PaintProjectile` | Real rigid-body contact extraction and typed contact/sweep intent | Persistent paint mutation or coverage |
| `PaintSystem` | Paint command queue/drain, rasterization, masks, texture, coverage, dirty/upload lifecycle | Projectile physics, stage decisions, a second terrain model |
| `GimmickBase` subclasses | Body-specific activation/effect intent with duplicate/cooldown guards | Direct mask mutation or stage-specific rules |
| `CameraDirector`, `AimInputController`, `HudController` | Presentation, human input translation, and UI coordination respectively | Gameplay authority or alternate observations |

### Deterministic route-graph terrain

- Retain the current base/fallback seeds and 32-attempt sequence in the headless
  `StageGenerationCertifier`. Move `StageGenerationProfile.profile_version` and
  every `StageData.stage_version` to `4`; after the full structural and physical
  gates pass, each StageData writes the accepted seed and references exactly one
  certificate under `resources/stages/certificates/<stage_id>_v4.tres`.
  Production runtime rebuilds that accepted seed once and fails closed unless
  height, target, placement, containment, and reachability checksums match; it
  never performs a physics search in `_ready()` and never falls through to an
  uncertified attempt. No authored fallback terrain is permitted.
- The grid is exactly `72 x 48` cells (`73 x 49` height samples) over local
  `x=[-90,90]`, `z=[-60,60]`; the top mesh is exactly 6,912 triangles before
  skirt/bottom triangles. The target/paint mask remains `512 x 512`.
- Attempt `i` uses `(base_seed + i * 7919) & 0x7fffffff` for `i=0..31`, then
  the existing pinned fallback seed once. Random profile values use keyed
  samples, not a mutable RNG stream. Build the UTF-8 key as
  `"paint_mountain:" + stage_id + ":v4:" + str(attempt_seed) + ":" + field_key`,
  then compute
  `u=float(FNV1a32(key)&0x7fffffff)/2147483647.0`. Field keys concatenate
  `"route/"`, the decimal route index, `"/node/"`, the decimal node index,
  `"/x"`; grade keys replace the node portion with `"/edge/"`, the decimal edge
  index, and `"/grade"`. Range sampling is `lerp(minimum, maximum, u)`. Adding
  an unrelated field cannot perturb existing values.
- Add `GeneratedRouteGraph`, `GeneratedRouteNode`, and `GeneratedRouteEdge` as
  typed immutable outputs. `StageRouteProfile` remains typed input and contains
  role, endpoint X, width, seven grade signs, drop/rise ranges, lateral bend,
  and optional mechanism pad kind/t/radius. `GeneratedRouteNode` fields are
  `id`, `position`, `route_index`, `station_index`, enum
  `SUMMIT/CORRIDOR/PAD/EXIT`, `mechanism_kind` (`-1` when absent), and
  `pad_radius`. `GeneratedRouteEdge` fields are `id`, `from_node_id`,
  `to_node_id`, `route_index`, `edge_index`, `role`, and `width`.
  `GeneratedRouteGraph` owns ordered node/edge arrays plus ID-to-index maps and
  validates uniqueness/references. Height synthesis accepts only this resolved
  graph, never route profiles or lobe data directly.
- Every route chain uses station Z values `[-44,-32,-20,-8,4,16,30,44]` metres.
  The summit node is `(0,-44)` and is shared. Intermediate X is
  `smoothstep(t) * endpoint_x` plus one seeded lateral offset within the profile
  range; the summit/end offsets are zero. Consecutive X change must be at most
  18 m. Each grade sign draws once from its fixed drop/rise range; cumulative
  height starts at the nominal peak, subtracting a negative-grade draw and
  adding a positive-grade draw. Uniformly shift all graph-node heights by
  `nominal_peak - maximum_node_height`, never rescale them, so the graph maximum
  is exactly the nominal peak.
- An optional mechanism pad splits the containing edge exactly at its configured
  `t`, where `t` is normalized cumulative XZ arc length over the resolved chain.
  Find the first edge whose cumulative end is at least `t*total_length`, compute
  local edge fraction from the remaining length, and split there. The pad becomes
  a typed graph node with configured kind/radius. Stage 2 uses route index 0
  (left endpoint `-26`) for Burst; Stage 3 uses the `SPLITTER` chain for Splitter
  and `BUMPER` chain for Bumper. Route/edge/pad IDs are stable `StringName`s
  derived from stage id, route index, original edge index, and pad kind; split
  suffixes are `/a` then `/b`, never instance IDs.
- `StageGenerationProfile` serializes the grid/bounds, stations, outer band,
  terrace step/blend, bank/corridor/shoulder/support distances, smooth min/max,
  noise fields, target-ratio band, and slope/lip gates listed here; every version
  4 `.tres` writes the explicit values rather than relying on script defaults.
  Remove all lobe count/radius/peak fields. `StageRouteProfile` adds
  `mechanism_kind`; Stage 2's left pad is `BURST`, Stage 3's center is
  `SPLITTER`, and Stage 3's right is `BUMPER`.

Frozen stage profiles:

| Stage | Graph input | Vertical contract | Target contract |
| --- | --- | --- | --- |
| First Descent | one `PRIMARY` chain, endpoint `0`, width `28 m`, grades `-------`, no pad | peak `72 m`, accepted max `68..78 m`, drops `5.5..7.0 m`, X bend `-8..8 m`, 0 reversals | target `4%`, 4 shots, target-mask ratio `0.24..0.42` |
| Burst Basin | two `PRIMARY` chains, endpoints `-26/+26`, width `18 m`, grades `--++---`, left Burst pad `t=0.36`, radius `8 m` | peak `80 m`, accepted max `76..88 m`, drops `6.0..8.0 m`, rises `3.0..4.5 m`, X bend `-7..7 m`, exactly 2 reversals per route | target `27%`, 5 shots, ratio `0.32..0.58` |
| Split Ridge | `SAFE/SPLITTER/BUMPER` chains, endpoints `-48/0/48`, widths `16/12/12 m`; grade arrays `[-1,-1,+1,+1,-1,-1,-1]`, `[-1,+1,-1,+1,-1,-1,-1]`, and `[-1,+1,-1,+1,-1,-1,-1]`; Splitter pad `t=0.60`, radius `10 m`; Bumper pad `t=0.72`, radius `9 m` | peak `88 m`, accepted max `84..98 m`; safe drops `6.5..8.5 m`, rises `3.5..5.0 m`, 2 reversals; other drops `7.5..10.0 m`, rises `4.5..6.5 m`, 4 reversals; X bend `-6..6 m` | target `70%`, 6 shots, ratio `0.40..0.70` |

Resource files must use the integer arrays shown in the table, in that order.

Height synthesis is fixed as follows:

1. Resolve the complete graph and pads. Reject invalid grade/reversal/spacing
   before producing any height.
2. For sample XZ `p` and 3D edge endpoints `a/b`, let `a_xz=(a.x,a.z)` and
   `b_xz=(b.x,b.z)`. Compute
   `t=clamp(dot(p-a_xz,b_xz-a_xz)/dot(b_xz-a_xz,b_xz-a_xz),0,1)`, closest XZ
   `q=lerp(a_xz,b_xz,t)`, `d=distance(p,q)`, and route height
   `h=lerp(a.y,b.y,t)`. An edge's core
   radius `c` is half its width, target shoulder ends at `c+12 m`, and visual
   support ends at `s=c+24 m`. Ignore the edge when `d>=s`. Ties use route
   index, then edge index.
3. Define `smoothstep01(v)=v*v*(3-2*v)` after clamping `v` to `0..1`.
   For an included edge, `bank=4*smoothstep01((d-c)/8)` and
   `falloff=1-smoothstep01((d-(c+12))/12)`. Its bounded support height is
   `support=max(0, falloff*(h+bank))`; it is exactly zero at `s`. Fold nonzero
   supports in stable edge order with polynomial
   `smax(a,b,k)=max(a,b)+max(k-abs(a-b),0)^2/(4*k)`, `k=6 m`.
4. Let `raw_mass` be that fold or zero. Compute
   `terraced=lerp(raw_mass, round(raw_mass/4)*4, 0.90)`. For every edge with
   `d<c+8`, fold its `h` with
   `smin(a,b,k)=min(a,b)-max(k-abs(a-b),0)^2/(4*k)`, `k=3 m`; let
   `carve_weight` be the maximum `1-smoothstep01((d-c)/8)` of those candidates.
   The pre-noise height is `lerp(terraced, folded_floor, carve_weight)` when a
   floor exists, otherwise `terraced`. Thus route cores are graph height, banks
   rise exactly 4 m, branch floors join by smooth minimum, and only local bounded
   envelopes use smooth maximum.
5. For each mechanism pad with radius `r` and node height `pad_h`, compute
   `pad_weight=1-smoothstep01((distance_to_pad-0.65*r)/(0.35*r))` and replace
   height with `lerp(height,pad_h,pad_weight)`. Apply pads in stable graph-node
   order; profile validation rejects overlapping pads.
6. When at least one edge has nonzero support, define `nearest_d/nearest_c` from
   the minimum-`d` edge with the stable tie order and apply seeded Simplex Smooth
   FBM (`frequency=0.035`, 2 octaves,
   `lacunarity=2.0`, `gain=0.45`) at maximum amplitude `0.5 m`, multiplied by
   `smoothstep01((nearest_d-(nearest_c+12))/12)` and
   `clamp(raw_mass/4,0,1)`. Noise is zero throughout the target footprint and
   never changes graph height, pad height, reversals, or target eligibility. When
   no edge has support, noise and height are both exactly zero before apron work.
7. The outermost `12 m` of the full X/Z bounds is a non-target falloff band.
   Blend support to the apron there. Emit one faceted top mesh, an `8 m` minimum
   visible skirt and a bottom. The render top and the top
   `ConcavePolygonShape3D` use the identical per-cell triangles
   `(p00,p01,p10)` and `(p10,p01,p11)`; the shell collider uses the identical
   skirt/bottom faces. `TerrainSurface` height/normal queries select that same
   diagonal and use triangle-plane/barycentric interpolation, not bilinear
   interpolation.
8. In world space the terrain remains centered at `(0,-2,-112)` and spans
   `x=[-90,90]`, `z=[-172,-52]`. Its far edge meets the front face of the rear
   backstop at `z=-172`; all graph mass extends toward the cannon from that
   wall. The containing apron is a faceted, collidable, non-target closed mesh
   over the legal launch cone rather than the current infinite-looking plane.

Fail-closed generation gates:

| Gate | Stage 1 | Stage 2 | Stage 3 |
| --- | ---: | ---: | ---: |
| Target-surface mean slope | `16..30 deg` | `18..32 deg` | `20..35 deg` |
| Target-surface p95 slope | `<=34 deg` | `<=38 deg` | `<=43 deg` |
| Target-surface maximum slope | `<=38 deg` | `<=42 deg` | `<=46 deg` |
| Route-core p95 slope | `<=32 deg` | `<=36 deg` | `<=42 deg` |
| Corridor lip maximum | `<=30 deg` | `<=32 deg` | `<=34 deg` |
| Components / branch reachability | one / exit reachable | one / both exits reachable | one / all three exits reachable |

Slope is measured from the same triangle-plane surface used by paint, at
512-mask pixel centers. Branch reachability is an 8-neighbour traversal through the
target mask with adjacent 3D center distance at most `1.25 m`; it is a topology
check. It is necessary but does not substitute for the direct ballistic gate
below.

### Target footprint and decorations

- `target_mask` is the rasterized filled union of every route core, its full
  `12 m` target shoulder, and every mechanism pad plus `4 m`. The union must be
  one component containing the summit and every route exit; generation rejects
  extra components instead of deleting them.
- `GeneratedStageLayout.target_mask` is the immutable canonical source.
  `PaintSystem` copies it once during `configure`, asserts the copied checksum,
  and never mutates it; no other runtime owner keeps target-mask bytes.
- Exclude only the fixed outer 12 m falloff band, non-target apron/skirt/bottom,
  and each mechanism body's horizontal convex hull dilated by `0.5 m`. Never
  exclude a texel for slope, route distance after construction, decoration,
  camera visibility, or expected shot difficulty.
- Every terrain-top contact whose snapped texel is inside `target_mask` paints
  and scores. Every reachable top texel inside the footprint is exposed by the
  same target material; adjacent non-target shell/buttress is at least 12%
  darker and 20% less saturated, while the farther apron keeps its separately
  locked value, so scoring boundaries remain visible without an overlay.
- Decorations are sampled only where their entire visual AABB is outside the
  target footprint, route support radius, mechanism pad, and a `2 m` clearance
  ring. They remain non-colliding scale cues. No solid-looking decorative object
  may be placed on or above a reachable route. Trees/rocks failing this rule are
  omitted; the generator never cuts a scoring hole around them.

### Direct reachability, default aim, and containment

- `CannonController` canonicalizes all requested actions before signaling them:
  yaw `-45.0..45.0 deg` and elevation `10.0..68.0 deg` round half away from zero
  to `0.1 deg`; power `0..100%` rounds half up to `1%`. Launch speed remains the
  existing linear `32..72 m/s` mapping. Human input, replay, tests, the agent
  action, stored solutions, and generation witnesses all pass through this one
  canonicalization function.
- `StageGenerationCertifier` is a headless-only scene-tree tool. For each
  candidate in the 32-attempt/fallback sequence it first runs graph, slope,
  target, decoration, and placement checks; it then materializes that candidate's
  exact terrain, apron, backstop, and mechanisms in an isolated certification
  root, waits one physics frame for bodies to register, and invokes
  `DirectReachabilityValidator`. It uses the production
  `TrajectoryPredictor.predict_motion()` path: radius `0.52 m`, fixed `1/60 s`,
  project gravity, production linear damping, stage bounds, and collision masks
  `1|4`. A closed-form or collision-free arc may nominate candidates but can
  never certify one. Rejected roots are freed before the next candidate and the
  tool exits nonzero if none passes; no visible window is opened.
- Extend `TrajectoryPrediction` with immutable `TrajectoryHitIdentity`: stable
  owner/shape IDs, PhysicsServer body-shape index from `get_rest_info`, and, for
  `terrain/top`, cell X/Z, triangle `0/1`, and barycentric coordinates.
  `TerrainSurface.classify_top_hit()` is the only triangle classifier. Convert
  measured world XZ to fractional cell coordinates, clamp the outer maximum to
  the final cell, otherwise use `floor`; select triangle 0 for local
  `u+v<=1` (the diagonal tie belongs to 0) and triangle 1 otherwise; then compute
  barycentrics and reconstruct Y from the exact fixed triangle. Classification
  fails unless reconstructed Y differs from the measured point by at most
  `0.05 m`, barycentric components are at least `-0.0001`, and predicted normal
  differs from the triangle normal by at most `1 deg`. Target texels use this
  identical classifier. A same-body hit on a different cell/triangle is never a
  reachability witness.
- Visit target texels in `(y,x)` order. A texel may reuse an earlier witness only
  when its reconstructed 3D point is on the same top triangle and at most
  `0.50 m` surface distance from that witness's measured collision point.
  `0.50 m` is the certificate tolerance, independent of the `0.52 m` projectile
  radius: both texels must resolve through the same fixed XZ-to-triangle rule,
  and sphere overlap alone never certifies reuse. Otherwise solve that exact
  point. Begin with the nearest `0.1 deg` yaw bearing and its two adjacent
  lattice values. For each yaw candidate, compute horizontal travel as the
  positive scalar projection of `(texel_xz-muzzle_xz)` onto that yaw's
  horizontal launch direction; reject a non-positive projection or perpendicular
  miss greater than `1.02 m` (`0.50 m` tolerance plus projectile radius). For
  each integer power from `0` through `100`, integrate collision-free motion at
  the same fixed tick to that projected range, sample elevation from
  `10..68 deg` in `1 deg` intervals, bracket every sign change in height,
  bisect it for
  12 iterations, then test the nearest `0.1 deg` elevation and its two adjacent
  lattice values with the real predictor. Candidate order is endpoint error,
  absolute yaw, elevation, power, then signed yaw. Duplicate canonical tuples
  are tested once.
- A witness passes only when the predictor reports `COLLISION`, stable owner and
  shape are `terrain/top`, the measured point uses the same render/collider
  triangle as the texel, and their reconstructed surface distance is at most
  `0.50 m`. Mechanism-first, shell, apron, backstop, bounds-exit, and timeout
  candidates fail. All target texels must be covered. Store the winning tuples,
  per-texel witness indices, minimum distance/range margins, and an FNV-1a
  `reachable_target_checksum` in the passing certificate. Rejected-attempt
  uncovered coordinates go to certifier evidence, not production resources.
  `GeneratedStageLayout` holds the verified certificate; no gameplay UI or
  agent observation exposes tuples.
- Predictor success is necessary but not sufficient. Before a certificate may
  pass, `tests/target_reachability_test.gd` groups every distinct witness tuple
  into stable witness-index batches of 128 and launches the production
  `PaintProjectile` RigidBody with production radius, mass, damping, CCD,
  collision layers, origin, and velocity in the same materialized scene.
  Test projectiles ignore layer `2` so batches cannot affect one another and are
  retired immediately after their first real contact; mechanisms retain normal
  bodies but no test paint/effect command is applied. Every tuple must first
  contact `terrain/top` within 720 fixed 60 Hz ticks. Its runtime
  `TrajectoryHitIdentity` must equal the certificate owner, shape, cell, and
  triangle, and the measured runtime point must be within `0.50 m` surface
  distance of every target texel assigned to that witness. Missing, wrong-body,
  wrong-triangle, mechanism-first, duplicate-first-contact, penetration, or
  timeout results fail. Sort `(witness_index, identity, quantized_point,
  first_contact_tick)`, where each point component rounds half away from zero to
  `0.001 m`, and store its FNV-1a
  `rigidbody_reachability_checksum`; three fresh certifier processes must match
  it exactly. This batched exhaustive launch is the physical parity proof, not a
  representative sample and not the gameplay projectile-cap path.
- A failed certificate rejects that generation attempt without changing the
  target mask. Run the existing 32 deterministic attempts, then the pinned
  fallback once. If all fail, generation fails closed and the geometry/control
  contract must be replanned; the executor may not delete target texels, widen
  impact tolerance, or introduce target-specific authored shots.
- Only the certifier's explicit `--write-certificate` mode may create
  `resources/stages/certificates/<stage_id>_v4.tres`; that output is provisional
  and cannot be committed or consumed as production content until three fresh
  `--verify-only` processes reproduce the accepted seed, height/target/
  placement/containment/predictor/rigid-body reachability checksums, witness
  tuples, and default aim.
  At runtime `SeededStageGenerator` rebuilds the stored accepted seed and
  verifies those immutable identifiers before briefing; a missing or stale
  certificate is a content error, not permission to generate an unchecked
  replacement.
- Compute the target centroid from all target-mask texel centers in world XZ.
  `DefaultAimSolver` selects the certified witness with smallest XZ impact
  distance to that centroid; ties use absolute yaw, elevation, power, then
  signed yaw. `GeneratedStageLayout.default_aim` replaces `StageData.initial_aim`
  and is applied by `StageController` at first entry and every restart. Its
  prediction must first hit `terrain/top` within `8.0 m` of the centroid and be
  byte-identical across fresh processes.
- `GameplayScene` passes the immutable generated layout into
  `StageController.configure()` before that controller performs its first
  restart. `StageController` is the only owner that applies
  `layout.default_aim` on first entry and restart; `GameplayScene`, HUD, and
  StageData never call `CannonController.set_aim()` for stage initialization.
  HUD values arrive from the accepted cannon aim signal. First entry and both
  restart destinations (`BRIEFING` and `AIMING`) must reproduce the exact
  certificate tuple and target-top prediction.
- `BackstopEnvironment` constructs a front-visible six-face `BoxMesh` and an
  exactly matching `BoxShape3D`, both `480 m` wide, `284 m` high, and `4 m`
  thick, centered at world `(0,111,-174.25)`. Thus its front face is
  `z=-172.25`, its bounds are `x=[-240,240]`, `y=[-31,253]`,
  `z=[-176.25,-172.25]`, and it physically joins the far terrain edge through a
  `0.25 m` faceted transition strip; no
  render or collision faces are coplanar. It uses collision layer `1`, mask `2`,
  stable IDs `world/backstop` and `BackstopWall`, and is neither selectable nor
  included in target/paint masks.
- `ContainmentSpec` defines the apron as one closed, collider-matched faceted
  mesh whose top covers `x=[-245,245]`, `z=[-172.25,52]`, has no top-surface
  point below `y=-30.5`, and joins the terrain shell, the `0.25 m` rear transition,
  and the backstop bottom without any render or collision gap greater than
  `0.01 m`. Its collision layer/mask are `1/2`; it is non-target and
  non-paintable. Faceting may vary only above this fixed catch surface and may
  not create a hole or lower exit.
- Every StageData resource uses containment bounds
  `AABB((-245,-32,-178),(490,286,230))`, whose end is `(245,254,52)`. A
  full-domain containment proof has two layers. First, a conservative
  no-damping envelope over the continuous aim domain uses all rotated muzzle
  extrema, maximum speed `72 m/s`, yaw `+/-45 deg`, elevation `10..68 deg`, and
  projectile radius `0.52 m`; it must fit the wall/apron with at least one
  radius of clearance. Second, run the exact predictor for every canonical
  `0.1 deg / 0.1 deg / 1%` tuple whose analytic envelope can reach a bounds face
  before the apron/backstop; each must physically collide rather than return
  `BOUNDS_EXIT` or `TIMEOUT`. The `5 deg / 2 deg / 5%` lattice remains a fast
  regression sample only, never the proof. A backstop contact records settlement
  reason `BACKSTOP`, creates no paint, zeros further projectile motion, and
  retires at the end of that physics tick after emitting its contact; it cannot
  be used as a bank shot.
- `tests/containment_wall_test.gd` runs predictor and real rigid-body launches at
  canonical tuples `(0,68,100)`, `(-45,50,100)`, and `(45,50,100)`. Each must
  first identify `world/backstop/BackstopWall`, report exactly one begun wall
  contact whose normal is within `1 deg` of world `+Z`, emit no mechanism or paint
  command, leave coverage and paint checksum unchanged, set linear and angular
  velocity to zero in that fixed tick, seal with `BACKSTOP`, and have no active
  projectile on the next physics tick. Predictor/runtime point error is at most
  `0.25 m`; any rebound, bank, duplicate contact, or bounds exit fails.
- `TrajectoryPrediction.is_fireable()` returns true only for `COLLISION`.
  Target, mechanism, and non-target collisions remain player-fireable choices;
  a bounds exit or timeout never is. Preview/HUD classify target-top as blue,
  a mechanism with its semantic color, and shell/apron/backstop as a coral miss
  marker. The arc always ends at the measured first collider and never displays
  a fictitious post-impact route.

### Contact, paint commands, and rasterization

- Extend `ProjectileContact` with `impulse_was_measured: bool`. Emit every begun
  `(collider_rid, collider_shape, local_shape)` key once. Every gameplay collider
  also exposes stable `contact_owner_id` and `contact_shape_id`: `terrain/top`,
  `terrain/shell`, `world/apron`, `world/backstop`, or
  `"mechanism/" + str(placement_index) + "/" + mechanism_kind_key`, followed by the named shape in the
  per-scene table. Emit in `(contact_owner_id, contact_shape_id, local_shape)`
  order. Preserve runtime RID/indices, world point/normal, projectile center,
  incoming velocity, impulse, provenance, and tick, but serialize stable IDs
  rather than process-local RIDs.
- Assign `contact_owner_id` as metadata on every gameplay `CollisionObject3D`
  and `contact_shape_id` on every named `CollisionShape3D`. Resolve a manifold's
  shape index with `shape_find_owner` then `shape_owner_get_owner`; missing or
  duplicate metadata is a blocking configuration error. Mechanism owner IDs use
  their index in the deterministically sorted generated-placement array
  `(route_role, route_t, kind)`. Runtime RIDs are diagnostic only.
- Replace `PaintDepositRequest` with two typed value objects:
  - `SurfacePaintSweep`: `physics_tick`, `spawn_ordinal`, `sequence`, `from_point`,
    `to_point`, `from_normal`, `to_normal`, `footprint_radius`, top collider RID,
    stable owner/shape IDs, collider shape, and `bridged_gap`.
  - `RadialPaintMark`: the same ordering/source identity plus `center`, `normal`,
    `radius`, and enum `IMPACT`, `SETTLE`, or `BURST`.
- Replace `PaintDepositTuning` with `PaintSurfaceTuning` at
  `resources/paint/default_paint_surface_tuning.tres`. It serializes mask size
  `512`, threshold byte `128`, core ratio `0.85`, maximum bridge ticks `2`,
  maximum bridge chord `10 m`, bridge sample spacing `0.5 m`, clearance `0.4 m`,
  normal delta `30 deg`, and ray span `1.0 m`. Projectile footprint/impact/
  settle radii remain explicit `ProjectileData` fields `4/9/4 m`; mechanism
  resources own Burst radius and Splitter child multiplier.
- `ProjectileManager` resets `spawn_ordinal` at shot start, assigns `0` to the
  parent, and monotonically assigns children in creation order. Producers submit
  intent with deterministic `source_event_index` from the stable contact order;
  they do not set `sequence`. The manager buffers one physics tick, sorts by
  `(physics_tick, spawn_ordinal, source_event_index,
  IMPACT<SWEEP<BURST<SETTLE, contact_owner_id, contact_shape_id)`, then alone
  assigns the next per-ordinal `sequence` and submits typed commands to
  `PaintSystem`. Mechanism marks inherit the activating projectile ordinal and
  contact event index.
- `source_event_index` is the zero-based index of the command's collider/shape
  key in that tick's complete stable-sorted current-contact list, not only the
  begun-contact list. Impact/sweep/settle uses the terrain-top index and a
  mechanism effect uses its activating mechanism index; absence of that key
  makes the intent invalid rather than assigning an arrival-order fallback.
- On a first valid target-top contact, emit an impact mark of radius `9.0 m` and
  establish the last contact. On consecutive contact ticks with the same top
  collider/shape, emit a sweep. On final settlement while still on target top,
  emit a settle mark of radius `4.0 m`; `max` blending makes an overlapping rest
  mark idempotent. Shell, apron, mechanism, and out-of-target contacts never
  create persistent paint.
- A missing-contact gap may be bridged only when it lasts at most 2 physics
  ticks, both samples have the same top collider/shape, chord length is at most
  `10.0 m`, and samples at no more than `0.5 m` spacing all pass: inside the
  target mask, absolute separation along the reconstructed surface normal
  `<=0.4 m`, adjacent normal angle `<=30 deg`, and a ray from the reconstructed
  point plus `Vector3.UP*0.5 m` to minus `Vector3.UP*0.5 m` returns the same top
  body on the terrain-only mask.
  If any test fails, leave the gap blank and start a new impact disc.
- Paint footprint radius is `4.0 m` for the parent and `3.12 m` (`0.78x`) for
  Splitter children. For every command, scan only its mask-space bounding box,
  reconstruct each candidate's 3D surface point, and use closest 3D distance to
  the segment or center. Full alpha (`255`) extends through `0.85r`; alpha falls
  linearly to `128` at `r`; outside is unchanged. Writes use bytewise `max`.
- Endpoint snapping maps local XZ to pixel-center coordinates
  `(uv * 512 - 0.5)`, rounds nonnegative values with `floor(value + 0.5)`, then
  clamps to `0..511`. Search outward at most 2 pixels in `(distance_squared,
  y, x)` order for a texel that is both target and inside that command's 3D
  footprint candidate set. A sweep applies only when both endpoints
  lie in the same 8-neighbour candidate component; otherwise apply independent
  valid endpoint discs and leave the segment blank.
- A flat/ramp fixture must measure an `8.0 m +/- 0.5 m` tangent-plane parent
  width and `6.24 m +/- 0.5 m` child width. Coverage remains XZ projection and
  is not corrected for slope area.
- Set `ProjectileManager.process_physics_priority=900`,
  `PaintSystem.process_physics_priority=1000`, and the StageController settlement
  observer priority to `1100`; lower priority runs first and a test asserts this
  order. The manager canonicalizes intents at 900. `PaintSystem` queues the
  resulting commands and drains at 1000, sorted by `(physics_tick,
  spawn_ordinal, sequence)`. It emits a drained tick
  and FNV-1a checksum. `StageController` seals a shot only after two inactive
  projectile ticks and a drain covering the last emitted command tick.
- The production `ProjectileData` normal-terrain baseline is radius `0.52 m`,
  mass `2.4 kg`, bounce `0.08`, friction `0.78`, linear damping `0.18`, and
  angular damping `0.35`. `TerrainTopBody`, `TerrainShellBody`, and the apron use
  the same explicit normal-terrain `PhysicsMaterial` pairing as the projectile
  fixture; no scene-local material may override bounce `0.08` or friction
  `0.78`. Backstop termination bypasses restitution by zeroing velocity after
  its first contact. On the fixed flat/ramp fixtures, the first post-impact
  normal speed is at most `10%` of incoming normal speed; on target slopes at or
  below `30 deg`, the ball returns to sustained contact, rolling, or settlement
  within `0.75 s` and makes no second ballistic arc whose center rises more than
  `1.5 m` above the reconstructed surface for longer than `0.25 s`. Maximum-
  speed `46 deg` impact still uses CCD and never penetrates. These values govern
  ordinary terrain, shell, and apron; a backstop terminates as specified above,
  and Bumper's explicit redirect is the only strong-rebound exception.
- Precompute 512-square surface points/normals/target bytes once per accepted
  layout. Reuse queue, component, visited-generation, and candidate buffers;
  clear `recent` only in accumulated dirty rectangles; update coverage on byte
  threshold crossings; upload the image no more than once per rendered frame.

The paint-drain performance fixture is exact. It configures the accepted base
Split Ridge layout, warms the same buffers for 60 unmeasured drain ticks, resets
paint without reallocating, then measures 600 drains with
`Time.get_ticks_usec()`. Ordinals `0..7` map to route roles
`SAFE,SPLITTER,BUMPER,SAFE,SPLITTER,BUMPER,SPLITTER,BUMPER`. Each 240-tick cycle
traverses graph `t=0.15..0.85`: cycle tick 0 emits an IMPACT mark at `t=0.15`;
each other tick emits one parent-radius sweep from the previous to current t.
Measured ticks 120 and 360 also emit one 14 m Burst mark at the Splitter pad.
All eight ordinals submit every tick through the real manager canonicalization
and PaintSystem drain. Sort the 600 microsecond durations and take zero-based
index 569 as p95; require p95 `<=4 ms`, maximum `<=8 ms`, stable checksum, and
the allocation/upload counters below. `tests/paint_queue_determinism_test.gd`
owns this fixture; no smaller substitute workload is allowed.

### Mechanism behavior and collision

- Burst keeps one charge and `0.35 s` cooldown and emits one terrain-aware
  `BURST` radial mark of radius `14.0 m`; remove amount and flow-step fields.
- Splitter emits exactly three generation-1 children, retains speed multiplier
  `0.78`, minimum route speed `22 m/s`, lift `5 m`, target `t=0.82`, and the
  `SAFE/SPLITTER/BUMPER` route-role order. Remove payload ratio; add the locked
  paint-footprint multiplier `0.78`. Recursion remains prohibited and the total
  active-projectile cap remains eight.
- Bumper retains its current desired-speed clamp `18..32 m/s`, incoming factor
  `0.85`, vertical lift `0.22`, infinite charges, and `0.8 s` cooldown. The
  displayed arrow and physical redirect use the same normalized downstream
  tangent.
- Against the off-white world, fixed active semantic colors are Burst amber
  `#F2B84B`, Splitter violet `#8A6BEA`, and Bumper coral `#E86A5B`. Burst and
  Splitter use spent `#9B96A6`; Bumper uses cooldown `#A68F8B`. Each active color
  is confined to the interactive core/band and matching preview/feedback;
  silhouette, icon, outlet count, and Bumper arrow remain independent cues so
  color is never the only distinction. Blue `#1678F2` remains reserved for
  paint and confirmed target-top impact, not a generic mechanism material.
- Burst, Splitter, and Bumper have world-space interactive diameters `6.0 m`,
  `7.0 m`, and `6.0 m`. At 1920x1080 they must project to at least 40 px in
  briefing and 26 px in aiming. Horizontal projection derives horizontal FOV as
  `2*atan(tan(vertical_fov/2)*aspect)`.
- Every gameplay-relevant visible part has a named owning collision shape whose
  AABB matches the visible part AABB in both directions within `0.10 m`.
  Labels, direction indicators, and particles are explicitly `visual_only` and
  cannot look like an impact face. Selection bodies stay on the briefing-only
  query layer and are absent from projectile/preview masks.
- Every placed mechanism stores one direct activation witness whose first
  collision is its real interactive body. Around that tuple, test the 27
  canonical combinations from yaw `-0.5/0/+0.5 deg`, elevation
  `-0.5/0/+0.5 deg`, and power `-2/0/+2%`; at least 9 must activate the same
  mechanism, and none may report a ghost shape. No mechanism collider may
  intersect the generated default-center trajectory.
- Balance is locked by outcomes rather than executor taste: one shot or one
  mechanism activation cannot clear Stage 2 or 3. The Phase 6 harness injects a
  test-only `MechanismEffectPolicy`; production and exported builds assert all
  three flags enabled. An ablation disables only the named effect after its real
  body contact: Burst emits no radial mark, Splitter spawns no children, or
  Bumper applies no velocity rewrite. Geometry, collision, cooldown/charge,
  state color, contact, activation signal, all other mechanisms, shot tuples,
  and ordering remain identical. The harness records the contact and activation
  plus `effect_suppressed=true`, and asserts the named paint/child/redirect
  output is absent.
- Under that exact policy, the frozen Stage 2 solution activates Burst and its
  Burst-off run stays below `27%`; the frozen Stage 3 solution activates both
  Splitter and Bumper, its Splitter-off and Bumper-off runs each stay below
  `70%`, and the safe-route-only sequence stays below `70%`. Full production
  sequences clear within `5/6` shots. Separate scene-state assertions compare
  the live material colors byte-for-byte with the active/spent/cooldown hex
  values above before contact, after activation, after cooldown, and after reset.
  Failed balance causes placement/effect verification and then replanning; it
  never authorizes a target reduction, hidden target hole, extra shot, or new
  special surface.

Per-scene visual/collision construction is fixed:

| Scene | Gameplay-visible parts | Physical mapping | Explicit visual-only parts |
| --- | --- | --- | --- |
| Burst | `Pedestal`: tapered 16-sided cylinder, bottom diameter `6.0 m`, top `5.0 m`, height `0.9 m`; `Lens`: solid sphere diameter `4.5 m`, center Y `2.15 m` | `BurstBase` cylinder radius `3.0 m`, height `0.9 m`; `BurstLens` sphere radius `2.25 m` | color bands painted on the Lens material, below-device label, particles; no free-standing torus |
| Splitter | `Base`: triangular prism circumradius `3.0 m`, height `0.7 m`, one point toward local +Z; `Crest`: same orientation, radius `2.4 m`, height `0.8 m`; jewel sphere radius `0.75 m`, center `(0,2.0,0)`; three outlet axes use yaw `-35/0/+35 deg` from local +Z, horizontal direction `(sin(yaw),0,cos(yaw))`, total length `3.4 m`, radius `0.35 m`, and center `direction*1.45+(0,1.4,0)` | one `ConvexPolygonShape3D` from exact Base+Crest vertices; three capsules with local Y axis rotated onto the listed direction and the identical center/radius/total height; jewel sphere with identical center/radius | below-device label and activation particles only |
| Bumper | `Base`: 16-sided cylinder radius `3.0 m`, height `0.8 m`; `Pad`: cylinder radius `2.4 m`, height `0.7 m`, center Y `1.15 m` | matching base/pad cylinders with the same centers and dimensions | thin navy direction arrow and below-device label; arrow sits above the physical pad and never looks like a blocking face |

Collision-layer values are fixed: terrain `1`, projectile `2`, mechanism body
`4`, briefing selection `8`, decoration `0`. Projectile and trajectory preview
query `1|4`; mechanism bodies mask `2`; selection bodies exist only on `8` with
mask `0`; briefing selection queries only `8`. Splitter's interaction envelope
is the horizontal circle of radius `3.5 m`; every listed visual/collider vertex
lies inside it, so its declared diameter is exactly `7.0 m`.

### Camera, trajectory, world art, and HUD

- Preserve `CameraDirector` and use Camera3D FOV `50 deg`, far plane `460 m`.
  Replace stage camera resources with the exact world-space bookmark table below;
  only the existing deterministic `1.5 m` terrain-clearance/line-of-sight
  correction may move a bookmark at runtime. Aiming composition at 1920x1080
  must place the target
  mountain inside 8%..92% horizontal and 10%..82% vertical screen bounds, with
  target terrain occupying 62%..84% of width and 45%..72% of height. The cannon
  occupies 9%..15% of width and 20%..32% of height in the lower-left and never
  obscures the Stage 1 route entrance.
- Replace the flat foreground plane with a faceted non-target apron derived from
  the terrain edge and containment boundary. Expose `8..14 m` of shell thickness
  in aiming views. Use scoreable dry top `#E6E4DE`, rear wall `#F7F3EC`,
  non-target shell/buttress `#C6C9C7`, apron `#D6D3CB`, background `#F5F0EA`,
  paint `#1678F2`, and navy `#10233D`; dry/paint roughness remains `0.88/0.24`.
  Pure white and unlit flat shading are prohibited: fixed faceted normals,
  directional light, self-shadow, and the listed off-white value separation
  must preserve the low-poly form.
- Use one world-space DirectionalLight3D with
  `rotation_degrees=(-38,-40,0)`, energy `1.15`, and
  `Color(1.0,0.95,0.84,1.0)`. The Environment uses solid background
  `#F5F0EA`, ambient color `Color(0.69,0.72,0.77,1.0)`, and ambient energy
  `0.34`.
  Compatibility shadows remain enabled. Terrain normals are faceted, not
  smoothed.
- In every bookmark and supported resolution, the projected rear wall overscans
  every viewport edge by at least `2%` except where physically occluded by the
  mountain, apron, or cannon. The wall is the six-face box/collider specified
  above, never a camera-facing quad. In aiming view the mountain exposes
  `8..14 m` of shell/buttress depth; across the briefing-to-aiming transition,
  foreground and far terrain landmarks must exhibit at least `8 px` relative
  parallax at 1920x1080. The coordinated evidence must show multiple lit face
  normals, ridge/valley occlusion, a wall join, and a cast/self-shadow so the
  distant target reads as a thick 3D object protruding from the wall.

Camera bookmark resources are exact:

| Stage | Briefing position -> target | Aiming position -> target | Wide position -> target | Result position -> target |
| --- | --- | --- | --- | --- |
| First Descent | `(92,62,24) -> (0,24,-112)` | `(5,3.2,18) -> (0,18,-102)` | `(82,52,8) -> (0,22,-112)` | `(-78,50,4) -> (0,22,-112)` |
| Burst Basin | `(-92,66,18) -> (0,28,-112)` | `(5,3.2,18) -> (0,22,-102)` | `(84,56,4) -> (0,24,-112)` | `(-82,54,0) -> (0,24,-112)` |
| Split Ridge | `(96,70,18) -> (0,30,-112)` | `(5,3.2,18) -> (0,24,-102)` | `(86,57,2) -> (0,26,-112)` | `(-84,55,-2) -> (0,26,-112)` |

`CameraDirector` derives no alternate base transform from screen metrics. If a
locked bookmark fails the composition gate after its safety correction, stop
for a plan revision rather than tuning it inside Phase 4.

- Trajectory dots are depth-tested camera-facing markers with 6 px diameter and
  17 px projected center spacing at the 1280x720 logical baseline, scaled with
  the UI stretch; maximum 60 dots. The final dot is always a measured first
  physical collision; bounds-exit/timeout predictions are non-fireable errors,
  not endpoints presented as hits. The 30 px impact ring is offset `0.05 m`
  along the measured normal, depth-tested, and colored by the target/mechanism/
  non-target classification above. No post-impact path or coverage prediction
  is shown.
- Mouse drag over the playfield changes yaw/elevation at `0.15/-0.12 deg` per
  physical X/Y pixel; A/D and W/S change their axis by `0.5 deg`, repeat after
  `0.30 s`, then every `0.08 s`. Yaw is `-45..45 deg`, elevation `10..68 deg`,
  and power `0..100%`; the shared canonicalization lattice is `0.1 deg / 1%`.
  Wheel and focused minus/plus change power by `1%` with the same hold timing.
  Space and Fire invoke the same guarded launch. Every stage begins and restarts
  at its generated `default_aim`, whose first collision is target top within
  `8 m` of the target centroid. The reachability/default solver is generation
  evidence and startup state only; it is never an aim hint, snap-to-target
  control, post-launch steering system, or player-facing solver.
- Set stretch aspect to `expand`. Use a full-rect CanvasLayer and Containers,
  never root absolute offsets. The logical baseline is 1280x720; safe margin is
  `max(16, round(24*viewport_width/1280))`. Baseline components are: stage card
  `118x48` top-left, mode chip `110x40` below it, target card `300x48` top-center,
  shots card `180x48` top-right, aim/power card `240x104` bottom-left, coverage
  card `480x56` bottom-center, restart `112x112`, and Fire `144x140` bottom-right.
- Surfaces use `#F7F3ED`, navy text, blue accent, radii `12..16 px`, one restrained
  shadow, labels 14 px, main metrics 22 px, buttons 20 px, and headings 18 px.
  No payload control, instructional paragraph, center modal, or debug text is
  visible while aiming. Every required control has keyboard focus styling.
- Layout gates cover `1280x720`, `1280x800`, `1366x768`, `1600x900`, and
  `1920x1080`, Korean and English. No visible control/text clips, overlaps,
  leaves its safe area, or occludes the launch-to-target corridor.
- `DeliveryCaptureRunner` is inert unless all four capture arguments are
  present exactly once: `--capture-screen`, `--capture-output`,
  `--capture-size`, and `--capture-locale`. Allowed screen values are
  `main_menu`, `stage_select`, `stage_briefing`, `aiming`, `stage1_mid_roll`,
  `stage1_settled`, `projectile_and_paint_roll`, `stage_clear`, and
  `stage_failed`; allowed locales are `ko/en`; allowed sizes are the five layout
  sizes above. Normalize the output path and require it to be inside either
  `.agents/evidence/gameplay-visual-reset/stage1` or `screenshots`. Reject a
  duplicate, unknown capture argument, unsupported value, or outside path.
  It switches to windowed mode, requests that exact
  viewport, waits until the viewport reports the requested pixels, and fails
  rather than going fullscreen or saving a mismatched image.

### Observation, replay, and persisted state

- Remove `initial_payload`, `current_payload`, `consumed_payload`, accepted
  amount, flow steps, and payload-derived settlement from projectile, manager,
  stage, observation, HUD, agent, debug, replay, resources, translations, and
  active tests.
- `ShotObservation` schema 4 contains shot index, yaw/elevation/power, ordered
  contacts with impulse provenance, ordered mechanism activations, child spawn
  ordinals, settlement reasons including `BACKSTOP`, coverage before/after/
  delta, paint command count, last drained tick, and final paint-mask FNV-1a
  checksum. Layout metadata contains the reachability checksum and generated
  default aim but never the per-target witness tuple array.
- Replay format 4 stores stage/profile versions, requested/accepted seed, height
  checksum, target-mask/reachability/containment checksums, generated default
  aim, ticked canonical actions, and expected schema-4 sealed observations.
  Format 3 is rejected rather than heuristically migrated.
- A fresh-process replay must produce the exact ordered contact/mechanism/child
  identity contract, final state, target checksum, and paint checksum. The
  existing positional tolerance may remain for reported floating-point contact
  points, but a checksum mismatch is a blocking defect and is never waived on
  the theory that `max` writes should commute.
- Save version and locale/unlock/result/settings migration remain unchanged
  unless code evidence proves a schema field actually changed. Replay changes
  do not authorize wiping saves.

### External-review disposition

Accepted: route-graph-first terrain, one generated layout/mask, continuous real
contact sweeps, all begun contacts, interior parity, batched paint work,
trajectory occlusion, corrected projection, preserved owners, and a Stage 1
vertical proof.

Modified: Claude's terrain and UI numbers are replaced by the fixed contracts
above; micro-gap bridging requires surface proof; graph migration names every
consumer; collision parity is per visible part; determinism is proved by stable
ordinals, a drain boundary, and fresh-process checks.

Rejected: `35/50/70` targets, route-proximity/slope masking of reachable target
terrain, solid-looking ghost decorations, payload conservation, downhill flow,
and an assumption that commutative writes alone prove replay determinism.

### 2026-08-03 user-direction disposition

Accepted as consistent with the planning/physics loop: every scoreable target
unit must be directly first-hit reachable within the legal manual aim domain;
the default shot lands near the target centroid; normal terrain uses low rebound;
the distant mountain remains a thick collidable 3D mesh; a bright physical rear
wall contains the current board; and the wall/terrain use a bright off-white
palette with visible faceting and shadow.

Interpreted to preserve the approved scope: “anywhere on the terrain” means the
entire scoreable `target_mask`, not the deliberately non-target shell, apron, or
backstop. “Special terrain” means the three already-approved physical mechanism
pads for this milestone; their helpful/risk-bearing behavior gets readability,
tolerance, and ablation gates, but no ice/sticky/booster/drain surface class is
invented. The player still aims manually and may choose a visible non-target
miss; the certificate never predicts post-impact paint coverage.

Deferred explicitly rather than left to implementation judgment: trajectories
that cross the cannon-visible rear silhouette into hidden terrain, an open rear
edge, and new surface-effect types. Supporting those later requires a separate
world/camera/physics design revision; the current wall is not a temporary
invisible hack and may not be removed during this plan.

## Tasks

### Phase 0: Align authority and introduce replacement contracts

Goal: make active instructions/specifications and typed schemas describe one
game before runtime behavior changes.

Preconditions:

- The user has instructed execution of this plan, thereby approving the exact
  one-line root `AGENTS.md` edit named above.
- The worktree is inspected and unrelated user changes are preserved.

Source owners: `AGENTS.md`, `docs/source-brief.md`, `docs/design-spec.md`,
`docs/technical-architecture.md`, `docs/test-checklist.md`, `.agents/Prompt.md`,
typed Resources/value objects under `src/stage_generation`, `src/projectile`,
`src/cannon`, `src/terrain`, and `src/paint`

- [ ] **0.1** Align active written authority without rewriting history.
  - Change: make the exact protected-line edit; add a clearly dated supersession
    note to `source-brief.md` without editing its verbatim original directive;
    replace finite-payload/flow language in active design, architecture,
    checklist, prompt, and documentation sections; add the target-wide direct
    reachability, generated default aim, rear containment, low-rebound, and
    mechanism-semantic decisions; retain historical plans and evidence as
    explicitly superseded records.
  - Accept: active docs agree on continuous contact paint, target-mask coverage,
    `4/27/70`, one mask authority, and the ownership table; source-brief original
    text and raw Claude review remain byte-unchanged below/within their recorded
    historical sections.
  - Guard: exactly one ExecPlan under `.agents/execplans` has `status: active`.
- [ ] **0.2** Add the version-4 typed contract skeleton.
  - Change: add generated graph node/edge/graph types, replace deposit request
    with surface-sweep/radial-mark types, add impulse provenance, version profile
    resources, add immutable `AimTuple`, `DirectReachabilityCertificate`, and
    `ContainmentSpec` values plus `TrajectoryHitIdentity` and `BACKSTOP`
    settlement, introduce compile-safe narrow queue/observation interfaces, and
    add `tests/version4_contract_test.gd`. Do not keep aliases for amount/payload
    or hand-authored initial-aim fields.
  - Accept: class registration/import passes; deterministic value-object tests
    cover validation, stable IDs, body-shape and terrain-triangle identity,
    barycentric/tie mapping, sort keys, snapping, and rejected invalid data.
  - Guard: the production scene remains launchable headlessly even before new
    behavior is wired.

Batch gate:

- Run `scripts/verify.ps1`; run the new contract tests; run `git diff --check`.
  Commit only Phase 0 files once all three pass.

### Phase 1: Prove one route, one real roll, and continuous paint

Goal: First Descent visibly and mechanically demonstrates the corrected game
before Stage 2/3 or broad presentation work continues.

Preconditions:

- Phase 0 acceptance and batch gate pass.

Source owners: `seeded_stage_generator.gd`, `generated_stage_layout.gd`,
`first_descent_profile.tres`, `terrain_geometry_factory.gd`,
`terrain_surface.gd`, `backstop_environment.gd`, `trajectory_predictor.gd`,
`direct_reachability_validator.gd`, `default_aim_solver.gd`,
`tools/stage_generation_certifier.gd`,
`paint_projectile.gd`, `projectile_manager.gd`, `paint_system.gd`,
`gameplay_scene.gd`, `StageController`, observation/replay/UI consumers required
for payload removal

- [ ] **1.1** Generate First Descent from the route graph.
  - Change: implement the fixed graph resolver and bounded support/carve pipeline;
    delete lobe synthesis from the production path; expose derived route queries
    from the graph while migrating consumers.
  - Accept: base/fallback/repeated generation is deterministic; Stage 1 has the
    exact chain, 0 reversals, accepted height/slope/target-ratio gates, and no
    lobe field influences any sample.
- [ ] **1.2** Make the Stage 1 target and solid geometry truthful.
  - Change: construct `target_mask`, derive top/skirt/bottom and top/shell bodies
    from the same heights, construct the exact apron/backstop render and
    collision, install the containment bounds, build the direct-reachability
    certificate and default aim, expose target/non-target material inputs,
    remove GameplayScene/HUD/StageData initialization writes in favor of the
    StageController layout handoff, and add vertex plus cell-interior render/ray
    parity and wrong-triangle rejection fixtures.
  - Accept: one target component reaches summit and exit; no slope or decoration
    exclusion exists; every target texel has its exact predictor witness and
    every distinct tuple reproduces the same real RigidBody first-contact
    body/shape/cell/triangle within `0.50 m`; the
    default first hit is within `8 m` of the target centroid on first entry and
    both restart paths; the analytic full-domain envelope and every required
    exact canonical-lattice check return no rear, side, upper, or lower bounds
    exit and first contact terrain, apron, backstop, or mechanism; every
    deterministic interior sample agrees within `0.05 m` and returns the
    expected top/shell/backstop body/shape/triangle identity.
  - Certify: after the non-writing test passes, run the certifier once with
    `--stage=first_descent --write-certificate=res://resources/stages/certificates/first_descent_v4.tres`,
    rerun it three times with `--verify-only`, and commit the resource only with
    identical evidence.
- [ ] **1.3** Produce complete contact events and contact-derived paint intent.
  - Change: emit every begun contact, maintain the current top-contact interval
    inside `_integrate_forces`, install the fixed low-rebound production tuning,
    implement the exact gap proof and backstop settlement, and create impact,
    sweep, and settle commands with stable ordinals/sequences.
  - Accept: flat, ramp, ridge, shell, airborne-hop, recontact, simultaneous-body,
    high-speed CCD, bounded-rebound, backstop, and settle fixtures report the
    expected ordered contacts and commands; no command uses `global_position`
    as a fabricated contact. The three locked wall launches satisfy the exact
    one-contact/zero-paint/zero-velocity/same-tick-retirement contract and cannot
    bank back into play.
- [ ] **1.4** Rasterize and drain continuous surface paint.
  - Change: add the late sorted queue, exact endpoint snapping/component rule,
    3D capsule/radial rasterization, threshold coverage, dirty batching, and
    drain/checksum signal.
  - Accept: flat/ramp widths meet contract, continuous contact has no unpainted
    centerline texel, a proven two-tick micro-gap paints continuously, a real hop
    stays blank, overlap counts once, and shader/coverage read identical bytes.
- [ ] **1.5** Remove finite-payload semantics end to end.
  - Change: remove fields and branches from projectile/resources, manager,
    StageController, observation, replay, agent, debug, HUD, translation, and
    tests; make settlement wait for paint drain; install schema/replay format 4.
  - Accept: targeted state/observation/replay/UI tests contain no payload facts;
    one physical Stage 1 shot seals after drain with matching paint checksum and
    leaves the player in the correct aiming/result state.
- [ ] **1.6** Pass the user-coordinated Stage 1 visual go/no-go gate.
  - Change: search the coarse lattice yaw `-45..45` step `5`, elevation `10..66`
    step `4`, power `40..100` step `5`, then the `+/-4 deg / +/-5%` neighbourhood
    of its best result at step `1`. A candidate must have a valid target-top
    contact, at least `25 m` of surface path, at least `0.75 s` total top contact,
    at least `4%` coverage, no penetration guard, and settlement within `18 s`.
    Select by coverage descending, surface path descending, contact duration
    descending, absolute yaw ascending, elevation ascending, power ascending,
    then signed yaw ascending. Re-run the selected tuple in three fresh processes
    and require identical height/target/paint checksums, event order, and result
    before storing it as the Stage 1 reliable solution. Add
    capture-runner keys `stage1_mid_roll` and `stage1_settled`, plus the fixed
    size/locale arguments above. Export and, only after explicit coordination,
    capture 1920x1080 aiming, mid-roll, and settled frames under
    `.agents/evidence/gameplay-visual-reset/stage1/`.
  - Accept: the mountain is a thick 3D target rather than a distant card; the
    ball visibly contacts and follows its surface; paint is continuous beneath
    the traversed path; the rear wall visibly contains the board; the default
    shot hits near center; rebound is short; collision and first-impact location
    are visually unambiguous. UI polish is not judged in this gate.
  - Guard: if the user rejects the Stage 1 proof, stop and revise this plan before
    expanding the other stages.

Batch gate:

- Targeted generation, terrain, contact, paint, state, and fresh-process replay
  tests pass, followed by `scripts/verify.ps1`. The approved Stage 1 evidence
  exists and records commit, engine, renderer, locale, resolution, seed, and
  shot tuple.

### Phase 2: Expand the graph terrain and safe placement to all stages

Goal: Stage 2/3 add real branches, rises/falls, pads, and readable placement
without weakening target-surface truth.

Preconditions:

- Phase 1 batch gate and Stage 1 visual approval pass.

Source owners: stage generation profiles/resources, `SeededStageGenerator`,
`GeneratedStageLayout`, reachability/default/containment owners, route-query
consumers, `mechanism_placement_generator`, `environment_dressing`,
generation/terrain/placement tests

- [ ] **2.1** Implement the frozen Stage 2 and Stage 3 graphs.
  - Change: migrate both profiles, shared summit/branch topology, edge IDs,
    pads, bounded support, target shoulders, reachability certificates, generated
    default aims, and deterministic checksums.
  - Accept: every stage passes its exact route count, role, width, reversal,
    height, slope, lip, ratio, component, and branch-reachability gate for base,
    repeat, attempt, and fallback paths; every accepted target texel also passes
    direct ballistic reachability with identical predictor and rigid-body
    certificate checksums.
  - Certify: write exactly `burst_basin_v4.tres` and `split_ridge_v4.tres` under
    `resources/stages/certificates/` with the same certifier arguments as Stage
    1, then require three fresh `--verify-only` passes for each before commit.
- [ ] **2.2** Enforce target and decoration policy for all layouts.
  - Change: eliminate decoration-based holes, place scale cues only outside all
    prohibited envelopes, and visually classify all non-target support.
  - Accept: no decoration AABB intersects target/route/pad clearance; no
    solid-looking uncollidable object appears on a reachable path; target bytes
    are independent of decoration seed/order.
- [ ] **2.3** Place mechanisms by graph role and correct projection.
  - Change: bind Burst/Splitter/Bumper to their typed pad nodes, validate slope,
    separation, line of sight, physical footprint, direct activation witness and
    9-of-27 tolerance neighbourhood, and corrected horizontal projection at
    every supported resolution.
  - Accept: required mechanism kind/role/pad is exact; projected-size and line-
    of-sight/activation-tolerance gates pass; no default-center path is blocked;
    invalid layouts are rejected, never repaired with authored X/Z coordinates.
- [ ] **2.4** Prove all geometry/query consumers use one layout.
  - Change: migrate placement, paint, replay metadata, agent height/route
    observations, camera queries, default aim, containment, and tests; remove
    obsolete route compatibility and initial-aim fields and every non-generator
    `StageRouteProfile` consumer after migration; make GameplayScene pass layout
    to StageController before its first restart and remove every other stage-
    initialization `set_aim`; `SeededStageGenerator` remains the sole consumer
    of route profiles as typed graph input.
  - Accept: static search finds no lobe field, secondary height computation,
    old eligibility term in active code, or authored production mechanism
    coordinate/initial aim; interior parity and physical containment pass all
    stages.

Batch gate:

- Run stage-generation, target-reachability, containment-wall, terrain-geometry,
  decoration-placement, mechanism-placement, camera-safety, and agent contract
  tests, then `scripts/verify.ps1`.

### Phase 3: Make mechanisms and multi-ball paint physically trustworthy

Goal: every visible gameplay object has truthful collision and every multi-ball
effect preserves contact, paint, ordering, and performance contracts.

Preconditions:

- Phase 2 acceptance and batch gate pass.

Source owners: `gimmick_base.gd`, mechanism scripts/scenes/resources,
`paint_projectile.gd`, `projectile_manager.gd`, `paint_system.gd`, mechanism,
contact, paint, reliability, and performance tests

- [ ] **3.1** Complete per-part mechanism collision and simultaneous contact.
  - Change: name visible/collision ownership, remove misleading impact faces,
    route all begun contact events, and preserve duplicate/cooldown guards.
  - Accept: each interactive visible part passes the `0.10 m` AABB containment;
    a tick beginning terrain plus mechanism contact both paints and activates
    exactly once; preview hits the same physical body/shape as runtime.
- [ ] **3.2** Convert Burst to amount-free radial paint.
  - Change: delete amount/flow tuning and emit one queued 14 m Burst mark through
    the activating projectile's ordering identity; apply the fixed amber/spent
    state materials without changing its real collision.
  - Accept: one charge, reset, cooldown, terrain connectivity, mask authority,
    command order, direct-hit tolerance, state color, and coverage union pass;
    Burst cannot paint shell/non-target or clear Stage 2 by itself.
- [ ] **3.3** Convert Splitter to three independent continuous painters.
  - Change: remove payload conservation, retain frozen motion/role targeting,
    assign stable child ordinals, apply the 3.12 m footprint, and apply the fixed
    violet/spent state materials.
  - Accept: exactly three generation-1 children, no recursion, cap eight, stable
    ordinal order, direct-hit tolerance, state color, continuous independent
    contact sweeps, and exact parent/child width fixtures pass.
- [ ] **3.4** Make Bumper collision and displayed redirect agree.
  - Change: preserve fixed velocity rule but drive it from the same body contact
    and downstream tangent shown by the navy arrow; apply the fixed coral/
    cooldown materials while retaining the normal-terrain low-bounce baseline.
  - Accept: exact body strike redirects once per cooldown into the intended
    route; direct-hit tolerance passes; glancing non-contact does not activate;
    state color passes; arrow/tangent/velocity angular error is at most `1 deg`.
- [ ] **3.5** Bound paint work under the worst multi-ball case.
  - Change: finish precomputation, scratch reuse, dirty-region clearing, one-
    upload batching, diagnostic timing/allocation counters, and
    `tests/paint_queue_determinism_test.gd`.
  - Accept: the exact 60-warm-up/600-drain Split Ridge fixture has zero full-mask temporary allocations per
    command, no full `recent` clear, at most one upload per rendered frame,
    paint drain p95 `<=4 ms` and maximum `<=8 ms`; overall memory/frame guards
    remain unchanged.

Batch gate:

- Run contact, projectile-paint, mechanism, reliability, and performance tests
  together, then `scripts/verify.ps1`. A fresh-process repeated multi-ball
  fixture must produce identical command order and paint checksum.

### Phase 4: Recompose the playable world around the reference

Goal: the generated geometry reads as a bright thick mountain, aiming reads
clearly, and mechanisms/trajectory/cannon have the intended visual hierarchy.

Preconditions:

- Phase 3 acceptance and batch gate pass.

Source owners: `gameplay.tscn`, terrain/backstop material and geometry,
foreground/dressing,
`camera_director.gd`, stage camera resources, `cannon.tscn`,
`trajectory_preview.gd`, mechanism scenes, approved committed art assets

- [ ] **4.1** Apply the fixed low-poly material, light, shell, and apron contract.
  - Change: replace the plane, expose shell, finish the six-face backstop and
    mountain/wall join, set the fixed off-white palette/roughness/light, preserve
    faceted normals and shadows, and use approved assets only as off-route scale
    cues or bounded effects.
  - Accept: scene/resource inspection matches every fixed value; wall projection
    overscan, `8..14 m` depth, `8 px` parallax, lit-face/shadow evidence, and
    render/collider identity pass; no plane hides shell thickness and the paint
    texture remains the authoritative visual input.
- [ ] **4.2** Recalibrate all camera bookmarks after terrain generation.
  - Change: replace every stage resource with the exact bookmark table and
    preserve only the existing clearance/line-of-sight correction.
  - Accept: analytic projection checks pass all stages/resolutions; no bookmark
    intersects terrain, clips a route/mechanism, or exceeds composition bounds.
- [ ] **4.3** Correct cannon scale and trajectory readability.
  - Change: fit cannon to its screen envelope; replace no-depth-test world
    spheres with depth-tested screen-consistent markers and the fixed impact
    ring.
  - Accept: predictor/runtime first impact remains within `2.0 m`; arc ends at
    the first collider, a bounds exit is not fireable, target/mechanism/miss
    rings classify the real collider, terrain occludes hidden markers, the
    impact point remains legible, and cannon/route screen bounds pass.
- [ ] **4.4** Finish mechanism silhouettes and feedback.
  - Change: size the three scenes to fixed diameters, preserve distinct
    Burst/Splitter/Bumper shapes, apply their exact amber/violet/coral state
    colors, map collision per part, and keep effects pooled and bounded.
  - Accept: world size, projected pixels, body mapping, idle/active/spent or
    cooldown feedback, and Korean label placement pass structural tests.
- [ ] **4.5** Add non-rendered composition evidence for the final visual gate.
  - Change: emit a revision-stamped JSON manifest of camera projections, screen
    rectangles, material/light values, target bounds, shell exposure, mechanism
    pixels/colors, wall overscan/depth/parallax, trajectory spacing/collision
    class, default-center hit, and cannon occupancy from
    `tests/composition_contract_test.gd`.
  - Accept: every fixed numerical contract passes for all stage/resolution
    fixtures; the manifest is stored under the current evidence revision.

Batch gate:

- Run camera-safety, trajectory, mechanism-placement, terrain-material, and
  composition-contract tests, then `scripts/verify.ps1`. Do not launch a visible
  game in this phase.

### Phase 5: Rebuild the Korean-first interface and causal feedback

Goal: the HUD matches the reference hierarchy, remains readable at non-16:9
desktop sizes, and explains physical outcomes without reviving payload data.

Preconditions:

- Phase 4 acceptance and batch gate pass.

Source owners: HUD component scenes/scripts, `hud_controller.gd`, global Theme,
translations, settings/pause/results, `project.godot`, observation/debug adapters

- [ ] **5.1** Rebuild aiming HUD roots with anchors and Containers.
  - Change: apply stretch/safe margins, fixed component sizes/positions,
    typography, palette, and focus states; remove remaining absolute root layout
    and payload widgets.
  - Accept: structure tests prove one component owner per card and the exact
    anchors/sizes; every required label/value/button is present and translated.
- [ ] **5.2** Make HUD feedback follow the sealed physical model.
  - Change: show stage/target/shots, yaw/elevation/power, live coverage/target
    marker, first-impact validity, mechanism callouts, and sealed shot summary
    from typed signals/observations only.
  - Accept: HUD never calculates coverage, predicts post-impact behavior, or
    decides fire/result; concurrent child balls and delayed queue drain cannot
    show a premature shot result.
- [ ] **5.3** Pass responsive localization and navigation gates.
  - Change: correct wrapping/minimum sizes across all supported resolutions and
    both locales; preserve settings/pause/result navigation and persistent locale.
  - Accept: automated rect/ancestor-clipping checks find zero clipping,
    intersection, overflow, corridor occlusion, untranslated key, or missing
    Pretendard glyph at all ten resolution/locale combinations.
- [ ] **5.4** Complete schema-4 replay, agent, and debug presentation.
  - Change: expose contact/sweep/drain/checksum facts without payload; keep
    replay-origin input isolation and debug-build-only overlay.
  - Accept: fresh-process record/replay, agent observation/action, debug export,
    persistence, and locale tests pass; format 3 rejection is explicit.

Batch gate:

- Run UI, localization, state, observation, agent, debug, persistence, and
  fresh-process replay suites, then `scripts/verify.ps1`.

### Phase 6: Prove fixed-target gameplay, determinism, and reliability

Goal: show that the corrected game is playable and stable without manipulating
targets, shots, score eligibility, or hidden paint values.

Preconditions:

- Phase 5 acceptance and batch gate pass.

Source owners: stage resources, solution search/test tools, state/content/replay/
reliability/performance tests, evidence records

- [ ] **6.1** Find and freeze one reliable physical solution per stage.
  - Change: run the existing resumable 60 Hz production-scene search against
    profile/stage version 4 and store exact yaw/elevation/power tuples in stage
    resources only after three fresh-process confirmations; also run the fixed
    Burst-off, Splitter-off, and Bumper-off `MechanismEffectPolicy` ablations
    without changing any tuple, collider, state transition, or non-named effect.
  - Accept: Stage 1 reaches at least 4% in 4 shots, Stage 2 reaches at least 27%
    in 5 with Burst activation, Stage 3 reaches at least 70% in 6 with Splitter
    and Bumper activation; each sequence passes three fresh processes with the
    same target/predictor-reachability/rigid-body-reachability/paint checksums
    and event order. No single shot or
    activation clears Stage 2/3; the Stage 2 Burst-off ablation stays below 27%;
    the Stage 3 Splitter-off and Bumper-off ablations and its safe route alone
    stay below 70%; every suppressed run contains the real activation but lacks
    only the named effect output.
  - Guard: do not lower targets, add shots, enlarge hidden footprints, remove
    target texels, or hand-author terrain/placement to obtain a solution.
- [ ] **6.2** Run full reliability and causality matrices.
  - Change: cover default-center fire/restart, full aim-domain containment,
    non-fireable bounds/timeouts, backstop settlement, bounded rebound,
    lifetime/settlement, contact chatter, simultaneous bodies, eight-ball cap,
    repeated mechanism activation, reset, stage progression, and no-leaked-node
    cases.
  - Accept: 30-cycle reliability, all stage results/unlocks, no projectile leaks,
    restart `<=50 ms`, no legal-domain rear/side/upper/lower escape or wall
    paint, all three wall tuples produce the exact one-contact `BACKSTOP`
    observation and same-tick zero/retirement behavior, and no result before
    final paint drain pass.
- [ ] **6.3** Pass final deterministic and performance matrices.
  - Change: run repeated base/fallback generation, replay record/read/cleanup,
    worst Burst/Splitter workload, and full ordered test runner. For the rendered
    1920x1080 performance case, start fresh Split Ridge, execute any reliable-
    solution tuples preceding the first Splitter-activating tuple to settlement,
    fire that tuple at time scale 1, discard 45 process frames, then measure 360
    consecutive process frames with `Time.get_ticks_usec()`; record maximum
    active balls, memory after the final frame, and coverage.
  - Accept: exact graph/height/target/paint checksums repeat across fresh
    processes together with predictor/rigid-body reachability, default, and
    containment certificates; load
    including certificate verification `<=3 s`, average `>=60 FPS`, no measured
    frame `>33.3 ms`, static memory `<=128 MiB`, paint drain gates pass, and
    active balls `<=8`.

Batch gate:

- `scripts/test.ps1`, then `scripts/verify.ps1`, then `git diff --check` all pass
  once at the frozen solution revision. Store long output under
  `.agents/evidence/gameplay-visual-reset/final-headless/`.

### Phase 7: Export, visually approve, and close documentation

Goal: verify the actual Windows build once, replace stale delivery evidence, and
close the plan truthfully.

Preconditions:

- Phase 6 acceptance and batch gate pass.
- The user explicitly coordinates the final visible session.

Source owners: export preset, delivery capture runner, `screenshots/`,
`docs/test-checklist.md`, `.agents/Documentation.md`, active specs and this plan

- [ ] **7.1** Build and smoke the production artifact headlessly.
  - Change: export `Windows Desktop` to `builds/windows/PaintMountain.exe` and
    run all checks that do not require a visible viewport.
  - Accept: export succeeds from a clean relevant input state; the artifact and
    embedded PCK exist; no editor-only/debug dependency is required.
- [ ] **7.2** Run the single coordinated final visual session.
  - Change: launch only the exported executable with the exact capture commands
    below. Capture the seven canonical 1920x1080 Korean-default states plus
    1280x800 Korean and English aiming frames. Record commit, binary hash,
    engine, renderer, locale, resolution, seed, state, and shot tuple in
    `screenshots/capture-manifest.json`.
  - Accept: direct inspection confirms the supplied-reference hierarchy; thick
    off-white 3D mountain visibly protruding from its solid wall, readable
    color-distinct mechanisms, small cannon, center-hitting default,
    depth-correct preview, short rebound, unambiguous ball contact, continuous
    bright paint, target boundary, and HUD all agree with this contract. No
    clipping, rear escape, or debug overlay appears.
- [ ] **7.3** Close records and remove obsolete active claims.
  - Change: update specs/checklist/documentation with measured results and known
    limitations, remove transient evidence not named by policy, verify fastrun
    still points to the exported executable, and mark this plan `done` only now.
  - Accept: all active docs describe implemented behavior; historical source,
    raw review, and superseded plans remain clearly classified; git status shows
    only intentional task-owned changes before the final scoped commit.

Batch gate:

- Final release screenshots and metadata exist and were inspected; production
  artifact starts through the existing fastrun command; `scripts/test.ps1`,
  `scripts/verify.ps1`, and `git diff --check` pass at the delivered commit.

## Validation and Rework Controls

Resolve Godot through the repository contract rather than a path owned by
another project. The executing shell must set `GODOT_BIN` or expose `godot4`/
`godot` on PATH; resolution and the exact 4.7.1 version check are mandatory:

```powershell
$paintMountainGodot = $env:GODOT_BIN
if ([string]::IsNullOrWhiteSpace($paintMountainGodot)) {
    $paintMountainGodotCommand = Get-Command godot4 -ErrorAction SilentlyContinue
    if ($null -eq $paintMountainGodotCommand) {
        $paintMountainGodotCommand = Get-Command godot -ErrorAction SilentlyContinue
    }
    if ($null -eq $paintMountainGodotCommand) {
        throw 'Set GODOT_BIN or add godot4/godot to PATH.'
    }
    $paintMountainGodot = $paintMountainGodotCommand.Source
}
$paintMountainGodot = (Resolve-Path -LiteralPath $paintMountainGodot -ErrorAction Stop).Path
$paintMountainGodotVersion = (& $paintMountainGodot --version | Select-Object -First 1).Trim()
if ($paintMountainGodotVersion -notmatch '^4\.7\.1\.stable') {
    throw "Paint Mountain requires Godot 4.7.1 stable; resolved $paintMountainGodotVersion"
}
```

Focused commands are exact and are selected by the task's named owners:

```powershell
& $paintMountainGodot --headless --path . --script res://tests/version4_contract_test.gd
& $paintMountainGodot --headless --path . --script res://tests/stage_generation_test.gd
& $paintMountainGodot --headless --path . --script res://tools/stage_generation_certifier.gd -- --stage=all --verify-only
& $paintMountainGodot --headless --path . --script res://tests/target_reachability_test.gd
& $paintMountainGodot --headless --path . --script res://tests/containment_wall_test.gd
& $paintMountainGodot --headless --path . --script res://tests/terrain_geometry_test.gd
& $paintMountainGodot --headless --path . --script res://tests/projectile_contact_test.gd
& $paintMountainGodot --headless --path . --script res://tests/projectile_settling_test.gd
& $paintMountainGodot --headless --path . --script res://tests/phase3_paint_test.gd
& $paintMountainGodot --headless --path . --script res://tests/phase3_projectile_paint_test.gd
& $paintMountainGodot --headless --path . --script res://tests/paint_queue_determinism_test.gd
& $paintMountainGodot --headless --path . --script res://tests/decoration_placement_test.gd
& $paintMountainGodot --headless --path . --script res://tests/mechanism_placement_test.gd
& $paintMountainGodot --headless --path . --script res://tests/phase5_mechanism_test.gd
& $paintMountainGodot --headless --path . --script res://tests/phase6_solution_test.gd
& $paintMountainGodot --headless --path . --script res://tests/aim_interaction_test.gd
& $paintMountainGodot --headless --path . --script res://tests/camera_safety_test.gd
& $paintMountainGodot --headless --path . --script res://tests/composition_contract_test.gd
& $paintMountainGodot --headless --path . --script res://tests/phase7_ui_test.gd
& $paintMountainGodot --headless --path . --script res://tests/localization_ui_test.gd
& $paintMountainGodot --headless --path . --script res://tests/phase4_state_test.gd
& $paintMountainGodot --headless --path . --script res://tests/shot_observation_test.gd
& $paintMountainGodot --headless --path . --script res://tests/phase8_debug_test.gd
& $paintMountainGodot --headless --path . --script res://tests/phase8_reliability_test.gd
& $paintMountainGodot --headless --path . --script res://tests/phase8_performance_test.gd
```

Fresh-process persistence and replay use their existing ordered write/read/
cleanup modes through `scripts/test.ps1`; do not improvise a parallel runner.

The following visible commands are permitted only at their two approval gates:

```powershell
$paintMountainExe = 'D:\npjt\paint-mountain\builds\windows\PaintMountain.exe'

# Phase 1 coordinated Stage 1 proof
& $paintMountainExe -- --capture-screen=aiming --capture-size=1920x1080 --capture-locale=ko --capture-output=D:/npjt/paint-mountain/.agents/evidence/gameplay-visual-reset/stage1/01_aiming.png
& $paintMountainExe -- --capture-screen=stage1_mid_roll --capture-size=1920x1080 --capture-locale=ko --capture-output=D:/npjt/paint-mountain/.agents/evidence/gameplay-visual-reset/stage1/02_mid_roll.png
& $paintMountainExe -- --capture-screen=stage1_settled --capture-size=1920x1080 --capture-locale=ko --capture-output=D:/npjt/paint-mountain/.agents/evidence/gameplay-visual-reset/stage1/03_settled.png

# Phase 7 coordinated final delivery
& $paintMountainExe -- --capture-screen=main_menu --capture-size=1920x1080 --capture-locale=ko --capture-output=D:/npjt/paint-mountain/screenshots/01_main_menu.png
& $paintMountainExe -- --capture-screen=stage_select --capture-size=1920x1080 --capture-locale=ko --capture-output=D:/npjt/paint-mountain/screenshots/02_stage_select.png
& $paintMountainExe -- --capture-screen=stage_briefing --capture-size=1920x1080 --capture-locale=ko --capture-output=D:/npjt/paint-mountain/screenshots/03_stage_briefing.png
& $paintMountainExe -- --capture-screen=aiming --capture-size=1920x1080 --capture-locale=ko --capture-output=D:/npjt/paint-mountain/screenshots/04_aiming.png
& $paintMountainExe -- --capture-screen=projectile_and_paint_roll --capture-size=1920x1080 --capture-locale=ko --capture-output=D:/npjt/paint-mountain/screenshots/05_projectile_and_paint_roll.png
& $paintMountainExe -- --capture-screen=stage_clear --capture-size=1920x1080 --capture-locale=ko --capture-output=D:/npjt/paint-mountain/screenshots/06_stage_clear.png
& $paintMountainExe -- --capture-screen=stage_failed --capture-size=1920x1080 --capture-locale=ko --capture-output=D:/npjt/paint-mountain/screenshots/07_stage_failed.png
& $paintMountainExe -- --capture-screen=aiming --capture-size=1280x800 --capture-locale=ko --capture-output=D:/npjt/paint-mountain/screenshots/08_aiming_1280x800_ko.png
& $paintMountainExe -- --capture-screen=aiming --capture-size=1280x800 --capture-locale=en --capture-output=D:/npjt/paint-mountain/screenshots/09_aiming_1280x800_en.png
```

Phase 0 renames the obsolete capture state `projectile_and_paint_flow` to
`projectile_and_paint_roll`; no active file or canonical screenshot keeps the
old flow term.

| Cadence | Exact check | Run when | Do not rerun until |
| --- | --- | --- | --- |
| Inner loop | Run the applicable exact focused command from the list below | A task changes behavior owned by that focused test | Relevant task input changes |
| Script/scene/resource/settings smoke | `powershell -NoProfile -ExecutionPolicy Bypass -File scripts\verify.ps1 -GodotPath $paintMountainGodot` | After each coherent implementation checkpoint touching those file types | Relevant project input changes |
| Phase gate | The named focused tests followed by the smoke command | All tasks in that phase pass | A phase-owned input changes |
| Full headless gate | `powershell -NoProfile -ExecutionPolicy Bypass -File scripts\test.ps1 -GodotPath $paintMountainGodot` | Phase 6 and final closeout | A test/runtime input changes |
| Export gate | `& $paintMountainGodot --headless --path . --export-release 'Windows Desktop' 'builds\windows\PaintMountain.exe'` | Phase 1 visual proof and Phase 7 | An export/runtime input changes |
| Documentation gate | `git diff --check`; `rg -l '^status: active$' .agents/execplans` returns only this plan | Every documentation checkpoint | A document changes |
| Visible Stage 1 gate | `& '.\builds\windows\PaintMountain.exe'` with the agreed capture arguments | Only after the first explicit coordination | Never automatically |
| Visible final gate | Existing seven `DeliveryCaptureRunner` state commands, with custom flags after `--` | Only after final explicit coordination | Never automatically |

Validation rules:

- Run the narrowest check that proves the current task and the named phase gate
  once after its tasks pass. Do not use visible runs as an inner loop.
- After any script, scene, resource, shader, or project-setting change, the
  required smoke check is `scripts/verify.ps1`.
- `scripts/test.ps1` owns its fresh-process persistence/replay cleanup. If a
  focused run is interrupted, use its explicit `--mode=cleanup` command before
  rerunning; do not delete broad user directories.
- Every task or phase gets one scoped commit containing only task-owned files.
  Preserve unrelated work; never reset, clean, stage, or revert it.
- Store large logs/JSON/interim images under
  `.agents/evidence/gameplay-visual-reset/` in the fixed phase subfolder. Only Phase 7 writes the
  canonical `screenshots/` filenames.
- A numeric gate failure authorizes correction of an implementation defect
  against the locked algorithm. It does not authorize tuning the gate, product
  target, mask semantics, or visual hierarchy.

## Predetermined Contingencies and Change Control

| Trigger | Required response | Boundary or escalation point |
| --- | --- | --- |
| User has not approved the exact protected instruction edit | Keep this plan active and stop before Phase 0; state the exact one-line change | Do not edit root `AGENTS.md` implicitly |
| A verified material fact contradicts this contract | Stop the affected branch, record evidence, update this contract, and obtain required approval | Executor may not choose a new product, architecture, data, UX, or validation contract |
| Base attempts fail generation | Run the pinned fallback once; if it fails, correct implementation against the fixed graph/support algorithm | No authored layout, lobe fallback, target-mask deletion, or threshold retuning |
| Any target texel lacks a direct first-hit witness | Verify canonical input, shared predictor, triangle identity, and candidate ordering; reject the attempt, then run the pinned fallback | Never remove/hide the texel, enlarge `0.50 m`, expose witnesses as auto-aim, or accept mechanism-first reachability; replan if fallback fails |
| Default aim misses target or lands more than `8 m` from its centroid | Trace target centroid, certificate ordering, and StageController restart application | Do not hand-author an initial tuple or silently choose a different target anchor |
| A legal aim exits through any rear, side, upper, or lower bound or passes through the wall/apron | Verify conservative envelope, wall/apron dimensions, collision layers, stage bounds, and predictor/runtime parity in that order | No invisible kill plane, larger projectile, bounds-as-hit classification, or camera concealment; stop and replan if the fixed containment is insufficient |
| Route graph passes metrics but reads as a wall in Stage 1 evidence | Reject the vertical slice and replan geometry/composition from evidence | Do not build Stage 2/3 or hide the issue with camera/UI |
| Off-white mountain still reads as a flat card | Verify six-face backstop, mountain/wall join, shell exposure, faceted normals, light/shadow, camera projection, and parallax in that order | Do not substitute a billboard, dark gray palette, texture-only fake depth, or uncollidable visual mass; replan after defects are excluded |
| Render, collider, or surface-query samples differ | Stop and make all three consume the same heights/triangle diagonal | No offsets, larger projectile, or paint compensation |
| A gap paints without the full clearance/ray proof | Reject the bridge and trace contact identity/sample order | Never paint an unproved airborne chord |
| A real continuous roll leaves a blank centerline | Fix contact interval, snapping, component, or queue implementation in that order | Do not enlarge radius or lower coverage threshold |
| Fresh-process paint checksum differs | Compare seed/layout, spawn ordinals, emitted command tuples, sort/drain order, then raster bytes | Do not waive exact mask identity or claim commutativity is proof |
| Mechanism preview/visual/body/runtime contact disagree | Remove query-only geometry from projectile masks and fix per-part mapping | Do not use a large union collider or ghost trigger |
| A mechanism fails color, activation-tolerance, or ablation balance | Verify state material, real body mapping, pad placement, effect execution, and recorded solution in that order | Do not add a new special surface, lower targets, add shots, hide terrain, or tune an unlisted value; replan after defects are excluded |
| Normal projectile rebound exceeds the locked gate | Verify resource wiring, material combination, contact normal, CCD, and fixture geometry | Keep Bumper isolated as the only redirect exception; if engine-correct behavior still fails, stop for a numeric plan revision rather than ad hoc tuning |
| A fixed target has no reliable physical solution | Verify contact/paint first, graph/target surface second, mechanism behavior third, search fourth | After defects are excluded, stop and replan; do not lower target/add shots/hide terrain |
| Paint performance misses its gate | Reuse arrays, reduce dirty work, batch uploads, and cache surface candidates in that order | Mask/grid/footprint/threshold/gameplay values remain fixed; dependency changes require approval |
| UI clips or covers gameplay | Fix container flags, anchors, wrapping, and minimum sizes | Do not shrink body text below 14 px or remove required controls |
| A visual metric passes but the coordinated image still fails the reference hierarchy | Treat the image review as the higher gate and replan the affected visual contract | Do not mark complete from structural metrics alone |
| User postpones a visible session | Stop at the named gate, leave its checkbox unchecked, and report headless status | Never launch, keep open, or repeatedly foreground Godot |
| Task-owned visible process does not exit | Stop that exact process by recorded PID and report it | Never kill by process name |
| Configured Godot executable or export templates are absent | Stop and request the installed Godot 4.7.1 console/template path | Do not download/copy an engine or alter dependencies |
| An approved asset is missing or unsuitable | Use procedural/current committed visuals within the locked style | Do not fetch a replacement pack without new approval |

Implementation-local discoveries may be handled inside the locked contract only
when they cannot change scope, visible behavior, ownership, architecture,
safety, persistence, or acceptance.

## Progress and Next Steps

- Canonical progress: the task checkboxes in this contract.
- Current phase: approval gate before Phase 0.
- Next task: 0.1 after the user instructs execution of this plan.
- Last completed gate: Discovery Closure Gate; raw Claude guidance was validated
  against current code, the later reachability/containment direction was
  independently reviewed against the game loop, and all readiness decisions are
  locked here.
- Carried-forward implementation foundations: immutable generated layout,
  heightfield/top+shell geometry owner, real rigid-body projectile, physical
  mechanism bodies, manual aim, first-collision predictor, camera safety,
  replay isolation, Korean localization/theme/components, headless runner,
  export preset, and fastrun command. These are starting code, not accepted
  final behavior.
- Update rule: after a checkpoint passes, append concise commit/test/evidence,
  check the task, and advance this pointer in the same edit. Never overwrite the
  superseded plan's historical progress.

## Completion and Stop Conditions

Complete when:

- Every task acceptance, guard, phase gate, and final gate in this contract
  passes and the user has approved both visible checkpoints.
- One generated graph/layout supplies all terrain, collision, target, paint,
  direct-reachability/default-aim/containment, placement, replay, and agent
  queries; no lobe or authored repair path remains.
- Every target texel has a legal manual first-hit witness, every restart predicts
  a target-top hit within `8 m` of center, and every legal aim ends at visible
  collision rather than escaping the rear/upper containment.
- A physical rolling/sliding ball paints a continuous 3D surface sweep for every
  target-top contact interval, satisfies the low-rebound gate, and never paints
  an unproved airborne gap or the backstop.
- All begun contacts are reported, all visible gameplay masses have truthful
  collision, and Burst/Splitter/Bumper pass their fixed contracts.
- Shader appearance and `4/27/70` coverage come from the same mask; all physical
  solution/replay/reliability/performance checks pass.
- Korean-default HUD, camera, trajectory, cannon, off-white wall/terrain, and
  color-distinct mechanisms pass all structural and running-image gates against
  the supplied reference.
- The Windows build exports, starts through the existing fastrun command, and
  final evidence/docs truthfully describe the delivered revision and limits.
- No placeholder, unresolved material choice, obsolete active claim, or
  unrelated staged change remains; this frontmatter becomes `status: done` only
  after the final scoped commit.

Replan when:

- A material discovery invalidates a locked product, topology, paint, collision,
  reachability, containment, persistence, performance, or visual contract.
- Stage 1 or final coordinated visual evidence fails after implementation defects
  within the current contract are excluded.
- A fixed target remains unsolved after the required ordered defect audit.
- The exact direct-reachability solver cannot certify a fallback layout, the
  containment envelope cannot prevent rear/upper escape, or the mechanism
  tolerance/ablation contract cannot coexist with the fixed targets and shots
  after implementation defects are excluded.

Stop immediately and report rather than widening scope when completion would
require a new dependency/asset, target reduction, shot increase, new content,
destructive operation, unapproved protected-file change, or unapproved visible
application launch.

Do not replan or stop for implementation-local mechanics already contained by
this contract, or for a passing check whose relevant inputs have not changed.
