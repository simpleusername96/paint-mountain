# Paint Mountain

Paint Mountain is a Korean-first, three-stage 3D physics-puzzle vertical slice
about launching finite-payload paintballs from a small foreground cannon onto a
large generated mountain. The repository is currently executing the core
interaction redesign in
`.agents/execplans/2026-08-03-core-interaction-redesign.md`; historical release
claims and screenshots do not establish completion of that redesign.

## Engine

- Godot 4.x (bootstrap verified with Godot 4.7.1 stable)
- GDScript
- Compatibility renderer
- Windows desktop primary target
- Fixed 60 Hz physics tick

## Launch

Open `project.godot` in Godot 4.x and run the project, or use the console executable:

```powershell
& 'C:\path\to\Godot_v4.x-stable_win64_console.exe' --path 'D:\npjt\paint-mountain' --editor
```

Run the repeatable headless smoke check with:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/verify.ps1 -GodotPath 'C:\path\to\Godot_v4.x-stable_win64_console.exe'
```

`scripts/verify.ps1` also accepts the `GODOT_BIN` environment variable or a `godot4`/`godot` command on PATH.

Create the production-style Windows build with:

```powershell
& 'C:\path\to\Godot_v4.7.1-stable_win64_console.exe' --headless --path 'D:\npjt\paint-mountain' --export-release 'Windows Desktop' 'builds\windows\PaintMountain.exe'
& 'D:\npjt\paint-mountain\builds\windows\PaintMountain.exe'
```

The executable is unsigned and the generated `builds/` directory is intentionally not tracked.

The repository is also registered in fastrun-manager with the canonical project command:

```powershell
& '.\builds\windows\PaintMountain.exe'
```

## Target Gameplay Controls

- Mouse drag on empty 3D space: adjust yaw and elevation independently.
- Mouse wheel or visible `−/+`: fine-tune power; holding the buttons repeats.
- `A` / `D`: adjust yaw; `W` / `S`: adjust elevation.
- `Space`: fire when the stage and complete pre-impact prediction permit it.
- `R`: restart the stage.
- `Tab`: switch between briefing inspection and aiming.
- `Esc`: pause; Resume returns to the prior gameplay state.
- `F3`: toggle the developer overlay in debug builds only.

Terrain clicks never solve aim. The dotted preview uses the real projectile
radius and physics through its first collision or playable-bounds exit and
does not predict paint coverage, bounces, or mechanism results.

## Project Structure

- `scenes/bootstrap/`: isolated 3D engine/render smoke scene.
- `scenes/gameplay/`: state-driven game scene and reusable cannon scene.
- `scenes/app/`, `scenes/ui/`, `src/app/`, `src/ui/`: application entry, navigation, scene-based screen/HUD components, and behavioral coordinators.
- `src/stage_generation/`, `resources/stage_generation/`: deterministic path-first terrain profiles, accepted layouts, placement, and dressing metadata.
- `src/cannon/`, `src/projectile/`, `src/terrain/`, `src/paint/`: manual ballistics/prediction, measured projectile contacts, closed generated terrain, and authoritative eligible-only paint.
- `src/mechanisms/`: shared activation contract and the Burst, Splitter, and Bumper implementations.
- `src/stage/`, `resources/stages/`: stage state, exact three-stage catalog, generation references, targets, cameras, and recorded solutions.
- `src/autoload/`, `src/replay/`, `src/agent/`: progression/persistence, replay, and UI-independent actions/observations.
- `src/debug/`, `src/delivery/`: release-disabled diagnostics and deterministic running-build capture support.
- `src/bootstrap/`: isolated bootstrap-only setup and procedural mountain proxy.
- `docs/`: active game design, architecture, and acceptance specifications.
- `.agents/`: repository-local project memory and the active implementation plan.
- `scripts/verify.ps1`: engine import and runtime smoke validation.
- `tests/`: focused subsystem, cross-process persistence/replay, reliability, UI, and performance checks.
- `screenshots/`: historical release captures until the active redesign's coordinated running-build gate replaces them.

The planned gameplay ownership boundaries are defined in `docs/technical-architecture.md`; empty speculative folders are intentionally not pre-created.

## Known Limitations

- Godot is not assumed to be installed on PATH.
- The Windows executable is unsigned and must be built locally with matching Godot export templates.
- The active redesign is not complete until its unchecked gates pass; the current build still contains superseded terrain/contact/aim/UI behavior during migration.
- Physics replay must be revalidated in format 3 after terrain and aiming migration.
- Approved Kenney/Pretendard assets and procedural audio meet the vertical-slice target; bespoke production art, animation, audio, signing, and installer packaging remain outside scope.

## Development Contract

Read `AGENTS.md`, `.agents/Documentation.md`, and the active ExecPlan before
changes. Implement its tasks in order, rerun the relevant focused checks plus
`scripts/verify.ps1`, and never report behavior as implemented without running
it. Do not open a visible Godot/game window until the final user-coordinated
visual gate.
