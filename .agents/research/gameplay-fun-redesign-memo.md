# Paint Mountain Gameplay Fun Redesign — Working Memo

Last updated: 2026-08-21

This is the durable working memo for the current gameplay redesign discussion.
It is advisory research and does not override `docs/source-brief.md`,
`docs/design-spec.md`, or an approved implementation plan.

## Correction to the previous memo

The previous version incorrectly treated compact result labels, generic
fresh-paint rewards, front-only scoring, and fast retry as new gameplay ideas.
They are presentation, constraints, or already-existing support systems. They do
not create a new decision and have been removed from the retained idea set.

Every retained idea below must answer both questions:

1. What does the player decide differently before the next shot?
2. What concrete new event happens in the simulation or paint state?

## Player experience target

- Keep each decision brief and the total run fast.
- Require a small but meaningful decision before each shot.
- Build a tight `try -> observe -> calibrate -> retry` loop. First-try clears are
  not required.
- Put bounded randomness before the decision; once revealed, shot outcomes must
  remain deterministic enough to learn.
- Make paint behavior enjoyable to watch without relying on a score number.
- Do not require accurate reasoning about rear or side surfaces the cannon view
  cannot read.

## Base direction already selected for further design

- A stage supplies a finite set of roughly four to six ball tokens.
- The composition may be seeded-random or authored; this remains open.
- The player chooses any unused token as the next ball. This is a selectable
  **ball hand**, not a forced queue.
- A dedicated selectable-hand UI and a UI-independent selection action are
  required.
- Negative-scoring paint remains available. The design should give it a
  systemic use instead of making disposal the automatic answer.
- Special balls must remain broadly useful. Do not hard-pair one special kind
  with one authored terrain device or one mandatory route.
- Core score and required objectives should use the broad cannon-readable front
  envelope. Hidden paint may remain physical and visible when revealed, but is
  not a mandatory scoring burden.

## Current implementation mismatch

- `src/ball/ball_deal_generator.gd` creates one ordered deal. Deals with at least
  four shots end with opposite-color Standard correction tokens.
- `src/stage/stage_controller.gd` consumes one advancing `_queue_cursor` and
  exposes only the current token plus the next two.
- `src/ui/components/ball_queue.gd` presents token information but does not
  publish a gameplay selection action.
- Free-order play therefore needs stable token identities, a remaining-token
  collection owned by `StageController`, one human/agent-neutral select action,
  and a selectable hand component.

## Separate correctness issue: Apex Split can hit before splitting

`src/projectile/apex_split_ball_behavior.gd` resolves only when vertical
velocity crosses the apex. A low, fast shot can contact terrain first, and valid
terrain contact then permanently prevents the split.

Treat this independently from the fun redesign. The preferred behavior to test
is:

- Split at the earliest of normal apex crossing or imminent valid-terrain
  contact within a small authored lead time/distance.
- Keep a final contact-time fallback so a legal Apex Split cannot silently act
  as a Standard ball because the arc was too flat.
- Preserve deterministic child directions and atomic three-child replacement.

No runtime fix is authorized by this memo.

## Five retained concrete mechanics

These are alternatives and ingredients, not a command to combine all five.

### 1. Paint changes the physics of later balls

Give each color one stable physical property in addition to its stage-specific
score sign:

- **Slick paint:** later balls crossing it retain tangential speed and use much
  lower friction.
- **Grip paint:** later balls crossing it lose bounce and settle into the local
  downhill direction more quickly.

A ball is affected only by paint left by earlier shots, never by the trail it is
creating now. This keeps causality readable and deterministic.

Concrete decision: use an otherwise negative Slick ball first to build a runway
for a later Split ball, or use Grip paint first to create a catch area for a
later Burst ball. The color is therefore a terrain edit, not only a score
number. No authored ball-to-terrain pairing is required.

Implementation fit: `PaintSystem` remains the owner of the channel mask;
projectile contact queries the existing channel beneath the contact and applies
one bounded material response. Texture treatment must distinguish slick and
rough paint without hue alone.

### 2. Stopped balls become reusable board pieces

A stopped ball stays on the mountain as a large, targetable sleeping ball.
Later shots can deliberately hit it.

- A direct hit above a threshold wakes both balls and they resume painting.
- Two same-color balls that collide above the threshold merge once into one
  **charged ball**: about `1.35x` radius, one immediate radial splash, and a wider
  trail until it stops.
- Opposite colors do not merge; they simply collide and continue.
- Aim selection receives a generous sleeping-ball target, so this is a planned
  shot rather than pixel hunting.

Concrete decision: spend an early ball placing a future collision target, then
choose whether a later token should reactivate it, merge with it, or avoid it.
Ball order and previous mistakes both become usable state. The merge supplies a
clear visual payoff without a fixed terrain mechanism.

Implementation fit: resident rigid bodies already exist conceptually. The new
work is stable sleeping identities, target selection, one merge limit, and an
authoritative replacement/splash event.

### 3. Opposite-color trail crossings create a cured-paint bloom

Do not reward simple parallel repainting. Record the local direction of fresh
trail stamps. When a Red trail and a Green trail cross at a sufficiently
different angle, the first crossing in that local region triggers a
**cured-paint bloom**:

- A large neutral white/gold splash grows from the intersection.
- Cured area counts strongly toward the minimum painted-area requirement.
- It contributes `0` to the signed Red/Green score.
- It is locked and cannot be recolored again.
- Each local crossing region triggers once, preventing repeated farming.

Concrete decision: a negative-color shot can lay one half of a future crossing;
a later positive shot must intersect it from another route. The player is
planning two trajectories, not discarding a bad color. The crossing and bloom
are immediately visible.

Implementation fit: keep one authoritative paint representation by adding a
cured ownership state and short-lived trail-direction metadata. Do not create a
second score mask.

### 4. Terrain depressions fill and spill into paint cascades

Derive a small drainage graph from the cannon-readable terrain face. Broad
concave regions become paint basins automatically; they are not hand-authored
special-ball sockets.

- Paint commands deliver a small amount of visible volume to the current basin.
- A basin shows a clear fill rim.
- When full, it spills over its lowest edge and paints a narrow downhill stream
  into the next basin.
- A downstream basin may then fill and spill, creating a bounded chain reaction.
- The final marks are written through `PaintSystem`; the basin volume is a
  transient trigger state, not a second coverage authority.

Concrete decision: spread paint immediately or invest enough of the hand into
one basin to trigger a larger cascade. Standard, Burst, and Split contribute
different volume distributions, but none is mandatory for a specific basin.

The first prototype should use only three to five readable basins on one small
front face and a hard cascade-step cap. This is a lightweight fill-and-spill
graph, not fluid simulation.

### 5. Exactly one ball in the hand is a visible anomaly

Each hand contains exactly one token with one clearly displayed random modifier.
The modifier is revealed before any shot and remains identical on `Retry Same
Hand`:

- **Heavy:** higher mass, lower bounce, wider trail.
- **Hollow:** lower mass, higher bounce, narrower trail.
- **Delayed:** makes one radial burst after its third valid surface contact.
- **Magnetic:** its first valid impact pulls nearby sleeping balls toward the
  impact point.

Concrete decision: the player decides when the unusual ball is most valuable
and may build the rest of the order around it. Randomness changes the puzzle
before play without making an identical revealed shot behave differently.

Keep this to one anomaly and four simple modifiers. Multiple random badges on
every token would slow the hand-reading step and turn the game into inventory
analysis.

## Recommended test order

Do not implement all five at once.

### Prototype A — lowest-cost systemic test

- Five-ball selectable hand.
- Idea 1: Slick/Grip paint affects later balls.
- Idea 5: one visible anomaly token.
- Three small stages using only the readable front score envelope.

Question: does choosing ball order create fast, understandable route planning?

### Prototype B — persistent-board test

Add Idea 2 only after Prototype A is readable. Use one stage with enlarged
sleeping-ball targets and a maximum of one charged merge per attempt.

Question: do players deliberately set up a later collision, or does it remain an
accident too difficult to aim?

### Isolated spectacle tests

Test Idea 3 and Idea 4 separately. Both change paint scoring/state substantially
and should not initially coexist with each other or with Slick/Grip physics.

Question for Idea 3: does a two-shot crossing plan make negative paint useful?

Question for Idea 4: is filling a basin and watching a bounded cascade enjoyable
even without reading the score UI?

## Evaluation questions

- Do players choose different first balls for an explicit mechanical reason?
- Is average pre-shot decision time short?
- Does a failed attempt reveal a useful setup or route adjustment through the
  world state itself?
- Is throwing a ball outside the objective still commonly optimal?
- Does negative paint have a use beyond satisfying a forced color requirement?
- Is the most enjoyable moment visible in the terrain/paint simulation rather
  than only in UI numbers?
- Does `Retry Same Hand` produce a materially improved attempt within two or
  three runs?

## Research basis

- Portal 2 and Splatoon make paint alter traversal or surface behavior instead
  of treating it only as score coloration.
- Curling makes previously placed stones part of later tactical shots; Suika
  Game turns same-kind collision into a clear merge payoff.
- Painting uses grounds, underpainting, and later layers to change the result of
  the next application rather than treating every coat independently.
- Hydrologic depressions retain runoff and can connect downstream only after
  filling and spilling.
- Balatro demonstrates the value of visible rule-modifying pieces that change a
  run's decisions; the proposal here limits that principle to one readable ball
  anomaly rather than importing a full build system.

## References consulted

- Nintendo, Splatoon 3 gameplay: https://splatoon.nintendo.com/en/gameplay/
- Portal Wiki, Gels: https://theportalwiki.com/wiki/Gels
- World Curling, curling basics: https://worldcurling.org/about/curling/
- World Curling match reports describing draws, hit-and-rolls, raises, and
  take-outs: https://worldcurling.org/
- Nintendo, Suika Game: https://www.nintendo.com/us/store/products/suika-game-switch/
- USGS, drainage area and fill-and-spill depressions:
  https://water.usgs.gov/themes/hydrofabric/drainage-area/
- USGS, watershed runoff: https://www.usgs.gov/water-science-school/science/runoff-surface-and-overland-water-runoff
- Gamblin, underpainting and ground layers:
  https://gamblincolors.com/underpainting-2/
- Winsor & Newton, Underpainting White:
  https://eu.winsornewton.com/en-row/products/artists-oil-colour-underpainting-white-fast-drying
- Balatro official site: https://www.playbalatro.com/
