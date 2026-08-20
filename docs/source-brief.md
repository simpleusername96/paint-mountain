---
type: spec
status: active
created: 2026-08-02
last_reviewed: 2026-08-11
canonical_for: baseline Paint Mountain directive and recorded later-user supersessions
scope: complete original user directive plus explicit later revisions
source: user message in the project-bootstrap conversation
related:
  - design-spec.md
  - technical-architecture.md
  - test-checklist.md
  - ../.agents/execplans/2026-08-06-ballistic-terrain-preparation.md
  - ../.agents/execplans/2026-08-08-projectile-scale-balance-and-aim-performance.md
  - ../.agents/execplans/2026-08-10-essential-ui-fidelity.md
  - ../.agents/Plan.md
---

# Original Paint Mountain Directive

## Purpose

Preserve the user's complete original implementation directive and explicitly
record later revisions so future work can resolve requirements without changing
the historical text.

## Scope

The text under “Verbatim Requirements” is the unedited directive beginning with
“You are” and ending with the product's central design question. It is the
baseline requirement. A dated entry under “Later User Supersessions” overrides
only the original clauses it explicitly names; all other original clauses remain
in force. This effective source brief wins conflicts with derived documents.

## Requirements

### Verbatim Requirements

You are a senior game designer, technical director, gameplay engineer, UI/UX designer, and QA lead. Your task is to design and implement a polished playable vertical slice of a 3D physics-puzzle game.

WORKING TITLE
Paint Mountain

DEFAULT TECHNOLOGY
Use the engine and conventions already present in the repository.

If no game project exists, use:
- Godot 4.x
- GDScript
- Desktop Windows as the primary platform
- A lightweight renderer suitable for modest hardware
- No Docker
- No backend or online service
- Minimal external dependencies

Do not stop at a design document. Produce a working playable game.

Do not ask broad design questions unless a genuinely blocking technical decision cannot be inferred. Make reasonable assumptions, record them briefly, and continue.

==================================================
1. HIGH-LEVEL CONCEPT
==================================================

Create a 3D gravity-driven paintball puzzle game.

The player controls a stationary paint cannon positioned far in front of a large mountainous target. The player adjusts the cannon’s horizontal direction, vertical launch angle, and firing power, then launches a paintball toward the mountain.

After landing, the paintball:

- Bounces according to its impact velocity and surface angle.
- Rolls or slides downhill under gravity.
- Leaves paint along its path.
- Produces a larger splash on strong impacts.
- Interacts with special mechanisms placed on the terrain.
- Eventually loses its remaining paint, stops moving, or leaves the playable area.

The objective is to cover at least a specified percentage of the mountain’s paintable surface using a limited number of shots.

The central pleasure of the game must come from:

- Reading the mountain’s shape.
- Choosing a high-value landing point.
- Predicting how gravity will carry the ball downhill.
- Routing the ball through useful mechanisms.
- Watching one good shot create a long, satisfying chain reaction.
- Improving the result through rapid retries.

This is not a shooter based on reflexes. It is a spatial planning and physics puzzle.

==================================================
2. NON-NEGOTIABLE SPATIAL COMPOSITION
==================================================

The scale relationship between the cannon and the mountain is critical.

The mountain must feel large, distant, and dominant. It must never look like a small tabletop diorama placed beside the cannon.

In the primary aiming view:

- The cannon is located in the lower foreground.
- The cannon occupies no more than approximately 15–20% of the visible frame.
- The mountainous target occupies most of the middle and upper portions of the screen.
- Most important slopes, ridges, valleys, and mechanisms should be visible from the aiming position.
- The mountain should visually feel tens or hundreds of meters across.
- Sparse trees, rocks, ledges, and architectural details may be used to communicate scale.
- The player must feel that they are launching a projectile toward a real distant landform.

Suggested approximate world scale:

- Cannon barrel length: 2–3 meters.
- Distance from cannon to primary target: 70–150 meters.
- Mountain width: 120–250 meters.
- Mountain height: 60–140 meters.
- Individual mechanisms: large enough to identify, but no larger than necessary.
- Mechanisms must not make the mountain feel miniature.

Do not use an orthographic tabletop presentation for the main gameplay.

A three-quarter or isometric-style camera may be used for stage previews and terrain inspection, but the actual aiming view should use a perspective camera positioned behind and slightly above the cannon.

A fixed side-view gameplay mode is outside the scope of the first implementation.

==================================================
3. DESIGN PILLARS
==================================================

Follow these five pillars.

1. Large, readable terrain

The player should be able to understand major slopes and likely routes without rotating the camera constantly.

2. Predictable but not trivial physics

Repeated launches with the same parameters should produce nearly identical results. The player must be able to learn from previous attempts.

3. Strong cause and effect

Every bounce, split, burst, and coverage increase must be visually understandable.

4. Rapid repetition

A failed attempt should be restartable in less than one second after confirmation. Do not make the player wait through long transitions.

5. Minimal presentation

The art, UI, menus, and feedback should be clean and restrained. Do not add unnecessary systems merely to make the project appear larger.

==================================================
4. MVP SCOPE
==================================================

The first playable vertical slice must contain:

- One main menu.
- One stage-select screen.
- Three complete stages.
- One terrain-inspection or stage-briefing mode.
- One third-person over-the-cannon aiming mode.
- One projectile-follow and paint-observation mode.
- One clear result state.
- One failure result state.
- Basic pause and settings menus.
- One basic paintball.
- Three terrain mechanisms:
  - Burst Node.
  - Splitter Node.
  - Bumper Node.
- Coverage calculation.
- Limited shots.
- Stage progression.
- Saved best results.
- Restart and replay support.
- Basic sound and visual feedback.

Do not add the following to the MVP:

- Shops.
- Premium currencies.
- Character customization.
- Permanent stat upgrades.
- Gacha.
- Daily challenges.
- Leaderboards.
- Multiplayer.
- User-generated maps.
- Ads.
- Story or dialogue.
- Inventory management.
- Multiple cannon types.
- Large collections of projectile types.
- Live-service systems.

Architect the project so some of these could be added later, but do not implement them before the core game is fun and reliable.

==================================================
5. CORE GAME LOOP
==================================================

The intended loop is:

1. Select a stage.
2. View the stage objective and available shots.
3. Inspect the mountain from a distant three-quarter camera.
4. Identify slopes, valleys, paintable routes, and mechanisms.
5. Enter the aiming view behind the cannon.
6. Adjust horizontal direction, vertical angle, and firing power.
7. Review the initial predicted trajectory.
8. Fire the paintball.
9. Watch the ball fly, impact, bounce, roll, split, or activate mechanisms.
10. Watch paint spread along the route.
11. Wait until all active balls and paint effects settle.
12. Add the newly painted surface to the stage coverage.
13. Return to aiming if shots remain and the target has not been reached.
14. Clear the stage if the target coverage has been reached.
15. Fail the stage if no shots remain and the target has not been reached.
16. Show the result and allow immediate retry, next stage, replay, or stage selection.

The player must not directly steer a paintball after firing.

The challenge should come from planning the launch, not controlling the projectile during flight.

==================================================
6. GAME STATE MACHINE
==================================================

Implement an explicit stage state machine.

Recommended states:

- LOADING
- BRIEFING
- AIMING
- PROJECTILE_IN_FLIGHT
- PAINT_SETTLING
- SHOT_RESULT
- STAGE_CLEAR
- STAGE_FAILED
- PAUSED

Rules:

- The player cannot fire while a projectile or child projectile is still active.
- Coverage should not be finalized until all active projectiles and paint-flow effects have settled.
- After the shot settles, briefly show how much coverage that shot added.
- If the target has been reached, transition to STAGE_CLEAR.
- If shots remain, transition back to AIMING.
- If no shots remain, transition to STAGE_FAILED.
- Restart must safely remove all projectiles, particles, paint, temporary gimmick states, timers, and camera transitions.

Do not spread stage-state logic across unrelated scripts. Keep one authoritative controller responsible for progression.

==================================================
7. CAMERA SYSTEM
==================================================

Create a dedicated camera director with clearly separated camera modes.

A. Stage briefing camera

Purpose:
- Inspect the terrain before aiming.
- Understand its overall shape.
- Locate mechanisms.

Behavior:
- Distant three-quarter perspective.
- Orbit around a limited range.
- Zoom in and out.
- Prevent the camera from moving behind or inside the terrain.
- Keep the full mountain readable.
- Allow mechanisms to highlight when hovered or selected.
- Provide a clear button to enter aiming mode.

B. Aiming camera

Purpose:
- Aim the cannon while seeing the mountain at meaningful scale.

Composition:
- Cannon in the lower foreground.
- Mountain dominates the middle and upper frame.
- Perspective projection.
- Suggested field of view: approximately 45–55 degrees.
- Avoid wide-angle distortion that makes the mountain look small.
- Keep the cannon barrel and first portion of the trajectory visible.
- Preserve enough vertical space to show high launch arcs.

C. Projectile-follow camera

Purpose:
- Make the result of the shot readable and satisfying.

Behavior:
- Initially follow the projectile from behind or from a cinematic side angle.
- Pull outward before the ball reaches the terrain if necessary.
- After impact, prioritize showing the ball’s route across the terrain.
- If the ball splits, transition to a wider view that keeps the important child balls visible.
- Avoid rapid camera cuts.
- Avoid clipping through the terrain.
- Allow the player to switch between:
  - Follow projectile.
  - Wide terrain view.
  - Cannon view.
- Provide an optional 2× simulation-speed button after the projectile has landed.

D. Result camera

Purpose:
- Present the final painted mountain as the main reward.

Behavior:
- Show the mountain from a clear three-quarter angle.
- Slowly orbit or use a restrained camera motion.
- Do not cover the mountain with an oversized result panel.

Camera transitions should generally take approximately 0.3–0.7 seconds and use smooth interpolation.

==================================================
8. AIMING AND INPUT
==================================================

Primary platform:
- Desktop.
- Mouse and keyboard first.
- Controller support may be added later.

Recommended controls:

Terrain briefing:
- Left-drag: orbit camera.
- Mouse wheel: zoom.
- Click a mechanism: show its name and short function.
- Enter or Start button: move to aiming mode.
- Escape: return to stage selection.

Aiming:
- Mouse drag or A/D: rotate cannon horizontally.
- Mouse drag or W/S: adjust elevation.
- Mouse wheel or Q/E: adjust power.
- Space or Fire button: fire.
- R: restart stage.
- Escape: pause.
- Tab: return temporarily to terrain inspection.

Display:

- Horizontal direction does not require a large numeric readout unless useful.
- Show vertical angle.
- Show power as a percentage.
- Show a compact dotted trajectory.
- Show an approximate first-impact marker when it is not hidden by terrain.

The trajectory preview must use the same gravity and launch parameters as the actual projectile.

The preview should show:

- The initial ballistic arc.
- The approximate position of the first collision.

The preview should not show:

- The complete post-impact route.
- Future mechanism activations.
- The exact final coverage.
- Every bounce and split.

The player should receive enough information to aim intentionally without solving the entire puzzle automatically.

==================================================
9. PROJECTILE PHYSICS
==================================================

Use a proper 3D rigid-body projectile.

The basic paintball must support:

- Gravity.
- Continuous collision detection.
- Bounce.
- Rolling.
- Sliding.
- Surface friction.
- Angular movement.
- Velocity damping.
- Paint-payload depletion.
- Out-of-bounds detection.
- Sleep or stop detection.

The physics must be deterministic enough that identical input parameters on an unchanged stage produce effectively identical results.

Suggested projectile properties should be stored in data, not hardcoded inside gameplay logic:

- Radius.
- Mass.
- Initial paint payload.
- Bounce coefficient.
- Friction.
- Linear damping.
- Angular damping.
- Maximum lifetime.
- Minimum movement speed.
- Stop duration.
- Paint stamp radius.
- Impact splash radius.
- Deposit rate.
- Maximum number of mechanism activations.

Use a fixed physics timestep.

Prevent tunneling at high launch speeds.

A projectile should stop being active when any of the following occurs:

- Paint payload reaches zero.
- It remains below a low-speed threshold for a specified duration.
- It falls outside the stage boundary.
- It exceeds its maximum lifetime.
- It is consumed by a mechanism such as the Splitter Node.

==================================================
10. PAINT BEHAVIOR
==================================================

Do not build a full real-time fluid simulation.

Instead, create a deterministic paint system that visually suggests thick paint responding to gravity.

The result should include:

- A splash at strong impacts.
- A continuous trail while the ball rolls or slides.
- Wider paint marks when more paint remains.
- Smaller marks as the payload is depleted.
- Limited downhill flow from some deposits.
- Small puddles on flatter areas.
- No infinite spreading.
- No paint appearing on surfaces the ball never reached unless caused by a mechanism.

The paintball has a finite paint payload.

Depositing paint reduces the remaining payload.

Suggested behavior:

- Airborne movement does not consume paint.
- Direct impact produces a radial splash.
- Surface contact deposits paint at regular time or distance intervals.
- Rolling slowly creates a narrower, denser trail.
- Fast sliding creates a longer, slightly thinner trail.
- A strong collision creates a larger temporary splash effect.
- A final small puddle appears when the ball stops with paint remaining.

For the first prototype, use a low-poly heightfield-style mountain without caves or overhangs. This makes a world-space paint mask practical and reliable.

Recommended implementation:

- Define the mountain’s paintable area in world X/Z coordinates.
- Maintain a grayscale runtime paint mask.
- Map world X/Z positions into paint-mask coordinates.
- Stamp circles, elongated marks, and short downhill trails into the mask.
- Use the same mask as the source of truth for:
  - Visual terrain paint.
  - Coverage calculation.
- Use a separate eligible-surface mask to identify which pixels count toward coverage.
- Do not count:
  - The cannon platform.
  - Background mountains.
  - The underside of the stage.
  - Mechanism meshes.
  - Decorative trees and rocks.
  - Non-playable boundary geometry.

A 512×512 mask is acceptable for the first prototype. Use 1024×1024 only if performance remains stable.

Prefer a GPU render-target approach if it remains simple and reliable. A batched CPU mask is acceptable if it meets the performance target.

Coverage calculation:

coverage =
number of eligible pixels whose paint value exceeds the painted threshold
divided by
total number of eligible pixels

Do not double-count overlapping paint.

Update the visible coverage number several times per second rather than every rendered frame.

Provide a debug mode that shows:

- Eligible paintable area.
- Painted pixels.
- Excluded area.
- Current calculated coverage.
- Recent paint stamps.

==================================================
11. OPTIONAL LIGHTWEIGHT DOWNHILL FLOW
==================================================

To make paint appear influenced by gravity, implement a lightweight terrain-grid flow pass.

This is not a true liquid simulation.

For a paint deposit with sufficient remaining volume:

1. Sample the terrain height at the current mask cell.
2. Inspect neighboring cells.
3. Find one or more lower neighbors.
4. Transfer a limited amount of paint to those cells.
5. Repeat for a small fixed number of steps.
6. Stop when:
   - No lower neighbor exists.
   - The flow budget has been exhausted.
   - The transferred paint becomes too small.
   - The path reaches a boundary.

Use this to create short rivulets below impact points and mechanisms.

Keep the flow:

- Finite.
- Reproducible.
- Readable.
- Cheap to simulate.
- Limited enough that the projectile route remains the primary source of coverage.

==================================================
12. TERRAIN MECHANISMS
==================================================

Implement exactly three mechanisms for the vertical slice.

All mechanisms must use a common base interface and be data-driven.

A. Burst Node

Purpose:
- Reward hitting a difficult location.
- Create immediate local coverage.

Behavior:
- Activates when physically struck by a paintball.
- Paints a circular or terrain-aware area around the node.
- Produces a strong radial splash effect.
- Has a clearly visible activation animation.
- Has a configurable number of charges.
- Default MVP charge count: one activation per stage.
- Changes appearance after being spent.

The Burst Node should add paint directly to the authoritative paint mask.

B. Splitter Node

Purpose:
- Turn one incoming route into several downhill routes.

Behavior:
- Consumes the incoming ball.
- Spawns three smaller child paintballs.
- Child balls travel in a visible fan pattern.
- The total paint payload must remain controlled.
- Do not triple the full incoming payload.

Recommended payload behavior:
- Each child receives approximately 30% of the incoming remaining payload.
- Approximately 10% may be lost during splitting.

Prevent infinite recursive splitting:
- Mark child balls as already split, or limit the maximum split generation.
- Default maximum split generation: one.

C. Bumper Node

Purpose:
- Redirect a ball toward another slope or mechanism.

Behavior:
- Applies a strong impulse in a visually indicated direction.
- Does not consume the projectile.
- Has a short cooldown to prevent unstable repeated triggering.
- Shows its launch direction before firing.
- Produces a distinct impact sound and animation.

Mechanism presentation:

- During briefing, mechanisms may display their names and functions.
- During aiming, use compact icons or subtle outlines.
- During projectile movement, avoid persistent text labels.
- On activation, briefly display the mechanism name or icon.
- Mechanism scale must not make the mountain appear miniature.

Future mechanisms that may be documented but must not be implemented in the MVP:

- Teleporter.
- Booster.
- Sticky surface.
- Paint amplifier.
- Drain.
- One-way gate.
- Rotating bumper.
- Timed mechanism.

==================================================
13. STAGE DESIGN
==================================================

Create three fully playable stages.

Each stage must have at least one intended successful route and should be manually tested.

Stage 1: First Descent

Purpose:
- Teach aiming, impact, rolling, and coverage.

Characteristics:
- One large readable mountain slope.
- No mechanisms.
- Several broad downhill paths.
- Low target coverage.
- Three or four shots.
- The player can clear the stage without precision.

Stage 2: Burst Basin

Purpose:
- Teach the Burst Node and the value of landing high.

Characteristics:
- A tall upper ridge.
- A visible Burst Node on a difficult ledge.
- A broad basin below it.
- Hitting the node should create a useful chain of downhill coverage.
- Moderate target coverage.
- Four or five shots.

Stage 3: Split Ridge

Purpose:
- Teach route planning through multiple mechanisms.

Characteristics:
- Two or three major downhill channels.
- One Splitter Node positioned near an upper route.
- One Bumper Node that can redirect a ball toward the splitter or a secondary channel.
- A direct low route that is safe but inefficient.
- A more difficult high route that can create much greater coverage.
- Five or six shots.
- Target coverage around 70%.

Each stage requires:

- Stage ID.
- Display name.
- Terrain scene or terrain data.
- Cannon transform.
- Camera bookmarks.
- Target coverage.
- Maximum shots.
- Paint color.
- Mechanism list.
- Mechanism states.
- Paintable-area mask.
- Out-of-bounds volume.
- Result thresholds.
- Best result data.
- Tutorial prompts, if any.

Store these values in reusable stage-data resources rather than hardcoding them inside individual scripts.

==================================================
14. SCORING AND RESULTS
==================================================

The main success condition is target coverage.

Do not make the basic objective dependent on score.

Clear condition:
- Current coverage is greater than or equal to target coverage after all projectiles and paint effects settle.

Failure condition:
- No shots remain and current coverage is below the target.

Result screen must show:

- Stage name.
- Final coverage.
- Target coverage.
- Shots used.
- Shots remaining.
- Best previous coverage.
- New-best indicator, when relevant.
- Star or rank result.
- A small live or recorded view of the final mountain.
- Retry.
- Next stage.
- Stage select.
- Replay.

Keep star thresholds inside stage data.

Suggested interpretation:

- One star: stage target reached.
- Two stars: stage-specific improved coverage threshold reached.
- Three stars: stage-specific excellent threshold reached.

Shot efficiency may be used as a secondary condition, but do not allow it to make the result difficult to understand.

==================================================
15. REQUIRED UI SCREENS
==================================================

Implement the following as separate full-screen interfaces.

Do not combine them into one poster, dashboard, contact sheet, or concept board.

1. Main menu

Required elements:
- Working title.
- Play.
- Stage Select.
- Settings.
- A large background view of a distant painted mountain.
- Minimal additional information.

2. Stage select

Required elements:
- Stage cards or a simple stage grid.
- Locked and unlocked states.
- Best star result.
- Best coverage result.
- Selected stage preview.
- Target coverage.
- Maximum shots.
- Mechanisms present.
- Start button.
- Back button.

3. Stage briefing and terrain inspection

Required elements:
- Large mountain view.
- Limited orbit and zoom.
- Objective.
- Target coverage.
- Available shots.
- Mechanism markers.
- Short mechanism descriptions on selection.
- Start Aiming button.
- Back button.

4. Aiming screen

Required layout:
- Top left: stage identifier.
- Top center: target coverage.
- Top right: shots remaining.
- Bottom left: angle and power.
- Bottom center: current coverage bar.
- Bottom right: restart and fire.
- Cannon in lower foreground.
- Mountain filling the middle and upper view.
- Dotted trajectory.
- Minimal reticle.

5. Projectile and paint-observation screen

Required behavior:
- Hide or reduce aiming controls.
- Keep shots remaining and coverage visible.
- Show pause.
- Show camera-mode control.
- Show optional 1× and 2× simulation speed.
- Keep the projectile, active mechanisms, and painted route readable.

6. Stage-clear screen

Required elements:
- Clear message.
- Final coverage.
- Target coverage.
- Shots used.
- Rank or stars.
- Final mountain preview.
- Retry.
- Next stage.
- Stage select.
- Replay.

7. Stage-failed screen

Required elements:
- Target not reached.
- Final coverage.
- Missing coverage amount.
- Retry as the primary action.
- Stage select.
- Replay.

8. Pause menu

Required elements:
- Resume.
- Restart.
- Settings.
- Stage select.
- Quit to main menu.

9. Settings

Required initial settings:
- Master volume.
- Music volume.
- Sound-effect volume.
- Camera shake.
- Projectile-follow camera.
- Trajectory preview.
- Fullscreen.
- Resolution.
- Graphics quality.
- Language architecture, even if English is the only initial language.

==================================================
16. UI AND UX DIRECTION
==================================================

The interface must be extremely simple.

Visual direction:

- Off-white or translucent light panels.
- Dark charcoal or navy text.
- One saturated paint color as the primary accent.
- Soft shadows.
- Rounded corners.
- Clear sans-serif typography.
- Large buttons.
- Consistent spacing.
- Very limited decorative UI.
- No dense text blocks during gameplay.
- No visual style that resembles a complex simulator dashboard.
- No mobile free-to-play storefront appearance.

Important information hierarchy:

1. Target coverage.
2. Current coverage.
3. Shots remaining.
4. Aim and power.
5. Fire and restart.
6. Secondary controls.

Do not use persistent tooltips over the mountain during ordinary gameplay.

Use animation sparingly:

- Coverage numbers smoothly count upward.
- Buttons have subtle hover and press feedback.
- Mechanism icons briefly pulse when activated.
- The result panel appears after the mountain becomes readable.
- Avoid excessive panel movement.

Support a standard 16:9 desktop display first.

Design layouts using anchors and containers so common desktop resolutions remain usable.

==================================================
17. ART DIRECTION
==================================================

Use a clean low-poly 3D style.

Terrain:

- Large angular mountain forms.
- Readable ridges and valleys.
- Gray, beige, or desaturated rock.
- Flat or lightly faceted shading.
- Sparse simple trees and rocks.
- No photorealistic textures.
- No excessive detail that hides paint routes.
- No caves or overhangs in the first version.

Paint:

- Bright saturated blue for the prototype.
- Glossy enough to contrast with the dry terrain.
- Clearly visible from a distance.
- Thick splashes and trails.
- Limited reflective response.
- Avoid expensive transparent-liquid rendering.
- Do not make the paint look like a flat neon emissive texture.

Cannon:

- Simple stylized industrial design.
- Clear barrel direction.
- Visible pivot and elevation movement.
- Small relative to the mountain.
- Dark gray body with restrained blue accents.

Mechanisms:

- Use white, gray, and blue.
- Give every mechanism a distinct silhouette.
- Make the active direction readable.
- Keep mechanism proportions consistent with the large world scale.

Environment:

- Soft daylight.
- Simple sky gradient or lightweight sky.
- Subtle distant mountain silhouettes.
- One primary directional light.
- Restrained ambient occlusion.
- Light shadows that communicate form.
- No heavy cinematic post-processing.
- No intense depth of field that makes the mountain unreadable.

==================================================
18. AUDIO AND FEEDBACK
==================================================

Implement a small but clear sound set:

- Cannon rotation.
- Power adjustment tick.
- Cannon firing.
- Projectile travel or wind sound.
- Soft terrain impact.
- Hard impact.
- Paint splash.
- Rolling paintball.
- Burst Node activation.
- Splitter Node activation.
- Bumper Node activation.
- Coverage milestone.
- Stage clear.
- Stage failure.
- Button hover and press.

Use restrained camera shake:

- Small shake on firing.
- Small shake on major impact.
- Slightly stronger shake on Burst Node activation.
- Never shake continuously while the ball rolls.

Use particles for:

- Muzzle discharge.
- Impact droplets.
- Burst activation.
- Split activation.
- Bumper impact.
- Stage clear.

Pool frequently created effects when practical.

==================================================
19. TECHNICAL ARCHITECTURE
==================================================

Use modular systems with clear responsibilities.

Recommended major components:

GameState
- Global stage progression.
- Save data.
- Settings.
- Best results.

StageController
- Owns the stage state machine.
- Tracks shots.
- Tracks coverage.
- Determines clear and failure.
- Coordinates camera and UI states.

StageData
- Data resource containing all configurable stage values.

CannonController
- Horizontal rotation.
- Elevation.
- Power.
- Trajectory preview.
- Projectile creation.

PaintProjectile
- Rigid-body physics.
- Paint payload.
- Paint deposition.
- Mechanism interaction.
- Stop and lifetime logic.

ProjectileManager
- Tracks all active parent and child projectiles.
- Reports when the shot is fully settled.
- Cleans up on restart.

PaintSystem
- Owns the paint mask.
- Applies stamps.
- Runs lightweight downhill flow.
- Calculates coverage.
- Clears stage paint.
- Drives the terrain shader.

GimmickBase
- Shared activation interface.
- Shared state and reset behavior.

BurstNode
SplitterNode
BumperNode
- Individual mechanism implementations.

CameraDirector
- Briefing camera.
- Aiming camera.
- Projectile camera.
- Wide camera.
- Result camera.
- Smooth transitions.

HUDController
- Updates all gameplay UI.
- Reacts to state changes.
- Does not contain game rules.

ReplayRecorder
- Stores stage ID.
- Stores random seed.
- Stores every shot’s yaw, elevation, and power.
- Stores relevant timing or event data only if deterministic resimulation is insufficient.

SaveSystem
- Stores unlocked stages.
- Best coverage.
- Best stars.
- Settings.
- Version number.

Keep data, presentation, and game rules separate.

Do not hardcode stage-specific node paths into global scripts.

Use signals or another clear event system for:

- Shot fired.
- Projectile impact.
- Paint deposited.
- Mechanism activated.
- Projectile stopped.
- Shot settled.
- Coverage changed.
- Stage cleared.
- Stage failed.

==================================================
20. REPLAY AND DETERMINISM
==================================================

Record enough information to reproduce a completed attempt.

At minimum, save:

- Stage identifier.
- Stage version.
- Physics seed.
- Shot order.
- Cannon yaw.
- Cannon elevation.
- Firing power.
- Optional camera choices.

Prefer deterministic resimulation over recording every projectile transform.

If deterministic replay cannot be guaranteed across sessions, record projectile transforms at a low fixed frequency and interpolate them during playback.

Replay controls:

- Play.
- Pause.
- Restart replay.
- 1× speed.
- 2× speed.
- Scrubbing is optional for the MVP.

==================================================
21. FUTURE AI-PLAYABILITY HOOK
==================================================

Design the gameplay layer so an external AI agent can later play the game without controlling the mouse or reading the screen.

Do not build a network service yet.

Provide a clean in-process observation and action interface.

Suggested observation data:

- Stage ID.
- Target coverage.
- Current coverage.
- Shots remaining.
- Cannon yaw.
- Cannon elevation.
- Cannon power.
- Terrain bounds.
- Simplified terrain height grid.
- Mechanism type, position, direction, and state.
- Previous shot parameters.
- Previous shot coverage gain.
- Previous shot mechanism activations.
- Whether the game is ready for another action.

Suggested actions:

- Set cannon yaw.
- Set cannon elevation.
- Set firing power.
- Fire.
- Restart.
- Change camera.
- Start next stage.

Suggested event stream:

- Shot started.
- Projectile impacted.
- Projectile bounced.
- Mechanism activated.
- Projectile split.
- Coverage increased.
- Shot settled.
- Stage cleared.
- Stage failed.

Keep this interface independent of the human UI so it can later support:

- LLM-controlled gameplay.
- Automated testing.
- Bot tournaments.
- Twenty-four-hour streaming.
- Replay analysis.
- Procedural stage evaluation.

==================================================
22. PERFORMANCE REQUIREMENTS
==================================================

Target:

- Stable 60 FPS at 1920×1080 on modest Windows hardware.
- Fast stage restart.
- Low memory use.
- Short loading times.
- No expensive real-time fluid simulation.
- No requirement for high-end GPU features.

Guidelines:

- Keep mountain geometry reasonably low-poly.
- Prefer one principal terrain mesh per stage.
- Batch paint-mask updates.
- Pool particles and temporary objects.
- Avoid creating one decal node for every paint stamp.
- Avoid large numbers of rigid bodies remaining active after a shot.
- Put inactive projectiles to sleep or remove them.
- Limit child projectile count.
- Use lightweight shadows.
- Avoid real-time global illumination.
- Avoid unnecessarily high-resolution textures.
- Do not update coverage by reading a full high-resolution texture every frame.

Suggested initial limits:

- Maximum simultaneous paintballs: 8.
- Maximum split generation: 1.
- Maximum active particle systems: controlled through pooling.
- Paint mask: 512×512 initially.
- Terrain mesh: preferably below approximately 50,000 triangles per stage.
- Restart time: under one second after user confirmation.
- Stage load time: preferably under three seconds on local storage.

==================================================
23. DEBUGGING TOOLS
==================================================

Create a developer debug overlay that can be toggled without changing release behavior.

Include:

- Current game state.
- Current FPS.
- Active projectile count.
- Projectile velocity.
- Projectile remaining paint.
- Current coverage.
- Coverage added by the current shot.
- Paint-mask preview.
- Eligible-surface-mask preview.
- Trajectory samples.
- First predicted collision.
- Mechanism activation state.
- Physics seed.
- Stage bounds.
- Camera mode.
- Restart timing.

Provide debug actions:

- Refill shots.
- Clear paint.
- Force stage clear.
- Spawn a test projectile.
- Toggle slow motion.
- Toggle paint-flow simulation.
- Toggle mechanism labels.
- Save current aim parameters.
- Replay the last shot.
- Export a short shot-result log.

Debug UI must be disabled by default in release builds.

==================================================
24. IMPLEMENTATION PHASES
==================================================

Work in this order.

Phase 1: Repository and project setup

- Inspect the existing repository.
- Identify the engine, project conventions, and existing assets.
- Create or update the project structure.
- Write a brief implementation plan.
- Set up one test scene.
- Confirm the project launches.

Phase 2: Cannon and projectile sandbox

- Build the cannon.
- Implement yaw, elevation, and power.
- Implement trajectory preview.
- Implement the basic rigid-body paintball.
- Add a simple mountain slope.
- Validate bounce, roll, slide, and stop behavior.
- Validate deterministic repeated shots.

Phase 3: Paint system

- Implement the paintable terrain mask.
- Implement impact splashes.
- Implement rolling trails.
- Implement coverage calculation.
- Make the terrain shader display the same paint mask.
- Add coverage debug visualization.
- Add lightweight downhill flow only after the basic trail works.

Phase 4: Stage loop and camera

- Implement the state machine.
- Implement briefing, aiming, projectile, wide, and result cameras.
- Add shot limits.
- Add clear and failure conditions.
- Add restart.
- Add the gameplay HUD.

Phase 5: Mechanisms

- Implement the common mechanism interface.
- Add Burst Node.
- Add Splitter Node.
- Add Bumper Node.
- Confirm all mechanisms reset correctly.
- Confirm all mechanism paint contributes to the same coverage mask.

Phase 6: Content

- Build the three stages.
- Tune target coverage and shot counts.
- Ensure every stage has at least one reliable solution.
- Add tutorials only where necessary.
- Add stage progression and saving.

Phase 7: Presentation

- Implement main menu.
- Implement stage select.
- Implement briefing UI.
- Implement result screens.
- Add simple audio.
- Add particles and restrained camera feedback.
- Improve visual readability.

Phase 8: Testing and delivery

- Test common resolutions.
- Test stage restarts repeatedly.
- Test projectiles leaving the map.
- Test split-ball limits.
- Test saved progression.
- Test result accuracy.
- Test replay.
- Verify performance.
- Produce the required screenshots and documentation.

Do not begin monetization, online systems, or content expansion before all Phase 8 acceptance criteria pass.

==================================================
25. ACCEPTANCE CRITERIA
==================================================

The vertical slice is complete only when all of the following are true.

Gameplay:

- The player can select and start all three stages.
- The player can inspect the terrain.
- The player can aim using yaw, elevation, and power.
- The trajectory preview closely matches the real initial flight.
- The paintball reliably collides with the terrain at high speed.
- The paintball bounces, rolls, slides, and stops.
- The paintball visibly leaves paint.
- Visual paint and calculated coverage share one source of truth.
- Overlapping paint is not counted twice.
- Burst, Splitter, and Bumper mechanisms work correctly.
- The stage clears at the target coverage.
- The stage fails when shots are exhausted.
- Restart returns the stage to a clean initial state.
- Every stage has at least one tested solution.

Composition:

- The cannon remains in the lower foreground during aiming.
- The mountain dominates the middle and upper frame.
- The mountain does not look like a small tabletop object.
- Major routes and mechanisms remain readable.
- The camera does not clip through the mountain.
- Gimmicks are readable without appearing absurdly large.

UX:

- Target coverage, current coverage, and shots remaining are always understandable.
- The player can restart quickly.
- The interface is not cluttered.
- Aiming controls disappear or reduce during projectile observation.
- Result actions are immediately available.
- There are no shop, currency, or live-service interfaces.

Technical quality:

- No recurring errors in the console during normal play.
- No orphaned projectiles after restart.
- No duplicated mechanism activation caused by one collision.
- No infinite splitter loop.
- No major frame-rate collapse during large paint events.
- Save data survives a normal restart.
- The project can be launched using documented steps.
- The code is organized according to system responsibility.

==================================================
26. REQUIRED DELIVERABLES
==================================================

Provide:

1. A playable project.
2. A README containing:
   - Engine version.
   - Launch instructions.
   - Controls.
   - Project structure.
   - Known limitations.
3. A concise design specification.
4. A concise technical architecture document.
5. A test checklist.
6. Three completed playable stages.
7. Separate screenshots captured from the running game.

Required screenshot files:

- 01_main_menu.png
- 02_stage_select.png
- 03_stage_briefing.png
- 04_aiming.png
- 05_projectile_and_paint_flow.png
- 06_stage_clear.png
- 07_stage_failed.png

Each screenshot must be:

- A separate full-resolution image.
- Captured from the actual running project.
- Free of debug overlays unless explicitly labeled as a debug screenshot.
- Representative of the intended camera composition.

Never replace these individual screenshots with:

- A contact sheet.
- A collage.
- A poster.
- An infographic.
- A single image containing several tiny screens.

Also provide:

- A short list of files changed.
- A short explanation of major implementation choices.
- Test results.
- Performance observations.
- Remaining known issues.
- Recommended next development step.

==================================================
27. WORKING RULES
==================================================

Follow these rules throughout development.

- Preserve the core concept.
- Prioritize the playable loop over peripheral features.
- Do not redesign the game into a generic artillery game.
- Do not redesign it into a shooter with character movement.
- Do not make the mountain small to fit the cannon beside it.
- Do not make the physics intentionally chaotic.
- Do not add randomness unless it is seeded and justified.
- Do not add several projectile types before the basic ball is satisfying.
- Do not use a full fluid simulation.
- Do not hide technical limitations behind fake UI mockups.
- Do not claim a feature works unless it has been run and tested.
- Do not produce only documentation.
- Do not modify unrelated repository files.
- Prefer simple, robust implementations over impressive but fragile systems.
- Keep the project playable after every implementation phase.
- When a requirement cannot be completed, state exactly what failed, why it failed, and what remains.
- When presenting progress, show actual separate gameplay screens rather than a single composite overview.

The final product should feel like a clean, focused puzzle game built around one strong question:

“Where should I launch this paintball so gravity, terrain, and mechanisms cover the greatest possible area?”

## Later User Supersessions (2026-08-03)

The user explicitly revised the following parts of the baseline directive. These
decisions are requirements, not optional interpretations:

- **Paint behavior:** replace finite paint payload, payload depletion, trail
  narrowing caused by depletion, and autonomous downhill paint flow. A ball
  persistently paints the scoreable target-top surface it physically traverses
  while in contact. Real first-impact, settlement, and Burst radial marks remain
  allowed, but airborne travel and contacts with the non-target shell, apron,
  backstop, or mechanisms never create persistent paint. One authoritative
  `PaintSystem` mask drives both the visible paint and coverage; coverage is the
  painted fraction of the immutable `target_mask`, with overlap counted once.
- **Terrain and physical truth:** generate one deterministic route-graph mountain
  with exactly one playable top height for every in-bounds XZ position. Broad
  rollable slopes, terraces, ridges, valleys, and pads are allowed; caves,
  overhangs, tunnels, stacked tops, detached route pieces, and literal stair
  risers are not. Rendering, top collision, hit classification, height/normal
  queries, target rasterization, and paint reconstruction must consume the same
  emitted indexed top-triangle list and fixed cell diagonal. A separate
  height-map collider, bilinear surface query, visual displacement, or query-only
  playable geometry cannot substitute for that shared surface.
- **Reachability, initial aim, and containment:** every scoreable target texel
  must have a legal manual yaw/elevation/power tuple whose first physical hit is
  that same target-top triangle. The generated default aim must select a certified
  first hit near the target-mask centroid and be reapplied on stage start and
  restart. A visible, collidable bright off-white rear wall and matching faceted
  apron contain the current board so legal shots cannot pass through or over the
  play space. Backstop contact is non-scoreable, creates no paint or bank shot,
  and terminates the ball. Ordinary terrain uses low rebound; Bumper is the only
  intentional strong-redirect exception.
- **Special features:** the approved special gameplay features remain exactly
  Burst, Splitter, and Bumper. They must be physical 3D objects with collider-
  matched visible mass, distinct semantic colors and silhouette cues, forgiving
  activation neighborhoods, and verified useful-but-not-automatic effects. This
  revision does not add ice, sticky, booster, drain, or other special-terrain
  material classes.
- **Gameplay HUD and game menu:** replace bottom-center coverage and the
  bottom-right Restart/Fire pair. Show coverage as a left-edge vertical gauge
  with authoritative absolute percentage text and goal-relative bottom-to-top
  fill; place Fire alone at bottom-center; keep shots plus a focusable gear button
  at top-right. Gear and Escape open the same fully input-capturing paused game
  menu with Continue, Restart, Settings, Stage Select, and Main Menu. Restart is
  not visible in the aiming HUD and is never part of the Settings form; the `R`
  quick-restart shortcut remains.
- **Concept-image authority:** the liked concept board is an art/read-direction
  comparator for composition, warm off-white palette, low-poly faceting,
  apparent thickness, route/mechanism readability, and paint contrast. Its exact
  HUD positions, terrain silhouette or seed, literal stairs, mechanism placement,
  and painted still-state topology are not implementation requirements. Runtime
  geometry and paint must remain consequences of the shared physical surface and
  verified contacts rather than being fabricated to match an image.

All baseline clauses not named above remain in force.

## Later User Supersession (2026-08-04): Open Progression and Faster Play

The user explicitly revised the following product requirements after inspecting
the current implementation. These revisions override conflicting three-stage,
single-shot-wait, paint-scale, pacing, and HUD clauses above:

- **Open stage progression:** provide approximately thirty stages and make every
  stage selectable from the beginning. Stage availability is no longer an unlock
  reward or a selection gate.
- **Immediate repeat firing:** firing the cannon must not lock the player out
  until the previous ball has completely stopped. The player may immediately
  adjust the next aim and fire again, while already launched balls remain purely
  physical and cannot be steered.
- **Projectile and paint scale:** increase the visible paintball and reduce the
  traversed paint footprint from the current implementation. The selected result
  must be a readable midpoint: paint remains wider than the physical ball, but
  no longer looks unrelated to its contact area.
- **Gradual stage growth:** stages increase progressively rather than through
  abrupt jumps. Later stages use somewhat larger mountain ranges, more broad
  rises and descents, more route undulation, more decorations, and more visible
  Burst/Splitter/Bumper placements. Growth must not reintroduce spikes, holes,
  detached boards, or unreasonably frustrating layouts.
- **Approximately doubled cadence:** normal play should feel about twice as fast
  overall. This is a pacing requirement, not permission to reduce fixed-step
  collision or paint-contact correctness.
- **HUD and typography:** replace the ambiguous top `follow/cannon/1x/2x` strip
  with grouped, icon-supported controls whose state and effect are immediately
  understandable. Redesign the layout around the established sparse edge HUD,
  use Pretendard with clearly bold hierarchy, keep Korean as the default, and
  retain Fire as the single bottom-center primary action.

All earlier requirements not contradicted here remain in force.

## Later User Clarification (2026-08-05): Gameplay Contract Recovery

The user inspected Stages 04 and 05 and the current firing loop, then made the
following requirements explicit. These clauses clarify the 2026-08-04
progression, repeat-fire, reachability, and scale requirements; they are not
optional polish:

- **Per-stage terrain difficulty:** adjacent stages must not merely clone one of
  a few terrain templates and change a seed or nominal height. The deterministic
  stage inputs must progressively change player-visible range size, broad
  rises/descents, route undulation, decorations, and mechanism opportunities.
  Stages 04 and 05 are an explicit acceptance pair: they must be measurably and
  visibly distinct while remaining gradual and free of spikes, holes, and abrupt
  scale jumps.
- **Summit reachability:** in addition to the existing target-wide reachability
  rule, every accepted stage must have at least one legal manual
  yaw/elevation/power tuple whose first physical terrain contact reaches the
  stage's global highest playable top region. A rear or foreground ridge may not
  occlude every legal trajectory to the summit. The default aim remains near the
  target-mask centroid; it does not become an automatic summit solution.
- **Usable immediate re-aiming:** accepting a Fire action must leave the next
  yaw, elevation, and power controls immediately editable. The camera,
  trajectory preview, HUD, and prediction-readiness feedback must also keep the
  next shot visibly aimable while earlier balls move. Controller-level support
  without a usable aiming view does not satisfy this requirement.
- **Projectile/paint scale acceptance:** the current `0.60 m` ball,
  `2.25 m` traversed/settlement radius, and `3.20 m` impact radius remain too far
  apart in the running game and are not an accepted midpoint. The next contract
  must make the physical/visible ball materially larger and the traversed paint
  materially narrower, then prove the relationship from real contact and the
  authoritative mask.
- **Completion truth:** catalog enumeration, permissive smoke checks, or partial
  controller support cannot be reported as completion of a stronger ExecPlan.
  Implemented-status records and plan checkboxes must match the actual code and
  production-style evidence.

All earlier requirements not contradicted here remain in force.

## Later User Supersession (2026-08-06): Range-Aware Generation and Responsive Preparation

The user stopped the prior long-running recovery session and explicitly changed
the immediate implementation priority. These clauses extend the terrain and
navigation requirements without weakening the separate first-physical-hit
certification contract:

- **Generation-time ballistic admission:** terrain generation must include the
  cannon's legal projectile domain as a candidate constraint. Every scoreable
  target sample must be inside the legal yaw fan, damped horizontal horizon, and
  reachable-height envelope derived from the stage cannon transform, projectile
  tuning, fixed 60 Hz step, and prediction horizon. A failing sample rejects the
  whole terrain candidate; generation must not shrink or otherwise redefine the
  configured scoreable footprint to pass.
- **Summit domain admission:** every accepted terrain must have at least one
  canonical highest-region sample inside the same analytic projectile domain.
  This fast code-level gate is not by itself a claim that terrain occlusion or
  first physical contact has been certified.
- **Responsive stage preparation:** a cold layout must not be generated
  synchronously during page navigation or Start. The application must prepare
  deterministic seed-derived layouts away from the main navigation path, retain
  only a small bounded set for the selected/current/next stages, and keep
  scene/render/physics world construction on the main thread. While a requested
  layout is not ready, the visible page must remain responsive and state that
  preparation is in progress truthfully.

All earlier requirements not contradicted here remain in force.

## Later User Supersession (2026-08-06): Persistent Wind-Driven Coverage Loop

The user explicitly revised the projectile lifetime, wind, completion,
mechanism, camera, and HUD requirements after inspecting the current running
game. These clauses override only the conflicting earlier clauses:

- **Persistent terrain paintballs:** a paintball has no finite paint payload.
  Once it has reached valid playable mountain top, age, low speed, and the
  engine's sleeping state must not delete it during the run. The rigid body may
  sleep naturally for performance and must remain present so collision or
  strong wind can move it again. Explicit mechanism consumption, real escape,
  a never-contacted miss timeout, unrecoverable invalid geometry, and stage
  cleanup are the only pre-result termination families.
- **Terrain contact recovery and paint:** a valid top traversal always produces
  visible paint, including outside the scoreable mask; only overlap with the
  authoritative target mask increases coverage. A stationary ball does not
  repeat paint at one point, and resumed movement paints only its new physical
  path. Terrain embedding is recovered from the authoritative surface and
  physical radius instead of being treated as an ordinary deletion outcome.
- **Wind:** one deterministic, stage-seeded wind changes on a readable
  30-second rhythm with a natural three-second transition. It affects both the
  trajectory preview and real projectile physics. Strong wind can wake
  terrain-resting balls, while small leaves or debris provide restrained world
  motion. A HUD cue must show the direction that projectiles are pushed,
  strength, time to change, and the approaching direction during the
  transition; world particles are supplementary, not the sole rule cue.
- **Timed coverage result:** the first actual launch starts a stage duration of
  90, 120, or 180 seconds according to progression. Reaching target coverage or
  spending all shots does not auto-end or fail the run. The player may use a
  Finish action after the first shot, or the timer ends the run. The sole score
  is final unique target coverage; existing star thresholds remain grades.
- **Surface glyph mechanisms:** Burst, Splitter, and Bumper are no longer
  physical raised 3D obstacles. They become terrain-conforming flat circular
  glyphs activated by a real valid-top contact inside their visible footprint.
  Burst applies its large paint effect and consumes the ball; Splitter keeps a
  readable three-way useful branch; Bumper becomes Uphill Rebound and sends the
  ball toward the locally highest meaningful direction. Small stages may have
  no glyph or one or two; larger stages may contain more. Additional mechanism
  ideas remain future candidates, not part of this implementation slice.
- **Aim lock and map inspection:** the Follow/Wide/Cannon camera preset strip
  and its gameplay 1x/2x/Pause actions are removed. Gameplay has two clear
  interaction modes while stage rules remain in the aiming phase. The then-current
  Aim Lock gesture used pointer-angle drag and wheel control (superseded by the
  2026-08-08 terrain-targeted Aim View revision); keyboard aiming and Fire were
  available, and the authored aiming camera was restored. In Map Inspection, a
  terrain click changes inspection focus, left drag orbits the
  safe camera, the wheel zooms, and aim/Fire inputs are blocked. Tab and one
  visible focusable toggle switch modes without changing the stored aim or
  preview. Briefing starts in inspection; Start enters Aim Lock. Gear and Escape
  remain the only pause/settings entry, and ordinary gameplay exposes no time
  scaling.
- **HUD and visual acceptance:** status remains sparse and edge-aligned. It
  includes time, shots, resident-ball activity, wind, Finish, and the current
  interaction mode without covering the mountain. The ball must become more
  readable and its continuous/impact paint marks must become more natural in
  real contact footage; internal numeric tuning is subordinate to that visible
  result.

All earlier requirements not contradicted here remain in force.

## Later User Supersession (2026-08-06): General Surface Glyph Placement

The user clarified that flat mechanism glyphs must not depend on a fixed
per-stage route-pad coordinate. This clause overrides only the earlier placement
interpretation:

- **General visible-surface search:** the shared generator searches actual
  playable mountain-top surface visible from the cannon/gameplay view, requires
  each full circular footprint to fit with an appropriate boundary and minimum
  inter-glyph distance, and places the requested count deterministically. It
  must not hand-author a world X/Z or add a stage-specific placement branch.
  Mechanism-specific data is derived after common surface eligibility: Uphill
  Rebound uses the locally highest direction, while Splitter retains the branch
  targets needed for its useful three-way effect.
- **Visible wind support:** leaves or debris count as implemented only when their
  motion is readable at the authored distant gameplay scale. They remain
  restrained, supplementary to the HUD, non-colliding, and suppressible by the
  reduced-motion setting.

All earlier requirements not contradicted here remain in force.

## Later User Supersession (2026-08-06): Practical Stage Validation

The user explicitly retired two validation requirements that no longer match
the current Paint Mountain loop. These clauses override the earlier
target-wide reachability and authored-solution language only:

- **Bounded aim validation:** an exhaustive predictor-plus-rigid-body
  first-hit witness for every target texel is not a product requirement,
  release gate, or standing test obligation. Keep the fast analytic
  yaw/horizon/height admission for the configured target and retain bounded
  real first-hit witnesses for the generated default aim and highest playable
  region. Ordinary trajectory, collision, containment, and reported gameplay
  defects remain valid regression scope. A complete
  `DirectReachabilityCertificate` may remain optional diagnostic metadata, but
  its absence is not an implementation gap.
- **No authored success-route contract:** stages do not require a pre-authored
  successful solution route, a solver clear, or an all-stage manual
  playthrough. Generated routes remain terrain-construction and readability
  metadata; they are not prescribed player solutions. Validate representative
  gameplay behavior and investigate concrete play defects without maintaining
  a per-stage success-path checklist.

All earlier requirements not contradicted here remain in force.

## Later User Clarification (2026-08-07): Aiming Freedom and Interaction Responsiveness

The user rejected the current running build's aiming freedom and interaction
responsiveness after the safe-framing and HUD work. These clauses supersede only
interpretations that treat full-point camera containment, mutually exclusive
inspection controls, or passing headless checks as sufficient gameplay
acceptance:

- **Aiming freedom and visibility:** the current fixed Aim Lock experience is
  too restrictive. While choosing manual yaw, elevation, and power, the player
  must be able to retain useful context for the whole mountain and for high or
  distant predicted impact points. Fitting every terrain point somewhere inside
  the viewport is necessary but is not sufficient when the mountain, routes,
  trajectory, or impact marker become too small to use. Camera inspection must
  not overwrite the stored aim.
- **Responsive interaction:** aim input, ordinary button activation, terrain
  refocus and other top/map interactions, and Aim Lock/Map Inspection changes
  must acknowledge immediately and must not produce the observed one-to-two-
  second stalls. Expensive trajectory, camera-framing, layout-hydration, or
  certification work must not run synchronously in an input callback or be
  needlessly restarted at a cadence that blocks the rendered interface. A
  truthful short prediction-pending state is preferable to blocking the click.
- **Preserved puzzle contract:** the cannon remains stationary, the player still
  chooses yaw/elevation/power, and projectiles remain unsteerable after launch.
  This clarification does not restore exhaustive target-wide first-hit
  certification, authored success routes, or all-stage manual playthroughs, and
  it does not by itself approve an inverse click-to-target solver.

All earlier requirements not contradicted here remain in force.

## Later User Supersession (2026-08-07): Cannon Standoff, Wind Flag, and Shot Observation

After reviewing the large-stage aiming composition and wind presentation, the
user revised the visible world and post-Fire camera requirements. These clauses
override conflicting debris, the earlier 15–20% cannon frame cap, fixed Aim
Lock, and immediate cannon-return interpretations only:

- **Wind as a cannon-side world cue:** the primary in-world wind cue is a flag,
  streamer, or windsock mounted beside the stationary cannon. Its orientation
  shows the direction projectiles are pushed and its motion communicates
  strength. The existing HUD remains a concise secondary rule and accessibility
  cue. Generic airborne leaves or debris are not retained as the main wind cue.
- **Physical cannon-to-mountain separation:** stage growth must not move the
  playable mountain progressively closer to the cannon. Every stage preserves a
  deliberate foreground-to-target standoff in world space, with at least 70 m
  from the cannon origin to the nearest playable front; camera scaling alone
  cannot conceal a short physical gap.
- **Aiming composition:** the aiming view presents the cannon as a substantial,
  readable foreground anchor at roughly 20–30% of viewport height while the
  complete playable mountain remains a smaller distant subject inside the view.
  The player still uses the established yaw, elevation, and power controls. This
  revision does not require another pointer gesture or a separate freely
  navigated camera inside the aiming mode; deliberate orbit/zoom inspection
  remains the map-inspection mode.
- **Automatic shot observation:** after an accepted Fire action, the presentation
  camera follows the newly launched root paintball through flight and shows its
  first terrain contact. A visible one-action control returns to the cannon view
  early. Returning changes only the camera: the projectile continues under the
  same physics and cannot be steered. Shot Follow temporarily replaces the aim
  controls on screen; returning immediately restores the stored aim and existing
  repeat-Fire capacity. The impact is held briefly before the normal automatic
  return so contact remains readable.
- **Flight pacing:** approximately three seconds to a representative useful
  first terrain contact is a tuning target, not an exact per-shot time rule.
  Useful shots must not feel immediately adjacent to the cannon or remain in the
  air for an excessive period, and a never-contacted miss must terminate
  promptly. Distance, launch tuning, and camera staging must be considered
  together.
- **Current work boundary:** no performance timing or profiling pass is required
  by this revision. Exhaustive target-wide reachability, solver clears, authored
  success routes, and their obsolete recovery artifacts remain outside the
  current gameplay direction.

All earlier requirements not contradicted here remain in force.

## Later User Supersession (2026-08-07): Fixed Baked Mountain-Range Terrain

After reconsidering run-to-run terrain randomness and the current tall mountain
silhouette, the user revised the terrain-authoring and shape requirements. These
clauses override conflicting runtime-randomization, candidate-selection, and
height-led progression interpretations only:

- **Fixed current terrain authority:** the current terrain family shares one
  canonical fixed seed. Stage and profile identity still make the thirty stages
  distinct, and each stage has one persisted baked layout selected during
  development. Stage entry, retry, replay, and a new process load the same saved
  height, footprint, topology, target, placement, and checksum data. Runtime
  never rolls a terrain seed, searches candidates, or regenerates a missing
  layout.
- **Offline generation only:** the seeded generator remains an authoring tool
  that produces the versioned baked catalog; it is not a gameplay system. A
  corrupt or missing baked layout fails closed. Future terrain variety requires
  a later explicit revision and separately generated, reviewed, persisted
  variants rather than hidden per-run generation.
- **Lower, wider mountain range:** reduce the height-led progression and widen
  the actual connected mountain footprint. The intended aiming-view silhouette
  is a horizontally spread range with several readable rises, terraces, ridges,
  valleys, and route layers rather than one dominant narrow tower. A roughly
  `3:4` height-to-width silhouette is an initial composition reference, not a
  universal geometric law or permission to flatten the playable mass.
- **Difficulty without vertical inflation:** stages may remain distinct through
  route count, branching, reversals, terraces, basins, passes, route width,
  mechanism opportunities, and restrained relief changes. Later difficulty
  must not depend on continually making the highest summit much taller.
- **One physical source:** the persisted baked layout remains the single source
  for render geometry, collision, surface queries, target eligibility, paint
  reconstruction, replay identity, and camera framing. No visual-only widened
  mountain or second terrain representation is permitted.

All earlier requirements not contradicted here remain in force.

## Later User Supersession (2026-08-07): Open Mountain Surface and Fixed Cannon

After clarifying what counts as a terrain surface and whether a deep mountain
requires a movable cannon, the user approved the following direction. These
clauses override conflicting rear-wall, side-containment-wall, wall-join,
all-face-paint, and cannon-position-orbit interpretations only:

- **Open mountain environment:** remove the visible and collidable rear
  backstop and the artificial side containment walls. Do not replace them with
  hidden blocking planes. A restrained non-target ground/apron may remain, but
  the world must read as open rather than as a closed box.
- **Independent closed mountain:** retain meaningful front-to-back depth and a
  substantial 3D mass. The mountain no longer protrudes from or joins a rear
  wall; its generated perimeter support shell and bottom close the physical
  body on every side.
- **Playable Terrain Surface:** this is the continuous one-height-per-XZ
  mountain skin, including cannon-facing slopes, terraces, valleys, ridges,
  summits, and far-side slopes. It does not mean only horizontal or highest
  areas. Contact traversal on this surface may write persistent paint.
- **Support Shell:** the vertical perimeter faces and bottom that close the
  mountain mass are collidable structural faces, not playable terrain. They,
  the apron, decorations, and mechanisms write no persistent paint and never
  contribute coverage.
- **Target Area:** the immutable Target Area is a subset of the Playable Terrain
  Surface. Paint remains visible across valid non-target surface traversal, but
  only painted Target Area overlap contributes coverage.
- **Fixed launch position:** each stage has one baked cannon transform derived
  from the terrain and minimum standoff. The player cannot move the cannon
  around the mountain or select side/rear launch stations. Map View camera orbit
  remains inspection only and never changes the launch position.
- **Open miss handling:** a shot that misses playable terrain may hit the
  non-target apron or Support Shell, cross the explicit open play bounds, or
  reach the never-contacted timeout. Rear/side wall collision and `BACKSTOP`
  settlement are retired; misses never bank from an enclosing wall.
- **Deferred full-surface mode:** painting or scoring the Support Shell,
  triangle-atlas coverage across every exterior face, continuous cannon orbit,
  and discrete launch stations require a later explicit product revision.

All earlier requirements not contradicted here remain in force.

## Later User Clarification (2026-08-07): Approximate Aim Composition

After reviewing the Stage 01 and Stage 30 captures, the user clarified that the
`3:4` terrain ratio and earlier cannon percentages are visual references, not
numeric acceptance gates. These clauses override only exact projected-ratio,
exact foreground-percentage, and complete-silhouette interpretations:

- Preserve the current lower, wider mountain-range result; its exact projected
  height-to-width ratio does not need to equal `3:4` when the composition reads
  approximately that way.
- Aim View is acceptable when the cannon is clearly visible along the lower
  foreground and the mountain's main mass, rises, and useful aiming context are
  readable above it. Minor peripheral terrain cropping is acceptable.
- Do not move the cannon, change terrain geometry, widen FOV, or regenerate the
  baked catalog solely to satisfy an exact camera-composition number.
- Runtime captures and direct visual review decide this composition. Projection
  measurements may diagnose clipping or disappearance but do not pass or fail
  the view by themselves.

All earlier requirements not contradicted here remain in force.

## Later User Supersession (2026-08-07): Truthful Surface Coverage and Responsive Aiming

After direct Stage 10 play, the user revised how coverage, Fire readiness,
manual aim, trajectory updates, and shortcut discovery must work. These clauses
override conflicting raw-target-texel scoring, prediction-gated Fire, hidden
shortcut, transient control-hint, and resolution-scaled mouse interpretations
only:

- **Target surface coverage:** the score is the unique painted physical area of
  the immutable Target Area divided by its total physical area on the Playable
  Terrain Surface. Each target-mask texel is weighted from its canonical terrain
  triangle so steep and flat patches contribute by real surface area rather
  than equal XZ projection area. Camera, FOV, distance, occlusion, and viewport
  size never affect this score.
- **One mutable paint truth:** the existing 512-square paint mask remains the
  sole mutable visual and scoring state. The immutable 512-square target mask
  identifies eligibility; immutable surface-area metadata supplies weights.
  Paint outside the Target Area remains visible but contributes zero.
- **Legible score boundary:** painted Target Area keeps the saturated blue paint
  treatment. Painted valid non-target terrain uses a lighter, less saturated
  treatment so the player can tell what contributes. Visible paint and the HUD
  percentage publish as one presentation batch before result sealing.
- **Prediction is advisory:** `StageController` admits Fire from the legal
  canonical aim, editable board state, shots, root-family capacity, terminal
  state, and action origin only. A pending prediction or a predicted miss never
  disables Fire. A legal miss uses the existing apron, Support Shell, open-bounds,
  and never-contacted-timeout rules.
- **Bounded latest preview:** runtime trajectory prediction keeps at most one
  active resumable job and one newest pending request, advances only a bounded
  number of fixed simulation steps per physics tick, and never publishes a
  stale arc. The last complete arc remains visible but subdued while the newest
  one is prepared; it is replaced atomically rather than cleared.
- **Resolution-stable manual aim:** mouse aim uses physical screen-relative
  motion without manual viewport scaling. Fractional yaw/elevation input is
  retained until it crosses the canonical 0.1-degree step. A persisted
  mouse-only sensitivity setting ranges from 50% to 150% with 100% as default;
  keyboard aim remains unchanged.
- **Persistent contextual shortcuts:** Aim View exposes drag, A/D/W/S, wheel,
  Space Fire, Tab Map View, F Finish when available, and Escape pause. Map View
  exposes its drag/wheel controls and Tab return. Shot Follow exposes Tab return.
  Pause exposes Escape Continue. These are compact control-adjacent keycaps and
  context text, not a central tutorial panel.
- **Retired hidden actions:** remove the four-second first-session hint after the
  persistent prompts exist, and remove the hidden direct `R` restart shortcut.
  Restart remains a visible pause-menu action. F3 remains debug-only and is not
  advertised.

All earlier requirements not contradicted here remain in force.

## Later User Supersession (2026-08-08): Larger Paintball, Attainable Goals, and Hitch-Free Aim Feedback

After reviewing the current aiming hitch and the difficulty of filling the
Target Area, the user authorized implementation without further product choices.
These clauses override only the prior projectile scale, Stage 11-30 target
curve, pending-preview ownership, per-tick preview budget, and normal aiming
calculation-message interpretations:

- **Two-times projectile scale:** use a `2.40 m` root physical/visible radius,
  a `2.80 m` continuous paint radius, and a `3.50 m` impact paint radius. Keep
  mass, launch speed, damping, bounce, friction, wind, and split-child `0.78`
  scale behavior unchanged. The shared launch origin must keep the complete
  sphere outside the barrel and cannon apron at every legal elevation.
- **Attainable clear curve:** preserve Stage 01-10 clear targets (`4.0..8.5%`).
  Set Stages 11-15 to `8.5%`, 16-20 to `9.0%`, 21-25 to `9.5%`, and 26-30 to
  `10.0%`. Preserve existing shot tiers and set star thresholds to clear,
  clear plus `2.5`, and clear plus `5.0` percentage points.
- **Preserve first impact:** keep the approximate first-impact trajectory and
  marker. Do not extend it into a post-contact solution path; rolling, bouncing,
  wind, and mechanisms remain the main outcome after contact.
- **Latest-only preview work:** runtime owns one active prediction job. A newly
  nominated live aim/wind context replaces obsolete active work rather than
  waiting for it. Each physics callback advances at most 12 exact fixed steps
  and stops near a 1 ms main-thread budget, while guaranteeing forward progress.
  Only a still-current context may publish.
- **No aiming wait copy:** normal Aim View shows no trajectory-calculation or
  update text, spinner, or other instruction to wait. The last complete arc and
  marker remain at subdued opacity while the current exact result is pending.
  Fire remains independent of preview readiness.
- **Validation boundary:** automated runtime checks establish scale-dependent
  contact, paint, bounded entry, and performance behavior. They do not create a
  shipping solver, authored successful route, exhaustive target certificate, or
  all-stage manual-clear obligation. Human play remains the owner of feel and
  readability judgments.

All earlier requirements not contradicted here remain in force.

## Later User Supersession (2026-08-08): Terrain-Targeted Aiming and Promised Contact

The user approved a limited revision to the Aim View interaction after reviewing
the current aiming flow. These clauses supersede only the named Aim View gesture,
target solve, explicit human aim-revision readiness, stale impact-marker,
runtime-power precision, and promised terrain-contact lifetime interpretations:

- **Aim View terrain targeting:** in Aim View, a click selects a valid Playable
  Terrain Surface top point and a drag continuously retargets to the latest valid
  top point. The cannon remains stationary. The selected point, not a pointer
  angle, is the human aiming intent; invalid gaps retain the last valid selection
  until release. Map Inspection remains inspection only: its terrain click,
  orbit, and zoom do not select a launch target or change the stored aim.
- **Target-preserving aim edits:** after a selected target, the game solves a
  legal yaw/elevation/power tuple for that point. An explicit elevation edit
  keeps elevation pinned and solves yaw/power; an explicit power edit keeps power
  pinned and solves yaw/elevation. This does not add in-flight steering, an
  authored route, or target-wide reachability certification.
- **Explicit human aim-revision readiness:** only a human target selection or
  target-preserving elevation/power edit creates a pending aim revision. Fire
  waits only until that revision commits a same-revision solution or restores the
  prior committed aim after rejection. Generic advisory-preview pending or miss
  states do not disable Fire, and direct replay, agent, and debug tuple actions
  remain atomic.
- **Truthful target and prediction markers:** the selected target is shown
  independently from an exact current prediction. A confirmed impact marker is
  shown only when its target, aim, and wind revisions match; stale arcs may stay
  subdued, but stale impact or exit markers are hidden. Marker states use shape
  as well as the existing blue role. Preview remains pre-impact only.
- **Runtime power precision and compatibility:** runtime power supports `0.1%`
  precision. Existing whole-power keys and offline generated identities remain
  stable and compatible.
- **Promised terrain-contact lifetime:** when a complete current prediction
  promises a first Playable Terrain Surface contact after the ordinary
  never-contacted timeout, the matching launched root remains alive through that
  promised contact under bounded lifetime tuning. A normal unmatched miss still
  times out, and a real predicted or live open-bounds exit remains immediate.

Stationary-cannon launch planning, no in-flight steering, advisory generic
prediction, Map Inspection, and the ban on post-impact preview remain in force.
All earlier requirements not contradicted here remain in force.

## Later User Supersession (2026-08-08): Casual Shared UI Refresh

After reviewing the current menus and Aim View, the user rejected the current
component detailing, spacing, overlap behavior, and prior mockup as sufficient
visual authority. These clauses supersede only conflicting UI layout-detail,
component-surface, padding, and selected-mockup interpretations:

- **Casual and unobtrusive:** the interface must feel like a simple casual game.
  It uses direct hierarchy, tactile but restrained controls, short copy, and
  enough breathing room to read immediately without covering the mountain,
  cannon, wind flag, selected target, trajectory, or impact.
- **Shared component system:** reusable Theme roles and component scenes remain
  mandatory. Typography, surfaces, radii, borders, focus, selected, hover,
  pressed, and disabled states are owned by the shared Theme rather than copied
  into individual screens.
- **Layout freedom with functional continuity:** Main Menu, Stage Select, and
  gameplay HUD may be recomposed. Preserve all real actions and authoritative
  values, keep Fire as the sole Aim View primary action, and prioritize fixing
  overlap, clipping, insufficient padding, weak grouping, and oversized empty
  surfaces over preserving historical coordinates.
- **External UI texture use:** a small, license-recorded subset of easy-to-source
  game UI panel or button assets may be imported and adapted through shared Theme
  roles. Imported assets do not replace production ownership, introduce fake
  controls, or authorize an unreviewed full asset pack.
- **Concept status:** generated visual alternatives are exploratory until the
  user selects a direction. They do not prove runtime behavior and do not
  silently override the implemented shared component baseline.

Gameplay logic and aiming-algorithm changes remain outside this UI revision and
must be documented in a separate execution contract before implementation.
All earlier requirements not contradicted here remain in force.

## Later User Supersession (2026-08-08): Remove Player Replay

After reviewing the implemented result-screen replay, the user decided that the
feature is not needed. These clauses override only the earlier replay support,
result action, replay/determinism, debug replay, replay-analysis, and replay-test
requirements:

- **No player replay:** remove replay from the result flow. Clear and failure
  results retain Retry, Next Stage when available, and Stage Select.
- **Remove the playback stack:** delete replay recording/serialization,
  deterministic resimulation, playback scheduling, playback input locking,
  replay speed/pause/restart/exit controls, replay localization, replay capture
  cases, and replay-specific tests.
- **Retain independent diagnostics:** shot and attempt observations, the
  UI-independent agent API, deterministic physics behavior, fixed baked-layout
  identity, debug metrics, and debug JSON shot-log export remain supported.
  They must not retain a hidden player-playback path or a replay format.
- **Historical text remains historical:** older plans, evidence, and checked
  results may describe the removed feature, but current specs, implementation
  records, test runners, and release evidence must not claim that it remains
  available.

All earlier requirements not contradicted here remain in force.

## Later User Supersession (2026-08-09): Immediate Aim, Sparse Instruments, and Higher Glyphs

After reviewing the running Settings and Aim View, the user rejected display
resizing during unrelated settings actions, the remaining aim wait, the
panel-and-text-heavy gameplay HUD, detached shortcut annotations, and glyphs
clustered near the mountain base. These clauses supersede only those behaviors:

- **Stable display settings:** opening or synchronizing Settings and changing a
  non-display setting must not reapply window mode or size. Fullscreen and
  resolution apply only from their own explicit actions or a deliberate defaults
  restore.
- **Immediate terrain targeting:** terrain click and drag remain the Human aim
  model. A valid top pick commits the best bounded approximate inverse solution
  immediately without exact collision validation. Exact pre-impact prediction
  remains latest-only advisory presentation and never blocks aim or Fire.
- **Sparse gameplay instruments:** normal play must not use large left, right, or
  bottom panels or a persistent prose instruction strip. Prefer icons, small
  images, numbers, and symbols; keep the mountain primary. Real interactive
  controls, accessible tooltips, focus, and localized names remain.
- **Integrated shortcuts:** place A/D, W/S, wheel, Space, Tab, F, and Escape key
  hints next to the value or action they control. They must read as part of the
  instrument rather than as detached documentation.
- **Higher surface glyphs:** when existing suitability, visibility, effect, and
  spacing rules admit alternatives, prefer glyph anchors around the middle and
  upper-middle of the terrain instead of the lower edge. Deterministic fallback
  remains legal when the preferred band cannot complete the loadout.
- **Rendered authority:** use the generated sparse-instrument UI reference only
  as a direction, then inspect the actual running game at supported 16:9 sizes
  and correct overlap, clipping, and hierarchy from those captures.

No in-flight steering, new action, new mechanism, second paint representation,
or projectile-physics change is introduced. All earlier requirements not
contradicted here remain in force.

## Later User Supersession (2026-08-09): Legible Instruments and Wind-Stable Aim Edits

After reviewing the revised Aim View, the user requested a clearer ammunition
readout, more polished shortcut prompts, and reliable target-preserving edits
while wind changes. These clauses supersede only conflicting HUD-label and
wind-refresh behavior:

- **Shot capacity:** show shots as remaining / maximum, such as `7 / 7`.
  Resident-ball activity remains a separate number and symbol.
- **Truthful shortcut tokens:** show only controls that act in the current mode.
  Aim View exposes S/W beside the actual elevation decrease/increase controls,
  a mouse-wheel glyph beside power, Space on Fire, Tab on the view toggle, F on
  Finish, and Escape on Gear. A/D is not an Aim View target control and is not
  advertised there. Key tokens do not use literal square brackets.
- **Compact aim instruments:** place decrement, current value, and increment in
  one row. Disable the matching button at the direct numeric boundary. Yaw is a
  passive directional value while terrain-target mode owns the horizontal aim.
- **Wind-stable explicit edits:** after a selected terrain target, the last
  successful explicit elevation or power edit remains pinned across later wind
  refreshes whenever a legal same-target solution exists. If that pinned value
  becomes temporarily infeasible, fall back to another legal same-target tuple;
  never publish an illegal tuple or create a prediction-based Fire gate.
- **Reference authority:** external HUD examples and model review are advisory
  evidence for hierarchy and interaction clarity. Do not copy a layout, asset
  pack, panel, or unsupported action from them.

All earlier requirements not contradicted here remain in force.

## Later User Supersession (2026-08-09): Aim-View-Centered Terrain Glyphs

After reviewing the revised glyph placement, the user clarified that “middle”
means the middle of the mountain as seen while aiming, not a normalized world
height or the upper ridgeline. These clauses supersede only conflicting glyph
placement wording:

- **Visual middle:** judge glyph height inside the projected Playable Terrain
  Surface silhouette under the canonical default Aim View. Do not substitute
  world elevation, route progress, or the viewport midpoint.
- **Middle-band preference:** complete the loadout on readable middle faces
  whenever eligible candidates exist. A bounded deterministic fallback remains
  legal only when mechanism behavior, spacing, or surface safety cannot complete
  the preferred assignment.
- **Complete readable marks:** prefer faces that point toward the Aim View and
  keep the complete terrain-draped glyph inside the view safe frame. Do not
  accept a placement that reads only as a clipped or grazing crescent.
- **Preserved gameplay meaning:** Burst, Splitter, and Uphill Rebound behavior,
  route witnesses, footprint consistency, separation, terrain, and camera
  composition remain unchanged.

All earlier requirements not contradicted here remain in force.

## Later User Supersession (2026-08-09): Remove Wind

After reviewing the implemented wind system and its role in the current
terrain-targeted aiming loop, the user decided to remove wind completely while
preserving the rest of the persistent coverage game. These clauses supersede
only earlier wind requirements and wind-specific interpretations:

- **Remove wind gameplay:** remove the stage-seeded wind schedule, projectile
  wind acceleration, strong-wind resident-ball wake, and every wind-dependent
  aiming or trajectory-prediction input. Gravity, collision, terrain contact,
  and mechanism impulses remain the projectile-motion rules.
- **Remove wind presentation:** remove the gameplay HUD direction, strength,
  countdown, and forecast; remove the cannon-side flag or streamer and any
  other world cue whose purpose is to communicate wind. Do not leave a calm or
  zero-wind compatibility indicator.
- **Remove wind contracts:** remove wind profiles, snapshots, controllers,
  stage fields, agent-observation fields, attempt-log schedule and transition
  fields, delivery-capture modes, localization, and wind-only tests. Retained
  generated resources must not point at deleted wind resources.
- **Preserve the non-wind coverage loop:** persistent paintballs, mechanism
  impulses and their generic wake observation, stage duration, timeout,
  Finish, coverage scoring, terrain generation and seed identity, and bounded
  gravity/collision prediction remain in force.
- **Record the result truthfully:** wind was implemented as deterministic
  physics, prediction, HUD, and resident-ball reactivation and did change
  simulation outcomes. In the target-driven aiming loop, however, its value as
  a legible player-controlled planning choice was not demonstrated, while its
  cross-system implementation, verification, and maintenance complexity was
  substantial. Do not claim measured CPU, GPU, memory, or frame-rate savings
  without a controlled profile.
- **Preserve history:** completed wind plans, prior evidence, and earlier
  supersession text remain historical records. Active specifications,
  implementation records, test runners, resources, and release evidence must
  describe and validate the wind-free current build.

All earlier requirements not contradicted here remain in force.

## Later User Supersession (2026-08-10): Hide Resident-Ball Activity

After seeing the compact resident-ball activity indicator in the running HUD,
the user decided that this internal simulation state does not need a visible
gameplay instrument. These clauses supersede only earlier requirements to show
resident-ball counts or moving/resting activity:

- **Remove the visible activity instrument:** remove its icon, moving/resting
  values, tooltip, localization, layout space, and HUD-specific update wiring.
  Do not replace it with another resident count or status label.
- **Keep internal gameplay truth:** projectile residency, moving/resting state,
  mechanism wake behavior, stage completion, scoring, and diagnostic contracts
  remain owned by their existing gameplay systems. Hiding the indicator must
  not change those rules.
- **Keep the run status focused:** the top-right gameplay status contains time,
  remaining/maximum shots, Finish, and Gear only.

All earlier requirements not contradicted here remain in force.

## Later User Supersession (2026-08-10): Double Active Pace and Remove Passive Messages

After reviewing the pace and the remaining message overlays in the running
game, the user requested faster active play, shorter difficulty-scaled run
limits, and a quieter HUD. These clauses supersede only conflicting gameplay
speed, duration, shot-summary, and mechanism-message requirements:

- **Two-times active play:** while the board is active, projectile physics,
  camera motion, and effects run at two times the former pace. This is the fixed
  normal gameplay pace, not a player-facing speed toggle. Briefing, result, and
  non-gameplay screens remain at normal UI time.
- **Wall-clock stage limits:** the first actual launch starts a real-time limit
  of 60 seconds for Stages 01-10, 90 seconds for Stages 11-20, and 120 seconds
  for Stages 21-30. Simulation time scale must not shorten these wall-clock
  limits a second time.
- **Remove passive message UI:** remove the temporary sealed-shot summary and
  the mechanism briefing/activation message card, including their scene nodes,
  HUD methods, message-only localization, and message-specific tests. Do not
  replace them with another toast, banner, or explanation overlay.
- **Preserve gameplay truth:** sealed shot observations, mechanism activation
  and selection events, agent/attempt diagnostics, paint, coverage, scoring,
  Finish, timeout, and result calculations remain independent of the removed UI.
- **Preserve actionable and terminal UI:** keep the briefing objective with its
  Start/Back actions, Return to Cannon, run status and Finish, coverage and aim
  instruments, context legend, Pause/Settings, loading/failure, and Results.

All earlier requirements not contradicted here remain in force.

## Later User Supersession (2026-08-10): Essential-Only Screen Copy and Semantic Boundaries

After reviewing the generated screen-audit refinements, the user approved the
existing Quiet Context visual style and requested a quieter final pass. These
clauses supersede only conflicting visible-copy, shortcut-prompt, briefing-label,
and decorative-separator requirements:

- **Put explanation on learning surfaces:** normal menus, selection, briefing,
  aiming, settings, and result screens show only identity, authoritative state,
  real actions, terminal reasons, conditional errors, and one current-context
  input guide. Strategy explanations and instructional prose belong in a future
  guidebook page, the first tutorial, or a dedicated UI guide instead of being
  repeated across ordinary screens.
- **Keep content without exposing filler:** stage objective keys, mechanism
  descriptions, and other useful teaching copy may remain as content inventory
  for those learning surfaces, accessibility, diagnostics, and localization.
  Hiding normal-screen copy must not delete gameplay rules or replace truthful
  loading, failure, disabled-reason, tooltip, or accessible-name text.
- **Make briefing visual:** briefing shows the complete terrain and its actual
  surface glyphs without world-space mechanism names, an objective paragraph,
  or a duplicate mouse hint. It retains compact stage identity, the inspection
  mode, Back and Start Aiming, and the one lower-edge context guide.
- **Own shortcuts in one place:** the lower-edge context guide is the sole
  visible shortcut explanation during interactive gameplay. Fire, Finish, and
  Aim/Map action labels contain their semantic Korean or English labels only;
  they do not repeat `Space`, `F`, or `Tab`. This replaces earlier instructions
  to place those key names inside the corresponding controls.
- **Use semantic boundaries only:** spacing, alignment, typography, and surface
  fill establish groups before rules or outlines. Do not use decorative
  full-width hairlines, repeated card borders, internal result separators, or
  column dividers. Keep boundaries only when they communicate focus, selection,
  containment, an editable control, a slider/progress rail, or a target marker.
- **Use the refined images as fidelity targets:** the seven approved refinements
  in `docs/reports/screen-audit-2026-08-10/assets/refined/` are the visual targets
  for Main Menu, Stage Select, Briefing, Aim View, Settings, Manual Result, and
  Timeout Result. Written behavior and runtime truth still override generated
  pixels, invented geometry, or accidental text artifacts.

No guidebook or tutorial implementation, gameplay-rule change, new action,
input change, stage-resource migration, or second paint representation is
introduced by this revision. All earlier requirements not contradicted here
remain in force.

## Later User Supersession (2026-08-11): Browser-Playable Internet Delivery

After the first automated itch.io upload produced only a downloadable Windows
build, the user clarified that internet distribution means playing Paint
Mountain directly in the browser without installing the game. These clauses
supersede only conflicting delivery-platform and release-automation wording:

- **Browser play is the primary internet build:** every releasable `master`
  revision exports a Godot Web build with `index.html` and publishes it to an
  itch.io channel that is tagged playable in the browser.
- **Use the compatible Web path:** keep the Compatibility renderer, use the
  official single-threaded Godot Web release template, and resize the canvas
  adaptively to the browser viewport. Do not require cross-origin-isolation
  headers or a custom third-party runtime.
- **Preserve the Windows companion build:** the verified Windows executable may
  remain available as an optional download, but it is not a substitute for the
  browser build and must not be described as satisfying browser delivery.
- **Keep platform actions truthful:** hide the native Quit action in Web builds;
  retain supported gameplay, settings, keyboard, mouse, persistence, and host
  fullscreen behavior. This revision does not add a mobile-specific layout.
- **Automate both verified artifacts:** a qualifying `master` push runs project
  verification and the complete test suite before exporting and publishing the
  Web and Windows alpha channels with one traceable version.
- **Keep visibility user-controlled:** browser upload and playable-channel
  configuration do not make the itch.io project public. Draft, restricted, or
  public visibility remains a separate user decision.

All earlier requirements not contradicted here remain in force.

## Later User Supersession (2026-08-11): Fixed-Center Terrain Inspection

After reviewing the running terrain-inspection camera, the user required every
terrain-lookaround function to use one stable mountain-centered orbit. These
clauses supersede only conflicting inspection-focus and camera-navigation
wording above:

- **One terrain visual center:** Briefing inspection and the Map Inspection
  available from Aim View use the same immutable pivot at the center of the
  visible terrain mass. The pivot is derived from the actual playable-top bounds
  and visible ground-join base; it is not a stage origin, camera bookmark target,
  clicked surface point, virtual framing headroom, or buried support-shell center.
- **Spherical orbit only:** left drag changes yaw and pitch around that pivot,
  the wheel changes radius, and the camera always looks at the pivot. Pitch and
  radius remain limited, and terrain clearance may increase effective radius
  only along the same center-to-camera ray.
- **No inspection pan or refocus:** terrain clicks, mechanism clicks, Briefing,
  and Map Inspection cannot move the pivot. There is no independent pan,
  click-to-focus, or focus-target drift.
- **Preserve separate camera responsibilities:** Aim View target selection,
  committed cannon aim, Shot Follow, Result presentation, and the noninteractive
  stage-select preview retain their existing owners and behavior. Inspection
  orbit and zoom never modify stored aim or projectile rules.

All earlier requirements not contradicted here remain in force.

## Later User Supersession (2026-08-13): Queued Ball Types, Glyph Removal, and Color Objectives

The user replaced the terrain-glyph mechanism direction with intrinsic ball
behaviors and a limited-preview queue. This revision supersedes earlier clauses
that require one basic ball, exactly three terrain glyph mechanisms, their
world/UI presentation, or preservation of their runtime and serialized
contracts.

User directive (verbatim):

> 공의 색이나 성질을 다르게하자. 테트리스처럼 queue 같은 걸 만들어.
> 다음에 올 공은 알지만, 한 4개 뒤에 어떤 공이 올 지 모르는거야.
> 문양과 관련된 ui, 디자인, 스크립트를 지워.
> 대신 지면에 맞닿으면 폭발하는 공, n개의 방향으로 최고점에서 나눠지는 공, 반탄력이 엄청 심해서 고각도에서 평탄한 곳에 안착시키지 않는 이상 튕겨져 나가는 공 등 추가 n개의 공에 대한 아이디어 떠올리고 계획서로 작성.
> 색에 대해서는... 잘 모르겠네. 랜덤하게 a 색은 n퍼센트 이상, b색은 m 퍼센트 이상 색칠해야 된다는 기준을 스테이지 클리어 기준으로 두고, 뒤에 칠한 색은 이미 칠해진 색을 덮어씌운다는 설정?
> 아니면 그냥 색과 무관하게 모든 색 생관없이 n 퍼센트 이상 색칠하되, a색과 b색은 보색이라 서로 겹치는 구간은 지워진다는 설정?
> 아무튼 이것도 다양한 아이디어를 내고 설명.

Effective requirements:

- Balls differ by intrinsic behavior and may also differ by paint color. The
  launch order uses a Tetris-like limited preview: the near future is known and
  a later tail is hidden.
- Remove terrain-glyph-related UI, visual design, scripts, runtime wiring, and
  serialized active contracts after their ball-owned replacements are ready.
- Include at least an impact-burst ball, an apex-splitting ball, a very high
  rebound ball, and additional distinct ball concepts.
- Explore multiple color/overlap/clear-rule alternatives and select one in the
  implementation plan. The selected rule must keep `PaintSystem` as the one
  authoritative runtime paint representation.
- Preserve the stationary-cannon planning puzzle and no in-flight steering.
  Ball effects occur through deterministic launch/contact/flight rules rather
  than player control after Fire.

All earlier requirements not contradicted here remain in force. The execution
plan created from this directive captured one interpretation; the later
clarification below withdraws its unapproved fixed roster, color, queue, and
deletion decisions from implementation authority.

## Later User Clarification (2026-08-14): Red/Green, Terrain Reuse, and Queue Feasibility

The user revised the exploration after reviewing a proposed MVP. These clauses
supersede only conflicting color identity, unconditional terrain deletion, and
queue-authoring assumptions.

User directives (verbatim):

> 빨강과 초록으로 바꿔. 그리고 지금 지형들을 무조건 삭제하지는 말고 활용하는 방법을 찾아. 공은 랜덤으로 queue를 형성하나? 뭐 랜덤이든 아니든 스테이지 클리어 조건을 만족할 수는 있게 해야지. 아니면 그냥 빠르게 re-roll 하도록?

> 이러면 지형에 따른 개별 큐 생성에 너무 많은 resource가 투입될 거 같은데.

> 뭔가 이것도 아닌 거 같네. 일단 관련 내용을 모두 커밋. 이 '특수 능력 공, 개별 색'과 관련된 아이디이어 시작부터 지금까지의 이력을 문서화. 이 아이디어에 대한 chatgpt pro의 분석을 위한 handoff folder 생성

Effective requirements and decision state:

- Replace the earlier blue/orange proposal with red and green as the individual
  paint colors. Color must not be the only readable signal for a gameplay fact.
- Do not delete current terrain geometry by default. Analyze how its existing
  basins, ridges, slopes, shelves, and other authored forms can support the new
  rule even if glyph-related presentation or behavior is later removed.
- Whether the queue is fixed or random, the supplied balls must permit the
  stage clear condition. A reroll was raised as an option, not approved as a
  required action.
- Do not require expensive, individually maintained queue sets for every
  terrain. Clearability must be achieved with a lower-authoring-cost rule or
  validation method.
- The per-stage prevalidated-queue proposal and the later universal paired-bag
  proposal are not accepted. Queue generation, Retry behavior, reroll, exact
  preview count, ball roster, color interaction, and clear thresholds remain
  open for analysis.
- Do not implement or delete gameplay systems until a new direction is
  explicitly selected.

All earlier requirements not contradicted here remain in force.

## Later User Selection (2026-08-18): Three-Ball Red/Green Target-Band Prototype

The user selected the downloaded
`paint-mountain-three-ball-red-green-target-band-plan.md` as the direction to
validate, refine into an ExecPlan, implement, test compactly after feature
completion, push, and verify on itch.io. This selection ends the 2026-08-14
implementation hold for the bounded prototype clauses below.

User directive (verbatim):

> Use this plan doc to refine the game.
>
> C:\Users\BK\Downloads\paint-mountain-three-ball-red-green-target-band-plan.md
>
> First, you need to validate if it's a solid plan.
> Then, turn this into a execplan.
> Then, finish all tasks on that plan.
> Do not conduct excessive performance test during the tasks, only apply necessary tests.
> Only after all features are implemented, conduct compactperformance test.
> Push to remote repo and make sure it works well on itch.io

Effective requirements for the first implementation pass:

- The MVP roster is exactly Standard, Impact Burst, and Apex Split. A ball has
  exactly one Red or Green paint channel, and that identity remains consistent
  through its world material, paint commands, derived children, queue token,
  observations, and scoring.
- Every eligible painted pixel has exclusive latest-writer Red or Green
  ownership while its visual strength remains monotonic. `PaintSystem` remains
  the one authoritative runtime representation and reports physical Red, Green,
  and Total target-area percentages.
- A stage calculates signed Paint Score from authored Red/Green weights limited
  to `-1`, `0`, or `+1`. Clear requires the final score to lie inside an
  inclusive authored target band. Painting above the upper bound can fail.
- The player sees the current token and next two tokens from a finite,
  constrained-random, deterministic deal. Successful root admission consumes
  one token; rejected Fire and split children consume none. Retry Same Deal and
  New Deal use the authoritative restart path.
- Finish is available only when the score is in band and projectile/paint work
  is quiet. Queue exhaustion auto-evaluates when quiet; timeout evaluates the
  already accepted authoritative paint state. Stars measure distance from the
  target-band center.
- Preserve existing terrain. Apply the new loop to a six-stage prototype first,
  as required by the selected plan's own definition of done. Keep stages 7–30
  functional under their current rule during this pass.
- Catalog-v11 migration, removal of glyph systems from all thirty stages,
  validated seed banks for every stage/deal, and population playtest-rate goals
  remain conditional on prototype evidence and later approval. Do not represent
  structural generator tests as human or physical clearability evidence.
- Use focused tests during implementation. Run one bounded performance check
  only after feature completion, then complete production-style Windows/Web
  validation, push task-owned commits, and verify the resulting itch.io build.

The prototype contract was later consolidated into the UI refinement contract
named below. Its completed gameplay and Web-performance evidence remains valid;
its unapproved public publication step does not authorize a remote action.

All earlier requirements not contradicted here remain in force.

## Later User Selection (2026-08-20): Cannon Focus Shared UI

After reviewing three actual Aim composition targets in
`docs/reports/ui-refinement-2026-08-20/index.html`, the user selected the C
layout and requested one final ExecPlan that merges the existing UI work and is
then executed.

User directives (verbatim):

> C 대포중심이 좋은 거 같아.
> Now, use this html report to create a execplan for UIUX refinement process.
> Merge already existing execplan tasks to this doc.
> Then, use the final execplan to fix the issues.

> Ok, now continue with the tasks. Create execplan doc and use it to fix all the issues.

Effective requirements:

- Cannon Focus is the canonical Aim composition. Use a vertical 0-100 score
  scale at the left, a horizontal current-plus-next-two ball queue at the
  upper-right, and angle, Fire, and power controls split around the lower cannon
  region. Preserve the mountain, cannon, trajectory, target, and impact area as
  the visual focus.
- Every repeated UI primitive is a shared component or canonical Theme role.
  Do not add screen-local panels, cards, palettes, fonts, icons, or tooltip
  behavior.
- Each queue token exposes its position, kind, paint role, and short behavior on
  pointer hover, keyboard focus, and press/touch, with equivalent accessible
  text.
- Stage Select keeps the approved StageRail layout and shows the actual newest
  prepared terrain for the selected stage. It does not use generic landscape
  art, create a second renderer, or commit stage selection before Start.
- Apply the same shared theme and component behavior to every reachable screen
  and all 30 stages while preserving the target-band rule for Stages 1-6 and
  established coverage/mechanism truth for Stages 7-30.
- Consolidate execution under
  `.agents/execplans/2026-08-20-cross-stage-ui-theme.md`. Completed prototype
  stabilization evidence remains a prerequisite; public itch publication still
  requires explicit authorization after the new local artifact is proven.

All earlier requirements not contradicted here remain in force.

## Acceptance Criteria

- The complete directive from the user's pasted message is present above without abridgment or paraphrase.
- Later revisions are dated, bounded to named clauses, and kept outside the
  verbatim directive.
- Derived specifications and plans link back to this file and defer to its
  effective baseline-plus-supersession contract when wording conflicts.
