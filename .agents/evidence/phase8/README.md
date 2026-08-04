---
type: evidence
status: active
created: 2026-08-04
topic: Phase 8 actual running-game visual inspection
scope: 1280x720 Windows release aiming and continuous-contact paint evidence
source: builds/windows/PaintMountain.exe
related:
  - ../../execplans/2026-08-03-gameplay-visual-reset.md
  - ../../design/UIUX_GUIDELINES.md
  - ../../design/ART_DIRECTION.md
---

# Phase 8 Running-Game Evidence

## Purpose

Record the final implementation-side visual inspection performed on the real
Windows Compatibility-renderer build without taking focus or visible desktop
space from the user.

## Sources

- `aiming.png`: First Descent aiming state.
- `aiming_burst.png`: Burst Basin aiming state.
- `aiming_split.png`: Split Ridge aiming state.
- `projectile_and_continuous_paint.png`: active First Descent projectile after
  at least 72 applied surface sweeps and 400 written paint pixels.
- Matching `.log` files record successful runtime capture completion.

## Findings

- Each aiming frame shows a closed faceted mountain mass, foreground cannon,
  full initial ballistic arc, and first-impact marker.
- Later stages visibly add ridge/valley complexity, and the enlarged amber,
  violet, and coral mechanisms can be distinguished without aiming-state text
  labels. Their effective visible, gameplay-collision, and placement envelopes
  share the same 2x scale, and the focused physical run resolves matching stable
  mechanism body/shape identities for prediction and real contact.
- The HUD has one left current/target coverage gauge, one bottom-center Fire
  action, top-right shots and gear, and no ordinary-aiming replay bar or
  top-center duplicate coverage card.
- The active-shot frame shows a broad initial contact joined to a long,
  continuous downhill blue path; the authoritative gauge reads 6.7%.
- Matching capture logs contain no `ERROR`, `SCRIPT ERROR`, or warning entry.

## Limitations

- These images establish implementation-side rendered evidence, not user
  acceptance or broad gameplay QA.
- The upper crown remains steep in a few places, and the observation control bar
  overlaps a small upper-right slice of the mountain; neither obscures the
  cannon, paint route, or primary contact area in the captured MVP states.
- Performance, replay, balance, exhaustive reliability, and complete Stage 2/3
  playthroughs were intentionally not evaluated in this pass.
