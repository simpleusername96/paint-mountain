---
type: evidence
status: active
created: 2026-08-04
last_reviewed: 2026-08-04
scope: bounded off-desktop evidence for Phase 9 transition and projectile-flight responsiveness
source: Windows release build produced from the active Phase 9 implementation
related:
  - ../../execplans/2026-08-03-gameplay-visual-reset.md
  - ../../../docs/test-checklist.md
---

# Phase 9 Responsiveness Evidence

`responsiveness.json` was produced by the exported Windows Compatibility build
in a hidden, non-focusable, off-desktop window. It measures call duration for
menu transitions and cached Stage 1 entry, then separates verified-contact
flight frames into paint-drain and non-drain groups.

The final stage-start call is 77.013 ms, compared with 739.678 ms before lazy
surface sampling. Main-menu/stage-select calls are 1.199 ms and 0.841 ms.
During flight, 121 continuous surface sweeps wrote 4,374 pixels through 23
coalesced uploads. Paint-drain frames average 36.301 ms with a 39.738 ms p95;
non-drain frames average 32.435 ms with a 34.060 ms p95.

The off-desktop Windows window is throttled near 30 fps, so these frame values
are comparative evidence and do not prove foreground 60-fps delivery. They do
show that the former recurring large paint spikes are absent in this bounded
run and quantify the remaining paint cost relative to non-drain flight.

`projectile_and_continuous_paint.png` was captured from the same production
build while the projectile remained active. It was inspected directly and
shows a continuous blue trail over the real mountain plus 9.2% coverage. The
capture uses normal in-flight `ImageTexture.update()` publication and does not
force a replacement texture before taking the screenshot.
