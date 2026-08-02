# Paint Mountain

Paint Mountain is a 3D physics-puzzle game about launching finite-payload paintballs from a small foreground cannon onto a large distant mountain. The repository currently contains the complete three-stage game and application/presentation layer through Phase 7; release tooling, export, performance evidence, and final screenshots remain.

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

## Current Gameplay Controls

- `A` / `D`: adjust cannon yaw.
- `W` / `S`: adjust elevation.
- `Q` / `E` or mouse wheel: adjust power.
- Left-drag: adjust yaw and elevation.
- `Space`: fire when no projectile is active.
- `R`: clear the current projectile and reset aiming.
- `Tab`: switch between briefing inspection and aiming.
- `Esc`: pause; Resume returns to the prior gameplay state.

Main menu, stage select, full settings, briefing orbit/zoom, follow/wide/cannon observation cameras, retry/next/replay, pause, three tuned stages, unlock state, save foundations, generated audio, pooled paint effects, and the in-process gameplay API are implemented.

## Project Structure

- `scenes/bootstrap/`: temporary runnable 3D smoke scene.
- `scenes/sandbox/`: current cannon/projectile validation entry.
- `scenes/gameplay/`: current state-driven game entry and reusable cannon scene.
- `scenes/app/`, `src/app/`, `src/ui/`: application entry, navigation, shared UI components, screens, and gameplay HUD.
- `src/cannon/`, `src/projectile/`, `src/terrain/`: Phase 2 runtime owners.
- `src/mechanisms/`: shared activation contract and the Burst, Splitter, and Bumper implementations.
- `src/stage/`, `resources/stages/`: stage state, exact three-stage catalog, placements, targets, cameras, and recorded solutions.
- `src/autoload/`, `src/replay/`, `src/agent/`: progression/persistence, replay, and UI-independent actions/observations.
- `src/bootstrap/`: isolated bootstrap-only setup and procedural mountain proxy.
- `docs/`: active game design, architecture, and acceptance specifications.
- `.agents/`: repository-local project memory and the active implementation plan.
- `scripts/verify.ps1`: engine import and runtime smoke validation.

The planned gameplay ownership boundaries are defined in `docs/technical-architecture.md`; empty speculative folders are intentionally not pre-created.

## Known Limitations

- Full debug overlay/log export, Windows export, final performance QA, and delivery screenshots are not implemented yet.
- Persistence has focused atomic/fallback tests; a separate real process-restart persistence check remains for final QA.
- Godot is not assumed to be installed on PATH.

## Development Contract

Read `AGENTS.md` and `.agents/Documentation.md` before implementation. Execute the first unchecked phase in `.agents/Plan.md`, and never report a planned feature as implemented without running it.
