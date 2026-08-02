---
type: plan
status: active
created: 2026-08-02
scope: procedural stage generation, mechanism placement, aiming interaction, Korean-first UI, visual remediation, and licensed asset integration
source: user remediation directive dated 2026-08-02
related:
  - Prompt.md
  - Documentation.md
  - ../docs/source-brief.md
  - ../docs/design-spec.md
  - ../docs/technical-architecture.md
  - ../docs/test-checklist.md
  - ../docs/remediation-report.html
---

# Paint Mountain Core Experience Remediation Plan

The current build contains the original three-stage rules, paint mask, projectile physics, mechanisms, replay, and export path, but it does not yet deliver the requested procedural mountain progression, readable item placement, Korean-first interface, direct aiming interaction, or reference-level visual composition. This plan replaces the completed vertical-slice plan with six executable remediation phases that preserve the working gameplay owners while rebuilding the visible core experience.

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
| Kenney asset pages and support page, accessed 2026-08-02 | Nature Kit, Game Icons, and Particle Pack are CC0; attribution is not required | Selects the external art set subject to the repository approval gate | Recheck license immediately before download |
| Pretendard official repository and license, accessed 2026-08-02 | Pretendard supports Korean and mixed-script UI under SIL OFL 1.1 | Selects the UI font subject to the repository approval gate | Recheck release and license immediately before download |
| Godot stable asset/font documentation, accessed 2026-08-02 | glTF 2.0 is the recommended 3D format; WOFF2 is supported as a dynamic font | Locks import formats | Recheck only if the engine version changes |

## Locked Decisions

| Topic | Final decision | Rationale / source |
| --- | --- | --- |
| Authority | The original source brief remains the product baseline; the 2026-08-02 feedback adds required procedural generation, Korean-first UX, and reference-parity remediation | Root `AGENTS.md` and explicit user feedback |
| Stage randomness | Every stage is generated from immutable `stage_id + stage_version + terrain_seed + profile`; retry and replay reuse the same output | Preserves learnability, replay, and identical-shot behavior |
| Terrain method | Use a path-first `64 × 48` height grid: build route spines and landing shelves, add ridge/valley fields, apply low-amplitude seeded `FastNoiseLite`, smooth only invalid slopes, then emit one faceted heightfield mesh | Produces readable routes instead of uncontrolled noise and stays far below the 50k-triangle budget |
| Generator retries | Evaluate at most 32 deterministic attempts (`seed + attempt_index`) and accept the first layout that passes the profile metrics; otherwise use the checked-in fallback seed for that profile and log once in debug | Prevents invalid or unbounded generation |
| Difficulty progression | Stage 1: one broad route, 0–1 meaningful slope reversals, 24–32 m route width, no mechanism. Stage 2: two routes, 2–3 reversals, 14–22 m width, one upper Burst. Stage 3: three routes, 4–6 reversals, 8–16 m width, one safe low route plus Splitter and Bumper on high-value routes | Directly encodes the requested increase in descending and rising sections while preserving the three-stage brief |
| Meaningful reversal | Count a rise/downhill sign change only after smoothing samples over 6 m and ignoring grades below 2° | Keeps small surface noise from inflating difficulty |
| Placement method | Generate feature candidates from shelves, ridges, channel entries, downstream drop, and aiming-camera visibility; mechanism-specific validators select from those candidates. No raw random X/Z placement remains | Items must support legible routes, not decoration |
| Placement readability | Mechanism base slope ≤ 18°, center separation ≥ 10 m, world diameter 3.2–4.5 m, projected diameter ≥ 32 px at 1920×1080 and ≥ 22 px at 1280×720, and unobstructed line of sight to the center from the aiming camera | Makes items visible without making the mountain miniature |
| Mechanism visuals | Keep the existing behavior scripts. Move visuals into three `.tscn` scenes: radial-lens Burst, triangular three-way Splitter, and arrowed directional Bumper, using white/gray/navy/blue chunky geometry and active/spent/cooldown states | Distinct silhouettes are a source-brief requirement; custom visuals fit better than generic packs |
| Aiming interaction | The mouse selects and drags a first-impact target directly on visible terrain. A pure low-arc solver derives yaw/elevation for the current power. Invalid solutions show a red marker and disable Fire while retaining the last valid aim | This is materially more direct than the current hidden drag sensitivity while preserving planned launch parameters |
| Power interaction | The lower-left control exposes a segmented slider plus `−` and `+` buttons. Click changes 2%, hold repeats after 300 ms, wheel changes 1%. `Space` and the Fire button launch only a valid locked target | Precision is more important than a timing-based charge meter in a planning puzzle |
| Preview boundary | Draw a continuous dotted arc from muzzle to the actual first collision and keep a high-contrast impact ring visible. Never preview post-impact bounces, mechanisms, or final coverage | Reconciles “show it to the end” with the source brief’s anti-solution boundary |
| UI direction | Match the reference hierarchy: top stage/target/shots, small mode chip, bottom-left aim/power, bottom-center coverage, bottom-right restart/fire. Use `#F7F3ED` surfaces, `#10233D` text, `#1678F2` accent, 12–16 px radii, restrained shadow, and no center modal during aiming | Reference image and source brief |
| Typography and locale | Bundle `PretendardVariable.woff2` and its OFL license, define one global Theme, default to `ko`, support `en`, use `tr()` keys, and store translation keys rather than display strings in StageData | Korean is required and the current language selector is only a stub |
| Korean gameplay terminology | `스테이지`, `목표 면적`, `칠한 면적`, `남은 탄`, `조준`, `각도`, `파워`, `다시 시작`, `발사`, `폭발`, `분열`, `범퍼` | Chosen for short, direct desktop-game labels and verified text fit in the generated target mock |
| External art set | After explicit approval, import selected low-poly props from Kenney Nature Kit, six matching icons from Kenney Game Icons, four white particle masks from Kenney Particle Pack, and Pretendard. Do not import Kenney UI Pack, Blaster Kit, Quaternius Fantasy Props, or the full Quaternius nature pack | One coherent small set avoids pack-driven art drift and keeps licenses simple |
| Provenance | Add each imported source URL, version/date, license text, selected filenames, and local usage to `docs/asset-licenses.md`; keep license files beside assets or under `assets/licenses/` | Prevents “free download” from being confused with redistribution permission |
| Paint authority | Keep `PaintSystem` as the only paint mask owner. Thick appearance comes from wider payload-scaled stamps, mask-derived edge normals/roughness, and transient pooled droplets—not a second persistent coverage mesh | Preserves the strongest existing architecture invariant |

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
- Import only the approved asset subset with provenance, then retune and revalidate all stages.

## Scope

In scope:

- Three deterministic generated stages that retain the original First Descent, Burst Basin, and Split Ridge teaching roles.
- One seeded generator and one placement generator with fixed difficulty profiles and checked-in fallback seeds.
- All current gameplay screens, settings, stage data, replay metadata, tests, and screenshots affected by generation/localization/UI.
- The exact selected font, nature props, icons, and particle masks after approval.

Out of scope:

- Endless mode, player-facing seed entry, daily/random challenges, online seed sharing, procedural caves/overhangs, new mechanisms, new projectile types, controller support, mobile layouts, monetization, backend, or full fluid simulation.
- Importing the generated report mockups as runtime textures or claiming them as running-game screenshots.

Destructive or irreversible actions:

- None. Retired fixed formulas and authored placement fields are removed only after generated stages and replay migration pass their guards; Git preserves history.

Exact actions requiring owner/user approval:

- Download and commit `PretendardVariable.woff2`, Kenney Nature Kit selections, Kenney Game Icons selections, and Kenney Particle Pack selections with their license files.
- Any production dependency, plugin, asset pack, or license source beyond those four selected sources.

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
| Target solver | New `src/cannon/impact_target_solver.gd` | Pure low-arc ballistic solve with explicit invalid result | Reuse `CannonBallistics` gravity/speed conversion |
| Cannon commands | `src/cannon/cannon_controller.gd` | Set aim, query launch, and fire request only; no device input | Preserve AI/replay compatibility |
| HUD and app screens | `src/ui/*` plus new `resources/ui/paint_mountain_theme.tres` | Display translated state and emit intents; no game rules | Replace duplicated per-control styles with shared theme/components |
| Localization | New `translations/ui.csv`, updated StageData keys, and `TranslationServer` wiring in app/settings | `ko` default, `en` option, persisted locale migration | Retire visible hardcoded English strings |
| Asset provenance | New `docs/asset-licenses.md` | Exact file/source/license/usage ledger | No existing owner |

## As-Is / To-Be Delta Map

| Concern | As-is | To-be | Acceptance check | Guard / leftover check |
| --- | --- | --- | --- | --- |
| Terrain | Three fixed smooth analytic mounds | Seeded path-first faceted stage layouts with profile metrics | Fixed seeds reproduce byte-identical height-grid checksums; all three metric bands pass | No stage-specific height function or unseeded RNG remains |
| Difficulty | Target/shots change; topology is weakly differentiated | Route count, width, reversals, shelf size, and mechanism complexity rise by stage | Metrics table matches each profile over selected seeds | Stage 1 stays forgiving; Stage 3 retains a safe low route |
| Items | Fixed coordinates and small primitive visuals | Feature-aware placement and chunky scene-owned silhouettes | Every item passes slope, spacing, LoS, projected-size, and route-value tests | No raw production X/Z placement or fourth mechanism |
| Aim | Hidden mouse drag plus keyboard axes | Mouse-selected first-impact target, low-arc solver, invalid-state feedback | Target drag, power changes, and actual first hit stay within existing tolerance | AI/replay calls remain UI-independent |
| Power | Wheel/Q/E with numeric text only | Segmented bar, `−/+`, wheel fine-tune, visible valid/invalid state | Step, hold-repeat, focus, and Space fire checks pass | No timing charge meter or accidental double fire |
| Preview | Small dots and marker can disappear into terrain | Continuous high-contrast arc and minimum-size impact ring to first hit | Marker visible on light/dark rock and preview matches first hit | No post-impact or coverage preview |
| UI | Fixed pixel composition and per-node styles | Reference-aligned regions, shared theme, icons, consistent spacing | 1280×720, 1600×900, and 1920×1080 screenshots show no clipping and match hierarchy | Mountain remains unobstructed; no dense simulator controls |
| Language/font | English literals, `en` stub, Godot default font | Korean default, English option, Pretendard, translation keys | Fresh save opens in Korean; locale switch persists; no missing glyphs | No user-facing raw key or English-only screen remains |
| Assets | Procedural placeholders without provenance | Small approved CC0/OFL subset plus license ledger | Every imported file is present in the ledger and release export | No unapproved pack, remote runtime asset, or mixed UI skin |

## Tasks

### Phase 1: Correct the product contract and establish regression fixtures

Goal: make the new requirements and visible baseline authoritative before gameplay code changes.

Source owners touched: `docs/design-spec.md`, `docs/technical-architecture.md`, `docs/test-checklist.md`, `.agents/Documentation.md`, `docs/remediation-report.html`

- [ ] **1.1 Update the active specifications and implemented-state record**
  - As-is: the active docs report the fixed vertical slice as complete.
  - To-be: record deterministic generation, placement ownership, direct target aiming, Korean default, selected assets, and reference-parity checks; move earlier completion language into historical context.
  - Accept: specs agree with this plan and the source brief; `Documentation.md` separates implemented behavior from remediation work.
  - Guard: do not weaken `StageController`, `PaintSystem`, replay, fixed-timestep, or scope exclusions.
- [ ] **1.2 Add visual and generation acceptance fixtures**
  - As-is: tests assert clipping and feature presence but not target composition or generation quality.
  - To-be: preserve the reference/current report images, define the Korean terminology list, selected seeds, profile metrics, and screenshot comparison checklist.
  - Accept: a future executor can identify pass/fail without inventing layout or terrain criteria.
  - Guard: generated mockups remain labeled as concepts, never running evidence.

Batch acceptance: document validation and `git diff --check` pass; no material decision remains outside this plan.

Batch guard: the game still launches unchanged after documentation-only edits.

### Phase 2: Deliver one generated playable stage end to end

Goal: replace the fixed terrain path with a deterministic generator and run First Descent through the existing paint/state loop.

Source owners touched: `src/stage_generation/*`, `src/terrain/terrain_mesh_factory.gd`, `src/stage/stage_data.gd`, `src/gameplay/gameplay_scene.gd`, `src/paint/paint_system.gd`, `resources/stage_generation/first_descent_profile.tres`, `resources/stages/first_descent.tres`, `tests/stage_generation_test.gd`

- [ ] **2.1 Add typed generation profile and layout contracts**
  - As-is: `terrain_variant` selects a hardcoded function.
  - To-be: StageData references a profile and seed; one read-only layout carries the height grid, routes, metrics, bounds, and placements.
  - Accept: Resources load with typed validation; replay metadata includes the accepted seed/profile version.
  - Guard: mutable runtime state does not enter StageData.
- [ ] **2.2 Implement path-first terrain generation with bounded validation**
  - As-is: fixed Gaussian hills build directly into vertices.
  - To-be: generate route spines, shelves, ridge/valley fields, low-amplitude noise, slope repair, and metrics under a 32-attempt cap.
  - Accept: First Descent passes its route/reversal/width/slope metrics and stable checksum test.
  - Guard: no caves, overhangs, unseeded random calls, or second terrain representation.
- [ ] **2.3 Feed the accepted grid into mesh, collision, paint flow, and restart**
  - As-is: these systems call the static height function.
  - To-be: one layout supplies height queries everywhere and is recreated identically on restart.
  - Accept: paint/coverage tests, one reliable First Descent solution, replay, and sub-second restart pass on the generated terrain.
  - Guard: `PaintSystem` remains the only paint authority and mesh stays under 50k triangles.

Batch acceptance: First Descent is fully playable from menu to result on its generated layout with a reproducible screenshot and solution.

Batch guard: all existing Phase 2–4 projectile, paint, and state tests pass before expanding generation.

### Phase 3: Scale difficulty and place readable 3D mechanisms

Goal: generate Burst Basin and Split Ridge with verified route complexity and feature-aware mechanisms.

Source owners touched: `src/stage_generation/mechanism_placement_generator.gd`, `resources/stage_generation/*.tres`, `resources/stages/*.tres`, `scenes/mechanisms/*.tscn`, `src/mechanisms/*.gd`, `src/terrain/environment_dressing.gd`, `tests/mechanism_placement_test.gd`

- [ ] **3.1 Implement placement candidate extraction and validators**
  - As-is: fixed X/Z coordinates are trusted.
  - To-be: score shelves, ridges, channel entries, downstream drop, approach direction, LoS, screen size, spacing, and bounds; orient Bumper toward its selected downstream target.
  - Accept: fixed-seed tests show Burst on a valuable upper ledge, Splitter with three downhill sectors, and Bumper with a valid approach/redirection path.
  - Guard: no placement policy enters StageController or mechanism behavior scripts.
- [ ] **3.2 Build distinct scene-owned mechanism visuals**
  - As-is: small primitives are created from script.
  - To-be: radial Burst, triangular Splitter, and directional Bumper scenes expose active/spent/cooldown visuals and selection bounds.
  - Accept: every mechanism meets world- and screen-size thresholds in briefing and aiming captures; activation is readable without persistent text during flight.
  - Guard: world scale stays believable and behavior/reset tests remain unchanged.
- [ ] **3.3 Add approved sparse nature dressing without hiding routes**
  - As-is: a few procedural trees use fixed coordinates.
  - To-be: seeded decoration placement uses the approved low-poly subset outside route clearance and eligible paint surfaces.
  - Accept: trees/rocks establish scale, never overlap mechanisms, and never reduce route visibility below the screenshot checklist.
  - Guard: asset download/import starts only after the exact approval gate and every file enters the license ledger.

Batch acceptance: all three generated stages satisfy their difficulty bands, display the correct mechanism loadout, and retain one reliable manual solution.

Batch guard: one split generation, eight active balls, authoritative paint, and reset behavior remain unchanged.

### Phase 4: Replace aiming and power interaction

Goal: let the player choose an intended first impact directly and see the entire valid initial trajectory before firing.

Source owners touched: `src/input/aim_input_controller.gd`, `src/cannon/impact_target_solver.gd`, `src/cannon/cannon_controller.gd`, `src/cannon/trajectory_preview.gd`, `src/ui/hud_controller.gd`, `scenes/gameplay/gameplay.tscn`, `tests/aim_interaction_test.gd`

- [ ] **4.1 Separate device input from cannon commands**
  - As-is: CannonController polls keyboard and handles mouse/Space.
  - To-be: AimInputController owns devices and calls the same validated cannon/stage actions used by replay and the agent API.
  - Accept: human, replay, debug, and agent actions produce equivalent aim/fire commands.
  - Guard: no input code decides shots, state, or outcomes.
- [ ] **4.2 Add direct impact targeting and explicit invalid state**
  - As-is: drag sensitivity changes angles without a terrain target.
  - To-be: hover previews a terrain target; click/drag locks it; the low-arc solver returns yaw/elevation or an invalid result for the current power.
  - Accept: valid points solve and actual first hit stays within the existing preview tolerance; invalid points show red and cannot fire.
  - Guard: the solver uses the same gravity/speed source as launch and never steers after fire.
- [ ] **4.3 Add precise power controls and legible preview**
  - As-is: wheel/Q/E and small dots.
  - To-be: segmented slider, `−/+`, hold repeat, wheel fine tune, Space/button fire, continuous dots, and a minimum-size impact ring.
  - Accept: keyboard, mouse, focus, repeat, disabled, and double-fire tests pass; the arc remains visible to first collision at all three resolutions.
  - Guard: no post-impact route, mechanism activation, or coverage prediction appears.

Batch acceptance: a first-time player can target terrain, adjust power, understand invalid aim, and fire without reading documentation.

Batch guard: deterministic repeated shots and replay deltas stay within the current recorded tolerances.

### Phase 5: Ship Korean-first theme and reference-aligned layout

Goal: replace the English placeholder presentation with one coherent localized interface across the complete app flow.

Source owners touched: `translations/ui.csv`, `resources/ui/paint_mountain_theme.tres`, `assets/fonts/pretendard/*`, `assets/ui/icons/*`, `src/ui/*`, `src/app/app_root.gd`, `src/autoload/save_system.gd`, `project.godot`, `docs/asset-licenses.md`, `tests/localization_ui_test.gd`

- [ ] **5.1 Import the approved font/icons/particles and record provenance**
  - As-is: no external runtime assets or font license ledger.
  - To-be: commit only selected source files and licenses, wire Pretendard as the Theme default, and map approved icons/particles to semantic uses.
  - Accept: each imported file has source, license, version/date, and usage; release works offline.
  - Guard: no CDN, remote runtime asset, full unused pack, or unapproved license enters the repo.
- [ ] **5.2 Implement real `ko`/`en` localization and save migration**
  - As-is: visible English literals and an `en`-only selector.
  - To-be: translation keys cover menus, HUD, mechanisms, results, errors, tutorials, and settings; fresh saves default to Korean; existing saves migrate safely.
  - Accept: locale switches immediately, persists across a fresh process, and every screen shows complete glyphs.
  - Guard: stage rules and identifiers remain locale-independent.
- [ ] **5.3 Recompose HUD and app screens from shared primitives**
  - As-is: duplicated fixed style overrides and weak hierarchy.
  - To-be: one Theme and responsibility-shaped components implement the reference regions, spacing, controls, focus, and localized text fit.
  - Accept: aiming matches the report hierarchy; briefing, observation, result, stage select, menu, pause, and settings are visually coherent at 1280×720, 1600×900, and 1920×1080.
  - Guard: no text clipping, offscreen controls, unsupported action, center modal over aiming, or persistent mountain tooltip.

Batch acceptance: a fresh install opens in Korean and the full menu-to-result loop is usable with keyboard and mouse in both locales.

Batch guard: controls stay at least 40 px high, focus is visible, state is not color-only, and the mountain remains the dominant visual.

### Phase 6: Tune, export, and prove the remediated game

Goal: validate gameplay quality, visual target, determinism, performance, persistence, and release delivery together.

Source owners touched: `resources/stages/*.tres`, `docs/test-checklist.md`, `.agents/Documentation.md`, `README.md`, `screenshots/*.png`, `export_presets.cfg`

- [ ] **6.1 Tune selected seeds, targets, shots, and solutions**
  - As-is: solutions target fixed formula terrain.
  - To-be: each generated seed has one recorded reliable route, intended teaching outcome, and coverage/shot target that preserves Stage 1 forgiving, Stage 2 Burst, and Stage 3 multi-route roles.
  - Accept: all three physical solution tests clear and a safe inefficient Stage 3 route remains below target by design.
  - Guard: do not compensate for bad terrain by inflating mechanism paint or weakening core physics.
- [ ] **6.2 Run visual comparison and accessibility checks**
  - As-is: existing checks prove clipping only.
  - To-be: compare fresh running screenshots against the provided reference and generated target for composition, mechanism visibility, terrain depth, paint thickness, hierarchy, font, and Korean fit.
  - Accept: UIUX Level 4 evidence reports no blocker; every important state has a valid capture.
  - Guard: generated concepts are never substituted for runtime evidence.
- [ ] **6.3 Complete production regression and delivery**
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
| No valid generated terrain within 32 attempts | Load the checked-in fallback seed for that profile, emit one debug warning, and preserve the failed metrics in test output | Never ship an invalid layout or raise the attempt cap without measured approval |
| Terrain passes metrics but a required mechanism has no valid placement | Reject the layout and continue the same bounded generation sequence | Fallback seed must include validated placements; do not hand-place a production mechanism |
| A selected target has no real low-arc solution | Show red target/arc state, disable Fire, preserve last valid aim, and let power change immediately re-evaluate | Never clamp into a false valid trajectory |
| Imported asset exceeds style or geometry budget | Exclude that file and use the already-selected custom/procedural replacement; keep the source decision in the license ledger | Do not add a new pack without approval |
| External asset approval is not granted | Continue Phases 1–4 with built-in geometry; pause only the exact import work and final Korean font acceptance | Do not claim Phase 5 or final completion without an approved embedded Korean font |
| Korean text clips | Increase container width or wrap/remove secondary copy; preserve 16 px minimum body size and 40 px control height | Do not shrink text or use negative spacing to hide the issue |
| Paint-thickness treatment causes visual/scoring drift | Remove the derived treatment and return to direct authoritative-mask shading while keeping wider stamps | Never create a second persistent paint/coverage state |
| Generation or assets push load beyond three seconds or break 60 FPS average | Profile generation/mesh/import cost, keep the accepted grid, reduce dressing/material cost, and preserve mechanism readability | Escalate before changing renderer, mesh budget, or adding dependencies |
| Replay diverges after generated-layout migration | Verify seed/profile version serialization and grid checksum before considering transform capture | Preserve deterministic input replay as primary metadata |

## Progress

- [x] Discovery: source brief, specs, architecture, current code, running release captures, reference image, and asset licenses inspected.
- [x] Decision contract: generation, placement, controls, localization, visual direction, and selected asset set locked.
- [x] Planning evidence: `docs/remediation-report.html` and its local images prepared for review.
- [ ] Phase 1: product contract and regression fixtures.
- [ ] Phase 2: one generated playable stage.
- [ ] Phase 3: difficulty scaling and mechanism placement/visuals.
- [ ] Phase 4: aiming and power interaction.
- [ ] Phase 5: Korean-first theme, layout, and approved assets.
- [ ] Phase 6: tuning, production QA, and delivery.

## Next Steps

1. Start with Phase 1 and keep the game behavior unchanged while correcting active specs and baseline checks.
2. Deliver Phase 2 as the first user-testable implementation checkpoint before touching all screens.
3. Continue through Phases 3–5 in order, requesting the single exact asset approval before Phase 3 dressing/Phase 5 imports.
4. Finish with Phase 6 only after every earlier batch gate passes.

## Completion Criteria

- [ ] Three fixed seeds reproduce three valid generated layouts with the specified route/reversal/width bands and one reliable solution each.
- [ ] Burst, Splitter, and Bumper are visible, distinct, correctly placed, and behaviorally unchanged.
- [ ] Mouse target selection, explicit power controls, Space/Button fire, invalid state, and first-collision preview pass input and physics checks.
- [ ] A fresh install defaults to complete Korean UI, English remains selectable, both persist, and Pretendard renders without missing glyphs or clipping.
- [ ] Running release screenshots match the reference hierarchy and show a stepped large mountain, thick readable paint, small cannon, and visible mechanisms.
- [ ] Every imported asset is approved, locally stored, offline-safe, and recorded with its license/source.
- [ ] Every existing gameplay, paint, mechanism, save, replay, reliability, performance, and production-delivery guard passes.
- [ ] No retired fixed terrain formula, authored production placement, English-only visible string, duplicate paint authority, placeholder plan text, or unreported limitation remains.

## Stop Conditions

Complete when: every completion criterion and final gate passes against the exported Windows build and the new seven running-game screenshots.

Escalate only when: the exact external asset approval is denied, a required license changes, the selected target interaction proves mathematically incompatible with the current launch model, or meeting the measured performance contract requires an engine/renderer/dependency change.

Do not stop when: a generated seed fails within the bounded retry path, a selected asset can be omitted in favor of the predetermined custom replacement, Korean copy needs layout adjustment, or a safe task-scoped fix remains.

## Handoff

```text
Goal: Remediate Paint Mountain's generated stages, item readability, aiming, Korean UI, and reference-level presentation.

Read first: AGENTS.md, docs/source-brief.md, .agents/Documentation.md, .agents/Plan.md, docs/remediation-report.html.

Execute exactly: Phases 1–6 in order; preserve StageController, PaintSystem, replay, physics, and scope guards.

Validate with: scripts/verify.ps1, the existing Phase 2–8 tests, the four new focused tests, production export/start, three resolutions, two locales, and seven fresh release screenshots.

Stop when: every completion criterion passes or an exact approval/escalation boundary above is reached.
```
