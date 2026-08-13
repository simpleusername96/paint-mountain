---
type: plan
status: active
created: 2026-08-13
scope: implement and validate Shared Propellant across thirty stages
supersedes: 2026-08-13-contrastive-risk-route-ladder.md
related:
  - ../PLANS.md
  - ../../docs/source-brief.md
  - ../../docs/design-spec.md
  - ../../docs/technical-architecture.md
  - ../design/DESIGN.md
  - ../design/UIUX_GUIDELINES.md
  - ../../project-specs/paint-mountain-difficulty-progression/PRD.md
  - ../../project-specs/paint-mountain-difficulty-progression/DECISIONS.md
---

# Shared Propellant Progression — Execution Contract

## Purpose

Implement a stage-wide propellant budget in which every accepted root launch
spends its selected power. The result must turn power into a multi-shot planning
resource without changing projectile physics, in-flight control, coverage, or
result scoring.

## Scope

In scope:

- Typed initial propellant in stage configuration.
- Authoritative remaining propellant, reset, and launch validation.
- Atomic shot and propellant consumption for accepted root launches.
- One compact localized HUD value and one conditional shortage reason.
- Initial five-band budgets for all thirty stages.
- Focused contracts, allocation reachability, rendered checks, representative
  playtests, release checks, and durable documentation.

Out of scope:

- New physics, projectile-projectile collision, timing objectives, aim locks,
  target-mask redesign, adaptive budgets, upgrades, shops, random costs, new
  mechanisms, save progression, telemetry, or a second score.
- Automatic power clamping, route hints, tutorial popups, HUD redesign, or
  changes to current target, shot, time, star, and mechanism-introduction tiers.

## Verified Context and Locked Decisions

| Concern | Current evidence | Locked decision |
| --- | --- | --- |
| Rule owner | `StageController` owns stage state and shot progression | It owns remaining propellant and root-launch acceptance |
| Configuration | Typed stage Resources own tuning | Add one non-negative integer initial budget to typed stage data |
| Power | Cannon exposes authoritative 0-100 power | Charge the exact accepted integer power; do not duplicate conversion |
| Derived balls | Splitter creates child projectiles | Charge accepted root launches only; children are free |
| Paint/result | `PaintSystem` owns one coverage mask | Do not change paint, coverage, clear, failure, or score |
| HUD | Quiet Context uses compact edge status | Add one value beside shots and one conditional disabled reason |
| Persistence | Budget is per-run stage state | Do not change the save schema |
| Progression | Maximum shots already vary by stage | Initial budget is max shots × 100/90/82/75/68 by six-stage band |

The five initial band allowances are product configuration. Implementation may
increase a band or an exact stage after evidence proves infeasibility and must
record the adjustment. It may not reduce a budget or introduce a new difficulty
axis without revising the PRD.

## Architecture Ownership

| Owner | Change | Must not absorb |
| --- | --- | --- |
| Existing typed stage data Resource | Immutable `initial_propellant` with validation | Mutable remaining value or HUD formatting |
| `StageProgressionData` / catalog materialization owner | Derive and persist the exact thirty initial budgets | Runtime consumption or fallback repair |
| `StageController` | Remaining value, reset, launch eligibility, atomic consumption, and typed state/reason signals | Aim calculation, paint, or UI layout |
| Existing cannon/action boundary | Supply the authoritative selected power with the root-launch request | Budget state or automatic clamping |
| `HUDController` and existing shot-status component | Display supplied remaining value and shortage reason | Budget calculation or launch approval |
| Translation CSV | Korean/English value label and shortage reason | Gameplay rules |

No large catch-all file should absorb the feature. If the existing launch
transaction cannot preserve atomic shot and propellant consumption through its
narrow interface, extend that interface rather than duplicating validation in
the cannon or HUD.

## Tasks

### Phase 1 — Establish the rule contract

- [ ] **1.1** Add `initial_propellant` to the existing typed stage configuration,
  validate it as non-negative, and materialize the thirty values from the five
  progression bands.
  - Accept: every stage hydrates the expected integer; no save field changes.
- [ ] **1.2** Add remaining propellant to `StageController` run state and reset
  it on stage start/restart through the same lifecycle as shots and time.
  - Accept: repeated restart and stage transition cannot retain prior spend.
- [ ] **1.3** Extend the narrow root-launch request/result contract so selected
  power is validated before spawn and both shot and propellant are consumed only
  after acceptance.
  - Accept: insufficient budget, active-root capacity rejection, invalid aim,
  and failed spawn consume neither resource; an accepted launch consumes one
  shot and exactly its power.
- [ ] **1.4** Prove Splitter children and every derived projectile bypass the
  root cost path.
  - Accept: one root that splits still incurs exactly one charge.

### Phase 2 — Present the decision without a HUD redesign

- [ ] **2.1** Extend the existing authoritative HUD view model/signals with
  remaining propellant and the insufficient-propellant reason.
- [ ] **2.2** Add compact `화약 N` / `PROPELLANT N` beside shot status and use
  the existing Fire disabled presentation for `화약 부족` /
  `NOT ENOUGH PROPELLANT`.
  - Accept: no new panel, bar, popup, result metric, or duplicated rule exists.
- [ ] **2.3** Check normal, exact-budget, insufficient, restart, observation,
  Finish-available, timeout, Korean, and English states.
  - Accept: no clipping or overlap at 1280x720, 1600x900, and 1920x1080; Fire
  remains the sole primary action and the mountain remains visually dominant.

### Phase 3 — Validate thirty-stage feasibility

- [ ] **3.1** Add deterministic tests for exact stage budgets, rejection,
  consumption, resets, root/child distinction, and unchanged shot behavior.
- [ ] **3.2** Add or extend an offline allocation/reachability check using the
  existing trajectory and stage evidence path. It may validate witnesses but
  must not become a runtime solver or expose solutions to the player.
  - Accept: 30/30 stages have at least one budget-valid reachable allocation.
- [ ] **3.3** Playtest Stages 01, 07, 13, 19, 25, and 30 with two allocations
  differing by at least 15 propellant between two root launches. Record launch
  powers, first contacts, mechanism events, coverage gains, and failure causes.
  - Accept: each representative stage has two credible allocation strategies;
  Stage 01 feels unchanged apart from the value display.
- [ ] **3.4** If evidence fails, increase only the affected stage or band budget,
  rerun the affected focused checks, and record the final value and reason.

### Phase 4 — Production validation and durable truth

- [ ] **4.1** Run `scripts/verify.ps1` after source, Resource, scene, and
  translation changes stabilize.
- [ ] **4.2** Before the broad final gate, explain its complete-suite, Windows
  and Web export, and capture cost and obtain the alignment required by repo
  policy. Then run it once and stop on the first material shared failure.
- [ ] **4.3** Use the task-owned background capture path for the six
  representative stages, inspect the actual running game, and record separate
  Korean and English fit evidence.
- [ ] **4.4** Run `$codebase-quality-auditor` because the implementation crosses
  shared stage data, controller, action, HUD, catalog, and test boundaries. Fix
  only small task-owned defects and rerun affected checks.
- [ ] **4.5** Update `docs/design-spec.md`, `docs/technical-architecture.md`,
  `.agents/design/UIUX_GUIDELINES.md`, `.agents/Documentation.md`, and
  `docs/test-checklist.md` with implemented truth and evidence. Do not edit the
  source brief unless the user explicitly revises it.
- [ ] **4.6** Commit only task-owned implementation and evidence, then mark this
  plan `done` only when all acceptance checks pass.

## Acceptance Checks

- `remaining = initial - sum(accepted root launch power)` for every run.
- All rejection paths and all derived projectile paths consume zero.
- Shot and propellant consumption remain atomic.
- Restart and stage transition restore the exact configured value.
- Fire validity reacts immediately to selected power and remaining value with
  no silent aim mutation.
- Existing deterministic physics, mechanisms, paint, coverage, result, save,
  and all-open stage contracts remain green.
- All thirty stages have feasibility evidence; the six representative stages
  have two materially different allocations.
- Required running-game captures show stable Korean/English fit and hierarchy.

## Validation Commands

Focused command names may follow existing test naming after owner inspection;
do not invent a parallel test harness. Expected forms:

```powershell
& $env:GODOT_BIN --headless --path . --script res://tests/stage_propellant_test.gd
& $env:GODOT_BIN --headless --path . --script res://tests/stage30_progression_test.gd
& $env:GODOT_BIN --headless --path . --script res://tests/localization_ui_test.gd
pwsh -NoProfile -File scripts/verify.ps1 -GodotPath $env:GODOT_BIN
```

Final production checks, after the required user alignment:

```powershell
pwsh -NoProfile -File scripts/test.ps1 -GodotPath $env:GODOT_BIN
& $env:GODOT_BIN --headless --path . --export-release 'Windows Desktop' 'builds/windows/PaintMountain.exe'
& $env:GODOT_BIN --headless --path . --export-release 'Web' 'builds/web/index.html'
pwsh -NoProfile -File scripts/verify-web-release.ps1 -ReleaseDirectory builds/web
```

## Regression Guards

- `StageController` remains the only owner of stage progression and launch
  resource consumption; `PaintSystem` remains the only paint/coverage owner.
- No second power conversion, second coverage representation, or UI-owned rule.
- No change to projectile collision layers, forces, mechanism tuning, current
  shot/time/target tiers, save version, stage locks, or result formula.
- No passive instruction card, budget bar, new menu, or route hint.
- No runtime solver or allocation telemetry.

## Predetermined Contingencies

| Trigger | Response |
| --- | --- |
| A stage has no reachable allocation | Increase that stage or its band budget and record why; do not weaken physics or target rules |
| Splitter is charged more than once | Move charging back to the accepted root-launch boundary; never special-case the HUD |
| A rejected spawn spends a resource | Make the launch transaction atomic before continuing |
| HUD text clips or obscures the world | Shorten localized copy or adjust the existing status group; do not add a panel |
| Save migration appears necessary | Stop; propellant is per-run configuration and must not enter the save schema |
| The mechanic remains unclear in playtest | First revise the compact value label and early no-pressure introduction; do not add tutorial prose without a new UI decision |

## Progress

- Discovery and product selection are complete.
- The prior route-ladder plan is superseded.
- No implementation task has started.

## Next Steps

- Begin Phase 1.1 only after the user requests implementation.

## Stop Conditions

Stop and ask before a new dependency, service, save migration, source-brief
change, destructive catalog operation, deployment, new player-facing system, or
weakened deterministic/paint safeguard. Mark complete only after every task and
acceptance check passes and task-owned changes are committed.
