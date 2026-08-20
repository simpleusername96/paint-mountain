---
type: evidence
status: active
created: 2026-08-20
last_reviewed: 2026-08-20
scope: production-render evidence for the Cannon Focus cross-stage UI refinement
related:
  - ../../execplans/2026-08-20-cross-stage-ui-theme.md
  - ../../../docs/reports/ui-refinement-2026-08-20/index.html
---

# Cannon Focus production-render evidence

This directory records the actual Windows/Compatibility-renderer output used
to close ExecPlan tasks 4.1-4.3. The captures come from the release-exported
`builds/windows/PaintMountain.exe`, not the editor or a mockup.

## Artifact

- Runtime: Godot 4.7.1 stable, Compatibility renderer, Windows desktop release.
- Executable: `builds/windows/PaintMountain.exe`
- Size: `120,981,448` bytes
- SHA-256: `039159CEB68F168BD1D266FEF0C51F07058450B6266DE6A990E32C8951EB66EF`
- Capture process: a real non-focusable Windows game window was placed outside
  the desktop, rendered at the named viewport, read back after frame draw, and
  exited after each image. No `PaintMountain` process remained afterward.
- Reproduction: run `recapture.ps1` from the repository root after exporting
  the current Windows release.

## Capture matrix

All 20 PNG files were regenerated from the artifact above and verified as
nonblank with exit code 0 on 2026-08-20.

| File | State | Stage | Locale | Viewport |
| --- | --- | --- | --- | --- |
| `01-main-menu-ko-1280x720.png` | Main Menu | 01 preview | ko | 1280x720 |
| `02-stage-select-stage30-ko-1280x720.png` | Stage Select with real selected terrain | 30 | ko | 1280x720 |
| `03-pause-stage01-ko-1280x720.png` | Pause | 01 | ko | 1280x720 |
| `04-settings-stage01-ko-1280x720.png` | Settings | 01 | ko | 1280x720 |
| `05-briefing-stage01-ko-1280x720.png` | Briefing | 01 | ko | 1280x720 |
| `06-aiming-stage01-ko-1280x720.png` | Cannon Focus Aim | 01 | ko | 1280x720 |
| `07-clear-stage01-ko-1280x720.png` | Target-band success Result | 01 | ko | 1280x720 |
| `08-aiming-stage03-ko-1280x720.png` | Cannon Focus Aim | 03 | ko | 1280x720 |
| `09-shot-follow-stage03-ko-1280x720.png` | Real airborne Shot Follow | 03 | ko | 1280x720 |
| `10-queue-description-stage03-ko-1280x720.png` | Ball queue description | 03 | ko | 1280x720 |
| `11-failed-stage03-ko-1280x720.png` | Target-band failure Result | 03 | ko | 1280x720 |
| `12-aiming-stage07-ko-1280x720.png` | Coverage-family Aim | 07 | ko | 1280x720 |
| `13-result-stage07-ko-1280x720.png` | Coverage-family Result | 07 | ko | 1280x720 |
| `14-aiming-stage30-en-1920x1080.png` | Large English Aim | 30 | en | 1920x1080 |
| `15-map-stage30-en-1920x1080.png` | Map Inspection | 30 | en | 1920x1080 |
| `16-result-stage30-en-1920x1080.png` | Large English Result | 30 | en | 1920x1080 |
| `17-aiming-stage01-ko-640x360.png` | Compact Aim stress | 01 | ko | 640x360 |
| `18-stage-select-stage01-en-640x360.png` | Compact Stage Select stress | 01 | en | 640x360 |
| `19-settings-stage01-ko-640x360.png` | Compact scrollable Settings stress | 01 | ko | 640x360 |
| `20-result-stage01-ko-640x360.png` | Compact Result stress | 01 | ko | 640x360 |

## Findings and corrections

Initial inspection found three P1 visual defects and no P0 blocker:

- Stage Select and Result used visible hard-edged dark sheets. Both now use the
  shared `WorldGradientScrim`, so the world remains continuous and dominant.
- Briefing, Aim, Map, and Result repeated mode or instructional copy. Duplicate
  text was removed; Map retains only Orbit and Zoom, and semantic detail remains
  in accessibility names where visible copy was compacted.
- The result fact row could wrap in large English layouts. It now uses compact
  icon-first facts while preserving the full accessible description.

The corrected matrix shows:

- Cannon Focus hierarchy at both 1280x720 and 640x360: vertical 0-100 score,
  queue, cannon, trajectory, and `angle -> Fire -> power` remain visible.
- Briefing and Result use horizontal score scales with visible 0 and 100
  endpoints; no score scale is cropped to the current target band.
- Stage Select shows the actual generated terrain for the selected stage and a
  compact stage rail without replacing the world with a card grid.
- Hover/focus/press-equivalent queue detail is rendered in the real Aim state.
- Pause, Settings scrolling, success/failure Results, Korean/English copy,
  focus, and legal actions do not clip or overlap in the named matrix.
- No P0/P1 visual issue remains. Minor terrain contrast differences are the
  authored world lighting, not UI obstruction.

## Targeted checks

The following Godot 4.7.1 checks passed after the rendered corrections:

- `screen_responsive_layout_test.gd`
- `localization_ui_test.gd`
- `first_fire_focus_test.gd`
- `ball_queue_tooltip_test.gd`
- `hud_layout_responsive_test.gd`
- `phase8_hud_truth_test.gd`
- `shortcut_prompt_test.gd`
- `stage_select_rule_truth_test.gd`
- `shared_ui_component_ownership_test.gd`
- `essential_ui_copy_test.gd`
- `phase7_ui_test.gd`
- `cross_stage_ui_theme_test.gd`

The source capture path also proved that `shot_follow_midflight` retains a real
airborne projectile through readback.

## Built-Web journey

- Export: Godot 4.7.1 single-thread Web/Compatibility release.
- Static verifier: 8 exact-case references; 50,812,044 raw bytes and 17,945,291
  gzip bytes against the 18,996,696-byte allowance.
- Local protected server: `http://127.0.0.1:13034/`, the fastrun registry's
  `codex` Web lane. The port was free before the run and free after the exact
  task-owned Python server PID was stopped.
- Browser: one isolated Chrome DevTools session, WebGL 2.0 Compatibility.
- `index.html`: 5,446 bytes, SHA-256
  `7A5C3FFF7865AE6AAE49DFCDAE1E927191A275C67E340AE71A789B272AF98EE6`.
- `index.pck`: 10,961,480 bytes, SHA-256
  `553AF54E5F939DFEBD1414F27DAD2019672E36807A73A3CFC58BB8B638D0750E`.
- `index.wasm`: 39,513,091 bytes, SHA-256
  `35116F68540AC41ACF7D71EA457ADDED91B5E960A9CCA3E2ACC72918EAF01277`.

The journey covered Main Menu, Stage Select with Stage 03/07 terrain swaps,
Briefing, Aim, Pause, Settings, English language switching, browser fullscreen
entry and exit, Stage 03 queue description, real firing/paint and timeout
failure Result, Stage 07 real firing/paint and manual Result, and a 640x360
live resize. The Canvas resized from 1280x720 to 640x360 without stale terrain,
clipping, or input interception. All 8 release requests returned HTTP 200.
Chrome recorded four Godot initialization/informational logs and zero error or
warning messages. The task did not run a second browser stack.

The Chrome journey used the immediately preceding release artifact. The only
later Web-visible source correction moved two unchanged presentation colors
and an outline size into the existing Theme owner; it changed no interaction,
layout, timing, or pixel value. The final artifact hashes above come from the
post-correction export and static verification. The 20 Windows captures were
regenerated from the corresponding final Windows export.

The fired Stage 03 and Stage 07 paths showed authoritative paint when the shot
returned to Aim and in Result; no multi-second post-flight visual update was
observed. The existing M8 owner measurements and deterministic paint/projectile
tests remain the exact latency regression evidence and are rerun at the final
gate. No public itch upload, channel change, or visibility change is part of
this evidence.

## Final production gate

The complete ordered `scripts/test.ps1` suite and `scripts/verify.ps1` passed
on the frozen source. Fresh Windows and Web release exports then completed, and
`scripts/verify-web-release.ps1` passed with the final values above. One
`projectile_settling_test` invalid-geometry warning is an expected diagnostic
from its recovery fixture; the test passed and no production warning was
suppressed. No `PaintMountain` process or task-owned local server remained.
