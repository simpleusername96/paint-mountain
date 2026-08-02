---
type: policy
status: active
created: 2026-08-02
scope: implementation sessions following the active Paint Mountain plan
---

# Implementation Workflow

## Purpose

Keep implementation aligned with the accepted game loop and make handoffs reflect tested reality.

## Scope

Applies when executing `.agents/Plan.md` or another user-approved implementation task.

## Rules

- Read root `AGENTS.md`, `Prompt.md`, `Documentation.md`, and the relevant sections of the design and architecture specs first.
- Implement one user-testable milestone at a time and keep the project launchable after each milestone.
- Update `Documentation.md` after meaningful milestones with exact completed behavior, validation, risks, and the next executable step.
- Validate narrowly during implementation and run `scripts/verify.ps1` before handoff.
- Never infer completion from the presence of a scene, node, button, or document; run the behavior and record the evidence.
- Keep task-owned changes isolated and do not reorganize unrelated files.

## Exceptions

- Documentation-only corrections may use `git diff --check` when no Godot behavior or project metadata changed.
