---
type: evidence
status: active
created: 2026-08-11
topic: web-runtime-responsiveness
scope: Windows release captures, local Chromium Web smoke, release artifact checks, and measurement limitations
source: ../../../.agents/execplans/2026-08-11-web-runtime-responsiveness.md
related:
  - ../../../.agents/Documentation.md
  - ../../test-checklist.md
---

# Web Runtime Responsiveness Evidence

## Outcome

The reported startup focus, Map Inspection drag direction, stage-entry build
ownership, cold first-use render work, and Web coverage icon defects are
corrected in the local source and release exports. Automated and functional
checks passed. Foreground frame budgets, three-cycle memory growth, and the
deployed itch revision are not certified by this evidence.

## Release Artifacts

- Engine: Godot `4.7.1.stable.official.a13da4feb`, Compatibility renderer,
  fixed 60 Hz physics, official single-thread Web template.
- Windows executable: `builds/windows/PaintMountain.exe`, 118,996,224 bytes,
  SHA-256 `7DD9F9FF568762D7B0880194A3D87FF9A08C9DDFD8EA568DE0DBE9F7AF77426A`.
- Web encoded initial payload: 16,779,326 bytes across 12 files. This is 2.84%
  below the accepted 17,269,724-byte baseline and below the 20 MiB cap.
- Main Web files: Wasm 39,513,091 raw / 10,263,400 gzip bytes; PCK 8,981,924
  raw / 6,402,378 gzip bytes; JavaScript 279,815 raw / 69,462 gzip bytes.
- The release validator found eight exact-case runtime references, all required
  icons and audio worklets, no worker artifact, and thread support disabled.

## Running-Game Captures

- `runtime/main-menu-ko-1280x720.png`: loading stays visible while preparation
  advances; passive startup has no focus ring.
- `runtime/main-menu-ready-ko-1280x720.png`: the prepared Stage 01 preview and
  Play action are ready without an automatic focus ring.
- `runtime/aiming-stage02-ko-1280x720.png`: Korean Aim View and the texture-based
  coverage target icon fit without clipping or missing glyphs.
- `runtime/map-inspection-stage02-ko-1920x1080.png`: Map Inspection fits at the
  large viewport; the visible focus border is intentional because the capture
  driver activated the Map control.
- `runtime/aiming-stage02-en-1920x1080.png`: English Aim View and coverage icon
  fit without clipping or missing glyphs.

All five images came from the fresh Windows release executable and were opened
and inspected at their native dimensions.

## Local Chromium Functional Smoke

- The fresh Web release launched through WebGL2/Compatibility with the official
  single-thread runtime. `crossOriginIsolated` was false as expected, the WebGL2
  context was not lost, and three audio worklet processors loaded.
- The console had no warning or error. Passive launch showed no focus ring;
  keyboard focus and Enter activation worked after readiness.
- Ready-stage handoff reached Briefing, Aim View opened, first and second Fire
  produced visible paint, and an actual left-button Map Inspection drag changed
  the camera. The direction contract is also covered by the deterministic
  `map_inspection_direction_test.gd` projection test.
- Canvas resize was checked at 1280x720 and 1920x1080. Browser device scaling
  used a 1.5 device-pixel ratio; the Godot canvas adapted without clipping.
- Final sampled JavaScript heap was 14,123,528 used / 14,835,712 total bytes.
  This single endpoint is diagnostic only and is not a lifecycle memory result.

## Discarded Performance Samples

The automated Chrome window rendered animation frames at approximately
1,000-1,017 ms intervals despite reporting a visible document. A 20-frame
`requestAnimationFrame` sample also exceeded the automation timeout. This
background-throttled environment invalidates frame pacing and load-time
measurements under the execution contract.

The first-shot trace observed one task above 50 ms and the second-shot trace
observed none, but both traces are discarded. The apparent 69-second stage
preparation is also discarded because cooperative build phases intentionally
yield to animation frames and the test window supplied only about one frame per
second. No p95, p99, maximum-frame, launch-time, or Fire-response pass is
claimed from these samples.

## Verification

- New focused focus/orbit/preparation/prepared-entry/warm-up checks: passed.
- Full ordered Godot suite: passed.
- `scripts/verify.ps1`: passed.
- `scripts/verify-web-release.ps1`: passed.
- Fresh Web and Windows release exports: passed.
- Scoped codebase-quality audit: no unresolved task-scoped contract break,
  competing owner, reachable failure path, or missing required automated gate.

## Remaining Gates

- Repeat cold/warm launch, stage-entry, first/second Fire, and interaction traces
  in a genuinely foreground 60 Hz Chrome window.
- Run the three-cycle stage enter/fire/restart/exit memory comparison, save and
  reload, host fullscreen, background/resume, and unlocked-audio checks.
- Publish only after explicit user authorization, then repeat the functional and
  performance smoke on the deployed itch revision. Draft visibility must remain
  unchanged.
