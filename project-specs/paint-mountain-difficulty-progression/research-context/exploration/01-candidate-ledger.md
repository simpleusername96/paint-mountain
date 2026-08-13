---
type: evidence
status: active
created: 2026-08-13
topic: unranked difficulty candidate ledger
scope: four cumulative exploration rounds and twelve candidates
related:
  - ../02-synthesis.md
  - 02-comparison-and-selection.md
---

# Candidate Ledger

## Purpose

Preserve the complete candidate search before evaluation. The ledger is
intentionally unranked. Candidate IDs indicate generation order, not quality.

## Sources

- `../00-intake.md`
- `../02-synthesis.md`
- `../research/01-local-product-truth.md`
- `../research/02-direct-precedents.md`
- `../research/03-distant-analogues.md`

## Findings

Each candidate records its changed unit, causal logic, likely implementation
surface, distinctive value, and first failure condition. The same hard gates in
`../02-synthesis.md` apply to every round.

## Round 1: Common-Answer Baseline

### C01 — Numeric Compression Ladder

- Changed unit: target coverage, shot allowance, time, and acceptable landing
  window.
- Causal logic: the same plan becomes harder when resources and tolerances
  shrink.
- Implementation surface: `StageProgressionData` formulas and existing stage
  Resources.
- Distinctive value: cheapest continuation of the current ladder.
- First failure condition: later stages become execution checks or timer
  pressure without creating a new planning decision.

### C02 — Geometry and Mechanism Density Ladder

- Changed unit: route count/width, reversals, passes, basins, bends, and the
  count of existing mechanisms.
- Causal logic: more intersecting spatial constraints increase the number of
  trajectories the player must compare before launch.
- Implementation surface: `StageGenerationProfile`, `StageRouteProfile`, and
  the offline catalog materializer.
- Distinctive value: uses the current authored terrain pipeline directly.
- First failure condition: every later stage raises many axes at once, so the
  cause of difficulty becomes visually noisy and hard to diagnose.

### C03 — Preview Withholding

- Changed unit: reduce or remove trajectory-preview information in later
  stages.
- Causal logic: the player must internalize ballistics instead of relying on a
  complete preview.
- Implementation surface: aim presentation and HUD state.
- Distinctive value: raises uncertainty without new content.
- First failure condition: this directly conflicts with the effective brief's
  complete pre-impact preview and weakens deterministic, informed planning.
- Gate disposition: ineligible; retained to show that information removal was
  considered and rejected.

## Round 2: Change the Value or Decision-Maker

### C04 — Self-Selected Challenge Contracts

- Changed unit: before a stage, the player voluntarily selects a bounded
  condition such as fewer shots, a higher target, or a no-Burst run.
- Causal logic: one layout serves different skill frontiers without locking any
  stage.
- Implementation surface: stage-select options, result evaluation, persistence,
  and new localization.
- Distinctive value: the player, not an opaque algorithm, chooses the pressure.
- First failure condition: optional contracts become a competing score system
  or add configuration work before the short core loop.

### C05 — Adaptive Stage Coach

- Changed unit: recommend, but do not lock, the next authored stage from recent
  local outcomes.
- Causal logic: keep the next challenge near the player's current skill
  frontier.
- Implementation surface: a skill estimate, failure classification, save data,
  stage-select recommendation state, and calibration rules.
- Distinctive value: personalized ordering while preserving all-open access.
- First failure condition: partial coverage does not reliably identify whether
  aim, terrain reading, route choice, or risk preference caused the result.

### C06 — Outcome-Prediction Ritual

- Changed unit: before firing, the player optionally marks the expected first
  contact, route, or mechanism sequence and later compares prediction to fact.
- Causal logic: explicit hypotheses make retries intentional and reveal
  misconceptions.
- Implementation surface: input, terrain annotations, observation comparison,
  and feedback UI.
- Distinctive value: changes how the player learns without changing physics.
- First failure condition: the annotation ritual is slower and visually louder
  than the desired rapid aim-fire-observe loop.

## Round 3: Distant Structural Analogues

### C07 — Contrastive Stage Curriculum

- Changed unit: stage order becomes a repeated six-role sequence: Anchor,
  Contrast A, Contrast B, Transfer, Interleave, and Fusion.
- Causal logic: hold most factors stable while one relevant axis changes, then
  transfer and combine the learned invariant.
- Implementation surface: typed challenge metadata, progression formulas,
  catalog content, and structural tests.
- Distinctive value: stages teach through comparison rather than tutorial text.
- First failure condition: the paired stages look too different, so the player
  cannot perceive what was held stable and what changed.

### C08 — Risk-and-Bailout Route Setting

- Changed unit: each advanced stage provides at least one broad recoverable
  route and one narrower, higher-yield mechanism route.
- Causal logic: the player chooses between robust coverage and a harder route
  with greater coverage opportunity; difficulty becomes strategy, not only
  precision.
- Implementation surface: existing route roles, width/grade/branch parameters,
  mechanism slots, and geometric validation.
- Distinctive value: one stage can serve cautious learning and expert mastery
  while remaining fully deterministic.
- First failure condition: the intended high-yield route is not visible from
  the camera or does not produce a meaningful tradeoff in actual physics.

### C09 — Proficiency Badges Without Locks

- Changed unit: award local mastery evidence for repeated outcomes such as two
  efficient clears or successful use of a skill family.
- Causal logic: consecutive evidence distinguishes a learned skill from one
  lucky result and suggests an appropriate next challenge.
- Implementation surface: validated badge definitions, save migration,
  result/stage-select UI, and localization.
- Distinctive value: mastery progression without closing any stage.
- First failure condition: badges become a second progression economy and the
  required thresholds lack enough evidence to be credible.

## Round 4: Failure Inversion and Morphological Recombination

### C10 — Recovery-First Resilience

- Changed unit: later layouts deliberately preserve useful continuation after a
  near miss through broad catch slopes, secondary routes, or delayed mechanism
  opportunities.
- Causal logic: advanced play tests the ability to revise a plan from the
  current paint and projectile state, not only hit one perfect opening shot.
- Implementation surface: route roles and shapes; no new player input.
- Distinctive value: failed shots can remain strategically informative and
  productive.
- First failure condition: recovery lanes make the main target automatic or
  visually erase the distinction between a good and poor launch.

### C11 — Paint-Modified Physics

- Changed unit: already-painted terrain changes friction or rebound response.
- Causal logic: each shot modifies the route landscape, so the player plans a
  multi-shot physical sequence rather than only cumulative coverage.
- Implementation surface: `PaintSystem`, terrain contact physics, prediction,
  observations, UI explanation, and extensive regression tests.
- Distinctive value: turns the authoritative paint mask into stateful terrain.
- First failure condition: identical launch values no longer have an obvious
  comparable outcome after paint changes, and the mask acquires a second
  high-risk responsibility beyond visuals and coverage.

### C12 — Contrastive Risk-Route Ladder

- Changed unit: combine the six-role contrastive sequence from C07 with the
  safe-versus-high-yield route structure from C08, using C10-style recovery as
  a boundary rather than a separate rule.
- Causal logic: every six-stage band establishes one planning invariant,
  contrasts route risk, transfers it, interleaves an older demand, and finishes
  with a readable fusion stage. Inside advanced stages, the player chooses a
  robust route or a narrower mechanism-rich opportunity.
- Implementation surface: typed challenge metadata, current route profiles,
  offline catalog materialization, structural validation, a compact stage-select
  focus label, and existing local diagnostics.
- Distinctive value: it joins a learning sequence to an in-stage strategic
  choice without adding controls, physics rules, mechanisms, scoring, locks, or
  online systems.
- First failure condition: content authors cannot keep the varied axis visible
  while holding secondary axes sufficiently stable.

## Saturation Note

After Round 4, further ideas mainly recombined four represented families:
numeric constraint, spatial topology, player-selected/adaptive challenge, and
contrast/recovery sequencing. Unrepresented ideas either required hidden
uncertainty, new controls, a competing score, or a large new subsystem. The
ledger was frozen at twelve candidates before scoring.

## Limitations

- Candidate feasibility is based on repository evidence, not implementation.
- Candidate names are working labels. Only the selected product contract may
  create durable runtime names.
