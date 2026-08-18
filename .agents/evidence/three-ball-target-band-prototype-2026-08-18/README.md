---
type: evidence
status: active
created: 2026-08-18
last_reviewed: 2026-08-18
scope: Three-ball red/green target-band prototype implementation, player-flow calibration, and compact release validation.
source: Godot 4.7.1 Compatibility runtime captures, repository tests, and one bounded performance workload.
related:
  - .agents/execplans/2026-08-18-three-ball-target-band-prototype.md
  - docs/test-checklist.md
---

# Three-ball target-band prototype evidence

## Render matrix

The `matrix/` directory contains 48 raw running-game frames. Each combination
of English/Korean and 1280x720, 1600x900, and 1920x1080 includes Stage Select,
Briefing, Aim, Map, Shot Follow, late queue, Clear, and Failed. The six images
under `matrix/contact-sheets/` are derived review sheets; the raw frames remain
the authoritative render evidence.

All frames were captured from the Godot 4.7.1 Compatibility renderer after a
`RenderingServer.frame_post_draw` boundary. Personal inspection confirmed:

- target band, current score, signed channel contributions, shots, and queue
  state are readable without relying on color alone;
- the target-only Briefing copy and Stage Select facts fit in both languages;
- the queue omits empty tail slots and is absent during Shot Follow/results;
- Clear/Failed metrics and Same Deal/New Deal actions are legible;
- no inspected frame has clipping, material overlap, stale state, or central
  world obstruction.

The `qa/` directory retains exploratory frames for the special queue plus
Burst and Apex Split mid-flight silhouettes. The result-screen clear capture is
a presentation fixture applied after a real terminal state transition; it is
visual evidence only. The failed capture uses the real zero-score terminal
path.

## Bounded rule and play evidence

`tests/prototype_stage_rule_test.gd` validates 16 structural deals for each of
the six prototype profiles (96 total). This proves deterministic construction,
allowed-kind/channel constraints, and visible-horizon rules. It does not claim
96 physically clearable deals or a human clear rate.

`tests/prototype_stage_runtime_smoke_test.gd` loads all six generated stages and
admits a real first root with the expected queue token. The bounded physical
witness harness `tests/prototype_playable_witness_test.gd` cleared each current
default deal against real projectiles and the authoritative paint system:

| Stage | Seed | Terminal path | Score | Stars | Roots used |
| --- | ---: | --- | ---: | ---: | ---: |
| 01 | 1001 | manual Finish | 7.2984401028 | 1 | 2 |
| 02 | 1002 | manual Finish | 10.6355707068 | 3 | 2 |
| 03 | 1003 | manual Finish | 13.6226151825 | 1 | 5 |
| 04 | 1004 | manual Finish | 9.3878727546 | 1 | bounded harness |
| 05 | 1005 | timeout | 10.2154817629 | 1 | bounded harness |
| 06 | 1006 | timeout | 9.5044706260 | 3 | bounded harness |

These are implementation witnesses for the six shipped default deals, not the
deferred catalog-wide feasibility or human-study gate.

## Compact performance evidence

`compact-performance.json` records the single post-feature workload requested
by the active ExecPlan. On the native headless Compatibility runtime, Stage 06
launched six fixed representative roots: Red/Green Apex Split, Red/Green Impact
Burst, and Red/Green Standard. Both Apex roots split into three children.

- 239 fixed-physics ticks completed in 3.943 seconds, for a 16.48 ms sustained
  average interval; the headless callback p95 of 30.55 ms is retained only as
  host-scheduling diagnostics and is not rendered-frame evidence.
- resident peak was 8 of 21; restart left zero residents and changed the live
  object count by -1;
- 126 paint commands drained in 31 batches, wrote 10,709 pixels, and produced
  8.97% target coverage;
- 11 texture uploads published those 31 drains. This runtime exposes Godot's
  full-image `ImageTexture.update()` fallback, so the measured guardrail is the
  bounded ten-hertz batching cadence rather than a claimed regional GPU API;
- controller reset completed in 2.49 ms and the cleared texture was visible in
  38.63 ms, both below the one-second target.

This is a compact regression sentinel, not a long soak, foreground GPU frame
trace, or proof that every allowed deal is physically clearable.

## Local production artifacts

Fresh Godot 4.7.1 release exports completed after the functional and compact
performance gates:

- Windows: `PaintMountain.exe`, 120,919,184 bytes, SHA-256
  `DFFEB969FC0FA5653BADB831F9BBED897A127C3A9FD29B9CC4C59DB9C7AE01B0`;
- Web: 12 files, 50,749,780 raw bytes and 17,893,511 gzip-estimated bytes.
  `verify-web-release.ps1` passed exact-case references, required runtime
  files, the single-thread contract, and the 18,996,696-byte gzip allowance.

The exported Windows executable produced the three images in `release/`:

- `windows-stage-select-en-1280x720.png`;
- `windows-stage06-aiming-ko-1280x720.png`;
- `windows-apex-split-en-1600x900.png`.

Personal inspection found no clipping, overlap, missing localized text, stale
queue state, or special-ball silhouette defect. Chrome's enterprise policy
blocked automated navigation to `127.0.0.1`, so no local-browser Web interaction
is claimed. The approved fallback is an interactive smoke of the published itch
build; static release validation remains the local Web gate.
