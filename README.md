# Paint Mountain

Paint Mountain is a complete Korean-first, three-stage 3D physics-puzzle vertical slice about launching finite-payload paintballs from a small foreground cannon onto a large generated mountain. It includes deterministic stage/placement generation, direct impact targeting, three mechanisms, progression, saves, replay, a UI-independent agent API, release-disabled debug tooling, approved offline assets, a Windows export preset, and final running-build evidence.

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

## Current Gameplay Controls

- Mouse hover: preview a solvable first-impact target and its complete trajectory.
- Left-click or held drag: lock or retarget the terrain/mechanism impact point.
- Mouse wheel or visible `−/+`: fine-tune power; holding the buttons repeats.
- `-` / `=`: adjust power by 2%.
- `A` / `D` and `W` / `S`: accessible yaw/elevation fallback.
- `Space`: fire when no projectile is active.
- `R`: restart the stage.
- `Tab`: switch between briefing inspection and aiming.
- `Esc`: pause; Resume returns to the prior gameplay state.
- `F3`: toggle the developer overlay in debug builds only.

Main menu, stage select, full settings, briefing orbit/zoom, follow/wide/cannon observation cameras, retry/next/replay, pause, three tuned stages, unlock state, save foundations, generated audio, pooled paint effects, and the in-process gameplay API are implemented.

## Project Structure

- `scenes/bootstrap/`: isolated 3D engine/render smoke scene.
- `scenes/sandbox/`: cannon/projectile validation scene.
- `scenes/gameplay/`: state-driven game scene and reusable cannon scene.
- `scenes/app/`, `src/app/`, `src/ui/`: application entry, navigation, shared UI components, screens, and gameplay HUD.
- `src/stage_generation/`, `resources/stage_generation/`: deterministic path-first terrain profiles, accepted layouts, placement, and dressing metadata.
- `src/cannon/`, `src/projectile/`, `src/terrain/`, `src/paint/`: direct targeting/ballistics, projectile lifecycle, generated terrain rendering, and authoritative paint.
- `src/mechanisms/`: shared activation contract and the Burst, Splitter, and Bumper implementations.
- `src/stage/`, `resources/stages/`: stage state, exact three-stage catalog, generation references, targets, cameras, and recorded solutions.
- `src/autoload/`, `src/replay/`, `src/agent/`: progression/persistence, replay, and UI-independent actions/observations.
- `src/debug/`, `src/delivery/`: release-disabled diagnostics and deterministic running-build capture support.
- `src/bootstrap/`: isolated bootstrap-only setup and procedural mountain proxy.
- `docs/`: active game design, architecture, and acceptance specifications.
- `.agents/`: repository-local project memory and the active implementation plan.
- `scripts/verify.ps1`: engine import and runtime smoke validation.
- `tests/`: focused subsystem, cross-process persistence/replay, reliability, UI, and performance checks.
- `screenshots/`: seven separate 1920×1080 images captured from the Windows release executable.

The planned gameplay ownership boundaries are defined in `docs/technical-architecture.md`; empty speculative folders are intentionally not pre-created.

## Known Limitations

- Godot is not assumed to be installed on PATH.
- The Windows executable is unsigned and must be built locally with matching Godot export templates.
- Physics replay is deterministic within the measured test-machine tolerance; engine/platform changes should rerun the replay probe.
- Approved Kenney/Pretendard assets and procedural audio meet the vertical-slice target; bespoke production art, animation, audio, signing, and installer packaging remain outside scope.

## Development Contract

Read `AGENTS.md` and `.agents/Documentation.md` before changes. Rerun the relevant focused checks plus `scripts/verify.ps1`, and never report behavior as implemented without running it.
