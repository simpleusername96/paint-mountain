---
type: evidence
status: active
created: 2026-08-10
last_reviewed: 2026-08-10
scope: release captures, combined comparisons, and validation record for the approved-image fidelity correction
source: ../../../docs/reports/screen-audit-2026-08-10/index.html
related:
  - design-qa.md
  - ../../execplans/2026-08-10-approved-image-fidelity-correction.md
  - ../../../docs/test-checklist.md
---

# Approved Image Fidelity Correction Evidence

## Purpose

Record source-backed runtime, comparison, and validation evidence for the seven
approved-image fidelity corrections.

## Sources

- The approved screen-audit source linked in frontmatter.
- The completed execution contract, focused Godot 4.7.1 checks, Windows release
  export, task-owned captures, combined comparisons, and `design-qa.md`.

## Findings

The exported Godot 4.7.1 Windows runtime now reproduces the recognizable
composition, hierarchy, assets, spacing, and neutral terrain values of all
seven approved images. Actual stage topology, paint, mechanisms, result facts,
and preference state remain runtime truth rather than copied concept pixels.

## Validation

- Focused checks passed: `phase7_ui_test.gd`, `essential_ui_copy_test.gd`,
  `localization_ui_test.gd`, `camera_safety_test.gd`, and
  `terrain_camera_safe_rect_test.gd`.
- `scripts/verify.ps1` passed after the final implementation changes.
- The canonical `Windows Desktop` release export passed and produced
  `builds/windows/PaintMountain.exe`.
- The exported executable generated all captures through the hidden background
  delivery path. The implementing agent inspected the seven final combined
  sheets and the Korean 1600x900 and English 1920x1080 density checks.
- The task-owned quality audit found no responsibility creep, competing owner,
  broken contract, reachable failure path, or missing focused validation.
- `design-qa.md` records zero actionable P0, P1, or P2 findings and ends with
  `final result: passed`.

## Runtime Captures

| State | Size / locale | File | SHA-256 |
| --- | --- | --- | --- |
| Main Menu | 1280x720 / ko | `runtime/ko-1280x720-main-menu.png` | `f6b9ac7a07af357877321edd7e1648ba7105897d375cd2be35959cdf9bdc9284` |
| Stage Select | 1280x720 / ko | `runtime/ko-1280x720-stage-select.png` | `913745e72133f1d72e94f3f883da341ba2983775bde7a82d4c849a8c459709cc` |
| Briefing, Stage 02 | 1280x720 / ko | `runtime/ko-1280x720-briefing.png` | `fbb95a15216e220f6f15821d33c00da24b57479f138a7172bebfd929bef5697d` |
| Aim View, Stage 30 | 1280x720 / ko | `runtime/ko-1280x720-aiming-stage30.png` | `6de849ac20684051e5ca5c6add79fb13723a9d94807d3cdc63d02ab979a149a7` |
| Settings | 1280x720 / ko | `runtime/ko-1280x720-settings.png` | `f84ba9cfd80f8a7d253c71097ff67b792028daaf42b17ae7613c6440d45f638d` |
| Manual Result, Stage 02 | 1280x720 / ko | `runtime/ko-1280x720-manual-result.png` | `1b182fde255039d52e01dc4a90c486c2283286dfee1f177aff1fec67ac349843` |
| Timeout Result, Stage 02 | 1280x720 / ko | `runtime/ko-1280x720-timeout-result.png` | `3aac31f1832ff3024c71fbed1b8dfd6b5d900fdfbd298b91c66417ca104d8366` |
| Stage Select density | 1600x900 / ko | `runtime/ko-1600x900-stage-select.png` | `27ee71dd24f95c2a6755ec8f0aac10039fa732330cbf8795047d2e925b2e233c` |
| Settings density | 1600x900 / ko | `runtime/ko-1600x900-settings.png` | `ef6877a86f8a3a9fa7ce30f9aa5711f9a4d9c00ddcf2760971a91d0e0ce37c7f` |
| Stage Select localization | 1920x1080 / en | `runtime/en-1920x1080-stage-select.png` | `aff65b8f67a20295a5523d5f8831b7c06aeaca1ac71d1daa011ebdbef51d1119` |
| Settings localization | 1920x1080 / en | `runtime/en-1920x1080-settings.png` | `06d7af49c199525b2481eaf7dd8ad78931f60268d8d8e7979b7efc783bdc032f` |

## Combined Comparisons

Each 2560x764 image contains the uniformly fitted 1280x720 approved source on
the left and final exported runtime on the right.

- `comparisons/01-main-menu-comparison.png`
- `comparisons/02-stage-select-comparison.png`
- `comparisons/03-briefing-comparison.png`
- `comparisons/04-aim-view-comparison.png`
- `comparisons/08-settings-comparison.png`
- `comparisons/09-manual-result-comparison.png`
- `comparisons/10-timeout-result-comparison.png`

## Artifact Identity

- Executable size: `188099784` bytes
- Executable SHA-256:
  `e8022a6b243ae15c57a2ebbf9134e6a2a0fee59d0018f8afcd041dd995bf1dce`
- Project-generated Settings and selection asset provenance is recorded in
  `assets/ui/icons/GENERATED_ASSETS.md` and `docs/asset-licenses.md`.
