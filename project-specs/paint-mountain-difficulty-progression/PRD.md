---
type: spec
status: active
created: 2026-08-13
scope: Paint Mountain difficulty progression
source: ../../docs/source-brief.md
related:
  - RESEARCH.md
  - DECISIONS.md
  - OPEN_QUESTIONS.md
  - TASKS.md
  - ../../.agents/execplans/2026-08-13-contrastive-risk-route-ladder.md
---

# Paint Mountain Difficulty Progression

## Summary

Use a **Contrastive Risk-Route Ladder** to make the existing thirty stages
progressively harder. The ladder teaches one planning invariant at a time,
varies it through contrast and transfer, and then combines it with earlier
skills. Advanced stages expose readable robust and high-leverage route
opportunities without prescribing a solution.

## Purpose

Define the selected player-learning and content-authoring contract for raising
difficulty across the current thirty-stage game.

## Problem Statement

The current build increases many values at once and verifies one weighted
monotonic difficulty score. That proves ordering, but it does not tell the
player or content author which planning skill changed. Later stages need to
demand stronger route hypotheses and transfer of learned terrain behavior,
instead of relying only on higher coverage, more terrain, more mechanisms,
time pressure, or narrower tolerances.

## Target User

- Primary user: a player who enjoys deliberate spatial planning and rapid retry.
- Context: a short single-player stage played with a fixed cannon and
  deterministic physics.
- Motivation: learn from visible cause and effect, then make a better launch.

## Job To Be Done

When a stage becomes harder, the player wants to understand which planning
skill is being tested, so they can improve through intentional experiments
rather than trial-and-error guessing.

## Goals

- Create a readable thirty-stage learning curve using current terrain, aim,
  paint, route, and mechanism contracts.
- Make the changed planning demand visible in stage geometry.
- Define structural, rendered, and playtest acceptance criteria.

## Non-Goals

- Add post-fire steering, new projectile or cannon collections, a fourth
  mechanism, upgrades, currencies, locked stages, or online systems.
- Treat a higher timer, target, terrain size, or mechanism count as sufficient
  evidence of better difficulty.
- Add adaptive difficulty, challenge modifiers, mastery badges, a second score,
  a runtime solver, route arrows, or prescribed solution hints.

## Scope

This specification covers immutable challenge identity, authored stage and
route structure, one compact Stage Select label, and the validation needed to
promote a new complete catalog. It does not authorize a new runtime rule,
progression system, persistence format, or service.

## User Flows

### Flow 1

- Trigger: the player chooses any stage from the all-open Stage Select.
- Main steps: inspect the short challenge focus, inspect terrain, form a route
  hypothesis, aim, fire, observe, and revise.
- Expected outcome: later stages require more deliberate route comparison while
  preserving the same readable loop.

### Flow 2

- Trigger: the player finishes or times out a run.
- Main steps: read the truthful coverage result and decide whether to retry or
  choose another stage.
- Expected outcome: the result stays coverage-based; learning comes from the
  visible route outcome and existing shot observations, not a new score.

## Requirements

### FR-1

- Requirement: divide the ordered thirty-stage catalog into five six-stage
  bands with these focus areas:
  1. Stages 01-06 — Contact and Descent.
  2. Stages 07-12 — Route Choice.
  3. Stages 13-18 — Reversal and Recovery.
  4. Stages 19-24 — Mechanism Chains.
  5. Stages 25-30 — Fusion and Robustness.
- Reason: five bands fit the existing six-stage mechanism tiers and provide
  enough repetition for contrast and transfer.

### FR-2

- Requirement: every band uses the ordered lesson roles Anchor, Contrast A,
  Contrast B, Transfer, Interleave, and Fusion exactly once.
- Reason: establish an invariant before varying and combining it.

### FR-3

- Requirement: every stage has a typed challenge profile containing its band,
  lesson role, localized focus key, primary challenge axis, earlier reference
  stage where applicable, and at least two explicitly held axes for Contrast A,
  Contrast B, and Transfer.
- Reason: make the authoring intention testable without treating one weighted
  scalar as the definition of difficulty.

### FR-4

- Requirement: the comparison contract derives challenge facts from the actual
  `StageData`, `StageGenerationProfile`, and `StageRouteProfile`. It must cover
  paint-distribution mechanism set, route count and endpoint span, minimum route
  width, maximum reversal count, maximum ordered mechanism slots on one route,
  and target coverage per available shot. It must not store a second geometry
  or coverage truth.
- Reason: contrast must be checked against the content the game will load.

### FR-5

- Requirement: the Interleave and Fusion stages in Bands 2-5 (Stages 11, 12,
  17, 18, 23, 24, 29, and 30) contain both a `SAFE` route and a non-`SAFE`
  challenge route. The safe route is at least 4 m wider. The challenge route has
  at least one additional mechanism slot or one additional grade reversal.
- Reason: create a visible robust-versus-high-leverage planning decision.
- Boundary: these are structural opportunities, not solver-certified clear
  routes. The game must not save or show a prescribed solution.

### FR-6

- Requirement: retain the existing target, shot, duration, canonical-seed,
  authoritative-paint, all-open, and three-mechanism contracts. Retain Stage 01
  with no mechanism, Stage 02 as the first Burst example, Stage 03 as the
  three-route Splitter example, and Stage 08 as the first Uphill Rebound
  example.
- Reason: the new ladder reorganizes difficulty; it does not replace the core
  game or invalidate established learning landmarks.

### FR-7

- Requirement: Stage Select shows one localized two-to-four-word challenge
  focus label for the selected stage. Cards, gameplay HUD, result scoring, and
  saved progression remain unchanged.
- Reason: the stage identity needs a compact explanation, while geometry remains
  the main teaching surface.

### FR-8

- Requirement: use existing in-memory `ShotObservation` and
  `AttemptObservation` facts for local balance evidence. Do not add network
  telemetry, an attempt-history save schema, or a player-skill estimate.
- Reason: current diagnostics can support representative playtests without
  creating an unsupported adaptive system.

## Acceptance Criteria

### AC-1

- Applies to: catalog structure.
- Conditions for done: the active catalog contains thirty ordered stages and
  exactly five consecutive bands, each with all six lesson roles in order.

### AC-2

- Applies to: contrast contracts.
- Conditions for done: every Contrast A, Contrast B, and Transfer profile points
  to an earlier valid reference, changes its declared primary axis, preserves at
  least two declared held axes under axis-specific comparison rules, and passes
  catalog validation.

### AC-3

- Applies to: route tradeoffs.
- Conditions for done: Stages 11, 12, 17, 18, 23, 24, 29, and 30 satisfy the
  typed `SAFE`/challenge route width and leverage rules from FR-5 in the
  materialized profiles and baked layouts.

### AC-4

- Applies to: regressions.
- Conditions for done: the early mechanism examples, current target/shot/time
  tiers, canonical seed, all-open catalog, paint authority, deterministic
  prediction/runtime parity, save compatibility, and quiet gameplay HUD remain
  covered by passing tests.

### AC-5

- Applies to: presentation.
- Conditions for done: Korean and English Stage Select show the focus label
  without clipping at 1280x720, 1600x900, and 1920x1080; the normal gameplay HUD
  and result panel contain no new difficulty prose or score.

### AC-6

- Applies to: running-game readability.
- Conditions for done: Windows release captures and the fixed playtest protocol
  cover Stages 01, 06, 12, 18, 24, and 30. For each failed representative
  attempt, the tester records a specific visible cause and a specific next-shot
  change. For Stages 12, 18, 24, and 30, the tester can identify the broad route
  and high-leverage route before firing without route overlays.

### AC-7

- Applies to: production readiness.
- Conditions for done: focused tests, `scripts/verify.ps1`, the complete test
  suite, Windows and Web release exports, Web validation, and task-owned
  running-game captures pass after one promoted versioned catalog build.

## Constraints

- Preserve the effective `docs/source-brief.md` and its later supersessions.
- Preserve the fixed-cannon, no-steering, authoritative-paint, timed-Finish,
  all-open thirty-stage loop.
- Use existing Godot 4.x architecture and typed Resources; add no production
  dependency, plugin, backend, or asset pack.
- Keep `StageController` as the sole stage state and result owner and
  `PaintSystem` as the sole mutable paint/coverage owner.

## Dependencies

- Current stage generation, `StageData`, catalog, `StageController`,
  `PaintSystem`, observations, `GameState`/`SaveSystem`, and Stage Select owners.
- Offline catalog generation and enough CPU/storage time to rebuild and verify
  one complete thirty-stage versioned bundle.

## Risks

- Difficulty may become opaque, punitive, or visually noisy.
- A contrast pair may vary too many secondary axes to teach its intended
  invariant.
- A structurally valid safe/challenge route pair may not be legible from the
  running camera or meaningful under real projectile physics.
- Complete catalog regeneration can expose unrelated geometric admission
  failures; promotion must remain all-or-nothing.

## Success Metrics

- 30/30 stages have valid band and lesson-role metadata.
- 15/15 Contrast A, Contrast B, and Transfer stages pass their declared
  primary/held-axis comparisons.
- 8/8 required advanced route-pair stages pass structural route validation.
- 6/6 representative release stages pass the diagnosis protocol; 4/4 advanced
  representatives expose the two route opportunities before launch.
- 0 new gameplay controls, mechanisms, score authorities, locked stages,
  network calls, or persisted skill/adaptation fields.

## Rollout or Validation Plan

- Follow `.agents/execplans/2026-08-13-contrastive-risk-route-ladder.md`.
- Build and validate challenge metadata before regenerating terrain.
- Dry-build the complete versioned catalog, inspect representative grayboxes,
  then promote exactly one complete bundle.
- Validate focused contracts during implementation and run broad production
  gates once after content and UI stabilize.

## Open Questions Summary

- No blocking product question remains. `OPEN_QUESTIONS.md` records bounded
  calibration questions and their predetermined disposition.
