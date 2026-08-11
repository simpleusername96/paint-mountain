---
type: plan
status: active
created: 2026-08-11
scope: remove the stage-selection readiness deadlock, prove the production transition, and publish the same revision to GitHub and itch.io
related:
  - ../PLANS.md
  - ../Documentation.md
  - ../../docs/source-brief.md
  - ../../docs/test-checklist.md
  - 2026-08-11-fast-stage-readiness.md
---

# Stage Selection Readiness and Deployment - Execution Contract

The release runtime can prepare and enter a stage in under one second, but selecting a different stage from Stage Select leaves the preparation request tied to the previously committed `GameState.selected_stage_id`. The requested artifact reaches the cache while hidden Gameplay is never installed, so Start can remain disabled indefinitely. This contract fixes that identity boundary without changing stage persistence, proves the actual selection-to-entry flow, and publishes the verified revision to GitHub and the existing itch.io HTML5 and Windows alpha channels.

## Purpose

- Objective: make every unlocked stage selected in Stage Select become ready and enter normally, with no stale-stage wait.
- Deliverable: an AppRoot request-identity correction, a focused regression test, production Windows/Web validation, a scoped commit and push, and a successful itch.io workflow upload.
- Completion state: the real Stage Select flow reaches the selected stage in at most 2 seconds in a fresh Windows release capture; all named gates pass; GitHub and both itch.io channels contain the same commit-derived version.

## Scope and Boundaries

In scope:

- AppRoot's orchestration of the currently requested stage while layout, runtime artifact, and hidden Gameplay preparation complete asynchronously.
- Regression coverage for selecting a stage that differs from the persisted current stage.
- Delivery telemetry/capture support needed to exercise the real transition.
- The existing GitHub branch and existing itch.io deployment workflow.

Out of scope:

- Stage geometry, gameplay, camera behavior, save schema, UI composition/copy, new dependencies, or itch.io visibility.
- Committing a stage choice before Start, or weakening the truthful Start readiness gate.
- Merging unrelated branches or changing deployment credentials/channels.

Constraints and invariants:

- `GameState.selected_stage_id` remains the committed selection and changes only through the existing entry flow.
- The latest user request owns preparation; obsolete asynchronous completion cannot install the wrong Gameplay.
- `StageController` and `PaintSystem` ownership does not change.
- itch.io remains Draft unless the user separately asks to change visibility.

Destructive or irreversible actions:

- Uploading replaces the latest build on the existing itch.io channels. Channel history remains available through itch.io/Butler.

Authorized external actions:

- The user explicitly requested a GitHub push and itch.io upload after validation.

## Discovery Closure

| Concern | Verified evidence | Locked decision | Task |
| --- | --- | --- | --- |
| Reported minute-long wait | Selecting Stage 02 after Stage 01 leaves `GameState` at Stage 01; Stage 02 artifact is cached but hidden Gameplay is absent after five seconds | Treat this as a readiness deadlock, not a terrain-generation regression | 1.1 |
| Direct entry speed | A release diagnostic entered Stage 30 in about 0.64 seconds in the same process | Preserve the optimized preparation pipeline | 1.1, 2.1 |
| Selection semantics | Stage Select owns an uncommitted local selection until Start | Add a separate requested-stage identity in AppRoot; do not write GameState early | 1.1 |
| Regression gap | Existing UI coverage changes cards but does not await the newly selected stage becoming Start-ready | Add a focused real-flow test and production capture | 1.2, 2.1 |
| itch.io delivery | `.github/workflows/itch-alpha.yml` already verifies and uploads Web plus Windows channels; its last master run succeeded | Dispatch this workflow on the pushed task branch and keep Draft visibility | 3.2 |

Readiness statement:

- Product behavior, ownership, compatibility, deployment targets, and acceptance thresholds are closed.
- No dependency, schema, asset, or irreversible visibility decision is required.

## Tasks

### Phase 1: Correct requested-stage ownership

- [x] **1.1** Track the latest requested stage independently from persisted GameState and use it to accept layout/artifact completion and prepare hidden Gameplay.
  - Accept: selecting Stage 02 while GameState still records Stage 01 produces matching prepared hidden Gameplay; stale completions cannot take ownership.
- [x] **1.2** Replace the temporary reproducer with an ordered regression test covering selection readiness, unchanged pre-Start persistence, and entry into the selected stage.
  - Accept: the test fails on the reproduced bug and passes after the fix within its bounded timeout.

### Phase 2: Verify production behavior

- [x] **2.1** Exercise the actual Stage Select selection-to-start route in the delivery runner and record fresh timing markers and a Korean release screenshot.
  - Accept: the selected stage becomes ready and visible within 2 seconds, with complete terrain/UI and no error state.
- [x] **2.2** Run focused tests, `scripts/verify.ps1`, the complete suite, Windows/Web release exports, and Web release validation.
  - Accept: all gates pass and the canonical fastrun Windows executable is the verified export.
- [x] **2.3** Update implemented-state and test evidence with the exact verified result.

### Phase 3: Publish the verified revision

- [ ] **3.1** Commit only task-owned files and push the current branch to GitHub; create or update a review link when repository permissions permit.
- [ ] **3.2** Dispatch the existing itch.io workflow with publishing enabled, wait for success, and confirm both HTML5 and Windows alpha channel uploads use the pushed revision.
  - Guard: do not change Draft/public visibility.

## Validation and Rework Controls

| Cadence | Check | Run when |
| --- | --- | --- |
| Inner loop | Focused stage-selection readiness test | AppRoot or test changes |
| Phase gate | `scripts/verify.ps1` | Source/scene/resource changes stabilize |
| Final gate | Complete suite, Windows/Web release exports, Web validator, rendered transition capture | Implementation and docs stabilize |
| Delivery gate | GitHub Actions itch workflow for the pushed SHA | All local gates pass and commit is pushed |

## Predetermined Contingencies

| Trigger | Response |
| --- | --- |
| A stale request can still install Gameplay | Correct AppRoot identity guards; do not serialize preparation or update GameState early |
| Release transition exceeds 2 seconds | Use delivery markers to isolate the owner and replan only if the cause lies outside request identity |
| GitHub token cannot create a PR | Push the branch, provide a compare URL, and continue the already-authorized workflow dispatch |
| itch workflow fails | Inspect the failing job, fix only task-owned delivery issues, rerun validation, and publish a new scoped commit |

## Progress

- Current phase: Phase 3.
- Next task: 3.1.
- Evidence so far: the focused regression passes; the full suite, verification,
  Windows/Web exports, and Web validator pass. A real Windows release Stage
  01→30 selection reaches Start-ready in 679.278 ms and visible Briefing in
  695.411 ms. Local Chrome selects and enters Stage 02 without console errors.

## Completion and Stop Conditions

Complete when every task above passes, the plan status is `done`, the scoped commit is on GitHub, and the existing itch.io workflow reports successful HTML5 and Windows alpha uploads for the same revision.

Stop and ask only if deployment requires new credentials/permissions or changing itch.io visibility.
