---
type: evidence
status: active
created: 2026-08-10
last_reviewed: 2026-08-21
topic: essential-ui-fidelity
scope: seven approved UI refinements plus supporting gameplay and responsive states
source: docs/reports/screen-audit-2026-08-10/assets/refined/
related:
  - .agents/execplans/2026-08-10-essential-ui-fidelity.md
  - .agents/evidence/essential-ui-fidelity-2026-08-10/README.md
  - .agents/design/UIUX_GUIDELINES.md
---

# Essential UI Fidelity Design QA

## 2026-08-21 Result Ribbon Addendum

- Source: `.agents/evidence/2026-08-21-clear-page-redesign-concept/selected/result-low-precision-ribbon-1280x720.png`.
- Exported evidence: `.agents/evidence/2026-08-21-result-low-precision-ribbon/production/`.
- Direct comparison: `clear-comparison.png` pairs the normalized selected concept and the exported `1280x720` Clear state in one image.
- Clear and Failure were also inspected at `640x360` from the same Windows release export.
- Result: passed. The mountain remains primary; the score ribbon stays inside the result safe region; the five authored grade zones read `1–2–3–2–1`; below-range scores clamp to the ribbon and use an inset red overflow marker; contribution values use their signed score effect; duplicate current-score and target copy is absent; Clear actions end in Next and Failure actions end in Same Deal Retry. No text, action, ribbon, or endpoint label clips in either checked viewport.
- Accepted P3 difference: the implementation keeps the project renderer, compact native action controls, and existing camera composition rather than reproducing the concept's illustrative terrain and larger typography literally.

## Purpose

Verify that the exported Windows build applies the seven approved Essential UI
refinements while preserving the Quiet Context style, real gameplay state,
localization, keyboard operation, and mountain-first composition.

## Sources

- Source visual truth: the seven `1672x941` refined images under
  `docs/reports/screen-audit-2026-08-10/assets/refined/`.
- Primary implementation evidence: Korean `1280x720` Windows release captures
  under `.agents/evidence/essential-ui-fidelity-2026-08-10/runtime/`.
- Full-view combined comparisons: seven labeled `2560x764` images under
  `.agents/evidence/essential-ui-fidelity-2026-08-10/comparisons/`.
- Responsive implementation evidence: English `1920x1080` Main Menu, Stage
  Select, Aim, Settings, and Manual Result captures, plus Korean `1600x900`
  Stage Select and Settings captures in the runtime evidence directory.
- Supporting-state evidence: Korean `1280x720` Map Inspection, Shot Follow
  impact hold, and Pause captures in the runtime evidence directory.

## Comparison Setup

- State: the screen, locale, selected stage, and terminal reason match each
  named reference. Aim fidelity uses Stage 30 on both sides so its complete
  glyph set and camera state are directly comparable.
- Viewport: the primary exported runtime is exactly `1280x720` physical pixels.
  CSS size and browser density do not apply to this native Godot build.
- Normalization: each `1672x941` reference was resized proportionally into a
  `1280x720` frame and centered with at most one padding pixel. It was not
  stretched. The runtime half remains its native `1280x720` pixels.
- Renderer: Godot 4.7.1 Compatibility renderer, Windows release export.
- Full-view evidence: each final comparison sheet was opened and inspected
  directly after normalization.
- Focused evidence: the native `1280x720` and `1920x1080` runtime captures were
  also opened separately to read small labels, controls, legends, result facts,
  and switch states. Extra crops were unnecessary because those captures were
  readable at native size.

## Findings

- No actionable P0, P1, or P2 issue remains.
- Fonts and typography: Pretendard remains the shared family. Screen identity,
  stage facts, coverage, results, and actions retain the approved hierarchy.
  Korean and English labels do not clip or wrap awkwardly in the checked
  viewports. English Main Menu uses an intentional two-line brand lockup within
  the fixed logical action column.
- Spacing and layout rhythm: Main Menu keeps a restrained left action lane and
  a real Stage 01 preview on the right. Stage Select uses a two-column list,
  fact-only detail, and selected-only outline. Briefing and Results reserve
  screen-specific safe regions for the full mountain. Settings keeps two equal
  columns without a divider. No persistent action or fact overlaps or clips.
- Colors and tokens: navy, warm paper, cool gray, blue, coral timeout, focus,
  selection, disabled, and progress colors remain Theme-owned and consistent.
  Filled blue is reserved for the primary action in each state.
- Image quality and asset fidelity: all mountains, paint, cannon, trajectory,
  target and mechanism glyphs, wheel, gear, and paint-splash visuals are real
  project assets or renderer output. Timeout uses the generated raster clock
  asset at its intended native-size role; it has no chroma halo, emoji, text
  glyph, or code-drawn substitute.
- Copy and content: Main Menu meta copy, Stage Select prose, Briefing objective
  and floating mechanism names, Settings helper rows, and Result explanation
  labels are absent. Fire, Finish, and Aim/Map controls show semantic actions
  only; Space, F, and Tab appear once in the lower context legend. Tooltips and
  retained objective/mechanism localization inventory remain available to
  accessibility and future learning surfaces.
- Icons and boundaries: focus, selected stage, modal/result containment,
  controls, switches, rails, and the target tick retain semantic boundaries.
  Decorative legend, column, result, and aim-group dividers and shortcut
  keycap boxes are absent.
- States and interactions: Main Menu and stage navigation, Briefing Back/Start,
  Aim/Map, Fire, Follow return, Pause, Settings, manual Finish, timeout Result,
  Retry, Next, and Stage Select remain represented by real enabled, disabled,
  selected, or terminal states. Timeout is distinguished by both the clock and
  localized title.
- Responsiveness: the Korean `1280x720`, Korean `1600x900`, and English
  `1920x1080` captures show no persistent control overflow, viewport escape,
  collision, or unreadable scaling. Logical control widths remain stable while
  the renderer scales the native viewport.
- Accessibility: interactive elements remain native focusable Godot controls;
  the shared focus treatment and non-color state labels remain. Tooltips and
  shortcuts continue to be checked by focused runtime contracts.

## Accepted P3 Differences

- Procedural mountain topology, real tree placement, lighting, glyph placement,
  paint traces, and coverage values differ from the illustrative generated
  pixels. The references mark these as directional, and the shipped hierarchy,
  safe regions, and world prominence remain intact.
- Native switch tracks are optically smaller than the concept switches. Their
  on/off state, hover/pressed behavior, focus, label, and minimum row target are
  still explicit, while the requested outer row boxes remain removed.
- Stage rows use slightly denser real localized facts than the concept. All
  thirty stages and pagination remain reachable without clipping.

## Open Questions

- None.

## Implementation Checklist

- [x] Remove normal-screen meta and explanatory copy while retaining future
  guide/tutorial/accessibility content inventory.
- [x] Remove decorative separators, repeated row boxes, and keycap outlines.
- [x] Make the bottom context legend the single visible shortcut owner.
- [x] Fit Main Menu, Briefing, and Result terrain into deterministic UI-safe
  presentation rectangles.
- [x] Integrate a real timeout clock asset and compact fact/action Result panel.
- [x] Verify Korean/English copy, focus, disabled/selected states, and responsive
  layouts from the exported Windows executable.

## Follow-up Polish

- No follow-up is required for acceptance. A future visual-art pass may refine
  procedural mountain material contrast independently of this UI contract.

## Comparison History

1. Initial final Aim comparison paired the Stage 30 reference with
   `runtime/ko-1280x720-aiming.png`, which is Stage 02.
   - P2 evidence mismatch: different mechanism inventory and terrain state made
     direct fidelity judgment invalid.
   - Fix: captured Stage 30 from the same exported executable and rebuilt the
     comparison with proportional, non-stretched normalization.
2. Post-fix evidence:
   `comparisons/04-aim-view-comparison.png`, using
   `runtime/ko-1280x720-aiming-stage30.png`.
   - Result: the state matches and no actionable P0/P1/P2 difference remains.
3. The other six first-pass final comparison sheets matched their named state
   and required no P0/P1/P2 rework.

## Verification

- `scripts/verify.ps1`: passed after the final scene, script, resource,
  localization, and test changes.
- Focused copy, shortcut, localization, UI composition, HUD truth, camera safe
  rectangle, and complete camera safety contracts: passed.
- `Windows Desktop` release export to
  `builds/windows/PaintMountain.exe`: passed.
- Exported capture processes: 18 of 18 exited with code 0. Seventeen satisfy the
  required matrix; the additional Stage 30 Aim capture normalizes QA state.
- Primary interactions exercised by tests and captures: Main Menu and stage
  navigation, Briefing Back/Start, Aim/Map, angle/power input, Fire, Follow
  return, Pause, Settings, manual Finish, timeout Result, Retry, Next, and
  Stages.
- Runtime and verification output were checked for script failures and recurring
  errors; none remain.

## Limitations

- Hover animation and reduced-motion transitions were not recorded as video;
  their static states and behavior remain covered by Theme and focused tests.
- The generated references define composition and UI fidelity, not exact
  procedural world pixels.

final result: passed
