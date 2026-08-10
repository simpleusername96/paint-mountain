---
type: plan
status: done
created: 2026-08-10
last_reviewed: 2026-08-10
objective: correct the shipped Paint Mountain UI so the seven approved refined images are visibly recognizable in the exported runtime
scope: shared UI scale and type, Main Menu preview, Stage Select, Briefing composition, Settings controls and icon assets, Results, terrain value hierarchy, tests, export, and same-state visual evidence
source: ../../docs/reports/screen-audit-2026-08-10/index.html
related:
  - 2026-08-10-essential-ui-fidelity.md
  - ../design/DESIGN.md
  - ../design/ART_DIRECTION.md
  - ../design/UIUX_GUIDELINES.md
  - ../design/VISUAL_REFERENCES.md
  - ../../docs/test-checklist.md
---

# Approved Image Fidelity Correction

## Purpose

Correct the implementation accepted by the completed Essential UI plan after
the user found that its exported screens still did not resemble the approved
images closely enough. The prior pass matched copy inventory and rough
structure, but its QA incorrectly treated material, scale, typography, icon,
control, and world-occupancy differences as non-blocking. This pass makes those
visible differences blocking and retains the already-correct removal of filler
copy, decorative hairlines, duplicated shortcut labels, and Briefing prose.

## Verified Evidence

Discovery compared the seven approved refined images directly with the seven
existing exported-runtime comparison sheets at the same 16:9 state.

| Screen | Blocking exported-runtime difference | Approved direction |
| --- | --- | --- |
| Main Menu | gray ground seam crosses the action lane; mountain facets are washed out; title/action rhythm is under-scaled | open warm field, strong title, clear left action lane, substantial faceted mountain on the right |
| Stage Select | all card and detail type is visibly too small; the background inherits the preview-world seam; detail/action hierarchy is weak | warm clean field, large cards and facts, assertive selected-stage detail, low Start action |
| Briefing | mountain is too far right and too small; terrain is much bluer than the approved neutral mountain | dominant centered-right terrain, preserved left identity/actions, neutral readable facets |
| Aim View | structure and shortcut ownership are close, but the runtime mountain is blue while the approved target is warm-neutral and brighter | preserve current HUD geometry while correcting world value hierarchy |
| Settings | missing seven visible icons and three numeric volume values; switch tracks are tiny; columns are sparse and type is weak | icon-led rows, visible percentages, 52 by 28 switches, full two-column rhythm |
| Manual Result | fact hierarchy and actions are too small and panel contents sit too high/sparse | stronger title/value/facts and reference-like vertical rhythm |
| Timeout Result | same hierarchy issue as Manual Result; existing clock asset remains valid | preserve clock/reason distinction and strengthen the shared result hierarchy |

The approved source images are 1672 by 941. Their geometry is compared after a
uniform fit to 1280 by 720; exact generated terrain topology and text raster
pixels remain directional, while relative occupancy, scale, icon presence,
visible copy, action hierarchy, and value separation are literal targets.

## Locked Decisions

- Keep the current Quiet Context colors, Pretendard family, tactile primary
  button, semantic focus outline, selected-stage outline, and minimal boundary
  policy. Do not introduce another visual system.
- Treat every material mismatch in this plan as P2 until a same-state combined
  comparison proves it acceptable. The old evidence statement that no P2 issue
  remained is historical and not evidence for this correction.
- Main Menu alone owns the real Stage 01 preview. Stage Select uses a warm solid
  field and does not render the preview world behind its cards.
- Remove the Main Menu preview ground plane. The closed mountain and dressing
  provide the subject; the environment background provides the open field.
- Enlarge the Main Menu preview safe region from the right-only strip to a
  0.30-0.98 horizontal field while preserving a hard non-overlap boundary after
  the 360 px action lane.
- Preserve Aim HUD placement and behavior. Correct shared gameplay terrain
  `rock_color` and `shadow_tint` toward neutral gray-white values and validate
  glyph, trajectory, paint, target-area, and support-shell contrast in all
  gameplay-state captures.
- Shift and enlarge Briefing with one shared safe rectangle, not stage-specific
  camera constants. Result framing remains separate and must continue to reserve
  the right result panel.
- Settings adds seven original project assets: master volume, music, sound
  effects, display, camera shake, reduced motion, and trajectory. Use real raster
  assets derived with ImageGen from the approved Settings reference; do not use
  emoji, font glyphs, handcrafted SVG, or code-drawn stand-ins. Each asset is
  displayed at 24 px and retains an accessible text label.
- Settings shows authoritative rounded volume percentages beside the three
  audio labels and updates them during dragging and state synchronization.
- Settings switches use explicit checked and unchecked raster assets sized for
  a 52 by 28 px control. They do not use the tiny engine-default CheckButton
  mark.
- Shared type roles may grow only where the approved screens require it:
  MenuTitle, StageCardButton, Settings rows, result title/value/facts. The 14 px
  lower context legend remains unchanged because the Aim reference already
  matches its compact hierarchy.
- Result panels keep the current 356 px ownership boundary and authoritative
  facts, but use larger semantic type roles and reference-like gaps. Do not add
  explanatory copy or a second coverage formula.
- No gameplay rule, input mapping, stage data, paint/coverage formula, save
  schema, dependency, plugin, asset pack, or guide/tutorial page changes are in
  scope.

## Scope and Non-Goals

### In scope

- `paint_mountain_theme.tres` semantic typography, control, and switch assets.
- Main Menu and Stage Select screen composition and preview-world ownership.
- Shared gameplay terrain value hierarchy and Briefing safe framing.
- Settings icon/value/control composition and live value presentation.
- Result type hierarchy and vertical rhythm.
- Focused tests, full verification, Windows release export, background captures,
  combined comparison sheets, and a new Product Design QA record.

### Not in scope

- changing terrain topology to copy generated mountain pixels;
- redesigning Map View, Shot Follow, Pause, or the already-close Aim HUD;
- adding guidebook/tutorial/UI-guide content;
- adding new actions, settings, or gameplay state;
- replacing the existing font, renderer, or third-party asset set.

## Architecture Ownership

- `resources/ui/paint_mountain_theme.tres` remains the shared visual token and
  semantic control owner.
- screen `.tscn` files own layout; their screen scripts own localization and
  live value presentation only.
- `AppRoot` owns the noninteractive Main Menu preview and whether it is visible.
- `GameplayScene` owns publication of the shared terrain material parameters;
  `PaintSystem` remains the only coverage and mask owner.
- `CameraDirector` owns shared Briefing and Result presentation rectangles.
- `ResultPanel` displays the result snapshot; it does not calculate it.

## Tasks

- [x] **AIF-01 — Add and register the approved Settings asset family.**
  - Generate seven navy line icons and checked/unchecked switch textures using
    the approved Settings image as the style reference.
  - Remove the flat chroma background, validate transparent corners and clean
    edges, place final PNGs under `assets/ui/icons/settings/`, and record their
    project-generated provenance.
  - Stop if the assets remain unclear at 24 px after one focused regeneration.

- [x] **AIF-02 — Correct the shared semantic scale without inflating the HUD.**
  - Add or tune Theme roles for Main Menu title, stage cards/details, Settings
    labels/values/switches, and Result title/coverage/facts.
  - Keep the existing compact Aim legend and control geometry unless a new
    combined comparison exposes a local mismatch.
  - Add explicit checked/unchecked switch icons and state colors to the shared
    Settings CheckButton variation.

- [x] **AIF-03 — Match Main Menu and Stage Select composition.**
  - Remove the Main Menu preview ground plane and dark full-screen wash; tune
    the preview environment/material and safe region so the mountain reads as a
    strong faceted subject without crossing the action lane.
  - Hide the preview world on Stage Select and give that screen its own warm
    field.
  - Increase stage-card/detail type and spacing, preserve eight reachable cards,
    selected-only outline, paging, preparation failure, and keyboard focus, and
    place Start at the approved low position.

- [x] **AIF-04 — Correct gameplay terrain values and Briefing occupancy.**
  - Tune the shared gameplay terrain rock/shadow values from blue-gray toward
    neutral off-white while retaining target-area, support-shell, paint,
    trajectory, and glyph contrast.
  - Widen and shift the shared Briefing presentation rectangle left so the
    complete mountain fills the approved visual mass without colliding with
    stage identity, Gear, actions, or the lower context legend.
  - Keep Aim composition geometry unchanged and validate its material result.

- [x] **AIF-05 — Recompose Settings with real controls and live values.**
  - Build icon-led audio rows with label, current percentage, and slider.
  - Build Display and Gameplay rows with the approved icons, text, and full-size
    switch assets; preserve focus, toggling, disabled Resolution behavior,
    localization, persistence, defaults, Close, and pause-child return.
  - Validate Korean and English fit at 1280x720, 1600x900, and 1920x1080.

- [x] **AIF-06 — Strengthen Manual and Timeout Result hierarchy.**
  - Increase title, coverage, target, grade, best, and metadata readability and
    reproduce the approved vertical rhythm inside the existing narrow panel.
  - Preserve manual/timeout reason truth, clock visibility, action availability,
    and authoritative values.

- [x] **AIF-07 — Validate behavior and code quality.**
  - Update focused UI tests for the new Settings row/value/icon structure,
    preview-world ownership, safe rectangles, and semantic Theme roles.
  - Run focused tests while iterating, then `scripts/verify.ps1` once the full
    implementation stabilizes.
  - Run `$codebase-quality-auditor` over the task-owned diff and apply only safe,
    task-scoped corrections.

- [x] **AIF-08 — Export, capture, compare, and repeat until passed.**
  - Export `Windows Desktop` release and use the hidden background delivery
    runner for the seven exact Korean 1280x720 states, plus Settings and Stage
    Select at Korean 1600x900 and English 1920x1080.
  - Build proportional same-state comparison sheets with the approved image on
    the left and exported runtime on the right.
  - Inspect the combined images directly. Any wrong scale, missing asset,
    visible seam, material cast, clipping, overlap, or hierarchy mismatch is P2
    and requires another affected-screen capture.
  - Write `design-qa.md` with per-screen P0-P3 findings. It may end with
    `final result: passed` only when no actionable P0/P1/P2 issue remains.
  - Update durable implementation/test records truthfully, mark this plan done,
    and commit only task-owned files.

## Acceptance Criteria

- A viewer can identify the approved Main Menu, Stage Select, Briefing,
  Settings, Manual Result, and Timeout Result compositions without relying on
  their text labels.
- Main Menu contains no preview ground seam or gray wash and the mountain is a
  readable, faceted right-side mass.
- Stage Select type is legible at the same apparent scale as the target, the
  field is clean, all thirty stages remain reachable, and selection/focus remain
  distinct.
- Briefing terrain occupies the approved central visual mass, and Aim/Briefing/
  Result terrain no longer has the rejected blue cast.
- Settings contains all seven real icons, three live volume percentages, and
  four clearly readable 52 by 28 switches with correct state.
- Result hierarchy matches the target while coverage, target, grade, best,
  elapsed time, shots, and actions remain authoritative.
- Korean and English have no clipping, overlap, awkward wrap, or microscopic
  text at the required captures.
- All focused tests, `scripts/verify.ps1`, release export, and new background
  captures pass.
- The final combined review contains no actionable P0, P1, or P2 finding.

## Verification

Focused commands:

```powershell
& $env:GODOT_BIN --headless --path . --quit-after 7200 --script res://tests/phase7_ui_test.gd
& $env:GODOT_BIN --headless --path . --quit-after 7200 --script res://tests/essential_ui_copy_test.gd
& $env:GODOT_BIN --headless --path . --quit-after 7200 --script res://tests/localization_ui_test.gd
& $env:GODOT_BIN --headless --path . --quit-after 7200 --script res://tests/camera_safety_test.gd
```

Final repository gate:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/verify.ps1
```

Release export:

```powershell
& $env:GODOT_BIN --headless --path . --export-release 'Windows Desktop' 'builds/windows/PaintMountain.exe'
```

## Regression Guards

- Do not restore filler copy, objective prose, mechanism labels, decorative
  hairlines, detached keycaps, duplicate Space/F/Tab labels, or visible yaw.
- Do not change `StageController`, `PaintSystem`, shot physics, fixed physics
  rate, stage timing, progression, or save truth.
- Do not hide controls or invent state solely to resemble a generated image.
- Do not use image references or headless tests as runtime acceptance evidence.
- Do not accept a visual mismatch merely because structure or copy tests pass.

## Risks and Contingencies

- If neutral terrain values collapse target/support depth, adjust only the two
  shared material colors and lighting inputs, then recapture Aim and one Result;
  do not add outlines or a second material system.
- If Briefing framing overlaps UI at a non-baseline aspect, enlarge the shared
  safe reserve or reduce the presentation margin uniformly; do not add a
  per-stage repair.
- If generated icon edges fail at native size, perform one targeted regeneration
  with larger strokes. Do not replace the icon with text or a code drawing.
- Preserve unrelated worktree changes. Stop if a task-owned file contains an
  unreconcilable user edit.

## Stop Conditions

Stop and ask before adding a dependency, plugin, renderer, external asset pack,
new gameplay setting, or stage-specific camera data; before changing supported
aspect requirements; or before accepting a material hierarchy that makes paint,
glyphs, target area, or support faces unreadable.

## Progress

- [x] Reopened all seven prior comparison sheets and reclassified visible
  typography, icon, control, material, and occupancy mismatches as blocking.
- [x] Verified scene, script, Theme, camera, material, test, and asset owners.
- [x] AIF-01 through AIF-08 complete.

## Completion Record

- Added the ImageGen-derived Settings icon/switch family, shared stage-card
  component, semantic Theme roles, live Settings values, neutral terrain
  values, revised screen layouts, and focused regression checks.
- `scripts/verify.ps1`, the Windows release export, all required background
  captures, responsive/localization density checks, and the task-owned quality
  audit passed.
- Seven final combined sheets were inspected directly. The active evidence is
  `docs/evidence/approved-image-fidelity-correction-2026-08-10/`; its
  `design-qa.md` ends with `final result: passed`.
- No gameplay rule, paint/coverage owner, save schema, input mapping,
  dependency, plugin, renderer, stage data, or generated terrain topology was
  changed.
