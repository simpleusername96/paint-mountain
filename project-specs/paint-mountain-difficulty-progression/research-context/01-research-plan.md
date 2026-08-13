---
type: plan
status: done
created: 2026-08-13
scope: bounded research for Paint Mountain difficulty selection
related:
  - 00-intake.md
  - 02-synthesis.md
---

# Research Plan: Paint Mountain Difficulty Progression

## Purpose

Gather only the evidence that can change the candidate search, selection, or
implementation boundaries.

## Scope

- In scope: current local difficulty controls and telemetry; direct game
  precedents; distant structural analogues; anti-patterns; implementation and
  validation boundaries.
- Out of scope: implementing code, adding dependencies, all-stage manual clears,
  exhaustive game-history surveys, and claims of fun without player evidence.
- Destructive or irreversible actions: none.
- Approval required before: any production dependency, new online collection,
  or change to the effective source brief.
- Search budget: three bounded explorer assignments, local primary sources, and
  up to twelve additional directly inspected external primary or authoritative
  sources when they resolve a decision-changing gap.
- Conflict-resolution rule: the effective source brief wins local product
  conflicts; implemented truth comes from code, resources, tests, and
  `.agents/Documentation.md`; external evidence may guide but cannot override
  user requirements.
- Stop rule: stop when every must dependency is supported or visibly unresolved,
  the common-answer map is stable, and new sources repeat mechanisms rather
  than opening a decision-relevant family.

## Decision-Relevant Dependencies

| ID | Priority | Question | What it can change | Evidence lane | Status | Stop condition |
| --- | --- | --- | --- | --- | --- | --- |
| M1 | must | What difficulty levers, observations, persistence, owners, and tests exist now? | Feasibility, ownership, plan surface | Local truth | supported | Exact owners and negative adaptive evidence recorded in `research/01-local-product-truth.md` |
| M2 | must | Which progression mechanisms recur in similar deterministic aiming/physics games? | Common-answer baseline and precedent limits | Direct precedents | supported | Four-plus families and their limits recorded in `research/02-direct-precedents.md` |
| M3 | must | Which distant fields contain transferable structures for progressive challenge and learning? | New search regions | Distant analogues | supported | Education, psychometrics, aviation, sport, surgery, ecology, and safety recorded in `research/03-distant-analogues.md` |
| M4 | must | Which approaches create opacity, frustration, invalid comparison, or maintenance cost? | Disqualifiers and contingencies | Counterevidence | supported | Every candidate has a first failure condition; one fails a hard gate |
| S1 | should | Which observable measures can validate learning and difficulty without a large telemetry system? | Acceptance criteria | Research and local observation contracts | supported | Structural metrics plus current local attempt/shot observations selected |
| S2 | should | What UI feedback is necessary to explain the selected challenge without adding clutter? | Presentation scope | Design specs and rendered evidence | supported | One Stage Select focus label; normal gameplay and result surfaces unchanged |

## Evidence Categories

| Evidence category | Preferred source | Freshness requirement | What it must establish | Sufficient evidence |
| --- | --- | --- | --- | --- |
| Current product truth | Effective brief, active specs, code, Resources, tests, implementation record | Current repository | Existing contracts and owners | Exact path, symbol, and behavior agree |
| Direct precedents | Official manuals/pages, developer talks, primary postmortems | Current access; historical facts may be older | Mechanism and boundary, not popularity | At least one direct source per structural family |
| Learning/assessment | Primary research, standards, authoritative institutional guidance | Current or still-canonical | Transferable causal structure and failure condition | Claim, setting, mechanism, and limitation are traceable |
| Distant practice | Governing body, training standard, first-party method, or primary study | Appropriate to claim | Non-game challenge structure | At least five distinct domains, no surface copying |
| Counterevidence | Primary studies, postmortems, standards, or direct local constraints | Appropriate to claim | When a mechanism fails or misleads | Named condition that changes candidate eligibility or plan |

## Planned Baseline Work

- Inspect current thirty-stage formulas, baked stage/profile data, stage state,
  observations, saves, stage-select/result surfaces, and focused tests.
- Map common game answers such as numeric tightening, geometry growth,
  information removal, mechanic stacking, and adaptive scaling.
- Search disconfirming evidence for time pressure, punitive randomness,
  opaque adaptation, extraneous cognitive load, and performance-only scoring.

## Resource Boundaries

- Depth: standard, because precedent, learning, architecture, and player-facing
  tradeoffs interact but the output is reversible planning.
- Access/cost: public sources and current repository only; no paid reports,
  interviews, live player recruitment, or new tooling.
- Expansion triggers: a material candidate depends on a claim not supported by
  the bounded source set, or direct and distant evidence conflict on a selection
  criterion.
- Explicit exclusions: monetization, competitive matchmaking, network
  telemetry, generative level creation at runtime, and new content packs.

## Tasks

- [x] Establish current local truth and architectural boundaries.
- [x] Gather direct precedent mechanisms and limits.
- [x] Gather distant analogue mechanisms and breakpoints.
- [x] Record counterevidence and anti-patterns.
- [x] Synthesize the evidence without selecting a candidate.
- [x] Mark this plan done when all must dependencies reach a disposition.

## Progress

- Current phase: complete.
- Evidence: three research notes, one neutral synthesis, a twelve-candidate
  ledger, and one comparison/selection record.

## Next Steps

- None; selection and execution planning moved to the active PRD and ExecPlan.

## Completion and Stop Conditions

- Complete when every must dependency is supported or explicitly unresolved,
  sources and limitations are traceable, and further research has lower expected
  decision value than cumulative candidate exploration.
- Stop and revise the contract if a source-brief conflict or implementation
  authority gap changes the allowed outcome.
