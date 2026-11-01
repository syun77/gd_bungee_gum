# Work Log

## Active chicken asset task
- Goal: Create photo-referenced diavola chicken collectible in images/foods/.
- Status: Generating.
- Completed: Read food asset conventions and inspected photo.
- Decisions: 64×64 transparent sprite; chicken/onion topping, corn, potatoes and black platter on red-brown base.
- Files changed: WORKLOG.md.
- Verification: Pending.
- Blockers: None.
- Next action: Generate, normalize and inspect final sprite.

## Completed escargot asset task
- Goal/status: Create photo-referenced escargot collectible in images/foods/; complete.
- Completed: Built-in imagegen generation; nearest-neighbor normalization; inspected enlarged final sprite with six wells and herb butter.
- Decisions: 64×64 transparent RGBA static sprite matching food asset convention; outer white serving plate omitted. Gameplay integration outside scope.
- Files changed: images/foods/escargot_oven_baked.png; specs/food-item-assets.md (including final prompt); AGENTS.md; WORKLOG.md.
- Verification: Pillow confirms 64×64 RGBA, alpha range 0–255 and four transparent corners; final visual review passed. Reviewed naming/docs for consistency; git diff --check passed.
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
