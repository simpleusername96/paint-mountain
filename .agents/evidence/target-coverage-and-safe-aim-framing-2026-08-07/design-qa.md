---
type: evidence
status: archived
created: 2026-08-07
last_reviewed: 2026-08-07
topic: target-coverage clarity and authored-first safe Aim Lock framing
scope: Korean Windows release at 1280x720 in Stage 01 Aim Lock, Stage 30 Aim Lock, and painted-contact states
source: exported PaintMountain.exe after scripts/verify.ps1 passed on 2026-08-07
related:
  - ../../execplans/2026-08-07-target-coverage-and-safe-aim-framing.md
  - ../../design/ART_DIRECTION.md
  - ../../design/UIUX_GUIDELINES.md
  - ../../../docs/design-spec.md
  - ../../../docs/technical-architecture.md
---

# Target Coverage and Safe Aim Framing UIUX Evidence

UIUX gate evidence:

- Surface: Paint Mountain Windows desktop gameplay HUD and Compatibility-rendered terrain.
- Invocation depth: Level 3 screen change. Camera composition, dry target classification, paint presentation, and localized HUD/result meaning changed.
- Files/screens touched: terrain shader; coverage translations; shared HUD consumers through existing keys; Aim Lock camera director/framer; Stage 01 Aim Lock; Stage 30 Aim Lock; painted-contact state.
- Primary task checked: Target Area is identifiable before firing, saturated visible paint begins at the authoritative 0.5 score threshold, and Aim Lock contains every canonical playable-top point, summit-region headroom, cannon, muzzle, and default impact at 48-degree FOV.
- Viewports checked: Korean 1280x720 from the exported Windows release. This is the project's declared desktop delivery baseline.
- States checked: Stage 01 Aim Lock, Stage 30 Aim Lock, and Stage 01 after real target contact and coverage gain.
- Accessibility checks: Existing keyboard and focus ownership were not changed. Visible labels and numbers accompany coverage, target, wind, shots, and Finish state; the target distinction is not conveyed by color alone because the HUD says `목표 영역`. The focused localization/HUD checks passed. No new dialog, form, icon-only action, motion behavior, or custom input control was added.
- Screenshots or fallback evidence: [Stage 01 Aim Lock](stage-01-aim-lock-1280x720.png), [Stage 30 Aim Lock](stage-30-aim-lock-1280x720.png), and [painted target contact](painted-target-contact-1280x720.png). All are separate 1280x720 PNGs from the final exported executable and were inspected at native resolution.
- Exceptions accepted: Narrow web/mobile and 200-percent browser zoom are not applicable to this fixed-baseline Godot Windows desktop game. Broader resolution and manual keyboard matrices were not repeated because this change added no control or responsive-layout owner.
- Remaining warnings: Stage 30 necessarily makes the cannon small to keep its 240x160 m playable top and summit visible at unchanged 48-degree FOV; the dotted trajectory keeps the cannon-to-impact relationship legible. The one-time Stage 01 hint wraps tightly in Korean but stays inside its container and does not overlap the cannon, trajectory, Fire, or aim controls. Final gameplay feel and aesthetic approval remain the user's decision.
- Result: passed.

## Native-size findings

- Stage 01 remains close to its authored scale: the mountain dominates the middle and upper frame, the cannon is visible in the lower foreground, and the full top and first impact remain inside the safe frame.
- Stage 30 now shows the complete playable mountain silhouette, highest summit, upper impact marker, cannon, muzzle relationship, and edge HUD without world/HUD overlap. Exact point-set projection avoids the excessive retreat seen in the rejected merged-AABB exploration.
- Dry Target Area reads as the brighter neutral route surface against quieter non-target rock. It remains lower salience than blue paint, trajectory dots, and mechanism glyphs.
- The painted-contact capture shows a saturated blue target mark, `목표 영역 0.2%`, and a textual `+0.1% · 직접 경로` gain. No filtered blue neighbor halo suggests unscored painted area.
- The Stage 30 PNG contains the same white Fire-label and dark HUD-text pixel populations as the intact Stage 01 capture; text that appeared absent in a scaled image preview was a preview-rendering artifact, not missing release content.

## Verification

- `scripts/verify.ps1 -GodotPath <pinned Godot 4.7.1 console>`: passed.
- Windows Desktop release export to `builds/windows/PaintMountain.exe`: passed.
- Three exported background capture runs: passed with exit 0.
- Focused paint, localization, HUD truth, point-set composition, and lifecycle camera-safety contracts: passed.
