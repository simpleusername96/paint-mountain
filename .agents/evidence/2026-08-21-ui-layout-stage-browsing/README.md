---
type: evidence
status: active
created: 2026-08-21
last_reviewed: 2026-08-21
topic: Final UI spacing, icon alignment, Aim-left composition, and Stage Select browsing responsiveness
scope: Windows release captures at 1280x720 and 640x360, rapid-selection timing, focused tests, full regression, and verification
source: ../../../builds/windows/PaintMountain.exe
related: ../../execplans/2026-08-21-ui-layout-and-stage-browsing-polish.md
---

# UI Layout and Stage Browsing Evidence

This folder retains the task's Godot/Compatibility render and timing evidence.
`phase2/` contains the post-layout development render gate, `phase3/` preserves
the timing diagnosis and correction sequence, and `phase4/` is the final
production evidence set.

## Final source

- Implementation commit: `b29505f` (`fix: polish UI layout and stage browsing`)
- Runtime: Godot 4.7.1 stable, Compatibility renderer, Korean locale
- Windows executable SHA-256:
  `620206D1E3C31A262BC16A2CDAF4AB8B6755B461B37FC77D41FC79D21FED904D`
- Final production images: Stage Select, Aim, Map, Follow, Pause, and Clear at
  1280x720; Stage Select, Aim, and Map at 640x360; plus the rapid Stage Browse
  final frame and `overview.png`.

## Visual inspection

- Pass: shared action, stepper, Settings, Pause, and Result icons are visually
  centered in their controls without changing the approved source images.
- Pass: Stage Select identity/rules, terrain-side arrows, Aim primary, and ten
  rail nodes keep distinct spacing at both evidence sizes.
- Pass: the Aim-left success range, current marker, total paint, and R/G roles
  follow one left spine with separate rows. Aim controls retain the centered
  Fire action and equal stepper rhythm.
- Pass: Map, Follow, Pause, and Clear retain their complete information and
  actions without clipping, overlap, or unintended containment surfaces.
- Pass: the final Stage Select captures wait for the asynchronous real terrain
  preview; neither desktop nor compact evidence shows an empty preview.

## Stage browsing timing

The final exported `stage-browse-release` scenario begins from a warmed Stage
01 preview, selects Stage 02, 03, and 04 on consecutive presented frames, then
waits for the latest preview.

- Selection dispatch: `135 us`, `108 us`, and `175 us`.
- Final Stage 04 artifact maximum main-thread slice: `8.890 ms`.
- Final Stage 04 preview publication: `4.591 ms`.
- Background-window present baseline maximum: `32.776 ms`.
- Browse maximum: `53.605 ms`, or `1.6355x` baseline. The off-desktop,
  non-focusable Windows capture is consistently presented near 30 FPS, so the
  relative value is the appropriate comparison.
- No intermediate Gameplay instantiation marker appears while browsing.
  `stage_selection_readiness_test.gd` separately proves that Start instantiates
  exactly one Gameplay scene for the final selection and does not commit
  `GameState` before Start.

The original failed production receipt in `phase3/` recorded a `218.629 ms`
maximum and isolated `112-158 ms` main-thread layout hydration per selection.
The final repository hydrates immutable layouts on one joined pure worker,
suppresses obsolete selected publication, reuses preview roots/material, and
separates layout, artifact, and preview publication across frames.

## Validation

- `stage_layout_repository_test.gd`, `stage_selection_readiness_test.gd`, and
  `stage_runtime_preparer_test.gd` pass after the final concurrency and frame
  separation changes.
- `scripts/test.ps1` passes the complete ordered suite.
- `scripts/verify.ps1` passes import, script parsing, and main-scene startup.
- Windows release export and all ten final production capture scenarios exit
  zero. Final runtime logs contain no task-owned error.
- The full suite retains its intentional invalid-contact diagnostic warning.
  The forced midflight Follow capture retains the known two-instance ObjectDB
  shutdown warning; the capture exits zero and the warning is not reachable in
  normal play.

The compact command, result, timing, and warning receipt is retained in
`validation-summary.txt`; verbose local logs remain excluded by repository log
policy.

## Quality audit

The post-pass found and corrected one cached-selection race: returning to an
already cached Stage now nominates that Stage in `StageLayoutRepository`, so an
older hydration cannot trigger obsolete artifact work. No competing UI owner,
second stage state, unbounded cache, or unjoined worker remains in the task
diff.
