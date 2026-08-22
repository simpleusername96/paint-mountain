# Paint Mountain Gameplay Fun Redesign — Working Memo

Last updated: 2026-08-22

This is the durable working memo for the current gameplay redesign discussion.
It is advisory research and does not override `docs/source-brief.md`,
`docs/design-spec.md`, or an approved implementation plan.

## Current conclusion

Paint Mountain's distinctive strength is the short causal loop:

`choose a shot -> fire -> watch the terrain transform -> immediately revise the next choice`

The current one-player, static-completion puzzle still does not look compelling.
Changing the completion rule from coverage to marked zones, connections,
recipes, loops, or effect checklists changes the task but not the source of fun.
All of them still ask the player to solve an inert board efficiently.

The deeper problem is:

- The board does not push back or create a new situation between shots.
- Paint is mostly evidence that a task was completed, not an active conflict.
- Special launch interactions improve efficiency but do not create stakes by
  themselves.
- Once a good route is found, later play becomes repetition or exact tuning.
- Adding a later tower-defense or management phase moves the payoff away from
  the cannon and slows the game's strongest loop.

## Hard requirements for the next concept

Any next prototype must satisfy all of these:

- The goal can be stated in one plain sentence.
- Every shot changes the immediate win/loss situation, not only a score meter.
- Angle, power, ball choice, airtime, and collision geometry remain the main
  controls.
- The visible paint state itself creates the next decision.
- One round lasts roughly 60–90 seconds and supports instant same-state retry.
- Randomness is revealed before the shot; identical revealed shots remain
  deterministic enough to calibrate.
- There is no later combat, economy, construction, or management phase.

## Rejected or deprioritized objective families

- Generic percentage coverage and signed target bands.
- Painting a fixed list of marked regions.
- Connecting terminals, drawing closed loops, or completing paint recipes as the
  main game.
- Effect checklists such as `split + splash + bounce` as the main game goal.
- Conventional tower defense in which cannon shots only prepare a later wave.
- Generic combo text, calibration labels, and visual reward layers presented as
  substitutes for a new rule.

These may still appear as secondary stage modifiers, but none currently justifies
the full game by itself.

## Strongest next hypothesis: compact ballistic paint duel

Use one shared, low, wide, fully readable basin. The player and a fast AI rival
alternate four to six cannon shots. Both receive a small visible ball hand and
may choose the order of their remaining balls.

**Goal:** when the final shot is resolved, control more of the central arena than
the rival.

The important difference from the old coverage puzzle is that territory is
contested and unstable:

- A shot can claim empty ground, overwrite rival paint, protect an exposed area,
  or set up a later color reaction.
- The rival's latest shot creates a new problem immediately; the board is never
  merely waiting to be solved once.
- High direct impacts, long skids, ridge skips, airborne splits, and repaint
  reactions are tactical ways to attack or defend territory, not separate goal
  checkboxes.
- The round ends after a fixed small number of shots, so there is no long
  preparation phase.
- `Retry Same Match` preserves the map, hands, and rival seed for calibration;
  `New Match` changes the revealed hands and rival plan.

No towers, units, economy, or separate combat layer are part of this hypothesis.
The cannon and paint remain the entire game.

## Solo fallback hypothesis

If a rival is undesirable, replace the opponent with one visible hostile paint
front that advances once after each player shot. The player must reclaim or
contain it before the hand ends. This preserves immediate counter-pressure but
is weaker than a rival because its responses may become predictable.

## Falsification prototype

Build only one compact map, two colors, one ordinary ball, one airborne-split
ball, five shots per side, simple overwrite rules, and one fast AI policy. Do not
add progression or all thirty stages.

Primary question:

**Does the rival's latest paint result make the player immediately want to aim a
new shot, and is that repeated exchange enjoyable for several short matches?**

If the answer is no, stop adding objectives and supporting systems. That would
be strong evidence that the current cannon-and-paint interaction is better used
inside another project than expanded into a full standalone game.

## Base direction and separate issue

- A small visible ball hand with free next-ball selection remains compatible
  with the hypothesis.
- Post-launch behavior based on airtime, impact speed, collision angle, and
  terrain contact remains promising as the shot vocabulary.
- The Apex Split low/fast-trajectory defect remains a separate correctness issue
  tracked in GitHub Issue #1.
