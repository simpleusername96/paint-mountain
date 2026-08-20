---
type: evidence
status: active
created: 2026-08-21
last_reviewed: 2026-08-21
topic: Final production full-viewport UI evidence for the v13 stage and shared UI refinement
scope: Korean 1280x720 primary states, matching 640x360 stress states, and late-chapter representatives
source: ../../../builds/windows/PaintMountain.exe
---

# Final Stage and UI Captures

This folder is the final full-viewport render batch from the local production
Windows export. It contains no crops. Run `recapture.ps1` from the repository
root to replace the complete batch from the current release executable.

The result fixtures use the real terminal UI transition but inject deterministic
visible score facts for layout evidence. They are not physical clear witnesses.
Static feasibility and shared-mechanic runtime evidence are recorded separately.

## Sources

- Windows executable: `119,271,576` bytes
- Windows SHA-256: `7B82A1F2375A171520380050CFA5FB7E3D1623EA7BCBF8DCC294D99F856F3D38`
- Web PCK: `10,200,200` bytes; SHA-256
  `EDB70F4792B875EA8DCC3FCD50F61FE1353C21FAF074B30D6004F3FFB54010B4`
- Capture result: 28 complete PNG viewports, 6,102,045 bytes total, no empty
  image, and no remaining `PaintMountain` process after the batch.

## Coverage

- `01-11`: the complete 1280x720 primary journey—Main Menu, Stage Select,
  Briefing, Aim, queue detail, Map, Shot Follow, Pause, Settings, Clear, Failure.
- `12-22`: the same critical surfaces at the full 640x360 stress viewport.
- `23-28`: Stage 07/12/18/24/30 late-rule representatives and a real Stage 09
  subtractive negative-score result.

## Findings

- No viewport has clipped controls, white queue cards, duplicate queue
  descriptions, truncated 0-100 endpoints, detached queue detail, or a central
  Shot Follow return action.
- The compact top row keeps Run Status clear of Settings. Compact Results hide
  the competing stage row, so verdict and stage identity no longer overlap.
- Queue descriptions use the shared label with a canvas-stable dark outline;
  they remain attached below the tokens without adding a panel.
- Stage Select keeps live terrain visible at both sizes. Stage 07-30 examples
  show Red/Green signs and their required special-ball glyphs. The final
  Stage Select recapture uses shared vector ball glyphs; no platform-font
  symbol or Web missing-glyph box remains.
- Limits: rendered composition does not prove human balance, screen-reader
  output, live Web timing, or exact per-stage rigid-body clears.

## Built-Web journey

- The final Web artifact ran at the registered codex-lane URL
  `http://127.0.0.1:13034/index.html` in Chrome WebGL2/Compatibility,
  single-threaded, at 1280x720.
- Stage 03, 07, 18, and 30 each entered through Stage Select, Briefing, and Aim,
  accepted one real Fire, consumed one queue token, painted the terrain, and
  updated the signed score. Captures taken 0.8-1.2 seconds after Fire showed the
  ball/paint/score together; no seconds-late paint tail appeared.
- After the vector-glyph correction, the final Web PCK was reloaded without
  cache. Stage 01/07/30 rule rows contained no missing glyph and current-build
  Stage 30 again accepted Fire, painted, and updated to `0.6`.
- Preserved browser output contains Godot/WebGL/build/ready logs only: no
  error or warning. All eight initial document/script/PCK/WASM/icon/blob
  requests returned `200`.
- This local journey does not prove public itch deployment or human balance.
