---
type: evidence
status: active
created: 2026-08-20
last_reviewed: 2026-08-20
scope: catalog-v11 all-stage Red/Green target-band migration and representative rendered/runtime proof
related:
  - ../../execplans/2026-08-20-cross-stage-ui-theme.md
  - ../../../docs/source-brief.md
  - ../../../docs/design-spec.md
  - ../../../docs/technical-architecture.md
---

# All-stage Red/Green target-band migration evidence

## Implemented catalog contract

- Catalog v11 manifest:
  `29c58dabab787164b600e4562ce0ec848212a655cecd8da763da14168130694e`.
- All 30 stages use the existing exclusive latest-writer Red/Green ownership,
  signed Paint Score, inclusive target band, finite deterministic deal, current
  plus next-two preview, Same Deal, and New Deal owners.
- Stage 01-06 shot counts, rule weights, bands, allowed kinds, and default seeds
  remain at their accepted values.
- Stage 07-15 use six roots; Stage 16-30 use seven. The late tier stays at seven
  because an existing three-child Splitter loadout with eight roots would need
  24 residents and violate the fixed 21-body safety cap.
- Stage 07 onward cycles through Both Add, Green-minus-Red, Red-minus-Green,
  Green-only, and Red-only rules. Target minima step from 7 to 10 in six-stage
  tiers; every band is four points wide.
- Every Stage 07-30 deal allows all three implemented kinds and requires at
  least one Impact Burst plus one Apex Split. Standard remains mandatory, both
  colors remain present, and the final two opposite-color Standards are the
  correction reserve.

## Immutable migration proof

The builder validated the prior content-addressed layout payload, duplicated it
into a new bundle, updated only its profile/layout version identity, recomputed
the payload hash, hydrated it against the new StageData, and promoted the
canonical pointer only after full bundle verification.

| Bundle | Files | Aggregate path+file SHA-256 |
| --- | ---: | --- |
| v10 source `fe93d0ac…f01` | 92 | `58B1BA93223EA3048A9CC9697EDE818D85AD87A13F4B943B37B62DC3373F3D00` |
| v11 active `29c58dab…94e` | 92 | `D62CB2C046401B9CD596B6858C568E7DFB7C6BDE25863A298DEB7BB5C4A25B4F` |

`generation_v11_materialization_test.gd` compares all 30 v10/v11 height,
footprint, target-mask, physical coverage, route, mechanism, decoration,
camera-witness, and cannon/terrain identities. The v11 payload hashes reproduce
and every layout hydrates under the new rule contract. No file in the v10
bundle is task-modified.

## Structural and running checks

- `all_stage_target_band_rule_test.gd`: 30 valid rule profiles and 480
  deterministic deals (16 seeds/stage), including required kinds, colors,
  reserve, exact length, capacity, and replay identity.
- `target_band_stage_runtime_smoke_test.gd`: Stage 01-07/18/30 instantiate; each
  publishes the bounded queue and admits its dealt root. Stage 07/18/30 then
  executes real projectile physics, writes authoritative target paint, and
  publishes a target-band result.
- `stage_select_rule_truth_test.gd`: early and later stages expose target band,
  Red/Green weights, and ball kinds through the shared StageRail/detail owner.
- `cross_stage_ui_theme_test.gd`: all 30 stages use the same Cannon Focus HUD,
  fixed 0-100 scale, queue, and ResultSummary.
- `save_v6_migration_test.gd`: a valid former scalar result stays preserved but
  is not returned or displayed as Paint Score; the next target-band clear can
  replace it normally.
- Catalog check, deterministic deal check, stage-30 progression, baked-layout,
  Finish, and queue progression checks pass.

## Production-render inspection

The six PNGs in this directory come from the current exported Windows release,
Godot 4.7.1 Compatibility renderer. Artifact size is `121,978,464` bytes and
SHA-256 is
`B0C2F5CEBBC8BF3988680BB549B12392F8FC49A493D2151F8CA639586729053F`.

| File | State | Stage | Locale / viewport | SHA-256 |
| --- | --- | ---: | --- | --- |
| `01-aim-stage07-ko-1280x720.png` | Cannon Focus Aim | 07 | ko / 1280x720 | `521DA1EE…1A204` |
| `02-result-stage07-ko-1280x720.png` | target-band Clear fixture | 07 | ko / 1280x720 | `517AE758…8913D` |
| `03-aim-stage18-ko-1280x720.png` | Cannon Focus Aim | 18 | ko / 1280x720 | `F906F53F…6156C` |
| `04-result-stage18-ko-1280x720.png` | target-band Clear fixture | 18 | ko / 1280x720 | `26552553…48FAA` |
| `05-aim-stage30-en-1920x1080.png` | Cannon Focus Aim | 30 | en / 1920x1080 | `44BE8E48…EB05` |
| `06-result-stage30-en-1920x1080.png` | target-band Clear fixture | 30 | en / 1920x1080 | `B499DB05…A5620` |

Visual inspection confirms that Stage 07/18/30 all show the vertical 0-100
scale, signed Red/Green rule, six/seven-shot count, actual varied queue tokens,
angle/Fire/power controls, real terrain, and target-band Result actions without
clipping. The Result images use the existing delivery presentation fixture:
`StageController` performs the terminal transition and the fixture supplies an
in-band score to inspect the Clear branch. They are not physical clear or
balance claims; the separate runtime smoke owns actual fire/paint evidence.

## Limits

The rule/data migration is proven for all 30 stages, and representative later
stages execute actual fire, paint, and result paths. This is not a human
playtest, authored solver clear, or claim that every target band is fully
balanced. The complete suite, repository verification, fresh Windows/Web
exports, Web static verification, and 22-image Windows capture matrix pass.
The final built-Web live journey remains pending because the available browser
bridge was not trusted. Nothing was published to itch.io.
