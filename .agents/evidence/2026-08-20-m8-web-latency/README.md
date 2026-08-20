---
type: evidence
status: active
created: 2026-08-20
scope: M8 release-Web latency attribution, measured paint correction, immutable projectile render warm-up, and final local artifact captures
related:
  - ../../execplans/2026-08-18-three-ball-target-band-prototype.md
  - ../2026-08-20-local-itch-stability-audit/README.md
  - ../../../docs/test-checklist.md
---

# M8 local release-Web latency evidence — 2026-08-20

## Outcome

The visible Burst hitch had a concrete application owner: its radius-14 paint
batch executed as one 164.0 ms GDScript raster operation. `PaintSystem` now
advances radial commands through deterministic scan, connected-component, and
write phases with at most 512 work items per physics tick. The final Burst uses
33 slices, has a measured worst application slice of 13.6 ms, and produces the
same bytes, checksum, target count, written-pixel count, and newly-painted count
as the former completion drain.

Live and warm-up projectile visuals now use the same immutable cached meshes for
Standard, Impact Burst, and Apex Split. On the final artifact, root construction
is 1.0-1.3 ms, Apex child construction is 0.5-1.1 ms per child, and the complete
atomic Apex replacement is 12.3 ms. The Apex presentation reaches the next
`frame_post_draw` 13.4 ms after replacement completes.

The independent Chrome run does not satisfy the plan's whole-window percentile
target. The isolated automation window repeatedly stopped being scheduled for
several seconds even with background throttling disabled. The same artifact's
measured application owners stay within one 16.7 ms frame, while
`root_construction_finished` to `frame_post_draw` varies by more than 100 ms.
This exact renderer/browser scheduling boundary is retained rather than hiding
it with a gameplay change or claiming that the global target passed.

## Artifact and environment

- Godot `4.7.1.stable`, Compatibility/WebGL2, single-thread Web export, fixed
  60 Hz physics.
- Local protected server: `127.0.0.1:13034`, the registered `codex` lane.
- Isolated foreground Chrome, 1280x720 window, 1264x625 canvas, device scale 1.
- Web PCK: 10,935,028 bytes, SHA-256
  `1751DC87AD89DA8130D0E29F4F35EA347284FA39BED7C54CBD89B3BABAD356BF`.
- Web WASM: 39,513,091 bytes. Static release verification passed; total gzip
  size is 17,927,151 bytes against an 18,996,696-byte allowance.
- Delivery telemetry is opt-in through `--delivery-telemetry`; ordinary play
  does not print markers or take per-slice timestamps.

## Before/after attribution

| Boundary | Before correction | Final artifact |
| --- | ---: | ---: |
| Burst canonical paint batch | 164.0 ms, one blocking operation | 529.0 ms elapsed over 33 physics slices; worst slice 13.6 ms |
| Burst paint result | 3,150 writes; 3,099 new pixels | identical, plus byte/checksum regression equality |
| Web texture publish | synchronous full fallback | 1.5 ms; full fallback remains below one frame |
| Standard root construction | cold allocation hypothesis | 1.0 ms |
| Burst root construction | cold allocation hypothesis | 1.3 ms |
| Apex root construction | cold allocation hypothesis | 1.0 ms |
| Apex atomic three-child replacement | unqualified | 12.3 ms total; child maximum 1.1 ms |
| Apex replacement to visible effect | not a rendered boundary | 13.4 ms to `frame_post_draw` |

The final probe's raw `requestAnimationFrame` summaries are deliberately not
used as application-owner proof:

| Scenario | p95 | p99 | max | Fire input to first root frame |
| --- | ---: | ---: | ---: | ---: |
| Standard, untouched Space | 16.8 ms | 116.6 ms | 5,816.6 ms | 123.4 ms |
| Impact Burst, second Space after explicit early return | 16.8 ms | 49.9 ms | 4,949.9 ms | 54.4 ms |
| Apex Split, pointer Fire | 16.9 ms | 516.7 ms | 6,866.5 ms | 263.2 ms |

For Standard and Apex, almost all Fire-to-frame time is after construction and
admission while awaiting the rendering-server boundary. Earlier runs of the
same implementation produced materially lower root-frame delays, which is why
this variable window-level interval is not assigned back to projectile
construction. `probe-standard.json`, `probe-burst.json`, and
`probe-apex.json` retain every correlated marker and the raw frame summaries.

## Correctness and visual proof

- `delivery_latency_marker_test.gd` proves per-trace ordering and once-only
  root, paint, texture, effect, and split markers without enabling console
  output.
- `paint_queue_determinism_test.gd` proves the radius-14 sliced result is
  byte-for-byte equal to a completion barrier and emits no partial completion.
- Existing coverage, first-Fire, Burst, Apex, rapid-fire, and warm-up contracts
  pass after the change.
- `cdp-standard-aiming.png` and `cdp-standard-after-fire.png` show the untouched
  keyboard Fire path and stable responsive HUD.
- `cdp-burst-after-fire.png` shows accepted Burst paint with the next action
  fully readable. `cdp-apex-after-fire.png` shows the three admitted Standard
  children in the family camera.
- A single intermediate Apex screenshot showed a blank Fire label during a
  multi-second automation-window stall. Repeated exact-artifact runs did not
  reproduce it; the final Standard, Burst, and Apex captures all show the icon,
  label, focus, and bounds. No speculative UI change was made.

## External sources and applicability

- [Godot Web export guidance](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_web.html)
  identifies Compatibility/WebGL2 and single-thread export as the broadly
  compatible default for stores such as itch.io. That supports keeping the
  current export instead of masking GDScript work with a thread/PWA change.
- [Godot RenderingServer reference](https://docs.godotengine.org/en/stable/classes/class_renderingserver.html)
  defines `frame_post_draw` as the boundary after all viewports update. Runtime
  visibility markers therefore use it; headless tests use an explicitly named
  process-frame substitute only when a test observer is installed.
- [Godot ImageTexture reference](https://docs.godotengine.org/en/stable/classes/class_imagetexture.html)
  supports updating an existing texture rather than reallocating it. The
  running Web target does not expose the partial-update method, so the measured
  full upload remains and is reported truthfully.
- [itch.io HTML5 upload guidance](https://itch.io/docs/creators/html5)
  describes iframe embedding and Click to Play. The host launch gesture is an
  activation/audio gesture, not a synthesized Godot Fire action; the probe sends
  the first Space only after entering Aim.

## Rejected alternatives and limits

- A hidden warm-up physics shot and a second paint representation were rejected
  because they would mutate gameplay or compete with authoritative paint.
- Changing Shot Follow to allow immediate second Fire was rejected because the
  source brief requires the explicit Return/Tab transition; the Burst probe
  follows that contract.
- Threads, PWA headers, lower paint fidelity, and a new texture representation
  were not justified by the measured owner boundaries and remain out of scope.
- These captures prove the local exported artifact, not the public itch
  artifact. Browser save/audio/background/fullscreen and exact remote PCK
  identity remain M9 work.

The task-owned probe opens a fresh Chrome profile and closes it on completion.
It does not reuse the user's browser login or claim that OS window scheduling is
a stable product benchmark.
