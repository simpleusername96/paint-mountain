# Paint Mountain Gameplay Goal Architectures — Working Note

Last updated: 2026-08-22

This is advisory research, not an approved implementation plan. It extends
`.agents/research/gameplay-fun-redesign-memo.md`.

## Accepted direction

The promising direction is to make post-launch interactions the game's main
verbs. Angle, power, airtime, terrain contact geometry, ball choice, and color
state may produce different results such as a direct-impact splash, long skid,
ridge skip, airborne split, or multi-color reaction. The HUD should disclose
coarse trigger conditions and current progress without previewing the complete
post-impact solution.

Wet/dry repainting and color interaction remain useful ingredients, but are not
a sufficient standalone objective.

## Goal-design constraints

A viable goal should:

- resolve through roughly one to five shots;
- show progress directly on the terrain within seconds;
- reward materially different post-launch interactions;
- provide several workable trajectories instead of one authored trick;
- keep same-state retry fast enough for calibration;
- avoid a later combat, economy, or management phase that makes painting setup;
- remain understandable through a small number of world markers and icons.

## Five candidate goal architectures

### 1. One-shot interaction contract

Each stage shows two required event icons and one optional icon. Example:
`air split + direct splash`, or `two ridge skips + children land in three
regions`. A shot clears the contract only if it also paints a small minimum
amount of fresh terrain. The player receives several attempts and the best
completed shot counts.

This makes the projectile's complete sequence the objective. The HUD lights
each icon as the event occurs; it does not reduce the result to a generic score.

### 2. Connect visible terminals

Place one source and two to four large terminals on the readable terrain face.
Continuous paint conducts between them:

- a skid creates a long wire;
- a splash creates a junction;
- an airborne split creates branches;
- later repainting may repair, redirect, or cut a connection.

Clear occurs when all required terminals glow as one connected network. The
missing connection is visible directly on the board after every shot.

### 3. Enclose and flood-fill regions

Mark one to three broad regions. Paint trails act as boundaries. Closing a loop
around a region immediately fills its interior with one fast paint animation.
Long shallow impacts draw edges, skips bridge gaps, and split children may close
multiple sides. An opposite-color strike may puncture or steal a boundary if a
negative-color role is needed.

This converts a few precise paths into a large visual transformation instead of
requiring manual percentage coverage.

### 4. Produce target layer states

Give two or three large terrain plates simple visible recipes rather than exact
pixel targets. Examples:

- same color twice before drying -> hardened coat;
- opposite color while wet -> neutral bloom;
- opposite color after drying -> top layer replaces the lower color;
- strong splash on a hardened coat -> fractured mixed state.

Clear occurs when every plate reaches its requested final state. Shot order,
impact style, color, and timing all matter, while the recipes remain readable as
two- or three-icon sequences.

### 5. Guide or contain a short paint front

A qualifying impact seeds a paint front that travels downhill for only a few
seconds. The stage asks the player either to reach marked outlets or to protect
marked islands. Subsequent shots may create new branches, redirect the front,
or lay an opposite-color stopping line. The player may fire while the front is
moving.

The result remains a rapid paint simulation, not a separate defense phase. One
attempt should finish in well under a minute.

## Recommendation

Use **One-shot interaction contract** as the first base-goal prototype because
it most directly tests whether diverse post-launch behavior is enjoyable and
calibratable. Test **Connect visible terminals** as the first spatial goal and
**Enclose and flood-fill regions** as the first large visual-payoff goal.

Layer-state and spreading-front goals should remain isolated experiments until
the base interaction vocabulary is stable and legible.

## Research basis

- Tony Hawk's Pro Skater links distinct actions into one banked combo and reduces
  value for repetition; pinball modes similarly ask players to complete visible
  shot sequences.
- Mini Metro turns a small set of visible connections into a network problem
  whose deficiencies remain legible after each edit.
- Go defines territory through complete enclosure rather than direct occupation
  of every interior point.
- Multi-plate and screen printing build images through separate ink applications
  and layered color states.
- Watershed routing follows connected downhill paths, while wildfire firelines
  attempt to contain an advancing perimeter.

## References consulted

- Activision support, Tony Hawk's Pro Skater 1 + 2 scoring and combos.
- Pinball.org rule sheets for shot-sequence modes and features.
- Dinosaur Polo Club / Nintendo, Mini Metro.
- British Go Association, rules and territory explanation.
- MoMA, Screenprint; Metropolitan Museum collection records for multi-color
  plate printing.
- U.S. Geological Survey, NHDPlus and cascade flow-path tools.
- U.S. Forest Service, Fireline Effectiveness research.
