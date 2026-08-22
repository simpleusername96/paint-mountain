# Paint Mountain Gameplay Fun Redesign — Working Memo

Last updated: 2026-08-22

This is durable advisory research for the current gameplay redesign discussion.
It does not override `docs/source-brief.md`, `docs/design-spec.md`, or an
approved implementation plan.

## Current problem statement

Paint Mountain's strongest loop is:

`choose a shot -> fire -> watch the terrain transform -> immediately revise`

The current game is an open, static optimization problem. Once the player finds
a good route, later play becomes repetition or precise calibration. Changing the
completion checklist does not solve that.

The next prototype needs one predictable disturbance that changes the board
after every shot. The disturbance must act through terrain and paint, not through
a later combat, economy, or management phase.

## Accepted interaction vocabulary

These remain promising and may be freely transformed:

- Landing geometry changes the operation: direct impact creates an area effect,
  shallow impact creates a long line, long airtime may split into several
  smaller balls, and ridge contact may redirect or amplify a result.
- Colors may overwrite, combine, neutralize, harden, attract, repel, or trigger
  each other.
- Paint changes with age. Fresh, curing, cured, and degraded states may behave
  differently.
- A small visible hand of balls with free next-ball selection remains compatible
  with the redesign.

## Required pressure design

- After every resolved shot, the hostile state advances exactly once or makes
  one fully visible move.
- Its next action is previewed before the player fires. Difficulty comes from
  choosing a response, not from hidden randomness.
- The terrain itself shows urgency. Gloss, cracks, arrows, advancing edges, and
  highlighted breaches should replace explanatory result text.
- One round should use roughly four to seven balls and end in about 60–90
  seconds, with deterministic Same Setup retry.

## Strongest hypothesis: mark, react, and purge a spreading contaminant

**Goal:** remove every contaminant patch before any patch reaches the protected
spring or the ball hand is exhausted.

- After each shot, every surviving unrestrained patch spreads one visible step.
  The exact next spread footprint is previewed.
- Either color can be applied first. Paint touching contamination marks it and
  stops that local spread for one turn.
- Hitting still-wet marked paint with the opposite color triggers a fast
  neutralization wave through the connected marked patch, removing it and
  leaving cured safe paint.
- Applying the same color again before drying thickens it into a persistent
  barrier instead of purging it.
- Unreacted paint eventually degrades and can be consumed by the contaminant.

Landing behavior determines how the player performs those operations:

- direct impact: mark or purge one broad patch;
- shallow skid: draw a long temporary barrier;
- long-airtime split: mark several separated outbreaks;
- ridge redirect: reach a patch hidden behind local relief.

This creates an immediate choice after every shot: buy time, build a barrier, or
cash out a prepared region with a purge chain. Paint remains the visible state
and the main spectacle.

## Four comparison hypotheses

### Herd a mobile stain into a drain

One coherent stain moves after every shot. Fresh color fields attract or repel
it, while dried fields lose or reverse that effect. Direct impacts push it,
skids create long fields, and split balls create multiple bait or repulsion
points. The next movement arrow is always visible.

### Complete a containment line

An expanding stain escapes if it crosses the map boundary. Fresh paint delays it
for one turn; a second compatible coat cures into a permanent line. The player
must close the remaining breach before the stain reaches it. Long skids build
line segments, splashes patch gaps, and splits handle several breaches.

### Repair a cracking surface

Cracks grow once after each shot, with the next growth shown beforehand. Fresh
paint bridges a crack temporarily; a second reacting coat cures the repair.
Direct impacts fill wide breaks, skids stitch long cracks, and split balls repair
several tips. Clear by curing every crack before one reaches the protected edge.

### Route unstable fluid into a purge basin

Several shallow basins contain a hostile fluid. A shot changes local surface
behavior: one paint state attracts or absorbs flow, another repels it, and curing
locks the effect. The next spill direction is previewed. Clear by draining all
fluid into the purge basin before any protected basin overflows.

## UI nudge contract

- Aim view shows only the current operation class: `SPLASH`, `SKID`, `SPLIT ×N`,
  or `REDIRECT`, plus a coarse confidence state.
- Hostile spread or movement for the next step appears as a translucent terrain
  overlay.
- Fresh paint is glossy and animated; cured paint is matte and solid; degrading
  paint visibly cracks or fades.
- The HUD may show remaining balls and one short goal sentence. It must not
  explain the tactical answer.

## Prototype recommendation

Test only the mark/react/purge hypothesis:

- one low, wide map;
- one protected spring;
- three contaminant patches;
- two symmetric colors;
- Standard and airborne-split balls;
- five player shots;
- one-step telegraphed spread after each shot;
- Same Setup and New Setup retry.

Primary question:

**Does the previewed next spread make the player immediately want to choose and
calibrate another cannon shot, while the final purge chain is enjoyable without
reading a score meter?**

If not, stop adding goal variants. That would be evidence that the current
cannon-and-paint system is better reused inside another project.

## Separate correctness issue

The Apex Split low/fast-trajectory defect remains independent and is tracked in
GitHub Issue #1.

## Research basis

- Fully telegraphed hostile intent in compact tactics.
- Wildfire control lines and containment.
- Ring containment around an outbreak.
- Immune tagging followed by elimination.
- Attraction and repulsion gradients used to guide moving agents.
- Wettability gradients used to direct fluid motion.
- Responsive and self-healing coatings that change behavior after damage or
  during curing.
