---
type: evidence
status: archived
created: 2026-08-09
topic: quiet-context-ui-system
scope: all production UI surfaces and selected Stage 30 Aim View fidelity
source: docs/concepts/full-ui-refresh-2026-08-09/revised-02-context-line.png
related:
  - .agents/execplans/2026-08-09-quiet-context-ui-system.md
  - .agents/design/UIUX_GUIDELINES.md
---

# Historical Quiet Context UI Design QA

## Purpose

This report records the pre-wind-retirement production build. Its wind flag,
wind HUD, and related verification statements are historical evidence, not the
current interface contract.

Verify that the production Windows build applies the selected Quiet Context
direction to every reachable UI surface, and that the Stage 30 Aim View remains
faithful to the exact approved visual target without changing gameplay behavior.

## Sources

- Source visual truth:
  `docs/concepts/full-ui-refresh-2026-08-09/revised-02-context-line.png`
  (`1280x720`, SHA-256
  `715DA06D3825E97B0C89975153289ECC0BF11F41A9C93A5129DC8397E2DDC33A`).
- Final implementation screenshot:
  `.agents/evidence/quiet-context-ui-system-2026-08-09/final-ko-1280x720-progression_aiming.png`
  (`1280x720`).
- Full-view combined comparison:
  `.agents/evidence/quiet-context-ui-system-2026-08-09/final-reference-vs-runtime-aim.png`
  (`2584x720`, source left and production runtime right).
- Cross-page Korean evidence:
  `.agents/evidence/quiet-context-ui-system-2026-08-09/final-ko-1280x720-contact-sheet.png`.
- Responsive English evidence:
  `.agents/evidence/quiet-context-ui-system-2026-08-09/final-en-1920x1080-contact-sheet.png`.
- Responsive Korean evidence:
  `.agents/evidence/quiet-context-ui-system-2026-08-09/final-ko-1600x900-contact-sheet.png`.

## Comparison Setup

- State: Stage 30, Aim View, Korean, default target, default angle/power,
  pre-launch Finish-disabled state.
- Viewport and CSS size: not applicable to this native Godot build; the source
  and primary runtime capture are both exactly `1280x720` physical pixels.
- Density normalization: none; both primary images are 1:1 at the same pixel
  dimensions.
- Renderer: Godot 4.7.1 Compatibility renderer, Windows release export.
- Focused evidence: the equal-size combined image was reviewed at full
  resolution. The separate English `1920x1080` Aim capture was also inspected
  for small legend, keycap, label, and stepper details, so no additional crop
  was required.

## Findings

- No actionable P0, P1, or P2 issue remains.
- Fonts and typography: Pretendard remains the single shared family. The runtime
  preserves the reference hierarchy: stage and run values are dominant,
  captions are restrained, and Korean/English labels do not clip or wrap
  awkwardly at the checked sizes.
- Spacing and layout rhythm: the production Aim View keeps the 24 px edge
  rhythm, centered Fire action, right-aligned angle/power instruments, direct
  top status, left coverage rail, and one shallow bottom context line. Main
  Menu and Stage Select no longer use giant enclosing cards; Pause and Settings
  retain only the one containment surface their interruption model requires.
- Colors and tokens: navy, off-white, cool gray, and blue remain Theme-owned.
  Routine surfaces are flat and quiet; only primary actions use filled blue.
  Focus, disabled, selected, and hover states remain visually distinct.
- Image quality and assets: the running terrain, glyphs, trajectory, cannon,
  flag, target icon, settings icon, mouse-wheel image, plus/minus images, and
  paint-splash image are real project assets or renderer output. No new
  placeholder or code-drawn visible asset was introduced.
- Copy and content: ammunition uses `n / n`; yaw and A/D are absent; Finish,
  Gear, Map, Follow, Briefing, Result, loading, retry, and settings behavior stay
  truthful. The context legend changes with Aim, Map, Follow, Briefing, and
  Pause.
- Responsiveness: Korean `1280x720` covers all core pages; English `1920x1080`
  covers Main Menu, Stage Select, Aim, Settings, and Result; Korean `1600x900`
  covers Stage Select and Settings. No persistent control clips, overlaps, or
  escapes the viewport in these captures.
- Accessibility and interaction states: all interactive controls remain native
  focusable controls with a 2 px focus token. Disabled Finish/Next/Previous and
  active stage/check states do not rely on text alone. Target-preserving W/S,
  wheel, and direct stepper behavior passed its focused runtime contracts.

### Accepted P3 differences

- The real mountain framing and procedural surface detail differ slightly from
  the generated concept pixels; the approved world composition and glyph band
  remain intact, and generated world pixels are not an implementation contract.
- The production Finish action uses the existing text action instead of the
  concept's decorative flag because no approved Finish icon asset exists.
- Fire renders `Space` at the same optical weight as `FIRE` inside the native
  Button. The input also appears in the context line, and the difference does
  not reduce clarity.

## Comparison History

1. Initial combined comparison:
   `.agents/evidence/quiet-context-ui-system-2026-08-09/iteration-01-reference-vs-runtime.png`.
   - P2: detached mode surface and dense status treatment drifted from the
     direct-edge reference.
   - Fix: made the mode control transparent at rest, added the two-line wind
     treatment, and integrated `Space` into the primary Fire action.
2. Second rendered comparison before final correction:
   `.agents/evidence/quiet-context-ui-system-2026-08-09/iteration-02-reference-vs-runtime.png`.
   - P2: the goal label shared the coverage marker baseline, so the blue line
     struck through localized copy at larger scales; the wheel image had weak
     contrast.
   - Fix: placed the goal label immediately below its authoritative rail tick
     and tinted the existing mouse-wheel image with the shared navy token.
3. Post-fix production comparison:
   `.agents/evidence/quiet-context-ui-system-2026-08-09/final-reference-vs-runtime-aim.png`.
   - Result: no actionable P0/P1/P2 difference remains.

## Verification

- `scripts/verify.ps1`: passed.
- Gameplay HUD, UI flow, localization, shortcut, wind/result, shot-feedback,
  and target-preserving aim contracts: passed.
- `Windows Desktop` release export: passed.
- Primary interactions exercised by tests/captures: menu and stage navigation,
  Briefing start/back, Aim/Map switch, target-preserving angle/power controls,
  Fire/Follow return, Pause, Settings open/close, manual Finish, timeout Result,
  Retry/Next/Stages states.
- Runtime capture output and Godot validation output were checked for script and
  recurring runtime errors; none remain.

## Limitations

- Hover-only animation was not recorded as video; static hover/focus/disabled
  states are covered by Theme contracts and captured focus/selection states.
- The selected concept provides an Aim View target only. Other pages were
  evaluated against its approved hierarchy and surface principles rather than
  invented pixel-for-pixel page mocks.

final result: passed
