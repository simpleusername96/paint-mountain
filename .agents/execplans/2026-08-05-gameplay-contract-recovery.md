---
type: plan
status: active
created: 2026-08-05
last_reviewed: 2026-08-05
scope: truthful thirty-stage terrain progression, summit reachability, usable immediate re-aiming, and projectile-to-paint scale recovery
source: source brief plus user QA and corrections through 2026-08-05
supersedes:
  - 2026-08-05-physical-gameplay-mvp.md
  - 2026-08-05-rapid-fire-thirty-stage-progression.md
  - 2026-08-05-runtime-grounded-interface.md
related:
  - ../PLANS.md
  - ../Documentation.md
  - ../evidence/2026-08-05-gameplay-contract-gap-audit.md
  - ../../AGENTS.md
  - ../../docs/source-brief.md
  - ../../docs/design-spec.md
  - ../../docs/technical-architecture.md
  - ../../docs/test-checklist.md
  - ../design/DESIGN.md
---

# Gameplay Contract Recovery - Execution Contract

This is the sole active Paint Mountain ExecPlan. It replaces three plans whose
progress prose and implementation diverged from their unchecked tasks. Execute
the phases in order. Do not preserve a shortcut merely because commit `f13927a`
described it as complete.

## Purpose

- Objective: make thirty stages become visibly and structurally harder in small
  steps, guarantee a legal first physical hit on each stage's highest playable
  top region, make the second shot genuinely aimable while the first moves, and
  converge the visible ball and paint footprint to a believable contact scale.
- Deliverable: one versioned deterministic stage catalog, certified summit and
  target reachability, one live AIMING board phase with orthogonal shot-family
  activity, one authoritative Fire-readiness surface, corrected projectile/paint
  tuning, and production-style off-screen evidence for the exact reported gaps.
- Completion state: all locked contracts and focused acceptance gates pass; the
  Windows release is rebuilt; current records no longer overclaim; and the user
  can perform the final foreground play review without the agent opening a
  visible Godot window.

## Authority and Verified Starting State

Authority order:

1. `docs/source-brief.md`, including the dated 2026-08-03, 2026-08-04, and
   2026-08-05 clauses.
2. The current user's four reported failures and request for a replacement plan.
3. `docs/design-spec.md` and `docs/technical-architecture.md` after their contract
   alignment in this planning change.
4. This plan for implementation order and exact recovery choices.
5. Current code only as the starting point; historical completion prose is not
   evidence.

The verified gap analysis is
[`../evidence/2026-08-05-gameplay-contract-gap-audit.md`](../evidence/2026-08-05-gameplay-contract-gap-audit.md).
Its conclusions are frozen inputs:

- Stages 04 and 05 clone First Descent, retain fixed version-5 geometry, have no
  mechanisms, and differ mainly by seed and `0.6 m` nominal peak.
- No code identifies or certifies the global summit; runtime solves only one
  centroid-near target point.
- Two direct controller Fire calls can coexist, but Fire hides the trajectory,
  moves the camera away from the cannon, and exposes no truthful readiness
  reason after a changed aim.
- The current `0.60/2.25/3.20/2.25 m` scale is implemented consistently but is
  still visually rejected and unsupported by a controlled rendered-width gate.
- The three predecessor plans have `0` checked tasks and contradictory progress
  claims. They are historical inputs, not executable authorities.

## Scope and Non-Goals

In scope:

- Stage 01 through Stage 30 generation inputs, committed catalog/resources,
  accepted seeds, previews, routes, macro terrain features, mechanisms,
  decorations, targets, shots, and progression evidence.
- Shared top topology, summit selection, legal aim solving, predictor/rigid-body
  witness verification, certificates, default aim, containment, and reliable
  solution admission.
- Parent/child projectile physical radius, collision/prediction parity, impact/
  sweep/settlement paint radii, and authoritative-mask width evidence.
- StageController board phase, two-family Fire admission, prediction freshness,
  human input, HUD readiness, trajectory visibility, and camera behavior needed
  for immediate re-aiming.
- Exact focused tests, deterministic builder checks, production export, and
  off-screen Compatibility-renderer captures.
- Removal of superseded template-cloning, weak smoke assertions, serial live
  states, stale readiness branches, and false implemented-status claims after
  their replacements pass.

Out of scope:

- New mechanism kinds, steering a fired ball, caves/overhangs/destruction,
  renderer changes, plugins, dependencies, online services, or new asset packs.
- Redesigning menu, stage-select, pause, settings, result, typography, or general
  art direction beyond data/readiness changes required by this plan.
- Broad performance optimization, historical test resurrection, or error tuning
  that does not block these four player-visible contracts.
- Foreground Godot/editor automation. The user alone owns final visible desktop
  play; agent-rendered evidence uses the existing background capture path.

## Locked Vocabulary and Semantic Alignment

- **Stage Number** is the integer `n` in `1..30`. Stable IDs become `stage_01`
  through `stage_30`; the three legacy IDs remain read-only migration aliases.
- **Progression Profile** is the immutable typed data computed for one Stage
  Number. It is not a legacy stage template and contains every stage-dependent
  generation, content, and rule input.
- **Macro Complexity** means broad ridges, passes, basins, route count,
  meaningful grade reversals, and undulation amplitude. Seeded noise is surface
  variation and never counts as difficulty.
- **Adjacent Progression** means every `n -> n+1` pair has a strictly increasing
  locked difficulty score, unique geometry checksum, bounded scale delta, and a
  nontrivial normalized height-field difference. It does not mean every single
  metric increases on every stage.
- **Playable Top** is the indexed top-triangle set shared by rendering,
  collision, queries, target rasterization, and paint reconstruction. Shell,
  apron, wall, and bottom are excluded.
- **Summit Region** is the set of Playable Top triangles having at least one
  vertex within `0.25 m` of the global maximum Playable Top vertex height.
- **Summit Reachability** is one legal manual aim whose predictor and real
  rigid-body first terrain contact land on the Playable Top within the
  authoritative `2.10 m` impact mark of a Summit Region sample, with contact
  height no more than `1.0 m` below the global maximum. The stable Summit
  Region identity remains separate from the centroid default witness.
- **Target Reachability** remains the stronger scoreability rule: every target
  texel maps to a Playable Top first-hit witness whose `2.10 m` impact mark
  covers that texel. Exact sampled-triangle identity is not required when the
  adjacent-facet contact is still inside the authoritative impact footprint.
  The target rasterizer remains unchanged; any occlusion or unreachable target
  must reject the candidate rather than silently deleting scoreable pixels.
- **Board Phase** is a mutually exclusive StageController phase. Shot motion is
  not a Board Phase.
- **Aim Editable** means human/replay/agent/debug origin rules permit changing
  the next yaw/elevation/power tuple. It remains true at two-family capacity.
- **Prediction Pending** means the current tuple has changed but a prediction
  with the same stable aim key has not arrived. It disables Fire, not aiming.
- **Fire Ready** means Aim Editable, a matching fireable prediction, at least one
  shot, one free root-family slot, no terminal pending, and no modal/origin lock.
- **Physical Radius** controls visible sphere, collider, CCD, prediction, contact
  offset, and summit/target certification. **Paint Radius** controls only the
  authoritative reconstructed mask mark or sweep.

## Architecture and Ownership

| Owner | Owns after recovery | Must not own |
| --- | --- | --- |
| `StageProgressionData` typed Resource | Exact formulas, bands, IDs, rule values, macro counts, sizes, and progression score | Runtime generation, UI, or mutable state |
| `scripts/build_stage_catalog.gd` | Offline 32-candidate build, validation, accepted-seed/certificate/preview output, atomic manifest promotion | Runtime search or hand repair |
| `StageCatalogData` / `StageCatalog` | Immutable catalog membership/order/lookup and legacy ID aliases | Profile synthesis or terrain generation |
| `SeededStageGenerator` and synthesizers | One layout from one complete per-stage profile/accepted seed | Catalog policy, Fire rules, paint state, or runtime candidate search |
| `GeneratedStageLayout` | Shared top/target identities, summit region, immutable metrics, placements, and certificate handoff | Mutable paint or stage decisions |
| `DirectReachabilityValidator` / certificate | Target-wide and summit predictor/rigid-body witnesses plus checksums | Default UI hints, target deletion, or runtime solving |
| `ProjectileData` / `PaintProjectile` | Shared physical and paint scale plus measured contact intents | Persistent mask or coverage |
| `PaintSystem` | The only mutable paint mask, visible texture, and coverage | Separate trails/coverage or projectile physics |
| `StageController` | Board phase, shots, root-family/terminal admission, authoritative readiness snapshot, clear/fail/restart | Input devices, camera transforms, prediction calculation, or HUD formatting |
| `CannonController` / predictor | Current aim, matching-key prediction status, launch origin/velocity | Fire admission, camera, or stage outcomes |
| `AimInputController` | Human device mapping and immediate next-aim events | Capacity, terminal, or outcome decisions |
| `CameraDirector` | Explicit CANNON/FOLLOW/WIDE presentation modes | Aim legality or automatic post-Fire state decisions |
| `HUDController` | Render StageController readiness and emit typed intents | Recalculate capacity/prediction/terminal policy |

## Locked Recovery Contracts

### 1. Version and catalog boundary

- Introduce contract version `7` for StageData generation/profile/layout and
  `DirectReachabilityCertificate`. Version `7` distinguishes corrected material
  from the current StageData-6/profile-5 mismatch. Replay format remains `7` but
  records and verifies the corrected stage/profile/layout/certificate versions.
- Replace `StageProgressionData extends RefCounted` with a typed `Resource` at the
  same path and add its sole production instance at
  `resources/stage_generation/version7_progression.tres`.
- Add `StageCatalogData` at `src/stage/stage_catalog_data.gd` and
  `resources/stages/catalog.tres`. `StageCatalog` loads this resource; it no
  longer clones `BASE_STAGE_PATHS`, calls `profile_band()`, or synthesizes
  profiles in `get_stage()`.
- Build and commit one content-addressed bundle at
  `resources/generated_stage_catalogs/v7-<manifest_sha256>/` containing
  `stages/stage_01.tres` through `stage_30.tres`, matching `profiles/`,
  `certificates/`, and thirty `768 × 432` real-stage `previews/`.
  `resources/stages/catalog.tres` is the only stable pointer to that bundle.
- Candidate seed `k` for Stage Number `n` is exactly
  `1_347_223_552 + 1_000_003*n + 7_919*k`, with `k` in `0..31`. The builder
  processes stages in numeric order and accepts the first candidate that passes
  every per-stage gate plus adjacency against the already accepted predecessor.
  It does not draw an unrecorded seed or retry at runtime.
- `--write` first emits the complete bundle under
  `resources/generated_stage_catalogs/.v7-<manifest_sha256>.staging/`, validates
  it twice, renames that directory to its final content-addressed name, writes
  `resources/stages/catalog.tres.next`, and replaces the catalog pointer last.
  The old bundle and pointer remain valid until that final same-directory
  replacement. Any earlier failure deletes only the positively identified
  staging directory and exits nonzero.
- Runtime reconstructs exactly one selected layout from its persisted accepted
  seed and verifies height/target/placement/containment/certificate checksums. It
  never searches candidates or changes the accepted seed.
- Legacy `first_descent`, `burst_basin`, and `split_ridge` map to `stage_01`,
  `stage_02`, and `stage_03` only at save/replay/catalog migration boundaries.
  New runtime observations use canonical numeric IDs.

### 2. Exact thirty-stage progression

Let `t = (n - 1) / 29`. `round_even` means nearest even integer with exact ties
upward; `round_half` means nearest `0.5` with exact ties upward.

| Input | Exact value |
| --- | --- |
| Terrain X metres | `round_even(180 + 60t)` |
| Terrain Z metres | `round_even(120 + 40t)` |
| Cell X | `round_even(72 + 24t)` |
| Cell Z | `round_even(48 + 16t)` |
| Nominal peak metres | `round_half(72 + 54t)` |
| Route stations | `8` for 01–09, `9` for 10–19, `10` for 20–30 |
| Route count | `1` for 01–07, `2` for 08–17, `3` for 18–30 |
| Reversals per route | `0` for 01–03, `1` for 04–11, `2` for 12–21, `3` for 22–30 |
| Broad ridges | `3 + floor((n - 1) / 5)` |
| Wide basins | `0` for 01–06, `1` for 07–16, `2` for 17–30 |
| Broad passes/macrowaves | `0` for 01–05, `1` for 06–13, `2` for 14–21, `3` for 22–30 |
| Route undulation amplitude | nearest `0.1` of `2.0 + 6.0t` metres |
| Base route width | nearest `0.5` of `28.0 - 10.0t` metres; one safe route is `+4 m` |
| Decorations | `10 + round(22t)` |
| Noise | simplex-smooth FBM, frequency `0.035`, 2 octaves, amplitude `0.50 m`; never a difficulty input |

Mechanism count preserves the original teaching stages and then grows without
cluttering the early boards:

- Stage 01: `0`.
- Stage 02: `1` Burst.
- Stages 03–06: `2`; Stage 03 is Splitter plus Bumper.
- Stages 07–12: `3`; 13–18: `4`; 19–24: `5`; 25–30: `6`.
- From Stage 04 onward, slot kinds cycle Burst, Splitter, Bumper by
  `(n - 4 + slot_index) mod 3`. Slots distribute round-robin across routes, stay
  at least `18 m` apart and `12 m` from summit/route exits, and retain the existing
  Burst/Splitter/Bumper pad radii `8/10/9 m`.
- Slot indices take normalized route positions in this exact order:
  `0.22, 0.38, 0.54, 0.68, 0.80, 0.30`. After round-robin route assignment,
  slots are sorted by normalized position on each route before edge splitting.

Profile materialization is deterministic and contains no authored per-stage
coordinates:

- `KeyedStageSampler` remains the sole sampler and is upgraded to the exact
  call-order-independent version-7 mapping
  `u = (FNV1a32(UTF8("paint_mountain:" + stage_id + ":v7:" + seed + ":" + field_key)) & 0x7fffffff) / 2147483647.0`, using offset basis
  `2166136261` and prime `16777619`; `sample_range(a,b) = lerp(a,b,u)`.
  Route keys are `route/<route>/edge/<edge>/grade` and
  `route/<route>/node/<station>/x`; macro keys are
  `range/backbone/<field>`, `range/ridge/<index>/<field>`,
  `range/summit/<index>/<field>`, `range/basin/<index>/<field>`,
  `range/pass/<index>/<field>`, and `range/wave/<index>/<field>`. No shared RNG
  stream or iteration-order draw is permitted. Version-7 golden unit vectors are
  fixed below; implementation compares hashes exactly and unit values to `1e-9`
  before the first catalog
  build:

  | Stage / candidate-0 seed | Field key | FNV-1a hash | Unit value |
  | --- | --- | ---: | ---: |
  | `stage_01 / 1348223555` | `range/backbone/x` | `2549627590` | `0.187262865802` |
  | `stage_04 / 1351223564` | `route/0/edge/0/grade` | `1282551704` | `0.597234677801` |
  | `stage_05 / 1352223567` | `range/ridge/2/height` | `2347213862` | `0.093006628609` |
  | `stage_18 / 1365223606` | `range/basin/1/depth` | `2072819545` | `0.965231818131` |
  | `stage_30 / 1377223642` | `range/wave/2/phase` | `3665977241` | `0.707103681614` |
- For `s` route stations, station `j` uses
  `z = -Z/2 + 16 + j*(Z-32)/(s-1)`. Route endpoints are `[0]`,
  `[-0.18X, +0.18X]`, or `[-0.28X, 0, +0.28X]` for one, two, or three routes.
  Route 0 is the safe route at base width `+4 m`; all other routes use base
  width. Interior lateral bends use the keyed range
  `[-(8+4t), +(8+4t)] m`; adjacent station X delta remains `<= 18 m`.
- World terrain center is exactly `(0, -2, -172 + Z/2)`, keeping the rear
  terrain edge at `z=-172` and the existing `0.25 m` join to the wall front at
  `z=-172.25`. The cannon transform remains `(0, -1.875, 5)`; growth therefore
  extends gradually toward the cannon while the rear wall and launch reference
  stay stable.
- Let `e = s-1` edges and `r` be Reversals per route. Edge `j` has run index
  `floor(j*(r+1)/e)` and sign down for an even run, up for an odd run. This
  creates exactly `r` broad sign changes and always begins downhill. Keyed
  downhill magnitudes use `[5.5+1.5t, 7.0+2.0t] m`; uphill magnitudes use
  `[2.5+1.5t, 4.0+2.0t] m`. The resolver keeps its existing final global shift
  so the highest route node equals Nominal peak.
- The macro field uses normalized point
  `(local_x/(X/2), local_z/(Z/2))`; the fixed legacy `90/60` divisors are
  removed. It retains the keyed, oriented-Gaussian construction but consumes
  explicit arrays rather than route-count-derived counts. Broad ridge count
  includes one backbone. The remaining ridges are
  spaced uniformly from normalized along `-0.66..0.66`, add keyed along jitter
  `[-0.07,0.07]` and cross jitter
  `[-(0.10+0.014*routes), +(0.10+0.014*routes)]`, and retain the current
  `0.20+0.015*routes .. 0.28+0.020*routes` height-ratio range. Summit caps use
  length spread `0.07..0.11` and width spread `0.09..0.14`; narrower legacy
  caps are forbidden.
- Basin `j` uses along progress `(j+1)/(basin_count+1)` over `-0.42..0.42`
  with keyed `±0.04` jitter, alternates cross side, and samples absolute cross
  offset `0.12..0.22`. Its angle is backbone angle `±0.45`, depth is
  `3.5..5.5%` of nominal peak, and length/width spreads are `0.10..0.16` and
  `0.10..0.17`. This keeps basins broad, off-centre, and non-crater-like.
- Pass `j` is spaced over normalized along `-0.46..0.46` with keyed `±0.04`
  jitter, oriented perpendicular to the backbone `±0.18`, and retains depth
  `2.5..4.5%`, length spread `0.14..0.22`, and width spread `0.028..0.050`.
  There is one wave per pass: angular frequency `2+j`, radial frequency
  `1+(j mod 2)`, keyed phase `0..TAU`, and ratio amplitude sampled from
  `0.5..1.0` times `undulation / (nominal_peak*max(pass_count,1))`.
- The existing footprint/corridor/terrace blend consumes those arrays and then
  applies the locked two-octave `0.50 m` noise. Candidate validation, not a
  hidden clamp or hand repair, enforces the slope, spike, connectivity, RMS, and
  reachability gates below.

Rules remain gradual:

- Stage 01–10 target is `4.0 + 0.5 * (n - 1)` percent.
- Stage 11–20 target is `round_half(9.0 + 0.35 * (n - 11))` percent.
- Stage 21–30 target is `round_half(12.5 + 0.30 * (n - 21))` percent.
- Maximum shots by five-stage band are `4, 5, 5, 6, 6, 7`.
- Star thresholds are target, target `+2.5`, and target `+5.0` percentage points.

Difficulty and adjacency gates:

- Record the exact profile score
  `D = 0.05(X-180) + 0.05(Z-120) + 0.10(H-72) + 4(routes-1) +
  2(reversals) + 0.8(ridges-3) + passes + basins +
  0.5(28-route_width) + 0.5(mechanisms) + 0.2(target-4) +
  0.5(undulation-2) + 0.4(stations-8)`.
- Every adjacent delta must satisfy `0.35 <= D(n+1)-D(n) <= 5.00`; this is the
  profile-level gradualness gate, not a substitute for the rendered/RMS gates.
- Static preflight of these exact formulas yields a minimum delta of `0.45`
  (Stage 28 to 29) and maximum of `4.85` (Stage 07 to 08), so the locked table
  satisfies its own score gate before candidate generation begins.
- All thirty height checksums and profile checksums are unique.
- Resample each adjacent height field to a common `64 × 48` normalized grid.
  RMS height difference must be `1.0..18.0 m`; below means visually duplicated,
  above means an abrupt jump.
- Adjacent dimension changes are at most `4 m` on X, `4 m` on Z, `2.0 m` nominal
  peak, and `0.3 m` undulation amplitude.
- A meaningful reversal is a grade-sign change after a `6 m` box filter,
  ignoring grades below `2°`.
- Local spike prominence is sample height minus the mean of its Chebyshev-radius
  `2` ring and must be `<= 10 m`. Playable Top absolute slope stays `<= 48°`.
- The accepted global maximum must be `H-2.0..H+4.0 m`; normalization is part of
  deterministic synthesis, not a post-build vertex edit. At least one Summit
  Region inset sample must be within `145 m` horizontal range of the cannon's
  90°-elevation yaw-pivot reference and inside the legal yaw bearing. The full
  physical witness below remains authoritative over this cheap prefilter.
- Every accepted layout remains one connected row-solid footprint, one top per
  XZ, a closed shell, and no hole, tunnel, overhang, detached board, or literal
  stair geometry.
- Stage 04 and 05 are explicit canaries. Their profiles resolve to
  `186 × 124 m / 74 × 50 / 77.5 m / 2.6 m / 12 decorations` and
  `188 × 126 m / 76 × 50 / 79.5 m / 2.8 m / 13 decorations` respectively,
  with base route widths `27.0/26.5 m`, difficulty scores `5.15/6.00`, different
  accepted geometry checksums, and RMS inside the adjacency gate.

Slope safety bands remain the former bounded contract:

| Stages | Target mean | Target p95 max | Target absolute max | Route p95 max | Corridor lip max |
| --- | --- | ---: | ---: | ---: | ---: |
| 01–05 | 16–28° | 34° | 38° | 32° | 30° |
| 06–10 | 17–29° | 35° | 39° | 33° | 31° |
| 11–15 | 18–30° | 36° | 40° | 34° | 32° |
| 16–20 | 19–31° | 37° | 41° | 35° | 33° |
| 21–25 | 20–32° | 38° | 42° | 36° | 34° |
| 26–30 | 21–33° | 40° | 44° | 38° | 35° |

The generator emits typed ridge/pass/basin/wave arrays from these fields. It may
not infer complexity from route count alone, widen acceptance to force a pass,
or use a different random seed after catalog build.

### 3. Summit, target, and default-aim reachability

- Keep the legal manual domain yaw `-45..45°` at `0.1°`, elevation `10..68°` at
  `0.1°`, and power integer `0..100`. Power maps linearly from `32.0 m/s` at
  `0` to `150.0 m/s` at `100`. Do not expand these limits to rescue an invalid
  accepted candidate.
- After building the exact Playable Top, `GeneratedStageLayout` calculates global
  maximum height and sorted stable Summit Region triangle IDs. The certificate
  stores those IDs, their checksum, one summit witness index, predictor contact,
  rigid-body contact, identity, and margins.
- `DirectReachabilityValidator` first deduplicates target texels by stable top
  triangle. It solves one legal witness for each distinct scoreable triangle and
  maps every texel to that witness. This preserves the per-texel contract without
  repeating an identical triangle search.
- Both target and summit solving extend the existing deterministic analytic
  nomination path instead of introducing another trajectory model: nominate the
  nearest bearing yaw and its `±0.1°` neighbors; evaluate every integer power
  `0..100`; bracket elevation roots over `10..68°` at `1°`; bisect each bracket
  for 12 iterations; snap and validate the `0.1°` elevation neighborhood with
  the production sphere-cast predictor. Summit samples are the centroid and the
  three `0.6/0.2/0.2` barycentric inset points of each stable-ID-sorted Summit
  Region triangle. The first valid tuple under the existing canonical tuple
  ordering is the summit witness.
- It then solves at least one Summit Reachability witness. Predictor first hit
  must be `terrain/top` on a Summit Region triangle. The production
  `PaintProjectile` must first contact the same collider/shape/triangle identity;
  predictor/rigid-body points may differ by at most `0.75 m` and both contact
  heights must be within `1.0 m` of the global maximum.
- A layout with an unreachable scoreable triangle or summit is rejected and the
  builder tries the next locked candidate seed. If all 32 candidates fail any
  per-stage or adjacency gate, the builder preserves the prior catalog, writes
  the bounded rejection metrics, exits with code `3`, and execution stops for a
  plan revision. It never changes formulas, target pixels, geometry, aim limits,
  collision, or acceptance thresholds during the run.
- The default aim remains the certified target witness whose hit is nearest the
  target-mask centroid. Default power/angle are not hard-coded `38°/68%` and do
  not target the summit unless the centroid witness naturally does.
- Stage start and restart install the same certified default. HUD controls can
  express every legal witness value, including the summit witness.
- Containment proof covers minimum/maximum aim-domain corners, default aim, and
  summit witness; none may pass over the visible rear wall.
- Replace the containment proof's undamped `v²/2g` apex bound with the same
  fixed-`1/60 s`, replace-mode `linear_damp=0.55`, gravity recurrence used by
  prediction and the rigid body. Evaluate the continuous-domain yaw/elevation
  extrema at `150.0 m/s`, include the `0.90 m` radius and muzzle extrema, and
  require nonnegative top/side/rear/front clearances against the collider-
  matched wall/apron. Preserve the exact containment bounds
  `AABB((-245,-32,-178), (490,286,230))`, apron XZ
  `Rect((-245,-172.25), (490,224.25))` at `y=-2`, and wall
  center/size `(0,111,-174.25)/(480,284,4)`. The damped preflight leaves more
  than `60 m` upper and lateral clearance at the domain extrema; a failed proof
  is an implementation parity defect, not permission to resize the wall or add
  an invisible upper kill plane.
- Reliable-clear admission reuses `scripts/solution_search.gd` exactly: coarse
  yaw `-28..28°` step `4°`, elevation `18..68°` step `4°`, power `0..100` step
  `10`; refine retained centers by yaw/elevation `±4°` step `1°` and power
  `±10` step `2`; beam width `12`; depth equals the stage shot limit. A winner
  reaches target coverage. It need not activate every mechanism in one route.
  Separately, every placed mechanism must have one legal single-shot activation
  witness whose sealed observation names that mechanism and whose attributable
  effect produces at least `0.10` target-coverage percentage points. Failure of
  either proof rejects that candidate; the witnesses remain hidden from play.

### 4. Projectile and paint midpoint

Replace the current parent values with:

| Parameter | Locked value |
| --- | ---: |
| Visible/collision/predictor radius | `0.90 m` |
| Minimum / maximum launch speed | `32.0 / 150.0 m/s` linearly over power `0..100` |
| Continuous traversed paint radius | `1.50 m` |
| First-impact paint radius | `2.10 m` |
| Settlement paint radius | `1.50 m` |
| Mass | `2.4` |
| Bounce / friction | `0.03 / 0.90` |
| Linear / angular damp | `0.55 / 1.10` |
| Minimum speed / stop duration / lifetime | `1.70 m/s / 0.50 s / 12.0 s` |

- The ball diameter becomes `1.80 m`; traversed/settlement paint diameter is
  `3.00 m` (`1.67×` diameter, `2.78×` area), and impact diameter is `4.20 m`
  (`2.33×` diameter, `5.44×` area).
- Ball mesh, collider, CCD, prediction sphere, contact offset, mechanism strike,
  and reachability all read the same `0.90 m` resource value. Cannon,
  prediction, rigid body, solution search, and certification all read the same
  `32..150 m/s` resource curve. No camera-only or mesh-only compensation is
  allowed.
- Splitter children retain the existing uniform `0.78` scale on both physical
  and paint radii so the ratios remain unchanged.
- Every consecutive verified Playable Top contact interval still submits one
  authoritative sweep. Airborne, wall, apron, shell, and mechanism surfaces do
  not paint. PaintSystem remains the sole mask/coverage owner.
- A controlled flat/ramp contact fixture measures mask width in world metres:
  continuous width must be `3.00 m ± one mask texel per side`; impact width must
  be `4.20 m ± one mask texel per side`. A `1280 × 720` background Compatibility
  capture must show the physical sphere and resulting mark together.

### 5. Usable immediate re-aim and repeat fire

- Replace live motion states with Board Phases `LOADING`, `BRIEFING`, `AIMING`,
  `PAUSED`, `STAGE_CLEAR`, and `STAGE_FAILED`. Old
  `PROJECTILE_IN_FLIGHT`, `PAINT_SETTLING`, and `SHOT_RESULT` are removed from
  live admission and consumer branching after migration.
- Shot Family activity remains orthogonal typed data. Maximum active root
  families is `2`; maximum physical bodies is `8`; Splitter descendants inherit
  the root `shot_id`. Each family seals after its bodies stop and its attributed
  authoritative paint drains. Terminal resolution waits for all admitted
  families and global paint, but never blocks Aim Editable before Terminal
  Pending.
- Add `CannonPredictionStatus` (`PENDING`, `FIREABLE`, `INVALID`) keyed by the
  exact `AimTuple.stable_key()`. Add `FireReadinessSnapshot` with board phase,
  aim editable, prediction status/key, active root count, remaining root
  capacity, active physical count, shots remaining, terminal pending, action
  lock, and final reason enum.
- `StageController` emits one `fire_readiness_changed(snapshot)` whenever any
  input changes. Human button/Space, replay, agent, and debug Fire all call the
  same admission method; HUD never reconstructs the rules.
- After Fire 1, Board Phase remains AIMING, cannon input remains enabled, camera
  remains CANNON/AIMING, and the next trajectory remains visible. Fire does not
  automatically enter FOLLOW. Follow is an explicit observation action; any
  yaw/elevation/power input returns to CANNON and displays the next trajectory.
- Aim input updates the cannon immediately and invalidates only the next Fire
  prediction. Coalesced prediction must publish a matching-key result within two
  rendered frames and `<= 50 ms` on the current delivery machine; no synchronous
  Fire-time recomputation or stale-key launch is allowed.
- Exact Korean Fire reasons are: `궤적 계산 중` for PENDING, `지형을 조준하세요`
  for INVALID, `포탄 2개 진행 중` for capacity, `남은 탄 없음` for no shots,
  and `결과 계산 중` for Terminal Pending. English translation keys are added.
  The reason appears adjacent to the existing bottom-center Fire action and does
  not add a new card.
- At two active roots, only Fire is disabled; aim controls and next trajectory
  remain editable/visible. When one family seals, capacity and Fire readiness
  update without waiting for the other family or a serial result timer.
- Remove the `0.7 s` serial shot-result wait. Coverage-gain feedback is nonmodal
  and does not change Board Phase or camera.

## Tasks

### Phase 0: Reset truthful boundaries and version surfaces

- [ ] **0.1 Freeze replacement fixtures before deleting shortcuts**
  - Owners: current catalog/profiles, audit evidence, focused tests.
  - Change: preserve exact legacy alias/save fixtures and add failing assertions
    for Stage 04/05 profile distinction, missing summit proof, human changed-aim
    repeat Fire, and the new scale values.
  - Accept: each new assertion fails for the diagnosed production reason, not a
    fixture or parse error; no foreground Godot window opens.
- [x] **0.2 Introduce version-7 typed data surfaces**
  - Owners: StageProgressionData, StageGenerationContract/Profile, StageData,
    StageCatalogData, GeneratedStageLayout, DirectReachabilityCertificate.
  - Change: add the exact version/schema fields and migration aliases before
    changing generation or live state.
  - Accept: project parses, legacy saves map only at the boundary, and stale
    mixed StageData-6/profile-5 inputs fail closed.

Phase gate: run `scripts/verify.ps1` once.

### Phase 1: Converge physical and paint scale

- [x] **1.1 Apply one shared `0.90 m` physical radius and `32..150 m/s` power curve**
  - Owners: ProjectileData resource, PaintProjectile, cannon/predictor/contact,
    mechanism strike consumers, relevant scene mesh/collider setup.
  - Change: update the parent radius and maximum launch speed/export range;
    remove any literal or derived old radius/speed ceiling.
  - Accept: visual mesh, shape, CCD, predictor, contact, and parent/child scale
    parity read the same resource; power endpoints are exact; existing low-
    rebound settlement remains.
- [x] **1.2 Apply the `1.50/2.10/1.50 m` authoritative paint radii**
  - Owners: ProjectileData and real impact/sweep/settle command creation.
  - Change: update only resource-driven paint radii; preserve verified-contact
    and single-mask rules.
  - Accept: controlled mask widths and one real-contact capture match the table;
    airborne/non-target writes remain zero.

Phase gate: update `projectile_contact_test.gd` and one scale-focused section of
the existing projectile/paint integration check; do not add per-helper tests.
Run `scripts/verify.ps1` once.

### Phase 2: Replace three-template cloning with real per-stage progression

- [x] **2.1 Implement the complete typed progression resource**
  - Owners: `stage_progression_data.gd`, version-7 resource, contract/profile,
    route profile, multiple mechanism-pad/entry types.
  - Change: encode every formula, band, stage-specific macro array, mechanism
    slot, rule, ID, and difficulty score in this plan.
  - Accept: Stage 04/05 exact canary values and Stage 01/30 endpoints match;
    all 29 profile-score deltas remain `0.35..5.00`; no executor-selected
    tuning remains.
- [x] **2.2 Make geometry consume every progression field**
  - Owners: route graph resolver, mountain/height synthesizers, footprint,
    topology, target rasterizer, placement, decoration, containment, camera
    framing.
  - Change: remove fixed version-5 equality and route-count-only macro feature
    selection; build variable bounds/cells/stations/routes/features/pads.
  - Accept: unique checksums, adjacent RMS/scale gates, exact macro counts,
    slope/spike/closed-mass rules, mechanism placement, and decoration counts
    pass for all 30 accepted layouts.
- [x] **2.3 Remove legacy runtime synthesis shortcuts**
  - Owners: StageCatalog and SeededStageGenerator.
  - Change: delete `BASE_STAGE_PATHS`, `profile_band()`, permissive profile
    widening, and eight-attempt runtime search after version-7 replacement works.
  - Accept: stage lookup performs no profile cloning and selected gameplay builds
    exactly the persisted accepted seed once.

Phase gate: replace `stage30_progression_test.gd` with one consolidated contract
that asserts formulas, all adjacent pairs, all 30 generated metrics, and no
runtime catalog search; run it, then `scripts/verify.ps1` once.

### Phase 3: Certify summit and target-wide physical reachability

- [x] **3.1 Add stable Summit Region identity**
  - Owners: TerrainTopTopology and GeneratedStageLayout.
  - Change: calculate maximum height, sorted triangle IDs, region checksum, and
    exact samples under the locked definition.
  - Accept: the region is nonempty, stable across rebuilds, and contains only
    Playable Top triangles within the height tolerance. The consolidated
    thirty-layout gate now checks this identity for every persisted layout.
- [ ] **3.2 Extend predictor and rigid-body certification**
  - Owners: DirectReachabilityValidator/Certificate, PaintProjectile batch
    verifier, containment proof, DefaultAimSolver handoff.
  - Change: deduplicate target work by triangle, retain per-texel assignments,
    add summit witness/identity/margins, and keep centroid default separate.
  - Accept: every scoreable target texel and the Summit Region have legal
    matching first-hit witnesses with the exact current `0.90 m` ball and
    `2.10 m` impact footprint; stale or fabricated proof fails identity checks.
- [ ] **3.3 Build the transactional thirty-stage catalog**
  - Owners: `scripts/build_stage_catalog.gd`, StageCatalogData, stage/profile/
    certificate resources, preview renderer, manifest and rollback path.
  - Change: implement `--check` and `--write`, the locked seed sequence and
    candidate order, reliable-clear/mechanism witnesses, previews, content-
    addressed staging bundle, and catalog-last promotion.
  - Accept: two clean checks are identical; injected pre-promotion failure leaves
    prior outputs intact; runtime never certifies or searches.

Phase gate: run one consolidated summit/target certificate contract on the 30
committed outputs, the builder `--check`, and `scripts/verify.ps1` once. Do not
run an extra exhaustive historical matrix.

### Phase 4: Make repeat fire visibly and functionally immediate

- [x] **4.1 Separate Board Phase from Shot Family activity**
  - Owners: StageController, ProjectileManager, PaintSystem attribution,
    ShotObservation, replay/agent/debug consumers.
  - Change: remove serial live states/timer, seal families independently, resolve
    terminal only after drain, and expose correct remaining root capacity.
  - Accept: two changed-aim roots coexist; a third is side-effect-free rejected;
    aim stays editable; each family seals once; final result includes all paint.
    `rapid_fire_contract_test.gd` now exercises a changed next tuple while the
    first family is still active and verifies distinct sealed commands.
- [x] **4.2 Publish one matching-key Fire readiness contract**
  - Owners: CannonController/predictor status, StageController snapshot/signals,
    GameplayScene wiring, HUD/ActionButtons, translation rows.
  - Change: implement exact status/reason semantics and remove direct prediction-
    validity-to-button wiring and constant-capacity snapshots.
  - Accept: button, Space, replay, agent, and debug agree for READY/PENDING/
    INVALID/CAPACITY/NO_SHOTS/TERMINAL; stale predictions never launch. The
    StageController now republishes matching-key prediction changes, the HUD and
    AimInputController consume that one snapshot, and agent observations expose
    the same primitive readiness fields. Focused rapid-fire/phase-7 checks cover
    READY/PENDING/CAPACITY plus stale-fire rejection; replay/debug use the same
    StageController admission path.
- [x] **4.3 Preserve the next aiming view after Fire**
  - Owners: GameplayScene, CameraDirector, TrajectoryPreview, AimInputController,
    observation controls.
  - Change: Fire stays CANNON/AIMING with visible next trajectory; Follow becomes
    explicit; any aim input returns from Follow to CANNON.
  - Accept: while ball 1 remains physically active, a real human input changes
    the next tuple, matching preview appears within the bound, and ball 2 fires
    at that tuple without steering ball 1. Background captures now cover
    `next_aim_ready` and `two_family` at the 1280 × 720 baseline.

Phase gate: replace the direct-only rapid-fire smoke with one integration contract
through AimInputController, HUD, CameraDirector, prediction, StageController, and
two real projectiles; run it and `scripts/verify.ps1` once.

### Phase 5: Production evidence, truth audit, and handoff

- [ ] **5.1 Extend the background delivery runner with named recovery states**
  - Add `--capture-stage=<stage_id>` and exact screens `progression_aiming`,
    `summit_hit`, `next_aim_pending`, `next_aim_ready`, `two_family`, and
    `scale_contact`. Invalid stage/screen/output exits nonzero.
  - Capture Stage 04, 05, 10, 20, and 30 aiming frames plus the five live
    interaction frames at `1280 × 720` under
    `.agents/evidence/gameplay-contract-recovery/`.
  - Write one metadata JSON with profile inputs, metrics, adjacent RMS,
    checksums, summit witness/contacts, aim keys/readiness timings, active family
    IDs, and measured paint widths.
  - Re-capture the baseline running-project set as `01_main_menu.png` through
    `07_stage_failed.png` after the recovered catalog/state/scale is active. The
    seven baseline files and the ten recovery captures are separate full-
    resolution images, never a collage or concept render.
- [x] **5.2 Run task-scoped quality and ownership audit**
  - Use `codebase-quality-auditor` after the cross-module implementation.
  - Correct only blocking task-owned competing owners, stale serial/template
    branches, contract mismatches, or false status claims.
  - Accept: StageController, PaintSystem, catalog, generator, certificate,
    prediction, and HUD each have one named responsibility with no legacy bypass.
- [ ] **5.3 Build and verify the production path**
  - Run the focused checks, builder check, one release export, and the named
    background captures. Inspect each actual image for distinct Stage 04/05
    silhouette, summit hit, ball/mark relationship, visible next trajectory, and
    two-family truth.
  - Do not open a visible editor/game window and do not substitute a mockup.
- [ ] **5.4 Reconcile lifecycle and implemented-status records**
  - Mark this plan `done` only after every checkbox/gate passes; update
    `.agents/Documentation.md`, `docs/test-checklist.md`, and evidence with exact
    observed results and limitations.
  - Accept: no current document calls three-template cloning progressive,
    centroid default summit proof, direct double-Fire usable re-aiming, or
    resource text rendered scale acceptance.

## Verification and Rework Controls

Use the already approved Godot console path through
`$env:PAINT_MOUNTAIN_GODOT`. All non-rendered checks are headless. Rendered
evidence uses `--capture-background`, which moves the Compatibility window to
`(-32000,-32000)` and removes focus.

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\verify.ps1 -GodotPath $env:PAINT_MOUNTAIN_GODOT
& $env:PAINT_MOUNTAIN_GODOT --headless --path . --script res://tests/projectile_contact_test.gd
& $env:PAINT_MOUNTAIN_GODOT --headless --path . --script res://tests/stage30_progression_test.gd
& $env:PAINT_MOUNTAIN_GODOT --headless --path . --script res://tests/target_reachability_test.gd
& $env:PAINT_MOUNTAIN_GODOT --headless --path . --script res://tests/rapid_fire_contract_test.gd
& $env:PAINT_MOUNTAIN_GODOT --headless --path . --script res://scripts/build_stage_catalog.gd -- --check
& $env:PAINT_MOUNTAIN_GODOT --headless --path . --export-release 'Windows Desktop' 'builds\windows\PaintMountain.exe'
& $env:PAINT_MOUNTAIN_GODOT --path . -- --capture-background --capture-size=1280x720 --capture-screen=progression_aiming --capture-stage=stage_04 --capture-output=res://.agents/evidence/gameplay-contract-recovery/stage_04_aiming.png
```

Rules:

- Run only the focused test named by each phase plus `scripts/verify.ps1` once at
  the phase boundary. Do not run the broad historical matrix.
- A passing script or metric does not replace actual running-state evidence for
  Stage 04/05 distinction, summit contact, scale, or next-shot usability.
- A screenshot does not replace physical identity, authoritative-mask, or
  deterministic resource checks.
- Do not regenerate the catalog after UI-only changes. Rebuild only when stage,
  generator, projectile radius, reachability, placement, or certificate inputs
  change.
- Record the command and result when a checkbox passes. Never update completion
  prose while leaving its task unchecked.
- Rerun a failed check only after a concrete relevant change or a new falsifiable
  hypothesis. Full export/captures happen once after all focused gates pass.

## Predetermined Contingencies

| Trigger | Required response | Forbidden shortcut |
| --- | --- | --- |
| Any per-stage or adjacent progression gate fails | Reject that candidate and continue the locked 32-seed sequence | Change a formula, hand-edit vertices, accept seed-only similarity, or lower a gate |
| All 32 candidates fail for one stage | Preserve the prior catalog, emit bounded metrics, exit `3`, and stop for a revised plan | Tune generation during execution or commit a partial catalog |
| No legal summit or target witness | Reject that candidate and continue the locked sequence | Expand aim limits/speed, change collision, delete target texels, teleport, or fake a certificate |
| Radius/speed change reports containment failure | Fix recurrence, muzzle-extrema, or fixed-spec parity and rerun; if exact parity still fails, stop for plan revision | Resize the wall, narrow aim limits, or let predictor/collider/mesh use different values |
| Paint width aliases at mask resolution | Use the exact world-to-mask reconstruction and report one-texel tolerance | Increase radius, add decals, or create a second paint representation |
| Prediction misses the two-frame/50 ms readiness bound | Reuse solver caches and coalesce latest-key work; drop obsolete queued keys | Synchronously solve on Fire or allow stale-key launch |
| A mechanism placement or usefulness witness fails | Reject that candidate and continue the locked sequence; if exhausted, stop as above | Reduce counts, shrink colliders, move an accepted item by hand, or waive usefulness |
| Catalog build is slow | Keep it offline, cache immutable per-candidate products, and report build time | Move search/certification to runtime or commit a partial catalog |
| User rejects the new scale after real evidence | Stop and revise the exact scale table with the user | Iterate unrecorded values during another broad execution run |

## Progress

- [x] Static code, git, prior-plan, and session-history audit completed without a
  visible Godot window.
- [x] Four reported symptoms mapped to concrete production paths and weak or
  missing acceptance checks.
- [x] Effective source brief clarified; predecessor plans superseded; one
  decision-complete recovery contract installed.
- [ ] Phase 0: truthful replacement fixtures and version surfaces (0.2 done;
  0.1 fixture-first gate remains to be reconciled).
- [ ] Phase 1: projectile/paint midpoint (locked resource/contact checks done;
  controlled rendered-width evidence remains).
- [x] Phase 2: real per-stage progression (typed formulas, serialized catalog,
  persisted-seed generation, runtime shortcut removal, adjacent normalized RMS,
  bounded scale deltas, summit identity, macro-count, pad, decoration, and
  thirty-layout checksum gates pass in the consolidated full-generation run).
- [ ] Phase 3: summit identity is implemented and checked for all thirty
  layouts; the canonical Stage 01 and Stage 30 summit predictor/rigid-body
  contracts now pass after correcting the visual-muzzle/ballistic-yaw sign
  contract, and target witnesses use the authoritative impact-mark tolerance.
  Summit certificate serialization now keeps a dedicated summit aim tuple
  separate from the target witness table.
  The complete Stage 01 target-wide predictor/rigid-body pass now passes all
  `67,729` target texels with `2,432` physical witnesses after reconciling
  target assignments to actual contact points. The dedicated offline worker
  and physical-contact certificate path are in place, but target-wide proofs
  for stages 02–30 and the complete certificate/preview bundle are still open.
  A candidate front-envelope raster filter was measured but rolled back because
  it added unacceptable generation cost and would have weakened the
  no-target-deletion rule; the unchanged thirty-layout generation gate then
  passed in `254.2 s`.
- [x] Phase 4: usable immediate re-aim/repeat fire (the live board now remains
  AIMING, the serial result timer is bypassed, and the matching-key readiness
  contract is implemented with prediction-change republishing, translated
  READY/PENDING/INVALID/CAPACITY/NO_SHOTS/TERMINAL reasons, remaining root
  capacity, and no direct cannon-to-HUD overwrite. Per-family sealing, changed
  aim, HUD/AimInput pending-to-ready, and two-family captures pass. Human
  AimInput, Agent, Replay, and Debug admission paths now each have focused
  acceptance evidence; Space maps to the same human request path.)
- [ ] Phase 5: production evidence, quality audit, and truthful handoff. The
  task-scoped ownership audit is complete and corrected the independent-summit
  certificate boundary; production export, focused regression evidence, seven
  fresh baseline captures, and named recovery captures pass. The delivery
  runner now records sweep intent before body removal and waits for the actual
  terminal transition in clear/failure evidence. Full target
  certificates/previews, rendered-width proof, and lifecycle reconciliation
  remain open.

## Next Steps

1. Continue at Phase 3 target-wide certification/catalog output; do not
   implement from a predecessor plan. The visual/ballistic yaw contract is now
   fixed and guarded, so do not reopen that tuning while building certificates.
2. Keep the current project launchable and commit each completed phase as one
   coherent task-owned change after its focused gate.
3. Stop after Phase 5 background evidence and hand the production build to the
   user for foreground play review.

## Completion and Stop Conditions

Complete only when all tasks and gates pass; all thirty catalog resources are
version 7 and deterministic; every stage has target-wide and summit physical
proof; Stage 04/05 are structurally and visibly distinct; a changed next aim and
second Fire work before ball 1 settles; the exact `0.90/1.50/2.10/1.50 m` scale
is visible and mask-measured; production export/captures exist; and current docs
state only observed facts.

Stop and replan only if all 32 locked candidates for one stage fail, or satisfying
a requirement needs a different terrain representation, aim domain, renderer,
dependency, mechanism set, or user-visible scale contract. Do not stop for one
rejected candidate, a local task-owned defect, a stale test that this plan
explicitly replaces, or pending foreground user QA after all agent-owned
evidence is complete.
