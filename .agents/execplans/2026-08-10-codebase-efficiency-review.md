---
type: plan
status: active
created: 2026-08-10
scope: read-only architecture, maintainability, failure-path, and measured runtime-efficiency review of the Godot codebase
related:
  - ../PLANS.md
  - ../Documentation.md
  - ../../docs/source-brief.md
  - ../../docs/technical-architecture.md
  - ../../docs/test-checklist.md
---

# Codebase Efficiency Review - Research Checklist

## Purpose

- Decision or research question: Which parts of the current Godot codebase have
  evidence-backed responsibility creep, competing ownership, avoidable
  coupling, duplicated work, reachable failure-path risk, or measured runtime
  inefficiency, and what is the smallest safe response to each finding?
- Why it matters: Paint Mountain has grown quickly across gameplay,
  stage-generation, delivery, UI, and test surfaces. Automated size and churn
  signals can prioritize review, but they cannot distinguish a cohesive owner
  from a catch-all or prove runtime cost.
- Decision owner: The audit executor reports evidence and recommended scope;
  the user decides whether to authorize any follow-up implementation.
- Final output: Create
  `.agents/evidence/2026-08-10-codebase-efficiency-review.md` with findings
  ordered by impact, exact file/symbol/consumer/test evidence, measured cost
  where applicable, a smallest-safe direction, and explicit clean areas. The
  review is read-only and does not authorize code changes.

## Observed Starting Point

- `docs/technical-architecture.md` defines narrow runtime owners, including
  `StageController` for stage state and results and `PaintSystem` for the sole
  mutable paint/coverage representation. Typed Resources own projectile, stage,
  mechanism, result, and generation tuning.
- Current size signals include
  `src/stage_generation/direct_reachability_validator.gd` (1,757 lines),
  `scripts/build_stage_catalog.gd` (1,214),
  `src/paint/paint_system.gd` (1,028),
  `src/delivery/delivery_capture_runner.gd` (977),
  `src/stage/stage_controller.gd` (828), and
  `src/camera/camera_director.gd` (771). Length is only a prioritization signal.
- Current Git-history churn signals include
  `src/gameplay/gameplay_scene.gd`, `src/stage/stage_controller.gd`,
  `src/ui/hud_controller.gd`, and `src/delivery/delivery_capture_runner.gd`.
  Churn is only a prioritization signal and may reflect legitimate integration
  ownership.
- The repository already provides `scripts/verify.ps1`, a dependency-free
  Godot smoke check, and
  `& .\scripts\test.ps1 -GodotPath 'D:\tools\Godot\4.7.1-stable\Godot_v4.7.1-stable_win64_console.exe'`,
  a broad test command. The shared Godot 4.7.1 console executable is the
  approved runtime.

## Scope and Evidence Contract

- In scope:
  - Production `.gd` and `.gdshader` code under `src/`, automation under
    `scripts/` and `tools/`, and their owning `.tscn`, `.tres`, project, export,
    translation, and typed-Resource contracts.
  - Tests as evidence of behavior, consumers, failure paths, determinism, and
    existing performance budgets.
  - Architecture and maintainability efficiency: responsibility creep,
    catch-all orchestration, competing owners, duplicated policy/validation,
    unnecessary coupling, stale compatibility paths, and avoidable repeated
    work.
  - Runtime efficiency only where a fixed, reproducible workload can measure
    CPU time, frame/tick work, allocations/memory, repeated scene/resource
    construction, or redundant queries.
- Out of scope:
  - Code, scene, resource, test, documentation, project-setting, or dependency
    changes during this checklist.
  - Product redesign, gameplay balance, UI redesign, naming-only rewrites,
    style-only formatting, and splitting cohesive files by line count.
  - New analyzers, plugins, packages, benchmark dependencies, network services,
    or changes to supply-chain safeguards.
  - Calling a theoretical micro-optimization a finding without a reachable
    production path and measured or mechanically unavoidable cost.
- Destructive or irreversible actions: None. The review may read the repository,
  run existing non-mutating checks, and write only its named evidence report.
- Approval required before: Any code or contract change, dependency or tool
  addition, broad benchmark/profiler run with material cost, player-facing
  behavior change, generated-catalog rewrite, or new Mode 3 implementation
  plan.
- Search budget or reassessment point: One repository-wide automated inventory
  and candidate ranking, followed by deep traces for at most the 12 highest
  combined ownership/churn/fan-in/runtime-risk candidates. Expand beyond 12
  only when a traced contract leads directly to another owner required to prove
  or disprove the same finding.
- Conflict-resolution rule: Current product authority and implemented behavior
  win over heuristic preferences. Preserve the ownership and invariants in
  root `AGENTS.md` and `docs/technical-architecture.md`; where code and docs
  disagree, report the contradiction rather than silently choosing a redesign.
- Stop rule for unproductive exploration: Stop a candidate trace when it is
  disproved, when the existing boundary is cohesive and tested, when no
  reachable consumer exists, or when the evidence contract is satisfied. Stop
  performance investigation when the existing deterministic workload shows no
  material regression or no safe controlled measurement exists; report the
  measurement gap instead of guessing.

| Evidence category | Primary source | Freshness requirement | What it must establish | Sufficient evidence |
| --- | --- | --- | --- | --- |
| Product and architecture ownership | Root/nearest `AGENTS.md`, `docs/source-brief.md`, `docs/technical-architecture.md`, `.agents/Documentation.md` | Current checkout | Intended owner, forbidden responsibility, invariant, and current implementation claim | Owner and non-owner are explicit, or all adjacent owners were inspected and the ambiguity is reported |
| Automated structural triage | Tracked source inventory, line counts, symbols, signal connections, scene/resource references, dependency fan-in/fan-out, duplicate-pattern searches | Same commit as the report | Which files warrant deep review and why | Ranked candidate record with at least one ownership, contract, or runtime-risk signal beyond length alone |
| Change-risk triage | Targeted Git history for current paths and recent consumers | Current branch history | Whether repeated change crosses responsibilities or repeatedly breaks the same contract | Current-path churn is tied to distinct change reasons; deleted historical paths are not treated as current debt |
| Contract and failure-path trace | Production owners, callers, signals, typed Resources, scenes, tests | Current checkout | Competing owners, compatibility impact, invalid/empty/partial/cancellation/long-running behavior | End-to-end reachable path and existing or missing guard are identified with exact symbols |
| Runtime efficiency | Existing deterministic tests, fixed stage/seed/workload, Godot timing/profiler output when proportionate | Shared Godot 4.7.1 and fixed 60 Hz settings | Repeatable cost and user- or pipeline-relevant impact | Baseline and repeated measurement use the same workload and isolate the suspected work; otherwise no performance finding |
| Validation boundary | `scripts/verify.ps1`, relevant focused tests, `scripts/test.ps1`, `docs/test-checklist.md` | Current checkout | What currently passes and what a later fix must protect | Smoke check plus only the focused checks needed by each finding; broad suite is reserved for a later approved implementation gate |

## Viable Options

Apply one option to each investigated candidate or finding.

| Option | Why materially viable | Decision criteria | Disqualifier |
| --- | --- | --- | --- |
| Clean; no action | Avoids churn when the owner is cohesive, contracts are clear, failure paths are guarded, and cost is acceptable | Deep trace disproves heuristic concern or existing tests/measurements establish the boundary | A material reachable defect or measured inefficiency remains |
| Local simplification | Removes duplication, stale branching, or repeated work inside the existing owner without changing public contracts | One owner, local invariant, bounded consumers, and focused acceptance check | Requires new ownership, schema/API change, or product decision |
| Responsibility extraction or redirection | Prevents a catch-all or competing owner while preserving behavior behind a named boundary | Concern changes for a distinct reason, has its own invariant/tests, or an existing owner should hide it | Extraction would be a pass-through split, line-count refactor, or new taxonomy without independent responsibility |
| Measured performance optimization | Reduces a reproducible cost in a reachable workload without weakening determinism or correctness | Fixed baseline, material cost, isolated cause, and parity guard exist | Claim rests on intuition, unstable timing, debug-only work, or changes game behavior |
| Separate architectural proposal | Contains cross-cutting debt that cannot be safely fixed as a small local change | Multiple contracts/owners or migration/compatibility decisions are required | A bounded local correction fully resolves the issue |
| Defer with named blocker | Preserves truth when measurement, authority, or a required consumer is unavailable | One exact missing evidence input or owner decision is recorded | General uncertainty after an incomplete trace |

## Tasks

### Phase 1: Establish current truth and automatic triage

- [ ] Record the commit and worktree state, then run `scripts/verify.ps1` from
  the repository root to establish import, parse, and startup health. Stop and
  report a baseline failure rather than attributing it to the review.
- [ ] Inventory production scripts, shaders, scenes, Resources, automation, and
  tests; collect size, symbol, dependency, signal, resource-loading, and current
  Git-churn signals without editing generated files.
- [ ] Map the explicit owners and forbidden responsibilities from the technical
  architecture to their current implementations and direct consumers.
- [ ] Rank candidates using combined signals. Seed the queue with the observed
  large and high-churn files above, but remove any candidate supported only by
  line count or churn.
- [ ] Select at most 12 deep-trace candidates and record why each could affect
  ownership, contract safety, repeated work, runtime cost, or validation.

Phase gate:

- The automated pass has produced a bounded, evidence-linked candidate queue;
  heuristics have not been reported as findings, and the baseline health is
  known.

### Phase 2: Trace responsibility, contracts, failures, and cost

- [ ] For each candidate, state its current responsibility, each distinct
  reason it changes, the suspected added responsibility or repeated work, and
  the nearest existing owner that could own or hide it.
- [ ] Trace direct and indirect consumers, typed signals, Resource/schema
  contracts, scene paths, test fixtures, and compatibility expectations before
  recommending any boundary change.
- [ ] Trace reachable invalid, empty, partial, cancellation, retry,
  long-running, import, and process-exit paths that apply to the candidate;
  record the exact guard or missing guard.
- [ ] Search for competing implementations of stage decisions, paint/coverage,
  projectile settlement, generation validation, UI formatting, persistence,
  capture/process control, and other rules only when the candidate reaches
  those concerns.
- [ ] For suspected runtime inefficiency, use an existing deterministic test or
  fixed stage/seed workload and repeat the same measurement enough to separate
  the signal from startup/import noise. If no controlled workload exists,
  record a measurement gap rather than create an unapproved benchmark.
- [ ] Run the smallest existing focused test that exercises each surviving
  finding. Do not run the broad `scripts/test.ps1` suite merely to regain
  confidence; reserve it for a later approved implementation gate unless a
  specific audit conclusion depends on suite-wide behavior.
- [ ] Apply `$codebase-quality-auditor` in read-only review mode to the surviving
  candidates and record findings by impact with exact evidence. Include clean
  candidates so the report does not imply that every heuristic signal was a
  defect.

Phase gate:

- Every reported finding has a reachable path, a named responsibility or cost,
  affected consumers, focused validation evidence, and a smallest-safe
  direction. Every rejected candidate has a concise disproof.

### Phase 3: Decide and record

- [ ] Separate observed fact, inference, measured result, recommendation, and
  user-owned implementation decision in the evidence report.
- [ ] Classify each surviving finding as clean/no action, local simplification,
  responsibility extraction, measured optimization, separate architecture
  proposal, or deferred with one named blocker.
- [ ] Order findings by impact and confidence, not file size. Include exact
  paths and symbols, affected contracts, suggested task boundary, acceptance
  check, and residual risk.
- [ ] Group only mutually coherent follow-up changes into proposed batches;
  keep unrelated cleanup, product changes, visual changes, and dependency work
  separate.
- [ ] If the user authorizes fixes, create one or more Mode 3 execution
  contracts from accepted batches. Do not edit this research checklist into an
  implementation plan and do not fix issues during the review.

Phase gate:

- The read-only audit is complete, clean areas and material findings are both
  explicit, and any follow-up work has a bounded proposed scope without implied
  authorization.

## Progress and Next Steps

- Canonical progress: the task checkboxes in this checklist.
- Current phase: Phase 1.
- Next task: Record the commit/worktree baseline and run the existing smoke
  verification.
- Last completed gate: Artifact scope, initial candidate signals, and evidence
  contract defined from the current repository.
- Update rule: Check an item only when its evidence exists. Do not repeat a
  passing check unless the relevant source, Resource, scene, test, Godot
  version, or workload changes.

## Verification

- Keep automated inventory output either summarized in the evidence report or
  in a bounded task-owned evidence attachment; do not commit verbose raw logs
  without a demonstrated future use.
- Cite current paths and symbols and verify them against the report's recorded
  commit before finalizing findings.
- Run `git diff --check` for the evidence-report change. The review must leave
  production code, scenes, Resources, tests, project settings, and dependencies
  unchanged.

## Risks

- Large, central files may be legitimate orchestration owners; line count and
  churn can only prioritize review.
- Godot scene/resource loading and signals can hide indirect consumers from a
  naive text-only graph.
- Debug, delivery, test, and generation code have different efficiency goals;
  do not apply frame-loop thresholds to offline tools or vice versa.
- Timing measurements can be dominated by import, startup, or shader work.
  Performance claims require a fixed warm workload and explicit limitations.
- Cross-cutting debt can be real but outside a small safe fix. Report it without
  expanding the audit into redesign.

## Completion and Stop Conditions

Complete when:

- The repository-wide automatic triage and the bounded deep traces are complete,
  or one exact unavailable source/runtime prerequisite is recorded as the
  blocker.
- Every reported finding meets the evidence contract, every selected candidate
  has a disposition, and unsupported heuristic signals have been removed.
- The named evidence report states material findings or a clean result, exact
  evidence, limitations, proposed follow-up batches, and any time-sensitive
  measurement that must be repeated after a relevant change.
- Production and test sources remain unchanged and `git diff --check` passes for
  the report.
- Frontmatter status changes to `done` after the decision or one specific
  blocker is recorded.

Escalate when:

- Code contradicts product or architecture authority and the established order
  does not determine whether the code or document should change.
- A finding requires a product, schema, dependency, compatibility, visual, or
  cross-owner decision.
- A controlled performance measurement would require a new tool, broad costly
  run, visible desktop impact, or other authority not already granted.

If implementation follows, invoke `$goal-checklist-builder` in Mode 3 and
`$codebase-quality-auditor` again after the task-owned changes. Also invoke
`$domain-language-alignment` only if the accepted findings expose real
terminology, invariant, lifecycle, or cross-module ownership pressure.
