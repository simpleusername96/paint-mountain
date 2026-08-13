---
type: spec
status: active
created: 2026-08-13
canonical_for: Shared Propellant difficulty progression for Paint Mountain
scope: stage-level launch-power budgeting across the thirty-stage game
source: ../../docs/source-brief.md
related:
  - RESEARCH.md
  - DECISIONS.md
  - OPEN_QUESTIONS.md
  - TASKS.md
  - ../../.agents/execplans/2026-08-13-shared-propellant-progression.md
---

# Shared Propellant Difficulty Progression

## Purpose

Raise difficulty through one understandable stage-wide decision: every root
launch draws its selected power from a shared propellant budget.

## Scope

This spec owns propellant configuration, consumption, launch validity, minimal
HUD presentation, progression bands, and validation. It does not replace shot,
time, paint, coverage, or result rules.

## Player Rule

- Each stage starts with a fixed integer propellant budget.
- An accepted root launch consumes its selected `power_percent`.
- Splitter children and every other derived projectile consume no propellant.
- A launch whose selected power exceeds the remaining budget is rejected
  without consuming a shot.
- The player lowers power explicitly; the game never clamps it silently.
- Restart and stage entry restore the initial budget.
- Finish, timeout, coverage, clear, failure, and scoring remain unchanged.

## Progression

The budget is `maximum shots × band allowance`.

| Stages | Allowance per available shot | Intended decision |
| --- | ---: | --- |
| 01-06 | 100 | Learn the display with no effective restriction |
| 07-12 | 90 | Compensate for one or two full-power launches |
| 13-18 | 82 | Assign different jobs to launches |
| 19-24 | 75 | Reserve power for chain and recovery launches |
| 25-30 | 68 | Plan the complete allocation before committing |

These are initial authored values. Calibration may increase one band when
reachability evidence fails. Decreasing a band or changing the progression
shape requires a spec decision because it increases product difficulty.

## Requirements

### FR-1: Authoritative ownership

`StageData` stores immutable initial propellant. `StageController` owns the
remaining value, consumption, reset, and launch rejection. HUD code only
displays supplied state and reason.

### FR-2: Launch transaction

Validate propellant in the same authoritative root-launch transaction as shot
capacity. Consume propellant and a shot only after the launch is accepted. A
failed spawn or rejected request consumes neither.

### FR-3: Minimal presentation

Show one compact `화약 N` / `PROPELLANT N` value beside the existing shot
status. When the selected power is too high, use the existing disabled Fire
state and a short localized `화약 부족` / `NOT ENOUGH PROPELLANT` reason. Do
not add a large bar, panel, tutorial popup, result metric, or second primary
action.

### FR-4: Existing-system preservation

Preserve no in-flight steering, current power range, deterministic physics,
all-open stages, mechanism behavior, authoritative `PaintSystem` coverage,
current result score, save format, and existing target/shot/time values.

### FR-5: Solvability evidence

Every materialized stage must retain a reachable launch allocation within its
budget. Representative stages 01, 07, 13, 19, 25, and 30 must demonstrate at
least two materially different valid allocations in controlled playtests. A
material difference moves at least 15 propellant between two root launches.

## Acceptance Criteria

- Remaining propellant equals initial budget minus accepted root-launch power.
- Rejected launches and derived projectiles consume zero propellant.
- Propellant resets correctly on restart and stage transition.
- Fire validity updates immediately when aim power or remaining propellant
  changes, without silent clamping.
- Korean and English values and the shortage reason fit the existing HUD at
  1280x720, 1600x900, and 1920x1080.
- Existing coverage, mechanism, shot, timer, result, save, replay-facing action,
  and deterministic checks still pass.
- All thirty stages pass allocation reachability; the six representative
  stages pass the two-allocation playtest requirement.

## Non-Goals

- Resident-ball collision, simultaneous-shot timing challenges, aim locking,
  split target islands, adaptive budgets, upgrades, shops, random costs, or a
  second score.
- Automatic power reduction, solution hints, route labels, new physics forces,
  or a new mechanism.

## Related

- `DECISIONS.md` records the five fresh candidates and selection rationale.
- `docs/difficulty-progression.ko.md` is the user-facing Korean explanation.
