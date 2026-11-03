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
