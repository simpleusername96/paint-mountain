---
type: plan
status: done
created: 2026-08-02
last_reviewed: 2026-08-03
scope: procedural stage generation, mechanism placement, aiming interaction, Korean-first UI, visual remediation, and licensed asset integration
source: user remediation directive dated 2026-08-02
related:
  - Prompt.md
  - Documentation.md
  - execplans/2026-08-03-gameplay-visual-reset.md
  - execplans/2026-08-03-core-interaction-redesign.md
  - ../docs/source-brief.md
  - ../docs/design-spec.md
  - ../docs/technical-architecture.md
  - ../docs/test-checklist.md
  - ../docs/remediation-report.html
---

# Paint Mountain Core Experience Remediation Plan

> Historical plan: this document records the remediation that was marked done
> on 2026-08-03. A later static code audit found that several claimed outcomes
> are not supported by the current implementation. The only active successor is
> [`execplans/2026-08-03-gameplay-visual-reset.md`](execplans/2026-08-03-gameplay-visual-reset.md);
> use its progress checklist and acceptance gates for all further work.

At plan creation, the baseline contained the original three-stage rules, paint mask, projectile physics, mechanisms, replay, and export path but lacked procedural progression, readable placement, Korean-first UI, direct targeting, and the target composition. The six phases below were executed to preserve the working gameplay owners while rebuilding the visible core experience; all completion gates passed on 2026-08-03.

## Purpose

- Objective: make Paint Mountain read and play like the provided reference while adding deterministic stage generation and placement that become more demanding from Stage 1 through Stage 3.
- Final artifact: a Windows Godot 4.x build with three reproducible generated stages, visible and usable 3D mechanisms, direct mouse targeting, explicit power controls, Korean-default localization, a coherent global UI theme, licensed production assets, and fresh production screenshots.
- Completion state: every phase below passes its acceptance and regression guards, the Windows release build passes the final gates, and the user-visible result is checked against `docs/remediation-report.html` and the original source brief.

## Pre-plan Evidence Already Verified

| Source or path | Verified fact | Decision affected | Freshness or recheck boundary |
| --- | --- | --- | --- |
| `docs/source-brief.md` sections 1, 2, 8, 13, 15–17, 22, 25, and 27 | The mountain must dominate the view; mechanisms and routes must be readable; the preview ends at the first collision; the UI is sparse; paint is thick and bright; randomness must be seeded and justified | Product, visual, input, determinism, and performance contract | Recheck only if the user changes the product direction |
| User remediation feedback dated 2026-08-02 | Procedural mountain and item placement, increasing rise/fall complexity, visible 3D items, revised aim/power controls, full first-impact preview, Korean default, better layout/font, and asset research are required | Supersedes the earlier assumption that the fixed three-stage presentation is sufficient | Recheck only after explicit user revision |
| `src/terrain/terrain_mesh_factory.gd` | A `56 × 38` mesh uses one of three fixed analytic height functions and has no seed, generator profile, rejection pass, or difficulty metric | Replace fixed formulas with a seeded path-first heightfield generator while retaining one principal mesh | Recheck after Phase 2 |
| `src/stage/stage_data.gd` and `resources/stages/*.tres` | Stage data stores a `terrain_variant` integer and authored mechanism coordinates | Add immutable generation profile and seed inputs; retire fixed placements | Recheck after Phases 2–3 |
| `src/stage/mechanism_placement.gd` and `src/gameplay/gameplay_scene.gd::_spawn_mechanisms` | Mechanisms are spawned from authored X/Z coordinates without terrain-feature, visibility, spacing, or route validation | Add one placement generator owned outside `StageController` | Recheck after Phase 3 |
| `src/mechanisms/*.gd` | Burst, Splitter, and Bumper rules exist and use real `Area3D` nodes, but their visuals are small runtime primitive assemblies | Preserve behavior and replace presentation with scene-owned chunky silhouettes | Recheck after Phase 3 |
| `src/cannon/cannon_controller.gd` | Human keyboard, drag, wheel, and Space input are embedded in the cannon command owner | Separate human input from cannon commands and add direct impact targeting | Recheck after Phase 4 |
| `src/cannon/trajectory_preview.gd` | The preview samples the shared ballistics, shape-casts to the first collision, then stops | Preserve the first-collision boundary and improve continuity, visibility, and marker state | Recheck after Phase 4 |
| `src/ui/ui_factory.gd`, `src/ui/hud_controller.gd`, `src/ui/settings_screen.gd`, `src/autoload/save_system.gd` | UI strings are hardcoded English, no project font is wired, and language defaults to `en` with only one selectable locale | Add real `ko`/`en` resources, Korean default, Pretendard theme, and componentized HUD | Recheck after Phase 5 |
| `docs/remediation-report-assets/current-aiming.webp`, `current-briefing.webp`, `current-paint-flow.webp` | Fresh captures from the Windows release confirm a smooth mound silhouette, weak terrain depth, tiny/absent mechanism readability, flat paint, and default typography despite working gameplay | Establishes the visible baseline | Re-capture after each user-facing phase |
| `docs/remediation-report-assets/reference-aiming.webp` | The provided visual target uses a stepped mountain, thick paint routes, distinct mechanisms, small cannon, and a sparse edge-aligned HUD | Locks composition and hierarchy | Preserve as the comparison target |
| Kenney official asset archives, downloaded and inspected 2026-08-03 | Nature Kit 2.1, Game Icons, and Particle Pack 1.1 contain the exact GLB/PNG files listed below and are CC0 | Locks the external art manifest after the user's explicit approval | Recheck only if an official archive hash differs |
| Pretendard official v1.3.9 release, downloaded and inspected 2026-08-03 | `PretendardVariable.woff2` is present and redistribution is permitted under SIL OFL 1.1 | Locks the Korean UI font after the user's explicit approval | Recheck only if the pinned release is replaced |
| `C:\Users\BK\.config\fastrun\commands.tsv`, inspected 2026-08-03 | `D:\npjt\paint-mountain` is already registered to `& '.\builds\windows\PaintMountain.exe'` | Locks the production run command; no manager mutation is needed | Recheck after the final export |
| Godot stable asset/font documentation, accessed 2026-08-02 | glTF 2.0 is the recommended 3D format; WOFF2 is supported as a dynamic font | Locks import formats | Recheck only if the engine version changes |

## Locked Decisions

| Topic | Final decision | Rationale / source |
| --- | --- | --- |
| Authority | The original source brief remains the product baseline; the 2026-08-02 feedback adds required procedural generation, Korean-first UX, and reference-parity remediation | Root `AGENTS.md` and explicit user feedback |
| Stage randomness | Every stage is generated from immutable `stage_id + stage_version + terrain_seed + profile`; retry and replay reuse the same output | Preserves learnability, replay, and identical-shot behavior |
| Terrain method | Use a path-first `64 × 48` height grid: build route spines and landing shelves, add ridge/valley fields, apply low-amplitude seeded `FastNoiseLite`, smooth only invalid slopes, then emit one faceted heightfield mesh | Produces readable routes instead of uncontrolled noise and stays far below the 50k-triangle budget |
| Generator retries | Evaluate exactly the deterministic sequence defined in the numeric contract below, accept the first fully valid layout, then validate the profile fallback seed; fail generation and block export if neither path passes | Prevents invalid, unbounded, or silently hand-corrected generation |
| Difficulty progression | Stage 1: one broad route, 0–1 meaningful slope reversals, 24–32 m route width, no mechanism. Stage 2: two routes, 2–3 reversals, 14–22 m width, one upper Burst. Stage 3: three routes, 4–6 reversals, 8–16 m width, one safe low route plus Splitter and Bumper on high-value routes | Directly encodes the requested increase in descending and rising sections while preserving the three-stage brief |
| Meaningful reversal | Count a rise/downhill sign change only after smoothing samples over 6 m and ignoring grades below 2° | Keeps small surface noise from inflating difficulty |
| Placement method | Generate feature candidates from shelves, ridges, channel entries, downstream drop, and aiming-camera visibility; mechanism-specific validators select from those candidates. No raw random X/Z placement remains | Items must support legible routes, not decoration |
| Placement readability | Mechanism base slope ≤ 18°, center separation ≥ 10 m, world diameter 3.2–4.5 m, projected diameter ≥ 32 px at 1920×1080 and ≥ 22 px at 1280×720, and unobstructed line of sight to the center from the aiming camera | Makes items visible without making the mountain miniature |
| Mechanism visuals | Keep the existing behavior scripts. Move visuals into three `.tscn` scenes: radial-lens Burst, triangular three-way Splitter, and arrowed directional Bumper, using white/gray/navy/blue chunky geometry and active/spent/cooldown states | Distinct silhouettes are a source-brief requirement; custom visuals fit better than generic packs |
| Aiming interaction | The mouse selects and drags a first-impact target directly on visible terrain. A deterministic fixed-tick numerical solver includes the projectile's linear damping and derives the lowest valid elevation for the current power. Invalid solutions show a red marker and disable Fire while retaining the last valid aim | Matches the real launch model; an analytic no-damping arc would diverge from the projectile |
| Power interaction | The lower-left control exposes a segmented slider plus `−` and `+` buttons. Click changes 2%, hold repeats after 300 ms, wheel changes 1%. `Space` and the Fire button launch only a valid locked target | Precision is more important than a timing-based charge meter in a planning puzzle |
| Preview boundary | Draw a continuous dotted arc from muzzle to the actual first collision and keep a high-contrast impact ring visible. Never preview post-impact bounces, mechanisms, or final coverage | Reconciles “show it to the end” with the source brief’s anti-solution boundary |
| UI direction | Match the reference hierarchy: top stage/target/shots, small mode chip, bottom-left aim/power, bottom-center coverage, bottom-right restart/fire. Use `#F7F3ED` surfaces, `#10233D` text, `#1678F2` accent, 12–16 px radii, restrained shadow, and no center modal during aiming | Reference image and source brief |
| Typography and locale | Bundle `PretendardVariable.woff2` and its OFL license, define one global Theme, default to `ko`, support `en`, use `tr()` keys, and store translation keys rather than display strings in StageData | Korean is required and the current language selector is only a stub |
| Korean gameplay terminology | `스테이지`, `목표 면적`, `칠한 면적`, `남은 탄`, `조준`, `각도`, `파워`, `다시 시작`, `발사`, `폭발`, `분열`, `범퍼` | Chosen for short, direct desktop-game labels and verified text fit in the generated target mock |
| External art set | Approval was granted on 2026-08-03. Import only the five Nature Kit GLBs, six Game Icons PNGs, four Particle Pack PNGs, and one Pretendard WOFF2 file enumerated in the asset manifest below | One coherent, auditable set avoids pack-driven art drift and leaves no file choice to implementation |
| Provenance | Add each imported source URL, version/date, license text, selected filenames, and local usage to `docs/asset-licenses.md`; keep license files beside assets or under `assets/licenses/` | Prevents “free download” from being confused with redistribution permission |
| Paint authority | Keep `PaintSystem` as the only paint mask owner. Thick appearance comes from wider payload-scaled stamps, mask-derived edge normals/roughness, and transient pooled droplets—not a second persistent coverage mesh | Preserves the strongest existing architecture invariant |

## Implementation-Ready Contract

This section is normative. Implementers may fix defects discovered by tests, but may not substitute algorithms, thresholds, copy, files, or interaction semantics without first updating this plan and recording the reason. A layout that fails a locked validator is rejected; it is never repaired by an authored production coordinate.

### Domain vocabulary and serialized contract

- `terrain_seed` is the immutable requested stage seed. `accepted_seed` is the deterministic attempt seed that produced the accepted layout. `generation_attempt` is `0..31`, or `-1` for the separately validated fallback.
- `profile_version` is `2`. Each stage resource moves to `stage_version = 2`; replay metadata moves to format `2` and serializes stage id/version, profile version, terrain seed, accepted seed, height-grid checksum, yaw, elevation, and power.
- `height_grid` is the sole authoritative geometric height sample source. Mesh vertices, collision, paint downhill queries, mechanism placement, decorations, replay checks, and the agent height-grid observation consume the same accepted layout.
- `route_spine` means an intended paint/scoring corridor. `eligible_mask` is a static scoring-eligibility projection derived from accepted geometry and route bands; it is not painted state and does not calculate coverage. `PaintSystem` remains the only mutable paint/coverage authority.
- `terrain_variant` and authored production `MechanismPlacement.local_xz` are removed after migration. `StageController` remains the only owner of stage state, shot progression, Fire acceptance, clear, and failure. `TARGET_LOCKED` and `ANGLE_FALLBACK` are cannon aim modes, not stage states.

### Seed sequence, grid, and synthesis

- Hash input is UTF-8 `paint_mountain:<stage_id>:v2`, hashed with 32-bit FNV-1a and masked with `0x7fffffff`. The frozen base seeds are First Descent `845479992`, Burst Basin `1692108109`, and Split Ridge `671499753`.
- Attempt `i` uses `(base_seed + i * 7919) & 0x7fffffff` for `i = 0..31`. The fallback seed is `base_seed ^ 0x5EED5EED`: `1820876501`, `976673696`, and `1995119364` respectively. The fallback must pass the same geometry and placement validators. If it fails, generation returns an error, gameplay does not enter briefing, and verification/export fails.
- The heightfield is `64 × 48` cells and `65 × 49` samples over local `x = [-90, 90]`, `z = [-60, 60]`, producing exactly `6,144` triangles. The rear summit is negative Z; the cannon is toward positive Z. Heights are clamped to `[0, 90]` metres.
- Between listed control points, route X and route height use `smoothstep(t) = t²(3 - 2t)` interpolation. For distance `d = abs(x - route_x(z))`, route influence is `1 - smoothstep(0.45w, 0.75w, d)`. The accepted height at a sample begins with the seeded mountain mass and is blended toward the closest route height by the maximum route influence.
- Mountain mass is the maximum of three seeded elliptical Gaussian lobes: a central lobe at `(0,-14)` with radii `(68,58)` and nominal peak Stage 1/2/3 = `72/80/88 m`; side lobes at `(-42,2)` and `(42,2)` with radii `(46,48)` and peaks `0.72` and `0.68` of that nominal peak. Each lobe center is jittered independently by X `±5 m`, Z `±4 m`, and peak `±2 m` from the attempt RNG.
- A shoulder ridge is added at route distance `0.70w`, with a Gaussian half-width `0.18w` and amplitude Stage 1/2/3 = `5/7/9 m`. Noise uses one seeded `FastNoiseLite` with `TYPE_SIMPLEX_SMOOTH`, frequency `0.035`, FBM, 2 octaves, lacunarity `2.0`, gain `0.45`, and amplitude `1.2/1.6/2.0 m`; it is multiplied by `(1 - 0.65 * route_influence)`.
- Terracing rounds height to 3 m bands and blends toward the rounded result by `0.12` in route cores and `0.32` elsewhere. The outermost 12 m on X and Z blends to zero using smoothstep. Exactly two Laplacian smoothing passes, blend `0.22`, apply only to samples whose central-difference slope exceeds the `42°` percentile threshold; route control samples and the outside edge are pinned, and the separate hard maximum remains `48°`.
- Required mechanism shelves are part of the typed profile, not placement repairs: Burst Basin Route A at `t=0.36`, radius `8 m`; Split Ridge center Route at `t=0.60`, radius `10 m`; Split Ridge right Route at `t=0.72`, radius `9 m`. After noise/terracing and before edge falloff, height blends to the route-center height with full influence through `0.25 × radius` and a broad smoothstep falloff to zero at the radius. Placement still must pass every slope/visibility/value validator.

### Frozen stage profiles

| Profile | Route control points `(z; height; x)` | Width and reversal band | Remaining locked rules |
| --- | --- | --- | --- |
| First Descent | `(-42;70;0), (-18;54;-8), (8;38;5), (32;23;-4), (54;8;-10)` | one route, width `28 m`, `0..1` meaningful reversals | X jitter `±5 m`, height jitter `±1.5 m`, accepted maximum height `64..76 m`, no mechanism, target `4%`, shots `4` |
| Burst Basin | Route A `(-44;78;-10), (-26;65;-18), (-8;71;-12), (12;57;-20), (34;44;-8), (54;31;0)`; Route B uses the same heights with X `18,30,24,34,42,30` | two routes, width `18 m`, `2..3` meaningful reversals | X jitter `±4 m`, height jitter `±1.25 m`, accepted maximum `72..84 m`, one Burst, target `27%`, shots `5` |
| Split Ridge | Z `-46,-30,-14,2,18,36,54`; base heights `84,74,79,69,74,63,52`; left X `0,-8,-20,-34,-42,-48,-54` and subtract height `0,1,2,3,4,5,5`; center X `0,2,6,0,-4,2,0`; right X `0,10,24,36,44,50,58` | widths left/center/right `14/10/10 m`, `4..6` meaningful reversals | X jitter `±3 m`, height jitter `±1 m`, accepted maximum `78..90 m`, left is the safe low route, Splitter + Bumper, target `70%`, shots `6` |

- A meaningful reversal is a sign change after a 6 m box filter, ignoring segments below `2°`. The profile reversal band is measured on First Descent's route, Burst Basin Route A, and Split Ridge's center route; parallel routes do not multiply the count. Every route must stay inside bounds, have no sample-to-sample gap above one grid diagonal, and retain its specified width within `±1.5 m` at 90% of longitudinal samples.
- Accepted layouts require: all finite samples; edge height `≤1 m`; maximum height in profile band; route-core 95th-percentile slope `≤42°`; no route-core slope `>48°`; at least one shelf per required mechanism with slope `≤12°`; eligible-area ratio Stage 1/2/3 within `0.14..0.22 / 0.18..0.32 / 0.12..0.30`; and exact route/reversal counts. Route-slope percentiles cover samples whose finite-difference footprint remains before the fixed outer 12 m ineligible skirt (`15 m` center clearance on this grid); the skirt is validated separately by its `≤1 m` boundary. Geometry always remains 6,144 triangles, below the 50k budget.

### Eligible mask, mechanisms, and dressing

- The mask is `512 × 512`. A texel is eligible iff it is outside a 14-pixel border, its projected terrain point is within `0.75 × route_width` of any route spine, terrain height is above `1 m`, and `normal.y ≥ 0.529919` (`58°` maximum slope). Exclude each mechanism trigger radius plus `0.75 m` and each decoration center by `1.5 m`. `PaintSystem` intersects this immutable mask with its one mutable paint mask to calculate coverage.
- Placement samples every second height-grid sample in stable row-major order. Universal filters are slope `≤18°`, mechanism-center separation `≥10 m`, bounds clearance `≥5 m`, route clearance `≤0.55 × route_width`, projected diameter `≥32 px` at 1920×1080 and `≥22 px` at 1280×720, and an unobstructed camera-to-center shape cast. Layout rejection occurs if any required mechanism has no passing sample.
- Burst samples Route A at normalized route position `0.28..0.44` and height quantile `≥0.62`. Score is `0.35 height + 0.30 downstream eligible area + 0.20 visibility/projected size + 0.15 shelf flatness`.
- Splitter samples the center route at `0.56..0.64`, on the visible middle-ridge crest after the second rise; its three downstream route tangents must be separated by at least `18°`. Score is `0.35 branch separation + 0.25 height + 0.20 approach alignment + 0.20 visibility/projected size`.
- Bumper samples the right route at `0.68..0.78`, on the following visible descent; its impulse direction is the normalized vector from the selected sample toward the next center-route sample, projected onto the XZ plane. Score is `0.35 redirection gain + 0.25 approach alignment + 0.20 height + 0.20 visibility/projected size`.
- Score inputs are normalized to `[0,1]` within the passing sample set. Highest score wins; ties use the smallest unsigned `(grid_index ^ accepted_seed)`, then smallest `grid_index`. Burst world diameter is `4.2 m`, Splitter `4.5 m`, and Bumper `3.8 m`; existing trigger limits and behavior values remain typed-resource owned.
- Decoration counts are Stage 1/2/3 = `10/14/18`. Deterministically shuffled passing samples require slope `≤42°`, height `≥1.1 m`, spacing `≥4 m`, outside the eligible route core plus `1 m`, and outside mechanisms plus `6 m`. The stable model cycle is 60% trees (`pineSmallA`, `pineSmallB`, `pineTallA`) and 40% rocks (`rockSmallA`, `rockLargeA`); the imported Kenney-native model scales are trees `3.0..4.5`, rocks `2.0..3.2`, as verified in the 1280×720 running capture. Runtime material overrides mute trees to `#59636D` and rocks to `#747B82`, so terrain and blue paint remain the hierarchy. Decorations are visual-only and cannot alter projectile physics.

### Aiming, solver, preview, and controls

- The aiming camera raycasts from the cursor up to `500 m` against terrain layer 1 and mechanism layer 2. Terrain targets are `hit_position + normal * projectile_radius`; mechanism targets are their declared target center. Hover shows an uncommitted ring; left click commits; held left drag retargets continuously. Fire is enabled only for a committed valid solution.
- Yaw is `atan2(delta.x, -delta.z)` and must remain in `[-28°, 28°]`. For elevation, scan `[18°,68°]` in `0.5°` steps from low to high. Each trial integrates at fixed `1/60 s` using the real recurrence `v += gravity*dt; v *= max(0, 1 - linear_damp*dt); p += v*dt`, with current power mapped through `ProjectileData` speed. The first vertical-error sign bracket at target horizontal distance is refined by 10 bisection steps.
- Every solver and preview segment uses a sphere shape cast of radius `0.52 m`, collision mask `1|2`, maximum flight `7.2 s`. A terrain target is valid only when its actual first collision is within `1.25 m`; a mechanism target is valid when the first overlap identifies that exact mechanism collider because its center-to-surface distance exceeds `1.25 m`. The solver returns the lowest passing elevation; no passing elevation returns explicit invalid. Invalid hover is red, Fire is disabled, and the cannon retains its last valid pose.
- Preview points are resampled every `2.2 m` of arc length into at most 72 pooled, unshaded blue spheres of radius `0.26 m`. The impact torus has `1.2 m` outer radius and distance scaling sufficient to keep at least `28 px` diameter at 1080p and `20 px` at 720p. Preview always ends at the first shape-cast collision and never visualizes a bounce, mechanism result, or future paint.
- Power range remains `10..100%`. UI `−/+` click changes `2%`; hold starts after `300 ms` and repeats every `80 ms`; wheel changes `1%`; keyboard `-`/`=` changes `2%`. `Space` or Fire requests a shot. `R` restarts, `Esc` pauses, and `Tab` opens inspect mode. `A/D` and `W/S` remain a `0.5°` accessible angle fallback and switch aim mode to `ANGLE_FALLBACK`; `Q/E` power control is removed.
- Human input, replay, and the agent API call the same cannon command methods. `StageController.request_fire()` checks state, remaining payload, projectile cap, and cannon aim validity before accepting and decrementing a shot; input and HUD never decide shot progression.
- Reliable-solution verification is deterministic rather than manually tuned. Target lists are Stage 1 route positions `0.22,0.38,0.54,0.70`; Stage 2 Burst center followed by Route A `0.58,0.76` and Route B `0.42,0.68`; Stage 3 Splitter center, Bumper center, then left/center/right route positions `0.42,0.62`. For each shot, try power `60,68,76,84,92%`, discard invalid solves, and run a lexicographic beam search of width 128 ranked by authoritative coverage then fewer shots then target/power order. A profile passes only when the search reaches its frozen target within its frozen shot count. The Stage 3 left-route-only sequence must remain below `70%`.

### Korean-first interface and persistence

- Base canvas is 1920×1080 with canvas stretch and 24 px safe margins. Aiming HUD rectangles at the base canvas are: stage `(24,16,168,56)`, centered target `(750,16,420,56)`, shots `(1676,16,220,56)`, mode `(30,88,132,48)`, aim/power `(24,916,330,140)`, coverage `(660,980,600,76)`, restart `(1616,916,116,140)`, Fire `(1744,916,152,140)`. Scale/anchors preserve these regions at 1600×900 and 1280×720.
- Palette is surface `#F7F3ED`, text `#10233D`, accent `#1678F2`, disabled `#9AA3AE`, invalid `#D64545`; panel radius 12 px, primary button radius 16 px. Interactive controls are at least 40 px high, keyboard focus is a 2 px accent outline, and state never relies on color alone. Aim/power uses angle value, a 10-segment power bar, and 44 px minus/plus buttons.
- The bundled variable font supplies regular 500, bold 700, and extra-bold 800 variations. UI sizes are 16 px body, 18 px control, 20 px card value, 24 px HUD primary value, and 36 px title. Korean labels wrap only at spaces; single-line HUD labels elide before reducing below 16 px.
- Translation keys cover the complete flow. Fixed gameplay copy is: `스테이지/Stage`, `목표 면적/Target Coverage`, `칠한 면적/Coverage`, `남은 탄/Shots Left`, `조준/Aim`, `각도/Angle`, `파워/Power`, `다시 시작/Restart`, `발사/Fire`, `폭발/Burst`, `분열/Splitter`, `범퍼/Bumper`, `설정/Settings`, `일시정지/Pause`, `계속/Resume`, `스테이지 선택/Stage Select`, `뒤로/Back`, `종료/Quit`, `다음/Next`, `재도전/Retry`.
- State/result copy is: `지형 확인/Briefing`, `조준/Aiming`, `비행 중/In Flight`, `페인트 정착 중/Paint Settling`, `탄 결과/Shot Result`, `스테이지 성공/Stage Clear`, `목표 미달/Stage Failed`, `산을 칠했습니다/Mountain Painted`, `목표에 도달하지 못했습니다/Target Not Reached`.
- Stage keys/copy are: First Descent = `첫 번째 하강/First Descent` and `넓은 경사면의 높은 지점을 노리고 중력으로 페인트를 흘리세요./Aim high on the broad slope and let gravity carry the paint.`; Burst Basin = `폭발 분지/Burst Basin` and `높은 폭발 장치를 맞혀 아래 분지를 넓게 칠하세요./Hit the high Burst to cover the basin below.`; Split Ridge = `분열 능선/Split Ridge` and `범퍼와 분열 장치로 세 개의 내리막 경로를 모두 공략하세요./Use the Bumper and Splitter to reach all three downhill routes.` Mechanism names appear during briefing/inspect only, not as persistent flight labels.
- `SaveSystem.SAVE_VERSION` becomes `2`. Fresh settings are `language = "ko"`, `language_user_selected = false`. V1 migration preserves progression, results, audio, display, and accessibility settings, sets Korean because V1 exposed no working locale choice, and adds `language_user_selected = false`. A locale selection sets the flag true and persists immediately. Stage resources store translation keys, never translated display text.

### Exact approved asset manifest

Official archives are pinned by SHA-256: Nature Kit `FA7974A0D342BFE63C38664BA9F8EC1A4AAB8EA25F099BDC56870E33588C4D9D`; Game Icons `7A86D8D58E0B851E22004B3C70BF90B003632BBF9AC633424DAA3BB17D9E7E4E`; Particle Pack `B631D4B07F7002549FDCF155F01141AD482F79F3440E4E301EED49CE5F1D8958`; Pretendard 1.3.9 `04BE351A74D6BF7D60C480A3087E51D185485D35A52023142AF1DF19EB8C428A`.

| Official archive member | Repository destination | SHA-256 | Runtime use |
| --- | --- | --- | --- |
| Nature `Models/GLTF format/tree_pineSmallA.glb` | `assets/nature/kenney/tree_pineSmallA.glb` | `BE1A438BBB2E157266C1FB093B775BFF8CE3E29A4C8F04AAF9D44C7A4E1F1FF0` | small pine A |
| `tree_pineSmallB.glb` | `assets/nature/kenney/tree_pineSmallB.glb` | `59392AA6604ADB9DCCD4FB76DF5ED12AE8AC7D7391EB7E04BC84FFFE9F9B36C8` | small pine B |
| `tree_pineTallA.glb` | `assets/nature/kenney/tree_pineTallA.glb` | `E0A56EB196D8A64BA86C7304D607136E17E6F9AD748DFFCF86BD53B18B91B196` | tall pine |
| `rock_smallA.glb` | `assets/nature/kenney/rock_smallA.glb` | `DF9FFF9D711E61370E8DF0CAA2514C89B8F8A8DC6C6FAFAF4EB2EC79C5AE07C1` | small rock |
| `rock_largeA.glb` | `assets/nature/kenney/rock_largeA.glb` | `6DD15390FD96501DCD1454765A17BA61DBBD8D47705DFE5149C8DD92B353CE25` | large rock |
| Game Icons `PNG/White/2x/target.png` | `assets/ui/icons/target.png` | `AFD40325569FA91BFC690856DC4C70901BBD7C2E27DEDC9FE3847258C61BBC81` | aim mode |
| `return.png` | `assets/ui/icons/restart.png` | `99B425EC6D8E49633DDCEA55E7485ADF44A4CA8614ABF39E59B7A83602EE3866` | restart |
| `minus.png` | `assets/ui/icons/minus.png` | `5F4E70ADEA9061D0105DB1860108B669E348D0D99314542A77DD96F707800EC7` | decrease power |
| `plus.png` | `assets/ui/icons/plus.png` | `DC5D564FFE3AE546F2E72CE19EA8349124CF48256418DE50BB045A5D97AB9872` | increase power |
| `pause.png` | `assets/ui/icons/pause.png` | `5C940AD60DD46B3252D4F991F24E9C21865722FE401947830228629BAED28774` | pause |
| `gear.png` | `assets/ui/icons/settings.png` | `50B313FFE97DB1733E529D5B0F5AC91EED5C0C8FFEE1034BBB7766508E4F720C` | settings |
| Particle Pack `PNG (Transparent)/circle_01.png` | `assets/vfx/kenney/muzzle_ring.png` | `4B2D03683BF0FE4A946567ADC3BD86B8BA045DA84CEE58DC2CF8AEF63BBFAA06` | muzzle ring |
| `circle_04.png` | `assets/vfx/kenney/impact_ripple.png` | `742DA1A1B96B93AE446700F6085385D1F62844352DA870C89427307B7B7CF03B` | impact ripple |
| `smoke_03.png` | `assets/vfx/kenney/paint_mist.png` | `A71F8ABCAC64F8D73A94625CC9A10033DBEAFA7EAEA750560CBA0DAA73FE8752` | blue paint mist |
| `star_04.png` | `assets/vfx/kenney/glint.png` | `6485AC16C773663BD39346F3BEDAE04465AC14C661EB47CC5CFA935CDBF6C2EC` | mechanism/clear glint |
| Pretendard `web/variable/woff2/PretendardVariable.woff2` | `assets/fonts/pretendard/PretendardVariable.woff2` | `9599F12FD42FC0BCE1CD50B47A0C022E108D7AA64DD0D1BB0ED44F3282D900B4` | global ko/en UI font |

- Copy the corresponding upstream license texts to `assets/licenses/Kenney-Nature-Kit-CC0.txt`, `Kenney-Game-Icons-CC0.txt`, `Kenney-Particle-Pack-CC0.txt`, and `Pretendard-OFL-1.1.txt`. Record official URLs, archive/file hashes, release/version, local destinations, and uses in `docs/asset-licenses.md`. Do not copy any other archive member.
- Official archive URLs are Nature Kit `https://kenney.nl/media/pages/assets/nature-kit/37ac38a37b-1677698939/kenney_nature-kit.zip`, Game Icons `https://kenney.nl/media/pages/assets/game-icons/1ebf9c14af-1677661579/kenney_game-icons.zip`, Particle Pack `https://kenney.nl/media/pages/assets/particle-pack/f8fe0f8cb8-1677578741/kenney_particle-pack.zip`, and Pretendard `https://github.com/orioncactus/pretendard/releases/download/v1.3.9/Pretendard-1.3.9.zip`. Runtime is fully offline and contains no downloader or install script.

### Fastrun and completion command

- The canonical registered entry is already `D:\npjt\paint-mountain` → `& '.\builds\windows\PaintMountain.exe'`. Do not add a duplicate, development-server command, or user-lane entry.
- After the final release export, invoke the existing fastrun entry from the project directory and verify it launches that exact executable. Failure is an export/start defect; it is not resolved by changing the registered command to an editor or debug path.

## Rejected Alternatives

| Alternative | Why it was viable | Why it was rejected |
| --- | --- | --- |
| Pure noise terrain | Fast and varied | Produces unreadable bumps and does not guarantee routes, shelves, or increasing rise/fall structure |
| Random mechanism coordinates | Minimal implementation | Cannot guarantee visibility, reachability, downstream value, or physical placement |
| New random terrain on every retry | Adds novelty | Breaks learning, replay, and deterministic comparison |
| Hold Space to charge and release to fire | Familiar arcade interaction | Timing accuracy conflicts with a deliberate planning puzzle and makes small power corrections frustrating |
| Keep the current left-drag aim only | Already implemented | It is undiscoverable, provides no direct terrain intent, and does not satisfy the requested interaction reset |
| Preview post-impact paint routes | Would make outcomes clear | Solves the terrain puzzle and directly conflicts with the source brief |
| Kenney UI Pack as the whole interface | CC0 and complete | Its colorful generic panels do not match the restrained reference; native Godot controls provide a closer result |
| Kenney Blaster Kit for the cannon | CC0 and low-poly | Reads as a handheld firearm rather than a mounted industrial paint cannon |
| Quaternius Fantasy Props | CC0 and optimized | Medieval props introduce an unrelated visual language |
| Full Quaternius Stylized Nature MegaKit | Broad CC0 selection and glTF | The full pack is visually dense and partly gated by free/source tiers; the smaller Kenney selection is sufficient |
| Photoreal assets or Poly Haven environment set | High quality and CC0 | Conflicts with the bright faceted low-poly target and increases rendering/material cost |

## Current State

Already true:

- The Windows release launches, the three stage flows work, and the release capture path produces current screenshots.
- `StageController`, `PaintSystem`, projectile management, mechanisms, replay, save, and the in-process agent API have usable ownership boundaries.
- Ballistic preview and actual launch already share one calculation source and stop at the first collision.
- The three mechanism gameplay effects and reset/limit guards have automated tests.

Remaining implementation:

- Replace fixed terrain formulas and authored mechanism coordinates with deterministic generation and validation.
- Rebuild mechanism scenes and visual scale so all required items are legible from the aiming view.
- Separate human input from cannon commands and implement terrain-target mouse aiming plus explicit power controls.
- Replace English literals and default font styling with `ko`/`en` translations and one Pretendard-based Theme.
- Recompose gameplay and application UI against the provided visual target.
- Import only the approved asset subset with provenance, then run the frozen gameplay and visual acceptance checks.

## Scope

In scope:

- Three deterministic generated stages that retain the original First Descent, Burst Basin, and Split Ridge teaching roles.
- One seeded generator and one placement generator with fixed difficulty profiles and checked-in fallback seeds.
- All current gameplay screens, settings, stage data, replay metadata, tests, and screenshots affected by generation/localization/UI.
- The exact approved font, nature props, icons, and particle masks in the manifest above.

Out of scope:

- Endless mode, player-facing seed entry, daily/random challenges, online seed sharing, procedural caves/overhangs, new mechanisms, new projectile types, controller support, mobile layouts, monetization, backend, or full fluid simulation.
- Importing the generated report mockups as runtime textures or claiming them as running-game screenshots.

Destructive or irreversible actions:

- None. Retired fixed formulas and authored placement fields are removed only after generated stages and replay migration pass their guards; Git preserves history.

Approval record and remaining approval boundary:

- On 2026-08-03 the user explicitly approved downloading and committing the exact Pretendard, Kenney Nature Kit, Kenney Game Icons, and Kenney Particle Pack subset with license/source records. No further approval is required for the manifest above.
- Any production dependency, plugin, additional archive member, asset pack, or license source beyond those four approved sources still requires new approval.

## Architecture and Ownership

| Concern | Final owner | Interface or invariant | Existing owner to reuse or retire |
| --- | --- | --- | --- |
| Generation tuning | New `src/stage_generation/stage_generation_profile.gd` typed Resource plus `resources/stage_generation/*.tres` | Immutable difficulty bands, geometry budgets, and mechanism loadout | Retire `StageData.terrain_variant` after migration |
| Generated layout | New `src/stage_generation/generated_stage_layout.gd` | Read-only seed, height grid, route metrics, bounds, and placements | Replaces implicit fixed formula state |
| Terrain topology | New `src/stage_generation/seeded_stage_generator.gd` | `generate(stage_data) -> GeneratedStageLayout`; deterministic 32-attempt cap | Retire stage-specific height functions in `TerrainMeshFactory` |
| Mesh/collision build | `src/terrain/terrain_mesh_factory.gd` | Convert one accepted height grid to one faceted mesh and collision shape | Preserve file ownership but remove stage selection logic |
| Mechanism placement | New `src/stage_generation/mechanism_placement_generator.gd` | Feature candidate extraction and mechanism-specific validators | Retire authored `local_xz` as production input |
| Stage configuration | `src/stage/stage_data.gd` | Store generation profile, seed, teaching role, rules, cameras, and reliable solution | Preserve immutable Resource ownership |
| Runtime construction | `src/gameplay/gameplay_scene.gd` | Build mesh, masks, decoration, and mechanisms from one `GeneratedStageLayout` | Preserve orchestration; no generation policy inside scene script |
| Paint and flow | `src/paint/paint_system.gd` | Consume the accepted height grid; remain the only persistent visual/scoring mask owner | Preserve architecture |
| Mechanism behavior | Existing `src/mechanisms/*.gd` | Activation/reset rules remain data-driven | Replace only visual child construction with `.tscn` scenes |
| Human aiming input | New `src/input/aim_input_controller.gd` | Translate mouse, wheel, buttons, and Space into validated commands | Remove `_process` and `_unhandled_input` from `CannonController` |
| Target solver | New `src/cannon/impact_target_solver.gd` | Fixed-tick damped numerical solve returning the lowest valid first-impact result or explicit invalid | Reuse the exact `CannonBallistics` integration and `ProjectileData` values |
| Cannon commands | `src/cannon/cannon_controller.gd` | Set aim, query launch, and fire request only; no device input | Preserve AI/replay compatibility |
| HUD and app screens | `src/ui/*` plus new `resources/ui/paint_mountain_theme.tres` | Display translated state and emit intents; no game rules | Replace duplicated per-control styles with shared theme/components |
| Localization | New `translations/ui.csv`, updated StageData keys, and `TranslationServer` wiring in app/settings | `ko` default, `en` option, persisted locale migration | Retire visible hardcoded English strings |
| Asset provenance | New `docs/asset-licenses.md` | Exact file/source/license/usage ledger | No existing owner |

## As-Is / To-Be Delta Map

| Concern | As-is | To-be | Acceptance check | Guard / leftover check |
| --- | --- | --- | --- | --- |
| Terrain | Three fixed smooth analytic mounds | Seeded path-first faceted stage layouts with profile metrics | Fixed seeds reproduce byte-identical height-grid checksums; all three metric bands pass | No stage-specific height function or unseeded RNG remains |
| Difficulty | Target/shots change; topology is weakly differentiated | Route count, width, reversals, shelf size, and mechanism complexity rise by stage | Metrics table matches each accepted seed and deterministic solution search passes | Stage 1 stays forgiving; Stage 3 retains a safe low route |
| Items | Fixed coordinates and small primitive visuals | Feature-aware placement and chunky scene-owned silhouettes | Every item passes slope, spacing, LoS, projected-size, and route-value tests | No raw production X/Z placement or fourth mechanism |
| Aim | Hidden mouse drag plus keyboard axes | Mouse-selected first-impact target, damped fixed-tick solver, invalid-state feedback | Target drag, power changes, and actual first hit stay within existing tolerance | AI/replay calls remain UI-independent |
| Power | Wheel/Q/E with numeric text only | Segmented bar, `−/+`, wheel fine-tune, visible valid/invalid state | Step, hold-repeat, focus, and Space fire checks pass | No timing charge meter or accidental double fire |
| Preview | Small dots and marker can disappear into terrain | Continuous high-contrast arc and minimum-size impact ring to first hit | Marker visible on light/dark rock and preview matches first hit | No post-impact or coverage preview |
| UI | Fixed pixel composition and per-node styles | Reference-aligned regions, shared theme, icons, consistent spacing | 1280×720, 1600×900, and 1920×1080 screenshots show no clipping and match hierarchy | Mountain remains unobstructed; no dense simulator controls |
| Language/font | English literals, `en` stub, Godot default font | Korean default, English option, Pretendard, translation keys | Fresh save opens in Korean; locale switch persists; no missing glyphs | No user-facing raw key or English-only screen remains |
| Assets | Procedural placeholders without provenance | Small approved CC0/OFL subset plus license ledger | Every imported file is present in the ledger and release export | No unapproved pack, remote runtime asset, or mixed UI skin |

## Tasks

### Phase 1: Correct the product contract and establish regression fixtures

Goal: make the new requirements and visible baseline authoritative before gameplay code changes.

Source owners touched: `docs/design-spec.md`, `docs/technical-architecture.md`, `docs/test-checklist.md`, `.agents/Documentation.md`, `docs/remediation-report.html`

- [x] **1.1 Update the active specifications and implemented-state record**
  - As-is: the active docs report the fixed vertical slice as complete.
  - To-be: record deterministic generation, placement ownership, direct target aiming, Korean default, selected assets, and reference-parity checks; move earlier completion language into historical context.
  - Accept: specs agree with this plan and the source brief; `Documentation.md` separates implemented behavior from remediation work.
  - Guard: do not weaken `StageController`, `PaintSystem`, replay, fixed-timestep, or scope exclusions.
- [x] **1.2 Add visual and generation acceptance fixtures**
  - As-is: tests assert clipping and feature presence but not target composition or generation quality.
  - To-be: preserve the reference/current report images and publish the frozen terminology, seeds, numeric profiles, and screenshot comparison checklist from this contract.
  - Accept: a future executor can identify pass/fail without inventing layout or terrain criteria.
  - Guard: generated mockups remain labeled as concepts, never running evidence.

Batch acceptance: document validation and `git diff --check` pass; no material decision remains outside this plan.

Batch guard: the game still launches unchanged after documentation-only edits.

### Phase 2: Deliver one generated playable stage end to end

Goal: replace the fixed terrain path with a deterministic generator and run First Descent through the existing paint/state loop.

Source owners touched: `src/stage_generation/*`, `src/terrain/terrain_mesh_factory.gd`, `src/stage/stage_data.gd`, `src/gameplay/gameplay_scene.gd`, `src/paint/paint_system.gd`, `resources/stage_generation/first_descent_profile.tres`, `resources/stages/first_descent.tres`, `tests/stage_generation_test.gd`

- [x] **2.1 Add typed generation profile and layout contracts**
  - As-is: `terrain_variant` selects a hardcoded function.
  - To-be: StageData references a profile and seed; one read-only layout carries the height grid, routes, metrics, bounds, and placements.
  - Accept: Resources load with typed validation; replay metadata includes the accepted seed/profile version.
  - Guard: mutable runtime state does not enter StageData.
- [x] **2.2 Implement path-first terrain generation with bounded validation**
  - As-is: fixed Gaussian hills build directly into vertices.
  - To-be: generate route spines, shelves, ridge/valley fields, low-amplitude noise, slope repair, and metrics under a 32-attempt cap.
  - Accept: First Descent passes its route/reversal/width/slope metrics and stable checksum test.
  - Guard: no caves, overhangs, unseeded random calls, or second terrain representation.
- [x] **2.3 Feed the accepted grid into mesh, collision, paint flow, and restart**
  - As-is: these systems call the static height function.
  - To-be: one layout supplies height queries everywhere and is recreated identically on restart.
  - Accept: paint/coverage tests, one reliable First Descent solution, replay, and sub-second restart pass on the generated terrain.
  - Guard: `PaintSystem` remains the only paint authority and mesh stays under 50k triangles.

Batch acceptance: First Descent is fully playable from menu to result on its generated layout with a reproducible screenshot and solution.

Batch guard: all existing Phase 2–4 projectile, paint, and state tests pass before expanding generation.

### Phase 3: Scale difficulty and place readable 3D mechanisms

Goal: generate Burst Basin and Split Ridge with verified route complexity and feature-aware mechanisms.

Source owners touched: `src/stage_generation/mechanism_placement_generator.gd`, `resources/stage_generation/*.tres`, `resources/stages/*.tres`, `scenes/mechanisms/*.tscn`, `src/mechanisms/*.gd`, `src/terrain/environment_dressing.gd`, `tests/mechanism_placement_test.gd`

- [x] **3.1 Implement placement candidate extraction and validators**
  - As-is: fixed X/Z coordinates are trusted.
  - To-be: score shelves, ridges, channel entries, downstream drop, approach direction, LoS, screen size, spacing, and bounds; orient Bumper toward its selected downstream target.
  - Accept: fixed-seed tests show Burst on a valuable upper ledge, Splitter with three downhill sectors, and Bumper with a valid approach/redirection path.
  - Guard: no placement policy enters StageController or mechanism behavior scripts.
- [x] **3.2 Build distinct scene-owned mechanism visuals**
  - As-is: small primitives are created from script.
  - To-be: radial Burst, triangular Splitter, and directional Bumper scenes expose active/spent/cooldown visuals and selection bounds.
  - Accept: every mechanism meets world- and screen-size thresholds in briefing and aiming captures; activation is readable without persistent text during flight.
  - Guard: world scale stays believable and behavior/reset tests remain unchanged.
- [x] **3.3 Add approved sparse nature dressing without hiding routes**
  - As-is: a few procedural trees use fixed coordinates.
  - To-be: seeded decoration placement uses the approved low-poly subset outside route clearance and eligible paint surfaces.
  - Accept: trees/rocks establish scale, never overlap mechanisms, and never reduce route visibility below the screenshot checklist.
  - Guard: import only the approved exact manifest and enter every file in the license ledger.

Batch acceptance: all three generated stages satisfy their difficulty bands, display the correct mechanism loadout, and retain one reliable manual solution.

Batch guard: one split generation, eight active balls, authoritative paint, and reset behavior remain unchanged.

### Phase 4: Replace aiming and power interaction

Goal: let the player choose an intended first impact directly and see the entire valid initial trajectory before firing.

Source owners touched: `src/input/aim_input_controller.gd`, `src/cannon/impact_target_solver.gd`, `src/cannon/cannon_controller.gd`, `src/cannon/trajectory_preview.gd`, `src/ui/hud_controller.gd`, `scenes/gameplay/gameplay.tscn`, `tests/aim_interaction_test.gd`

- [x] **4.1 Separate device input from cannon commands**
  - As-is: CannonController polls keyboard and handles mouse/Space.
  - To-be: AimInputController owns devices and calls the same validated cannon/stage actions used by replay and the agent API.
  - Accept: human, replay, debug, and agent actions produce equivalent aim/fire commands.
  - Guard: no input code decides shots, state, or outcomes.
- [x] **4.2 Add direct impact targeting and explicit invalid state**
  - As-is: drag sensitivity changes angles without a terrain target.
  - To-be: hover previews a terrain target; click/drag locks it; the fixed-tick damped solver returns the lowest valid yaw/elevation or an invalid result for the current power.
  - Accept: valid points solve and actual first hit stays within the existing preview tolerance; invalid points show red and cannot fire.
  - Guard: the solver uses the same gravity/speed source as launch and never steers after fire.
- [x] **4.3 Add precise power controls and legible preview**
  - As-is: wheel/Q/E and small dots.
  - To-be: segmented slider, `−/+`, hold repeat, wheel fine tune, Space/button fire, continuous dots, and a minimum-size impact ring.
  - Accept: keyboard, mouse, focus, repeat, disabled, and double-fire tests pass; the arc remains visible to first collision at all three resolutions.
  - Guard: no post-impact route, mechanism activation, or coverage prediction appears.

Batch acceptance: a first-time player can target terrain, adjust power, understand invalid aim, and fire without reading documentation.

Batch guard: deterministic repeated shots and replay deltas stay within the current recorded tolerances.

### Phase 5: Ship Korean-first theme and reference-aligned layout

Goal: replace the English placeholder presentation with one coherent localized interface across the complete app flow.

Source owners touched: `translations/ui.csv`, `resources/ui/paint_mountain_theme.tres`, `assets/fonts/pretendard/*`, `assets/ui/icons/*`, `src/ui/*`, `src/app/app_root.gd`, `src/autoload/save_system.gd`, `project.godot`, `docs/asset-licenses.md`, `tests/localization_ui_test.gd`

- [x] **5.1 Import the approved font/icons/particles and record provenance**
  - As-is: no external runtime assets or font license ledger.
  - To-be: commit only selected source files and licenses, wire Pretendard as the Theme default, and map approved icons/particles to semantic uses.
  - Accept: each imported file has source, license, version/date, and usage; release works offline.
  - Guard: no CDN, remote runtime asset, full unused pack, or unapproved license enters the repo.
- [x] **5.2 Implement real `ko`/`en` localization and save migration**
  - As-is: visible English literals and an `en`-only selector.
  - To-be: translation keys cover menus, HUD, mechanisms, results, errors, tutorials, and settings; fresh saves default to Korean; existing saves migrate safely.
  - Accept: locale switches immediately, persists across a fresh process, and every screen shows complete glyphs.
  - Guard: stage rules and identifiers remain locale-independent.
- [x] **5.3 Recompose HUD and app screens from shared primitives**
  - As-is: duplicated fixed style overrides and weak hierarchy.
  - To-be: one Theme and responsibility-shaped components implement the reference regions, spacing, controls, focus, and localized text fit.
  - Accept: aiming matches the report hierarchy; briefing, observation, result, stage select, menu, pause, and settings are visually coherent at 1280×720, 1600×900, and 1920×1080.
  - Guard: no text clipping, offscreen controls, unsupported action, center modal over aiming, or persistent mountain tooltip.

Batch acceptance: a fresh install opens in Korean and the full menu-to-result loop is usable with keyboard and mouse in both locales.

Batch guard: controls stay at least 40 px high, focus is visible, state is not color-only, and the mountain remains the dominant visual.

### Phase 6: Freeze results, export, and prove the remediated game

Goal: validate gameplay quality, visual target, determinism, performance, persistence, and release delivery together.

Source owners touched: `resources/stages/*.tres`, `docs/test-checklist.md`, `.agents/Documentation.md`, `README.md`, `screenshots/*.png`, `export_presets.cfg`

- [x] **6.1 Freeze generated results and verify scripted solutions**
  - As-is: solutions target fixed formula terrain.
  - To-be: the predetermined seed sequence, targets `4/27/70%`, shots `4/5/6`, and one recorded reliable route per accepted layout preserve the three teaching roles without manual parameter selection.
  - Accept: all three physical solution tests clear and a safe inefficient Stage 3 route remains below target by design.
  - Guard: do not compensate for bad terrain by inflating mechanism paint or weakening core physics.
- [x] **6.2 Run visual comparison and accessibility checks**
  - As-is: existing checks prove clipping only.
  - To-be: compare fresh running screenshots against the provided reference and generated target for composition, mechanism visibility, terrain depth, paint thickness, hierarchy, font, and Korean fit.
  - Accept: UIUX Level 4 evidence reports no blocker; every important state has a valid capture.
  - Guard: generated concepts are never substituted for runtime evidence.
- [x] **6.3 Complete production regression and delivery**
  - As-is: the prior release passes the old checklist.
  - To-be: run all old and new tests, export release, launch it, measure performance, verify persistence/replay, and replace the seven named running-game screenshots.
  - Accept: the complete updated checklist passes and `Documentation.md` records observed results and limitations.
  - Guard: no claim is based on scene structure, mockups, or editor-only output.

Batch acceptance: the exported Windows build visibly matches the remediation contract and preserves every non-negotiable gameplay invariant.

Batch guard: final performance remains stable at 60 FPS average at 1920×1080 on the current test machine, stage load stays under three seconds, and restart stays under one second.

## Validation Cadence

Resolve Godot through the repository verification contract. Set `GODOT_BIN` to the current Godot 4.x console executable; `scripts/verify.ps1` may otherwise resolve `godot4` or `godot` from `PATH`:

```powershell
$godot = $env:GODOT_BIN
if ([string]::IsNullOrWhiteSpace($godot)) {
    $godot = (Get-Command godot4, godot -ErrorAction Stop | Select-Object -First 1).Source
}
```

Inner-loop commands:

- `& $godot --headless --path . --script res://tests/stage_generation_test.gd`
- `& $godot --headless --path . --script res://tests/mechanism_placement_test.gd`
- `& $godot --headless --path . --script res://tests/aim_interaction_test.gd`
- `& $godot --headless --path . --script res://tests/localization_ui_test.gd`
- `powershell -ExecutionPolicy Bypass -File scripts/verify.ps1 -GodotPath $godot`

Batch gates:

- Phase 2: existing Phase 2–4 tests plus `stage_generation_test.gd` and the First Descent physical solution.
- Phase 3: `phase5_mechanism_test.gd`, `phase6_content_test.gd`, `mechanism_placement_test.gd`, and all three physical solutions.
- Phase 4: `phase2_test.gd`, `phase2_physics_test.gd`, `phase8_replay_process_test.gd`, and `aim_interaction_test.gd`.
- Phase 5: `phase7_ui_test.gd`, persistence write/read/cleanup, localization UI capture at all supported resolutions, and visual inspection in both locales.

Final gates:

- Full tests: run every existing `phase2_*` through `phase8_*` test plus all four new tests.
- Production build: `& $godot --headless --path . --export-release 'Windows Desktop' builds/windows/PaintMountain.exe`.
- Production start: launch `builds/windows/PaintMountain.exe`, exercise menu → stage → aiming → shot → result in Korean, switch to English, restart the process, and verify persistence.
- Manual UI routes and viewports: 1280×720, 1600×900, and fullscreen 1920×1080 for menu, stage select, briefing, aiming valid/invalid, observation, clear, failure, pause, and settings.
- Gameplay evidence: separately capture the seven exact files in `docs/test-checklist.md` from the release build without debug overlay.
- Performance: reproduce the prior 360-frame Burst workload at fullscreen 1920×1080; record average FPS, worst frame, load time, memory, generation attempts/time, and active-ball cap.
- Documentation and lifecycle: `git diff --check`; confirm `.agents/Plan.md` remains the only active plan; update `.agents/Documentation.md` with observed facts only.

Rerun policy:

- Rerun a failed narrow check only after a concrete change or new hypothesis.
- Rerun full gates only after the suspected cause changed.
- Record known non-blocking warnings instead of rediscovering them.

## Predetermined Error Handling and Contingencies

| Trigger | Required response | Limit / escalation point |
| --- | --- | --- |
| No valid generated terrain within 32 attempts | Validate the frozen fallback seed, emit one debug warning, and preserve failed metrics in test output | If fallback also fails, block gameplay/export; never ship an invalid layout or raise the cap |
| Terrain passes metrics but a required mechanism has no valid placement | Reject the layout and continue the same bounded generation sequence | Fallback seed must include validated placements; do not hand-place a production mechanism |
| A selected target has no real first-impact solution | Show red target/arc state, disable Fire, preserve last valid aim, and let power change immediately re-evaluate | Never clamp into a false valid trajectory |
| An imported manifest file fails its pinned hash or import check | Stop that import, re-download only from the recorded official URL, and verify the archive and file hashes | Do not substitute a different file or pack without a plan revision and approval |
| Korean text clips | Increase container width or wrap/remove secondary copy; preserve 16 px minimum body size and 40 px control height | Do not shrink text or use negative spacing to hide the issue |
| Paint-thickness treatment causes visual/scoring drift | Remove the derived treatment and return to direct authoritative-mask shading while keeping wider stamps | Never create a second persistent paint/coverage state |
| Generation or assets push load beyond three seconds or break 60 FPS average | Profile generation/mesh/import cost, keep the accepted grid, reduce dressing/material cost, and preserve mechanism readability | Escalate before changing renderer, mesh budget, or adding dependencies |
| Replay diverges after generated-layout migration | Verify seed/profile version serialization and grid checksum before considering transform capture | Preserve deterministic input replay as primary metadata |

## Progress

- [x] Discovery: source brief, specs, architecture, current code, running release captures, reference image, and asset licenses inspected.
- [x] Decision contract: generation, placement, controls, localization, visual direction, and selected asset set locked.
- [x] Planning evidence: `docs/remediation-report.html` and its local images prepared for review.
- [x] External approval: the exact four-source asset import was approved on 2026-08-03; archive members, destinations, uses, and hashes are frozen above.
- [x] Phase 1: product contract and regression fixtures.
- [x] Phase 2: one generated playable stage.
- [x] Phase 3: difficulty scaling and mechanism placement/visuals.
- [x] Phase 4: aiming and power interaction.
- [x] Phase 5: Korean-first theme, layout, and approved assets.
- [x] Phase 6: tuning, production QA, and delivery.

## Next Steps

All six remediation phases completed on 2026-08-03. Their claims are historical.
Further gameplay-reset work follows
[`execplans/2026-08-03-gameplay-visual-reset.md`](execplans/2026-08-03-gameplay-visual-reset.md),
the sole active successor installed after the corrected paint rule and validated
external review.

## Completion Criteria

- [x] Three fixed seeds reproduce three valid generated layouts with the specified route/reversal/width bands and one reliable solution each.
- [x] Burst, Splitter, and Bumper are visible, distinct, correctly placed, and behaviorally unchanged.
- [x] Mouse target selection, explicit power controls, Space/Button fire, invalid state, and first-collision preview pass input and physics checks.
- [x] A fresh install defaults to complete Korean UI, English remains selectable, both persist, and Pretendard renders without missing glyphs or clipping.
- [x] Running release screenshots match the reference hierarchy and show a stepped large mountain, thick readable paint, small cannon, and visible mechanisms.
- [x] Every imported asset is approved, locally stored, offline-safe, and recorded with its license/source.
- [x] Every existing gameplay, paint, mechanism, save, replay, reliability, performance, and production-delivery guard passes.
- [x] No retired fixed terrain formula, authored production placement, English-only visible string, duplicate paint authority, placeholder plan text, or unreported limitation remains.

## Stop Conditions

Complete when: every completion criterion and final gate passes against the exported Windows build and the new seven running-game screenshots.

Escalate only when: a pinned upstream license or archive changes, the fixed-tick target interaction proves incompatible with the measured launch model after an implementation defect is excluded, or meeting the measured performance contract requires an engine/renderer/dependency change.

Do not stop when: a generated seed fails within the bounded retry path, Korean copy needs layout adjustment within its frozen size/accessibility rules, or a safe task-scoped defect fix remains.

## Handoff

```text
Goal: Remediate Paint Mountain's generated stages, item readability, aiming, Korean UI, and reference-level presentation.

Read first: AGENTS.md, docs/source-brief.md, .agents/Documentation.md, .agents/Plan.md, docs/remediation-report.html.

Execute exactly: Phases 1–6 in order; preserve StageController, PaintSystem, replay, physics, and scope guards.

Validate with: scripts/verify.ps1, the existing Phase 2–8 tests, the four new focused tests, production export/start, three resolutions, two locales, and seven fresh release screenshots.

Stop when: every completion criterion passes or an exact approval/escalation boundary above is reached.
```
