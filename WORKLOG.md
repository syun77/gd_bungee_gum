## Door close sound timing

- Goal/status: Play door2 only when closing animation finishes; complete.
- Completed/decisions: Entrance/exit completion branches own close cue; active guard prevents repeats. Opening timing unchanged.
- Files: stage_entrance.gd, stage_exit.gd, sound-effects.md, AGENTS.md, WORKLOG.md.
- Verification: Sound effects, stage entrance and stage exit suites PASS; git diff --check PASS. Known certificate/exit-resource warnings remain.
- Final refactoring: Removed close-phase crossing checks; completion branches handle sound and deactivation together without additional state.
- Blockers: None. Next action: Playtest closing sound timing.

## Door opening / closing sounds

- Goal/status: Assign door1.wav to opening and door2.wav to closing; complete.
- Completed/decisions: Central SoundEffects cues; entrance/exit timeline boundary crossing plays once per opening/closing, including large steps.
- Files: stage_entrance.gd, stage_exit.gd, sound_effects.gd, runtime WAVs, sound spec, AGENTS.md, WORKLOG.md.
- Verification: Headless import completed; sound effects, stage entrance and stage exit suites PASS; runtime WAV byte equality and git diff --check PASS. Existing certificate/editor sandbox and exit-resource warnings remain.
- Final refactoring: Reviewed phase crossings and cue ownership; no extra state/duplicate sound playback, existing timeline and physics unchanged.
- Blockers: None. Next action: Playtest entrance/exit sound balance.

## Brick crash sound

- Goal/status: Assign sounds/crash.wav to block destruction; complete.
- Completed/decisions: Dedicated SoundEffects crash cue plays once per successful gum brick destruction. Normal adhesion retains hit. Runtime WAV is byte-identical to root sound.
- Files: assets/sounds/crash.wav/import, sound_effects.gd, gum_connection.gd, sound/destruction verifiers, sound/brick specs, AGENTS.md, WORKLOG.md.
- Verification: verify_sound_effects PASS (nine overlapping cues/lifetime/cap), verify_breakable_terrain PASS including actual crash stream on hit; asset byte equality and git diff --check PASS. Known certificate/exit-resource/editor sandbox warnings remain.
- Final refactoring: Cue registration stays centralized; verifier uses CLIPS size rather than hard-coded cue count. No sound speed/pitch changes.
- Blockers: None. Next action: Playtest placed bricks for crash sound.

## Stronger brick burst

- Goal/status: Faster and wider fragment scatter; complete.
- Completed/decisions: Chunk launch X1.9/Y1.65, faster spin, grit100–155px/s, dust spread24px and stronger downward arc. Timing0.5s/chunk size unchanged. Transparent canvas128×128/pivot64,56 (sheet512×512) prevents clipping; offset(0,8) unchanged.
- Files: brick-break.mjs, generated PNG/runtime copy/JSON/contact/GIF, verify_breakable_terrain.gd, effect spec, AGENTS.md, WORKLOG.md.
- Verification: Contact sheet inspected; PixelFX checker PASS0warnings; sheet dimensions/empty final/runtime byte equality PASS; Godot destruction/effect lifecycle PASS. git diff --check PASS. Known certificate/editor sandbox/exit-resource warnings remain.
- Final refactoring: All asset dimension/pivot references and verifier expectations aligned; no gameplay/lifetime changes or added dependencies. Temporary checker wrapper removed.
- Blockers: None. Next action: Playtest gum brick hits; updated GIF available.

## PixelFX brick destruction effect

- Goal/status: Create and integrate block destruction effect with PixelFX; complete.
- Completed/decisions: Terracotta rotating chunks12/grit8/translucent dust/short cream impact,0.5s.96×96cells,4×4/16frames incl blank,30fps,pivot48/40. Three render/review rounds refined jitter,stable seeded trajectories,dust/grit and decay. Runtime stage-owned world-frozen Sprite2D spawns only on successful destruction, supports overlap, expires/restart-cleans.
- Files: images/effects/brick-break.mjs, brick_break PNG/JSON/contact/GIF, matching runtime PNG/import, tools/build_brick_break_effect.mjs, brick_break_effect.gd, breakable_terrain.gd, verify_breakable_terrain.gd, specs/brick-break-effect.md, brick tile spec, AGENTS.md, WORKLOG.md.
- Verification: PixelFX checker1pass/0fail/0warnings via temporary wrapper (removed); RGBA/384px/16frames/transparent final/runtime equality PASS. Godot verify_breakable_terrain PASS including effect center/count/slicing/nearest/independent playback/expiry/no ordinary-hit burst; verify_gum PASS incl live Game. git diff --check PASS. Known certificate/exit-resource/editor-sandbox warnings remain. Live graphical game playtest not performed.
- Final refactoring: Sprite owns animation/lifetime only; destruction owns spawn center; sheet and JSON generated together using PixelFX helper APIs. Rebuildable source retained. Existing user Time Attack map edits untouched.
- Blockers: None. Next action: Play placed brown bricks and fire gum; GIF/contact preview available.

## Gum destroys brick tiles

- Goal/status: One-hit gum destruction of brown terrain bricks; complete.
- Completed/decisions: Swept OUTBOUND tip hits TerrainTiles source4/(0,0) → erase exactly one cell → rebuild remaining Terrain collision/rims → retract without attachment/force. READY/connected lines do not destroy. Instantiated scene changes only; reload restores authored blocks.
- Files: breakable_terrain.gd, terrain_rectangles.gd, gum_connection.gd, MapEdit stage_exchange.gd, verify_breakable_terrain.gd, brick/mapedit specs and README, AGENTS.md, WORKLOG.md.
- Verification: New real-physics brick suite PASS (neighbor isolation, repeat shot through removed collision, normal attachment, wrapping geometry and scene reload); verify_gum/verify_controls/verify_gum_path/verify_theater_stage PASS. Known certificate/exit-resource warnings persist. git diff --check PASS.
- Final refactoring: Extracted shared rectangle partitioning from editor exchange for runtime use; runtime rebuilt shapes track TileMap/body transforms and rim rectangles consistently. No editor-only dependency in gameplay.
- Blockers: None. Next action: Play a MapEdit-authored source4 brick layout and fire X/Square; no new default placements added.

## Placement outline settings

- Goal/status: Per-category optional outline color, default disabled; complete.
- Completed/decisions: Tile settings checkbox/color well; optional outlineRGB persisted with style. Name/fill/shortcut changes retain outline; reset disables. Shared inset2px/reduced-small-cell drawing for map/preview/minimap and markers (round main-map markers retain round outline). Editor-only settings.
- Files: Canvas.swift, main.swift, tools/mapedit/README.md, specs/mapedit.md, AGENTS.md, WORKLOG.md.
- Verification: Swift app build PASS; AppKit bitmap probe PASS default/missing-setting disabled, encode/decode persistence, brick virtual-category red edge pixels and blue center retained; image inspected. git diff --check PASS. Live settings UI gestures not exercised.
- Final refactoring: Centralized outline rendering/category resolution, reused placement rectangles, deactivate outline color well on close/load/disable. No map exchange changes.
- Blockers: None. Next action: Save/restart MapEdit, select category → タイル設定 → enable outline and choose color.

## Fix breakable category color

- Goal/status: Apply dedicated category color to brick cells, preview and minimap; complete.
- Cause/decision: TerrainTiles storage kind bypassed virtual brush style. MapDocument.placementCategory resolves layer+tile; shared Canvas tile-aware placementColor routes all three render paths.
- Files: MapDocument.swift, Canvas.swift, specs/mapedit.md, specs/breakable-block-tile.md, AGENTS.md, WORKLOG.md.
- Verification: Swift app build PASS; Canvas color probe PASS custom color/change/reset, ordinary terrain isolation, nil/nonterrain mapping. git diff --check PASS. No live GUI gesture test.
- Final refactoring: Single category resolver and shared color overload; no duplicate source-ID checks in draw paths, placementStyles refresh already invalidates canvas/minimap.
- Blockers: None. Next action: Save and restart MapEdit via run.command; existing saved color automatically applies to brick cells. Godot sprite colors are unchanged.

## Expose breakable block category

- Goal/status: Dedicated MapEdit placement category for brown brick; complete.
- Completed/decisions: Model exposes BreakableBlocks virtual brush backed by TerrainTiles source4, filters duplicate from ground palette. UI names it 破壊可能ブロック/茶色レンガ, widens sidebar/buttons, edits category style by selected button. No storage/collision/destruction changes.
- Files: MapDocument.swift, main.swift, Canvas.swift, MapEdit README, specs/mapedit.md, specs/breakable-block-tile.md, AGENTS.md, WORKLOG.md.
- Verification: Swift app build PASS; model probe PASS category/filter/mapping/placement/JSON roundtrip/snapshot restore. git diff --check PASS. Live UI and gesture Undo/Redo not exercised.
- Final refactoring: Centralized category/tile/layer mapping in model, preserved palette label indexing after filtering, absent brick palette produces no virtual category.
- Blockers: None. Next action: Save current edits, restart MapEdit via run.command, copy stage from Godot again; choose 破壊可能ブロック. Destruction gameplay remains unimplemented.

## Integrate brown brick tile

- Goal/status: Register brown brick for Godot/MapEdit terrain painting; complete.
- Decisions: Shared TileSet source4/(0,0), existing TerrainTiles collision pipeline; no destruction rules or unsolicited map placement. Generator preserves registration.
- Files: theater_tileset.tres, build_theater_stage.gd, stage_exchange.gd, verify_mapedit.gd, brick import metadata, specs/breakable-block-tile.md, AGENTS.md, WORKLOG.md.
- Verification: Godot import completed. Headless resource/both-stage palette/placement validation/snapshot/terrain occupancy probe PASS; verify_theater_stage PASS1212cells/27shapes/76one-way/59corners. Editor verify_mapedit stopped at pre-existing scene-root acquisition assertion line16, before new assertions; full Undo/Redo remains unverified. Known sandbox editor .NET socket/settings warnings. git diff --check PASS.
- Final refactoring: reviewed shared source IDs, generator parity and collision ownership; no duplicate collision or new layer required.
- Blockers: None for image integration. Next action: Copy stage from Godot into MapEdit, choose brown tile in TerrainTiles. Gameplay destruction requires a separate rule specification.

## Brown breakable block variant

- Goal/status: Create brown brick-style alternative; complete.
- Completed/decisions: Built-in imagegen edited cream reference into terracotta/ochre/chocolate colors. Selected fully opaque face; rejected transparent-hole generation. Preserve cream alternative.
- Files: restaurant_breakable_brick{,_source}.png under images/tilesets, matching runtime tile, specs/breakable-block-tile.md, AGENTS.md, WORKLOG.md.
- Verification: 32×32/RGBA/full opacity/runtime byte equality PASS;10× nearest preview inspected. Final review: consistent alternative filenames, no gameplay changes.
- Blockers: None. Next action: User can select artwork; TileSet/behavior integration remains separate.

## Breakable block tile artwork

- Goal/status: Create restaurant-style breakable block tile; complete.
- Completed/decisions: Built-in imagegen cream/coral ceramic with dark teal cracks; point-resized32×32 RGBA, transparent corners; artwork only.
- Files: images/tilesets/restaurant_breakable_block{,_source}.png, matching runtime PNG, specs/breakable-block-tile.md, AGENTS.md, WORKLOG.md.
- Verification: Pillow asserts32×32/RGBA/transparent alpha and identical runtime bytes PASS;10× nearest preview inspected. Final review: one tile plus source, no unnecessary code changes.
- Blockers: None. Next action: Optional TileSet and destruction gameplay integration when requested.

## Remove HUD menu button

- Goal/status: Remove on-screen MENU button; complete.
- Completed/decisions: Remove HUD/Menu and pressed connection; OPTIONS/Esc retain pause menu. Preserve user-authored score/timer typography/layout.
- Files: game.tscn, game.gd, stage/pause verifiers, stage/pause/baguette/implementation specs, AGENTS.md, WORKLOG.md.
- Verification: verify_stage_select and verify_pause_menu PASS (OPTIONS/Esc, freeze/resume/retry/selection); git diff --check passed; no stale HUD/Menu callers remain. Refactoring: deleted stale button wiring, tests use input actions/pad. Blockers: None. Next action: Optional F5 visual check.

## HUD score and timer themes

- Goal/status: Resource-based score/time text editing; complete.
- Decisions: Dedicated hud_score_theme.tres and hud_timer_theme.tres; preserve white24px/2px shadow appearance. Author hidden HUD/Timer in game.tscn and show in Time Attack; remove dynamic Score duplication/local shadow overrides. Existing customized popup theme untouched.
- Files: two Theme resources, game.tscn, game.gd, specs/debug-text.md, AGENTS.md, WORKLOG.md.
- Verification: verify_stage_select and verify_music_note_pickup PASS (stage flow, scoring, independent timer/score, popup lifecycle); git diff --check passed. Refactoring: scene owns both labels, themes own all typography. Blockers: None. Next action: Open HUD Theme resources in Godot for tuning.

## Food score300

- Goal/status: Set food points and popup to300; complete.
- Completed/decisions: Shared FoodCollectible.POINTS now300; score and popup consume it. Updated exact-point/popup expectations and current specs/knowledge. Baguette30/note10 retained.
- Files: food_collectible.gd, stage/pickup/reel verifiers, food/baguette/note specs, AGENTS.md, WORKLOG.md.
- Verification: verify_stage_select, verify_music_note_pickup and verify_food_reel PASS (300point credit/popup, duplicate safety, death persistence); git diff --check passed. Final refactoring review confirms one shared score/popup source. Known certificate/resource-cleanup warnings remain. Blockers: None. Next action: Optional F5 pickup check.

## Remove gum status HUD text

- Goal/status: Remove gum-state debug text; complete.
- Completed/decisions: Remove HUD/Status and Game status formatting/update entirely. Keep menu/score/timer and gum visuals/diagnostics.
- Files: game.gd, game.tscn, specs/gum-flight-return.md, specs/keyboard-controls.md, AGENTS.md, WORKLOG.md.
- Verification: verify_stage_select PASS; git diff --check passed; no remaining runtime status-label references. Final refactoring removed unused label reference and formatter. Blockers: None. Next action: Optional F5 appearance check.

## Dedicated score popup theme

- Goal/status: Resource-based score typography editing; complete.
- Decisions: Dedicated Theme score_popup_theme.tres owns default font/size and Label fill/outline/width. Remove all local typography overrides; preserve existing appearance, shared by10/30/1000.
- Files: score_popup_theme.tres, score_popup.gd, specs/music-note-item-assets.md, AGENTS.md, WORKLOG.md.
- Verification: verify_music_note_pickup PASS (all pickup popups/points/lifetimes); git diff --check passed. Final refactoring review: one Theme authority, independent from debug UI. Blockers: None. Next action: Open score_popup_theme.tres in Godot and tune Theme properties.

## Locate score typography settings

- Goal/status: Explain where to tune score-number outline; complete.
- Findings: score_popup.gd lines12–14 override fill/outline/width; debug_theme.tres owns shared font and24px default size. Theme outline changes cannot override the popup local overrides.
- Files: WORKLOG.md only. Verification: Read current script/theme; no runtime changes or tests needed.
- Blockers: None. Next action: User can adjust popup overrides; dedicated theme resource remains optional.

## White score-number outline

- Goal/status: White outline for pickup point numbers; complete.
- Completed/decisions: Shared ScorePopup font_outline_color is white, affecting note10/baguette30/food1000; retained cream fill and4px outline.
- Files: score_popup.gd, specs/music-note-item-assets.md, AGENTS.md, WORKLOG.md.
- Verification: Reviewed shared style and scope; git diff --check passed. Refactoring review: one shared color override, no duplicate style. No new tests for color-only change; visual playtest not performed.
- Blockers: None. Next action: Optional F5 appearance check.

## Shared pickup point popups

- Goal/status: Show rising numbers for baguette30 and food1000 like note10; complete.
- Decisions: Shared score_popup.gd spawns outside item and retains note styling/timing. ContactPickup.points (baguette30/note10) and FoodCollectible.POINTS1000 drive both popup and score to avoid mismatches. Food contact and gum completion share collect.
- Files: score_popup.gd, music_note.gd, contact_pickup.gd, food_collectible.gd, game.gd, pickup verifiers, music-note/baguette/food specs, AGENTS.md, WORKLOG.md.
- Tests: verify_music_note_pickup PASS (all three values, duplicate guard, rise/fade/lifetime after deletion); verify_food_reel PASS (1000 popup on gum completion); verify_stage_select PASS (points/death persistence). Final refactoring: removed note-only popup/point constant and host-name scoring branches; shared values drive presentation and score. git diff --check passed. Known non-blocking certificate/resource cleanup warnings remain. Blockers: None. Next action: Optional F5 visual playtest.

## Pickup point values

- Goal/status: Baguette30 / food1000 / note10; complete.
- Decisions: Food collected signal credits both contact and completed gum reel once. Existing shared HUD and death persistence apply; no new popup requested.
- Files: game.gd, verify_stage_select.gd, specs/baguette-score-item.md, specs/food-item-assets.md, AGENTS.md, WORKLOG.md.
- Tests: verify_stage_select PASS (exact30/1000/10 deltas, duplicate collection, death score preservation and manual reset); verify_food_reel PASS; git diff --check passed. Refactoring review: reuse _add_score and existing signal registration, named constants for values. Known certificate/resource-cleanup warnings remain. Blockers: None. Next action: Optional F5 pickup playtest.

## Anchor-overlap shot rejection

- Goal/status: Fix failure to attach when firing inside an anchor; complete.
- Findings/decisions: Pre-fix real physics test fails overlap shots with BLOCKED PATH: hit_from_inside returns the same ring for tip hit and root visibility. Root-only ray now excludes the hit anchor cell RID, keeping terrain/props and other rings detectable. Player was already excluded; jump behavior unchanged.
- Files: gum_connection.gd, verify_gum_anchors.gd, specs/gum-anchor-tile.md, AGENTS.md, WORKLOG.md.
- Tests: Pre-fix overlap regression reproduced BLOCKED PATH for center and edge positions, multiple directions. Post-fix anchor and gum suites PASS. Refactoring review: explicit RID parameter; shared cast preserves player exclusion and keeps root exception local to hit anchor. Blockers: None. Final anchor and controls suites PASS; git diff --check passed. Known non-blocking certificate/exit-resource warnings remain. Next action: Optional F5 overlap-shot playtest.

## Investigate jump-shot early return

- Goal/status: Explain gum returning early during jumping; investigation complete.
- Findings: Gum._cast_segment excludes Player RID and ray mask omits player bit2. Game._handle_actions handles fresh jump first: detaches even OUTBOUND, and simultaneous Z/X suppresses shot. Return completion is only handled in RETURNING, never cancels OUTBOUND by player proximity. Moving root can separately trigger BLOCKED PATH / TOO FAR; reported gesture is not captured, so exact incident remains unconfirmed.
- Files: WORKLOG.md, AGENTS.md only; gameplay unchanged.
- Tests: Existing verify_controls covers physical Z cancel during flight and simultaneous Z/X priority; PASS.
- Blockers: None. Next action: Report control cause as supported explanation, distinguish unconfirmed incident; exact incident requires observed input order or release reason.

## Restrict air brake to disconnected gum

- Goal/status: Keep attached swing momentum, enable opposite-input brake after detach; complete.
- Decisions: Query live Gum.connected in Player.simulate; no historical latch. Jump/manual/break releases immediately allow free-flight brake; vertical momentum unchanged.
- Files: player.gd, verify_player.gd, specs/player-controller.md, AGENTS.md, WORKLOG.md.
- Tests: Mirrored real-anchor attached retention and detach-jump brake checks passed; player, controls and gum suites PASS. Refactoring review: one live connected predicate, no extra state or history required. git diff --check passed. Blockers: None. Known non-blocking certificate and exit-resource warnings remain. Next action: Optional swing/detach playtest.

## Music note ten-point pickup

- Goal/status: Display 10 on note pickup and add ten points; complete.
- Decisions: Note owns a stage-hosted rising/fading 0.65s label. Game shares score addition for baguettes/notes; Time Attack gets separate score/timer labels. Existing death persistence applies.
- Files: music_note.gd, game.gd, verify_music_note_pickup.gd, verify_stage_select.gd, music-note/baguette specs, AGENTS.md, WORKLOG.md.
- Tests: Final verify_music_note_pickup and verify_stage_select PASS; git diff --check passed. Verified popup survives item deletion, rises/expires, duplicate collection adds only10, timer remains and death retains score. Refactoring review: shared _add_score, one note POINTS constant, popup owned outside deleted scene tile. Known certificate/resource-cleanup warnings remain. Blockers: None. Next action: Optional F5 visual playtest.

## Air counter-steering brake

- Goal/status: Reset horizontal gum momentum on opposite movement input; complete.
- Decisions: Clear opposing airborne external X before movement, including fresh gum force each held-input tick. Preserve Y, normal input acceleration, grounded friction and reciprocal rigid force.
- Files: player.gd, verify_player.gd, specs/player-controller.md, AGENTS.md, WORKLOG.md.
- Tests: Player, gum and controls suites PASS, including mirrored air brake, held-force cancellation, corner landings and reciprocal forces. Final refactoring review: keep one sign-product condition at the movement input boundary; no new state or force-source bookkeeping. git diff --check passed. Blockers: None. Known non-blocking certificate and gum/controls exit-resource warnings remain. Next action: Optional F5 swing/counter-steering feel test.

## Preserve collected items on checkpoint death

- Goal/status: Prevent collected items respawning on death; complete.
- Decisions: Carry collected placement identities and score through checkpoint scene reload, including Time Attack start fallback. Manual retry starts fresh. Track original placement before food reeling.
- Files: game.gd, verify_stage_select.gd, specs/stage-selection.md, AGENTS.md, WORKLOG.md.
- Tests: Stage selection PASS for all three pickup types, moved food, score, repeated deaths and manual reset. Refactoring: unified recursive pickup registration and renamed setup to match responsibility. Final stage selection, food collectibles and food reel suites PASS; git diff --check passed. Food suite reports exit resource-leak warnings; macOS certificate warning persists. Blockers: None. Next action: Optional interactive death/retry playtest.

## Direct Time Attack debug startup

- Goal/status: Skip mode selection on startup; complete.
- Completed/decisions: Main scene starts Time Attack; mode selection remains accessible from pause menu. Time Attack clear results offer retry only.
- Files: project.godot, game.gd, verify_stage_select.gd, stage-selection/time-attack-courses specs, AGENTS.md, WORKLOG.md.
- Verification: Headless verify_stage_select.gd PASS (direct startup, result retry-only, menu return and existing stage flow); git diff --check passed. Final refactoring review keeps result button construction within its mode branch; no further changes needed. Godot emitted the known non-blocking macOS certificate warning.
- Blockers: None. Next action: F5 for optional interactive playtest.

## MapEdit instant-death spikes

- Goal/status: Place instant-death spikes from MapEdit. Complete.
- Completed/decisions: Added the empty Time Attack Spikes layer to the saved scene and generator. Existing shared hazard tiles are labeled 即死トゲ in the editor.
- Files: MapEdit main.swift/README, Godot stage exchange, Time Attack scene/generator and mapedit verifier, specs/mapedit.md, AGENTS.md, WORKLOG.md.
- Verification: Swift build, both editor placement/Undo/Redo probes, live Time Attack overlap/sweep/death probe and git diff --check passed.
- Blockers: None. Next action: Reopen both apps and copy the stage into MapEdit.

## MapEdit movable blocks

- Goal/status: Add placeable gum-pullable blocks. Complete.
- Completed/decisions: Added the movable block palette kind and empty GumBoxes scene-tile layers in Theater and Time Attack, backed by the existing light rigid body. Stage builders preserve the layers.
- Files: MapEdit Swift sources and README, Godot GumBoxes tileset, both stages and generators, stage exchange/verifier, specs/mapedit.md, AGENTS.md, WORKLOG.md.
- Verification: Both Godot editor probes passed placement, scene packing, and Undo/Redo. A live Time Attack probe attached to a placed block and confirmed reciprocal nonzero force. Swift build and git diff --check passed.
- Blockers: None. Next action: Reopen both apps and reimport the stage to refresh the palette.

## MapEdit live tile settings and shortcuts

- Goal/status: Allow shortcut assignment per placement kind and live settings. Complete.
- Completed/decisions: Replaced the modal dialog with a modeless settings panel, saving valid edits immediately. Added unique single ASCII letter/digit shortcuts, reset, and palette tooltip labels.
- Files: MapEdit Canvas.swift, main.swift and README, specs/mapedit.md, AGENTS.md, WORKLOG.md.
- Verification: Swift build and AppKit probe passed for live name/color changes, persistence, duplicate rejection, synthetic key selection and reset. git diff --check passed. Interactive color picker was not exercised.
- Blockers: None. Next action: Relaunch MapEdit via run.command.

## MapEdit pickup tile spacing

- Goal/status: Visually separate neighboring anchors and items. Complete.
- Completed/decisions: Center anchor and item rectangles at 80% of cell width/height in both views. Placement remains cell-based.
- Files: tools/mapedit/Canvas.swift, specs/mapedit.md, AGENTS.md, WORKLOG.md.
- Verification: Swift build and git diff --check passed. On-screen rendering was not exercised.
- Blockers: None. Next action: Relaunch via run.command.

## MapEdit baguette and note tiles

- Goal/status: Offer baguette and note as independent placement tiles. Complete.
- Completed/decisions: Added Baguettes scene tiles and retained the separate MusicNotes layer. Time Attack starts with empty layers; existing baguettes keep their world positions. Runtime connects score pickups from scene tiles and preserves the Time Attack timer.
- Files: MapEdit Swift sources and README, Godot stage exchange, stages, stage builders, baguette layout/tileset, game.gd, verify_mapedit.gd, specs, AGENTS.md, WORKLOG.md.
- Verification: Both MapEdit editor probes placed both item kinds in the same cell and passed Undo/Redo. Runtime probe confirmed original Theater positions and +100 scoring. Swift build and git diff --check passed.
- Blockers: None. Next action: Relaunch both apps and copy the Godot stage to refresh the palette.

## MapEdit overlapping palette labels

- Goal/status: Fix overlapping items after palette refresh. Complete.
- Completed/decisions: Replace the complete scroll document grid at each refresh and give the scroll view an opaque system background.
- Files: tools/mapedit/main.swift, AGENTS.md, WORKLOG.md.
- Verification: Swift build and AppKit replacement probe passed when switching Time Attack → Theater → Time Attack; old controls detached and only current buttons remained. git diff --check passed. On-screen rendering was not checked.
- Blockers: None. Next action: Relaunch via run.command.

## MapEdit named food placement

- Goal/status: Enable named food item placement in MapEdit. Complete.
- Completed/decisions: Foods uses a named dish picker without numeric IDs in the UI. Godot supplies Japanese labels for all eleven food scene tiles. Time Attack has an empty Foods layer using the same resource as Theater, in the saved scene and generator.
- Files: MapEdit main.swift and README, Godot stage_exchange.gd, time_attack.tscn, build_time_attack_stage.gd and verify_mapedit.gd, specs/mapedit.md, AGENTS.md, WORKLOG.md.
- Verification: Swift build, both editor stage probes with food placement/undo/redo, food gameplay suite, and git diff --check passed.
- Blockers: None. Next action: Reopen both apps and copy the stage from Godot to refresh the palette.

## MapEdit tile display settings

- Goal/status: Allow editing placement colors and display names. Complete.
- Completed/decisions: Added per-kind settings in the right pane with native color well, editable display name, and reset. Styles persist in app-specific preferences and apply across stages.
- Files: tools/mapedit/{Canvas,main}.swift, tools/mapedit/README.md, specs/mapedit.md, AGENTS.md, WORKLOG.md.
- Verification: Swift build, color/name encoding round trip, checkpoint group style lookup, default reset and git diff --check passed. The interactive color panel was not exercised.
- Blockers: None. Next action: Relaunch via run.command and select a kind before opening tile settings.

## MapEdit direct-send UI cleanup

- Goal/status: Remove the clipboard-based Godot paste and MapEdit export controls. Complete.
- Completed/decisions: Godot retains the copy-to-MapEdit menu; MapEdit retains clipboard import and uses direct send for Godot updates. Removed the obsolete export shortcut and handlers.
- Files: tools/mapedit/main.swift and README.md, gd-bungee-gum/addons/mapedit/{plugin,direct_paste}.gd, specs/mapedit.md, AGENTS.md, WORKLOG.md.
- Verification: Swift build, both Godot editor stage probes and git diff --check passed.
- Blockers: None. Next action: Reopen Godot and MapEdit to load the updated menus.

## MapEdit repeated direct paste

- Goal/status: Keep subsequent direct sends accurate after an apply. Complete.
- Completed/decisions: The direct bridge returns the final confirmation result. A full apply advances the client comparison source to the submitted document, independent of ongoing local edits. Undo and strokes retain the latest source. Cancellation and partial application do not advance it.
- Files: Swift MapEdit app/canvas, Godot direct bridge/plugin/verifier, README/spec, AGENTS.md, WORKLOG.md.
- Verification: Swift build, deferred applied/canceled loopback, both-stage repeated-send rollback and conflict tests, git diff --check passed. Live two-window click-through not run.
- Blockers: None. Next action: Restart both apps and repeat successive sends.

## MapEdit stale direct paste merge

- Goal/status: Resolve the reported revision rejection without discarding edits. Complete.
- Completed/decisions: Verified both sides communicated and the saved checkpoint already exists. Carry source placements and use a three-way merge for stale submissions. Restore the source from the original baseline for existing clipboard sessions.
- Files: MapEdit Swift model/app, Godot mapedit exchange/plugin and verifier, README/spec, AGENTS.md, WORKLOG.md.
- Verification: Real session and current saved stage merge produces only the intended anchor move from (38,15) to (39,12), preserving unrelated Godot edits. Swift build, both Godot regression cases and git diff --check passed. Scene and session files were not edited.
- Blockers: None. Next action: Restart both apps and resend the current session for confirmation.

## MapEdit direct paste diagnostics

- Goal/status: Make direct paste failures traceable from both apps. Complete.
- Completed/decisions: Added correlated timestamped sender and listener logs without logging payload JSON. Godot records validation, preview, cancel and scene apply. Documented log locations and common states.
- Files: tools/mapedit/main.swift, tools/mapedit/README.md, gd-bungee-gum/addons/mapedit/{direct_paste,plugin}.gd, AGENTS.md, WORKLOG.md.
- Verification: Swift build, both Godot editor regressions, and loopback request/reply logs passed. The normal port was occupied by an open Godot instance, so the loopback probe used an ephemeral port. git diff --check passed.
- Blockers: Original failure has no captured trace yet. Next action: Relaunch both apps and repeat direct paste, then correlate the logged attempt.

## MapEdit direct paste

- Goal/status: Send a MapEdit payload straight to the open Godot editor. Complete.
- Completed/decisions: Added a Godot send button and an interactive editor localhost bridge. Both entry points share preview, conflict handling, confirmation and Undo. Clipboard remains available. Updated the editor fixture to choose unused checkpoint names.
- Files: tools/mapedit/main.swift, tools/mapedit/README.md, gd-bungee-gum/addons/mapedit/{plugin,direct_paste}.gd, gd-bungee-gum/tools/verify_mapedit.gd, specs/mapedit.md, AGENTS.md, WORKLOG.md.
- Verification: Swift build, Godot TCP request/response loopback, two-stage editor regression suite and git diff --check passed. The live two-window confirmation flow was not manually exercised.
- Blockers: None. Next action: Relaunch both apps, open the target Godot stage, and use Godot に送る.

## MapEdit copy button

- Goal/status: Add a copy button above Fit. Complete.
- Completed/decisions: Added a Godot clipboard button above Fit in the right sidebar using the existing Cmd+C action.
- Files: tools/mapedit/main.swift, tools/mapedit/README.md, WORKLOG.md.
- Verification: Swift build and git diff --check passed. Interactive clipboard button use was not checked.
- Blockers: None. Next action: Relaunch MapEdit via run.command.

## MapEdit stale checkpoint paste

- Goal/status: Recover checkpoint paste from a stale Time Attack clipboard. Complete.
- Completed/decisions: Reproduced the revision mismatch with the supplied payload. Current Godot terrain differs by one cell. The plugin now offers a confirmed additions-only operation for noncolliding MapEdit checkpoint IDs, preserving current scene placements.
- Files: gd-bungee-gum/addons/mapedit/{plugin,stage_exchange}.gd, gd-bungee-gum/tools/verify_mapedit.gd, tools/mapedit/README.md, specs/mapedit.md, AGENTS.md, WORKLOG.md.
- Verification: Exact attachment validates as one checkpoint-only addition at (912, 416); both editor regression cases and git diff --check passed. The stage file was not edited by this task.
- Blockers: None. Next action: Reload the Godot plugin and paste the same payload, then confirm the checkpoint-only addition.

## MapEdit multiple checkpoints

- Goal/status: Place and remove multiple checkpoints from MapEdit. Complete.
- Completed/decisions: One orange checkpoint brush adds one checkpoint per cell and erases with the right button. Origins align with cell bottom-center. Godot validates new marker IDs, instantiates checkpoint.tscn and includes additions/removals in scene history and paste preview.
- Files: tools/mapedit/{MapDocument,Canvas,main}.swift, tools/mapedit/README.md, gd-bungee-gum/addons/mapedit/{plugin,stage_exchange}.gd, gd-bungee-gum/tools/verify_mapedit.gd, specs/mapedit.md, AGENTS.md, WORKLOG.md.
- Verification: Swift build and real Time Attack model brush/duplicate/erase probe passed. Headless editor verification passed on both stages for addition, deletion, packing, and Undo/Redo. git diff --check passed. No stage scene files were written.
- Blockers: None. Next action: Relaunch MapEdit and reload the Godot project before pasting checkpoints.

## MapEdit camera restore

- Goal/status: Restore camera zoom and scroll on relaunch. Complete.
- Completed/decisions: Save optional camera zoom and canvas origin in the atomic session; restore after layout. Missing camera data falls back to fit.
- Files: tools/mapedit/Canvas.swift, tools/mapedit/main.swift, tools/mapedit/README.md, specs/mapedit.md, AGENTS.md, WORKLOG.md.
- Verification: Swift build, camera JSON and viewport round trip, missing camera decoding, and git diff --check passed.
- Blockers: None. Next action: Use run.command and close normally after positioning the camera.

## MapEdit minimap drag

- Goal/status: Enable left-drag camera navigation in the minimap. Complete.
- Completed/decisions: Click and drag share the coordinate conversion and preserve zoom. Only drags started inside the map navigate; they clamp to the map edge and stop on release.
- Files: tools/mapedit/Canvas.swift, tools/mapedit/main.swift, tools/mapedit/README.md, specs/mapedit.md, AGENTS.md, WORKLOG.md.
- Verification: Swift build and git diff --check passed. Interactive dragging was not checked.
- Blockers: None. Next action: Relaunch MapEdit via run.command.

## MapEdit minimap rendering regression

- Goal/status: Restore canvas and sidebar visibility alongside the minimap. Fixed.
- Completed/decisions: The minimap introduced a custom-drawn sibling into a mixed layer-backed hierarchy with no explicit minimap clip. Use one layer-backed content hierarchy and clip both custom draws to their view bounds.
- Files: tools/mapedit/Canvas.swift, tools/mapedit/main.swift, AGENTS.md, WORKLOG.md.
- Verification: Swift build and git diff --check passed. Dark Aqua AppKit offscreen composite showed the canvas, palette and minimap together for Time Attack and Theater. Live WindowServer rendering on the reported desktop remains unverified.
- Blockers: None. Next action: Relaunch MapEdit via run.command.

## MapEdit minimap

- Goal/status: Show a bottom overview with viewport outline and click navigation. Complete.
- Completed/decisions: Aspect-fit tile and marker overview; outlined visible intersection; click centers the canvas at the current zoom. Viewport and placements invalidate the overview.
- Files: tools/mapedit/Canvas.swift, tools/mapedit/main.swift, tools/mapedit/README.md, specs/mapedit.md, AGENTS.md, WORKLOG.md.
- Verification: Swift build and synthetic AppKit clicks near both ends and at center passed for both stage payloads, preserving zoom and data. git diff --check passed. Desktop visuals unverified.
- Blockers: None. Next action: Relaunch MapEdit with run.command.

## MapEdit route marker visibility

- Goal/status: Enlarge and distinguish start, goal and checkpoint markers. Complete.
- Completed/decisions: Route markers use a 14pt screen diameter, with green start, pink exit and orange checkpoints. Sidebar uses the same colors. Marker coordinates and tile rendering stay intact.
- Files: tools/mapedit/Canvas.swift, specs/mapedit.md, AGENTS.md, WORKLOG.md.
- Verification: Swift build and git diff --check passed. Interactive rendering was not checked.
- Blockers: None. Next action: Relaunch MapEdit via run.command.

## MapEdit cell size and swatches

- Goal/status: Use uniform tile sizes and show matching color swatches in the palette. Complete.
- Completed/decisions: Full-cell rendering for every tile kind; active kind takes display priority on overlap. Added a colored square before each palette label using the shared placement colors. Markers retain pixel positions.
- Files: tools/mapedit/Canvas.swift, tools/mapedit/main.swift, specs/mapedit.md, AGENTS.md, WORKLOG.md.
- Verification: Swift build and git diff --check passed. Desktop rendering remains unverified.
- Blockers: None. Next action: Relaunch MapEdit via run.command.

## MapEdit right sidebar

- Goal/status: Move placement controls into a Tiled-style right pane. Complete.
- Completed/decisions: Map is on the left; a fixed-width right pane holds a scrollable two-column category grid, tile variant picker and fit button. Fit on load uses the laid-out canvas bounds.
- Files: tools/mapedit/main.swift, tools/mapedit/README.md, specs/mapedit.md, AGENTS.md, WORKLOG.md.
- Verification: Swift build and both-stage AppKit layout/selection probes passed at 650×350, including restaurant palette overflow and separate canvas/sidebar bounds. git diff --check passed. Desktop appearance remains unverified.
- Blockers: None. Next action: Relaunch MapEdit via run.command.

## MapEdit placement grid

- Goal/status: Replace the placement-kind dropdown with a clickable grid. Complete.
- Completed/decisions: Added a five-column AppKit grid for tile categories and markers with one highlighted selection. Kept the tile variant popup in the row below the grid.
- Files: tools/mapedit/main.swift, tools/mapedit/README.md, specs/mapedit.md, AGENTS.md, WORKLOG.md.
- Verification: Swift build and AppKit probes passed for both real stage documents, including anchor and goal selection, single selected button, and separate canvas bounds. git diff --check passed. Interactive display remains unverified.
- Blockers: None. Next action: Relaunch MapEdit via run.command.

## MapEdit palette visibility

- Goal/status: Restore visible placement type and tile controls in Dark Mode. Implementation complete.
- Completed/decisions: Put explicitly initialized, bordered popup controls and labels on a dedicated AppKit toolbar with a fixed height and minimum control widths. Clip the layer-backed canvas to its own bounds.
- Files: tools/mapedit/main.swift, AGENTS.md, WORKLOG.md.
- Verification: Swift compilation and a Dark Aqua layout probe passed with real Time Attack data, visible control geometry, selected title and disjoint toolbar/canvas frames. git diff --check passed. Interactive rendering on the reported desktop remains unverified.
- Blockers: None. Next action: Relaunch with run.command and check the palette in Dark Mode.

## MapEdit session restore

- Goal/status: Automatically save the working map on quit and restore it on launch. Complete.
- Completed/decisions: Atomic app-local session stores the current map, original baseline and optional manual save URL. Quit is canceled on write failure. Normal load validation also applies to restore.
- Files: tools/mapedit/main.swift, tools/mapedit/README.md, specs/mapedit.md, AGENTS.md, WORKLOG.md.
- Verification: AppKit build passed. Two-process test of the save/restore methods with a real Time Attack payload and temporary storage passed, including unsaved marker edits and dirty state. git diff --check passed.
- Blockers: None. Next action: Close and reopen MapEdit during normal use.

## MapEdit Finder launcher

- Goal/status: Add a double-click launcher for MapEdit. Complete.
- Completed/decisions: Executable run.command resolves its own directory and delegates to run.sh. Updated the README and durable launch instructions.
- Files: tools/mapedit/run.command, tools/mapedit/README.md, AGENTS.md, WORKLOG.md.
- Verification: Shell syntax, executable bit, git diff --check and direct launch from /tmp passed. Finder interaction was not exercised.
- Blockers: None. Next action: Double-click run.command in Finder when using MapEdit.

## MapEdit

- Goal/status: Implement the macOS single-canvas placement editor and Godot round trip. Complete.
- Completed/decisions: Added Swift/AppKit editor, clipboard and atomic JSON files, typed palettes, brush/erase and marker movement, pan/zoom and Undo/Redo. Godot plugin validates stage and clipboard revision, previews differences and commits placements, merged static collision and theater rims together. Time Attack and Theater supported. Canvas uses semantic colors and tile IDs. Existing marker instances are movable.
- Files: tools/mapedit, gd-bungee-gum/addons/mapedit, gd-bungee-gum/tools/verify_mapedit.gd, project.godot, specs/mapedit.md, AGENTS.md, WORKLOG.md.
- Verification: AppKit build and launch smoke passed. Swift model decoded and re-encoded both real stage payloads, rejected duplicates, and UndoManager undo/redo passed. Godot editor tests passed for both stages (no-op, invalid data, changes, collision coverage, stale paste, Undo/Redo). Saved Theater map test and git diff --check passed. Sandbox Godot CA/editor-settings and AppKit service warnings were observed.
- Blockers: None. Next action: Manual desktop clipboard and pointer/trackpad playtest; launch and workflow are documented in tools/mapedit/README.md.

## Tilemap editor design guidance

- Goal/status: Record tilemap editor research as repository guidance. Complete.
- Completed/decisions: Documented separate tileset/map storage, per-layer palette references, stable IDs, editing tools, minimap navigation, cursor-anchored zoom and verification. Semantic layers and automatic painting are extensions to manual painting.
- Files changed: `.agents/タイルマップエディタ作成.md`, `WORKLOG.md`. AGENTS.md already references the guide.
- Verification: Reviewed guide sections, local references and whitespace.
- Blockers: None. Next action: Use the guide when implementing the editor.

## Tilemap editor guidance

- Goal/status: Create concise instructions for building a tilemap editor. Complete.
- Completed/decisions: Added a guide covering rectangular grids, tile selection and painting, undo grouping, storage validation, and save/load checks. It inherits the general tool guide and prioritizes existing formats.
- Files changed: `.agents/タイルマップエディタ作成.md`, `AGENTS.md`, `WORKLOG.md`.
- Verification: Checked both guide references and whitespace.
- Blockers: None. Next action: Use both guides when implementing a tilemap editor.

## Tool creation guidance

- Goal/status: Review the guide for general-purpose tools and correct scope gaps. Complete.
- Completed/decisions: Split common practices from CLI/batch, interactive editor, and grid guidance. Scoped framework and format defaults, clarified write failures and undo/save behavior, and added checks for batch failures and reruns.
- Files changed: `.agents/ツール作成.md`, `WORKLOG.md`. Existing reference in `AGENTS.md` remains valid.
- Verification: Reviewed against read-only CLI, batch writer, file editor and grid editor use cases. Whitespace checks passed.
- Blockers: None. Next action: Apply the relevant sections during the next tool task.

## Time Attack width expansion

- Goal/status: Triple the saved Time Attack stage width. Complete.
- Completed/decisions: Expanded 64→192 columns with a straight floor and ceiling extension, moved the east wall and exit 4096px east, and updated background/camera width to 6144px. Preserved authored footholds, anchors and checkpoint. The expanded course has a separate local best file.
- Files: time_attack.tscn, game_time_attack.tscn, game.gd, Time Attack spec, AGENTS, WORKLOG.
- Verification: Reviewed old/new geometry and camera values. Godot headless verified exact rectangle coverage and live physics across all 4608 cells plus the camera limit and exit floor. git diff --check passed. Known CA warning.
- Blockers: None. Next action: F5 to playtest or edit the extension.

## Time Attack collision sync for revised platforms

- Goal/status: Align collision with the manually revised saved tiles. Complete.
- Completed/decisions: Replaced only the Terrain shape resources and nodes in time_attack.tscn. The 441 occupied terrain cells are covered by 13 nonoverlapping rectangles. Tile layers were preserved byte for byte.
- Verification: Godot loaded the Time Attack game and verified exact rectangle coverage and live physics at all 1536 cell centers, including empty cells. git diff --check passed. Known sandbox CA warning.
- Blockers: None. Next action: F5 to playtest the revised layout.

## Time Attack lower fall-death threshold

- Goal/status: Move Time Attack fall death slightly lower. Complete.
- Completed/decisions: Added a per-scene offset and set Time Attack to +64px (two tiles), taking the default threshold from Y=900 to Y=964.
- Files: game.gd, game_time_attack.tscn, Time Attack spec, AGENTS, WORKLOG.
- Verification: Reviewed the default zero offset. Headless actual scene survived just past Y=900 and respawned at the checkpoint past Y=964 with elapsed time preserved. git diff --check passed. Known CA and teardown warnings.
- Blockers: None. Next action: F5 for fall-depth playtest.

## Time Attack checkpoint recovery

- Goal/status: Enable checkpoint recovery while preserving elapsed Time Attack time. Complete.
- Completed/decisions: Moved the already placed checkpoint under Checkpoints, preserving its position. Shared Game setup restores the checkpoint and elapsed time on scene-scoped automatic reloads. Death before activation preserves time at the entrance. Manual restart clears both.
- Files: game.gd, stages/time_attack.tscn, specs/time-attack-courses.md, AGENTS, WORKLOG.
- Verification: Reviewed scene-scoped metadata and normal restart paths. Live Godot test passed for contact, fall death, respawn position, elapsed time continuity and manual reset. Standard stage selection suite and git diff --check passed; known sandbox CA warning.
- Blockers: None. Next action: F5 for manual route playtest.

## Time Attack countdown disabled

- Goal/status: Disable the Time Attack countdown. Complete.
- Completed/decisions: Removed countdown-only state and gameplay gate. The HUD begins at TIME 0.00, and Game starts movement and timing on the first gameplay tick after the existing entrance.
- Files: game.gd, specs/time-attack-courses.md, AGENTS.md, WORKLOG.md.
- Verification: Reviewed the shared entrance/restart flow. Headless live scene probe passed for zero time during entrance, immediate movement/timer/gum availability, and reset on restart. git diff --check passed. Known sandbox CA warning.
- Blockers: None. Next action: F5 to playtest the start.

## Time Attack collision sync after manual tile edits

- Goal/status: Match collisions to the saved tile placement. Complete.
- Completed/decisions: Used TerrainTiles as the source of truth and replaced only Terrain rectangle resources and nodes. The 493 occupied cells are covered by 12 nonoverlapping grid-aligned rectangles.
- Files: scenes/stages/time_attack.tscn, specs/time-attack-courses.md, AGENTS.md, WORKLOG.md.
- Verification: Both serialized tile layers preserved byte for byte. Godot headless loaded actual Game and verified exact cell coverage, live raised step and ceiling hits, and an erased floor gap without collision. git diff --check passed.
- Blockers: None. Next action: Playtest the edited route in F5.

## Time Attack TileMap terrain presentation

- Goal/status: Preserve tile editing while aligning the terrain silhouette. Complete.
- Completed/decisions: TerrainTiles shader fills alpha gaps within each painted cell. Removed independent terrain backing polygons and rims. Merged static rectangle colliders still provide gum wrapping geometry.
- Files: Time Attack generator and saved stage, time_attack_terrain.gdshader, spec, AGENTS, WORKLOG.
- Verification: Godot headless generation and saved stage check passed for painted/empty cells, node types and wall/top rays at x384/y608. git diff --check passed. Shader appearance awaits visual playtest.
- Blockers: None. Next action: F5 to check the tile edges in the rendered game.

## Time Attack prototype implementation

- Goal/status: Create the single Restaurant Sprint stage and make it playable. Complete.
- Completed/decisions: 64×24 map with service entrance, atrium, terrace, six rings and recovery floor. Direct entry from mode select, three-second countdown after entrance, active physics timer, best time file, restart and return to modes. Existing Game owns the clock and goal timing.
- Files: game.gd, mode_select.gd, game_time_attack.tscn, stages/time_attack.tscn, build_time_attack_stage.gd, verify_stage_select.gd, specs, AGENTS and WORKLOG.
- Verification: Headless generator and standard 3-stage selection suite passed. Automated live route passed in 20.33s using direct gum aim and actual player/rigid physics. Goal freeze and retry record persistence passed with the record file redirected to a writable temporary fixture. Sandbox default user directory was not writable; known CA and teardown resource warnings persist. git diff --check passed.
- Refactoring: Centralized Time Attack timer advancement and kept standard prop/checkpoint setup separate. Reviewed result/pause/restart destinations and reran both suites.
- Blockers: None. Next action: F5 → Time Attack for visual and eight-way manual playtesting and tuning of the airborne line.

## Time Attack single-stage proposal

- Goal/status: Consolidate Time Attack into one dedicated stage. Proposal complete.
- Completed/decisions: One route from the service entrance through the atrium to the terrace, with stable and faster lines, a direct mode entry, and one whole-stage personal best. The 30–45s target is provisional.
- Files: specs/time-attack-courses.md, AGENTS.md and WORKLOG.md.
- Verification: Reviewed navigation, layout constraints and timing for consistency. git diff --check passed. Layout and timing await playtesting.
- Blockers: None. Next action: Block out the atrium and test landing and airborne lines at the saved 160px firing range.

## Mode selection before stage selection

- Goal/status: Add startup mode selection. Complete.
- Completed/decisions: F5 opens Stage and Time Attack cards. Stage leads to the existing stage catalog, and Time Attack displays 準備中 until gameplay is implemented. Stage selection has a back button and ui_cancel.
- Files: project.godot, mode_select scene/script, stage_select.gd, verify_stage_select.gd, specs, AGENTS and WORKLOG.
- Verification: Godot 4.5.1 headless startup and expanded stage selection suite PASS, including round-trip navigation and all three stages. git diff --check PASS. Existing sandbox CA warning.
- Refactoring: Reviewed card construction, navigation guards and existing gameplay return paths.
- Blockers: None. Next action: F5 for visual review. Time Attack rules and timer are future work.

## Baguette score pickup integration

- Goal/status: Add baguette pickups alongside music notes. Complete.
- Completed: Three placements per saved stage and matching generator layouts, shared contact pickup lifecycle, 100-point Game score and HUD, runtime sprite copy and spec. Scene reload resets score and pickups.
- Files: game/stage/item scenes, game/music_note/contact_pickup/baguette_layout scripts, both stage generators, runtime baguette asset, baguette-score-item spec, AGENTS and WORKLOG.
- Verification: Godot import and live contact probe passed in all three games; nine pickup sensors clear terrain/platforms/spikes. Existing music-note appearance, pickup and 117-placement checks plus stage exit passed. Known sandbox CA and pickup-suite exit warnings persist.
- Refactoring: Shared one-shot pickup handling between both items and kept scoring in Game. Reviewed generator alignment and final diff.
- Blockers: None. Next action: F5 for interactive HUD and route playtest.

## Small baguette score-item sprite

- Goal/status: Create a small French baguette sprite for Teto; image complete.
- Completed/decisions: Built-in imagegen produced a golden diagonal baguette with three cuts. Cropped alpha and resized with nearest-neighbor to a centered 32 × 32 RGBA canvas with transparent margins. Scope is artwork.
- Files: images/foods/baguette.png, AGENTS.md, WORKLOG.md.
- Verification: Pillow checked transparency; inspected the nearest-neighbor enlarged preview for shape, scoring cuts and margins. git diff --check passed.
- Blockers: None. Next action: Use the sprite if a baguette pickup is added to the game.

## Music note vertical-axis turn
- Goal/status: Add slow readable vertical-axis rotation without thin/collapsed sprite; complete.
- Completed:4s ±32degree yaw, compensated face width>=94%, max~2px extruded sides, subtle perspective/shading; retained3s cream highlight and fixed18px pickup sensor. All117scene tiles inherit new appearance.
- Decisions: Shallow back-and-forth yaw preserves note readability; no edge-on/full360 spin, node scaling or asset changes. Both clocks pause and use positional phases.
- Files: scripts/music_note.gd; shaders/music_note.gdshader (replaces highlight-only name, preserved UID); scenes/items/music_note.tscn; verify_music_note.gd; music-note spec/AGENTS/WORKLOG.
- Verification: Actual OpenGL32-frame4s capture visually reviewed;4× front silhouette68×84px, oblique72×84–85px (no collapse/clipping). Final headless animation/117-placement/3stage-physical-pickup suites PASS; git diff --check PASS. Known sandbox CA and pickup exit ObjectDB/resource warnings remain.
- Refactoring: Unified appearance update, clear highlight/turn clock names and appearance material/shader name; removed old helper/name references. Shader helper returns UVs so built-in TEXTURE remains in fragment for Godot4.5 compiler compatibility. Final focused reruns PASS.
- Blockers: None. Next action: F5 gameplay or F6 music_note_preview.tscn to review subtle turn at native size.

## Music note contact pickup
- Goal/status: Let player collect placed notes; complete.
- Completed: Area2D18px sensor with player-bit/group filtering; immediate hide/item sound/one-shot collected() then deletion. Child Sprite retains independent highlight material/phases. All117 saved notes inherit pickup behavior, reload restores availability.
- Decisions: No gum target/reeling, scoring, ability reward or extra particles. Pause inherited from scene tree. Runtime SoundEffects lookup avoids early preload/autoload identifier compile errors.
- Files: scripts/music_note.gd; scenes/items/music_note.tscn; verify_music_note.gd/verify_music_note_placement.gd; new verify_music_note_pickup.gd; music-note spec/AGENTS/WORKLOG.
- Verification: Final actual-contact suite PASS across3saved stages (player, prop/nonplayer exclusion, gum rays, paused contacts/resume, reload, duplicate requests); animation and117-placement suites PASS; git diff --check PASS. Known sandbox CA and pickup-suite exit ObjectDB/resource warnings remain.
- Refactoring: Reviewed animation/pickup ownership and all scene callers; single Area2D owns lifecycle, child owns appearance, one guarded collection path; updated stale display-only documentation and strengthened placement script-loading assertion. Final focused reruns PASS.
- Blockers: None. Next action: F5 touch notes to playtest contact radius/sound; score remains unimplemented.

## Music note route placement
- Goal/status: Place animated notes to guide traversal across3 playable stages; complete.
- Completed: Editable MusicNotes scene TileSet/layers: restaurant70/terrace25/kitchen22 (117total). Authored route arrays/shared helper; original generator integration. Existing scene content preserved without rebuilding terrain.
- Decisions: Sparse ground trails, upward lift cues,48px food clearance; display-only (no collection/scoring). No physics/tuning changes.
- Files: scripts/music_note_layout.gd; assets/items/music_note_tileset.tres;3saved stage scenes; build_theater_stage.gd; verify_music_note_placement.gd; music-note spec; AGENTS/WORKLOG.
- Verification: Placement suite PASS with real117scene instances and24×28 terrain/platform/hazard clearance; animation/map/food suites PASS; geometry overview visually reviewed. Food suite retains exit leak/resource warnings, engine sandbox CA warning remains. verify_stage_route fails at first upward lift with current160px range; identical failure reproduced after removing notes (temporary /tmp fixture), independent of this change. Full-route reachability is not verified.
- Refactoring: Shared creation helper and top-level generator preload, no duplicated runtime spawn path; reviewed saved diffs to confirm only note resource/layer additions. Final placement rerun and git diff --check PASS.
- Blockers: None for placement. Next action: F5 playtest note guidance/density; pickup/scoring remains separate work.

## Music note highlight animation
- Goal/status: Implement subtle local highlight loop; complete.
- Completed: Runtime32px asset/reusable Sprite2D, cream-only shader,3s loop (2.4s quiet/0.6s sine-squared shine), independent positional phases and pause support;3-note F6 preview.
- Decisions: Fixed silhouette/position/alpha; no outer glow/particles. Animation scene only; no collection/scoring/TileSet or map edits.
- Files: assets/items/music_note.png; scenes/items/music_note.tscn; scenes/music_note_preview.tscn; scripts/music_note.gd; shaders/music_note_highlight.gdshader; tools/verify_music_note.gd; spec/AGENTS/WORKLOG.
- Verification: Import complete with known sandbox CA/Mono/editor-settings warnings. Headless verify_music_note PASS (scene/size/materials/phases/quiet/peak/loop/transforms/pause). Graphical render attempt exited134 in sandbox, so actual rendered brightness remains manual review. Texture highlight mask inspected. Final refactoring review kept one clock and per-instance material, corrected CanvasItem tint to avoid double texture multiplication; final focused rerun and git diff --check PASS. Highlight affects6 of181 visible source pixels.
- Blockers: No implementation blocker; graphical visual verification unavailable. Next action: F6 preview to review brightness.

## Music note idle animation proposal
- Goal/status: Propose subtle shine/rotation for note collectible; complete as design proposal.
- Completed: Reviewed tile specification; proposed3s highlight loop (2.4s hold/0.6s local shine), staggered phases;4s shallow vertical-axis turn as alternative.
- Decisions: Prefer local highlight only; preserve silhouette/location, no additional effects. Proposal not yet implemented or approved.
- Files: specs/music-note-item-assets.md; WORKLOG.md.
- Verification: Documentation reviewed against32px sprite and restrained presentation request; git diff --check PASS. No runtime changes/tests.
- Blockers: None. Next action: Create animation artwork or runtime effect when requested.

## Music note collectible artwork
- Goal/status: Generate transparent coral music-note tile; complete.
- Completed: Built-in imagegen source,32px nearest export; inspected full image and8× tile preview. Preserved generated alpha.
- Decisions: Single static low-score pickup candidate; art only, no runtime collection/scoring changes.
- Files: images/items/music_note{,_source}.png; specs/music-note-item-assets.md (full final prompt); AGENTS.md; WORKLOG.md.
- Verification: Source1254×1254 RGBA/alpha0–255/all corners transparent;32×32 tile silhouette visually PASS. No gameplay tests needed. Asset/document review complete.
- Blockers: None. Next action: Integrate tile placement and collection when requested.

## Strong lateral gum hair pose integration
- Goal/status: Select added hair-lag sheet under strong lateral gum force; implementation and focused checks complete.
- Completed: Reproducible shared-cell normalization/source-runtime parity;8-frame10fps gum_hair_pull, mirrored hand samples and existing continuous hand follow; actual horizontal force threshold700/hold525, upward/sideways dominant force and airborne ATTACHED gate. Existing assets preserved.
- Decisions: Shared Inspector Gum Pull Pose threshold; grounded/vertical/downward/outbound retain existing poses. Physics shape/forces unchanged. Temporal loop is initial playtest behavior.
- Files: build_gum_hair_art.py; normalized/runtime PNGs; gum_animations.tres; player.gd/game_settings.gd; verify_hair_pull.gd; character-gum-animations/game-settings specs; AGENTS/WORKLOG.
- Verification: Normalized sheet visually reviewed; hair/hanging(17304cases)/hand suites PASS. Player full regression and gum physics/live Game suite PASS; final focused rerun, asset parity/dimensions and git diff --check PASS. Import completed with known sandbox CA/Mono/editor settings warnings.
- Refactoring: Dedicated state helper, shared settings and existing hand/animation lifecycle; no duplicate physics or rendering system.
- Blockers: None. Next action: F5 playtest threshold/loop feel; implementation verified headlessly, live visual feel remains user review.

## Large hair follow-through hanging variants
- Goal/status: Add gentle body bend with large delayed drill-hair movement; complete as source artwork.
- Completed: Built-in imagegen produced additional transparent4×2 temporal sheet; visually confirmed eight full bodies, shallow torso curve and pronounced hair sweep/return. Existing artwork/runtime preserved.
- Decisions: Source patterns only; common-cell normalization, hand alignment and loop polish precede runtime integration. Low-alpha generation fringe retained.
- Files: images/gum-source/teto_gum_hair_followthrough.png; specs/character-gum-animations.md (prompt and checks); AGENTS.md; WORKLOG.md.
- Verification: Pillow1774×887 RGBA, alpha0–255, corners0/0/1/0; all8 cells occupied. Visual silhouette/hair review PASS. Documentation/asset scope reviewed; no gameplay changes or runtime tests. git diff --check PASS.
- Blockers: None. Next action: Review added source patterns; normalize/integrate if requested.

## Horizontal hanging pose review
- Goal/status: Evaluate natural body pose during strong lateral gum pull; review complete, proposal only.
- Completed: Inspected runtime hang-angle/pull sheets and player pose selection; documented gentle shoulder-to-hip arc, trailing relaxed legs and brief stronger onset response rather than sustained sharp waist fold.
- Decisions: Arm direction follows support; body response should distinguish lateral tension/acceleration from travel speed. Existing implementation remains unchanged; proposal in character-gum-animations.md.
- Files: specs/character-gum-animations.md; WORKLOG.md.
- Verification: Visually reviewed both normalized sheets; checked _select_gum_pose and tension gate. Documentation-only review; no runtime tests required. Reviewed proposal against existing physics/collision constraints.
- Blockers: None. Next action: If adopted, create lateral traction pose candidates and review their silhouettes before integration.

## Exit landing before approach
- Goal/status: Airborne exit contact lands before horizontal auto-run; complete.
- Completed: Separate gravity landing phase retains vertical entry speed, uses air pose/no horizontal motion, and waits for real walkable floor collision. Grounded contact confirms floor immediately; run then moves horizontally at landed height to center before rear art/timeline.
- Files: stage_exit.gd/game.gd; verify_stage_exit.gd; exit/rear specs; AGENTS/WORKLOG.
- Decisions: Immediate control/gum lock; vertical momentum captured before reset_motion, private fall accumulator follows shared gravity. No diagonal air approach/teleport; pause/retry remain supported.
- Verification: Focused exit PASS across3stages, grounded start, airborne/upward arc, no prelanding horizontal movement/input/timeline, real floor, rear pose and result; stage-selection/pause PASS. Known sandbox CA warning only.
- Refactoring: Landing and approach are exclusive phases with separate helpers; removed obsolete diagonal motion, retained existing timeline. Live verification waits boundedly for actual landing/approach completion rather than fixed frame count. Final focused rerun and git diff --check PASS.
- Blockers: None. Next action: F5 contact exit while airborne to review landing then run.

## Exit approach and rear pose integration
- Goal/status: Lock controls, run to exit center, switch to rear art then exit sequence; complete.
- Completed: Shared entrance/rear normalization builder; rear256px cell/runtime copy; collision-sliding approach120px/s in run; <=0.5px center switches static exit_back; existing open/fade/hide/close/result; Game caller/docs/assertions aligned.
- Decisions: Opening begins after center arrival. No teleport, input/physics simulation remains locked throughout; OPTIONS pause/R/selection retained. Actor transform reset before run removes prior jump deformation.
- Files: stage_exit.gd/game.gd; verify_stage_exit.gd; tools/build_character_door_art.py (replaces front-only builder); rear normalized/runtime PNG/import; exit/front/entrance specs; AGENTS/WORKLOG.
- Verification: Rear normalized art visually inspected and source/runtime parity; focused exit PASS across3stages with real trigger, progressive movement/opposing input, rear texture, fade/lock/result; live left/airborne approach and paused movement PASS. Stage-selection, entrance and pause suites PASS. Import has known sandbox CA/Mono/editor settings warnings.
- Refactoring: Extracted approach helper, collision remainder sliding for floor contact; unified front/rear normalization to remove duplication and updated current references. Final exit rerun, asset parity/baseline and git diff --check PASS.
- Blockers: None. Next action: F5 playtest exit approach and rear-facing disappearance.

## Rear-facing exit character art
- Goal/status: Generate rear-facing Teto looking into screen for exit use; complete as source artwork.
- Completed: Built-in imagegen using approved front source and idle style; reviewed back-facing head/jacket/boots, full silhouette, palette/proportions; saved images/teto_back_exit_source.png.
- Decisions: Single neutral rear view with transparent exterior; no runtime changes. Normalize cell/baseline and generated low-alpha fringe when integrated.
- Files: New source PNG; specs/character-back-exit.md; AGENTS.md; WORKLOG.md.
- Final prompt: Full-body strictly rear-facing Teto looking away, neutral lowered arms/level feet, preserve red curls/white ornament/gray-red costume and chibi pixel style; rear jacket/boots, no face, transparent exterior, no scenery/text/duplicates.
- Verification: Visual review PASS;1024×1536 RGBA and exterior/inter-leg alpha checked. Artwork task requires no gameplay tests or implementation refactor; documentation reviewed for current scope.
- Blockers: None. Next action: Normalize and integrate with exit timeline if requested.

## Entrance front-pose integration
- Goal/status: Use approved front artwork until entrance controls unlock; complete.
- Completed: Reproducible256px normalization (196px height,feet232,alpha threshold128 and transparent RGB cleanup), runtime copy; static entrance_front throughout fade/closing, idle restoration; docs and focused assertions.
- Decisions: Reuse actor AnimatedSprite2D and private SpriteFrames for existing fade/visibility/pause ownership; no physics changes, checkpoint skip retained.
- Files: tools/build_front_entrance_art.py; normalized/runtime PNGs/import; stage_entrance.gd; verify_stage_entrance.gd; entrance/front specs; AGENTS/WORKLOG.
- Verification: Normalized sprite visually inspected; entrance suite PASS across3stages including correct texture/static pose/fade/locks/restoration/checkpoint; pause suite PASS. Import completed with known sandbox CA/Mono/editor-settings warnings.
- Refactoring: Reviewed entire entrance lifecycle; one animation uses existing actor transforms/color, no extra sprite or duplicate timeline. Builder clears transparent RGB for clean previews. Final entrance rerun and git diff --check PASS.
- Blockers: None. Next action: F5 select any stage to review front-facing emergence.

## Front-facing entrance character art
- Goal/status: Generate a transparent full-body front-facing Teto entrance sprite; complete as source artwork.
- Completed: Reviewed original front/normalized idle references, generated neutral lowered-arm pose using built-in imagegen and requested background extraction; saved images/teto_front_entrance_source.png.
- Decisions: One neutral front pose matching existing pixel art; no gameplay integration. Preserve generated alpha; normalize runtime cell/baseline when integrated.
- Files: New source PNG; specs/character-front-entrance.md; AGENTS.md (corrected stale original reference path); WORKLOG.md.
- Final prompt: Single full-body strictly front-facing Teto, neutral lowered arms, square shoulders/hips, forward eyes/boots, preserve red drill curls/gray-red costume/black boots and chibi pixel style, transparent exterior, no scenery/text. Follow-up extraction preserves character and removes exterior haze/shadows.
- Verification: Visually reviewed pose/identity/full silhouette; confirmed1024×1536 RGBA and alpha0 exterior samples including between legs. Documentation review complete; source-art task requires no gameplay tests/refactoring.
- Blockers: None. Next action: Normalize and integrate with entrance timeline if requested.

## Exit sequence integration
- Goal/status: Contact-triggered opening → darken/hide player → closing → clear; complete.
- Completed: Normalized six EXIT frames/shared header, runtime/source parity and reproducible builder. Dedicated player-only Area + fixed-step timeline; Game lock and deferred result, fade RGB preserving alpha, hide body/art + masks0. All3stages floor-aligned, old label/generator output removed. Updated specs/tests/AGENTS.
- Decisions:0.4s open→0.5s darken→hide→0.4s close; no player teleport. Gum detached/hidden, motion reset. Pause/retry/menu retained. Result after closing only.
- Files: stage_exit.gd/game.gd; source/runtime PNGs; build_stage_exit_art.py; saved stage/generator label removal; verify_stage_exit/stage_select; specs/stage-exit-art.md/stage-selection.md; AGENTS/WORKLOG.
- Refactoring: Shared floor-alignment helper across entrance/exit, independent presentation timeline, no async callbacks/duplicated proximity clear.
- Verification: Final exit suite PASS across3stages for actual contact, all phases, physics/input lock, actor collision removal, one-time result and live pause/resume; stage-select/entrance/pause/map suites PASS. OpenGL opening/fade/closing/result screenshots reviewed; fixed result panel clipping via CenterContainer. Asset dimensions/parity and diff check PASS. Known sandbox CA/editor/exit-resource warnings remain.
- Blockers: None. Next action: F5 playtest any stage, touch the EXIT doorway to view sequence.

## Exit opening animation artwork
- Goal/status: Create six opening patterns for EXIT doorway; complete as source artwork, not integrated.
- Completed: Built-in imagegen produced3×2 closed→fully open states matching approved EXIT source. Reviewed all six EXIT signs, symmetric progressive door opening, palette and transparent exterior. Saved images/tilesets/restaurant_stage_exit_animation_source.png.
- Final prompt: Exact EXIT reference as six aligned3×2 frames, symmetric hinged leaves0/15/35/55/75/90degrees into dark teal interior; stationary cream/mint/coral architecture/EXIT lettering, transparent exterior, no character/arrows/grid.
- Files: New PNG; specs/stage-exit-art.md; AGENTS.md; WORKLOG.md.
- Verification: Visual/text review PASS; PNG dimensions/RGBA/alpha checked. Generated source still requires cell normalization before runtime. No gameplay changes/tests or implementation refactor needed.
- Blockers: None. Next action: Normalize and integrate opening sequence at Exit markers if requested.

## Exit tile artwork
- Goal/status: Generate a restaurant exit tile image; complete as source art, not integrated.
- Completed: Built-in imagegen generated one closed EXIT doorway matching entrance; reviewed exact EXIT lettering, no arrow, cream/mint/coral/teal palette and transparent exterior. Saved images/tilesets/restaurant_stage_exit_source.png.
- Final prompt: Single closed restaurant exit doorway matching entrance reference, cream ceramic/mint frame/coral striped canopy/teal glass/gold handles, bold brown EXIT sign, orthographic chunky pixel art, transparent exterior, no arrows/characters/scenery; readable at logical96×128.
- Files: New PNG; AGENTS.md; WORKLOG.md.
- Verification: Visual review PASS; PNG dimensions/RGBA/alpha checked. Source art only; no gameplay tests or implementation refactor needed.
- Blockers: None. Next action: Normalize and integrate at Exit markers if requested.

## OPTIONS pause menu
- Goal/status: OPTIONS opens retry/stage-selection/cancel menu; complete.
- Completed: Dedicated ALWAYS CanvasLayer/menu, entire SceneTree pause, focus navigation, same-button/Esc cancel, HUD menu, retry/selection unpause. Dedicated OPTIONS action replaces restart binding; R remains direct. Added explicit any-device UI Cross accept while preserving Enter/KpEnter/Space (built-in ui_accept lacked joypad). Updated affected specs/tests/AGENTS.
- Decisions: Cancel retains position/momentum/gum/entrance progress; Game consumes closing tick so Cross cannot trigger jump. Works during entrance/death/clear. Menu _exit_tree releases owned pause.
- Files: scripts/pause_menu.gd, game.gd; project.godot; game.tscn; verify_pause_menu/controls/stage_select; pause-menu/control/stage/checkpoint/architecture specs; AGENTS/WORKLOG.
- Refactoring: Menu owns pause/focus/UI, Game owns scene changes and resume-input suppression; removed superseded direct Esc/HUD return path. Reviewed pause lifecycle and scene teardown.
- Verification: Final focused menu PASS with actual OPTIONS/D-pad/Cross, pause/rigid/entrance freeze, retained momentum, resume-input suppression, retry and selection. Stage-selection/entrance suites PASS; controls PASS. OpenGL screenshot reviewed; git diff --check PASS. Known sandbox CA/exit-resource warnings only.
- Blockers: None. Next action: F5, choose a stage and press OPTIONS to use the menu; physical hardware QA remains separate.

## Stage entrance sequence integration
- Goal/status: Integrate door opening, black-to-normal character emergence simultaneous with closing, locked controls; complete.
- Completed: Shared Game lock and dedicated stage_entrance.gd timeline; six96×128 nearest cells/shared header and reproducible slicer; floor alignment; checkpoint skip; removed duplicate stage label/generator output. Source/runtime PNG parity. Updated runtime docs/AGENTS and fixtures to complete entrance before unrelated gameplay assertions.
- Decisions:0.20s closed,0.40s opening,0.50s simultaneous emergence/closing; self_modulate RGB black→original, alpha retained. No player simulation/gum input during sequence; R/menu remain usable. Same-Z placement after stage/before player fixes decor overlap.
- Files: stage_entrance.gd, game.gd; assets/stage PNG, source normalized PNG; tools/build_stage_entrance_art.py; stage label/generator; affected verification fixtures; stage-entrance/player/controls/stage-selection specs; AGENTS/WORKLOG.
- Refactoring: Reviewed timeline lifecycle (no asynchronous callbacks), render ordering, reset ownership and input gates. Reproducible crop/header builder replaces ad hoc processing.
- Verification: Final focused entrance suite PASS across3stages/lock/held-input-no-queue/color/closing/floor/resume/checkpoint; stage-select/controls/map/gum/player/food-reel/ladder PASS after final refactor; asset parity/dimensions and git diff --check PASS. OpenGL screenshot reviewed; corrected background overlap and duplicate label then reviewed again. Known sandbox CA/editor/exit-resource warnings only.
- Blockers: None. Next action: F5 select any stage to review/play the entrance sequence.

## ENTRANCE sign edit
- Goal/status: Replace arrows on six entrance animation frames with ENTRANCE; complete.
- Completed: Built-in imagegen changed all six signs to correctly spelled dark-brown ENTRANCE; visually reviewed door states, palette and exterior transparency. Saved images/tilesets/restaurant_stage_entrance_animation_entrance.png; original retained.
- Final prompt: Change only six sign interiors, remove arrows, exact uppercase ENTRANCE in centered bold brown pixel lettering; preserve3×2 layout, door states, architecture, palette and transparent exterior.
- Files: New PNG; specs/stage-entrance-art.md; AGENTS.md; WORKLOG.md.
- Verification: Six text labels visually checked; RGBA/alpha/dimensions checked. Source remains unnormalized with fringe/alignment differences; no runtime changes/tests needed. Reviewed documentation references for consistency.
- Blockers: None. Next action: Normalize artwork before runtime integration when requested.

## Entrance door animation artwork
- Goal/status: Create entrance opening/closing patterns; complete as generated source artwork, not integrated.
- Completed: Built-in imagegen edited the entrance into six opening states,3columns×2rows; reviewed closed→progressively open→fully open, retained cream/mint/coral architecture, arrow and transparent exterior. Saved images/tilesets/restaurant_stage_entrance_animation_source.png.
- Decisions: Read left-to-right/top-to-bottom; reverse closes. Hold full-open for separate character emergence. No character baked in. Generated sheet has small architecture/alignment differences and requires normalization before runtime use.
- Final prompt: Reference doorway, six equal3×2 frames, identical stationary architecture, symmetrical hinged double doors at0/15/35/55/75/90degrees into dark teal interior, transparent exterior, no character/text/grid; reverse playback closes.
- Files: New source PNG; specs/stage-entrance-art.md; AGENTS.md; WORKLOG.md.
- Verification: Visual sequence/palette/transparent exterior reviewed; RGBA/alpha/dimensions checked. Art only, no gameplay tests or code refactor needed.
- Blockers: None for requested patterns. Next action: Normalize frames and implement character emergence separately if requested.

## Stage entrance tile artwork
- Goal/status: Generate a restaurant-themed stage-start entrance image; complete as artwork, not integrated.
- Completed: Built-in imagegen produced one transparent cream/mint double doorway, coral striped canopy, teal glass/gold handles and right-arrow sign; visually reviewed silhouette/palette/no lettering. Saved images/tilesets/restaurant_stage_entrance_source.png.
- Decisions: Source artwork only; logical96×128 usage was requested in prompt but generated resolution is not a production tile grid. No map/physics/runtime changes.
- Final prompt: Isolated flat front-elevation restaurant entrance, chunky pixel art, cream ceramic surround/mint frame/coral-cream canopy/teal double doors/gold handles/right-arrow sign only, transparent exterior, no scenery/characters/lettering/glow; readable at96×128 logical pixels.
- Files: New source PNG; WORKLOG.md; AGENTS.md asset-location note.
- Verification: Visual review PASS; PNG dimensions/RGBA/alpha checked. No gameplay tests needed. No implementation refactor required.
- Blockers: None. Next action: If approved for integration, normalize to chosen tile dimensions and define placement separately.

## Three provisional stages
- Goal/status: Add playable stages1/2/3; complete.
- Completed: Three selectable cards backed by stage_catalog.gd; existing restaurant1; saved2048×768 ring terrace2 and cargo/pulley kitchen3. New courses each have9 physical rings,8 food placements, checkpoint, recovery floor and distinct stepped terrain. Shared Game stage_scene/stage_width exports and optional prop markers configure inherited game scenes. Exit40px goal displays result/selection return on all courses.
- Decisions: Preserve current gameplay settings and reciprocal physics. New maps intentionally provisional; stage1 authored source and shared TileSet untouched. No progression locks/save system.
- Files: scripts/stage_catalog.gd, stage_select.gd, game.gd; scenes/game_stage_2/3.tscn, stages/stage_2/3.tscn; tools/build_provisional_stages.gd, verify_stage_select.gd; specs/stage-selection.md; AGENTS.md/WORKLOG.md. Earlier stage-selection/help-removal uncommitted changes retained.
- Refactoring: Extracted Game._setup_stage; menu cards share one construction method and catalog; inherited scenes share Game/physics rather than copying implementation. Regenerated maps after correcting kitchen pulley placement above clear floor.
- Verification: Map generator PASS; final verify_stage_select PASS for all cards, actual scene identity, floor settling, real ring shot, camera, checkpoint death reload, R reset, physical goal and return. verify_controls and verify_gum PASS; git diff --check PASS. Known sandbox CA/exit resource warnings remain. Rendered/hardware QA and complete end-to-end route playthrough not performed.
- Blockers: None. Next action: F5 playtest3 provisional courses, then tune route difficulty/layout.

## Stage selection screen
- Goal/status: Implement stage selection and gameplay return; complete.
- Completed: Cream/mint/coral restaurant card with existing food artwork, focused start button, F5 menu startup, actual Game transition, Esc/ui_cancel and HUD return. Fresh entry clears checkpoint metadata; Game R/death behavior retained. Preserved prior uncommitted help-removal edits.
- Decisions: Existing six-section map is one restaurant stage; no fabricated stages or progression. Direct Game F6 remains supported.
- Files: project.godot; scenes/stage_select.tscn, game.tscn; scripts/stage_select.gd(+uid), game.gd; tools/verify_stage_select.gd; specs/stage-selection.md, player-controller.md, keyboard-controls.md, godot-implementation-plan.md; AGENTS.md/WORKLOG.md.
- Refactoring: Reviewed menu construction, focus, reentry guards and scene-owned lifecycle; kept menu isolated from physics and shared settings. No obsolete startup path or extra global state.
- Verification: Headless import PASS; final stage-selection suite PASS (focused accept, fresh entrance/checkpoint clearing, R, actual Esc, HUD round trip); existing verify_controls.gd PASS; git diff --check PASS. Known sandbox CA warning only. Rendered visual and physical gamepad QA not performed.
- Blockers: None. Next action: F5 visual/playtest review of stage selection.

## Remove on-screen control help
- Goal/status: Remove gameplay control instructions; complete.
- Completed: Deleted HUD/Help Label; preserved runtime status display. Updated control/architecture specs and durable HUD guidance.
- Files: scenes/game.tscn, specs/keyboard-controls.md, specs/godot-implementation-plan.md, AGENTS.md, WORKLOG.md.
- Decisions/refactor: Remove unused Label rather than hiding it; no script references exist. Reviewed HUD ownership; no further restructuring needed.
- Verification: Headless gameplay startup (Godot --quit-after 3) and git diff --check PASS after final refactor review; known sandbox CA certificate warning only.
- Blockers: None. Next action: Optional F5 visual review.

## Hit-driven waypoint pulley
- Goal/status: Implement per-hit waypoint travel with LOOP/PING_PONG; complete.
- Completed: Pulley script/scene and Game adhesion binding; exported local2D points/mode/speed/force, generated rail segments including loop closure, force motor and per-segment native guide. Specs/AGENTS aligned.
- Decisions: Fresh successful adhesion advances1segment; moving hits ignored/no queue; sustained connection does not repeat; arrival waits, detach does not stop motor. Default3-point horizontal ping-pong (80→184→288),140px/s/18000force. Powered hold replaces passive drifting; reciprocal gum forces/player momentum remain physical.
- Files: scripts/pulley_trolley.gd(+uid), scenes/props/pulley_trolley.tscn, scripts/game.gd, tools/verify_pulley_trolley.gd, specs/pulley-trolley.md, AGENTS.md/WORKLOG.md.
- Verification: Initial focused suite PASS: mode cycles/reversals,2D loop/native guide, real-hit-only/moving-hit/no-queue/arrival wait, loaded hanging/reciprocal forces/release fall, pass-through, actual Game preview/launch/arrival and R reset. Known sandbox import/CA/exit-resource warnings remain. Final refactor simplified rail creation to an assigned shared AtlasTexture, removed template Sprite/lifecycle; reviewed motor/state/force ownership. Final focused and gum/controls regression PASS; git diff --check PASS.
- Blockers: None. Native gameplay rendered QA not performed. Next action: F5 gameplay review; configure PulleyTrolley Route Points/Route Mode for authored courses.

## Elevate hanging pulley
- Goal/status: Move pulley to a high position; complete.
- Completed: Game rail origin(944,384), axle(1024,384), pad(1024,426); approach from one-way platform at(1024,512). Synced spec/AGENTS and actual-stage shot fixture.
- Decisions: Raise196px, preserve horizontal travel and physics; upper beam ends y352, leaving room for wheel. Upper platform owns reachable firing position with saved160px range.
- Files: scenes/game.tscn, tools/verify_pulley_trolley.gd, specs/pulley-trolley.md, AGENTS.md/WORKLOG.md.
- Verification: Final refactor reviewed all current placement references and approach/geometry; Focused suite PASS including grounded upper-platform approach/UP shot, hanging-only physics and R reset; git diff --check PASS. Known sandbox CA/exit-resource warnings remain; native gameplay visual QA not performed.
- Blockers: None. Next action: F5 review elevated pulley above the section2 upper platform.

## Integrate single-wheel hanging pulley
- Goal/status: Replace serving trolley with approved hanging-only single-wheel pulley; complete.
- Completed: Source-identical runtime PNG and new atlas regions; platform removed; convex pad at(0,42) is rigid bit16/mask0, player/props pass through. Native mass1.5/288px rail/initial80px and stage placement preserved. Removed superseded runtime art/import and palette shader; specs/AGENTS aligned.
- Files: scenes/props/pulley_trolley.tscn; assets/props/restaurant_pulley_single_wheel.png(+import); tools/verify_pulley_trolley.gd; specs/pulley-trolley.md; AGENTS.md/WORKLOG.md. Deleted old runtime trolley PNG/import and pulley_rail shader/uid; concept sources retained.
- Verification: Import and focused test PASS: real pad ray/reciprocal tension/horizontal movement/release momentum/end stops, player+box pass-through, no floor support, sustained gum hanging, falling after release, saved-stage UP flight and R reload. Original/runtime PNG parity verified. Final refactor reviewed scene-only ownership, shape/art origin alignment, gum-only masks and removal of obsolete support/material resources; no core player/gum changes. Final focused rerun, gum/controls/anchors regression and git diff --check PASS. Known sandbox CA/editor and exit-resource warnings remain; native rendered visual QA not performed.
- Blockers: None. Next action: F5 visual/playfeel review of hanging-only pulley in section2; existing full-route range mismatch remains outside task.

## Single-wheel hanging pulley concept
- Goal/status: Generate approved single-wheel hanging-only design; complete as concept, gameplay unchanged.
- Completed: Built-in imagegen edit of hanging concept, visually reviewed exactly one coral wheel, narrow cream vertical bracket, smaller pink teardrop and dark gray-green rail; no connecting plate/platform. Saved images/props/restaurant_pulley_single_wheel_concept.png.
- Final prompt: Replace two wheels/connecting plate with exactly one centered round coral wheel and gold axle; narrow short cream vertical pendant with mint trim, filled pink downward teardrop smaller than wheel; retain dark desaturated gray-green rail, chunky side-view pixel art, transparent background; no standing surfaces/text/characters/rope.
- Files: New concept PNG and WORKLOG.md. No new verified implementation knowledge for AGENTS.md.
- Verification: Generated appearance reviewed against approved silhouette/palette; no runtime changes/tests required.
- Blockers: None. Next action: Use selected single-wheel concept for hanging-only runtime asset/physics integration when requested.

## Hanging-only pulley artwork concept
- Goal/status: Generate approved hanging-only redesign; complete as concept, runtime unchanged.
- Completed: Built-in imagegen edit of original concept; removed serving platform/side supports, compact coral wheel carriage, cream pendant and downward pink teardrop pad, dark gray-green rail. Transparent result visually reviewed and saved to images/props/restaurant_pulley_hanging_concept.png.
- Final prompt: Edit original into strict side-view chunky pixel-art hanging-only pulley; remove all lower standing surfaces, keep two coral wheels/thin mint frame/gold hardware, short cream pendant and filled downward pink teardrop pad, long dark desaturated gray-green rail, transparent background, no characters/text/gum rope/scenery.
- Files: New concept PNG and WORKLOG.md. No new verified implementation knowledge for AGENTS.md.
- Verification: Generated visual satisfies silhouette/palette/pad requirements. No runtime changes/tests needed.
- Blockers: None. Next action: If integrated, replace atlas regions and remove player-support collision while preserving rigid gum force and native rail constraint.

## Subdue pulley rail color
- Goal/status: Reduce rail brightness/saturation so it does not read as floor; complete.
- Completed: Shared source-coordinate shader on stationary rail and baked carriage rail; mint pixels in original y108–171 band use25% saturation and62% brightness. Other carriage artwork preserved.
- Files: shaders/pulley_rail.gdshader, scenes/props/pulley_trolley.tscn, specs/pulley-trolley.md, AGENTS.md/WORKLOG.md.
- Decisions: Render-time palette treatment preserves source PNG and applies consistently to both atlas regions. No physics changes.
- Verification: Final refactor reviewed shared material/no duplicate palette code, atlas coordinates and alpha preservation. Final focused pulley suite PASS; rail-band mask sampling PASS; git diff --check PASS. Known sandbox CA warning only. Native rendered visual QA not performed.
- Blockers: None. Next action: F5 review subdued gray-green rail at gameplay camera scale.

## Integrate physics pulley trolley
- Goal/status: Integrate generated serving trolley; complete.
- Completed: Reusable native GrooveJoint2D horizontal rail and RigidBody2D carriage, physical platform/pad, AtlasTexture artwork, F5 Game placement(944,580), spec and AGENTS guidance; existing gum/player interaction reused.
- Decisions:288px engine-constrained travel, initial80px, mass1.5, damping0.35, rotation locked. Platform top y650 in section2. Both pad/platform attachable; rail visual only; wheel art static. Source/runtime PNGs identical.
- Files: scenes/props/pulley_trolley.tscn, scenes/game.tscn, assets/props/restaurant_pulley_trolley.png(+import), tools/verify_pulley_trolley.gd(+uid), specs/pulley-trolley.md, AGENTS.md/WORKLOG.md.
- Verification: Final strengthened focused suite PASS for actual ray/reciprocal tension/pull/release momentum/rail bounds/rider support+carry/saved-stage LEFT shot/R reload; gum, controls, compression and saved-map suites PASS. Route suite FAILS at lift0; removing trolley reproduces identical failures (saved range160 vs authored222px shot); temporary diagnostic removed. Known sandbox CA/editor/exit warnings remain. Final refactor reviewed native constraint ownership, shape/art alignment, isolated scene and strengthened end-stop assertion to track actual approach (joint may recoil after impact). git diff --check PASS.
- Blockers: No trolley blockers. Native gameplay visual QA not performed. Next action: F5 visual/playfeel review in section2. Baseline route/tuning mismatch remains outside this task.

## Rising checkpoint idle trails
- Goal/status: Implement approved rising side lights/top stars; complete.
- Completed: Replaced scattered idle sparkles with paired50px rising lights, tapered tails,10px top-star bloom and1s stagger. Re-exported source/runtime sheets; current specs/AGENTS aligned.
- Decisions: Keep96px cells/60frames/2s and runtime lifecycle; activation burst retained. Inactive cream/coral, registered mint/cream; central flag/check unobscured.
- Files: checkpoint-idle.mjs, checkpoint_idle.png/checkpoint_active.png and runtime copies, specs/checkpoints.md, AGENTS.md/WORKLOG.md.
- Verification: Both color variants contact-sheet visual review PASS; source/runtime parity/dimensions PASS; Godot import/checkpoint suite/diff check PASS (known sandbox editor/CA/exit warnings). Final refactor reviewed shared palette constants, phase/brightness boundaries, tail-to-star transition and existing runtime/export interfaces; no runtime code changes required. Native gameplay visual QA not performed.
- Blockers: None. Next action: F5 review at gameplay camera scale.

## Checkpoint idle visibility concept
- Goal/status: Propose stronger idle visibility; concept complete, runtime/assets unchanged.
- Completed: Reviewed current four small side sparkles and2s loop.
- Proposal: Paired mint/cream rising side trails with staggered stars and a periodic top sparkle; emphasize coherent vertical motion over scattered extra particles. Keep flag/check center clear, avoid full ring and rapid flashing. Inactive cream/coral, registered mint/cream.
- Files changed: WORKLOG.md only; proposal is not adopted tuning. No new verified implementation knowledge for AGENTS.md.
- Verification: Source review only; no runtime changes/tests needed.
- Blockers: None. Next action: On adoption, revise PixelFX idle source/export both variants, review at gameplay camera scale and run checkpoint verification.

## Pulley trolley concept image
- Goal/status: Generate the proposed serving pulley trolley image; complete.
- Completed: Built-in imagegen produced a transparent side-view pixel-art concept; visually reviewed exposed wheels/rail, pink solid adhesion pad and cream serving platform. Saved images/props/restaurant_pulley_trolley_concept.png; no runtime integration.
- Final prompt: Single isolated orthographic side-view restaurant serving pulley trolley; long mint rail, two exposed coral wheels, gold axles, cream suspension with solid pink adhesion disk and broad cream/mint serving platform; crisp chunky pixel art, brown outlines, transparent background; no characters/text/arrows/perspective.
- Verification: Generated output visually reviewed. Concept only; sprite slicing, physical dimensions and motion design remain undecided. No tests needed. No new durable implementation knowledge for AGENTS.md.
- Blockers: None. Next action: Review concept before producing separate rail/carriage/wheel game assets.

## Gum-driven pulley visual concept
- Goal/status: Propose artwork for a pulley-like gum-driven gimmick; concept complete, no implementation/art asset changes.
- Completed: Reviewed current worklog, restaurant palette and stage/physics direction.
- Proposal: Mint rail-mounted cream trolley with coral wheel, exposed axle and distinct gum adhesion pad; alternatives are a kitchen serving lift and a wall crank. Show motion through visible rails/wheel rotation and tension response rather than a hit-triggered scripted result.
- Decisions: Concept only; motion axis, load and exact mechanics remain undecided. Keep adhesion target distinct from existing hollow gum-only rings.
- Files changed: WORKLOG.md only. No new verified durable repository knowledge for AGENTS.md.
- Verification: Existing art/spec conventions reviewed; no runtime changes/tests required.
- Blockers: None. Next action: Select visual concept, then prepare a side-view idle/pulled concept image before production sprites.

## Increase checkpoint effect visibility
- Goal/status: Make checkpoint PixelFX moderately more visible; complete.
- Completed: Idle4 larger particles/stars in both states with subtle glow; activation arcs2px with bright core; burst stars up to9px with glow and slower visual fade. Source/runtime sheets regenerated; specs/AGENTS aligned.
- Files: checkpoint-idle.mjs/checkpoint-activate.mjs, three effect PNGs and runtime copies, specs/checkpoints.md, AGENTS.md/WORKLOG.md.
- Verification: Contact-sheet visual review PASS; sheet parity/transparent final frame PASS; Godot import and focused checkpoint suite PASS (known sandbox CA/editor/exit warnings). Final refactor reviewed effect bounds, numeric colors, fading, export consistency and existing timing/lifecycle; no runtime change required. git diff --check PASS.
- Blockers: None. Next action: F5 visual review at gameplay camera scale.

## Food idle PixelFX implementation
- Goal/status: Create and integrate approved food availability sparkles; complete.
- Completed: PixelFX source/exporter, identical transparent sheets, animated preview; all foods create child idle sprite, immediate hide on reel/collect and restore on cancelled reel; docs/AGENTS and lifecycle verification.
- Decisions:96px cells/60frames/30fps/2s, cream/gold four-point stars outside dish, maximum7px; deterministic per-position phase; existing success burst unchanged.
- Files: images/effects/food-idle.mjs, food_idle.png, food_idle_preview.gif; tools/build_food_idle_effect.mjs; runtime sheet/import and food_idle_effect.gd; food_collectible.gd; verify_food_collect_effect.gd; specs/food-idle-effect.md, food-item-assets.md; AGENTS.md/WORKLOG.md.
- Verification: PixelFX export via connected Node runtime PASS (shell node unavailable); light/dark composite visual review PASS; sheet parity PASS; Godot import and food collect effect/collectibles/reel suites PASS. Known sandbox CA and exit-resource warnings remain. Refactor reviewed child ownership, setter visibility and shared frame update; no duplicate physics or collection flow. git diff --check PASS. Native in-game visual review unperformed.
- Blockers: None. Next action: F5 review at normal camera scale if desired; edit PixelFX source/exporter to tune appearance.

## Checkpoint PixelFX implementation
- Goal/status: Create and integrate idle/activation/registered checkpoint effects; complete.
- Completed: Two editable PixelFX modules, three transparent sheets and runtime copies, reproducible Node exporter, art-only child effect and checkpoint activation integration. Docs/AGENTS and focused lifecycle tests aligned.
- Decisions:60-frame96×96 idle variants/2s;25-frame128×96 burst/0.8s; six stars0.4s after activation; no replay on respawn/repeated contact. Idle hidden during burst. Feet origin/nearest rendering, no physics changes.
- Files: images/effects/checkpoint-{idle,activate}.mjs and checkpoint_{idle,active,activate}.png; runtime copies; tools/build_checkpoint_effects.mjs; checkpoint_effect.gd; checkpoint scene/script; verify_checkpoints.gd; specs/checkpoints.md; AGENTS.md/WORKLOG.md.
- Verification: PixelFX contact-sheet review PASS; exporter rerun PASS; nonempty PNGs/runtime parity/transparent final burst frame PASS. Final Godot import/checkpoint suite/spike suite/diff check PASS (known sandbox CA/editor and exit-resource warnings). Refactor reviewed ownership, one-shot lifecycle, editor isolation, common sprite factory and exporter reuse; corrected px alpha use to fading line and guarded floating-point final time. Native in-game visual QA remains unperformed.
- Blockers: None. Next action: F5 review at normal camera scale; editable PixelFX sources and exporter support later art tuning.

## Checkpoint PixelFX concept
- Goal/status: Propose surrounding checkpoint effects; concept complete, implementation unchanged.
- Completed: Reviewed existing PixelFX gum-attach/landing-dust modules and current flag→check artwork/timing.
- Proposal: Sparse warm-cream idle sparkles, then mint/cream elastic side arcs and small upward sparkles synchronized with final check (~0.4s after activation); restrained active idle sparkle. Avoid enclosing rings that resemble gum anchors or large opaque bursts hiding the flip.
- Files changed: WORKLOG.md only. No new verified durable implementation knowledge for AGENTS.md.
- Verification: Local PixelFX exports support seeded drawing, glow/ellipse/px/shade and independent loop/one-shot metadata; no runtime changes/tests required.
- Blockers: None. Next action: If adopted, author independent idle/activation PixelFX modules and transparent sprite sheets; bind activation once, suppress burst on respawn and keep art-only effects outside physics.

## Replace inactive checkpoint circle with flag
- Goal/status: Adopt muted coral flag → mint check artwork; complete.
- Completed: Built-in imagegen edit, composited only inactive sign interiors, original alpha and active-frame RGBA restored exactly; source/runtime copies updated. Specs include final prompt and edit-source provenance; test label and AGENTS aligned.
- Decisions: Preserve existing base alignment/active check/4x2 flip timing. Generated edit retained separately as restaurant_checkpoint_flag_edit.png.
- Files changed: images/props/restaurant_checkpoint_{flip_source,flag_edit}.png, runtime restaurant_checkpoint.png, specs/checkpoints.md, verify_checkpoints.gd label, AGENTS.md, WORKLOG.md.
- Verification: Final unique-path visual review PASS;1774×887 RGBA, byte-exact alpha and active4 frames, runtime parity PASS. Godot import and focused checkpoint suite PASS (known sandbox editor/CA warnings). Refactor review: retained existing art-only pipeline, no scene/script behavior changes; current documentation/test terminology aligned. git diff --check PASS.
- Blockers: None. Next action: F5 review in-game flag at normal camera scale if desired.

## Inactive checkpoint design review
- Goal/status: Consider a clearer alternative to the inactive circle; design recommendation complete, artwork/runtime unchanged.
- Completed: Inspected current eight-frame flip sheet, checkpoint scene and specification.
- Decision/proposal: Recommend a muted coral checkpoint flag silhouette on the existing cream tabletop sign; retain mint check on activation and horizontal-axis flip. Current circle resembles the functional gum anchor and has ambiguous inactive meaning. This is a proposal, not adopted art direction.
- Files changed: WORKLOG.md only.
- Verification: Source image and actual scene scale reviewed; no runtime changes/tests required. No new verified durable implementation knowledge for AGENTS.md.
- Blockers: None. Next action: If adopted, redesign inactive-side frames consistently while retaining base alignment, active check and eight-frame timing.

## Subdue glass highlights
- Goal/status: Slightly darken reflection streaks; complete.
- Decisions: Built-in imagegen edit, preserve pale blue glass/light frame, placements and physics.
- Completed: Built-in imagegen reflection edit; restored original alpha with ImageMagick CopyOpacity after generated variants changed transparency, normalized both copies. Preview reviewed; docs/AGENTS updated.
- Files: source/final/runtime PNGs, specs/gum-pass-barrier-tile.md, AGENTS.md/WORKLOG.md.
- Tests: Original alpha byte-for-byte preserved and runtime PNG parity PASS; visual review PASS. Refactor reviewed source normalization (unchanged) and documented alpha restoration. Highlights mean RGB246→212 (14% darker); Godot import and diff check PASS (known sandbox settings/CA warnings). Physics/placements unchanged. Blockers: None. Next action: F5 visual review as desired.

## Light frame and pale blue glass
- Goal/status: Brighten gray frame and add transparent blue glass tint; complete.
- Decisions: Built-in imagegen edit, translucent blue instead of dithering; preserve32px footprint and reflections, physics and placements.
- Completed: Built-in imagegen edited source, crop updated to silver-frame bounds156..1098, both32px copies regenerated. Enlarged review confirms light frame, blue pane and retained diagonal highlights; specs/AGENTS updated.
- Files: source/final/runtime PNGs, tools/build_gum_pass_barrier.py, specs/gum-pass-barrier-tile.md, AGENTS.md/WORKLOG.md.
- Tests: Visual PASS; sampled blue pane alpha23/255, frame253/255. Refactor reviewed explicit crop/current source authority. RGBA32px, low-alpha pane, copy parity and diff checks PASS; Godot import completed (known sandbox settings/CA warnings). Physics and placements unchanged. Blockers: None. Next action: F5 appearance review as desired.

## Gray glass barrier with more reflections
- Goal/status: Increase highlight coverage and shift frame toward gray; complete.
- Decisions: Built-in imagegen edit current source; preserve transparency,32px grid and collision/placements.
- Completed: Two built-in imagegen edits, source copied and normalized to both32px copies. First edit had colored speckles; final edit plus20px crop preserves clean gray frame and six reflections. Enlarged preview checked. Specs/AGENTS updated.
- Files: source/final/runtime PNGs, tools/build_gum_pass_barrier.py, specs/gum-pass-barrier-tile.md, AGENTS.md/WORKLOG.md.
- Tests: Visual PASS;712/784 interior pixels fully transparent (91%). Refactor reviewed source normalization, made crop explicit for current1254px source. PNG dimension/neutral frame/transparency/copy parity and diff checks PASS; Godot import completed (known sandbox settings/CA warnings). Physics/placements unchanged. Blockers: None. Next action: F5 appearance review if desired.

## Thin glass barrier artwork
- Goal/status: Thin frame and add subtle transparent glass highlights; complete.
- Decisions: Preserve32px grid, placements and physics; built-in imagegen edit with original tile, keep alpha and restaurant palette.
- Completed: Built-in imagegen edited original to thin frame/sparse reflections; saved generated source and nearest32px copies, visually inspected enlarged result. Replaced procedural authoring with source-normalization utility; specs/AGENTS updated.
- Files: barrier images/runtime PNG, restaurant_gum_pass_barrier_source.png, tools/build_gum_pass_barrier.py, specs/gum-pass-barrier-tile.md, AGENTS.md/WORKLOG.md.
- Tests: Center alpha0, only16 nontransparent pixels inside28px interior; enlarged visual review PASS. Refactor reviewed utility/source authority and removed obsolete procedural design. 32px RGBA/byte parity and diff check PASS; Godot import completed with known sandbox editor settings/CA warnings. Collision/placements unchanged. Blockers: None. Next action: F5 appearance review as desired.

## Place gum-pass barriers in stage
- Goal/status: Integrate frame tiles into playable stage; complete.
- Decisions: Two three-cell horizontal screens below existing rings in sections01/03, optional overhead geometry preserves lower route. Layout owns placements; update saved scene without regenerating unrelated content.
- Completed: Added six cells to layout/saved layer and generator; real saved-screen ring attachment/path continuity PASS. Added saved-screen body-block check; docs updated.
- Files: stage_layout.gd, build_theater_stage.gd, theater_stage.tscn, verify_gum_pass_barrier.gd, specs/gum-pass-barrier-tile.md, AGENTS.md/WORKLOG.md.
- Tests: Final focused PASS (saved6 cells, both ring connections/path continuity, saved-screen body block and existing four-direction/drop-mask suite); map PASS; diff check PASS. Refactor reviewed layout ownership, collision separation and preserved unrelated authored content. Known headless CA/exit-resource warnings only. Full route/native rendered playtest not run. Blockers: None. Next action: F5 review sections01/03 screens; edit GUM_PASS_BARRIERS for further placement changes.

## Gum-pass barrier tile
- Goal/status: Transparent framed tile blocks bodies and passes gum; complete; artwork, integration, refactor and verification finished.
- Decisions: 32px restaurant enamel square frame, transparent22px center and coral passage chevrons; independent physics bit64 avoids one-way drop-through toggles. source3 and empty GumPassBarriers layer; existing route untouched.
- Completed: Procedural pixel artwork/source and identical copies, saved TileSet + stage/generator, player77/box73 masks, focused real-physics suite and specification/durable guidance. Refactor reviewed mask isolation, full-cell semantics and generator/saved consistency; test nodes explicitly freed.
- Files: tools/build_gum_pass_barrier.py; images/runtime barrier PNGs; theater_tileset.tres; stage/player/box scenes; project.godot; build_theater_stage.gd; verify_gum_pass_barrier.gd/verify_one_way.gd; specs/gum-pass-barrier-tile.md + affected mask docs; AGENTS.md/WORKLOG.md.
- Tests: Initial focused suite PASS after correcting test-only state API; map and gum anchors PASS; PNG dimensions/transparent center/byte parity and visual preview PASS. Final focused rerun PASS with clean resource teardown. One-way regression exposed its obsolete exact box-mask9 assertion; updated to73 including barrier bit; full rerun PASS. Import succeeded with known sandbox editor/CA warnings. No generator run (preserves authored scene).
- Blockers: None. Next action: Paint source3/(0,0) on GumPassBarriers and save the scene when choosing placements. Native gameplay appearance remains for user review.

## Remove wall kicks
- Goal/status: Remove wall-derived kicks; complete; implementation, refactor and verification finished.
- Decisions: Keep ceiling kicks; wall contact permits existing coyote/one-use air jump but never grants/refills a jump. Floor/gum jumps unchanged.
- Completed: Removed wall-normal impulse/diagnostic source, separated jump-eligible contacts from all contacts, updated current specs and durable guidance. Added mirrored real-wall regression for exhausted allowance rejection and ordinary vertical double jump.
- Files: player.gd; verify_double_jump.gd; specs/keyboard-controls.md/player-controller.md/game-settings.md; AGENTS.md; WORKLOG.md.
- Tests: Focused double-jump suite incl. both real walls and72 launch cases PASS before/after refactor; controls PASS; git diff --check PASS. Full player PASS (42 mirrored corner conditions, wall-adjacent floor jumps, coyote, landing/momentum). Known CA/exit-resource warnings only. Blockers: None. Next action: Optional F5 playtest of wall-adjacent jumping.

## Double-jump vertical velocity assignment
- Goal/status: Replace all existing vertical momentum with configured double-jump speed; complete.
- Decisions: Accepted air jump assigns external_velocity.y = -double_jump_kick_speed, retaining X; current gravity and prior upward/downward speed cannot affect launch. Gravity resumes next tick; other jumps unchanged.
- Completed: Directly assign double-jump Y speed; compensation diagnostics record canceled old vertical velocity. Other jump branches retain compensation plus additive impulse. Updated focused and control/player/food expectations and current specs/AGENTS; saved tuning untouched. Refactor: removed obsolete gravity reconstruction, renamed focused matrix to vertical-speed assignment, removed unused additive-test variables.
- Files: player.gd; tools/verify_double_jump.gd/verify_controls.gd/verify_player.gd/verify_food_reel.gd; specs/player-controller.md/keyboard-controls.md/game-settings.md; AGENTS.md, WORKLOG.md.
- Tests:72 launch cases and Game adhesion/rejump PASS. Controls, final food rerun, post-refactor72-case rerun and full player (including42 corner conditions) PASS. Final test cleanup moved third-press baseline capture to its actual use. git diff --check PASS. Known CA/exit-resource warnings only. Blockers: None. Next action: F5 jump-feel review as desired.

## Gravity-free double-jump launch tick
- Goal/status: Ignore downward gravity at double-jump launch before upward impulse; complete.
- Findings: Existing launch cancels downward external speed but upward momentum still loses current-tick gravity. Current user tuning: kick_speed inherits400, double_jump_kick_speed300, rotation3; preserve resource.
- Decisions: Only accepted double jump removes current-tick gravity, then cancels remaining downward external speed and adds independent kick. Retain pre-gravity upward/horizontal momentum; gravity resumes next tick. Other jump types unchanged.
- Completed: Added air-jump-specific gravity removal before downward cancellation; shared impulse/deformation/diagnostics remain intact. Updated control/settings specs and verified current tuning guidance without editing saved Resource. Refactor reviewed calculation ordering, rising-to-falling boundary, no double gravity removal and other jump branches; reused compensation path.
- Files: player.gd, verify_double_jump.gd, specs/player-controller.md/keyboard-controls.md/game-settings.md, AGENTS.md, WORKLOG.md.
- Tests: Focused72-case gravity/timestep/vertical/horizontal matrix and actual Game gum rejump PASS; food/controls/deformation and post-refactor focused rerun PASS; git diff --check PASS. Known headless CA/exit-resource warnings only. Blockers: None. Next action: F5 jump-feel review as desired; native playback not performed.

## Separate first and double-jump kick speeds
- Goal/status: Expose independent initial/contact and double-jump impulse speeds; complete.
- Decisions: Existing Player Movement/kick_speed retains normal/contact/coyote/gum-release/food/ladder behavior; new Player Double Jump/double_jump_kick_speed applies only to the one-use spinning air jump. Current saved kick_speed380 is preserved and seeds new saved/schema380.
- Completed: Added independent export/saved380, selected launch speed by accepted air-jump type in existing shared impulse pipeline, aligned controller/keyboard/settings specs and AGENTS. Refactor reviewed all impulse consumers and named local launch_speed to distinguish selected speed from setting; no parallel jump implementation.
- Files: game_settings.gd/.tres, player.gd, verify_double_jump.gd, specs/game-settings.md/player-controller.md/keyboard-controls.md, AGENTS.md, WORKLOG.md.
- Tests: Distinct310/470 first/air/gum-release physical fixture PASS. Final post-refactor focused, actual Game gum adhesion/rejump, controls, food reel and deformation suites PASS; git diff --check PASS. Known CA/exit-resource warnings only. Blockers: None. Next action: Tune the two Inspector values independently as desired.

## Gum adhesion cancels spin and restores air jump
- Goal/status: Stop double-jump rotation at gum adhesion and allow another double jump after release; complete.
- Decisions: Successful terrain/rigid/ring adhesion restores one air allowance once and resets visual spin immediately, without velocity changes. Food reeling retains independent reward/lock rules; misses/outbound do not restore. Attached Z remains detach jump, followed by one fresh airborne double jump.
- Completed: Non-food Gum._attach_hit calls Player.on_gum_attached; reuse spin-stop/animation/deformation helpers for immediate visual restoration. Dedicated real Game swept-flight→adhesion→Z release→fresh air jump PASS; immediate direct-adhesion momentum preservation and held-connection no-refill PASS. Source/controller/keyboard specs and AGENTS updated.
- Files: player.gd, gum_connection.gd, verify_double_jump_gum.gd, specs/player-controller.md/keyboard-controls.md/character-sprite-audit.md, AGENTS.md, WORKLOG.md.
- Tests: Final dedicated real Game suite (including food exclusion), double-jump, gum/live Game, controls and food reel PASS; git diff --check PASS. Final refactor reviewed one-shot event boundary and reused existing visual pipeline without extra fixed-step state. Known sandbox CA and headless exit-resource warnings only. Blockers: None. Next action: F5 appearance/feel review as desired; native playback not performed.

## Facing-dependent double-jump rotation
- Goal/status: Make spin direction follow character facing; complete.
- Decisions: Right-facing clockwise, left-facing counterclockwise. Read current sprite flip each fixed step, reverse continuously on midair facing changes, neutral input retains facing. Shared speed remains magnitude; no physics changes.
- Completed: Applied current facing sign after animation selection with positive angular wrapping. Expanded real-input custom-speed tests through left→neutral→right→neutral. Refactor reviewed: reuse sprite.flip_h, no duplicated facing state, isolated speed magnitude/direction; Inspector tooltip explains direction. Files: player.gd, game_settings.gd, verify_double_jump.gd, specs/game-settings.md/player-controller.md/keyboard-controls.md, AGENTS.md, WORKLOG.md.
- Tests: Initial focused test exposed stale assumption that saved speed is2.5; user tuning is6.0 and preserved. Fixture now explicitly sets2.5 rather than asserting gameplay tuning; final focused rerun PASS (both directions, live reversal, neutral retention, custom/zero speed, momentum/collision invariants). Deformation/afterimages PASS; diff check PASS. Known CA/exit-resource warnings only. Blockers: None. Next action: F5 visual review as desired.

## Configurable double-jump rotation speed
- Goal/status: Expose visual rotation speed in shared Settings; complete.
- Decisions: Player Double Jump / Double Jump Rotation Speed in revolutions per second, default2.5 (=0.4s/revolution);0 freezes rotation without changing pose or physics. Read live each fixed step.
- Completed: Exported speed with rev/s Inspector suffix, saved/schema2.5 baseline, replaced fixed-period constant, documented controls/settings and durable guidance. Refactor reviewed shared visual path and separated rev/s→radians conversion for clarity. Files: game_settings.gd/.tres, player.gd, verify_double_jump.gd, specs/game-settings.md/player-controller.md/keyboard-controls.md, AGENTS.md, WORKLOG.md.
- Tests: Dedicated double-jump PASS including custom1/4rev/s, live tuning, zero freeze, shared defaults and unchanged velocities. Deformation and post-refactor focused rerun PASS; git diff --check PASS. Known headless CA/exit resource warnings only. Blockers: None. Next action: Adjust Player Double Jump / Double Jump Rotation Speed in shared resource as desired.

## Tuck pose runtime integration
- Goal/status: Use approved knees-hugged artwork during double-jump rotation; complete.
- Completed: Registered cropped single-frame double_jump art and source scale; spin priority, mirrored/rotating hand sample and actual landing/reel restoration verified. Reviewed full visual pipeline: reuse existing SpriteFrames/deformation/afterimages, keep source intact, named source constants, no duplicate state or physics edits.
- Decisions: Keep source pixels intact; AtlasTexture clips visible body region, runtime scale0.175 matches existing head width. Tuck pose takes priority while spinning; ladder/landing/reel reset restores normal poses. No physics changes.
- Files: player.gd, player.tscn, runtime teto_double_jump.png(+import), verify_double_jump.gd, specs/player-controller.md and character-sprite-audit.md, AGENTS.md, WORKLOG.md.
- Tests: Final double-jump (pose, scale, mirrored hand, outbound priority, actual landing/reset), deformation, afterimages, gum hand origin,17304-case hanging poses and physical controls PASS. Runtime import, PNG byte parity and git diff --check PASS. Known sandbox CA/Mono editor warnings and headless exit-resource warnings; no assertion failures. Initial new test type-inference parse error corrected with explicit Vector2.
- Blockers: None. Next action: F5 appearance review; native rendered playback not performed.

## Tucked rotation-jump pose
- Goal/status: Create Teto hugging-knees pose using supplied somersault posture reference; complete as asset.
- Completed: Built-in imagegen with existing jump/front art for identity and supplied image for posture; visually verified both arms holding folded legs, compact silhouette and intact hair/boots. Saved project copy; existing runtime assets unchanged.
- Decisions: Single upright right-facing pose on transparent background; engine rotates artwork. Runtime normalization/integration remains a separate task.
- Files: images/teto_double_jump.png, specs/character-sprite-audit.md (prompt/use guidance), AGENTS.md, WORKLOG.md.
- Verification:1254×1254 RGBA, alpha0–255, corner alpha0/0/1/0 (nearly transparent); faint low-alpha peripheral pixels retained; visual review PASS. Naming/scope/spec review complete; no runtime implementation changes to refactor or test.
- Blockers: None. Next action: Normalize to existing head/body scale and integrate only when requested.

## Double jump implementation
- Goal/status: Add one airborne jump with sprite-only rotation; complete.
- Decisions: One air allowance refreshed on floor only; contact/coyote/gum/food/ladder actions take priority without refilling/consuming it. Shared kick_speed, gum-style downward cancellation; sprite spins every0.4s until floor/ladder/reset. Body/collider and movement physics remain independent of spin. New request overrides prior no-air-jump scope.
- Completed: Controller, dedicated real-physics suite, affected legacy rejection fixtures, controller/keyboard/food specs and AGENTS guidance. Refactor: named spin period and shared special-jump eligibility, reused existing impulse/deformation/sound pipeline.
- Files: scripts/player.gd; tools/verify_double_jump/player/controls/player_deformation/jump_buffer/food_reel.gd; specs/player-controller.md, keyboard-controls.md, food-gum-reel.md; AGENTS.md, WORKLOG.md. Existing local Git visibility entries preserved.
- Tests: Dedicated double-jump, physical controls, full player (42 corner conditions), deformation, jump buffer and food reel PASS. Post-refactor double-jump/deformation/buffer/food suites repeated PASS; final food test covers third-press rejection. git diff --check PASS. Known headless CA warning and intermittent exit resource warnings remain; no failed assertions.
- Blockers: None. Next action: F5 appearance/feel review; native visual playback not performed.

## Hide local PixelFX checkout
- Goal/status: Hide pixelfx from GitHub Desktop changes only; complete.
- Completed: Added /pixelfx/ to .git/info/exclude; checkout and shared .gitignore unchanged.
- Files: Local .git/info/exclude, AGENTS.md, WORKLOG.md. Verification: git check-ignore identifies local rule; git status no longer lists pixelfx. Reviewed single-rule scope; no runtime tests needed.
- Blockers: None. Next action: None.

## PixelFX GitHub Desktop plus indicator investigation
- Goal/status: Explain persistent pixelfx plus indicator; complete, no Git tracking policy changed.
- Findings: Parent git status reports `?? pixelfx/`; directory is an independent nested clone, neither tracked nor ignored nor registered as a submodule. Nested status also has untracked src/fx/impacts/gum-attach.js. Effect authoring sources import its core; preserve checkout.
- Files: WORKLOG.md and AGENTS.md only. Verification: Parent/nested status, tracked entries, ignore rules, origin and effect imports inspected. No runtime changes/tests needed.
- Blockers: None. Next action: Choose local ignore versus a reproducible shared dependency only if requested.

## Sound effect assignment
- Goal/status: Assign eight non-2 sounds to gameplay events; complete.
- Decisions: Global capped one-shot audio survives reload; checkpoint first activation only, accepted kicks/qualified landings, successful hit/fire, actual first contraction tick including food reel; relaxed-to-contract repeats once. Manual restart silent.
- Files: scripts/sound_effects.gd, game/player/gum_connection/food_collectible scripts, project.godot, assets/sounds, specs/sound-effects.md, AGENTS.md, WORKLOG.md.
- Verification: WAV import and focused8clips/24voice cap/contraction/repeated input/checkpoint/death/scene-removal checks PASS. Gum, food reel, food collectibles, checkpoints and spikes PASS; controls and full player42-corner regression PASS. All8 source/runtime WAV byte parity PASS.
- Limitations: Headless verification checks event/audio lifecycle, not perceived loudness. Known sandbox CA/editor warnings; some headless suites report exit resource warnings, final full player suite exits cleanly.
- Refactoring: Reviewed all event gates; grouped gum audio state with variables and clear it on detach; shared contraction helper covers reel/spring.
- Blockers: None. Next action: F5 auditory balance/timing review; native listening not performed. Focused SFX repeated PASS after refactor; diff check PASS.

## Direction-owned gum arm poses
- Goal/status: Apply angle-driven upper arm selection to firing and attached gum; complete.
- Decisions: Upper sector uses raised poses independent of speed/distance; lateral sector starts70deg from up (within20deg of horizontal). Outbound uses shot_direction immediately, including zero-length tip tick. Keep attached floor/slack and lower-direction behavior explicit/current; no physics edits.
- Completed: Shared sector selector for firing/attachment; initial fire_gum uses current shot direction; diagnostics expose shot/support source and upper sector; removed speed/40px arm gates. Updated tests/specs/durable guidance.
- Files: player.gd, verify_hanging_poses.gd, specs/character-gum-animations.md, specs/game-settings.md, AGENTS.md, WORKLOG.md.
- Verification: Dense17304-case suite PASS including short/fast vertical and zero-length flight; hand-origin suite PASS. Initial sweep found5deg float boundary ambiguity; applied same0.0001deg tolerance as70deg boundary.
- Refactoring: Shared shot/support direction source and sector selector remove separate speed/distance policy; pass computed angle to frame selector instead of recomputing. Diagnostics use same direction source. Reviewed all touched callers/specs.
- Final verification: Focused suite rerun PASS17304 cases plus real grounded upward fire/momentum invariant; hand-origin, gum/live Game, controls and food suites PASS; git diff --check PASS. Known sandbox CA warning only.
- Blockers: None. Next action: F5 appearance review of vertical/diagonal shots and fast upper swings; native visual playback not performed.

## Arm direction policy analysis
- Goal/status: Analyze upper gum connections showing lateral arm and proposed20deg-from-horizontal threshold; complete, analysis only.
- Findings: _select_animation chooses gum_pull when speed>=130 or support vertical offset>=-40 despite near-vertical support; supplied log tick847 has0deg/130.07px/s and tick921 has0deg/3.16px/s/offset-34.65, both pull. OUTBOUND always gum_fire regardless angle. Hand-origin smoothing changes only ribbon transition, not wrong pose selection.
- Recommendation: For attached upward loaded gum, choose arm direction from first support vector; remove speed and absolute40px distance as arm-orientation gates. Lateral regime only within20deg of horizontal (up-reference70–90deg); upper regime0–70deg uses hang/directional samples independent of speed. Body motion may reflect speed separately. Treat below-horizontal/grounded/slack/outbound explicitly; do not map lower angles to upper sprites indiscriminately. Boundary hysteresis may stabilize selection.
- Files: WORKLOG.md only. Verification: Reviewed current player selector and prior gameplay log; no runtime edits/tests for analysis. Blockers: None. Next action: Implement direction-owned arm selection when requested; verify vertical fast/short connections and horizontal20deg boundaries.

## Continuous gum visual hand origin
- Goal/status: Fix ribbon origin jumping when arm poses switch; complete.
- Findings: Physics origin already stays at chest, but rendering reads per-frame hand samples directly, jumping between front/raised poses and mirroring.
- Decisions: Smooth drawing-only hand offset in player-local space at fixed-step bounded speed; world player motion follows instantly. Keep raw pose target separate, initialize at ready, update once after deformation; no physics changes.
- Files: player.gd, game_settings.gd, verify_hanging_poses.gd, new verify_gum_hand_origin.gd, specs/character-gum-animations.md, specs/game-settings.md, AGENTS.md, WORKLOG.md.
- Completed: Added raw hand target/stored continuous origin, shared tuning360px/s (6px per60Hz tick), initialization and both simulation branches; diagnostic hand origin/target/gap. Updated angular hand test to check target.
- Verification: Hand suite PASS30/60/120Hz mirrored pose transitions/bounded movement/settling/player translation/deformation/physics/normal+food-lock actual simulate; angular674-case suite PASS. Gum/controls/food regressions PASS including live gameplay integration. Known sandbox CA warning only.
- Refactoring: Reviewed all origin consumers and both simulation branches; shared getter keeps ready/flight/attached/return/reel consistent, raw target separated from fixed-step state, no draw-time mutation or physics edits. Final hand suite repeated PASS; diff check PASS.
- Blockers: None. Next action: F5 visual review of front-to-up pose switching; artwork itself remains discrete and line briefly tracks toward its new hand target.

## Hanging diagnostic gameplay log review
- Goal/status: Review supplied gameplay angle logs; complete, no runtime changes requested.
- Findings: Logged10/20/30deg directional frames0/1/2 agree with nearest-angle selection; mirrored left30deg also correct. Logged angle range only0–29.863deg, so frames3–7 unobserved in this capture. Speed crossing130px/s repeatedly replaces angular hang with gum_pull; <40px vertical separation also replaces vertical hang despite low speed. Missing intermediate poses during fast swing reflect current eligibility, not incorrect quantization.
- Files: WORKLOG.md only. Verification: Parsed all33 diagnostic rows, checked angular selection error <=5deg; no wrong angular selections. No tests needed for read-only analysis. Blockers: None.
- Next action: If requested, broaden angular pose eligibility during fast swings; keep current physics unchanged. Otherwise gather larger-angle slow hanging capture to observe40–80deg.

## Hanging angle diagnostics
- Goal/status: Add gameplay logs to verify fine angle selection; complete.
- Decisions: Dedicated toggle, selection-change and30-tick samples with actual angle/frame/nominal/error/mirror/support/eligibility context; enable saved gameplay setting for immediate reproduction. Test dense sweep and transition boundaries.
- Completed: Added wrapper after animation selection, reusable snapshot, change/30-tick/exit logs, Inspector toggle (schemaOFF/savedON); dense sweep plus throttle/disable/exit checks. Added0.0001deg nearest-angle tie tolerance.
- Files: player.gd, game_settings.gd, game_settings.tres, verify_hanging_poses.gd, specs/game-settings.md, specs/character-gum-animations.md, AGENTS.md, WORKLOG.md.
- Verification: Focused suite PASS674 mirrored quarter-degree cases and all existing pose/hand/wrapping/physics invariants; SELECTED/SAMPLE/EXIT observed.
- Refactoring: Reviewed full pose selection/logging path; animation wrapper covers every early return, shared snapshot keeps diagnostics/tests consistent, loop frames excluded from direction-change key. Final focused suite and diff check PASS. Gum/controls regressions PASS including live Game. Known sandbox CA warning only.
- Blockers: None. Next action: F5 reproduce and inspect [HangingPoseDiagnostic] in Godot Output; disable shared toggle after investigation if desired.

## Hanging arm directional integration
- Goal/status: Integrate8 angular poses into hanging animation; complete.
- Completed: Reviewed player pose priority, hand origins and source sheet.
- Decisions: Normalize common body registration; choose static angular frame only in existing hanging state, preserve vertical hang loop and pull priority; use first wrapped support direction and mirror left.
- Files: WORKLOG.md, AGENTS.md, specs/character-gum-animations.md, player.gd, gum_animations.tres, normalized/runtime teto_gum_hang_angles.png(+import), verify_hanging_poses.gd, verify_gum.gd.
- Completed additionally: Normalized1024x512 atlas/runtime copy,8 hand samples, stopped nearest-direction selector and focused integration suite; specs updated.
- Verification: Focused hanging suite PASS all16 mirrored angles/hand positions/wrapped support/pose priorities/unchanged collision. Gum and controls regressions PASS. Normalized atlas dimensions/alpha/8 occupied cells/runtime byte parity and git diff --check PASS. Player full regression PASS including42 corner landings, movement, contact/coyote kicks, friction and animations. Known sandbox CA warning only.
- Refactoring: Reviewed pose-priority branch, isolated direction selector, kept shared GUM_HANDS transform/mirroring, formatted resource consistently; final focused suite repeated PASS.
- Blockers: None. Next action: F5 visual playtest of angular hanging poses; native interactive appearance remains unverified.

## Gum hanging arm in-between artwork
- Goal/status: Create additional angular in-between poses; complete as source artwork.
- Completed: Generated8 poses from existing hang/pull references; second imagegen edit removed background/haze. Saved transparent original and documented ordering/prompt/integration limits.
- Decisions:4x2 right-facing sheet, intended10–80deg from up; angles illustrative, not measured. Original/runtime sheets preserved; no gameplay edits.
- Files: images/gum-source/teto_gum_hang_inbetweens.png, specs/character-gum-animations.md, AGENTS.md, WORKLOG.md.
- Verification: Visual review confirms progressive arm directions and complete silhouettes; Pillow confirms1774x887 RGBA, alpha0–255, transparent corner and8 occupied cells. Documentation/scope reviewed; no runtime tests needed for source-only artwork.
- Blockers: None. Next action: Normalize/register256px cells and measure shoulder/hand positions when runtime integration is requested.

## Authored spike placements
- Goal/status: Place readable, avoidable spike strips across the map; complete.
- Completed:20 cells: six64px floor strips across6sections and four64px optional upper strips. Kept spawn/checkpoints/box workspaces/lift start positions clear. Selective Spikes installer preserves other authored map content; generator shares Layout.SPIKES.
- Decisions: Third floor strip moved to64–65 to avoid LightBox spawn. Each floor strip verified with one physical contact kick and swept hazard checks; no movement/physics tuning changes.
- Files: stage_layout.gd, theater_stage.tscn, install_spikes.gd, verify_spike_placements.gd, verify_spikes.gd, specs/spike-tile-assets.md, AGENTS.md, WORKLOG.md.
- Verification: Placement suite PASS20 supported cells/spawn clearance/6actual jump crossings; spike death suite and saved-map suite PASS. Existing full-route suite fails first lift with unchanged original test too: current attachment_range160 differs from240px route design. No full-stage completion claim. Known sandbox CA warning only.
- Refactoring: Reviewed selective authoring and scene-tile fixtures; reset_motion resets controller state between local approaches, avoiding leaked control velocity from previous fixture. Removed temporary probes, retained original full-route test. Final placement/spike/map/checkpoint suites all PASS after refactor; git diff --check PASS.
- Blockers: None for spike placements; existing full-route/tuning mismatch remains separate. Next action: F5 visual/difficulty playtest; native appearance and overall difficulty not verified.

## Checkpoint floor alignment
- Goal/status: Fix checkpoint artwork floating above ground; complete.
- Findings: Atlas opaque base ends at396px in top row,389.5/390.5px in bottom-row local cells; centered sprite at-28 left approx5–6px gap.
- Completed: Align sprite offset per frame to opaque base bottom; fixed default editor offset, tests measure all8 alpha bottoms, specs/durable guidance aligned. No stage/trigger/respawn changes.
- Files: checkpoint.gd/.tscn, verify_checkpoints.gd, specs/checkpoints.md, AGENTS.md, WORKLOG.md.
- Verification: Checkpoint suite PASS: all8 independently measured alpha bottoms within0.15px of floor origin, activation/animation/death respawns/manual reset intact; git diff --check PASS. Known sandbox CA warning only.
- Refactoring: Reviewed sprite-only alignment, centralized frame_changed hook covers activation/playback/restoration/editor; no duplicate offset handling or physics changes.
- Blockers: None. Next action: F5 visual review of grounded sign; native capture not performed.

## Background decoration tile integration
- Goal/status: Integrate16 decorations as paintable background tiles and dress saved stage; complete.
- Completed: Normalized source into384×384 RGBA atlas (16 padded96px stamps), identical runtime copy and dedicated TileSet; BackgroundDecor layer with42 placements across6 sections; shared authoring helper/generator parity and decor-only update tool. Adjusted pendant positions after real render to keep section titles legible.
- Decisions:32px placement grid/3×3-cell stamp artwork, nearest filtering and subdued tint; no TileSet physics layers and disabled layer collision. Existing terrain/checkpoints/food/props preserved; full map generator intentionally not run.
- Files: Atlas pair, background_decor_tileset.tres, background_decor.gd, stage_layout.gd, build_theater_stage.gd, install_background_decor.gd, verify_background_decor.gd, saved stage, specs/restaurant-background-decor.md, AGENTS.md, WORKLOG.md.
- Verification: Final focused suite PASS42 placements/all16 sprites/physics isolation/generator parity; saved-map PASS1212 solid cells/27shapes/76 one-way/59corners. Native Apple M1 OpenGL rendered verification PASS and entrance screenshot visually reviewed after placement refinement. PNG dimensions/alpha/source-runtime byte parity and git diff --check PASS. Known sandbox CA warning; sandbox native renderer aborted, approved native run succeeded.
- Refactoring: Reviewed full touched authoring path; shared creation and atlas-coordinate mapping remove duplication between generator and decor-only update; gameplay code untouched. Relevant verification repeated after final edits.
- Blockers: None. Next action: F5 to play; edit TheaterStage/BackgroundDecor in Godot. Keep Layout.BACKGROUND_DECOR aligned with desired durable placements before regeneration.

## Spike death playback confirmation
- Goal/status: Ensure created effect plays on lethal spike contact; complete.
- Completed: Confirmed both initial overlap and swept movement call Game._die_on_spikes; fixed-step playback finishes before checkpoint restart. Existing implementation already fulfills request, no runtime edits needed.
- Files changed: WORKLOG.md only. Decisions: Retain existing single death owner and0.6s playback.
- Verification: Godot verify_spikes.gd PASS exit0, including real high-speed death, hidden player/gum, single effect, halfway playback, frozen movement, reload and stationary overlap. Known sandbox CA warning only. Reviewed relevant lifecycle and effect implementation; no refactor needed.
- Blockers: None. Next action: F5 playtest spike contact for appearance; native visual QA remains unverified.

## Checkpoint no-rebound integration
- Goal/status: Replace checkpoint playback with original non-bounce8-frame version; complete.
- Completed: Runtime PNG replaced with original4x2 source, sprite scale0.13 preserves approx58px size, final frame derived from sheet dimensions; tests/spec/durable guidance aligned. Respawn/death systems unchanged.
- Files: checkpoint.gd/.tscn, runtime PNG, verify_checkpoints.gd, specs/checkpoints.md, AGENTS.md, WORKLOG.md.
- Decisions: Keep0.055s frame duration, hold frame7 permanently; preserve source artwork variants.
- Verification: Import complete with known sandbox CA/Mono/settings warnings; checkpoint and spike suites PASS, including8-frame progression/permanent final check and both death respawns. Runtime/source PNG byte parity and git diff --check PASS.
- Refactoring: Reviewed touched playback; cached typed sprite and derive final index from actual sheet grid rather than duplicated frame constants. Verification ran after refactor.
- Blockers: None. Next action: F5 interactive appearance review if desired; native visual playback not checked.

## Restaurant background decoration artwork
- Goal/status: Create transparent tile-placement decoration sheet; complete as source artwork.
- Completed: Generated and visually reviewed16 front-view decorations in4x4 layout: plants/lights/windows/paintings,4 each; saved project source and usage specification.
- Decisions: Cream/coral/mint palette, transparent background, separate source atlas; no TileSet/stage/physics edits.32px normalization and engine integration remain outside this image task.
- Files: images/tilesets/restaurant_background_decor_source.png, specs/restaurant-background-decor.md, AGENTS.md, WORKLOG.md.
- Verification: Visual review confirms16 distinct objects and clear separation; Pillow confirms RGBA/transparent corner. No runtime tests apply. Final scope/document review complete.
- Blockers: None. Next action: Normalize/slice and register background decoration tiles if integration is requested.

## Spike disappearance effect
- Goal/status: Create PixelFX disappearance and integrate spike death; complete.
- Completed: Editable original PixelFX effect, transparent atlas/JSON/contact sheet/GIF and runtime copy; fixed-step one-shot death at swept contact center, hidden player/gum, cleared afterimages,0.6s checkpoint respawn. Preserved ongoing checkpoint/background work.
- Decisions: Pink/cream gum-like pop and shrinking radial fragments,128px cells/5x4/19frames/30fps. R remains immediate even during death; falling remains immediate. Death blocks checkpoint activation and player simulation.
- Files: images/effects/player-disappear.mjs, player_disappear PNG/JSON/contact/GIF, runtime PNG, player_disappear_effect.gd, game.gd, verify_spikes.gd, verify_checkpoints.gd, specs/player-disappear-effect.md, spike spec, AGENTS.md, WORKLOG.md.
- Verification: Three visual reviews (dark initial/refined, light final); PixelFX render deterministic/transparent endpoint/unclipped padded bounds PASS; RGBA640x512/runtime byte parity PASS. Final Godot spike/checkpoint suites PASS after refactor; controls PASS; known sandbox CA warning only. Shell node unavailable; exported through connected Node runtime with local PixelFX library.
- Refactoring: Reviewed Game lifecycle, kept restart/checkpoint handoff shared and effect playback small; R input precedes death timer. Updated checkpoint regression for delayed death. git diff --check PASS.
- Blockers: None. Next action: F5 visual playtest on painted spikes; native gameplay appearance not yet checked.

## Checkpoint gameplay integration
- Goal/status: Integrate sign animation and death respawns; complete.
- Completed: Reusable checkpoint scene,12-frame playback,5 safe floor placements and generator parity; Game binds activation and one-shot scene-scoped reload handoff. Death uses last checkpoint; manual restart resets entrance.
- Decisions: Scene reload resets props/food/gum/velocities; active checkpoint restored at final check frame, no repeated animation. No save across app launches. Source sheet retained, runtime copy uses4x3 Sprite2D.
- Files: checkpoint.gd/.tscn, runtime PNG/import, game.gd, stage_layout.gd, saved stage, generator, verify_checkpoints.gd, specs/checkpoints.md, keyboard-controls.md, stage-action-concept.md, AGENTS.md, WORKLOG.md.
- Verification: Import complete (known sandbox CA/Mono/editor-settings warnings). Checkpoint suite PASS including5 floor supports, actual contact,12 frames,pit/spike reloads,latest selection,manual reset,entrance fallback and cleared motion/gum; spikes/controls/map suites PASS. Runtime/source PNG identical; git diff --check PASS.
- Refactoring: Reviewed full restart/ready flow, single idempotent deferred reload, one-shot metadata consumption, fixed-step ownership and scene/generator parity; no duplicate death handler or player-controller changes. Final enhanced checkpoint suite rerun PASS.
- Blockers: None. Next action: F5 interactive review of checkpoint appearance/playback; native visual QA not performed.

## Checkpoint reverse-trapezoid revision
- Goal/status: Apply user perspective correction to bounce sheet; complete as source artwork.
- Completed: Built-in imagegen edited user reference into clean transparent4x3 sheet. Visual review confirms9/11 bottom-wide panels,10 top-wide,12 upright; removed rough white pasted patches and skewed stands.
- Decisions: Preserve original assets; new v2 source only, no runtime integration. Fine frame registration and damping amplitude still need animation-stage tuning.
- Files changed: images/props/restaurant_checkpoint_flip_bounce_v2_source.png, WORKLOG.md.
- Prompt: Preserve first8 poses/design;9 bottom-wide overshoot,10 opposite top-wide rebound,11 smaller bottom-wide correction,12 upright; fixed horizontal axle/support, clean transparent pixel art.
- Verification: Visual review of all12 poses complete; no runtime tests applicable. Blockers: None. Next action: Normalize/playback tune when integration requested.

## Checkpoint rebound perspective analysis
- Goal/status: Analyze user's edited frames9/11; complete, no artwork edits requested.
- Findings: User reference reverses panel trapezoid in9/11 (bottom wider/top narrower), opposite approach-side frames and frame10; alternating perspective communicates crossing the upright rest angle. Uniform vertical compression cannot distinguish tilt sign.
- Decisions: For subsequent art use sequence8 upright,9 forward overshoot,10 opposite rebound,11 smaller forward correction,12 rest. Fix axle/stand registration; transform card/rim/symbol coherently and diminish tilt amplitude. Perspective style is intentional (strict orthographic projection alone has no trapezoid).
- Files changed: WORKLOG.md only. Verification: Visual analysis of attached4x3 sheet; no runtime tests. Blockers: None. Next action: Apply this geometry when artwork revision is requested.

## Checkpoint sign bounce artwork
- Goal/status: Add rotational overshoot and damped return to checkmark flip; complete as source artwork.
- Completed: Built-in imagegen reference edit generated12-frame4x3 transparent source sheet; reviewed front flip and final reverse-face tilt/settling poses.
- Decisions: Horizontal-axis panel flip with forward overshoot, reverse correction and smaller settling motion. Stand stays fixed conceptually; generated source still needs registration/normalization before runtime animation. Original8-frame source preserved.
- Files changed: images/props/restaurant_checkpoint_flip_bounce_source.png, WORKLOG.md.
- Prompt: Preserve original sign;12 chronological poses, horizontal flip followed by205deg overshoot/168deg rebound/185deg correction/180deg rest; stationary support, transparent4x3 grid.
- Verification: Visual review complete; no runtime code/tests applicable. Blockers: None. Next action: Normalize frame registration and tune playback if integration requested.

## Checkpoint sign flip in-betweens
- Goal/status: Create ring-to-check rotation in-betweens; complete as source artwork.
- Completed: Built-in imagegen reference edit produced eight frames in4x2 grid; visually reviewed front compression/edge transition/reverse expansion and stationary stand concept.
- Decisions: Horizontal axle;6 in-betweens plus starting/ending poses. Generated sheet is source art; exact registration/pixel sizing requires normalization before runtime use. No integration requested.
- Files changed: images/props/restaurant_checkpoint_flip_source.png, WORKLOG.md.
- Prompt: Preserve original mint/cream/coral sign, eight horizontal-axis flip angles0/25/50/75/100/125/155/180, ring front/check reverse, transparent4x2 sheet, fixed base, no text.
- Verification: Visual review of all8 poses complete; no code/tests applicable. Blockers: None. Next action: Normalize and preview animation if user requests game integration.

## Checkpoint tabletop sign image trial
- Goal/status: Generate alternative reserved-table sign checkpoint; complete, preview only.
- Completed: Built-in imagegen produced transparent paired inactive gum-ring / active large-checkmark signs. Visual review confirms rounded mint frame, cream card, coral pivot stand, distinct symbols.
- Decisions: User found bell unclear; this alternative prioritizes large readable symbols and a horizontally flipping card. No gameplay integration or animation requested.
- Prompt: matching pixel-art tabletop signs with cream/mint/coral palette, pink gum ring versus bold green check, visible pivot knobs, transparent background, no text/scenery.
- Files changed: WORKLOG.md only. Output: Codex generated_images for this chat, exec-b88f94e8-a832-42a7-80b4-0956fbf1c495.png.
- Verification: Visual review complete; runtime tests not applicable. Blockers: None. Next action: Await design feedback before sprite preparation/integration.

## Checkpoint bell image trial
- Goal/status: Generate selected restaurant bell checkpoint concept; complete, preview only.
- Completed: Built-in imagegen produced transparent side-by-side inactive/activated pixel-art bells; visually checked cream base, mint dome, coral button, pink gum and raised activation flag.
- Decisions: Concept preview only; no runtime integration or final sprite sizing. Prompt: two matching pixel-art tabletop bells, inactive raised button / active depressed button and flag, cream/mint/coral/pink, dark teal outlines, transparent background, no text/scenery.
- Files changed: WORKLOG.md. Preview remains in Codex generated_images for this chat (exec-bc355caa-3aef-4b96-8550-6ad9d670a901.png).
- Verification: Visual concept review complete; no runtime tests applicable. Blockers: None.
- Next action: Refine selected appearance or prepare properly sized game sprites when requested.

## Checkpoint visual concept task
- Goal/status: Suggest checkpoint artwork fitting the restaurant/gum setting; complete (concept only).
- Completed: Reviewed current project context and asset inventory; proposed a mint/coral table-order bell as the leading option, plus reserved-seat sign, cream-soda lamp and receipt stand alternatives.
- Decisions: Concepts are proposals, not an approved design; distinguish inactive/active by silhouette and motion as well as color. No image generation or gameplay changes requested.
- Files changed: WORKLOG.md only.
- Verification: Checked thematic fit against current cream/coral/mint restaurant direction; no runtime tests applicable.
- Blockers: None. Next action: User selects a concept before artwork production/integration.

## Two-frame ladder sprite task
- Goal/status: Create rear-facing alternating climb pixel sprites and integrate; complete.
- Integration confirmation: User requested installation again; verified active Player loads runtime climb SpriteFrames and plays it while gripping. Re-ran verify_ladder.gd: PASS exit0 (both frames/play/pause/no flip plus physical ladder behavior). No further implementation changes needed.
- Completed: Inspected provided pose and current Player animation/ladder verification.
- Decisions: Keep images/teto_climb.png as reference; new two-frame climb animation, pause on hold, fixed rear orientation. Preserve ladder physics.
- Files: images/teto_climb_sheet_source.png, images/normalized/teto_climb.png, runtime PNG/climb_animations.tres, player.gd, verify_ladder.gd, specs/ladders.md, AGENTS.md, WORKLOG.md.
- Completed artwork/integration: Generated rear-view two poses, saved source and nearest normalized512×256 sheet/runtime copy; dedicated climb SpriteFrames6fps, hold pause/no flip. Existing reference untouched; ladder spec/durable guidance updated.
- Tests: Ladder suite PASS including both playing frames, fixed orientation and hold freeze. Normalized visual review/size/binary alpha/runtime parity/reference preservation PASS. Import PASS with known sandbox CA/Mono/settings warnings.
- Refactoring: Shared resource merge loop for gum/climb; reviewed full animation priority and fixed collision geometry; ladder physics untouched. Final ladder rerun and full Player suite PASS exit0; git diff --check PASS. Blockers: None. Next action: F5 playtest dedicated climb animation at first optional ladder; interactive appearance remains unverified.

## Ladder climbing character image task
- Goal/status: Generate Teto climbing pose; complete.
- Completed: Built-in imagegen reference-matched single rear-three-quarter climbing pose; saved images/teto_climb.png, visually reviewed full-body raised-hand/knee silhouette.
- Decisions: Standalone character only, no ladder/gameplay integration; preserve existing work.
- Files: images/teto_climb.png, AGENTS.md, WORKLOG.md.
- Prompt: Reference Teto identity/pixel style, rear three-quarter vertical climb, staggered raised hands/one raised knee, full body, transparent background, no ladder/text/multiple frames. Built-in imagegen used.
- Tests: Pillow size/mode/alpha inspection and visual review complete; no implementation/refactoring needed.
- Blockers: None. Next action: Optional animation normalization/integration when requested.

## Lethal spike gameplay task
- Goal/status: Implement paintable lethal spikes; complete.
- Decisions: Dedicated scene-tile Spikes layer, three blade shapes/base, player-only swept hazard query in Game, shared idempotent deferred restart. Default layer empty to preserve authored route.
- Completed: Reusable three-blade/base scene tile, runtime art/TileSet, saved empty Spikes layer/generator parity, Game swept capsule and common restart; specs aligned.
- Files: Hazard script/scene/TileSet/runtime artwork, Game, saved stage/generator, specs/test planned.
- Tests: Focused real Game spike suite PASS (paint/erase,overlap,fast horizontal/vertical sweep,safe pass,gum exclusion,actual movement death,once-only reload,spawn/gum reset). Import PASS with known sandbox CA/Mono/settings warnings.
- Refactoring: Reviewed full Game update/restart and hazard ownership; shared one restart path, no hazard callbacks or new player state.
- Verification: Final spike suite PASS after refactor; controls PASS; saved-map PASS1212cells/27shapes/76one-way/59corners; git diff --check PASS. Runtime artwork matches source32px asset. Known sandbox CA warning only during tests.
- Blockers: None. Next action: Paint Spikes layer and F5 playtest desired placements; native interactive visual QA remains separate.

## Ladder gameplay task
- Goal/status: Implement reusable climbable ladder and first optional stage placement; complete.
- Completed: Transparent runtime artwork/reusable editor-preview scene, collision-aware Player climbing, tuning120px/s, first optional shelf placement bottom(464,640)/height128, layout/generator parity and current specifications.
- Decisions: Up/Down grips/climbs, neutral holds; sideways/Z/active gum releases. Z is one world-up ladder kick. Grip absorbs momentum, exit retains climb speed; no teleport or solid/gum target. Ignore only one-way bit8 while gripping; restore on endpoint exit/reset/deletion/reel. Regrab requires release of vertical input. Mandatory gum lifts preserved.
- Files: scripts/ladder.gd,player.gd,game_settings.gd,stage_layout.gd; scenes/props/ladder.tscn,stages/theater_stage.tscn; assets/props/restaurant_ladder.png; tools/build_theater_stage.gd,verify_ladder.gd; specs/ladders.md,player-controller.md,keyboard-controls.md,game-settings.md,stage-action-concept.md; AGENTS.md,WORKLOG.md.
- Tests: New real saved-stage ladder suite PASS after final refactoring (climb/hold/top shelf/down/Z/no-regrab/bottom/side/disable/reel/deletion/actual Game X). Full Player, controls, one-way, jump-buffer, food-reel and saved-map suites PASS exit0; PNG copies identical; git diff --check PASS. Known sandbox CA warning; import also known Mono/editor-settings warnings. Native interactive appearance not verified.
- Refactoring: Shared ladder exit/mask restoration, orphan cleanup, guarded drop-through timer, endpoint clamp/exits, normal tree drawing behind Player, editor height preview; diagnostics identify ladder kick. Existing unrelated jump-buffer/artwork changes preserved.
- Blockers: None. Next action: F5 playtest ladder at x464 in first section; tune Ladder/ladder_speed or scene height as desired.

## Ladder image task
- Goal/status: Create ladder image in images; complete.
- Completed: Built-in imagegen generated front-facing mint/cream/coral pixel-style ladder, saved images/restaurant_ladder.png; visually inspected.
- Decisions: Asset only, no gameplay integration; preserve ongoing jump-buffer work.
- Files: images/restaurant_ladder.png, AGENTS.md, WORKLOG.md.
- Tests: Pillow confirms1024×1536 RGBA, transparent corner and inter-rung center (alpha0); visual review confirms isolated ladder. No code/tests needed.
- Prompt: Single orthographic restaurant ladder, mint rails, cream rungs/coral fittings, teal outlines, pixel art, transparent background, no text.
- Review: Final asset/path and scope checked; no code refactoring applicable.
- Blockers: None. Next action: Use as source artwork if ladder gameplay is requested.

## Jump buffering task
- Goal/status: Add missing pre-landing jump buffering; complete.
- Completed: Configurable0.12s floor-only input buffer; one-shot consumption; success/drop/reset/reel clear it. Fresh-only gum/food/wall/ceiling actions preserved. Current specs and durable guidance aligned.
- Files: player.gd, game_settings.gd, verify_jump_buffer.gd, specs/player-controller.md,game-settings.md,keyboard-controls.md,stage-action-concept.md, AGENTS.md, WORKLOG.md.
- Decisions: First supported physics tick executes usual floor kick; no free air jump or held-button repeat. Existing fixed-step ownership retained.
- Tests: New real-physics buffer suite PASS twice (landing/disabled/expiry/no-repeat/reel/reset); controls, one-way, food-reel and full Player regression PASS exit0. git diff --check PASS. Known sandbox CA warning only.
- Refactoring: Reviewed all touched controller/input/reset paths; reuse common kick logic and scalar timer, fresh input kept separate for special actions. Strengthened expiry regression to detect any transient launch.
- Blockers: None.
- Next action: F5 playtest landing input feel; tune Player Movement/jump_buffer_time if desired.

## Shockwave rendering correction
- Goal/status: Compare linked Qiita implementation and fix missing rendered wave; complete.
- Findings: Godot4.5 Polygon2D emits UVs only with a valid texture; textureless quad UV assignment was ignored. Previous headless lifecycle tests missed this.
- Completed: Vertex-position radial coordinates with explicit quad radius; annular mask applies to screen displacement as in reference; retained bright rim. Added geometry/uniform regression.
- Files: gum_hit_shockwave.gdshader, gum_hit_shockwave.gd, verify_gum_hit_shockwave.gd; specs/gum-hit-shockwave.md, AGENTS.md and rendered regression tool.
- Tests: Lifecycle suite PASS. Native OpenGL Compatibility renderer on Apple M1: rendered regression PASS7956 changed pixels; captured checkerboard visually inspected, expanding refracted pink/white ring confirmed. git diff --check PASS.
- Refactoring: Removed ineffective UV array; one radius uniform derives coordinates from actual quad geometry, retaining bounded effect lifecycle. Added standalone real-render regression because headless uses dummy rendering.
- Blockers: None.
- Next action: F5 inspect effect in stage; GPU fixture confirmed rendering, full interactive gameplay appearance remains separate.

## Shockwave visibility task
- Goal/status: Make gum hit shockwave easier to see; complete.
- Completed: Wider refraction band, bright pink/white core, sustained envelope and single alpha mask; retained saved160px/1s/16px/opacity1 tuning. Fixed lifecycle fixture to explicitly set its0.32s duration; docs aligned.
- Files: gum_hit_shockwave.gdshader, verify_gum_hit_shockwave.gd, specs/gum-hit-shockwave.md, specs/game-settings.md, AGENTS.md, WORKLOG.md.
- Decisions: Visual only, keep frozen centers/lifecycle/physics intact; preserve unrelated one-way task edits.
- Tests: Focused Godot lifecycle/arrival suite PASS twice, including after final shader/settings review; git diff --check PASS. Known sandbox CA warning only. Rendered appearance remains unverified.
- Refactoring: Reviewed complete shader masking/envelope and effect lifecycle; retained existing bounded burst ownership and removed duplicate attenuation without extra settings or nodes.
- Blockers: None.
- Next action: F5 inspect the brighter ring against restaurant terrain at gameplay zoom.

## One-way drop-through task
- Goal/status: Down+jump to descend through one-way floors; complete.
- Completed: Player detects one-way-only floor support, suppresses jump, ignores bit8 until capsule clearance58px or0.5s; downward minimum60px/s, coyote consumed, other momentum/food reward preserved. Existing Game jump action detaches gum.
- Files: player.gd, verify_one_way.gd, specs/one-way-platforms.md, specs/keyboard-controls.md, AGENTS.md, WORKLOG.md.
- Decisions: Solid floor retains ordinary kick; no teleport or world/rigid collision changes.
- Tests: Final one-way suite PASS (Down alone, drop, solid floor, restored shelf collision plus existing full suite); controls suite PASS; git diff --check PASS. Full player regression PASS exit0 (jump/coyote/pinning/corners/friction/momentum). Known sandbox CA warning only.
- Blockers: None.
- Refactoring: Shared existing geometric support-face classifier for edge support; reviewed collision-mask lifecycle and no unrelated edits.
- Next action: F5 playtest Down+Z on a one-way shelf (pad Down+Cross).

## Item pickup PixelFX task
- Goal/status: Create and integrate restaurant-colored pickup particles; complete.
- Completed: PixelFX collect-burst wrapper with cream/coral/mint palette and2× timing; exported transparent22-frame sheet/runtime copy/JSON/contact preview. collect() spawns once for both contact and completed reel at actual collection position; frozen world-space residue survives food deletion, expires0.7s, stage deletion clears.
- Decisions: Presentation only; no gameplay/tuning changes. Existing unrelated changes preserved. Nearest112×108 cells,5×5 atlas,30fps,Z7; image center56/54 is actual burst center, PixelFX anchor56/84.
- Files: images/effects/food-collect.mjs,food_collect.png/json,food_collect_preview.png; runtime PNG; food_collect_effect.gd(+UID),food_collectible.gd; verify_food_collect_effect.gd(+UID),verify_food_collectibles.gd,verify_food_reel.gd; specs/food-collect-effect.md,food-item-assets.md; AGENTS.md,WORKLOG.md.
- Tests: Four visual contact-sheet inspections including stock reference and final light/dark backgrounds. Godot effect/contact/reel suites PASS exit0 after final refactoring; image size/RGBA/identical copies/transparent terminal frame PASS. Godot import complete; known sandbox CA/Mono/editor-settings warnings only. git diff --check PASS.
- Refactoring: Reviewed lifecycle and shared collection path; host skips TileMapLayer only, retaining ordinary scene ownership. Common successful collection owns emission, one-shot guard prevents duplicate particles.
- Blockers: None; interactive in-game appearance remains unverified.
- Next action: F5 inspect contact pickup and gum hand collection effects in gameplay.

## Food hit area task
- Goal/status: Make food hit areas slightly larger than64px artwork; complete.
- Completed: All11 centered circular Areas enlarged to radius36px/diameter72px, shared by contact pickup and gum rays; layout/artwork unchanged. Specs and AGENTS aligned.
- Decisions: Reuse existing CircleShape2D, no runtime scaling or changes to physics layers.
- Files: scenes/items/foods/*.tscn, specs/food-item-assets.md, AGENTS.md, WORKLOG.md.
- Tests: verify_food_collectibles.gd and verify_food_reel.gd PASS exit0 after final review; all11 radius36 scenes confirmed; git diff --check PASS. Known sandbox CA warning only.
- Refactoring: Reviewed all scene shapes and shared consumers; no duplicated runtime logic required.
- Blockers: None.
- Next action: F5 playtest pickup/gum targeting feel around enlarged food edges.

## Food display size task
- Goal/status: Double all food visuals around placement center; complete.
- Completed: All11 Sprite2D scenes use native64px size centered on unchanged32px cell; pickup radius14px and layout unchanged. Specification and durable guidance aligned.
- Decisions: Scale artwork only; preserve ongoing food reel work and other unrelated changes.
- Files: scenes/items/foods/*.tscn, specs/food-item-assets.md, AGENTS.md, WORKLOG.md.
- Tests: Existing verify_food_collectibles.gd PASS (all11 pickups, saved36 placements, reload); all11 scene transforms/14px radii checked; git diff --check PASS. Known sandbox CA warning only.
- Refactoring: Reviewed all11 scenes; default Sprite2D scale/centering avoids redundant overrides or runtime scaling logic.
- Blockers: None.
- Next action: F5 inspect enlarged food artwork in stage.

## Food gum reel task
- Goal/status: Gum-hit food reels to hand, player motion/gravity lock, then one available air jump; complete.
- Completed: Food Area bit32/ray mask53 with area hits; REELING lifecycle, hand-directed pull600px/s Inspector setting, velocity reset/position lock through arrival/completion ticks, single consumed world-up Z kick after successful collection. Existing contact pickup preserved.
- Decisions: Z/X ignored during reel, no autojump/buffering/stacking; target loss grants no reward; restart reconstructs state. Terrain/rigid spring unchanged. Preserved concurrent food artwork enlargement and other unrelated work.
- Files: food scenes, food_collectible.gd, gum_connection.gd, player.gd, game.gd, game_settings.gd; verify_food_reel.gd(+UID), verify_gum.gd; food-gum-reel.md, food-item-assets.md, game-settings.md, keyboard-controls.md, player-controller.md, gum-flight-return.md; AGENTS.md, WORKLOG.md.
- Tests: Focused live Game PASS actual swept Area hit/wall occlusion, zero momentum/input/gravity/motion, hand collection, ground+air jump/no-repeat, deletion/restart cleanup. Controls, full Player, contact-food suites PASS. Gum suite PASS after isolating new Foods targets from terrain-only shelf fixture. git diff --check PASS. Known sandbox CA/Mono/editor settings warnings.
- Refactoring: Reviewed complete target/state/input/player integration, shared collect/reset_motion paths and explicit REELING state; separated food jump from attached jump for correct diagnostics, retained common world-up kick/consumption rules. Final focused suite PASS after review with grounded case added.
- Blockers: None; interactive appearance/feel unverified.
- Next action: F5 aim X at food, confirm freeze/pull then fresh Z jump; tune Food Collection/food_reel_speed if desired.

## Gum hit shockwave task
- Goal/status: Add an expanding shader shockwave at gum impact; complete.
- Completed: Local screen-refraction shader with soft pink annulus, eased56px expansion/0.32s duration, actual adhesion signal, frozen world-space centers, four-burst cap, independent materials, disable/zero-duration/restart cleanup and shared Inspector tuning.
- Decisions: Full circle for both terrain and rings, Z4 below gum/hit particles/patch; no physics/timing changes. Existing unrelated edits preserved. Shared screen snapshot means overlapping waves do not recursively refract each other.
- Files: scripts/gum_hit_shockwave.gd(+UID), shaders/gum_hit_shockwave.gdshader, scripts/game.gd, scripts/game_settings.gd, scenes/game.tscn, tools/verify_gum_hit_shockwave.gd(+UID), specs/gum-hit-shockwave.md, specs/game-settings.md, AGENTS.md, WORKLOG.md.
- Tests: Focused real-arrival/force-free/center/frozen residue/material progress/expiry/cap/disable/cleanup PASS, repeated after final review. verify_gum.gd and verify_controls.gd PASS exit0. git diff --check PASS. Known sandbox CA warning only.
- Refactoring: Reviewed complete effect lifecycle/shader/settings integration; shared removal path handles expiry/cap/stop, bounded independent quads and no physics coupling.
- Blockers: None; rendered refraction appearance not visually verified in headless tests.
- Next action: F5 inspect hit wave against frames/terrain; tune Gum Hit Shockwave in resources/game_settings.tres as desired.

## Food layout task
- Goal/status: Place foods meaningfully across all six map sections; complete.
- Completed: Authored36 cells (six per section), lower-route guidance, lift/step landings and optional high-shelf rewards; all11 dishes used. Saved only Foods tile data; generator reproduces layout.
- Decisions: Terrain/tuning unchanged; stage_layout.FOODS owns placement. Preserved unrelated afterimage/settings work.
- Files: stage_layout.gd, build_theater_stage.gd, theater_stage.tscn, verify_food_collectibles.gd, food-item-assets.md, AGENTS.md, WORKLOG.md.
- Tests: Focused collectible PASS36 saved instances/layout parity/all11 dishes/six per section/no terrain overlap/support below, all11 actual contact pickup/props excluded/single notification/reload36. Saved map collision PASS1212cells/27shapes/76one-way/59corners; git diff --check PASS. Known sandbox CA warning only.
- Refactoring: Reviewed placement ownership, removed stale empty-layer docs, kept shared existing scene-tile pickup implementation and generator source. No physics or gameplay changes needed. Final focused suite rerun PASS.
- Blockers: None; interactive visual/route feel remains unverified.
- Next action: F5 playtest food guidance and optional upper-shelf pickups; edit FOODS and saved layer together for future changes.

## Afterimage draw priority
- Goal/status: Ensure snapshots render behind Player; complete.
- Completed: Replaced tree-only show_behind_parent flags with explicit absolute Z one below source effective Z; top-level frozen transforms retained. Added draw-order regression assertion.
- Files: player_afterimages.gd, player.gd, verify_player_afterimages.gd, docs and AGENTS.
- Decisions: Top-level CanvasItems require explicit Z ordering; preserve existing effects and unrelated work.
- Tests: Focused afterimage suite PASS after final review; diff check PASS. Fixture now sets threshold/lifetime/interval explicitly to isolate saved user tuning; saved Resource untouched. Known sandbox CA warning only.
- Blockers: None.
- Next action: F5 inspect behind-player afterimages.

## Food collectible task
- Goal/status: All11 food sprites paintable as collectible scene tiles; complete.
- Completed: Dedicated Food TileSet/scenes, nearest32px display/14px trigger, player-only Area2D with one-shot collected(food_id), empty Foods layer in saved map and generator. Editor workflow documented.
- Decisions: No default placements, score/healing or physics changes. Existing WORKLOG edits and pixelfx preserved; saved map not regenerated.
- Files: assets/foods, scenes/items/foods, food_collectible.gd(+UID), verify_food_collectibles.gd(+UID), player.tscn, theater_stage.tscn, build_theater_stage.gd, food-item-assets.md, AGENTS.md, WORKLOG.md.
- Verification: Godot import succeeds (known sandbox CA/Mono/editor-settings warnings). Focused test PASS all11 actual scene tile instantiation/contact pickup/box exclusion/single signal/reload. Saved map check PASS1212cells/27shapes/76one-way/59corners. git diff --check PASS.
- Refactoring: Reviewed shared script ownership, one-shot guard, independent Food TileSet and generator integration; all scenes share one pickup implementation. Focused suite rerun after review.
- Blockers: None; interactive editor appearance not verified.
- Next action: Open theater_stage.tscn, select Foods, paint desired food scene tiles and F5 playtest.

## Speed afterimage task
- Goal/status: Speed-triggered character afterimages complete.
- Completed: Frozen world-space current-frame/flip/deformation snapshots, quadratic pink fade,8-image cap, fixed-step actual displacement gating and shared Player Afterimages tuning. Defaults350px/s,0.04s interval,0.20s lifetime,alpha0.32. Normal run remains220px/s.
- Decisions: Child-owned lifecycle clears on restart; disable/lifetime0 clears; slowing stops emission while residue expires. No physics changes. Existing uncommitted work preserved.
- Files: scripts/player_afterimages.gd(+UID), player.gd, game_settings.gd; tools/verify_player_afterimages.gd(+UID); specs/player-controller.md,game-settings.md; AGENTS.md; WORKLOG.md.
- Verification: Focused afterimage PASS including real vertical Player motion, speed/custom threshold, frozen pose/world transform, fade/expiry/cap/disable; deformation suite PASS. Editor import succeeds with known sandbox CA/Mono/settings warnings. Full verify_player.gd PASS exit0 (corner/support, movement, jumps, friction/momentum); git diff --check PASS.
- Refactoring: Reviewed ownership/render order/settings; reused movement's existing before_position snapshot, isolated bounded snapshot lifecycle. Focused suite rerun PASS after review.
- Blockers: None; interactive appearance unverified.
- Next action: F5 inspect and tune shared Player Afterimages settings as desired.

## Completed squash/stretch settings
- Goal/status: Expose visual deformation in shared game_settings; complete.
- Completed: Player Squash and Stretch group with jump/landing Vector2 multipliers and duration; removed Player constants, updated callers/specs/AGENTS/custom-value fixture. Existing tuning preserved.
- Decisions: Same defaults; duration0 disables effect safely; saved Resource inherits schema defaults.
- Files: game_settings.gd, player.gd, verify_player_deformation.gd, player-controller.md, game-settings.md, AGENTS.md, WORKLOG.md.
- Tests: verify_player_deformation.gd PASS with custom multipliers/durations, actual jump/landing, zero-duration disable and unchanged collision geometry; verify_landing_dust.gd PASS exit0; git diff --check PASS. Known sandbox CA warning only.
- Refactoring: Reviewed all deformation callers and schema; removed superseded constants/references, retained shared recovery path and inherited Resource defaults.
- Blockers: None.
- Next action: Adjust resources/game_settings.tres → Player Squash and Stretch in Inspector as desired.

## Completed jump/landing squash and stretch
- Goal/status: Add visual-only upward jump stretch and landing squash; complete.
- Completed: Sprite-only feet-pivot deformation; accepted upward launches0.88/1.16 for0.18s, qualified landing1.18/0.84 for0.16s; quadratic recovery. Physics/body/capsule unchanged; rejected kicks/spawn/contact flicker do not trigger.
- Decisions: Reuse qualified landing event and fixed-step animation owner. New events replace active deformation. Existing uncommitted particle/tuning work preserved.
- Files changed: scripts/player.gd; tools/verify_player_deformation.gd; specs/player-controller.md; AGENTS.md; WORKLOG.md.
- Verification: Focused actual jump/landing fixture PASS, including rejected input, feet pivot, collision invariance and exact recovery; repeated after final refactoring review PASS. Full verify_player.gd and verify_landing_dust.gd PASS exit0; git diff --check PASS. Known sandbox CA warning only. Interactive appearance unverified.
- Refactoring: Reviewed touched jump/landing/animation flow; one shared deformation/recovery path, constants for tuning, no signal duplication or physics coupling.
- Blockers: None.
- Next action: F5 inspect squash/stretch strength at gameplay scale; tune constants if desired.

## Completed gum hit particle implementation
- Goal/status: Implement approved expanding hit particle ring; complete.
- Completed: GumHitParticles draw-only Node2D via adhesion_started,12 pale-pink particles/outward surface hemispheres/full ring circles, eased expansion to~20px,0.26s lifetime, frozen world-space residue,4burst/64particle cap; optional short arcs defaultOFF. Shared settings, Game binding/restart cleanup, specs and AGENTS aligned.
- Files: scripts/gum_hit_particles.gd (+UID), scripts/game.gd, scripts/game_settings.gd, scenes/game.tscn, tools/verify_gum_hit_particles.gd (+UID), tools/verify_gum_shot_particles.gd, specs/gum-hit-particles.md, specs/game-settings.md, AGENTS.md, WORKLOG.md.
- Decisions: Existing patch remains on top; no physics/timing changes. Existing saved tuning and untracked pixelfx preserved. Shot fixture expiry now follows configured lifetime; prior0.5s hardcoded expectation failed with saved lifetime0.5 (up to0.65s randomized).
- Verification: Focused hit PASS actual adhesion/force-free arrival/no repeated emission, all surface directions, real centered ring/full circle, expansion/expiry, movement independence/detach/deletion residue, caps/disable/cleanup, draw order and miss. Existing gum/controls/adhesion/shot suites PASS exit0. Final hit/shot reruns PASS. Editor import succeeds with known sandbox CA/Mono/settings warnings. git diff --check PASS. Interactive rendered appearance unverified.
- Refactoring: Reviewed full touched effect/settings/lifecycle; shared particle rendering for core/halo, isolated arc drawing, explicit max-per-burst constant and idle redraw guards. No new generic particle framework needed for distinct burst/trail timing.
- Blockers: None.
- Next action: F5 inspect default particle-only hit ring; tune Gum Hit Particles or enable short arcs if desired.

## Completed gum hit particle proposal
- Goal/status: Consider hit particles and expanding-circle direction; proposal complete, runtime unchanged.
- Completed: specs/gum-hit-particles.md compares burst/solid ring/particle ring; recommends sparse expanding particle ring with optional faint short arcs. Includes timing, surface hemisphere vs ring360, residual lifecycle and acceptance criteria.
- Decisions: Proposal only:10–14particles, radius3–5 to16–22px,0.26s expiry; existing adhesion patch remains central. World-space residue, no force/damage/hit-stop. No new verified implementation conventions for AGENTS.
- Files changed: specs/gum-hit-particles.md; WORKLOG.md.
- Verification: Reviewed against existing adhesion signal,0.30s following patch and shot residue lifecycle. Documentation-only; git diff --check PASS.
- Blockers: None.
- Next action: If requested, implement particle ring first and compare optional short arcs at actual gameplay scale.

## Completed gum shot particle implementation
- Goal/status: Implement approved luminous shot trail; complete.
- Completed: Actual swept-tip segment signals, world-space distance-sampled pale-pink dots/rose accents/additive halos, damped drift and shrink/fade; residual lifetime after attach/miss/detach/refire, immediate restart cleanup,64-particle cap and shared Inspector settings.
- Decisions: Procedural Node2D drawing; no raster assets. Physics and adhesion timing unchanged. Existing untracked pixelfx directory preserved.
- Files: gum_shot_particles.gd (+UID), gum_connection.gd, game.gd, game_settings.gd, game.tscn, verify_gum_shot_particles.gd, specs/gum-shot-particles.md, specs/game-settings.md, AGENTS.md, WORKLOG.md.
- Verification: Focused particle fixture PASS real arrival/miss/cancel, force-free arrival, residue/world coordinates, all8directions and partition-independent spacing, expiry/cap/disable/cleanup. Existing gum/controls/adhesion suites PASS exit0. Editor import succeeds with known sandbox CA/Mono/settings warnings. git diff --check PASS. Interactive rendered appearance not verified.
- Refactoring: Reviewed full signal/effect/settings ownership; reused appearance calculation for dots/halos and exact exponential drag integration; avoided idle disabled redraws. Focused verification rerun after final review.
- Blockers: None.
- Next action: F5 inspect shot trail; tune Gum Shot Particles spacing/lifetime/spread/opacity if desired.

## Completed gum shot particle proposal
- Goal/status: Consider appearance and behavior of small luminous particles around fired gum; proposal complete, runtime unchanged.
- Completed: Added specs/gum-shot-particles.md with pale pink microdots, distance-based actual-tip trail, damped outward drift, short lifetime, state lifecycle and verification criteria.
- Decisions: Preserve uniform luminous gum and existing adhesion VFX; initial proposal8–12px spacing,0.12–0.22s lifetime,64-particle cap. Current effective shot baseline verified1200px/s and160px range (~0.13s).
- Files changed: specs/gum-shot-particles.md; WORKLOG.md.
- Verification: Reviewed proposal against outbound sweep, state transitions and existing adhesion effect; documentation-only, no runtime tests. No new durable implementation fact requiring AGENTS update.
- Blockers: None.
- Next action: Implement and visually tune the proposal when requested.

## Completed emission settings confirmation
- Goal/status: Confirm saved game_settings tuning; complete.
- Completed: Preserved saved Resource values glow radius18, opacity0.18, core brightness0.12; matched script defaults/specs/AGENTS. Other settings untouched.
- Files: game_settings.gd, specs/game-settings.md, AGENTS.md, WORKLOG.md; existing game_settings.tres tuning preserved.
- Decisions: Current saved Inspector values are authoritative.
- Tests: Godot effective saved/default comparison PASS (57 properties); verify_aim_tile PASS; git diff --check PASS. Temporary comparison script removed. Final refactoring reviewed tuning references; no runtime structure change needed. Known sandbox CA warning only.
- Blockers: None.
- Next action: Continue with confirmed emission baseline18/0.18/0.12.

## Completed uniform gum width
- Goal/status: Remove distance-based widening; complete.
- Completed: Removed taper setting/custom polygon geometry; shared antialiased polyline draws uniform-width halo/base/core. Emission colors and tension width retained; specs/AGENTS aligned.
- Files: gum_connection.gd, game_settings.gd, specs/game-settings.md, AGENTS.md, WORKLOG.md.
- Decisions: User prefers uniform width along path.
- Tests: verify_aim_tile PASS; git diff --check PASS. Final refactoring replaced custom ribbon tessellation with shared native antialiased polyline and removed unused tuning. Known sandbox CA warning only.
- Blockers: None.
- Next action: F5 inspect uniform-width luminous gum.

## Completed reference gum appearance
- Goal/status: Match supplied pale-pink tapered luminous gum reference; complete.
- Completed: Tapered path-following ribbon (hand1×/target2.5×), wider pale core, pink tension palette,24-layer Gaussian additive halo. Loosen gray preserved.
- Files: gum_connection.gd, game_settings.gd, WORKLOG.md, specs/game-settings.md, AGENTS.md.
- Decisions: Keep physical path/sag/wrapping; width taper is visual only, no cone-shaped collision or physics.
- Tests: verify_gum PASS; verify_aim_tile PASS; git diff --check PASS. Known sandbox CA warning only. Final refactoring reviewed shared ribbon geometry/colors and cumulative path taper; no physics changes. Interactive rendered appearance unverified.
- Blockers: None.
- Next action: F5 visually compare pale-pink tapered glow against reference; tune Gum Appearance if needed.

## Completed settings baseline confirmation
- Goal/status: Confirm effective current game_settings values; complete; defaults/docs aligned.
- Completed: Preserved saved Resource; aligned minimum_length4, attachment_range160, pinning/gum diagnostics false in script defaults and settings specification. Existing bloom edits preserved.
- Files: scripts/game_settings.gd, tools/verify_gum.gd, specs/game-settings.md, AGENTS.md, WORKLOG.md.
- Decisions: Current saved overrides are authoritative; all other effective values unchanged.
- Tests: verify_aim_tile PASS; verify_gum PASS exit0; git diff --check PASS. Flight fixture explicitly sets240px range for its200px target (saved gameplay range remains160). Final refactoring review confirmed only four defaults changed and no runtime tuning drift.
- Blockers: None.
- Next action: Use current settings as the confirmed baseline; interactive feel review remains optional.

## Completed gum bloom enhancement
- Goal/status: Strengthen gum emission; complete.
- Completed: Separate behind-parent additive CanvasItem with12 quadratic halo layers; shared path/color/markers; radius16px/opacity0.6 defaults. READY preview excluded; renderer/physics unchanged.
- Files: gum_connection.gd, game_settings.gd, specs/game-settings.md, AGENTS.md, WORKLOG.md.
- Decisions: Local bloom approximation supports Compatibility and preserves loosen color.
- Verification: verify_aim_tile PASS; verify_gum exit1 with9 flight/arrival/contraction assertions, identical failures confirmed with HEAD gum script (saved range160 vs fixture200). Known sandbox CA warning. Final refactoring reviewed shared color/geometry and draw lifecycle; git diff --check PASS.
- Blockers: None for implementation; interactive rendered appearance unverified.
- Next action: F5 inspect gum emission; tune Gum Appearance radius/opacity if desired. Existing gum fixture range mismatch remains outside this rendering change.

## Completed valid aim brightness
- Goal/status: Brighten firing preview on attachable hit; complete.
- Completed: Valid line/reticle use configured color alpha directly (default0.9); unavailable keeps aim_guide_opacity multiplier (default resulting0.27). Input-independent; tile blink unchanged. Aligned Inspector comment, specs and AGENTS.
- Files: gum_connection.gd, game_settings.gd, specs/keyboard-controls.md, specs/game-settings.md, AGENTS.md, WORKLOG.md.
- Verification: Final refactoring review kept shared line/reticle color with single conditional alpha; focused verify_aim_tile.gd PASS, git diff --check PASS. Known sandbox CA warning only. Visual appearance not checked interactively.
- Blockers: None.
- Next action: F5 inspect brighter valid-target prediction.

## Completed aim tile highlight
- Goal/status: Blink the tile hit by firing prediction; complete.
- Completed: READY-only 3Hz translucent fill/outline using prediction valid/invalid colors; merged terrain inward cell lookup, ring RID cell, target-change phase reset and miss/flight/attachment/return hiding. No physics changes.
- Files: gum_connection.gd, tools/verify_aim_tile.gd, specs/keyboard-controls.md, AGENTS.md, WORKLOG.md. Existing landing dust/stage edits preserved.
- Verification: Focused real-ray fixture PASS terrain cell/ring cell/phase switch/miss/outbound; existing verify_gum_anchors PASS. Final refactor reviewed cell resolution/drawing, named blink frequency and aligned colors; focused fixture rerun PASS; git diff --check PASS. Known sandbox CA warning only.
- Blockers: None. Interactive appearance not checked.
- Next action: F5 inspect prediction blink at terrain and rings.

## Completed landing dust integration
- Goal/status: Integrate normal/heavy landing dust; complete.
- Completed: Player.landed after real airborne floor transition; Game binding/restart cleanup; reusable nearest Sprite2D with rigid point/normal following; runtime PNG copies; shared Landing Dust speed settings; focused fixture/specs/AGENTS updated.
- Decisions: Suppress first spawn settling, <0.05s/<2px airborne flicker and compression recovery; select80/450px/s relative normal impact; capture pre-contact velocity, emit before rigid impulses. No physics changes. Unrelated stage edits preserved.
- Files: player.gd/game.gd/game_settings.gd, landing_dust_effect.gd/tscn, game.tscn, assets/effects/landing_dust_*, tools/verify_landing_dust.gd, specs/landing-dust-effect.md/game-settings.md, AGENTS.md, WORKLOG.md.
- Verification: Focused final refactor fixture PASS real normal/heavy/horizontal-speed/rotated-rigid landing, spawn/flicker/compression suppression,30fps/expiry, rigid follow/deletion and cleanup. Controls/compression PASS exit0. Player regression PASS exit0 including both high-speed corners and full movement checks. Import successful; known sandbox CA/Mono/editor-settings warnings. git diff --check PASS.
- Refactoring: Reviewed touched areas; named airborne eligibility constants, shared both variants in one node, explicit following flag handles freed rigid bodies, thresholds use shared tuning resource. Final focused fixture rerun after review.
- Blockers: None. Interactive gameplay appearance not checked.
- Next action: F5 inspect landing dust at normal/strong falls and box landings; tune shared Landing Dust impact thresholds if needed.

## Completed landing dust assets
- Goal/status: Create PixelFX landing dust under images/; complete.
- Completed: Normal/heavy warm-gray dust PNG atlases, JSON, contact sheets, GIF previews and shared editable source. Two visual review rounds refined lobes and dissipation. Existing PixelFX license/notices apply.
- Decisions:64×32px cells,192×128 atlas,3columns,10frames (9visible+transparent endpoint),30fps,0.30s,pivot32/26. JSON endpoint0ms; previews add end pause. No game integration.
- Files: images/effects/landing-dust.mjs and landing_dust_*; specs/landing-dust-effect.md; AGENTS.md; WORKLOG.md. Unrelated theater_stage.tscn edits preserved.
- Verification: Both variants ×4seeds PASS deterministic replay/expanded-canvas bounds/empty ending. Pillow PASS RGBA dimensions,9visible frames and transparent end. Both final contact sheets visually reviewed. git diff --check PASS.
- Refactoring: Reviewed full authoring source, kept shared field/shading and options for both variants, removed temporary review module; final exports/verification use refined source.
- Blockers: None for assets; actual game-scale appearance remains unverified.
- Next action: Integrate assets using proposed landing event/relative impact filtering when requested.

## Completed firing-range tuning confirmation
- Goal/status: Confirm current saved game_settings tuning; complete.
- Completed: Reviewed sole pending settings change: attachment_range=160px; maximum_length remains400px. Existing minimum_length=4 and disabled pinning/gum diagnostics are unchanged.
- Files changed: gd-bungee-gum/resources/game_settings.tres; WORKLOG.md.
- Verification: Focused git diff --check PASS; configuration-only change, no code/refactoring needed.
- Blockers: None.
- Next action: Play F5 to assess160px firing range; unrelated working changes retained.

## Completed landing dust proposal
- Goal/status: Consider PixelFX workflow for character landing dust; proposal complete, asset/runtime implementation not requested.
- Completed: Inspected local heavy-landing effect, authoring/export tools and current Player landing transition. Wrote specs/landing-dust-effect.md with palette, timing, two strengths, export workflow, event/relative-impact design and acceptance checks.
- Decisions: Short warm-gray non-glowing dust,64×32 proposed canvas,0.30s/30fps; exclude cracks/debris/hitstop. Thresholds and sizes are provisional; use pre-contact velocity relative to supporting surface, not total speed.
- Files changed: specs/landing-dust-effect.md; AGENTS.md; WORKLOG.md.
- Verification: Proposal checked against local PixelFX and Player code; final design review separated existing behavior from proposed event/filtering. git diff --check PASS. No runtime tests needed for proposal only.
- Blockers: None. Appearance/export remain unverified until authoring.
- Next action: Author normal/heavy variants, render/contact-sheet review on stage backgrounds, then integrate approved assets.

## Completed Godot gum adhesion effect integration
- Goal/status: Integrate authored adhesion VFX into Godot; complete.
- Completed: Runtime copies of surface/ring atlases and license notices; reusable nearest-filtered Sprite2D scene/script; Gum adhesion_started/adhesion_ended signals; Game binding. Effect follows live endpoint/rotating surface tangent; ring stays centered.9visible frames at30fps, hides at0.30s/release/restart/invalid target. Physics ownership/timing untouched.
- Files: scripts/gum_connection.gd, game.gd, gum_attachment_effect.gd; scenes/game.tscn, effects/gum_attachment_effect.tscn; assets/effects/*; tools/verify_gum_attachment_effect.gd; specs/gum-attachment-effect.md; AGENTS.md; WORKLOG.md.
- Verification: Final focused real-Game fixture PASS (actual outbound arrival, force-free tick, rigid translation/rotation, all four normals,30fps/expiry, no contract retrigger, detach/restart, miss, centered ring/erased target). Existing gum/controls/anchor suites all PASS exit0. git diff --check PASS. Source/runtime atlas bytes identical. Godot import succeeded; known sandbox CA/editor-settings/Mono socket warnings unrelated.
- Refactoring: Reviewed touched signal/state boundaries and sprite lifecycle; shared surface/ring presentation in one reusable node, no duplicated animations or per-attachment allocations. Final focused fixture rerun after review and additional orientation/restart coverage.
- Blockers: None. Interactive gameplay visual feel not yet reviewed.
- Next action: F5 and attach to terrain, rotating boxes and rings to assess visual size/readability in gameplay.

## Completed gum adhesion effect assets
- Goal/status: Create pixelfx adhesion effects and save under images/; complete.
- Completed: Original pink squash/stretch/recoil surface and radial ring variants; three render/review iterations; exported PNG atlases, JSON, GIF previews/contact sheets and editable procedural source under images/effects/. Included pixelfx license/notices; updated asset specification and AGENTS.
- Decisions:64×64 frames,256×192 atlases,4columns,10frames including empty endpoint,30fps,pivot32/32. No Godot integration. Surface normal-X. Exact0.30s playback uses9 visible samples plus zero-hold empty endpoint.
- Files changed: images/effects/*; local pixelfx/src/fx/impacts/gum-attach.js; specs/gum-attachment-effect.md; AGENTS.md; WORKLOG.md.
- Verification: pixelfx check PASS0fail (procedural speed warning21.3ms/frame in tool runtime); Pillow checked both RGBA atlas sizes, metadata/frame count and all visible/empty frames. Three rounds visually inspected on dark/light backgrounds. Refactoring consolidated field/capsule drawing for shared variants. Shell node unavailable; bundled Node REPL imported pixelfx tooling directly.
- Blockers: None for baked assets. Gameplay appearance remains unverified until integration.
- Next action: Integrate selected sheets into Godot presentation event when requested.

## Completed gum attachment effect proposal
- Goal/status: Consider pixelfx workflow for gum adhesion VFX; proposal complete, implementation not requested.
- Completed: Inspected local pixelfx README/authoring/export code and blunt-hit/slime references; inspected Gum attachment/arrival/center resolution. Wrote specs/gum-attachment-effect.md with timing, palette, authoring/export workflow, Godot event/follow/lifecycle design and acceptance checks.
- Decisions: Dedicated0.30s squash/thread/recoil effect; surface-normal variant plus centered radial ring variant; presentation only, preserve arrival force timing. Aseprite JSON needs conversion/importer for Godot.
- Files changed: specs/gum-attachment-effect.md; WORKLOG.md. No runtime or pixelfx source edits.
- Verification: Proposal cross-checked against local source; no runtime tests applicable. Final review kept proposed values distinct from implemented behavior.
- Blockers: None; visual quality and export output remain unverified until authoring.
- Next action: Author and render three candidate gum-attach effects, review at gameplay scale, then integrate selected sprite sheet.

## Completed pixelfx checkout
- Goal/status: Checkout https://github.com/patch-gg/pixelfx into repository-root pixelfx/; complete.
- Completed: Cloned upstream default branch as an independent nested Git repository. No game integration or dependency installation requested.
- Files changed: pixelfx/ checkout; WORKLOG.md.
- Verification: Clone exited0; origin URL and clean branch status verified. Reviewed scope; no source refactoring applicable.
- Blockers: None. Initial sandbox DNS restriction resolved with authorized network escalation.
- Next action: Use pixelfx/ for subsequent requested work.

## Completed attached release jump
- Goal/status: Implement attached Z/Cross release jump; complete.
- Decision: Snapshot validated attachment before detach; attached jump always world-up, cancel all downward external velocity, retain upward/horizontal momentum and add kick_speed. Unattached contact/coyote rules stay unchanged.
- Completed: Implemented Game attachment snapshot and Player release-jump branch; six live physical-Z cases cover descend/still/ascend × contract/loosen, consumed kick/coyote, horizontal retention and hold/repress rejection. Pad Cross checks upward jump. Aligned control/player/genre/stage/flight/architecture specs and AGENTS. Existing edits preserved.
- Files: game.gd, player.gd, verify_controls.gd; keyboard-controls/player-controller/game-direction/stage-action-concept/bungee-gum-prototype/godot-implementation-plan/gum-flight-return specs; AGENTS.md, WORKLOG.md.
- Verification: Final controls/player/gum suites all PASS exit0; logs have no script/assertion errors, only known macOS CA warning. git diff --check PASS. Refactoring reviewed fixed-step ownership, release priority and jump consumption, consolidated compensation application and aligned affected specs. Physical keyboard synthetic inputs and pad Cross covered; interactive feel unverified.
- Blockers: None.
- Next action: F5 playtest attached Z/Cross while descending and ascending; kick_speed controls added jump velocity.

## Completed centered ring adhesion
- Goal/status: Ring attachment always resolves to tile center; complete.
- Completed: Shared endpoint resolver feeds maximum-length validity, aim reticle and attachment. Ring tip/local endpoint/path/natural length/immediate display all use center; terrain/rigid bodies retain actual hit position. Saved GumAnchors/generator/fixture use physics_quadrant_size1 so RID identifies exact cell even with inflated off-cell hits.
- Files changed: gum_connection.gd; saved theater_stage.tscn; build_theater_stage.gd; verify_gum_anchors.gd; specs/gum-anchor-tile.md and gum-flight-return.md; AGENTS.md; WORKLOG.md.
- Findings: Godot4.5 default physics quadrant16 groups RIDs; get_coords_for_body_rid returns quadrant coordinates. Per-cell bodies are necessary for correct ring identity. Verified experimentally before fixing configuration.
- Verification: Final anchor fixture PASS:12 saved centers, four off-center/diagonal hits, aim/display/path/natural length, real moving-tip arrival, transformed second-cell identity/local following, center-based maximum rejection, erase/disable lifecycle and pass-through. Gum/controls/map/stage_route suites PASS exit0; logs inspected without script/assertion errors. git diff --check PASS. Known macOS CA warning only.
- Refactoring: Centralized endpoint selection, expanded aim branch for clarity, reviewed all hit.position uses for flight/diagnostic versus attachment intent; final anchor suite rerun after cleanup/assertion additions.
- Blockers: None. Interactive feel unverified.
- Next action: F5 hit ring rim or invisible margin; line and contraction should end at its center.

## Completed generous anchor adhesion bounds
- Goal/status: Enlarge gum-only anchor detection beyond unchanged artwork; complete.
- Completed:48×48px filled octagon (corners trimmed8px) around30px artwork;9px extra reach per cardinal side. Saved TileSet updated directly; shared Layout.GUM_ANCHOR_POLYGON drives generator. Player/prop masks, artwork and map placements unchanged.
- Files changed: theater_tileset.tres; stage_layout.gd; build_theater_stage.gd; verify_gum_anchors.gd; specs/gum-anchor-tile.md; AGENTS.md; WORKLOG.md.
- Verification: Final anchor fixture PASS incl all12 saved rays, four outside-art rays, diagonal approach, moving near-miss shot, outside-margin misses, player/rigid passage, force and erase lifecycle. Map/gum/stage_route suites PASS exit0; logs inspected without script/assertion errors. git diff --check PASS. Known macOS CA warning only.
- Refactoring: Shared immutable polygon array converted to packed array at Godot boundaries; reviewed naming/comments and consolidated fixture position assignment, reran anchor fixture. Moved fixture box clear of horizontal ray cases. No whole-map rebuild.
- Blockers: None. Interactive aiming feel requires playtesting.
- Next action: F5 test aim forgiveness; shape tuning is Layout.GUM_ANCHOR_POLYGON and saved TileSet source2 physics index1.

## Completed enlarged functional anchor tiles
- Goal/status: Enlarge ring within32px cell and replace8 decorative rings in place; complete.
- Completed: Built-in imagegen edited ring; source/runtime PNG visible30×30px with1px transparent margin, preserved transparent hole. Matching30px gum-only octagon. Converted8 source0/(5,6) cells to source2/(0,0) via targeted scene save, preserving all12 authored positions and terrain. Layout synced for future generator builds; saved minimum_length16 untouched.
- Files changed: anchor PNG copies and enlarged source; scene/TileSet; stage_layout.gd; build_theater_stage.gd; verify_gum_anchors.gd and verify_gum.gd; specs/gum-anchor-tile.md; AGENTS.md; WORKLOG.md.
- Decisions/refactoring: No whole-map rebuild. Anchor fixture checks all authored rays, then isolates passage/force/lifecycle from neighboring terrain. Terrain wrapping fixture disables anchor collisions because enlarged section04 ring correctly intercepts its ceiling ray; gameplay detection unchanged. Reviewed affected generator/settings/docs consistency.
- Verification: PNG RGBA32px/bounds(1,1)..(30,30)/center alpha0/copy equality PASS, enlarged preview inspected. Exact12 saved positions and functional source2 PASS. Final anchors/map/gum/stage_route suites all exit0/PASS, logs inspected without script/assertion errors. git diff --check PASS. Known macOS CA/editor sandbox warnings only.
- Blockers: None. Interactive visual/feel QA remains separate.
- Next action: F5 inspect enlarged12 rings; select GumAnchors/source2 for new placement. Imagegen final prompt is in specs/gum-anchor-tile.md.

## Completed nonattaching ring investigation
- Goal/status: Explain why user-painted rings do not attach; identified, no scene edits.
- Findings: Saved GumAnchors layer contains8 source0/(5,6) decorative tiles at(5,12),(7,9),(10,7),(22,10),(25,8),(38,10),(43,8),(62,8); those tiles have no physics polygons. Four functional source2/(0,0) rings remain. Layer collision and source2 bit16 polygon are correct; gum mask21 includes them. Saved user tuning minimum_length16 preserved.
- Files changed: AGENTS.md; WORKLOG.md.
- Verification: Read current scene, TileSet and gum ray implementation; decoded saved TileMap cells. No runtime changes or regeneration.
- Blockers: None.
- Next action: Explain source selection and how to paint functional source2 rings; replace existing decorative cells only if requested.

## Completed minimum contraction distance explanation
- Goal/status: Locate closest-distance tuning and explain risks of reducing it; complete, no runtime edits.
- Findings: Gum Physics/minimum_length defaults36px in game_settings.gd; saved Resource omits override. It limits natural total path length, not actual separation; origin is feet+(0,-34). Short initial attachment never lengthens. Gravity/spring equilibrium and terrain collision also limit approach; force is zero inside rest length.
- Files changed: AGENTS.md; WORKLOG.md.
- Verification: Read shared resource, schema and shorten/force/path-direction code. No experiments claiming small-length instability reproduced; jitter/overshoot described as potential physical consequences only.
- Blockers: None.
- Next action: Explain Inspector location and distinction to user; tune only on request.

## Completed gum anchor TileMap integration
- Goal/status: Register gum-only ring tile and saved-map samples; complete.
- Completed: TileSet source2/(0,0), physics bit16, collision-enabled GumAnchors layer with6 layout-owned placements. Gum mask21 supports TileMap endpoints/local points and collision-RID lifecycle. Rebuilt stage intentionally; documented editor placement and generation ownership.
- Decisions: Player/rigid masks unchanged and ignore rings; filled22px octagon includes visual hole for aiming. Rings are static attachments, not wrapping obstacles. Erase/disable releases connection. Two initial placements moved upward after passage test found adjacent terrain.
- Files changed: generator/layout/gum_connection, project.godot, generated stage/TileSet, verify_gum_anchors.gd; anchor PNG import metadata; specs/gum-anchor-tile.md, bungee-gum-prototype.md, gum-wrapping.md, theater-tileset-assets.md; AGENTS.md; WORKLOG.md.
- Verification: Final anchor fixture PASS (all6 actual rays/forces, player/rigid test_move passage, erase/no-hit/repaint moving-shot/disable). Gum/controls/gum_path/map/one_way/stage_route/player suites PASS exit0. Game60-tick smoke PASS. Logs inspected without script/assertion failures; known macOS CA and editor sandbox warnings only. git diff --check PASS.
- Refactoring: Reviewed target lifetime/force/dynamic-obstruction path, split supported-target classification for readability, kept one generator/layout authority and updated authoritative mask/wrapping docs. Final fixture/regression runs followed implementation cleanup.
- Blockers: None. Interactive appearance/feel unverified.
- Next action: In stage editor select GumAnchors and source2 to paint; F5 tests first ring at cell(8,14), world center(272,464). Update Layout.GUM_ANCHORS before generator rebuild to preserve new placements.

## Completed gum anchor tile artwork
- Goal/status: Create transparent gum-only attachment ring tile artwork; complete.
- Completed: Built-in imagegen generated mint/cream hollow ring with coral grip accents; point-resized to32px; saved source and identical runtime asset; documented generation prompt and intended separate physics configuration.
- Decisions: Artwork-only request; no TileSet/map/physics edits. Dedicated gum-only layer remains integration work; existing terrain layer would collide with player.
- Files changed: images/tilesets/restaurant_gum_anchor{,_source}.png; gd-bungee-gum/assets/tilesets/restaurant_gum_anchor.png; specs/gum-anchor-tile.md; AGENTS.md; WORKLOG.md.
- Verification: RGBA32×32, alpha-zero center/borders, occupied bounds(5,5)..(26,26), identical runtime bytes PASS. Enlarged nearest preview visually inspected. Refactoring reviewed asset naming/copies and documentation consistency; no runtime changes/test need.
- Blockers: None.
- Next action: Deliver image; separate follow-up can register gum-only physics layer and place anchor tiles.

## Completed PS4 gamepad support
- Goal/status: DualShock 4 support implemented and locally verified.
- Completed: Any-device InputMap mappings, axis deadzone0.25, eight-way sign-quantized stick aim, HUD instructions with status moved below five help lines, control spec and AGENTS knowledge. Synthetic joypad tests exercise live Game fire/contract/relax/release/no-repeat, D-pad and stick directions, drift rejection and OPTIONS mapping.
- Decisions: D-pad/left stick move and aim; Cross detaches/contact-kicks, Square fires/contracts, OPTIONS restarts. Existing keyboard, held-input gates and physics stay authoritative.
- Files changed: project.godot; scenes/game.tscn; scripts/game.gd; tools/verify_controls.gd; specs/keyboard-controls.md; AGENTS.md; WORKLOG.md.
- Verification: Initial/final controls, player and gum suites PASS exit0; no assertions/script errors (known macOS CA warning only). git diff --check PASS.
- Refactoring: Reviewed InputMap serialization/action reuse and shared edge/gate logic; kept runtime change confined to eight-way direction normalization. Split pad help across two lines and adjusted status placement.
- Blockers: No physical controller available for USB/Bluetooth recognition/feel QA.
- Next action: Connect DualShock 4 by USB/Bluetooth and F5 verify physical recognition and control feel.

## Completed one-way extreme-edge landing repair
- Goal/status: Fix one-way edge sliding; complete locally.
- Findings: TileMapLayer bypassed CollisionObject2D rectangle support correction; capsule corner converted downward momentum into outward drift. Baseline offset5px fell with90px drift.
- Completed: Slide/prediction contact records carry collision RID; dedicated TileMap server-convex face resolver feeds existing support classification, momentum cleanup and friction. has_body_rid rejects erased tile contacts. Native collision geometry/margins/passage and actual horizontal momentum unchanged.
- Files: scripts/player.gd; tools/verify_one_way.gd; specs/one-way-platforms.md; AGENTS.md; WORKLOG.md.
- Verification: Mirrored outer-edge offsets0/5/7/8px retain support for60ticks with drift<0.1px. Native upward/side passage, fast/seam landing, kick, rigid support, gum ray and paint/erase PASS. Post-review player/compression/stage_route/one_way all exit0 with no assertions/script errors (/tmp/edge-final-*.log); git diff --check PASS. Known macOS CA warning only.
- Refactoring: Kept TileMap server lookup isolated from CollisionObject shape-owner lookup; shared existing support pipeline. Reviewed stale-RID lifecycle and polygon winding/transform handling; final suites above run after cleanup.
- Limits: User4.7.2 unavailable; verified4.5.1. No snapping outside native contact; extremely shallow overlap can miss native one-way contact (9.8px outside a10px radius capsule), outside this contact-response repair.
- Blockers: None.
- Next action: F5 repeat edge landings in user4.7.2.

## Completed one-way floor artwork thickness
- Goal/status: Double visible tile thickness5→10px; complete.
- Completed: Built-in imagegen geometric edit, point-normalized visible band to10px at top of128×32 RGBA strip; saved identical source/runtime copies. Updated asset docs, physics/art distinction and AGENTS knowledge.
- Decisions: Artwork-only: top position/32px cells/layout/collision5px unchanged. Original generation source preserved. Prompt requests vertical-only thickness doubling while retaining X layout/palette; recorded in asset specification.
- Files changed: images/tilesets/restaurant_one_way_platform.png; gd-bungee-gum/assets/tilesets/restaurant_one_way_platform.png; specs/theater-tileset-assets.md; specs/one-way-platforms.md; AGENTS.md; WORKLOG.md.
- Verification/refactoring: Enlarged final image inspected. RGBA128×32, visible y0..9, lower22px transparent and matching copies PASS. Reviewed all touched thickness documentation for visual/physical distinction; git diff --check PASS. No runtime code change; physics reruns unnecessary.
- Blockers: None.
- Next action: Godot automatically reimports updated PNG; F5 inspect thicker platforms.

## Completed tuning-based stage rebuild
- Goal/status: Complete and locally verified with saved movement/gum tuning.
- Completed: Central scripts/stage_layout.gd owns27 terrain rectangles,15 one-way strips/76cells, markers and7 lift tests. Generator intentionally regenerated1212 solid cells,59 gum corners; old unmatched terrain gone. Props use map markers. Stage route uses actual Game including four boxes, real Gum.fire, retained momentum, saved settings and Player.simulate with no teleports after entrance; seven lifts and64px kicks reach exit. Actual60Hz kick height69.48px/airtime0.7s/running range154px measured.
- Decisions: 128px gum lifts,64px kick shelves,222px vertical shot distance against240px range. Safe basins and higher optional routes; final climb offsets lower/upper beams so upper shot stays clear. No tuning/controller/gum changes.
- Files changed: stage_layout.gd, build_theater_stage.gd, regenerated stage/TileSet, game.gd/game.tscn prop placements, verify_stage_route/verify_theater_stage/verify_one_way/verify_player/verify_gum/verify_gum_path; map/one-way/wrapping specs and AGENTS.md.
- Verification: New map grid art/collision checker PASS (1212solid,27shapes,76one-way,59corners); actual Game full-route PASS. Generator PASS. All seven other suites (one_way/player/compression/gum/controls/gum_path/camera) PASS exit0 with no script errors/assertions. Existing geometry-specific regressions updated to current beams; large-coordinate precision case preserved as standalone fixture.
- Blockers: None.
- Refactoring: Shared Layout owns stage dimensions, terrain, shelves, markers and per-lift kick targets; removed route index coupling and obsolete pit-warning decoration. Preserved large-coordinate shelf regression as isolated geometry fixture. Regenerated after cleanup.
- Final verification: Post-refactor all9 suites PASS exit0 (stage_route/theater_stage/one_way/player/compression/gum/controls/gum_path/camera), /tmp/stage-final-*.log inspected with no script errors/assertions. Game60-tick and map-preview5-tick smoke PASS; editor import generated scriptUID files. git diff --check PASS. Known sandbox CA warnings; editor-only Mono socket/settings warnings. Interactive visual/feel QA remains unperformed.
- Next action: F5 play rebuilt route; F6 map_preview for overview. Upper shortcuts remain optional/unverified for optimal timing; lower full route including boxes is verified.

## Completed one-way TileMap implementation
- Goal/status: One-way tiles and saved-map sample complete and locally verified.
- Completed: Native source1 four one-way polygons; OneWayPlatforms collision-enabled layer at cells10..15,y17. Player mask13, box mask9; gum passes through. Generator, layer names and specs aligned; preserved all original scene data.
- Decisions: Top5px polygons, margin1; native physics, no new controls. Box original serialized bitwise expression actually loads1; numeric9 adds only platform collision, preserving existing effective behavior.
- Files changed: theater_tileset.tres, stage/player/box scenes, project.godot, build_theater_stage.gd, verify_one_way.gd, specs/one-way-platforms.md, tile asset docs, AGENTS.md, WORKLOG.md; new tile assets from prior task included.
- Verification: verify_one_way PASS (real player upward/side passage, fast/seam landing, kick, rigid upward/landing, gum ray, single-tile paint/erase collision updates); player/compression/gum/controls/gum_path/camera PASS. Saved-map check has pre-existing failure:1228 actual vs1222 expected; six hand-edited cells(89/90,18),(91/92,19),(93/94,20) have no static collision. Temporary audit confirms other1222 covered,24 shapes/markers/62 gum corners correct. No changes to those cells or weakening of existing test.
- Blockers: Existing saved-map verification mismatch outside requested floor implementation; local engine4.5.1 only.
- Refactoring/verification: Reviewed native resource/generator parity and masks; atlas is registered before polygon creation. Generator ran successfully with only output paths redirected to /tmp (saved map untouched); final new suite and git diff --check PASS. All six other runtime suites exit0 with no assertions/script errors. Known sandbox CA warning only in headless checks. No interactive visual playtest.
- Next action: F5 try entrance shelf; paint source1 tiles on OneWayPlatforms. Existing unrelated six uncollidable hand-edited terrain cells remain for a separate terrain repair.

## Completed one-way platform tile asset
- Goal/status: Add missing one-way floor artwork; complete as artwork only.
- Completed: Generated thin restaurant shelf strip; normalized to128×32 RGBA, four32px cells (left/middle/right/single), top y0,height5px. Saved source and matching source/runtime final copies; documented slicing and pending physics integration.
- Decisions: Separate asset preserves original atlas layout. No TileSet/map/collision changes in this first asset task.
- Files changed: images/tilesets/restaurant_one_way_platform{,_source}.png; gd-bungee-gum/assets/tilesets/restaurant_one_way_platform.png; specs/theater-tileset-assets.md; AGENTS.md; WORKLOG.md.
- Verification: Enlarged visual inspection; Pillow checks dimensions/RGBA/transparent lower27px/identical copies PASS. Reviewed asset naming, scope and documentation; no runtime code to refactor/test.
- Blockers: None.
- Next action: Register artwork and implement one-way collision when requested; consider gum ray/wrapping behavior explicitly during physics design.

## Completed extreme-edge landing follow-up
- Goal/status: Fix remaining edge slip and apparent side rebound in user4.7.2 log; locally implemented and verified.
- Findings: Static terrain normal(-.941842,-.336056) is wall-classified. Projecting external(0,278.3334) yields exactly(-88.09582,246.9001): sideways momentum from slope projection, not restitution. Old raw45deg gate excluded genuine top support; engine movement also drifted each tick when driven downward into steep rounded contact.
- Completed: Predict collision with test_move; verified walkable rectangle face allows that movement's raw capsule normal to classify as floor, with configured angle immediately restored. Before grounded movement, remove into-face motion while retaining external momentum for actual post-move contact/reaction. Rigid proximity contacts include actual shape index and use same face resolver to distinguish support from repulsion. No shape/position/mask or tuning changes.
- Files changed: scripts/player.gd, tools/verify_player.gd, specs/player-controller.md, AGENTS.md, WORKLOG.md. User settings/debug-font edits preserved.
- Verification: Expanded regression fails baseline (/tmp/extreme-before.log); final42 mirrored cases pass at offsets0/3/5/7/9/9.8/9.99 and fall0/300/600 (/tmp/extreme-limit.log). Diagonal278.3334px/s descent has no horizontal external pushback or outward displacement; real walls/undersides stay nonfloor, angle restored, upward/downward load and horizontal momentum preserved. Post-refactor all7 suites PASS exit0 with --fixed-fps60: /tmp/extreme-final-{player,compression,gum,controls,gum_path,camera,theater_stage}.log, logs checked for assertion/script errors. Latest player test expansion also PASS. Known macOS CA warning only. git diff --check PASS.
- Refactoring: Dedicated _move_with_face_support owns temporary engine configuration/restoration; geometric helper evaluated with original slope limit, shared by motion/momentum/friction/rigid-contact classification. Relevant suites rerun after cleanup.
- Blockers: User4.7.2 unavailable locally; verified with4.5.1.
- Next action: F5 repeat extreme ledge landing/diagonal corner descent on user4.7.2; compare updated behavior if further logs supplied.

## Completed corner landing repair
- Goal/status: Implement approved support-face correction; complete and locally verified.
- Completed: Rectangle edge resolver uses collider shape index/transform and0.5px face tolerance for all4 edges. Momentum cleanup and friction share a per-step support normal; engine contacts/movement and capsule are unchanged. Integrated current behavior into specs/player-controller.md and removed proposal file.
- Files changed: scripts/player.gd, tools/verify_player.gd, specs/player-controller.md, removed specs/corner-landing-fix-proposal.md, AGENTS.md, WORKLOG.md. Pre-existing debug font edits preserved.
- Verification: New original-ledge test fails baseline (/tmp/corner-before.log); assertions can return exit0, so logs were checked explicitly. Final Godot4.5.1 all7 suites PASS exit0 with no script errors/assertions: /tmp/corner-player-refactor.log and /tmp/corner-refactor-{compression,gum,controls,gum_path,camera,theater_stage}.log.24 mirrored ledge cases cover offsets0/3/5/7 and fall0/300/600; impact drift<0.1px and support retained. Downward load/upward departure, horizontal momentum/ledge escape and rotated-face checks pass. Rigid center/edges60/60 floor, drift<=0.028px; moving platforms60/60 and0 relative drift. git diff --check PASS. Known macOS CA warning only.
- Refactoring: Local support-normal argument avoids persistent state; shared face resolver, named tolerance and four-edge handling. Relevant suites rerun after cleanup. No movement rewrite needed: impact-frame displacement tests pass with existing engine movement.
- Decisions: Preserve incoming horizontal momentum, upward departure, real slopes, rigid contact-point reactions and deferred application. Unsupported/nonrectangle shapes retain real contact normals.
- Blockers: None for local implementation; native user-engine/interactive feel not tested.
- Next action: F5 land on stage corners to confirm feel; existing physics checks cover local4.5.1 behavior.

## Completed corner landing repair proposal
- Goal/status: Develop a repair approach; proposal complete, runtime unchanged.
- Decisions: Recommend verified support-surface response distinct from raw capsule contact normal. Horizontal top support absorbs downward relative velocity without creating lateral momentum; preserve incoming horizontal momentum, upward departure and actual slopes. Include same-tick move_and_slide displacement verification, rigid point-relative support/reaction and deferred impulse constraints. Do not blanket-replace all floor normals with UP.
- Files changed: specs/corner-landing-fix-proposal.md, WORKLOG.md.
- Verification: Reviewed proposal against player.gd current movement, friction, rigid support and compression architecture. Documentation-only; no runtime test rerun. Proposal includes mirrored original-support regressions and full implementation verification/refactoring sequence.
- Blockers: None for proposal; exact support-face lookup and same-tick movement handling require implementation experiments.
- Next action: If implementation requested, add original-corner regressions, implement support-face resolver and test collision displacement before expanding movement changes.

## Completed static corner landing investigation
- Goal/status: Identify why landing on a corner slides player off; diagnosis complete, runtime unchanged.
- Findings: Capsule rounded bottom touching a rectangular ledge produces tilted floor normal. player.gd collision cleanup projects full falling external velocity onto that tangent, creating outward/downward retained momentum even with no input/gum. Ground friction removes only15px/s per60Hz tick (900px/s²), insufficient before contact escapes; gravity is added while grounded too. At edge+3px, normal(0.300466,-0.953793), impact external after friction(69.7571,21.97504); eventually falls. At initial fall600, outward179.2035px/s. Edge+0px remains grounded for all tested speeds. Static-only reproduction rules out rigid support/platform carry as necessary cause.
- Verification: Godot4.5.1 temporary /tmp/corner_probe.gd, /tmp/corner-probe.log exit0: 96×40 static platform top640, feet start600, offsets0/3/5/7px, initial falling speeds0/300/600,90 real physics ticks each. All9 outside-edge cases fall; all3 exact-edge cases stay. Known macOS CA warning only. Existing corner traversal test settles on added recovery floor, so does not assert retention on original corner; floor-kick corner fixture checks only12 ticks before launch.
- Decisions: Investigate only; no gameplay fix adopted. A repair needs explicit floor-support handling of landing/gravity versus retained intentional physical momentum, plus original-corner retention regressions; merely increasing friction changes movement globally.
- Files changed: WORKLOG.md, AGENTS.md only. Reviewed touched documentation for consistency; no runtime refactoring required.
- Blockers: User exact location/engine sequence not supplied; mechanism independently reproduced locally, not yet verified against their specific occurrence.
- Next action: On repair request, add mirrored corner-retention cases with multiple fall speeds and implement floor-support momentum policy while preserving gum/air/rigid reciprocal momentum; run player/compression and related suites.

## Completed debug text font replacement
- Goal/status: Replace on-screen debug text with fonts added by user; complete.
- Completed: Shared project Theme uses PixelMplus12 Regular24px; import uses no AA/subpixel, oversampling1. Game help/status, map preview and stage labels inherit it; adjusted HUD spacing/header height.
- Decisions/refactoring: One shared theme, removed arbitrary stage sizes and generator size argument; no physics changes. Console output font remains owned by editor/terminal.
- Files changed: project.godot, resources/debug_theme.tres, font import, game/map-preview/stage scenes, stage generator, specs/debug-text.md, AGENTS.md, WORKLOG.md.
- Verification: Godot4.5.1 import and gameplay smoke exit0; temporary headless font checks PASS for both scenes/all labels, font path24px, help bounds936×87 and745×59 fit1280px and reserved vertical space. git diff --check PASS. Existing sandbox CA/Mono/editor-settings warnings only; rendered appearance not visually inspected.
- Blockers: None.
- Next action: F5 inspect updated debug text; F6 map preview uses same font.

## Completed scheduled block-top repair
- Goal/status: Scheduled repair implemented and locally verified; one-time automation deleted at start. User4.7.2/native verification pending.
- Completed: Distinguish floor support from repulsion. Non-support solver updates virtual body velocities and player momentum, commits rigid impulses after all movement. Supporting collision momentum is transferred at its real contact point after movement; no skin separation/restitution on floor normals. Default automatic platform layers preserved. Terrain queries exclude nearby rigid RIDs without mask changes on normal frames. Preserved existing pushing-run edits.
- Files changed: player.gd, game_settings.gd comments, verify_compression.gd, specs/player-controller.md, specs/game-settings.md, AGENTS.md, WORKLOG.md. Existing verify_player/pushing edits preserved.
- Verification: New support regressions fail pre-fix (central0/60 floor, edge drift24.88px, moving support9/60). Final Godot4.5.1 all7 suites PASS exit0 (/tmp/block-support-final-{compression,player,gum,controls,gum_path,camera,theater_stage}.log). Center/left/right support60/60, drift<=0.028px, no hover and kick escape; rightward/leftward-ascending rigid platforms60/60,0 relative-X drift; dual3000-force loaded gap20.553px and escape pass. Contact fixture verifies body velocity unchanged before deferred commit, then momentum/torque response. git diff --check PASS; known macOS CA warning only.
- Decisions: Floor support uses actual engine collision rather than artificial clearance; body position/rotation and gum mechanics remain physics driven. Physical contact reactions are deferred, not discarded; real moving-platform carry remains enabled.
- Refactoring: Removed duplicate normal member state; pending impulse records also supply cleanup normals. Updated all solver/commit callers and docs; support/repel diagnostics and platform velocity fields distinguish phases. Full7 suites rerun after cleanup.
- Blockers: None for implementation; user engine4.7.2 unavailable locally.
- Next action: User can F5 verify stable block-top standing and block/block compression on4.7.2. No further scheduled runs remain.

## Completed block-top landing investigation
- Goal/status: Diagnose block-top lost landing/sliding; complete, runtime unchanged.
- Findings: Initial landing succeeds, then generic repulsion treats0.75px contact skin as penetration and requests upward separation even for support normals(0,-1). Center fixture hovers0.318px, floor0/90, jump pose; zero separation bias alone restores90/90 on-block contact/idle. Off-center downward impulse on block also creates instantaneous point angular velocity; automatic CharacterBody platform carry reads that same-tick induced velocity, translating rider sideways while floor collision largely cancels actual box motion next step. Log313 incoming x0 vs slide x-16.03 matches this pathway. First corner119 additionally has residual control68px/s and tilted normal(-.093,-.996), so it is not a pure centered landing.
- Verification: Godot4.5.1 eight A/B probes (x360/343.2408, separation bias ON/OFF × dynamic platform carry ON/OFF), /tmp/block-landing-isolation.log, exit0. Center: default0/90 on-box vs biasOFF90/90. Near-edge: carryON falls to terrain (0/90 on-box; x318.36 default, x323.03 biasOFF); carryOFF stays x343.2408/on-box90/90 for both bias variants. Max auto platform X velocity22.63px/s; box post-physics spin remains tiny. Only known macOS CA warning. User engine4.7.2 not locally tested.
- Decisions: Repair must distinguish supporting floor contacts from repelling/compressing contacts and avoid double-counting same-tick contact impulses in platform carry. Probe-only platform_floor_layers=1 is a diagnostic isolation, not an adopted gameplay setting. No need for another user log to establish these mechanisms.
- Files changed: WORKLOG.md, AGENTS.md only. Probe at /tmp/block_landing_probe.gd; gameplay scripts/settings/specs untouched.
- Blockers: None for diagnosis.
- Next action: On repair request, add persistent centered/off-center landing regressions, remove separation target for support contact skin, coordinate rigid momentum transfer with platform carry, then rerun compression and full controller/gum suites.

## Completed pushing run animation
- Goal/status: Show run while pushing a block even when collision removes movement speed; complete.
- Decisions: Ground run selection considers movement input as well as retained horizontal speed. Air/gum/landing pose priority and physics remain unchanged.
- Files changed: scripts/player.gd, tools/verify_player.gd, specs/player-controller.md, AGENTS.md, WORKLOG.md.
- Verification: Godot4.5.1 player suite PASS exit0 (/tmp/push-run-final-player.log), including grounded zero-displacement run assertion; controls PASS exit0 (/tmp/push-run-controls.log); git diff --check PASS. Existing macOS CA warning only. Blocked fixture corridor widened20→21px to leave collision-margin space and keep it grounded; initial exact-width frozen fixture lost floor and was unsuitable for grounded animation verification.
- Refactoring: Reviewed animation priorities; kept one input-or-speed predicate, no new pushing state or physics branching. Existing blocked fixture reused with explicit grounded precondition; relevant suites rerun.
- Blockers: None.
- Next action: F5 hold left/right against a block to inspect run motion; release to return to idle once horizontal momentum stops.

## Completed rigid contact repulsion
- Goal/status: Fix persistent two-block pinning with repulsion on contact, not only opposing deep-overlap recovery; implemented and locally verified; user4.7.2 verification pending.
- Findings: Latest24-line user log reports opposing_bodies=2 every30ticks334–574, correction0; prior pair recovery executes but does not free user4.7.2. Its tiny support-refresh move can also consume intended motion. Need earlier single-contact response and actual server velocity/impulse diagnostics.
- Decisions: Introduce pre-move mass/angular-aware contact impulses for each movable rigid body, reciprocal player momentum, bounded penetration bias and restitution. Retain terrain recovery, remove superseded pair-only impulse/refresh path. Verify first-contact response and continuous two-body pressure.
- Files changed: player.gd, game_settings.gd, verify_compression.gd, specs/player-controller.md, specs/game-settings.md, AGENTS.md, WORKLOG.md.
- Verification: New continuous two-block1500/3000-force fixture exposed lingering floor/escape failures with weak independent response. Coupled8-pass solver +0.75px skin passes3000-per-side test with loaded gap20.499px and post-release21.002px, bounded gravity and kick escape. Single impact/momentum/separation/custom-COM torque checks PASS (/tmp/contact-inertia.log). Final Godot4.5.1 all7 suites PASS exit0 (/tmp/repel-final-{compression,player,gum,controls,gum_path,camera,theater_stage}.log). Final loaded gap20.263px, preserved floor/gravity/kick escape; git diff --check PASS. Existing macOS CA warning only.
- Blockers: User engine4.7.2 not locally installed; local Godot4.5.1 available.
- Refactoring: Replaced pair-only query/impulse path with shared shape contact/impulse pass, renamed contact normals, reused probe shape, skip empty contacts and disabled shapes. Direct shape-pair queries avoid live body mask toggles; original terrain guard retained.
- Next action: F5 repeat block/block compression on4.7.2. If still blocked, collect CONTACT_IMPULSE with actual server velocities, impulses and depth; tuning is Player Contact in shared resource.

## Completed two-block compression repair
- Goal/status: Extend compression handling to player trapped between dynamic blocks; complete; native4.7.2 verification pending.
- Findings: User confirms wall case fixed. New log ends at player x483.91, HeavyBox500/6kg and LightBox458.87/1kg, only1.13px gap for20px capsule; heavy penetration13.99px, repeated4 contacts, lost floor and accumulated gravity. Existing recovery requires static terrain displacement, so cannot open dynamic-only gap.
- Decisions: Derive individual rigid penetration vectors from physics-server queries; apply mass-aware equal/opposite separation impulses to both sides and refresh terrain support when opposing bodies compress player. Preserve original wall handling.
- Files changed: player.gd, verify_compression.gd, verify_gum.gd (explicit diagnostic toggle in diagnostic fixture), specs/player-controller.md, AGENTS.md, WORKLOG.md.
- Verification: Isolated sleeping-pair shape/impulse regression fails with pair response disabled (exit1), passes enabled (exit0); confirms outward impulses on both1kg/6kg bodies and pre-cleanup momentum balance. Local4.5 solver can naturally open gap differently from user4.7; full user freeze sequence is not reproduced. Final Godot4.5.1 all7 suites PASS exit0: compression/player/controls/path/camera/map (/tmp/pair-repair-final-*.log), gum (/tmp/pair-repair-gum-rerun.log). Gum diagnostic fixture explicitly enables/restores its flag, independent of saved Diagnostics OFF. git diff --check PASS; known macOS CA warning only.
- Blockers: None.
- Refactoring: Isolated opposing-contact query helper and shared reciprocal impulse application; single-body wall query skips pair tests. Account for already separating velocity to avoid redundant impulse. No rigid transform edits.
- Next action: F5 pull a block toward player backed by another block, relax/detach and Z to confirm no persistent overlap on user4.7.2; logs retain opposing_bodies count.

## Completed pixel font research
- Goal/status: Find Japanese pixel fonts suited to current restaurant game; research complete, no font installed or selected.
- Completed: Checked official PixelMplus, Misaki and DotGothic16 sources/licenses; confirmed current viewport1280×768.
- Decision: Recommend PixelMplus12 for first UI trial at24px; DotGothic16 for denser Japanese text; Misaki for deliberately tiny retro labels. Recommendations remain untested in rendered gameplay.
- Files changed: WORKLOG.md, AGENTS.md; runtime untouched.
- Verification: Official source review; documentation reviewed for clear recommendation vs adoption. No runtime tests required.
- Blockers: None. Existing compression repair remains unfinished and unchanged.
- Next action: If implementation requested, compare candidate fonts with actual HUD/menu strings at integer scale before selecting.

## Completed player compression repair
- Goal/status: Repair wall/block compression and restore escape; complete, native user-engine verification pending.
- Completed: Terrain-only physics-server depenetration near unfrozen rigid bodies,0.25px recovery clearance, equal/opposite mass-scaled contact impulse without rigid transform changes; refresh support contacts and combine original/recovered normals to stop gravity accumulation. Diagnostic recovery log throttled30ticks.
- Decisions: CharacterBody controller/gum force law unchanged. Recovery uses physics-server zero-motion travel (max8 iterations), not a fixed relocation. Static reaction removes inward external momentum; frozen bodies stay frozen. Normal movement keeps its original single collision cleanup when no correction occurs.
- Files changed: scripts/player.gd, tools/verify_compression.gd(+UID), specs/player-controller.md, AGENTS.md, WORKLOG.md. Earlier diagnostics/gum fixes and other workspace changes preserved.
- Verification: Pre-fix real dynamic pressure fixture failed terrain/floor/escape checks. Final Godot4.5.1 all7 suites PASS exit0: compression/player/gum/controls/gum_path/camera/theater_stage (/tmp/pin-repair-final-*.log). Compression covers left/right, light/heavy/rotation, real gum tension with retained connection, pre-existing logged-size overlap, bounded gravity and kick escape. git diff --check PASS. Existing macOS CA warning only. Godot4.7.2/native feel not tested.
- Refactoring: Original normals captured once; refreshed normals appended only on corrected frames, avoiding changed ordinary collision projection. Reused collider transform, documented recovery/contact impulse, isolated test cases and bounded/throttled correction logging; full suites rerun after cleanup.
- Blockers: None.
- Next action: F5 pull block into wall-side player on user engine, relax/detach and Z to confirm escape; retain PinningDiagnostic for further cases.

## Completed pinning log analysis and capture correction
- Goal/status: Analyze supplied wall/block trapped log and close diagnostic blind spot; diagnostics updated and verified, physics unchanged.
- Findings: Supplied64-line log has no PinningDiagnostic (could be omitted, disabled or capture condition missed). At tick336 wall depth5.2837px repeated4 times, floor=false, real motion~0.002px/tick; slack tension0 and manual detach do not release trap. Z accepted as +400 horizontal wall kick then denied rearm. Downward external speed grows1395→8381 while actual motion stays near zero. Block center96.97 with left face76.97 vs wall64 leaves~12.97px for20px player; geometric compression is consistent with overlap, but onset/nearby query not present to prove full causal sequence.
- Decisions: Extend capture to static-only stalled penetration (depth>=1px, speed>=10, displacement<0.1px/tick). Do not change physics or choose a recovery fix from incomplete onset evidence.
- Completed/files: player.gd diagnostic predicate/fields, game_settings comment, specs/game-settings.md, AGENTS.md, WORKLOG.md.
- Verification: Godot4.5.1 player/controls suites PASS exit0 (/tmp/pinning-static-{player,controls}.log), git diff --check PASS. New stalled-static trigger not yet exercised by user reproduction. Known macOS CA warning only.
- Refactoring: Reuse same contact lifecycle/history/nearby query for both triggers; no duplicate logger or new state.
- Blockers: Need onset/nearby details to distinguish exact recovery failure and block pushing behavior on user engine.
- Next action: Run verification, report evidenced failure chain and request new complete Output with strengthened PinningDiagnostic.

## Completed player pinning diagnostics
- Goal/status: Log player trapped between wall and pulled block; complete; physics unchanged.
- Decisions: Default-on diagnostics watch rigid slide contacts, capture8 prior steps, transitions/input changes and30-tick summaries; include nearby collider query to expose contacts missing from slide results.
- Completed: Shared Pinning Diagnostics toggle,8-step pre-event history, rigid contact transitions/input changes/30-tick summary, pre/post cleanup motion/contacts/gum state, event-only2px nearby query; documented current semantics. Added real narrow-gap player fixture verifying blocked input/displacement, bounded history, nearby candidates and disable behavior.
- Files changed: player.gd, game_settings.gd, verify_player.gd, specs/game-settings.md, AGENTS.md, WORKLOG.md.
- Verification: Godot4.5.1 player/controls/gum suites PASS exit0 (/tmp/pinning-player.log, /tmp/pinning-final-{controls,gum}.log); real fixture logged attempted26.67px/s vs zero displacement and nearby wall/block/floor. History cap/disable checks passed. git diff --check PASS. Existing macOS CA warning only. Gameplay cause awaits supplied reproduction log.
- Refactoring: Reviewed full touched move pipeline and logger, kept captures read-only and named by timing; shared collider snapshot helper and input dictionary avoid duplicate field handling, nearby query runs only on log events. No further code change needed.
- Blockers: None; gameplay pinning cause not yet established.
- Next action: F5 reproduce pinning, try left/right/Z and gum relaxation, supply [PinningDiagnostic] plus [JumpDiagnostic]/[GumDiagnostic] output.

## Completed floor-contact endpoint fix
- Goal/status: Resolve remaining rotating block releases; bounded terrain endpoint correction complete.
- Findings: New logs ticks331/422 PATH INVALID; actual endpoint y640.481/641.097 penetrates floor y640 during rigid contact, unlike prior self-obstruction.
- Decisions: Only rigid target route endpoint may project out of static union within2px; actual local adhesion point/torque position unchanged; deeper penetration remains invalid.
- Files changed: gum_connection/gum_path/gum_terrain_geometry scripts, verify_gum/verify_gum_path, specs/gum-wrapping.md, AGENTS.md, WORKLOG.md.
- Verification: Initial gum replay PASS for logged floor penetration, subsequent1.1px contact, deep-penetration release, unchanged actual endpoint and reciprocal force. Final Godot4.5.1 gum/path/controls/player/camera/map suites PASS exit0 (/tmp/contact-final-*.log), git diff --check PASS; known macOS CA warning only. User Godot4.7.2/native feel untested.
- Refactoring: Projection owned by GumPath after cached geometry refresh, preserving geometry-change pivot cleanup; common geometry helper checks exposed union exits. No force/torque repositioning.
- Blockers: None.
- User verification: Rotating-block unintended release is resolved in gameplay.
- Next action: Investigate separate player pinning issue using diagnostics above.

## Completed target self-obstruction fix
- Goal/status: Prevent attached rotating blocks from causing self-obstruction releases; complete.
- Decisions: Exclude attached target RID from dynamic route rays; separate dynamic blockers still release, static target terrain wrapping unchanged.
- Completed: Added rotated far-side adhesion regression and separate-blocker check. Pre-fix suite failed self-intersection retention/obstruction identity; fixed suite passed. Updated query and current specs/AGENTS.
- Files changed: gum_connection.gd, verify_gum.gd, gum-wrapping/prototype specs, AGENTS.md, WORKLOG.md; existing tuning/diagnostics preserved.
- Verification: Godot4.5.1 final gum/controls/path suites PASS exit0 (/tmp/self-obstruction-{final,controls,gum_path}.log); regression fails before fix and passes after. git diff --check PASS. Known macOS certificate warning only. User engine4.7.2/native gameplay not tested.
- Refactoring: Reviewed full dynamic query; removed obsolete endpoint-shortening workaround now that target is explicitly excluded, and compute exclusion list once per path query. Final gum rerun PASS after cleanup.
- Blockers: None.
- Next action: F5 verify rotating block pull on user engine; diagnostics retained for further investigation.

## Completed saved tuning baseline
- Goal/status: Finalize game_settings.tres tuning; complete.
- Completed: Adopted saved attachment_range240 and gum_shot_speed1200 as script defaults and specification baseline. Resource already committed in 9e081d5; no resource edit needed.
- Files changed: scripts/game_settings.gd, specs/game-settings.md, AGENTS.md, WORKLOG.md.
- Decisions: Preserve existing diagnostic changes; do not bundle them into a settings commit.
- Verification: Reviewed saved values and affected defaults/docs; Godot4.5.1 verify_controls.gd PASS exit0 (/tmp/final-tuning-controls.log); git diff --check PASS. Reviewed touched defaults/docs for consistency; no extra refactor needed. Existing macOS CA warning only.
- Blockers: None.
- Next action: F5 playtest finalized tuning.

## Completed block-release log analysis
- Goal/status: Analyze supplied gameplay release logs; cause identified, runtime unchanged.
- Findings: Unexpected detach ticks114/214/305 all UNSUPPORTED OBSTACLE with collider=target LightBox and is_target=true; path_failure empty, zero pivots, lengths86.43/74.57/53.29 below max400. Rotating attached block intersects its own connection ray before attachment endpoint. Tick531 RELEASED coincides with Z kick and is expected.
- Decision: Immediate cause is target self-obstruction in _dynamic_obstruction, which excludes only player RID. Rotation brings the fixed local attachment point behind the near silhouette; logs do not establish an engine transform-sync defect. Proposed fix is excluding attached target from dynamic obstruction while retaining other-body checks; pending implementation request.
- Files changed: WORKLOG.md, AGENTS.md only.
- Verification: Read complete supplied log and current ray query; no runtime tests required for analysis-only task.
- Blockers: None for diagnosis; fix not applied.
- Next action: On fix request, add rotating-target regression plus independent-blocker retention check, update query/specs and rerun gum/controls/path suites.

## Completed gum block-release diagnostics
- Goal/status: Add logs for unexpected block-pulling disconnections; complete; reported gameplay occurrence awaits reproduction.
- Completed: Toggleable default-on release snapshot, eight pre-reset step snapshots, dynamic ray hit identity/segment details. Physics rules unchanged.
- Decisions: Include manual/outbound releases for reason comparison; detect whether obstruction is attached target without changing collision filtering.
- Files changed: gum_connection.gd, game_settings.gd, specs/game-settings.md, AGENTS.md, WORKLOG.md.
- Verification: Godot4.5.1 gum/controls/path suites PASS exit0 (/tmp/gum-diagnostics-{final,controls,path}.log); logged release snapshots/history and rigid state observed. git diff --check PASS. Known unrelated macOS certificate warning only.
- Refactoring: Reviewed snapshot lifecycle; clear history on new shots/attachments, print history as separate searchable lines, preserve original ray query and force/reset ordering.
- Blockers: None; actual user-reported occurrence not reproduced yet.
- Next action: F5 reproduce block-pulling release and inspect [GumDiagnostic] DETACH/HISTORY in Godot Output, especially reason and obstruction.is_target.

## Completed constant faint guide
- Goal/status: Keep prediction line and reticle faint regardless of arrow input; complete.
- Completed: Unconditional guide opacity multiplier0.3, renamed setting aim_guide_opacity, removed obsolete cross-node aim_active flag; updated direction regression assertions, current specs and AGENTS.
- Decisions: Valid/invalid hue and READY-only visibility retained; input no longer changes guide alpha.
- Files changed: game/gum/game_settings scripts, verify_controls, current specs, AGENTS, WORKLOG.
- Verification: Godot4.5.1 controls suite PASS exit0 (/tmp/faint-guide-controls.log); stale setting/state search clean; git diff --check PASS. Known unrelated macOS CA warning only. Rendered appearance not inspected.
- Refactoring: Reviewed direction/render interface, removed unused flag and renamed opacity to reflect unconditional behavior; no compatibility aliases.
- Blockers: None.
- Next action: F5 inspect constant faint guide; tune Aim Guide Opacity if needed.

## Completed guide visibility change
- Goal/status: Hide predicted shot line until gum returns to hand; complete.
- Completed: READY-only guide line/reticle drawing; hidden throughout outbound/attached/returning. Updated current specs and AGENTS; direction input continues while hidden.
- Decisions: Reuse READY transition for completed return/timeout; interrupt/refire keeps guide hidden without a transient READY draw.
- Files changed: gum_connection.gd, keyboard/flight/settings/direction/prototype/stage-action/implementation specs, AGENTS, WORKLOG.
- Verification: Godot4.5.1 controls regression PASS exit0 (/tmp/guide-visibility-controls.log); git diff --check PASS. Known unrelated macOS CA warning only. Actual rendered appearance not inspected.
- Refactoring: Reviewed complete draw branch and state transitions; guide and gum drawing now mutually exclusive, no extra flags/timers or redundant tests.
- Blockers: None.
- Next action: F5 inspect guide disappearance on fire and reappearance after return.

## Completed press-to-fire implementation
- Goal/status: Apply X press fire, always-on preview, no aim zoom, and pre-attachment Up/Down gating; complete.
- Completed: Removed aim/release gesture state, movement suppression and camera hold settings; always-visible preview with idle alpha0.3; immediate return-cancel/refire; all pre-arrival Up/Down gated until release. Updated scene HUD and all current control/flight/camera/player specs and AGENTS.
- Decisions: Neutral/opposing arrows retain last direction, initial facing. Arrows combine run/aim; A/D movement-only. Saved user shot speed400 and firing range240 preserved; timing fixtures explicitly set speed2400 and ranges. Path-length zoom remains independent.
- Files changed: game/player/gum/settings scripts/resource/scene, controls/camera/gum/player tests, current specs, AGENTS, WORKLOG.
- Verification: Godot4.5.1 all six suites PASS exit0: controls (/tmp/press-final-controls.log), gum/camera/player/gum_path/theater_stage (/tmp/press-*.log). Physical press/release/no-repeat, eight-way same-tick direction, running diagonal, return cancel/refire, pre-shot and midflight Up/Down gates, manual length controls and Z priority covered. git diff --check PASS. Known unrelated macOS CA warning only.
- Refactoring: Reviewed direction→input→arrival→player→preview order; removed obsolete gesture/camera hold state, face_aim helper and simulate aiming argument; updated every caller and reran controls after cleanup. Initial timing-fixture failures resolved by explicit speed independent of saved tuning.
- Blockers: None. Native visual opacity and play feel not checked by headless tests.
- Next action: F5 playtest press firing while running, neutral preview and held pre-attachment Down; tune Aim Idle Opacity if needed.

## Completed press-to-fire impact review
- Goal/status: Summarize concerns changing X release fire to X press fire; analysis complete, no runtime/spec policy changes.
- Findings: Press fire removes in-hold aiming/preview and aim zoom preparation. Must define pre-shot direction selection, movement-vs-aim ownership, held Up/Down gates after arrival, state-dependent X semantics and repeat suppression. Return X should cancel and fire atomically if adopting immediate fire; Z priority must remain explicit. Tip travel delay remains independent.
- Files changed: WORKLOG.md only.
- Verification: Read current Game gesture handling and flight/return authority; design analysis, no engine tests required.
- Blockers: None for review.
- Next action: If adopting press fire, choose direction/preview policy first, then update Game input, camera, tests and current control/flight specs together.

## Completed gum flight / return implementation
- Goal/status: Implement approved tip flight, delayed contraction and interruptible cosmetic return; complete.
- Completed: Swept tip/arrival state, zero-force attachment tick, reverse-path cosmetic return with timeout, fresh-X interruption/re-fire, outbound-X release consumption, settings/HUD, flight-only pose. Promoted proposal to specs/gum-flight-return.md and aligned related current specs/AGENTS.
- Decisions: Shot2400px/s, return3200px/s, max0.25s. Direct attach_at explicitly sets up connection physics fixtures; gameplay uses fire. Removed obsolete fire timer/cancel interface; state owns pose lifetime. Return drawing root follows current hand after player movement.
- Files changed: game/gum_connection/game_settings/player scripts, verify_gum/controls, specs/gum-flight-return plus keyboard/prototype/wrapping/settings/implementation/animation/direction/stage-action specs, AGENTS, WORKLOG.
- Verification: Godot4.5.1 all six suites PASS exit0: gum (/tmp/flight-final-gum.log), controls (/tmp/flight-final-controls.log), camera/player/gum_path/theater_stage (/tmp/flight-*.log). Covers 30/60/120Hz flight, zero arrival force, next-tick contraction, exact-range/thin-blocker/moving-target/moving-root cases, reverse return/lifetime/deleted-target snapshot, physical interrupt/re-fire and all existing reciprocal force/momentum regressions. git diff --check PASS. Known unrelated macOS CA warning only.
- Refactoring: Reviewed touched runtime; shared segment query and world display conversion, state-driven animation, removed redundant cancel timer, simplified HUD branching; relevant suites rerun after cleanup.
- Blockers: None. Native rendered appearance and speed feel not checked by headless suites.
- Next action: F5 playtest flight and Z→X→release chaining; tune Gum Flight speeds/lifetime via resources/game_settings.tres if needed.

## Completed gum flight / return specification review
- Goal/status: Specify high-speed tip travel, attachment-before-contraction and interruptible return; proposal complete, runtime unchanged.
- Completed: State/input table, swept collision and live hit validation, independent range/length limits, zero-force attachment tick, immediate physical Z release, reverse-path cosmetic return and fresh-X cancellation; current control authority links proposal.
- Decisions: Proposed shot2400 px/s, return3200 px/s, return lifetime0.25s pending playtest. Keep X hold aim/release fire; consume held/canceled gestures. No force before attachment or during return; existing physics and kick rules retained.
- Files changed: specs/gum-flight-return-proposal.md, specs/keyboard-controls.md, AGENTS.md, WORKLOG.md.
- Verification: Reviewed current Game/Gum flow and keyboard specification. Reviewed proposal for state/input consistency, moving targets, wrapping, safety release and settings ownership; git diff --check PASS. No runtime tests for document-only proposal.
- Blockers: None for design; proposed speeds need implementation-time playtest.
- Next action: On implementation request, integrate proposal into authoritative specs, implement flight/return lifecycle and update gum/controls/camera regression suites.

## Completed independent gum range
- Goal/status: Separate firing range and connected physical length; complete.
- Completed: Added attachment_range for ray/aim/Game aim vector; maximum_length retains wrapped break limit, HUD length ratio and manual cap. Over-limit initial hit rejected consistently by preview/attachment. Updated long-range fixtures and current specs.
- Decisions: Both defaults400 px; existing saved tuning preserved. Short firing range can support a longer connected rope; physical limit still applies at attachment.
- Files changed: game_settings/game/gum_connection scripts, verify_gum/controls/camera, settings/prototype/wrapping/keyboard specs, AGENTS.md, WORKLOG.md.
- Verification: Godot4.5.1 gum/controls/camera suites PASS exit0 (/tmp/range-{gum,controls,camera}.log); independent short ray, miss preview, initial physical cap and extension beyond firing range covered. git diff --check PASS. Known unrelated macOS certificate warning only.
- Refactoring: Reviewed every maximum_length consumer; ray/aim use only attachment_range, physics/path/manual/HUD use only maximum_length. Shared attachable predicate keeps aim and firing consistent.
- Blockers: None.
- Next action: Set Attachment Range and Maximum Length independently in resources/game_settings.tres via Inspector; F5 playtest desired tuning.

## Completed gum glow implementation
- Goal/status: Give gum a luminous core and soft halo; complete.
- Completed: Four translucent halo layers, base silhouette and narrow bright core on line/pivots/endpoint; shared Inspector controls and spec updated. Gray loosen base retained.
- Decisions: Renderer-independent CanvasItem drawing; no world lighting or physics changes.
- Files changed: scripts/gum_connection.gd, scripts/game_settings.gd, specs/game-settings.md, AGENTS.md, WORKLOG.md.
- Verification: Godot4.5.1 verify_gum.gd PASS exit0 (/tmp/gum-glow.log); git diff --check PASS. Known unrelated macOS certificate warning. Native visual appearance not checked.
- Refactoring: Reused one shape helper for halos/base/core; reviewed appearance settings and endpoint consistency, no physics coupling.
- Blockers: None.
- Next action: F5 inspect glow against restaurant background; tune Gum Glow Radius/Opacity/Core Brightness in shared settings if needed.

## Completed manual extension baseline update
- Goal/status: Promote user-saved manual extension limit to defaults; complete.
- Completed: Verified saved margin240 and inherited max400 (manual cap160); matched script default and all current specs/AGENTS. Kept saved resource unchanged. Made wrapped extension regression respect configured cap.
- Decisions: Preserve all other tuning, including extension180/shortening90 and above-cap attachment behavior.
- Files changed: game_settings.gd, verify_gum.gd, relevant control/settings/physics specs, AGENTS.md, WORKLOG.md. User resource edit preserved.
- Verification: Godot4.5.1 settings comparison PASS (all43 saved/default properties, cap160/break400; /tmp/manual-baseline.log). Full gum and physical controls suites PASS exit0 (/tmp/manual-limit-gum.log, /tmp/manual-limit-controls.log). git diff --check PASS; known unrelated macOS CA warning only. Temporary comparison script removed.
- Refactoring: Reviewed settings consumption and all current numeric documentation; wrapped test computes cap-aware expectation without hardcoded margin. No runtime logic change beyond default tuning.
- Blockers: None.
- Next action: Continue gameplay using confirmed manual cap160 px and break limit400 px.

## Completed manual gum controls implementation
- Goal/status: Implement approved Up/Down/X controls and unattached-only X camera zoom; complete; final refactor verification passed.
- Completed: Explicit relax/contract, continuous natural-length adjustment, per-key firing release gates, no-op attached X release consumption, camera timing reset, shared tuning, multiline HUD and authoritative specs. Removed superseded proposal file and toggle/margin API. Fixed ceiling fixture range by duplicating settings explicitly.
- Decisions: Extension180 px/s, shortening90 px/s, automatic180 px/s, margin40 px (cap360/break400). Down wins over X; Up+Down relaxes/holds. Above-cap attachments never snap down to cap. Physical tension is preserved.
- Files changed: game/gum_connection/game_settings scripts, game scene, verify_controls/gum/camera, keyboard-controls/game-settings/prototype/direction/stage-action/implementation/wrapping/player-controller specs, AGENTS.md, WORKLOG.md.
- Verification: Godot4.5.1 all six suites PASS: controls (/tmp/new-controls.log), gum/camera/gum_path/player/theater_stage (/tmp/new-verify_*.log). Includes real physical keys, independent firing gates, mode priority, dt/rate/bounds, wrapped total length and reciprocal rigid forces. git diff --check PASS. Known unrelated macOS CA certificate warning only.
- Refactoring: Reviewed full input→length→force→camera flow, shared shorten helper, explicit mode commands, clearer per-tick input naming; avoided duplicate authoritative design docs. HUD length help split onto separate line.
- Blockers: None. Native visual/play feel not checked.
- Final verification: Refactored controls/gum/camera suites all PASS exit0 (/tmp/final-controls.log, /tmp/final-gum.log, /tmp/final-camera.log); final diff and git diff --check PASS.
- Next action: F5 playtest Down extension, Up precision shortening, X automatic contraction; tune manual rates/margin in resources/game_settings.tres if needed.

## Completed vertical floor/coyote kick implementation
- Goal/status: Apply approved world-up floor/coyote kicks and bounded vertical gravity compensation; complete.
- Completed: Removed saved floor-normal launch state. Floor/coyote add world-up kick; coyote correction uses only downward external/gravity Y with minimum cap. Collision-projected gravity tracker, contact/friction normals and wall/ceiling priority retained. Specs and durable guidance aligned.
- Files changed: player.gd, verify_player.gd, keyboard-controls/player-controller/game-settings/godot-implementation-plan specs, AGENTS.md, WORKLOG.md.
- Decisions: Preserve existing horizontal/upward/excess downward momentum; no settings changes. Logs distinguish selected kick direction from floor_normal.
- Verification: Full player suite PASS before/after cleanup, final exit0 (/tmp/vertical-refactor.log). Includes actual left/right tilted capsule corner floor/delayed-coyote launches,144 momentum/timing/timestep cases, grace eligibility, continuous-wall floor jumps and corner landing. Physical controls suite with unchanged saved max-length400 fails unreachable-ceiling fixture; temporary duplicated settings max900 passes full suite exit0 (/tmp/vertical-controls-fixture.log); temporary script removed. git diff --check PASS. Known unrelated macOS certificate warning only.
- Refactoring: Named kick_direction separately from collision normals, removed unused coyote_normal and all callers, kept one impulse path and existing gravity projection lifecycle.
- Blockers: None; local Godot4.5.1 verified, native4.7.2 play feel pending.
- Next action: F5 compare stationary left/right box corner jumps and delayed coyote inputs; existing sideways gum/run momentum should remain.

## Completed vertical floor/coyote kick design review
- Goal/status: Analyze consequences of world-up grounded kicks and coyote coupling; complete, runtime unchanged.
- Findings: coyote_normal captures every grounded floor normal including capsule corners. Both coyote impulse and gravity compensation use that normal, so stale corner tilt adds horizontal velocity even after leaving floor; changing impulse alone leaves lateral compensation. For pure110px/s downward gravity and normal(0.302513,-0.953145), compensation adds about31.7px/s horizontally in addition to kick121px/s.
- Recommendation: Separate contact normals from launch direction; world-up floor+coyote impulse and world-up bounded gravity correction. Preserve existing external X/outward/excess downward momentum; keep wall/ceiling contact precedence unless explicitly redesigning it. Review slope clearance/height, edge-to-wall transitions and near-ceiling collisions; vertical impulse does not guarantee vertical trajectory with retained momentum.
- Files changed: WORKLOG.md, AGENTS.md only.
- Verification: Read current normal capture, eligibility, compensation and96-case test matrix. Analytical reasoning only; no engine tests/runtime changes requested.
- Blockers: None for analysis; terrain/slope play feel needs implementation-time regression and playtest.
- Next action: On implementation request, align floor/coyote direction and compensation, update specs/tests and add both corner directions, timed coyote, slope/momentum and wall precedence regressions.

## Completed supplied corner jump log analysis
- Goal/status: Identify diagonal corner launch from supplied Godot4.7.2 log; analysis complete, runtime unchanged.
- Findings: tick536 LightBox corner normal(0.302513,-0.953145),17.609deg from up, multiplied by kick400 produces horizontal+121.0054px/s from zero input/external X. Pre-move launch already(121.0054,-362.9247); no post-move contacts. tick288 left corner similarly produces-14.24452px/s; flat floor ticks219/362 impulse X0. Capsule corner contact normal is used directly by grounded kick. tick219 minor0.0738px side correction from LightBox is separate.
- Decisions: Cause is floor-normal launch policy acting on capsule/box corner contact, not gum, coyote or horizontal input. Geometric origin inferred from capsule/contact coordinates; log directly proves velocity injection. Recommend world-up grounded/coyote kick while retaining existing external momentum and wall/ceiling kick rules if vertical floor jump is desired; slope/coyote compensation policy and regressions must align when implementing.
- Files changed: WORKLOG.md, AGENTS.md only.
- Verification: Compared supplied ACCEPTED/KICK_APPLIED/AFTER_MOVE and current player.gd normal selection/impulse; no runtime changes or engine test required.
- Blockers: Terrain-corner sample absent; supplied corner cases are LightBox.
- Next action: On requested fix, define grounded/slope/coyote launch direction, update implementation/specs and add stationary box-corner regressions in both directions.

## Completed settings baseline update
- Goal/status: Promote current saved settings to script defaults; complete.
- Completed: Matched six overridden defaults to game_settings.tres; aligned settings specification and durable default guidance. Saved resource remains unchanged.
- Decisions: Preserve current runtime tuning and unrelated workspace edits; camera zoom1.2 uses normal decimal notation.
- Files changed: scripts/game_settings.gd, specs/game-settings.md, AGENTS.md, WORKLOG.md.
- Verification: Godot4.5.1 headless comparison PASS for all41 script properties (new Resource versus saved resource), /tmp/settings-baseline.log; git diff --check PASS. Known unrelated macOS certificate warning only. Temporary probe removed.
- Refactoring: Reviewed full settings schema and resource; only six differing defaults required changes, no additional configuration paths or runtime logic.
- Blockers: None.
- Next action: Continue tuning through resources/game_settings.tres as usual.

## Completed corner jump diagnostics
- Goal/status: Add logs identifying diagonal launch from terrain/block corners; complete.
- Completed: KICK_APPLIED records selected normal/angle, kick/compensation, pre/post external and combined launch velocity. Existing jump states include collider paths, contact points/depths, floor/wall normals and actual displacement velocity.
- Decisions: Physics unchanged; existing Jump Diagnostics toggle owns output. Pre-move contact/real-motion fields represent previous move_and_slide. Actual corner cause awaits user reproduction logs.
- Files changed: gd-bungee-gum/scripts/player.gd, specs/game-settings.md, AGENTS.md, WORKLOG.md.
- Verification: Full headless verify_player.gd PASS, exit0 (/tmp/corner-jump.log), including both corner directions, coyote and wall jump cases. New log fields emitted successfully. git diff --check PASS; unrelated macOS certificate warning only.
- Refactoring: Reviewed touched kick/contact logging flow; reused existing diagnostic toggle/events and collision iteration, preserving impulse order and avoiding duplicate normal arrays.
- Blockers: None.
- Next action: F5 reproduce corner jump and inspect/share same-tick ACCEPTED, KICK_APPLIED, AFTER_MOVE lines.

## Completed idle sprite correction
- Goal/status: Replace shrinking idle motion with shallow knee bends; complete.
- Completed: Built-in imagegen edit preserving character identity; normalized four upper-row poses at one0.56 nearest scale, sequenced0/1/2/3/2/1 into existing six-frame layout. Replaced normalized and runtime sheets together. Source original preserved;6fps/runtime controller unchanged.
- Decisions: Feet baseline y232; visible top34/36/40/43/40/36px (maximum2.8px in game); no per-frame height scaling. Final two cells empty. Unrelated workspace edits preserved.
- Files changed: images/normalized/teto_idle.png, gd-bungee-gum/assets/characters/teto_idle.png, specs/character-sprite-audit.md, AGENTS.md, WORKLOG.md.
- Verification: Final sheet visually inspected; Python matching-byte/RGBA/1024×512/six-cell/baseline/empty-cell checks PASS. Godot import completed; verify_player.gd PASS (/tmp/idle-player.log), exit0. git diff --check PASS. Editor sandbox emitted known certificate/Mono socket/editor-settings permission warnings; runtime suite unaffected.
- Refactoring: Reviewed full asset consumption/layout and docs, removed ambiguous scale description; reused existing six-frame resource without new paths or animation machinery.
- Blockers: None; native in-game appearance not inspected.
- Next action: F5 inspect idle motion at gameplay zoom.

## Completed coyote gravity compensation
- Goal/status: Compensate only gravity-acquired inward momentum on coyote kicks; complete.
- Completed: Track gravity velocity during grace, collision-project it, cap normal correction by tracked inward gravity and current inward external speed. Clear tracker on floor/expiry/kick. Actual walk-off expectations and timing/timestep/slope/momentum regressions updated; controller/controls/settings specs aligned.
- Decisions: Preserve tangent, current outward and excess downward external momentum; usual contact kicks unchanged. No added settings; saved user tuning (currently kick400/coyote0.2) preserved. Position is never rewound.
- Files changed: scripts/player.gd, tools/verify_player.gd, specs/keyboard-controls.md, player-controller.md, game-settings.md, AGENTS.md, WORKLOG.md. Other workspace edits preserved.
- Verification: Full Godot4.5.1 headless player suite PASS (/tmp/coyote-compensation.log, final /tmp/coyote-compensation-final.log); no assertion/script errors. Includes96 timing/timestep/normal/external-speed cases, pure-gravity constant normal launch speed, weak-outward clamp, excess downward and tangent retention; real walk-off/expiry/disabled/consumed/no-repeat and wall/corner/momentum regressions pass. git diff --check PASS. Known unrelated macOS certificate warning only.
- Refactoring: Reviewed full gravity/contact/collision lifecycle; one vector tracker uses existing collision normals, no external-force source classification or duplicated impulse paths. Expanded cap coverage and suppressed only combinatorial test diagnostic noise before final rerun.
- Blockers: None; native play feel and user Godot4.7.2 not verified locally.
- Next action: F5 compare early/late coyote inputs after walking off ledges, including while carrying gum momentum.

## Completed coyote launch-height design review
- Goal/status: Evaluate downward-velocity cancellation during coyote kick; analysis complete, runtime unchanged.
- Findings: Player adds gravity before adding kick along remembered floor normal. Current saved tuning kick350/gravity1100/coyote0.2 allows roughly220px/s downward speed to offset kick, leaving130px/s upward; ideal rise from input point falls55.7→7.7px. Player regression currently requires pure additive impulse, so correction must update assertions.
- Recommendation: Compensate the downward normal component attributable to gravity accrued since floor departure before the usual kick; bound compensation by both current inward normal speed and accrued gravity. Preserve tangent momentum, outward speed and excess downward gum/impact momentum. Simpler full downward-normal reset guarantees launch speed but erases externally acquired falling momentum; explicit design tradeoff. Compensate normal grounded gravity too if matching contact-launch speed is required.
- Decisions: No implementation requested. Keep grace single-use, expiration and detach ordering; test early/late departure, slopes, upward/tangent velocity, strong downward momentum and consumed grace on adoption.
- Files changed: WORKLOG.md, AGENTS.md (verified additive behavior note) only.
- Verification: Read current player integration order, shared saved tuning and physics momentum requirements; values are ideal flat-floor estimates, no runtime measurement.
- Blockers: None for design.
- Next action: On implementation request, add bounded gravity compensation accounting and update regression/specs; compare launch speed across grace timings.

## Completed loosen color implementation
- Goal/status: Apply approved LOOSEN #B8A6AD; complete.
- Completed: Added shared Gum Loosen Color; line/pivots/endpoint use mode color regardless of tension. CONTRACT palette and physical width/sag unchanged. Controls/settings docs and durable guidance aligned.
- Files changed: scripts/game_settings.gd, scripts/gum_connection.gd, specs/keyboard-controls.md, specs/game-settings.md, AGENTS.md, WORKLOG.md.
- Decisions: Opaque color; no physics/HUD changes. Existing workspace edits preserved.
- Verification: Original gum suite fails saved-map scenarios with current maximum_length400 (/tmp/loosen-color-gum.log). Temporary duplicate settings with maximum_length900 passes full gum suite plus exact opaque color load check (/tmp/loosen-color-final.log); real resource untouched, temporary script removed. git diff --check PASS. Known macOS certificate warning only. Native visual review not performed.
- Refactoring: Reviewed draw/settings area; explicit mode override keeps one shared color for line/pivots/endpoint and existing tension width, no physics changes. Final suite ran after cleanup of drawing logic.
- Blockers: None.
- Next action: F5 toggle X and review gray loosen line at normal/wide zoom.

## Completed coyote time implementation
- Goal/status: Add floor-departure grace for contact kick-off; complete.
- Completed: Shared Player Movement/coyote_time default0.10s, floor-normal capture, fixed-step countdown, consume-on-any-kick, ACCEPTED_COYOTE and remaining-time logs. Actual platform walk-off regression covers accepted grace, expiry, zero setting, consumed normal kick and repeated-air rejection. Control/controller/direction/implementation/settings docs aligned.
- Decisions: Floor-only grace, additive momentum along last floor normal,0 disables; no extra jump after kick, no wall/ceiling refill or input buffering. Existing Z detach-first ordering and user kick350/max-length400 tuning preserved.
- Files changed: scripts/player.gd, scripts/game_settings.gd, tools/verify_player.gd; specs/player-controller.md, keyboard-controls.md, game-direction.md, stage-action-concept.md, bungee-gum-prototype.md, godot-implementation-plan.md, game-settings.md; AGENTS.md, WORKLOG.md.
- Verification: Full headless player suite PASS before/after refactor (/tmp/coyote-player-final.log, /tmp/coyote-refactor.log), including wall-landing jumps, no air jump, momentum, corner settling and physical key mappings. git diff --check PASS. Local Godot4.5.1; known unrelated macOS certificate warning. First test expected vertical impulse incorrectly; real capsule-edge floor normal is angled, now regression checks captured floor normal as designed.
- Refactoring: Simplified nested kick decision branches; one eligibility calculation shared by log and impulse. Centralized detailed control policy in keyboard-controls; broader specs reference it.
- Blockers: None. Native play feel not checked.
- Next action: F5 walk off ledge and press Z just after departure; tune Coyote Time in shared settings Inspector if desired.

## Completed gum mode visibility review
- Goal/status: Evaluate loosen-mode feedback and subdued gray candidate; review complete, runtime unchanged.
- Findings: Line currently interpolates pink→red solely by tension; width follows tension and sag actual slack. Either CONTRACT or LOOSEN can be taut/slack. Reviewed actual cream/coral/mint atlas and muted teal stage direction.
- Recommendation: Prefer opaque pink-gray #B8A6AD for LOOSEN over blue-violet; low saturation reduces prominence while retaining gum identity. Pure medium gray is a neutral fallback; pale gray risks blending into cream and dark gray into teal. Candidate needs in-game zoomed-out visibility validation; consider a subtle dark outline if terrain overlap is weak. Keep mode hue stable when tension returns, tension in width and slack in sag. Exact colors unvalidated; existing controls spec remains tension-color authority until implementation.
- Files changed: WORKLOG.md, AGENTS.md only; runtime unchanged. Existing active coyote-time work preserved.
- Verification: Read draw/mode/force/HUD/settings/control spec, viewed atlas and checked scene colors. Documentation consistency review; no runtime tests for analysis.
- Blockers: In-game candidate readability untested.
- Next action: If implementing, update shared appearance settings, draw/HUD and aligned specs; verify both modes at zero/high tension and normal/wide camera zoom.

## Completed wall landing jump fix
- Goal/status: Restore jump after continuous wall-to-floor contact; complete; final cleanup rerun passed.
- Completed: Floor contact now restores kick eligibility even with wall contact. Added saved-stage left-wall regression: three floor jumps, each with uninterrupted terrain contact through landing. Existing no-air-jump, momentum and corner regressions preserved. Updated controller/diagnostic specs and durable guidance.
- Decisions: Keep edge-trigger Z, existing impulse and wall/ceiling-only lock. No settings changes in this task; user tuning preserved.
- Files changed: scripts/player.gd, tools/verify_player.gd, specs/player-controller.md, specs/game-settings.md, AGENTS.md, WORKLOG.md.
- Verification: Before fix, new regression rejects second jump with REJECTED_NOT_REARMED and assertion failure (/tmp/wall-jump-before.log). After fix, full player suite PASS (/tmp/wall-jump-after.log). Final cleanup rerun PASS (/tmp/wall-jump-final.log). git diff --check PASS. Local Godot4.5.1; user log4.7.2 not available locally. Known macOS certificate warning only.
- Refactoring: Reviewed full contact/rearm/impulse flow; retained one simple reset condition. Kept manual test simulation owner disabled across both real-tick regressions to avoid interleaved Game simulation.
- Blockers: None; native user-version play feel unverified.
- Next action: F5 repeat jumps while holding toward a wall.

## Completed supplied jump log analysis
- Goal/status: Analyze wall-associated loss of contact kick-off from supplied runtime log; cause confirmed in log and current controller, runtime unchanged.
- Evidence: tick2204 accepts floor+wall kick; AFTER_MOVE remains wall contact and available=false. No rearm before tick2241 landing. tick2248 rejects NOT_REARMED with floor+wall; tick2277 and subsequent requests still reject on floor alone. Eligibility resets only when all floor/wall/ceiling contacts are absent, so continuous wall-to-floor contact latches it false.
- Decision: Ground contact must restore floor kick eligibility independently of full contact loss; preserve edge-trigger Z and no free air impulse. Separate no-contact rejections at ticks560/723 are not this latch failure.
- Files changed: WORKLOG.md and AGENTS.md only; no runtime changes requested in this analysis.
- Verification: Read supplied log and scripts/player.gd eligibility/impulse sequence; no engine test needed for analysis.
- Blockers: None for diagnosis; proposed correction not yet implemented or regression-tested.
- Next action: On implementation, reproduce continuous wall-contact jump/landing on real physics ticks, restore floor eligibility, verify repeated floor jumps and airborne rejection.

## Completed jump diagnostic task
- Goal/status: Add logs for intermittent repeated contact kick-off failure; complete, movement behavior unchanged.
- Completed: Default-ON Jump Diagnostics logs Z request acceptance or no-contact/not-rearmed rejection, post-move state and eligibility rearming. Includes physics tick, feet, floor/wall/ceiling, eligibility, held Z/X, control/external/incoming velocities, collision normals and gum connection after Z detach.
- Decisions: Keep existing contact and impulse rules. Eligibility resets only after a non-contact tick; logs expose that gate without assuming it is the reported cause. Requests use previous move_and_slide contact results. Holding Z does not repeat requests.
- Files changed: scripts/player.gd, scripts/game_settings.gd, specs/game-settings.md, AGENTS.md, WORKLOG.md. Existing workspace changes preserved.
- Verification: Headless verify_player.gd PASS; accepted, after-move, rearm and airborne-rejection output confirmed in /tmp/jump-diagnostic-player.log. verify_controls.gd FAIL on upward gum attachment and dependent X contraction checks (/tmp/jump-diagnostic-controls.log); Z accepted/rearm output confirmed. Current resource maximum_length=400; no gum behavior/settings changes made in this task. git diff --check PASS. Known unrelated macOS certificate warning.
- Refactoring: Reviewed full touched simulation/log flow; isolated formatting in one opt-out helper, no duplicate physics decisions or extra per-frame output. Existing player/control checks exercise physical behavior.
- Blockers: Actual intermittent user event has not been captured.
- Next action: Reproduce with F5 and collect [JumpDiagnostic] lines around failure from Godot Output.

## Completed camera zoom task
- Goal/status: Close normal camera, held-X and gum-path distance zoom-out; complete.
- Completed: Player-centered camera starts at1.5x; X held0.25s requests0.8x; total gum path200–800px interpolates1.5→0.65x. Wider request wins. Exponential response5/s (0 snaps). All seven values in shared Camera Zoom settings. Release resets hold; attach/toggle/cancel input semantics preserved.
- Decisions: Wrapped path length rather than tension/rest length; equal/reversed distance thresholds use step at start. Keep scene limits and position follow. Existing project.godot edit preserved untouched.
- Files changed: scripts/game.gd, game_settings.gd; resources/game_settings.tres; tools/verify_camera.gd; specs/game-settings.md; AGENTS.md; WORKLOG.md.
- Verification: Final headless camera/controls/gum suites PASS (/tmp/camera-{camera,controls,gum}.log); git diff --check PASS. Camera regression covers physical X delay/release, real saved-stage attachment, distance interpolation/clamp, priority, equal thresholds, detach smoothing, timestep subdivision and position follow. Known unrelated macOS certificate warning only.
- Refactoring: Reviewed complete camera/input update ordering and shared settings; isolated presentation helper, simplified threshold handling, no physics changes. Relevant suites rerun after final runtime edit.
- Blockers: None. Native visual/play-feel verification not performed.
- Next action: F5 review camera feel and tune Camera Zoom in resources/game_settings.tres via Inspector.

## Completed landing fix
- Goal/status: Fix repeated lift-off after corner impacts and retain diagnostic logging; complete.
- Changes: Input velocity is refreshed horizontally and keeps only projected X after collision. External sliding/momentum, gum forces, floor contact authority and animations remain physics-driven. Diagnostic logs report collision correction and high-speed landing with incoming velocity/discarded control Y, normals, ground state and gum information; detail throttled30 ticks, existing anomaly persistence logging retained, defaults ON.
- Files: scripts/player.gd; tools/verify_player.gd; removed obsolete tools/diagnose_landing.gd; specs/player-controller.md, godot-implementation-plan.md, game-settings.md; AGENTS.md; WORKLOG.md. Existing unrelated/session edits preserved.
- Verification: Headless player/gum/controls/gum_path/theater_stage suites all PASS; /tmp/landing-fix-*.log. Player regression uses actual physics ticks, both corner directions, releases movement after8 ticks, requires zero control Y throughout and30/30 final grounded ticks plus idle. Mirrored-side recovery floor is test-only to isolate the stage pit. Correction and high-speed landing log output verified. Existing retained air momentum/floor friction checks pass. git diff --check passed; unrelated macOS certificate warning only.
- Refactoring: Reviewed full movement/collision/logging flow and test lifecycle; keep legitimate momentum in external_velocity and horizontal intent in control_velocity, reuse existing logger with explicit event types, remove superseded bug reproducer and stale AGENTS guidance. All relevant checks run after final runtime edits.
- Blockers: None; native play feel remains unverified.
- Next action: F5 try high-speed gum traversal into terrain corners; capture [LandingDiagnostic] from Godot Output if instability recurs.

## Completed landing diagnostic logging
- Goal/status: End investigation without fixing behavior; add runtime logging for recurrence. Complete.
- Completed: Player emits [LandingDiagnostic] on unexpected |control Y|>1 px/s, first6 floor transitions, then every60 physics ticks while persistent, and clearance. Records feet/control/external velocities, ground change/count, animation, landing/fire timers, gum state/reason/tension and collision normals. Normal play is quiet. Shared Diagnostics/Landing Diagnostics setting defaults ON.
- Files changed: scripts/player.gd, game_settings.gd; resources/game_settings.tres; specs/game-settings.md; AGENTS.md; WORKLOG.md. Existing runtime defect intentionally retained.
- Verification: diagnose_landing.gd reproduces unchanged defect and control intervention; /tmp/landing-logging.log contains onset/6 transitions/2 summaries/clearance. verify_player.gd PASS with no diagnostic noise (/tmp/landing-logging-player.log). git diff --check passed; unrelated macOS certificate warning only.
- Refactoring: Logging isolated after animation update, bounded detail events and periodic summaries, same shared settings resource; no physics or animation changes.
- Blockers: None.
- Next action: Stop here as requested; on recurrence collect [LandingDiagnostic] entries from Godot Output or engine log. Fix remains a separate future task.

## Completed persistent landing investigation
- Goal/status: Investigate post-gum foot-tapping / failure to settle; root cause reproduced, runtime unchanged as requested.
- Findings: Player.simulate updates only control_velocity.x, but collision cleanup calls control_velocity.slide(normal), creating persistent control_velocity.y at capsule/step corner impacts. At landing external down velocity is cleared while upward control Y survives; next tick lifts off again, repeatedly resetting landing_time. Grounded comes from engine is_on_floor, not a retained gum flag.
- Reproduction: tools/diagnose_landing.gd, actual physics_frame ticks at 60Hz; saved stage, feet (520,550), control (220,0), external (700,0), right held 8 ticks then released. Corner hits ticks3–4 yield control Y=-47.53929 px/s. Last60 ticks have12 grounded and24 ground/air transitions; gum disconnected and fire_time0 throughout. Clearing ONLY control Y in diagnostic restores30/30 grounded ticks and idle. Foot tapping here is repeated jump/landing frames, not a stuck run flag.
- Files changed: tools/diagnose_landing.gd (repro plus controlled intervention), AGENTS.md, WORKLOG.md. Temporary exploratory probe removed; production code untouched.
- Verification: Godot headless --path gd-bungee-gum --log-file /tmp/landing-diagnosis.log --script res://tools/diagnose_landing.gd PASS/REPRODUCED and control experiment PASS; known unrelated macOS certificate warning. Reviewed diagnostic timing to ensure simulate runs within real physics ticks; git diff --check passed.
- Decisions: Investigate only. A fix should prevent persistent vertical intent velocity while preserving legitimate external collision momentum; do not mask by forcing grounded or merely changing animation.
- Blockers: Exact user's unseen event not captured, but matching persistent landing defect is verified and causally isolated.
- Next action: On fix request, redesign horizontal control collision response, promote this case into verify_player.gd regression, and rerun player/gum/controls/path/map checks.

## Completed incorrect wrap pivot fix
- Goal/status: Fix section-04 shelf contact selecting lower floor and pulling player down; complete.
- Root cause: Geometry2D.is_point_in_polygon classified (2751.99,352) as inside shelf starting x2752; exposed-boundary filtering removed both left shelf corners. Dijkstra then chose lower floor (2753,575), changing tension downward. Saved-map anchor (2742,128), origin moving x2700→2756 at y480 reproduced it exactly.
- Changes/decisions: Use edge-relative convex half-plane containment with scalar cross products for union boundary and visibility midpoint checks. Correct support becomes shelf corner (2751,385). Force model/tuning unchanged. Added translated rectangle near-edge tests and four anchors' sequential saved-map regressions for correct shelf pivots, upward pull and no length jump. Live Game regression verifies actual upward force/external velocity.
- Files changed: scripts/gum_terrain_geometry.gd; tools/verify_gum_path.gd, verify_gum.gd, verify_theater_stage.gd; specs/gum-wrapping.md; AGENTS.md; WORKLOG.md. Temporary probe removed. Prior task's other changes preserved.
- Verification: Final headless gum/path/controls/player/map suites PASS (/tmp/wrap-fix-*.log). Saved map now exposes 62 corners; independent Python rectangle-union quadrant count confirms 62 from 24 rectangles. Prior task's recorded 50 corners was an incorrect extraction missing 12 corners, not the intended map geometry. git diff --check passed. Known macOS certificate warning only.
- Refactoring: Reviewed containment assumptions: registered polygons are convex and normalized counterclockwise; expanded visibility polygons retain this property. One containment helper used for both boundary and visibility, no coordinate-specific workaround.
- Blockers: None. Manual rendered replay of screenshot sequence remains unverified.
- Next action: F5 retest section 04 shelf crossing; expected support is contacted shelf left corner, never lower floor merely from shelf contact.

## Completed gum wrapping implementation
- Goal/status: Implement specs/gum-wrapping.md; complete for static-terrain prototype scope.
- Completed: Collision-derived exposed union corners, ordered pivots, <=1px endpoint-motion sampling (4096 cap), local visibility routing, hysteretic unwrap, total-path spring/damping/length cap, balanced terrain reactions, safe unsupported-obstacle releases, collision-checked slack rendering, pivot/HUD display and first-support animation direction. Inspector wrapping settings added; current specs aligned.
- Decisions: Rectangle/convex-polygon static terrain; dynamic boxes remain endpoints, not pivots. Sampling preserves side through persistent local pivots; subpixel geometry/extreme-speed behavior needs extra validation. Original endpoint/local adhesion, reciprocal forces and release momentum retained.
- Files: scripts/gum_connection.gd, gum_path.gd, gum_terrain_geometry.gd, game.gd, player.gd, game_settings.gd; resources/game_settings.tres; tools/verify_gum_path.gd, verify_gum.gd, verify_controls.gd, verify_theater_stage.gd; specs/gum-wrapping.md, bungee-gum-prototype.md, keyboard-controls.md, godot-implementation-plan.md, physics-foundation.md, game-settings.md; AGENTS.md; WORKLOG.md. Unrelated asset work preserved.
- Verification: Final Godot headless gum/path/controls/player/map suites all PASS; logs /tmp/wrap-{gum,path,controls,player,map}.log. Path suite includes four-sided wrap/unwrap, 300-tick stability, overlapping/shared-edge unions, holes, multiple obstacles, endpoint sweep, deletion, unsupported shapes, both budgets, analytical path speed and terrain force balance. Gum suite covers wrapped loosen, exact release momentum, total-path max, dynamic obstruction and live saved-map shelf wrap/120-tick contraction. Saved map has 50 convex corners; build ~6ms, steady path ~0.25ms/tick in this headless run. git diff --check passed. Known unrelated macOS certificate warning only.
- Refactoring: Kept geometry/path/input/force responsibilities separate, one support_point interface for animation, removed obsolete obstruction-release test reason, clear path/reactions on detach and share root scope for path updates. Full relevant checks rerun after final edits.
- Blockers: None for implementation. Native rendered visual/feel, full-stage clear and render-fps comparisons remain unverified.
- Next action: F5 playtest shelf wrapping/unwrap and tune Gum Wrapping Inspector settings if needed; dynamic-corner wrapping is a separate feature.

## Completed gum wrapping design task
- Goal/status: Redesign obstacle handling as corner wrapping; design complete, runtime unchanged.
- Completed: Added specs/gum-wrapping.md with static terrain union outlines, ordered stable pivots, swept path updates, side-preserving local routing, hysteretic unwrap, total-path spring/damping, balanced terrain reactions, rendering, budgets, phased implementation and acceptance cases.
- Decisions: Static convex terrain corners first; dynamic endpoint boxes retained, dynamic pivot wrapping deferred with explicit unsupported-obstacle release. 900 px applies to total path; no rest-length reset or topology-change impulse.
- Files changed: specs/gum-wrapping.md, godot-implementation-plan.md, physics-foundation.md, bungee-gum-prototype.md, keyboard-controls.md; AGENTS.md; WORKLOG.md. Concurrent food assets/docs preserved.
- Verification: Reviewed force signs and telescoping force balance, no-pivot reduction, runtime-versus-target labels, controls/length semantics, safety failure cases and touched-area structure. git diff --check passed. No runtime tests run for documentation-only changes.
- Blockers: None for design; proposed tolerances/budgets require prototype validation.
- Next action: Implement terrain geometry/path unit checks first, then integrate total-path forces and replace obstruction-release tests per specs/gum-wrapping.md.

## Completed Italian pudding asset task
- Goal/status: Create photo-referenced Italian pudding collectible; complete.
- Completed: Built-in imagegen generation, visible-bounds nearest-neighbor normalization and enlarged final visual review.
- Decisions: 64×64 transparent RGBA; yellow custard, dark caramel cap/pool and white tan-rimmed plate; asset only.
- Files changed: images/foods/italian_pudding.png; specs/food-item-assets.md (final prompt); AGENTS.md; WORKLOG.md.
- Verification: Pillow confirms 64×64 RGBA, alpha 0–255 and transparent corners. Final silhouette/color contrast reviewed. Naming/docs consistency checked; git diff --check passed.
- Blockers: None.
- Next action: Use saved sprite; copy into res:// with nearest filtering when integrating collectibles.

## Completed peperoncino asset task
- Goal/status: Create photo-referenced peperoncino collectible; complete.
- Completed: Built-in imagegen generation, visible-bounds nearest-neighbor normalization and enlarged final visual review.
- Decisions: 64×64 transparent RGBA; yellow spaghetti, golden garlic slices, red chili, green parsley and white patterned bowl; asset only.
- Files changed: images/foods/peperoncino.png; specs/food-item-assets.md (final prompt); AGENTS.md; WORKLOG.md.
- Verification: Pillow confirms 64×64 RGBA, alpha 0–255 and transparent corners. Final silhouette and ingredient colors reviewed. Naming/docs consistency checked; git diff --check passed.
- Blockers: None.
- Next action: Use saved sprite; copy into res:// with nearest filtering when integrating collectibles.

## Completed spinach asset task
- Goal/status: Create photo-referenced sauteed spinach collectible; complete.
- Completed: Built-in imagegen generation, visible-bounds nearest-neighbor normalization and enlarged final visual review.
- Decisions: 64×64 transparent RGBA; dark cooked spinach, bright stems, four bacon pieces and white tan-rimmed bowl; asset only.
- Files changed: images/foods/sauteed_spinach.png; specs/food-item-assets.md (final prompt); AGENTS.md; WORKLOG.md.
- Verification: Pillow confirms 64×64 RGBA, alpha 0–255 and transparent corners. Final food silhouette reviewed. Naming/docs consistency checked; git diff --check passed.
- Blockers: None.
- Next action: Use saved sprite; copy into res:// with nearest filtering when integrating collectibles.

## Completed hamburger steak asset task
- Goal/status: Create photo-referenced hamburger steak collectible; complete.
- Completed: Built-in imagegen generation, visible-bounds nearest-neighbor normalization and enlarged final visual inspection.
- Decisions: 64×64 transparent RGBA; sauced patty, egg, corn, two potatoes, black iron platter and red-brown wooden base; asset only.
- Files changed: images/foods/hamburger_steak.png; specs/food-item-assets.md (final prompt); AGENTS.md; WORKLOG.md.
- Verification: Pillow confirms 64×64 RGBA, alpha range 0–254 and transparent corners; final silhouette and food arrangement reviewed. Naming/docs checked; git diff --check passed.
- Blockers: None.
- Next action: Use saved sprite; copy into res:// with nearest filtering when integrating collectibles.

## Completed automatic gum release investigation
- Goal/status: Explain releases without manual detach; complete, runtime unchanged.
- Findings: validate_connection releases on straight-line obstruction (including a different face of the same terrain body), distance >900 px, or target deletion. Obstruction ray ends 3 px before anchor; no wrapping. Tension cap does not break gum. HUD preserves OBSTRUCTED / TOO FAR / TARGET LOST until later action.
- Files changed: WORKLOG.md; AGENTS.md.
- Verification: Headless verify_gum.gd passed, including obstruction/maximum-length/deleted-target cases; log /tmp/gum-release-investigation.log. Existing macOS certificate warning only. Reviewed code/spec agreement; exact user-observed trigger cannot be identified without HUD reason or reproduction.
- Blockers: None for explanation.
- Next action: Read HUD release reason at observed event; if changing behavior, decide obstacle handling and maximum-length rules first.

## Completed tarako pasta asset task
- Goal/status: Create photo-referenced Sicilian-style tarako pasta collectible; complete.
- Completed: Built-in imagegen generation, visible-bounds nearest-neighbor normalization and enlarged final visual review.
- Decisions: 64×64 transparent RGBA; yellow pasta, pink sauce, dark shredded nori and white patterned bowl; asset only.
- Files changed: images/foods/tarako_pasta.png; specs/food-item-assets.md (final prompt); AGENTS.md; WORKLOG.md.
- Verification: Pillow confirms 64×64 RGBA, alpha 0–255 and transparent corners. Final preview checked for distinct pasta/sauce/nori. Naming/docs reviewed; git diff --check passed.
- Blockers: None.
- Next action: Use saved sprite; copy into res:// with nearest filtering when integrating collectibles.

## Completed margherita pizza asset task
- Goal/status: Create photo-referenced buffalo mozzarella margherita collectible; complete.
- Completed: Built-in imagegen generation, visible-bounds nearest-neighbor normalization and enlarged final visual review.
- Decisions: 64×64 transparent RGBA; whole pizza on white plate, red sauce and five white mozzarella patches. Lifted slice omitted for compact silhouette; asset only.
- Files changed: images/foods/margherita_pizza.png; specs/food-item-assets.md (final prompt); AGENTS.md; WORKLOG.md.
- Verification: Pillow confirms 64×64 RGBA, alpha 0–255 and transparent corners; final preview checked. Reviewed naming/docs consistency; git diff --check passed.
- Blockers: None.
- Next action: Use saved sprite; copy into res:// with nearest filtering when integrating collectibles.

## Completed game settings task
- Goal/status: Explain faint X guide and centralize editor tuning; complete.
- Findings/decisions: Guide alpha was hardcoded to 0.25 at width 1 px in Gum._draw. Game Settings now groups player movement/friction/mass, gum physics, aim guide, gum colors/width and restart Y; guide defaults alpha 0.9, width 2 px. Explicit values stored in .tres.
- Files: gd-bungee-gum/scripts/game_settings.gd (+preserved UID), resources/game_settings.tres replace gum_settings files; scripts/player.gd, game.gd, gum_connection.gd; scenes/game.tscn and characters/player.tscn; tools/verify_player.gd and verify_gum.gd; specs/game-settings.md, player-controller.md, bungee-gum-prototype.md, godot-implementation-plan.md; AGENTS.md, WORKLOG.md.
- Verification: Godot headless player/gum/controls suites passed. Final player check also verifies shared Resource identity and changed run_speed actually affecting movement. Logs /tmp/settings-{player,gum,controls}.log. git diff --check passed; no obsolete gum_settings references in current runtime/specs. Known sandbox certificate warning only. Visual feel not assessed.
- Refactoring: One typed shared schema; Game assigns its resource to both systems, standalone player scene uses same default asset. Removed duplicated tuning exports and stale timing comments; updated callers/docs, no compatibility paths.
- Blockers: None. Existing food/friction work preserved.
- Next action: In Godot select res://resources/game_settings.tres, edit Inspector groups, save and rerun F5; see specs/game-settings.md.

## Completed shrimp salad asset task
- Goal/status: Create shrimp salad collectible in images/foods/; complete.
- Completed: Built-in imagegen generation/refinement, clean cutout regeneration, visible-bounds nearest-neighbor normalization and final enlarged visual review.
- Decisions: 64×64 transparent RGBA; pink shrimp, lettuce, two tomatoes, cabbage and white patterned bowl; asset only.
- Files changed: images/foods/shrimp_salad.png; specs/food-item-assets.md (final prompt); AGENTS.md; WORKLOG.md.
- Verification: Pillow confirms 64×64 RGBA, alpha 0–255 and transparent corners; final silhouette reviewed. Naming/docs reviewed; git diff --check passed.
- Blockers: None.
- Next action: Use saved sprite; future Godot integration copies into res:// with nearest filtering.

## Completed ground-friction investigation
- Goal/status: Investigate and fix persistent sliding after landing; complete.
- Findings/decision: External horizontal velocity had no floor friction (retained velocity, not retained acceleration). Apply 900 px/s² tangent deceleration after move_and_slide/collision cleanup, including landing tick; preserve airborne momentum. Ground contact comes from the completed move, so departing kick-offs are excluded naturally.
- Files changed: gd-bungee-gum/scripts/player.gd, gd-bungee-gum/tools/verify_player.gd; specs/player-controller.md, specs/godot-implementation-plan.md; AGENTS.md; WORKLOG.md. Existing food asset changes preserved.
- Verification: Godot 4.5.1 headless verify_player.gd passed both sliding directions, gradual stop, air retention and landing alongside existing movement/collision checks; verify_gum.gd and verify_controls.gd passed. Logs: /tmp/friction-{player,gum,controls}.log. Only known sandbox certificate warning. git diff --check passed.
- Refactoring: Isolated floor-tangent damping in _apply_ground_friction; reviewed fixed-step ordering and docs. Removed a redundant normal-velocity gate: tiny floor collision normal differences could otherwise skip friction. Final runtime checks passed after simplification.
- Blockers: None; interactive feel not assessed.
- Next action: F5 playtest stopping distance and tune exported ground_friction if desired.

## Completed chicken asset task
- Goal/status: Create photo-referenced diavola chicken collectible in images/foods/; complete.
- Completed: Built-in imagegen generation, nearest-neighbor normalization and enlarged final visual inspection.
- Decisions: 64×64 transparent RGBA static sprite; chicken/onion topping, corn, two potatoes, black platter and red-brown base; asset only.
- Files changed: images/foods/chicken_diavola.png; specs/food-item-assets.md (final prompt included); AGENTS.md; WORKLOG.md.
- Verification: Pillow confirms 64×64 RGBA and transparent corners; alpha range 0–255. Final preview checked for readable food/platter silhouettes. Reviewed naming and documentation consistency; git diff --check passed.
- Blockers: None.
- Next action: Use saved asset; copy into res:// with nearest filtering when integrating collectibles.

## Completed escargot asset task
- Goal/status: Create photo-referenced escargot collectible in images/foods/; complete.
- Completed: Built-in imagegen generation; nearest-neighbor normalization; inspected enlarged final sprite with six wells and herb butter.
- Decisions: 64×64 transparent RGBA static sprite matching food asset convention; outer white serving plate omitted. Gameplay integration outside scope.
- Files changed: images/foods/escargot_oven_baked.png; specs/food-item-assets.md (including final prompt); AGENTS.md; WORKLOG.md.
- Verification: Pillow confirms 64×64 RGBA, alpha range 0–255 and corner alpha0/0/1/0 (nearly transparent); faint low-alpha peripheral pixels retained; final visual review passed. Reviewed naming/docs for consistency; git diff --check passed.
- Blockers: None.
- Next action: Use saved sprite; copy into res:// with nearest filtering when integrating collectibles.

## Completed food asset task
- Goal/status: Create the supplied Milan-style doria as a collectible pixel-art PNG; complete.
- Completed: Generated and refined using built-in imagegen; normalized with nearest-neighbor sampling; visually inspected enlarged final sprite.
- Decisions: 64×64 transparent RGBA static sprite, oval terracotta dish, cheese/meat sauce, no spoon/tray. Asset only; existing control implementation work untouched.
- Files changed: images/foods/milano_doria.png; specs/food-item-assets.md (including final prompt); AGENTS.md; WORKLOG.md.
- Verification: Pillow confirms 64×64 RGBA, transparent corners and alpha range 0–255. Final enlarged preview reviewed for readable silhouette. Reviewed asset naming/documentation; git diff --check passed.
- Blockers: None.
- Next action: Use the saved sprite; future gameplay integration copies it into Godot res:// and uses nearest filtering.

## Completed Z/X implementation
- Goal/status: Apply approved keyboard controls; complete.
- Completed: Physical Z jump/detach and X aim/release-to-fire; normalized retained eight-way aim; aim movement suppression; auto-contract on attach; fixed-length loosen (+32px)/contract toggle; canceled/broken toggle gestures wait for X release; Z priority; HUD and authoritative docs aligned. Proposal promoted to specs/keyboard-controls.md.
- Decisions: Air Z preserves momentum without impulse; contact Z detaches before kick-off. A/D remain movement aliases outside aim. Removed obsolete mouse/Space/E actions and boolean step(contract) interface; all callers updated.
- Files changed: project.godot; scenes/game.tscn; scripts/game.gd, gum_connection.gd, gum_settings.gd, player.gd; tools/verify_controls.gd (+UID), verify_gum.gd, verify_player.gd; specs/keyboard-controls.md (replaces proposal), bungee-gum-prototype.md, game-direction.md, stage-action-concept.md, godot-implementation-plan.md, player-controller.md; AGENTS.md; WORKLOG.md. Concurrent food asset work preserved.
- Refactoring: Separate gesture/status/aim-target helpers; separate connection validation and mode toggle from force integration; one fixed-step owner and mode independent of tension. Player owns aim facing, initial aim follows facing at first selection.
- Verification: Final verify_controls.gd passed physical Z/X, all eight directions, opposing/neutral aim retention, movement suppression, release shot, auto-contract, toggle/hold, air release/ground kick, Z priority, canceled/broken gesture safety and miss. verify_gum.gd passed physics/live Game regression plus regained tension in loosen mode. verify_player.gd and verify_theater_stage.gd passed. git diff --check passed. Only known sandbox certificate warnings. Interactive visual/feel verification not performed.
- Blockers: None.
- Next action: F5 playtest Z/X controls; tune loosen_margin and contraction after feel review. Stage checkpoints/clear progression remain future work.

## Completed Z/X control specification review
- Goal/status: Evaluate requested two-button controls; specification proposal complete, runtime unchanged.
- Completed: Added state/action table, eight-direction release-to-fire aiming, automatic contraction, explicit loosen/contract mode, Z detach/contact kick-off, input ownership/priority/cancellation and acceptance cases.
- Decisions: Recommended airborne Z releases with retained momentum, without adding a free air jump. Loosen mode extends rest length once to current distance+32 px (bounded), then holds it, allowing tension to return for swings. Toggle mode is independent of physical slack. These are proposals, not implementation changes or confirmed final choices.
- Files changed: specs/keyboard-controls-proposal.md; reference in specs/bungee-gum-prototype.md; AGENTS.md; WORKLOG.md.
- Verification: Reviewed against current spring code and game/stage/implementation specs; explicitly identified design statements to update on adoption. Reviewed full proposal for consistent edge-trigger behavior and physical invariants; git diff --check passed. No runtime tests needed for document-only changes.
- Blockers: None.
- Next action: On adoption, implement input gesture state and contraction mode; update all authoritative control docs, HUD and tests. Current executable retains mouse/Space/E controls.

## Completed Bungee Gum action
- Goal/status: Implement one physics-based gum connection; complete for player action prototype.
- Completed: Mouse aim, LMB attach, hold RMB contraction, E/MMB release; local endpoint tracking, unilateral damped spring, equal/opposite rigid force, retained player momentum; max-length/deletion/occlusion release; tension line/reticle/HUD; gum fire/pull/hang poses with drawing-only hand offsets; light/heavy boxes at entrance and section markers.
- Decisions: Game owns input→gum force→Player.simulate→camera/HUD; Player no longer self-updates. Settings Resource assigned through scene property. R reconstructs entire current map; section checkpoints, combat/exit and full-map traversal acceptance remain future work.
- Files changed: project.godot, player/game scripts/scenes; gum_connection.gd, gum_settings.gd, resources/gum_settings.tres, scenes/props/gum_box.tscn, tools/verify_gum.gd and engine UIDs; specs/bungee-gum-prototype.md, player-controller.md, character-gum-animations.md, godot-implementation-plan.md; AGENTS.md and WORKLOG.md.
- Refactoring: Moved hand samples into constants, separated HUD formatting, constrained settings inspector ranges, kept physics and visual origins distinct; cancel firing pose on connection release. Input device=16 did not match local Godot 4.5 events; changed existing bindings to any-device (-1) and reran physical-key checks without changing assigned keys.
- Verification: Final gum check passed: mouse bindings/release, terrain/dynamic rays, blocked targets, slack, contraction/hold, force cap, exact detach momentum, occlusion, max length, rotating local point and angular point velocity, equal/opposite force, light/heavy real rigid acceleration, off-center torque, deleted target, 180-tick swing, live Game ceiling lift/poses/detach. Player regression and map checks passed; git diff --check passed. Only unrelated sandbox certificate warnings in headless runs. Native rendered preview could not launch in sandbox (exit 134); actual screen appearance/feel remains unverified.
- Blockers: None for action implementation.
- Next action: F5 playtest: aim at ceiling and LMB, hold RMB, release with E to swing/fly; compare mint/light and coral/heavy entrance boxes. Tune settings after playtest; add section checkpoints and stage-clear progression separately.

## Completed arrow-key fix
- Goal/status: Correct left/right arrows while preserving A/D; complete.
- Completed: Set physical Left=4194319, Right=4194321 in project.godot. Updated player comments and AGENTS guidance. Added physical-event regression checks for A/D, both arrows and PageUp exclusion.
- Decisions: Movement tuning and momentum behavior remain unchanged.
- Files changed: project.godot, scripts/player.gd, tools/verify_player.gd, AGENTS.md, WORKLOG.md.
- Refactoring: Reviewed affected input/comments; press and release use distinct InputEventKey instances to follow Godot event ownership requirements.
- Verification: Final headless player check passed (physical key mappings, spawn, animation, air-jump rejection and wall momentum cleanup); git diff --check passed. Only unrelated sandbox certificate warning emitted.
- Blockers: None.
- Next action: Run F5 and verify arrow controls interactively.

## Latest movement investigation
- Goal/status: Investigate horizontal movement and add script comments; complete. Runtime behavior unchanged.
- Findings: OS.get_keycode_string confirms 4194321=Right and 4194323=PageUp: current physical arrow bindings disagree with HUD. A/D works. Reversing input at +220 leaves +193.3 px/s on the first tick while facing instantly flips left. External +300 persists without input; left control -220 still results in rightward +80. Parent camera update precedes child player update.
- Files changed: scripts/player.gd and game.gd comments; AGENTS.md; WORKLOG.md. Temporary movement probe removed.
- Verification: Headless movement probe measured input reversal, release and injected external momentum. Final player check passed; git diff --check passed. Reviewed comments for accuracy and duplication; no runtime refactor needed for this comment-only task. Existing check uses action_press and cannot detect physical key mapping errors. Sandbox certificate warning remains unrelated.
- Blockers: None. No interactive visual check performed.
- Follow-up: Arrow bindings corrected and verified in the completed fix above.

## Latest completed task
- Goal: Implement playable Teto with idle, run and contact kick-off/jump animation.
- Status: Complete.
- Completed: Added reusable feet-origin CharacterBody2D scene, normalized project sprite copies, state-driven animation, steering/external momentum, collision cleanup, contact kick-offs, gameplay wrapper, follow camera and restart. F5 starts gameplay; preview remains available through its own scene.
- Decisions: Short contact kick-off only; gum remains outside this task. Jump poses follow actual vertical velocity. Static capsule stays independent of animation.
- Files changed: AGENTS.md; project.godot; scripts/player.gd, game.gd, map_preview.gd; scenes/characters/player.tscn, scenes/game.tscn; assets/characters/*; tools/verify_player.gd; specs/player-controller.md, character-sprite-audit.md.
- Refactoring: Reviewed controller/state responsibilities, reused axis handling and fixed collision shape, constrained exported mass, removed stale preview comment.
- Verification: Godot 4.5.1 headless player check passed after final review (spawn, floor alignment, idle/run/jump/landing, air-jump rejection, wall momentum cleanup). Existing map check passed (1222 tile centers, 24 shapes, six clear markers). git diff --check passed. Editor import completed; sandbox produced unrelated certificate/editor settings/Mono IDE socket errors. Interactive visual playback has not been checked.
- Blockers: None.
- Next action: Play F5 to review animation feel/scale; future work can implement gum physics using the external-force integration point. Full stage traversal awaits gum implementation.

## Completed gum animation assets
- Goal/status: Add firing, pulled and hanging poses; complete as assets.
- Completed/files: Three generated originals in `images/gum-source/`, normalized eight-frame sheets in `images/normalized/`, matching project copies and `gum_animations.tres` in `gd-bungee-gum/assets/characters/teto/`; `specs/character-gum-animations.md`, sprite audit and AGENTS guidance.
- Decisions: Separate gum line; physics controls motion; right-facing pose candidates. Existing player controller was added concurrently; these gum assets are not wired to its animation states.
- Verification: Built-in imagegen outputs and normalized hanging sheet inspected; Pillow checks passed (1024×512 RGBA, 8 occupied cells, transparent gutters, identical copies). Godot import and temporary resource check passed (3 animations × 8 frames, loop flags correct). Final resource/spec review and git diff --check passed. Sandbox certificate/Mono/settings and font-cache warnings were non-blocking. Temporary verification script removed.
- Blockers: None for assets; hand offsets, directional variants and loop polish require gameplay integration.
- Next action: Preview SpriteFrames, then integrate with gum physics and existing player state machine.
