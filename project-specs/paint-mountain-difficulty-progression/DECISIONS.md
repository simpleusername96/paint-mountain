---
type: record
status: active
created: 2026-08-13
scope: replacement difficulty-progression decision
related:
  - PRD.md
  - RESEARCH.md
  - research-context/exploration/02-comparison-and-selection.md
---

# Difficulty Progression Decision

## Context

The first Contrastive Risk-Route Ladder proposal was rejected as unclear. The
user requested a complete restart and exactly five new ideas.

## Decision

Select **Shared Propellant**. Every accepted root launch spends its selected
power from one stage budget. Progression reduces the average allowance per
available shot over five bands while retaining occasional full-power launches.

The rejected route-ladder proposal has no active product authority.

## Rationale

- The rule is explainable in one sentence and visible as one number.
- It deepens the existing power choice instead of adding a control.
- It creates planning across shots without adding in-flight steering.
- It composes with all current terrain and mechanisms.
- It has lower implementation and predictability risk than projectile
  collision or timing-centered alternatives.

## Consequences

- `StageController` gains one authoritative stage resource.
- Stage data gains one immutable budget value.
- The HUD gains one compact value and one conditional disabled reason.
- Every stage requires budget-aware reachability evidence.
- No implementation exists yet; the linked ExecPlan starts only on a later
  implementation request.

## Alternatives

1. **Resident Ball Bumpers:** use settled earlier projectiles as collision
   geometry for later shots. Rejected for physics variance and capacity risk.
2. **Two-Shot Relay:** coordinate two active root launches around mechanism
   cooldowns. Rejected because timing dexterity can dominate planning.
3. **Shared Propellant:** selected.
4. **Aim-Axis Lock:** freeze one aim parameter after the first launch. Rejected
   because it removes experimentation and can force restarts.
5. **Target Archipelago:** divide the target mask into separated visible
   regions. Retained as the strongest fallback, but it risks checklist-like
   play and greater target-readability work.
