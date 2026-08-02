# Paint Mountain

Paint Mountain is a planned 3D physics-puzzle game about launching finite-payload paintballs from a small foreground cannon onto a large distant mountain. This repository currently contains the completed Phase 1 project bootstrap, not the finished vertical slice.

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

## Current Controls

- `Esc`: quit the bootstrap scene.

Gameplay aiming and camera controls are specified in `docs/design-spec.md` but are not implemented in Phase 1.

## Project Structure

- `scenes/bootstrap/`: temporary runnable 3D smoke scene.
- `src/bootstrap/`: bootstrap-only scene setup and procedural mountain proxy.
- `docs/`: active game design, architecture, and acceptance specifications.
- `.agents/`: repository-local project memory and the active implementation plan.
- `scripts/verify.ps1`: engine import and runtime smoke validation.

The planned gameplay ownership boundaries are defined in `docs/technical-architecture.md`; empty speculative folders are intentionally not pre-created.

## Known Limitations

- The playable cannon, projectile physics, paint mask, coverage, stage loop, cameras, mechanisms, menus, saving, replay, audio, debug overlay, stages, and delivery screenshots are not implemented yet.
- The bootstrap mountain is procedural preview geometry with collision, not a tuned stage.
- Godot is not assumed to be installed on PATH.

## Development Contract

Read `AGENTS.md` and `.agents/Documentation.md` before implementation. Execute the first unchecked phase in `.agents/Plan.md`, and never report a planned feature as implemented without running it.
