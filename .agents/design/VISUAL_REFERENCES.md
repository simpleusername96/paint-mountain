---
type: evidence
status: active
created: 2026-08-04
last_reviewed: 2026-08-10
topic: Paint Mountain visual references and anti-references
scope: provenance, authority, and permitted interpretation of project visual evidence
source: ../../docs/handoffs/gameplay-visual-reset-2026-08-03/source-map.md
related:
  - DESIGN.md
  - ART_DIRECTION.md
  - UIUX_GUIDELINES.md
  - ../execplans/2026-08-10-essential-ui-fidelity.md
  - ../../docs/reports/screen-audit-2026-08-10/index.html
---

# Paint Mountain Visual References

## Purpose

Register the visual evidence used by Paint Mountain and state what each source
can and cannot decide. This document prevents historical captures, generated
concepts, or asset previews from silently becoming product requirements.

## Sources

### Primary target comparator

![Primary user-supplied target comparator](../../docs/handoffs/gameplay-visual-reset-2026-08-03/visuals/01-target-reference.png)

- Image: [primary target comparator](../../docs/handoffs/gameplay-visual-reset-2026-08-03/visuals/01-target-reference.png)
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

![Representative generated Stage 1 concept](../../docs/concepts/execplan-outcome-2026-08-03/03_stage1_default_aim.png)

- Gallery: [generated outcome concept board](../../docs/concepts/execplan-outcome-2026-08-03/index.html)
- Images: `../../docs/concepts/execplan-outcome-2026-08-03/01_stage_progression.png`
  through `07_stage3_clear.png`.
- Use for: warm off-white palette, faceting, apparent thickness, wall join,
  composition options, camera depth, Korean UI tone, and state readability.
- Do not use as: a runtime screenshot, feasibility proof, literal geometry,
  exact HUD contract, stage seed, mechanism placement, or acceptance evidence.

### Historical aiming-HUD direction

![Selected Command Columns HUD](../../docs/concepts/ui-layout-directions-2026-08-06/command-columns-hud.png)

- Image: [Command Columns HUD](../../docs/concepts/ui-layout-directions-2026-08-06/command-columns-hud.png)
- Provenance: generated from the current Stage 30 running render and selected by
  the user on 2026-08-06 for implementation.
- SHA-256:
  `1B4AF8DDFF91D5A23238296EC3C886F17CA18E2FC00F2FA93811B50EEEEDCA0F`.
- Historical use: the aiming HUD's narrow command/status columns,
  bottom-center Fire action, warm restrained panel treatment, and compact Korean
  typography rhythm.
- Historical runtime/spec details omitted or simplified in the image included
  focusable Gear, direction value, power-step controls, Aim Lock/Map Inspection,
  dynamic weather detail, disabled/readiness states, and authoritative live
  values. These are not current requirements.
- Do not use as: world-render authority, literal stage/mechanism placement,
  runtime proof, a reason to fake state, or permission to remove functionality.
- Status: superseded on 2026-08-08 by the user's casual shared UI direction.
  Preserve only the still-valid real actions and edge-first hierarchy recorded
  in `UIUX_GUIDELINES.md`; do not preserve the literal columns, panel details,
  or the weather instrumentation retired on 2026-08-09.
- The sibling `quiet-edge-hud.png` and `instrument-rail-hud.png` remain historical
  alternatives, not active directions.

### Historical anti-reference

![Rejected historical build capture](../../docs/handoffs/gameplay-visual-reset-2026-08-03/visuals/02-current-build.png)

- Image: [rejected historical build](../../docs/handoffs/gameplay-visual-reset-2026-08-03/visuals/02-current-build.png)
- Provenance: user-supplied capture of the rejected build.
- SHA-256:
  `AEDE8587A122B1977AE4C87FA551E8CE6383AC94B0A9D3EE39024E29F184E173`
- Use for: detecting recurrence of the gray wall/mound, card-like depth,
  dominant flat foreground, oversized black cannon, weak route/mechanism
  visibility, oversized trajectory dots, and legacy HUD hierarchy.
- Do not use as: proof of the current revision or a layout to preserve.

### Current exploratory casual UI matrix

- Gallery: [Casual UI Directions](../../docs/concepts/casual-ui-directions-2026-08-08/index.html)
- Images: `../../docs/concepts/casual-ui-directions-2026-08-08/01-paper-toy-main-menu.png`
  through `09-field-guide-aim-view.png`.
- Provenance: nine independent ImageGen outputs grounded in the matching
  running-game capture and the primary target comparator.
- Use for: comparing three component languages across Main Menu, Stage Select,
  and Aim View: Paper Toy Adventure, Sticker Arcade, and Quiet Field Guide.
- Historical recommendation: borrow Paper Toy's tactile surfaces for menus and
  Field Guide's restraint for the gameplay HUD. The later approved Quiet
  Context system below supersedes this recommendation.
- Do not use as: runtime proof, approved implementation authority, a source of
  gameplay values, or permission to add invented actions. The implemented Theme
  and `UIUX_GUIDELINES.md` remained authoritative until the user selected the
  later concept.

### Approved Quiet Context UI system

![Approved Quiet Context UI](../../docs/concepts/full-ui-refresh-2026-08-09/revised-02-context-line.png)

- Image: [approved Quiet Context UI](../../docs/concepts/full-ui-refresh-2026-08-09/revised-02-context-line.png)
- Provenance: ImageGen revision grounded in the current running Stage 30 Aim
  View, selected explicitly by the user on 2026-08-09.
- SHA-256:
  `715DA06D3825E97B0C89975153289ECC0BF11F41A9C93A5129DC8397E2DDC33A`.
- Current use: direct edge-aligned status, warm paper-white field, navy type,
  blue primary action, left coverage rail, centered Fire, right-side
  angle/power instruments, minimal containment, and one
  quiet lower-edge context legend with inline input/action pairs.
- Apply across: Main Menu, Stage Select, Briefing, Aim View, Map View, Shot
  Follow, Pause, Settings, transient feedback, and Result using the same Theme,
  spacing, divider, action, focus, and disabled-state principles.
- Preserve beyond the still: real Gear, Finish, loading/failure, Map/Follow,
  focus, localization, settings, and result behavior even when the generated
  image omits or simplifies them.
- Do not copy: generated mountain/glyph placement, fake state, missing actions,
  text artifacts, or exact pixels that conflict with responsive layout. Do not
  retain detached dark keycap tiles or visible target-derived yaw.
- Status: approved visual authority for the UI system. Running-build captures
  remain required implementation and acceptance evidence.

### Approved Essential UI fidelity set

- Report: [2026-08-10 screen audit and refined targets](../../docs/reports/screen-audit-2026-08-10/index.html)
- Provenance: seven ImageGen edits grounded in the matching running-game
  captures and the already approved Quiet Context redesigns. The user explicitly
  approved the retained style and requested this copy-and-boundary refinement on
  2026-08-10.
- Images and SHA-256:
  - `../../docs/reports/screen-audit-2026-08-10/assets/refined/01-main-menu-refined.png`
    — `3180F3CBE62ADBE6A7C4EF9DDB20B790199037551CC69CA3A4D47CACF761A0AB`
  - `../../docs/reports/screen-audit-2026-08-10/assets/refined/02-stage-select-refined.png`
    — `534AE4D710034E7812CBC9463A8F1E33CD02A790010B6C683D17680497CC788B`
  - `../../docs/reports/screen-audit-2026-08-10/assets/refined/03-briefing-refined.png`
    — `6A391F80DAF526A4785CF7189FDE779C6B2DD1DADB2A4F03DBDD5A3245B5D6D5`
  - `../../docs/reports/screen-audit-2026-08-10/assets/refined/04-aim-view-refined.png`
    — `38F75235B126CC5995BA53E61665AEE9DCD397B27CA92939B08BE90ED10E76B1`
  - `../../docs/reports/screen-audit-2026-08-10/assets/refined/08-settings-refined.png`
    — `F6C5A4C34D0B32A14C2D8908ACCDE35D2630C623DF6F2B9B458AA3EBB99B845E`
  - `../../docs/reports/screen-audit-2026-08-10/assets/refined/09-manual-result-refined.png`
    — `BAB75443FE83FE5D5034ACE8A03FB844E2ED8252BBE4BD7693754D04BE449604`
  - `../../docs/reports/screen-audit-2026-08-10/assets/refined/10-timeout-result-refined.png`
    — `178BB88187B11BF6CCD87D17348AA8DEE61908E74228A53A5735B198D474F28B`
- Use literally for: which normal-screen copy is visible, the absence of
  duplicated key names inside actions, the absence of decorative hairlines and
  repeated unselected-card outlines, primary/secondary/tertiary action hierarchy,
  and the intended relative UI/world occupancy at a 16:9 baseline.
- Use directionally for: exact responsive coordinates, mountain shape, terrain
  seed, paint marks, lighting details, glyph placement, camera interpolation,
  and text rasterization. Runtime layout must use real translated strings and
  authoritative game state.
- Screen scope: Main Menu, Stage Select, Briefing, Aim View, Settings, Manual
  Result, and Timeout Result. The approved Quiet Context image and the existing
  three screen-audit improvements remain the direction for Map View, Shot Follow,
  and Pause until a later user revision replaces them.
- Status: approved fidelity targets for the named screens. They supersede the
  earlier screen-audit improvement images only for those seven screens, and
  supersede the Quiet Context reference only where visible copy, separator use,
  or screen composition conflicts. Running-build captures remain required
  implementation and acceptance evidence.

### Historical remediation report

- Report: [historical remediation report](../../docs/remediation-report.html)
- Use for: prior diagnosis and approved-asset research context.
- Do not use as: current visual authority. Candidate previews and generated
  images remain procurement or exploration evidence.

### Textual sources

- `../../docs/source-brief.md`: baseline product and presentation requirements.
- `../../docs/design-spec.md`: working UI, art, camera, and interaction interpretation.
- `../execplans/2026-08-03-gameplay-visual-reset.md`: active
  implementation sequence and currently accepted composition details.
- `../../docs/asset-licenses.md`: approved local asset and license record.
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
- The HUD is visually secondary and edge-aligned. Its current canonical
  behavior and component rules come from `UIUX_GUIDELINES.md`; the approved
  Quiet Context image supplies the visual hierarchy while running code and
  active specs preserve real behavior.
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
