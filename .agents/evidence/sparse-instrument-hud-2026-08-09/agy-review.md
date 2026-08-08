### Read-Only Technical & Visual UX/UI Critique: Paint Mountain

Based on visual inspection of the runtime screenshots ([`03-aim-stage30-1280x720.png`](file:///D:/npjt/paint-mountain/.agents/evidence/casual-shared-ui-refresh-2026-08-08/03-aim-stage30-1280x720.png), [`05-settings-stage30-1280x720.png`](file:///D:/npjt/paint-mountain/.agents/evidence/casual-shared-ui-refresh-2026-08-08/05-settings-stage30-1280x720.png), and [`06-aim-stage30-1920x1080-en.png`](file:///D:/npjt/paint-mountain/.agents/evidence/casual-shared-ui-refresh-2026-08-08/06-aim-stage30-1920x1080-en.png)) and analysis of [UIUX_GUIDELINES.md](file:///D:/npjt/paint-mountain/.agents/design/UIUX_GUIDELINES.md), [ART_DIRECTION.md](file:///D:/npjt/paint-mountain/.agents/design/ART_DIRECTION.md), [`hud.tscn`](file:///D:/npjt/paint-mountain/scenes/ui/hud/hud.tscn), [`hud_controller.gd`](file:///D:/npjt/paint-mountain/src/ui/hud_controller.gd), [`settings_screen.gd`](file:///D:/npjt/paint-mountain/src/ui/screens/settings_screen.gd), and [`mechanism_loadout_planner.gd`](file:///D:/npjt/paint-mountain/src/stage_generation/mechanism_loadout_planner.gd), here is the implementation-oriented critique.

---

### 1. Five Strongest Visual Problems (Grounded in Screenshot Regions)

1. **Massive Right-Rail Panel Obstructing Mountain Topography**
   - **Coordinates / Region**: Upper-to-Mid Right Edge (`x: 1088..1256`, `y: 24..530` at 720p; `x: 1728..1896`, `y: 24..530` at 1080p).
   - **Defect**: [`run_status_card.tscn`](file:///D:/npjt/paint-mountain/scenes/ui/hud/run_status_card.tscn) renders as a 168px wide × 506px tall opaque white card containing 4 separated metric sections plus a Finish button. It covers over 35% of the mountain's right flank and support shell, violating [UIUX_GUIDELINES.md](file:///D:/npjt/paint-mountain/.agents/design/UIUX_GUIDELINES.md#aiming-hud-hierarchy) ("keep visible mountain routes free of persistent panels").

2. **Hardcoded Top-Left Offsets Causing Severe HUD Misalignment at 1080p**
   - **Coordinates / Region**: Lower Control Grou
<truncated 7000 bytes>
    $$\text{Score} = w_1 \cdot H_{\text{norm}} + w_2 \cdot \text{DivergenceScore} - w_3 \cdot \text{SlopePenalty}$$
     Setting $w_1 = 2.0$ guarantees that mid/upper terrain anchors strictly rank above low-elevation base anchors.

4. **Vertical & Horizontal Spatial Clearance**:
   - Extend `_separated_from_selected()` to enforce vertical elevation separation $\Delta H = |Y_{\text{glyph}_A} - Y_{\text{glyph}_B}| \ge 0.15 \cdot (Y_{\text{max}} - Y_{\text{min}})$ alongside 2D horizontal clearance (`GLYPH_SEPARATION_MARGIN`).

---

### 5. Implementation Risks to Avoid

- **Unreachable Stage Mechanisms**: Placing glyphs above $H_{\text{norm}} > 0.85$ or behind steep ridges can render them impossible to hit with standard cannon trajectories, breaking stage solvability.
- **CanvasLayer Resolution Drift**: Converting top-left fixed offsets to anchors without testing multi-aspect viewports (16:9, 16:10, 21:9) can push edge controls off-screen.
- **Bypassing `HUDController` Signal Architecture**: Mutating UI state directly from child scripts instead of routing through `HUDController` will cause state desynchronization between Korean/English locale updates and game phase transitions.
- **Recursive Settings Sync Loops**: Mutating `DisplayServer` window properties inside `_on_settings_changed` without guard flags (`_syncing`) can trigger recursive window resize events and display flickering.

---

### Summary of Completed Review

- **Inspected files & screenshots**: All 3 runtime evidence screenshots and 6 core script/spec files were reviewed without editing any project files.
- **Visual hierarchy**: Grounded 5 key visual issues with precise coordinates and screenshot references.
- **Refreshed HUD composition**: Proposed a clean, sparse, icon-driven HUD layout adhering to [UIUX_GUIDELINES.md](file:///D:/npjt/paint-mountain/.agents/design/UIUX_GUIDELINES.md).
- **Settings bug & placement algorithm**: Provided root-cause code hypothesis for screen distortion and a mathematical 4-step rule for mid/high terrain glyph generation.