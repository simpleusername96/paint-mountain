---
type: evidence
status: active
created: 2026-08-04
last_reviewed: 2026-08-04
topic: Paint Mountain visual references and anti-references
scope: provenance, authority, and permitted interpretation of project visual evidence
source: ../handoffs/gameplay-visual-reset-2026-08-03/source-map.md
related:
  - README.md
  - ART_DIRECTION.md
  - UIUX_GUIDELINES.md
---

# Paint Mountain Visual References

## Purpose

Register the visual evidence used by Paint Mountain and state what each source
can and cannot decide. This document prevents historical captures, generated
concepts, or asset previews from silently becoming product requirements.

## Sources

### Primary target comparator

![Primary user-supplied target comparator](../handoffs/gameplay-visual-reset-2026-08-03/visuals/01-target-reference.png)

- Image: [primary target comparator](../handoffs/gameplay-visual-reset-2026-08-03/visuals/01-target-reference.png)
- Provenance: original user-supplied design reference.
- SHA-256:
  `1E32C82DF16DBE0809458DC7A7D9385C7EB3A61D0240BD8551B40F02190E4538`
- Use for: dominant thick low-poly mountain, layered terraces and routes, small
  cannon, sparse HUD, paint contrast, mechanism readability, bright restraint,
  and overall visual ambition.
- Do not copy: literal mountain topology, mechanism locations, English copy,
  horizontal coverage bar, bottom-right Restart, exact painted state, or implied
  physics. Later accepted UI decisions supersede those image details.

### Secondary concept board

![Representative generated Stage 1 concept](../concepts/execplan-outcome-2026-08-03/03_stage1_default_aim.png)

- Gallery: [generated outcome concept board](../concepts/execplan-outcome-2026-08-03/index.html)
- Images: `../concepts/execplan-outcome-2026-08-03/01_stage_progression.png`
  through `07_stage3_clear.png`.
- Use for: warm off-white palette, faceting, apparent thickness, wall join,
  composition options, camera depth, Korean UI tone, and state readability.
- Do not use as: a runtime screenshot, feasibility proof, literal geometry,
  exact HUD contract, stage seed, mechanism placement, or acceptance evidence.

### Historical anti-reference

![Rejected historical build capture](../handoffs/gameplay-visual-reset-2026-08-03/visuals/02-current-build.png)

- Image: [rejected historical build](../handoffs/gameplay-visual-reset-2026-08-03/visuals/02-current-build.png)
- Provenance: user-supplied capture of the rejected build.
- SHA-256:
  `AEDE8587A122B1977AE4C87FA551E8CE6383AC94B0A9D3EE39024E29F184E173`
- Use for: detecting recurrence of the gray wall/mound, card-like depth,
  dominant flat foreground, oversized black cannon, weak route/mechanism
  visibility, oversized trajectory dots, and legacy HUD hierarchy.
- Do not use as: proof of the current revision or a layout to preserve.

### Historical remediation report

- Report: [historical remediation report](../remediation-report.html)
- Use for: prior diagnosis and approved-asset research context.
- Do not use as: current visual authority. Candidate previews and generated
  images remain procurement or exploration evidence.

### Textual sources

- `../source-brief.md`: baseline product and presentation requirements.
- `../design-spec.md`: working UI, art, camera, and interaction interpretation.
- `../../.agents/execplans/2026-08-03-gameplay-visual-reset.md`: active
  implementation sequence and currently accepted composition details.
- `../asset-licenses.md`: approved local asset and license record.
- `../../resources/ui/paint_mountain_theme.tres`: current implemented UI token
  owner, not independent design authority.

## Findings

- The target direction is a bright, faceted, deliberately designed puzzle
  mountain with visible depth layers, not a realistic mountain and not a flat
  height strip.
- Route readability is structural: shelves, terraces, valleys, slopes,
  mechanisms, camera, shadows, and paint must form one legible composition.
- Blue paint and trajectory provide the strongest saturated gameplay contrast;
  environment and UI stay restrained.
- The HUD is visually secondary and edge-aligned, but its current canonical
  layout comes from later user decisions in `UIUX_GUIDELINES.md`, not the
  primary image's literal controls.
- Existing screenshots and scenes can be useful implementation evidence while
  still being wrong as design direction.

## Recommendations

- Start every comparison with the written art or UI spec, then use the primary
  target to judge direction and the rejected capture to catch regressions.
- Name the exact quality being borrowed from an image—such as mass, depth,
  hierarchy, palette, or readability—rather than saying only "match the
  reference."
- If a new user-approved image changes the direction, register its provenance
  here and update the relevant spec. Adding an image alone does not change the
  contract.
- Keep generated concepts clearly labeled and separate from running-build
  evidence.

## Limitations

- A single view cannot prove watertight geometry, parallax, collision, physical
  response, continuous paint, hidden overlap, or responsive UI.
- Generated images may contain impossible geometry, inconsistent object scale,
  fake labels, or interactions Godot does not implement.
- The primary target predates the accepted vertical coverage, centered Fire,
  and gear-owned Restart layout.
- This register does not itself authorize visual testing or establish that the
  current build matches any source.
