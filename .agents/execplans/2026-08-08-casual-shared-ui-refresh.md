---
type: plan
status: done
created: 2026-08-08
scope: shared casual UI refresh, licensed UI textures, rendered evidence, and exploratory screen concepts
related:
  - ../../docs/source-brief.md
  - ../design/UIUX_GUIDELINES.md
  - ../../resources/ui/paint_mountain_theme.tres
  - ../../docs/experience-audit-2026-08-08.html
---

# Casual Shared UI Refresh - Execution Contract

Replace the visibly cramped, oversized, and weakly detailed menu and gameplay UI with a casual shared component system, prove the result in the exported game, and record three distinct visual directions across the three primary screens without changing gameplay rules.

## Purpose

- Objective: make Main Menu, Stage Select, and Aim View simple, tactile, readable, and non-obstructive at the 1280x720 desktop baseline.
- Deliverable: updated shared Theme and component scenes, a narrow CC0 Kenney texture subset with provenance, inspected release captures, and a nine-image concept gallery.
- Completion state: all tasks and gates pass, evidence is recorded, and this plan is marked `done`.

## Scope and Boundaries

In scope:

- Shared Theme button, panel, focus, type, spacing, and selected-state roles.
- Main Menu, Stage Select, and Aim View hierarchy and component geometry.
- Existing functional Pause, Settings, result, and briefing surfaces only where the shared Theme changes them automatically.
- Kenney UI Pack 2.0 CC0 textures selected from the official archive.
- Runtime snapshots and ImageGen concepts for Main Menu, Stage Select, and Aim View.

Out of scope:

- Terrain, camera, ballistics, target solving, coverage, stage rules, save/replay schemas, or new gameplay actions.
- New production dependencies, plugins, fonts, asset packs, networking, or deployment.
- Implementing a generated concept before the user selects it.

Constraints and invariants:

- `resources/ui/paint_mountain_theme.tres` remains the single reusable visual-token owner.
- Existing component scenes remain the state-display and intent boundaries; HUD components do not acquire gameplay logic.
- Fire remains the sole Aim View primary action; Gear/Escape, Finish, Aim/Map, and Shot Follow retain their real behavior.
- Korean and English text, keyboard focus, and 40 px minimum control targets remain supported.
- The user-owned `tests/target_mask_test.gd` change and unrelated untracked evidence remain untouched.

Destructive or irreversible actions:

- None. Imported textures and UI changes are ordinary version-controlled files.

Exact actions requiring owner or user approval:

- None. The user explicitly authorized external UI panel assets; the selected pack is CC0 and adds no executable dependency.

## Discovery Closure

| Requirement or concern | Verified current owner and behavior | Evidence | Locked decision | Task IDs |
| --- | --- | --- | --- | --- |
| Shared components | Theme owns visual roles; scenes own reusable HUD and screen structure | `resources/ui/paint_mountain_theme.tres`, `scenes/ui/**` | Extend Theme variations and existing component scenes; do not add script-local StyleBoxes | 1.2, 2.1, 2.2 |
| Main Menu blank card | Subtitle uses `size_flags_vertical = 3` inside a 624 px tall fixed panel | `scenes/ui/screens/main_menu.tscn`, current 1280x720 capture | Use a shorter anchored content card with explicit text rhythm and no filler expansion | 2.1 |
| Stage Select imbalance | Cards occupy one left panel while preview floats only in the lower-right | `scenes/ui/screens/stage_select.tscn`, current capture | Use two balanced full-height surfaces and eight larger cards per page | 2.1 |
| Aim control clipping | Component minimum width is 336 px but instance width is 280 px | `scenes/ui/hud/aim_controls.tscn`, `scenes/ui/hud/hud.tscn` | Use one 352 px coherent component at the lower-right, away from the cannon and wind flag | 2.2 |
| External asset safety | Kenney official UI Pack 2.0 has 430 files and CC0 license | Official `https://kenney.nl/assets/ui-pack`, archive SHA-256 `A8A14A234911EB648C062622915C93E79E94E97CB7F9F375A70F6617F1174318` | Keep only six non-executable PNGs plus the upstream license and source note | 1.1, 1.2 |
| Visual evidence | Existing background capture runner reaches all three screens | `src/delivery/delivery_capture_runner.gd`, prior audit assets | Export once, capture named 1280x720 states, inspect actual images, and fix visible blockers before concepts | 3.1 |
| Concept breadth | User requested three screens in three fully distinct styles | current user direction and ImageGen workflow | Generate nine independent 1280x720 images grounded in the matching runtime screen and primary reference | 3.2 |

Readiness statement:

- Every material product, architecture, dependency, data, UX, ownership, safety, and validation decision is closed.
- Godot 4.7.1, `scripts/verify.ps1`, the Windows export preset, ImageMagick, the capture runner, and ImageGen are available; their invocations are verified for PowerShell.
- Remaining unknowns are implementation-local and cannot change this contract.

## Tasks

### Phase 1: Authority, provenance, and shared visual system

Goal: make the new casual component direction and licensed inputs durable before scene composition changes.

Preconditions:

- The current Theme, screen scenes, HUD scenes, design specs, current captures, and official asset source have been inspected.

Source owners: `docs/source-brief.md`, `.agents/design/UIUX_GUIDELINES.md`, `docs/asset-licenses.md`, `assets/ui/external/kenney_ui_pack_2/`, `resources/ui/paint_mountain_theme.tres`

- [x] **1.1** Record the bounded UI direction and external asset provenance.
  - Change: add the user supersession, update the UI spec and visual-reference status, and record source URL, version, license, archive hash, and selected files.
  - Accept: each durable document points to the production owner and does not claim generated concepts are approved.
- [x] **1.2** Apply one shared casual Theme vocabulary.
  - Change: use the selected neutral, blue, and red Kenney textures as nine-slice shared button/card roles; refine surface, type, focus, disabled, and spacing roles without scene-local colors or fonts.
  - Accept: Godot imports the textures and parses the Theme without warnings or missing resources.
  - Guard: no full external pack, font, sound, script, or second token registry enters the repository.

### Phase 2: Three production screens

Goal: remove visible clipping, overlap pressure, empty filler, and unbalanced containment while preserving all real actions.

Preconditions:

- Phase 1 acceptance checks pass.

Source owners: `scenes/ui/screens/main_menu.tscn`, `src/ui/screens/stage_select_screen.gd`, `scenes/ui/screens/stage_select.tscn`, `scenes/ui/hud/*.tscn`

- [x] **2.1** Recompose Main Menu and Stage Select.
  - Change: shorten the menu card, remove the stretching subtitle, balance selection and preview columns, increase card breathing room, and change pagination to eight stages without altering stage openness or navigation signals.
  - Accept: 1280x720 Main Menu and Stage Select renders have deliberate whitespace, no overlap or clipping, and clear primary focus.
- [x] **2.2** Recompose Aim View HUD components.
  - Change: make aim controls internally consistent at 352x96, place them lower-right outside the cannon/flag area, reduce coverage/status surface weight, and keep Fire centered and unobstructed.
  - Accept: 1280x720 Stage 30 Aim View shows every value and control fully inside its component, with no panel overlap or world-space target obstruction.
  - Guard: Aim/Map, Fire, Finish, Gear, and Shot Follow behavior and focus connections remain unchanged.

Batch gate:

- Run `powershell -ExecutionPolicy Bypass -File scripts/verify.ps1` once after scene and Theme parsing passes locally.

### Phase 3: Production evidence and visual alternatives

Goal: prove the implemented baseline in the real build, then create a clearly non-canonical exploration set.

Preconditions:

- Phase 2 and its batch gate pass.

Source owners: `export_presets.cfg`, `src/delivery/delivery_capture_runner.gd`, `.agents/evidence/casual-shared-ui-refresh-2026-08-08/`, `docs/concepts/casual-ui-directions-2026-08-08/`

- [x] **3.1** Export and inspect the implemented UI.
  - Change: export Windows Desktop once; capture Main Menu, Stage Select, Stage 30 Aim View, and one 1920x1080 Aim View using `--capture-background`; create a before/after comparison.
  - Accept: direct image review finds no clipping, collisions, unintentional empty expansion, unsupported action, or unreadable Korean label.
  - Guard: the exported executable starts and exits through the capture runner without a Godot error.
- [x] **3.2** Record nine independent visual concepts.
  - Change: generate Main Menu, Stage Select, and Aim View for each of three deliberately different style systems, preserving real screen functions and 16:9 composition; save prompts and outputs in one HTML gallery.
  - Accept: nine images exist in stable display order, each screen has three clearly distinct styles, and the gallery labels every image as exploratory rather than runtime proof.

## Validation and Rework Controls

| Cadence | Exact check | Run when | Do not rerun until |
| --- | --- | --- | --- |
| Inner loop | `& 'D:\tools\Godot\4.7.1-stable\Godot_v4.7.1-stable_win64_console.exe' --headless --path . --editor --quit` | Theme, imported texture, or scene parsing changes | Relevant resource or scene changes |
| Phase gate | `powershell -ExecutionPolicy Bypass -File scripts/verify.ps1` | Phase 2 tasks pass | Script, scene, resource, or project setting changes |
| Final export | `& 'D:\tools\Godot\4.7.1-stable\Godot_v4.7.1-stable_win64_console.exe' --headless --path . --export-release 'Windows Desktop' 'builds/windows/PaintMountain.exe'` | Phase gate passes | Export-owned input changes |
| Final rendered evidence | `Start-Process builds/windows/PaintMountain.exe -ArgumentList @('--','--capture-background','--capture-screen=<state>','--capture-size=<size>','--capture-language=ko','--capture-output=<absolute-path>') -PassThru -Wait` | Final export passes, once per named state and size | Visible owner or capture-state input changes |
| Document gate | `git diff --check` | Evidence, plan, and gallery records are complete | A touched text file changes |

Validation rules:

- Run the narrowest check that proves the current task.
- Run each named phase gate once after its owned tasks pass.
- Run the production export and rendered evidence once after implementation stabilizes.
- Rerun a failed check only after a relevant implementation change or a new hypothesis can produce new evidence.
- Record known non-blocking warnings once instead of rediscovering them.

## Predetermined Contingencies and Change Control

| Trigger | Required response | Boundary or escalation point |
| --- | --- | --- |
| A verified material fact contradicts this contract | Stop the affected branch, update the contract, and obtain any required approval before resuming | Do not let the executor choose a new product, architecture, dependency, data, UX, safety, or validation contract |
| Kenney texture nine-slice produces visible distortion | Keep the imported source and use it only for button/card roles whose 192x64 ratio and 12 px patch margins render cleanly; retain Theme-owned flat panels elsewhere | Do not edit gameplay scenes or import a second pack |
| A shared Theme change breaks a secondary surface | Correct that role in the Theme or add a narrowly named Theme variation | Do not add scene-local color, font, or StyleBox duplication |
| ImageGen output invents unsupported actions or unusable text | Regenerate that one image with the exact real action inventory and matching screen reference | Do not treat a visibly false image as an implementation direction |

Implementation-local discoveries may be handled inside the locked contract when they cannot change scope, visible behavior, ownership, architecture, safety, or acceptance.

## Progress and Next Steps

- Canonical progress: the task checkboxes in this contract.
- Current phase: Complete.
- Next task: none.
- Last completed gate: final quality, release export, and document gate.
- Update rule: after a checkpoint passes, record its concise evidence, check the task, and advance this pointer in the same edit.

Completion evidence:

- Godot import/script verification passed after the final shared Theme change.
- The Windows Desktop release export passed; concept documentation was excluded
  from the release through its local `.gdignore`.
- Six running-release states and two comparison boards were opened and inspected
  under `.agents/evidence/casual-shared-ui-refresh-2026-08-08/`.
- Nine independent ImageGen outputs, prompt recipes, and a Korean HTML gallery
  are stored under `docs/concepts/casual-ui-directions-2026-08-08/`.
- The diff-scoped quality audit confirmed Theme ownership and found one local
  state defect: DangerButton hover/pressed styling fell back to the neutral
  base. The shared Theme now keeps its red surface and white text in those states.
- `git diff --check` passed.

## Completion and Stop Conditions

Complete when:

- Every task acceptance check passes.
- Every guard, phase gate, and final gate named by this contract passes.
- No placeholder or unresolved material decision remains.
- Durable direction and implemented status are recorded in the owning spec and project record.
- Frontmatter status is changed to `done` only after the implementation is complete.

Replan when:

- A material discovery invalidates the locked contract.

Do not replan or stop for:

- Implementation-local mechanics already contained by this contract.
- A passing check whose relevant inputs have not changed.

On start or resume, read this contract and inspect the worktree only enough to confirm checkpoint inputs, then continue from the first unchecked task whose prerequisites are satisfied. Treat checked tasks and recorded evidence as complete unless a relevant input changed. Run each check only at its declared cadence. Mark a task complete only after its acceptance check passes, and update the checkbox and progress pointer together. If reality contradicts a material decision, stop that branch and revise this contract before continuing.
