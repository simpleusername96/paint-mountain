---
type: evidence
status: archived
created: 2026-08-04
last_reviewed: 2026-08-04
scope: bounded off-desktop evidence for Phase 10 Fire, rendered follow-camera, and verified-contact paint responsiveness
source: Windows release builds produced from the active Phase 10 implementation
related:
  - ../../execplans/2026-08-03-gameplay-visual-reset.md
  - ../../../docs/test-checklist.md
---

# Phase 10 Fire-to-Flight Evidence

## Purpose

`responsiveness.json` is the final post-refinement run from the canonical
`builds/windows/PaintMountain.exe` in a hidden, non-focusable, 1280x720
Compatibility-renderer window. The run kept fixed 60 Hz physics and observed
121 continuous sweeps, 3,949 written pixels, 1,049 newly painted pixels, 21
texture publications, and an active projectile at the stop point.

## Sources

- `responsiveness.json`, written by the canonical exported Windows runner.
- `airborne_follow.png` and `verified_continuous_paint.png`, captured from the
  Phase 10 Windows release path and inspected directly.
- the final canonical executable and the unchanged local fastrun registry.
- the final `scripts/verify.ps1` import, parse, and startup result.

## Findings

The locked Fire and camera gates pass. Dirty-aim Fire returned false in
`0.002 ms` without consuming a shot or spawning a projectile; ready Fire
succeeded in `1.255 ms`. The interpolated projectile moved on 195 sampled
rendered frames, the follow camera moved on all 195, and its longest unchanged
run was zero frames.

The direct paint-drain budget also passes after caching only the accepted
64x48 topology-cell triangle data while leaving every 512-square mask sample
lazy. Nonempty drain duration measured `1.922 ms` p95 and `6.357 ms` maximum.
The sole remaining runner failure is the off-desktop rendered-frame comparison:
paint-drain p95 was `38.723 ms` and non-drain p95 was `34.266 ms`, a `4.457 ms`
delta against the locked `4.0 ms` gate. Windows throttles this off-desktop
window near 30 fps, so the result is recorded as unresolved comparative
evidence, not foreground acceptance; no threshold was changed.

`airborne_follow.png` and `verified_continuous_paint.png` are nonempty 1280x720
captures from a Phase 10 Windows release build using the same gameplay and
visual contracts. They were inspected directly. The first shows the physical
blue projectile airborne between the cannon and the mountain while FOLLOW is
active. The second shows the active projectile against a continuous saturated
blue trail on the real faceted terrain with 8.1% authoritative coverage. The
projectile/terrain chain remains unobscured by the HUD. The later cell-table
refinement changes only when canonical triangle data is cached and does not
change render output.

Artifact details:

- `airborne_follow.png`: 96,623 bytes, SHA-256
  `5D272838846A92D99419F6F08421580FEDC8DCA4F433754F3AE94543EE25D741`.
- `verified_continuous_paint.png`: 96,496 bytes, SHA-256
  `D1A7FAF1B430C0D60A0334EFFA9E7A98CE1BA224B8330F7D1EADAE07F1952C0B`.
- canonical executable: 132,519,808 bytes, written `2026-08-04 22:30:54`,
  SHA-256 `BBABAE5247A6A7568A959C51447C022DA0538C96FC7975A1C6CF37ED5764FE49`;
  it postdates the latest Phase 10 production source at `22:30:24`.
- fastrun registry SHA-256 remained
  `8472FA3D3FD181A7B2F1BC660DDAFAE482E2AB84F8C4D12AD46CD4232143B72F`;
  line 45 remains `D:\npjt\paint-mountain<TAB>& '.\builds\windows\PaintMountain.exe'`.

## Limitations

`scripts/verify.ps1` passed Godot 4.7.1 import, script parsing, and the bounded
headless main-scene startup after the final production change. No broad suite,
`scripts/test.ps1`, visible Godot process, or foreground acceptance run was used.
