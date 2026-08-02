# Paint Mountain

Paint Mountain is a 3D physics-puzzle game about launching finite-payload paintballs from a small foreground cannon onto a large distant mountain. This repository currently contains the completed Phase 2 cannon/projectile sandbox, not the finished vertical slice.

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

## Current Sandbox Controls

- `A` / `D`: adjust cannon yaw.
- `W` / `S`: adjust elevation.
- `Q` / `E` or mouse wheel: adjust power.
- Left-drag: adjust yaw and elevation.
- `Space`: fire when no projectile is active.
- `R`: clear the current projectile and reset aiming.
- `Esc`: quit the sandbox.

Stage inspection, camera switching, pause, and complete gameplay controls remain scheduled in the active plan.

## Project Structure

- `scenes/bootstrap/`: temporary runnable 3D smoke scene.
- `scenes/sandbox/`: current cannon/projectile validation entry.
- `src/cannon/`, `src/projectile/`, `src/terrain/`: Phase 2 runtime owners.
- `src/bootstrap/`: isolated bootstrap-only setup and procedural mountain proxy.
- `docs/`: active game design, architecture, and acceptance specifications.
- `.agents/`: repository-local project memory and the active implementation plan.
- `scripts/verify.ps1`: engine import and runtime smoke validation.

The planned gameplay ownership boundaries are defined in `docs/technical-architecture.md`; empty speculative folders are intentionally not pre-created.

## Known Limitations

- Paint mask, coverage, stage loop, camera director, mechanisms, menus, saving, replay, audio, debug overlay, completed stages, and delivery screenshots are not implemented yet.
- The sandbox mountain is procedural validation geometry with collision, not a tuned stage.
- Godot is not assumed to be installed on PATH.

## Development Contract

Read `AGENTS.md` and `.agents/Documentation.md` before implementation. Execute the first unchecked phase in `.agents/Plan.md`, and never report a planned feature as implemented without running it.
