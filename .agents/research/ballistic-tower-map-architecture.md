# Ballistic Tower Defense Map Architecture — Deprioritized Note

Last updated: 2026-08-22

## Decision state

This direction is **deprioritized as the primary redesign**.

It turns Paint Mountain into a conventional tower-defense structure with an
unusual placement control. The important payoff moves from the immediate
`fire -> paint result -> recalibrate` loop into a later enemy wave, progression
slows down, and the cannon becomes a preparation tool for another game.

Keep this note only as historical exploration. The isolated concept that a
landed ball may immediately transform into a useful persistent object can be
reconsidered later, but not through a long setup-and-wave loop.

The active problem statement and current cross-domain candidates are recorded
in `.agents/research/gameplay-fun-redesign-memo.md`.

## Historical candidate

The explored map used a low-relief wide basin, one inner Core, three perimeter
enemy gates, broad valley corridors, and one cannon moving around a circular
perimeter rail. Landed balls became normal towers outside corridors or
barricade towers inside corridors, and misplaced zero-fire towers could be
recalled between waves.

Although internally coherent, this architecture does not preserve the project's
most distinctive fast paint-and-calibrate loop and should not guide current
implementation work.
