# Paint Mountain Gameplay Fun Redesign — Working Memo

Last updated: 2026-08-22

This is the durable working memo for the current gameplay redesign discussion.
It is advisory research and does not override `docs/source-brief.md`,
`docs/design-spec.md`, or an approved implementation plan.

## Core problem statement

Paint Mountain's distinctive strength is not terrain coverage by itself. It is
the short causal loop:

`choose a shot -> fire -> watch the terrain transform -> immediately revise the next choice`

The current design problem appears whenever depth is moved outside that loop.
Ordered-queue disposal, exact target-band bookkeeping, long preparation phases,
and a later tower-defense battle may add systems, but they delay the payoff and
turn the cannon into a setup interface for another game.

A useful new mechanic must therefore satisfy all of these conditions:

- Cannon angle, power, ball choice, or timing materially changes the visible
  paint result within a few seconds.
- The changed terrain itself suggests the next choice; explanatory result text
  should not carry the design.
- One shot creates only a few new decisions, not a long management phase.
- Same-state retry is immediate and deterministic enough for calibration.
- Randomness is revealed before the decision, not injected into an identical
  shot's outcome.
- Paint remains the main spectacle and the main evolving state.
- A secondary genre must not postpone the value of painting until a later wave
  or combat phase.

The tower-defense architecture is therefore deprioritized as the primary game.
The isolated idea that a landed ball may transform into something useful can be
revisited later, but only if its effect is immediate inside the shot loop.

## Base direction that remains open

- A stage may supply a small finite hand of balls, with free choice of the next
  unused token.
- The hand may be authored or generated through bounded visible randomness.
- Negative-scoring paint remains available if it has a direct systemic use.
- Terrain should be broad, low enough to read quickly, and composed around
  visible shot routes rather than hidden total surface area.
- The Apex Split low/fast-trajectory defect remains a separate correctness issue
  tracked in GitHub Issue #1.

## Five new cross-domain mechanic candidates

These are alternatives and ingredients, not a command to combine all five.

### 1. Ballistics become the brush mode

Do not choose a separate paint tool. Derive the stroke from the actual approach
geometry:

- high normal impact: one broad radial splash and a short stop;
- high tangential impact: one long narrow skid stroke;
- shallow near-critical impact: two or three skipping splashes.

The aiming preview shows only a small predicted stroke icon, not the full final
path. Angle and power now decide both where the ball lands and what kind of mark
it makes. This makes the cannon the primary expressive instrument instead of a
launcher that merely selects a point.

### 2. Wet paint creates a short combo window

Fresh paint remains wet for roughly two to three seconds. The next ball may be
fired before it dries.

- Crossing wet paint drags it outward into a large fan-shaped smear.
- Hitting dry paint behaves normally.
- Waiting is safe and predictable; firing quickly risks a larger transformation.

This introduces speed through a visible physical state, not a timer bonus. The
player decides whether to inspect carefully or exploit the wet window for a
rapid two-shot combo.

### 3. Three shots stretch a paint membrane

The first impact point of a suitable ball can become a visible paint anchor.
When three same-channel anchors exist on one readable terrain face, a paint film
stretches across their triangle and fills it in one fast animation.

- Trails still paint normally on the way to each anchor.
- The third shot creates the large payoff.
- A later opposite-color anchor may cut one bounded hole or replace one vertex,
  if negative paint needs a direct use.

This turns surveying and triangulation into a compact three-shot spatial puzzle.
It produces a large result without requiring the player to manually cover every
pixel.

### 4. Trails seed competing growth fronts

After a ball settles, its fresh trail expands sideways for about one second like
a crystallization or reaction front.

- Expansion stops at ridges, dry boundary lines, or another color's front.
- A long rolling trail seeds a wide ribbon; a short impact seeds a compact island.
- Opposing fronts meet and freeze into a sharp visible border.

The player chooses seed curves through ballistics, then watches the map rapidly
organize itself. The rule can create varied patterns from simple local behavior
without adding a separate economy or combat phase.

### 5. Retry uses visual bracketing, not manual re-entry

After a shot, preserve the exact previous setup and show three clickable ghost
variants around it. They are real nearby ballistic candidates, not text labels:

- one varies power;
- one varies lateral aim;
- one preserves impact but changes approach angle.

The player may select one and fire immediately, or edit normally. This applies
sequential experiment design to the control loop: each result narrows the next
set of useful settings while the player still makes the decision.

## Recommended test order

First test **Idea 1 + Idea 5** on one low, wide map. This directly tests whether
the cannon can become more expressive while retries become faster.

Then test **Idea 2** and **Idea 3** separately. Both create clear two- or
three-shot payoffs and can be judged quickly in manual play.

Test **Idea 4** only after the ordinary trail remains readable; uncontrolled
front growth could otherwise make calibration harder.

Do not migrate all thirty stages or combine all five until one mechanic makes
repeated shooting enjoyable without relying on score UI.

## Evaluation questions

- Can the player explain why a different angle, power, ball, or timing should be
  used for the next shot?
- Does the visible paint state provide that reason without a result paragraph?
- Is the next shot usually chosen within a few seconds?
- Does an identical retry remain stable enough to learn from?
- Is a large paint transformation satisfying before any score appears?
- Does the cannon remain the main verb of the game?

## Research basis

- Oblique droplet and spray-coating research shows that impact speed, angle, and
  surface conditions produce different spreading, splashing, rebound, and
  elongated-deposition regimes.
- Wet-on-wet watercolor uses substrate wetness, capillary flow, and timing to
  create blooms, backruns, soft expansion, and hard dry boundaries.
- Surveying and computational geometry derive areas and meshes from a small set
  of points and closed boundaries.
- Reaction-diffusion and crystal-growth fronts generate complex visible patterns
  from local propagation and collision rules.
- Sequential experiment design uses each observed result to choose more useful
  settings for the next measurement.

## References consulted

- Splat morphology and spreading behavior due to oblique impact of droplets in
  plasma spray coating, Surface and Coatings Technology.
- Effect of Weber number and impact angle on solidification behaviour of a
  molten droplet on an inclined surface, Experimental Thermal and Fluid Science.
- Pattern formation by droplet evaporation and imbibition in watercolor
  paintings.
- Wicking and flooding of liquids on vertical porous sheets.
- Shoelace formula / surveyor's formula and Delaunay triangulation references.
- NIST, On the Growth and Form of Spherulites.
- NIST, OptBayesExpt: Sequential Bayesian Experiment Design for Adaptive
  Measurements.
