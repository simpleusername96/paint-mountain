# Paint Mountain

Paint Mountain is a Korean-first, 30-stage desktop 3D physics puzzle about
launching persistent paintballs from a stationary foreground cannon onto a
distant generated mountain. The player selects a target and adjusts elevation
and power before firing; projectiles continuously paint the playable mountain
surface they physically traverse. Every stage is selectable from the start.

## Engine

- Godot 4.x (bootstrap verified with Godot 4.7.1 stable)
- GDScript
- Compatibility renderer
- Windows desktop primary target
- Fixed 60 Hz physics tick

## Launch

Godot 4.7.1 is shared with Cardborne from
`D:\tools\Godot\4.7.1-stable`. The user-level `GODOT_BIN` points to the
console executable there; do not create another project-local Godot copy.

Open `project.godot` in Godot 4.x and run the project, or use the shared console executable:

```powershell
& 'D:\tools\Godot\4.7.1-stable\Godot_v4.7.1-stable_win64_console.exe' --path 'D:\npjt\paint-mountain' --editor
```

Run the repeatable headless smoke check with:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/verify.ps1
```

`scripts/verify.ps1` resolves the shared path by default and also accepts an
explicit `-GodotPath`, the `GODOT_BIN` environment variable, or a
`godot4`/`godot` command on PATH.

Create the production-style Windows build with:

```powershell
& 'D:\tools\Godot\4.7.1-stable\Godot_v4.7.1-stable_win64_console.exe' --headless --path 'D:\npjt\paint-mountain' --export-release 'Windows Desktop' 'builds\windows\PaintMountain.exe'
& 'D:\npjt\paint-mountain\builds\windows\PaintMountain.exe'
```

The executable is unsigned and the generated `builds/` directory is intentionally not tracked.

The repository is also registered in fastrun-manager with the canonical project command:

```powershell
& '.\builds\windows\PaintMountain.exe'
```

## Gameplay Controls

- Click or drag on valid mountain-top terrain in Aim View: select the intended
  landing point and commit the best bounded aim solution.
- Mouse wheel or visible `−/+`: fine-tune power; `W` / `S` or the visible
  angle controls adjust elevation while preserving the selected target.
- `Space` or the Fire button: fire when the authoritative stage rules permit
  it. Advisory trajectory prediction does not independently block Fire.
- `Tab`: switch between Aim View and Map Inspection; during Shot Follow it
  returns the camera to the cannon.
- `Esc`: pause; Resume returns to the prior gameplay state.
- `F3`: toggle the developer overlay in debug builds only.

Map Inspection clicks change only the inspection focus. The dotted preview is
latest-only advisory presentation through first collision or playable-bounds
exit; it does not predict paint coverage, bounces, or mechanism results.

## Project Structure

- `scenes/bootstrap/`: isolated 3D engine/render smoke scene.
- `scenes/gameplay/`: state-driven game scene and reusable cannon scene.
- `scenes/app/`, `scenes/ui/`, `src/app/`, `src/ui/`: application entry, navigation, scene-based screen/HUD components, and behavioral coordinators.
- `src/stage_generation/`, `resources/stage_generation/`: deterministic offline terrain profiles, accepted layouts, placement, and dressing metadata.
- `src/cannon/`, `src/projectile/`, `src/terrain/`, `src/paint/`: target solving and prediction, physical contacts, open generated terrain, and authoritative paint/coverage.
- `src/mechanisms/`: shared activation contract and the Burst, Splitter, and Uphill Rebound implementations.
- `src/stage/`, `resources/stages/`: stage state, the fixed 30-stage catalog, targets, cameras, and persisted entry witnesses.
- `src/autoload/`, `src/agent/`: progression/persistence and UI-independent actions/observations.
- `src/debug/`, `src/delivery/`: release-disabled diagnostics and deterministic running-build capture support.
- `src/bootstrap/`: isolated bootstrap-only setup and procedural mountain proxy.
- `docs/`: active game design, architecture, and acceptance specifications.
- `.agents/`: repository-local project memory and the active implementation plan.
- `scripts/verify.ps1`: engine import and runtime smoke validation.
- `tests/`: focused subsystem, persistence, reliability, UI, and performance checks.
- `screenshots/` and evidence directories: current or historical running-build captures as identified by their adjacent records.

The planned gameplay ownership boundaries are defined in `docs/technical-architecture.md`; empty speculative folders are intentionally not pre-created.

## Known Limitations

- Godot is not assumed to be installed on PATH.
- The Windows executable is unsigned and must be built locally with matching Godot export templates.
- Player replay is intentionally removed; historical plans and evidence can
  still describe it but do not define current behavior.
- Approved Kenney/Pretendard assets and procedural audio meet the vertical-slice target; bespoke production art, animation, audio, signing, and installer packaging remain outside scope.

## Development Contract

Read `AGENTS.md`, `.agents/Documentation.md`, and any relevant active ExecPlan
before changes. Run the relevant focused checks plus `scripts/verify.ps1`, and
do not report behavior as implemented without testing it. Player-facing work
also requires inspection of actual running-game output.
