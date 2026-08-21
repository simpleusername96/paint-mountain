# Ballistic Tower Defense Map Architecture — Working Note

Last updated: 2026-08-21

This note records the current map-design candidate for the gameplay redesign.
It is advisory research, not an approved implementation plan, and complements
`.agents/research/gameplay-fun-redesign-memo.md`.

## Current map candidate

Use a low-relief, wide basin viewed as one readable tactical board. Do not use a
single narrow road or fully open, unpredictable navigation. Use a **semi-fixed
valley network**:

- one defended Core in the inner basin;
- three perimeter enemy gates;
- two or three broad movement corridors separated by low ridges;
- a few visible crossovers where enemies can switch corridors;
- no mandatory hidden rear/side score surface;
- no literal ten-times world-scale expansion. Increase readable breadth and
  lower relief while keeping cannon flight and enemy travel short.

Enemies spawn from the announced active gates and move toward the Core. Before
each wave, show the currently expected corridor arrows. Towers may influence
local route cost, but one tower must never hard-seal the only path.

## Cannon layout

Use one cannon on a circular perimeter rail rather than three independent
cannons. The rail has about eight snap positions. The player moves left/right
around the ring and selects a firing angle from a different side of the same
board without managing multiple cannon entities.

- During setup, rail movement is immediate or nearly immediate.
- During a wave, rail movement remains possible but occupies the cannon for a
  short reload-like travel time.
- The tactical camera keeps the whole basin visible; aiming briefly moves to the
  selected rail position.

## Suggested phase structure

- Stage start: three setup shots before enemies enter.
- Each short wave grants one additional ball.
- That ball may be fired during the wave, so the player can add a tower, hit an
  enemy directly, or repair a weak side.
- Aiming during combat may use brief bounded time dilation rather than a full
  indefinite pause.

This creates a build-and-observe rhythm without splitting the game into a long
paint puzzle followed by an unrelated defense phase.

## What a landed ball becomes

Every accepted landed ball unfolds into a tower after a short readable delay.
Location changes its role:

- **Outside a movement corridor:** normal tower with full range and durability.
- **Inside a movement corridor:** frontline barricade tower. It attacks and
  slows nearby enemies, but enemies can attack it or move around it within the
  broad corridor. It never creates a hard path lock.
- **Direct enemy hit during a wave:** applies kinetic impact damage first; the
  surviving ball still unfolds after landing.

This makes road placement a valid risky choice instead of an invalid placement.

## Misplaced tower recovery

Design the board so most legal terrain can cover at least one corridor, but
retain a recovery rule for obvious mistakes:

- If a tower fires zero times during a complete wave, mark it as recoverable.
- Between waves, the player may magnetically recall it to the hand.
- Recall consumes the next wave's live-shot allowance, so recovery costs tempo
  but does not permanently ruin the attempt.

Do not make every poor placement automatically useful; the point is to prevent
one bad ballistic result from forcing an immediate restart.

## Why this topology

A single thin fixed track makes the best tower locations too obvious and turns a
ball on the road into a pathfinding exception. Fully open navigation makes enemy
intent hard to read while the player is also aiming a cannon. Broad authored
valleys provide readable intent, several valid tower angles, and limited route
adaptation.

Relevant references:

- Bad North uses compact terrain shape as the main tactical variable while the
  player gives broad commands.
- X-Morph: Defense previews attack paths in a setup phase, allows tower placement
  during battle, and recalculates routes when the battlefield changes.
- Toy Soldiers combines battlefield command with direct weapon control.
- Thronefall demonstrates a stripped-down build/defend rhythm with low input
  complexity.
- Isle of Arrows demonstrates bounded randomness before a defense wave, but its
  full path-construction layer should not be copied into this prototype.

## Small falsification prototype

Build one map only:

- one Core;
- three gates, with two active per run;
- three wide valley corridors and two crossovers;
- one eight-position cannon rail;
- three setup balls plus one live ball per wave;
- normal and barricade tower landing modes;
- two 25-second waves;
- zero-damage recall.

Primary question: does choosing a rail angle and ball landing point create a
fast, understandable defense decision while the landed projectile becoming a
tower remains satisfying?
