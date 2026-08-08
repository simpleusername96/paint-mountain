---
type: evidence
status: active
created: 2026-08-08
scope: running-release evidence for the casual shared UI refresh
related:
  - ../../execplans/2026-08-08-casual-shared-ui-refresh.md
  - ../../../docs/concepts/casual-ui-directions-2026-08-08/index.html
  - ../../../resources/ui/paint_mountain_theme.tres
---

# Casual Shared UI Refresh Evidence

## Purpose

Prove the implemented shared component refresh in the exported Windows game and
keep that proof separate from the ImageGen exploration set.

## Sources

- Godot 4.7.1 Compatibility renderer.
- Windows Desktop release export at 1280x720 Korean and 1920x1080 English.
- Production capture path owned by `src/delivery/delivery_capture_runner.gd`.
- Prior audit captures under `docs/experience-audit-assets/` and the primary
  target comparator under `docs/handoffs/gameplay-visual-reset-2026-08-03/`.

## Captures

- `01-main-menu-1280x720.png`
- `02-stage-select-1280x720.png`
- `03-aim-stage30-1280x720.png`
- `04-pause-stage30-1280x720.png`
- `05-settings-stage30-1280x720.png`
- `06-aim-stage30-1920x1080-en.png`
- `07-before-after-board.png`
- `08-reference-runtime-board.png`

## Findings

- Main Menu no longer stretches a mostly empty card across the screen. The
  primary action and secondary actions form a compact, padded stack.
- Stage Select uses balanced full-height selection and detail surfaces. Eight
  larger stage cards fit without collision or clipped labels.
- Aim controls fit their container and sit at the lower-right, clear of the
  cannon, wind flag, coverage rail, centered Fire button, and world target.
- Pause and Settings inherit the same shared Theme roles without losing their
  actions. The 1920x1080 English Aim View keeps values and controls inside their
  surfaces.
- Direct review found no overlap, clipping, unsupported action, or unreadable
  Korean label in the recorded states.

## Validation

- Godot editor import and parse: passed.
- `powershell -ExecutionPolicy Bypass -File scripts/verify.ps1`: passed.
- Windows Desktop release export: passed.
- The concept directory contains `.gdignore`, so the nine documentation images
  are not imported or bundled as production game resources.
- Every capture listed above was opened and inspected directly.

## Limitations

- The captures prove only the named states and sizes, not every localization or
  transient animation frame.
- The nine ImageGen images in the linked concept gallery are not runtime proof.
- Settings remains intentionally more modal and information-dense than the
  three primary screens; it is coherent, but was not structurally redesigned.
