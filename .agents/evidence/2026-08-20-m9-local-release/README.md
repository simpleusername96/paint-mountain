---
type: evidence
status: active
created: 2026-08-20
scope: final local Windows and production-Web validation before the itch.io publication approval gate
related:
  - ../../execplans/2026-08-18-three-ball-target-band-prototype.md
  - ../2026-08-20-m8-web-latency/README.md
  - ../../../docs/test-checklist.md
---

# M9 local release validation — 2026-08-20

## Outcome

The final local gate passes. The complete ordered suite, final verification,
Godot 4.7.1 Windows and single-thread Web release exports, Web static checks,
five Windows/Compatibility captures, and the production Web interaction
journey all pass. The local Web journey covers first keyboard Fire without an
Aim-screen click, once-only pointer Fire, both special-ball families, responsive
Settings, pause, browser fullscreen, persistence, background/resume, and
console/network health.

This does not prove the public itch.io revision. No push, workflow dispatch,
Butler upload, visibility change, or public-page interaction was performed.

## Source and artifacts

- Task implementation commits: `eb1ee6c`, `c6bfc23`, `d42168e`, and
  `6741674`. The current branch also contains the independent instruction-only
  commit `9e971bf`; it does not change the packaged game.
- Runtime: `4.7.1.stable.official.a13da4feb`, Compatibility renderer, fixed
  60 Hz physics, Windows desktop first and single-thread Web/WebGL2.
- Windows executable: 120,954,992 bytes, SHA-256
  `248E6324E0664B7EDA0D865AFB12B8A3468D681D9469680EBDA026D050CEB1E7`.
- Web PCK: 10,935,028 bytes, SHA-256
  `1751DC87AD89DA8130D0E29F4F35EA347284FA39BED7C54CBD89B3BABAD356BF`.
- Web WASM: 39,513,091 bytes, SHA-256
  `35116F68540AC41ACF7D71EA457ADDED91B5E960A9CCA3E2ACC72918EAF01277`.
- Web `index.html`: SHA-256
  `DA334DA462835EB6639E0E37CF41933315B72F013AA0A622E0FC4D10AD1E96E4`.
- The 12-file Web artifact is 50,785,592 raw bytes and 17,927,123 estimated
  gzip bytes, below the 18,996,696-byte allowance.

The first Windows export attempt encountered the just-built executable still
holding its destination briefly and left the exact export-owned
`PaintMountain.tmp`. The process exited on its own; the stale temporary file
was verified and removed, and the clean retry passed. No source file or prior
release was removed.

## Automated gate

- `scripts/test.ps1`: complete ordered suite passed once after implementation
  was frozen.
- `scripts/verify.ps1`: import, editor parse, and startup verification passed.
- Windows and Web release exports completed successfully.
- `scripts/verify-web-release.ps1`: exact-case references, single-thread
  artifact shape, and size limits passed.
- The post-implementation responsibility audit found no competing owner for
  Fire admission, state transitions, projectile families, paint authority, or
  responsive presentation. Runtime timers are active only for opt-in delivery
  telemetry.

## Windows render review

The implementing agent inspected each 1280x720 source image at native size:

- `01-windows-aiming-1280x720-ko.png`: Fire, Aim controls, target band, queue,
  status, and shortcut legend remain inside their panels with no overlap.
- `02-windows-pause-1280x720-ko.png`: the modal and context legend are readable
  over the dimmed game with a truthful Continue focus.
- `03-windows-settings-1280x720-en.png`: both columns, sliders, switches,
  selectors, and footer actions fit with 24 px safe margins.
- `04-windows-impact-burst-1280x720-ko.png`: the once-only Burst cue and
  accepted radial paint are visible without obscuring the primary HUD.
- `05-windows-apex-split-1280x720-ko.png`: three red Standard children are
  simultaneously readable as one split family.

All five capture processes returned zero. Their standard-error logs are empty,
and their standard output contains no script error or warning.

## Production Web interaction

The final `builds/web` artifact ran on the registered codex-lane server at
`127.0.0.1:13034` in foreground Chrome. The browser was exercised at 1280x720
and 1024x768 without delivery command-line arguments.

- Explicit keyboard activation entered Play. After pointer Start entered Aim,
  the next untouched Space consumed exactly one Stage 01 shot and produced
  visible paint without an intervening canvas or control click.
- One browser-dispatched pointer press/release/click sequence on Fire consumed
  exactly one additional shot; it did not double-fire.
- Stage 02 fired its second token, Impact Burst. The queue consumed one token
  and the accepted wide radial paint appeared.
- Stage 03 fired its first token, Apex Split. The queue consumed one token and
  the three-child family executed. The same-PCK Web captures retained under
  `../2026-08-20-m8-web-latency/` show the Burst and Apex families directly.
- Pause and Settings opened and remained bounded. At 1024x768 Settings changed
  to the intended one-column scroll layout with a fixed footer and no clipping.
- The document entered and exited the browser Fullscreen API successfully.
  Resizing between 1280x720 and 1024x768 preserved usable controls.
- Master volume changed from 80% to 28%, survived a page reload through the
  Godot Web save store, and was restored to 80% after verification.
- A second tab held the game in the background for two seconds. Returning to
  the game preserved Settings state and accepted subsequent input.
- Two loads produced 16 successful `200`/`304` document, script, PCK, WASM,
  icon, and blob requests. The console contained only Godot/WebGL2/build and
  gameplay-ready logs: no error, warning, rejected promise, missing resource,
  or blocked-audio message.

The interaction supplied keyboard and pointer activation before gameplay, and
Chrome reported no audio-unlock warning. Automation does not prove audible
speaker output, so an audible public-host check remains in the post-publish
manual journey.

## Remaining boundary

The application-owned Burst slice, projectile construction, Apex replacement,
texture upload, and effect-to-render boundary remain within one 16.7 ms frame
as recorded in M8. Whole-window Chrome percentiles were polluted by multi-second
automation-window scheduling stalls and are not claimed as passing.

The active plan remains open for explicit publication authorization, CI/Butler
completion, deployed-PCK hash equality, and the exact public itch launcher and
iframe journey. The public check must include audible audio, host fullscreen,
save/reload, background/resume, both special balls, and console/network health.
