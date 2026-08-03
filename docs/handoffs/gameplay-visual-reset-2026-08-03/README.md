---
type: handoff
status: active
created: 2026-08-03
last_reviewed: 2026-08-03
topic: Paint Mountain gameplay and visual reset
scope: read-only external design and architecture review
related:
  - ../../../AGENTS.md
  - ../../source-brief.md
  - ../../design-spec.md
  - ../../technical-architecture.md
  - ../../../.agents/Documentation.md
---

# Paint Mountain Gameplay and Visual Reset Handoff

## Purpose

This package gives Claude enough local evidence to produce a decisive,
implementation-ready correction guide for Paint Mountain. It is intentionally a
review package, not another claim that the current build is complete.

The requested review is read-only. Claude should inspect the files and images,
resolve the design contradictions described here, and return concrete guidance.
Claude must not edit the repository, launch Godot, or run the game.

## Snapshot

| Field | Value |
| --- | --- |
| Workspace | `D:\npjt\paint-mountain` |
| Branch | `master` |
| Implementation baseline | `15bac6405e79767df55552d0113dd906fb2a6c94` |
| Baseline worktree | Clean before this handoff package was added |
| Remote | None configured at package creation |
| Engine target | Godot 4.x, Compatibility renderer, fixed 60 Hz physics |
| First platform | Windows desktop |

The implementation baseline identifies the code Claude should review. The
handoff package itself is a later documentation-only commit.

## Authority Order

Use this order when evidence conflicts:

1. The newest explicit user corrections recorded in
   [current-state.md](current-state.md), especially the corrected paint behavior.
2. `docs/source-brief.md` for requirements that the user has not subsequently
   revised.
3. Root `AGENTS.md` for architecture and operating constraints.
4. The current code for what is actually implemented.
5. Derived plans, specifications, test checklists, and completion records only
   as historical or implementation evidence.

The current user correction deliberately overrides the source brief's finite
paint-payload behavior. Several derived documents have not yet been updated and
must not silently override that correction.

## Reading Order

1. Read this file.
2. Read [current-state.md](current-state.md) for the corrected product model and
   the observed failure.
3. Compare
   [visuals/01-target-reference.png](visuals/01-target-reference.png) with
   [visuals/02-current-build.png](visuals/02-current-build.png).
4. Use [source-map.md](source-map.md) to inspect the authoritative requirements,
   current implementation, and stale assumptions.
5. Read [constraints-and-decisions.md](constraints-and-decisions.md).
6. Follow [external-model-prompt.md](external-model-prompt.md) exactly.
7. Return the review in Markdown. A maintainer may paste the unedited response
   into [external-review-raw.md](external-review-raw.md) for later validation.

## Current State

The repository contains a working Godot vertical-slice structure, procedural
heightfield generation, rigid-body projectile code, a shared paint mask,
mechanism scenes, Korean translations, and componentized HUD scenes. Those facts
do not establish that the intended game has been achieved.

The latest running-build capture shows a visually flat, wall-like gray terrain,
an oversized foreground cannon, weak route readability, tiny or absent
mechanisms, and a UI composition far from the supplied target. The code also
models paint as a finite quantity deposited through spaced stamps, contrary to
the user's corrected rule that the ball continuously paints every target surface
area it traverses while in contact.

## Requested Result

Claude should return one coherent correction guide that makes the major design
and technical choices before implementation begins. It must include:

- a precise restatement of the game;
- a screenshot-backed gap analysis;
- a route-first procedural mountain algorithm;
- a continuous swept-contact paint algorithm with no payload depletion;
- render/collision/contact contracts;
- camera, art-direction, mechanism, and Korean-first HUD guidance;
- file-level ownership and migration recommendations;
- vertical implementation slices with objective stop/go gates;
- revised test and visual-evidence gates;
- explicit resolutions for contradictions and remaining assumptions.

Generic advice is not useful. Every recommendation should say what must change,
why, where it belongs, and how a reviewer can tell that it works.

## Next Steps

1. Give Claude access to the repository at the workspace path above.
2. Paste the English instruction from `external-model-prompt.md` into Claude.
3. Save Claude's unedited response in `external-review-raw.md` if a durable record
   is desired.
4. Validate every external recommendation against the repository before turning
   it into a replacement ExecPlan.
5. Update the stale product and technical documents before implementation so
   future work no longer treats paint depletion as authoritative.

## Risks

- Passing only the existing plan or test checklist will reproduce the wrong
  finite-payload model.
- Passing only the target image can encourage a visual reskin without repairing
  physics, topology, and paint semantics.
- Structural tests currently prove selected contracts, not that the running game
  looks or feels correct.
- The current screenshot shows symptoms, but a read-only review cannot prove
  every runtime collision path. Claude must distinguish code evidence from
  visually verified behavior.
- The package contains no credentials, user data, build outputs, `.godot` cache,
  local Codex settings, or unrelated logs. It is local-only because the
  repository has no configured remote.
