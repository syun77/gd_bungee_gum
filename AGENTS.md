# Repository Instructions

## Project identity

- This repository is a game project built with Godot Engine.
- The game's central theme is "Bungee Gum," the Nen ability from *Hunter x Hunter*. Use this theme as a guiding constraint for gameplay mechanics, presentation, terminology, and specification decisions.
- Model Bungee Gum primarily as a consistent connection-and-tension system, not as a collection of unrelated special moves. Its core interaction loop is attach, build tension, then contract or detach.
- Preserve the coexistence of adhesion and elasticity, player-controlled timing, reciprocal force between endpoints, environmental interaction, and player-discovered applications across movement, combat, defense, and restraint.
- Treat `specs/bungee-gum-analysis.md` as the current thematic and mechanical foundation for future gameplay specifications.
- Physics-engine simulation is a non-negotiable thematic foundation, not an optional presentation feature. Use a hybrid architecture in which game rules own connection state and safety limits while the physics engine resolves mass, momentum, forces, gravity, and collisions.
- Preserve reciprocal forces, retained momentum after release, and emergent interaction with dynamic objects and terrain. Do not replace the core with canned animations or separate scripted outcomes for each use case.
- Treat `specs/physics-foundation.md` as the current authority for physics architecture and prototype acceptance criteria.
- Build the game as a side-view, stage-clear 2D physics action game. Integrate physical puzzles into traversal; puzzles, traversal, and combat must use the same attachment, tension, contraction, and release rules rather than separate modes.
- Use `CharacterBody2D` for the responsive player controller and explicitly integrate gum forces as persistent external momentum. Use `RigidBody2D` for dynamic world objects and apply the reciprocal gum force to them.
- Do not provide a free conventional jump. Use short surface-contact kick-offs to seed swings and tension while keeping gum traversal mandatory.
- Begin with one active gum connection, ray-based aiming, explicit attach/contract/detach controls, visible tension, and instant section restart. Defer multiple connections, complex enemies, progression systems, and large maps until the core prototype passes its acceptance criteria.
- Treat `specs/game-direction.md` as the current authority for genre, viewpoint, core loop, control model, level structure, and prototype scope.
- Treat `specs/stage-action-concept.md` as the current authority for stage flow, movement vocabulary, combat integration, enemy and gimmick roles, scoring, and reference-game synthesis.
- Use `specs/godot-implementation-plan.md` for the Godot prototype architecture, attachment-point tracking, collision-aware external velocity, and staged verification plan.

## Durable project knowledge

- Food collectible art lives in `images/foods/`; `milano_doria.png`, `escargot_oven_baked.png`, `chicken_diavola.png`, `shrimp_salad.png`, `spicy_chicken.png`, `margherita_pizza.png`, `tarako_pasta.png`, `hamburger_steak.png`, `sauteed_spinach.png`, `peperoncino.png`, and `italian_pudding.png` are 64 × 64 transparent RGBA static sprites. Use nearest-neighbor filtering; see `specs/food-item-assets.md`.

- Current setting/art direction is a pop-colored family restaurant: cream ceramic, coral/mint trim, painted frames and muted teal background. `theater_*` filenames remain the current resource identifiers. Edit both atlas copies together (`images/tilesets/` and `gd-bungee-gum/assets/tilesets/`); `restaurant_tileset_source.png` is the color-edit source.

- The first editable map is `gd-bungee-gum/scenes/stages/theater_stage.tscn` (160 × 24 cells, 32 px grid). F6 opens the stage alone; F5 opens mode selection. In Stage Mode, the restaurant card starts `scenes/game.tscn` with the Teto player (A/D or arrows, Z for detach/contact kick-off, R for restart). Open `scenes/map_preview.tscn` with F6 for arrows to pan, 1–6 to select a section and Tab for overview.
- Ordinary map layers have collision disabled (except native one-way `OneWayPlatforms`); `TheaterStage/Terrain` owns merged rectangular static shapes on physics layer 1. When editing terrain tiles, update matching shapes and outline nodes together. `tools/build_theater_stage.gd` regenerates the scene/TileSet and overwrites manual edits; run only intentionally.
- Local Godot executable: `/Applications/Godot_mono.app/Contents/MacOS/Godot` (4.5.1). For sandboxed headless runs, use `--log-file /tmp/<task>.log` to avoid a crash writing default user logs. Run the saved-map collision check with `--headless --path gd-bungee-gum --log-file /tmp/map-check.log --script res://tools/verify_theater_stage.gd`.

- `images/tilesets/theater_tileset.png` is a 512 × 512 RGBA manual-placement atlas (32 px cells, 16 columns, 105 occupied cells). See `specs/theater-tileset-assets.md` and `specs/theater-tileset-atlas.json`; 47-pattern autotiling and seamless joins are not yet validated.

- `specs/tileset-specification.md` defines the proposed initial tileset art direction, 32 px grid, asset separation, and visual acceptance checks; scale and stage dimensions remain subject to prototype validation.

- The Godot project root is `gd-bungee-gum/`; open `gd-bungee-gum/project.godot` in Godot and place engine project files under that directory.
- Image assets are stored in the repository-root `images/` directory. Consult this directory when selecting or integrating game visuals.
- Character references: `images/original/teto.png` is the original front view; original idle/run/jump references are also under `images/original/`, and runtime-ready sheets are under `images/normalized/`. See `specs/character-sprite-audit.md` for measured sizes and slicing issues before integration. Root-level `images/` is outside Godot’s `res://`.

- Gum poses: `images/normalized/teto_gum_{fire,pull,hang}.png` and matching Godot copies under `assets/characters/teto/`; `gum_animations.tres` provides three eight-frame animations. See `specs/character-gum-animations.md`; poses do not drive physics.

- Normalized Teto animation candidates live in `images/normalized/`: 1024 × 512 RGBA sheets, 4 × 2 cells of 256 px. Idle uses the first six cells; run/jump use eight. Ground baseline is cell y=232; see the sprite audit for generation caveats.

- During every task, proactively record durable, repository-specific knowledge in this `AGENTS.md` as soon as it is verified and likely to help future work.
- Examples include required commands, architectural constraints, non-obvious conventions, recurring pitfalls, and user preferences that apply to this repository.
- Keep entries concise, actionable, and generally applicable. Do not add guesses, temporary task state, information already obvious from the code, or duplicated guidance.
- Never record secrets, credentials, tokens, personal data, or other sensitive values.
- If later evidence invalidates an entry, update or remove it immediately instead of appending contradictory guidance.

- Gum fixed-step owner is `scripts/game.gd`: input → `Gum.step` → `Player.simulate` → camera/HUD. Player has no independent physics callback. Tune `resources/game_settings.tres`; attachable terrain/props/anchor tiles use physics bits1/4/16, player is bit2. Keep reciprocal forces and collision momentum cleanup together.
- Gum controls: arrows continuously select eight-way direction, X press fires and arrival starts auto-contract next tick; attached Down relaxes/extends, Up manually shortens only while relaxed, X starts automatic contraction (no-op while already contracting); Z while attached detaches then world-up jumps regardless of contact/rearm: cancel downward external velocity including current gravity, retain upward/horizontal velocity and add kick_speed. Game snapshots validated attachment before detach and passes it to Player.simulate; unattached contact/coyote rules remain. `tools/verify_controls.gd` exercises physical Z/X gestures and cancellation. `tools/verify_gum.gd` covers real ray queries, rigid force/mass response and live Game integration. Input bindings use device -1 (any device); editor-saved device 16 bindings do not match Godot 4.5 synthetic keyboard events.
- Assign the gum settings Resource through the scene's exported property; preloading its instance as a typed script property's default caused uninitialized Resource script values under Godot 4.5.1.

- `specs/keyboard-controls.md` is the implemented Z/X control authority. X only acts on press edges; held/released X never fires after connection loss or return. All pre-attachment held Up/Down, including presses during flight, wait for release before length control. Relaxed mode holds natural length when manual input stops.

## Persistent progress and session recovery

- Use the repository-root `WORKLOG.md` as the durable handoff and recovery record for all work.
- At the start of every task, read `WORKLOG.md` before making changes and resume any relevant unfinished work from it.
- Save a checkpoint after every meaningful unit of work, including important discoveries, decisions, edits, and verification results. Do not wait until the end of the session.
- Before any likely interruption, context compaction, handoff, or end of session, update `WORKLOG.md` so another session can continue without relying on chat history.
- Each active-task checkpoint must state: the goal, current status, completed work, key decisions or assumptions, files changed, commands/tests and their results, blockers, and the exact next action.
- Keep the active entry current rather than accumulating a noisy transcript. Preserve concise summaries of completed tasks only when they remain useful.
- Do not put secrets, credentials, tokens, personal data, or large command outputs in `WORKLOG.md`.
- Progress recording is mandatory, but it does not replace normal source control or verification.

## Development policy

- Before creating or extending a tool for this repository, read and follow `.agents/ツール作成.md` for implementation, editor interactions, file handling, and verification.

- This project is under active development and does not require backward compatibility. Prefer the best current design, including breaking changes, over compatibility shims, deprecated paths, or preservation of obsolete APIs.
- When changing a design or interface, update every affected implementation, caller, test, configuration, fixture, asset, and document to the new form in the same task. Do not leave mixed old and new patterns behind.
- Implement the solution judged best for the current codebase rather than minimizing the diff. Remove superseded code and stale compatibility machinery when it is safe and in scope.
- Comments and documentation must describe only the current behavior and rationale. Remove migration notes, change-history comments, commented-out old code, and explanations framed around the previous implementation; source control is the history.
- Every implementation task must include a final refactoring phase after the feature or fix is functionally complete. In that phase, review the full touched area for simpler structure, clearer naming, duplication, dead code, consistent interfaces, and alignment with current conventions, then run the relevant verification again.

## Specifications

- Store all project specification documents in the repository-root `specs/` directory. Create or update specifications there rather than placing them beside source files or in ad hoc documentation locations.
- Keep specifications aligned with the current implementation whenever behavior or interfaces change.


- Player feet are the local origin; `scenes/characters/player.tscn` uses normalized 256 px cells at 0.3125 scale, a fixed 20 × 52 px capsule and sprite y=-32.5. `tools/verify_player.gd` checks movement/animation and collision momentum using the same headless invocation as the map check.

- Physical arrow bindings in project.godot are Left=4194319 and Right=4194321. `tools/verify_player.gd` checks physical-key events as well as action-driven movement; action_press alone bypasses key mappings.

- Player floor friction is explicit: after move_and_slide/collision cleanup, ground_friction (900 px/s²) reduces external velocity along the floor tangent. Air momentum remains intact; CharacterBody2D does not provide automatic material friction. verify_player.gd covers both sliding directions and landing/air preservation.

- Shared runtime tuning lives in `resources/game_settings.tres` (schema: `scripts/game_settings.gd`), grouped for the Inspector. Game.Settings is assigned in game.tscn and passed to Player/Gum at ready; standalone Player has the same default asset. Aim Guide colors include alpha (0.9) and line width (2 px). See specs/game-settings.md.



- Static corner wrapping is implemented in `gum_path.gd` / `gum_terrain_geometry.gd`; see specs/gum-wrapping.md. Collision-derived union corners (59 in saved stage), ordered pivots, <=1px endpoint sweep, total-path spring/length limit and terrain reactions. Dynamic obstacle wrapping is unsupported and releases explicitly. Run tools/verify_gum_path.gd alongside gum/controls/player/map suites.

- Wrapping geometry uses edge-relative convex half-plane containment: Geometry2D.is_point_in_polygon misclassified near-edge points at section-04 coordinates, dropping valid shelf corners. Keep translated-shape, large-coordinate shelf and saved-map beam pivot regressions in verify_gum_path.gd.



- Normal locomotion input velocity stays horizontal, including after collision projection; ladder climbing explicitly supplies vertical control; external velocity retains physical sliding/momentum. verify_player.gd covers both high-speed corner directions on actual physics ticks and stable landing.
- Landing Diagnostics defaults OFF: [LandingDiagnostic] logs CONTROL_COLLISION_RESOLVED / HIGH_SPEED_LANDING (30-tick detail throttle), plus persistent unexpected control-Y diagnostics; includes incoming/control/external velocity, discarded Y, normals and gum state. See specs/game-settings.md.

- Runtime camera zoom is owned by Game._update_camera after Player.simulate; Camera Zoom settings control normal/path-length scales, distance thresholds and exponential response. Uses wrapped total path length; X does not change zoom. Verify with tools/verify_camera.gd.

- Jump Diagnostics defaults OFF: `[JumpDiagnostic]` logs each Z request (ACCEPTED / REJECTED_NO_CONTACT / REJECTED_NOT_REARMED), AFTER_MOVE and pre-reset REARMED state. Contact eligibility resets on floor contact or a fully non-contact tick; request contact uses previous move_and_slide results. Toggle in shared Diagnostics settings; see specs/game-settings.md.

- Floor kick eligibility recovers on floor contact even with continuous wall contact; wall/ceiling-only contact does not rearm. verify_player.gd checks three consecutive jumps on saved-stage left wall without any fully non-contact tick.

- Gum LOOSEN color is opaque pink-gray #B8A6AD independent of tension (Gum Loosen Color); CONTRACT retains pink→red tension colors. Line/pivots/endpoint share color; width follows tension and sag actual slack. Either mode can be taut or slack.

- Floor coyote grace uses shared Player Movement/coyote_time (default0.20s,0 disables), world-up kick and fixed-step countdown. Any successful contact/coyote kick consumes it; wall/ceiling do not refill. verify_player.gd covers walk-off/expiry/disabled/consumed/no-repeat cases. JumpDiagnostic includes coyote seconds and ACCEPTED_COYOTE.

- User prefers subdued gray-like loosen feedback over prominent blue-violet.

- Coyote kicks cancel only accumulated downward gravity velocity along world up, capped by current downward external speed, before adding kick_speed. coyote_gravity_velocity follows collision projection and resets on floor/expiry/kick; horizontal, upward and excess downward external momentum remain. verify_player.gd covers delay/timestep/horizontal-and-vertical-speed combinations.

- Idle sheet uses six-frame shallow knee-bend ping-pong poses (0/1/2/3/2/1),6fps; keep normalized/runtime copies identical, baseline y232 and one common scale across poses. See specs/character-sprite-audit.md.

- Corner-jump diagnostics use existing Jump Diagnostics: KICK_APPLIED records selected normal/angle and exact launch velocity changes; ACCEPTED/AFTER_MOVE include collider paths, contact points/depths and real displacement. Contact/real-motion fields before movement describe the previous move_and_slide result.

- Settings schema kick_speed is400 (current saved tuning400); other documented baseline values: coyote_time0.2, maximum_length400, camera_long_gum_zoom1.0. Keep specs/game-settings.md default descriptions aligned.



- Floor and coyote kicks add world-up velocity; ceiling retains downward contact kicks; walls never grant kicks (wall contact permits an available coyote/double jump). Contact normals still own collision/friction, never floor launch direction. verify_player.gd includes real left/right tilted corner floor and delayed-coyote launches.



- Manual gum tuning: extension180 px/s, shortening90 px/s, break margin240 px (manual cap160 at max400). Down immediately relaxes without clearing tension; existing above-cap natural length never snaps shorter on extension. Down wins over X, Up+Down relaxes/holds; X attached always consumes its release. Ceiling input/physics fixtures duplicate settings with max900 explicitly; saved gameplay settings stay400.

- Gum glow is renderer-independent local bloom approximation in gum_connection.gd: a behind-parent additive CanvasItem draws24 Gaussian-falloff halos plus parent base/core, shared by line/pivots/endpoint. Defaults radius18px/opacity0.18, core white mix0.12 at75% ribbon width; uniform line4px+tension4px, with no distance-based widening. User prefers uniform width along the gum. Contract colors stay pink; READY preview is excluded. Tune Gum Appearance glow radius/opacity/core brightness in game_settings; no world lighting or physics effect.

- Gum firing/aim range is attachment_range (default160); connected wrapped path break limit and manual cap use maximum_length (default400). A hit beyond maximum_length is non-attachable even inside firing range. Long-range fixtures must set both explicitly.

- Gum flight/return authority: `specs/gum-flight-return.md`. Gameplay `fire` sweeps tip at2400px/s; arrival tick has zero force, next tick contracts. `attach_at` directly sets up connection physics fixtures. Z immediately releases physics and cosmetically retracts reverse path at3200px/s (max0.25s); fresh X cancels return and fires immediately, outbound X is ignored. Flight/return have no force; use press edges with independent pre-attachment length-key gates.

- Direction preview (line and reticle) is visible only in READY; hide throughout outbound/attached/returning and restore on return completion. Neutral/opposing arrows preserve last direction (initial facing). Valid preview uses configured valid-color alpha directly (default0.9); unavailable preview multiplies invalid alpha by aim_guide_opacity0.3 (default0.27). No input brightness boost. Arrows combine run/aim; A/D remain movement-only. Player.simulate(delta, jump_requested) never suppresses movement for aiming. Saved gum_shot_speed1200 and attachment_range160 are user tuning; timing fixtures set speed2400/ranges explicitly.

- Gum Diagnostics defaults OFF: `[GumDiagnostic] DETACH` logs release reason/current endpoint and path state; HISTORY contains eight pre-force-reset steps. Dynamic obstruction includes collider/segment/hit and `is_target` to investigate self-hits while pulling blocks. Toggle in shared Diagnostics; see specs/game-settings.md.

- Block-pulling release logs confirmed target self-obstruction: rotating LightBox can intersect its own final gum ray (`UNSUPPORTED OBSTACLE`, `is_target=true`) while path is under limit. `_dynamic_obstruction` excludes player and attached-target RIDs; separate dynamic blockers still release. verify_gum.gd covers a rotated far-side adhesion point with reciprocal tension and an independent blocker.

- Rigid target contact can place local gum adhesion <=2px inside static floor during rotation (logs PATH INVALID at y640.48/641.10 for floor640). GumPath.update optional endpoint_contact_tolerance projects only rigid route endpoint to exposed static union exterior; physical adhesion/torque stays fixed. Deep penetration still fails. verify_gum replays contact case; verify_gum_path covers all sides/deep points/internal seams.

- Pinning Diagnostics defaults OFF: player `[PinningDiagnostic]` logs rigid slide contact start/end, input/gum mode changes and30-tick summaries with8-step history, pre/post collision velocities, displacement, collider/rigid state and gum force. Event-only nearby2px shape query (max16) supplements slide contacts; proximity does not prove pinning. verify_player.gd covers blocked fixture/history/toggle.

- Pinning reproduction can report only4 repeated static wall hits (depth5.28px, floor=false), omitting the rigid block. Watch stalled penetration as well as rigid contacts: depth>=1px, incoming>=10px/s, displacement<0.1px/step. Supplied log shows slack/detached gum does not resolve it; gravity accumulates. Do not infer block absence from slide contacts.

- Detailed pinning log confirms compressed gap: wall x64,40px LightBox center96.446 (rotation~-PI/2) gives12.446px gap for20px capsule; player wall depth grows1.45→5.67px, then4 repeated wall hits exhaust max_slides4, hide floor/block and accumulate gravity despite zero displacement. Rightward input remains positive but cannot escape; gum tension0 and later rigid sleep rule out continuous gum pull as persistence cause. Behavioral fix must address compressed contact geometry, not only input/jump/tension.

- Debug UI uses project-wide resources/debug_theme.tres: PixelMplus12 Regular24px, antialiasing/subpixel positioning OFF and oversampling1. Stage generator labels inherit it; see specs/debug-text.md. Console fonts are independent.

- Compression terrain queries exclude nearby movable rigid RIDs in body_test_motion (safe_margin+0.25, max8 iterations); normal support queries do not toggle live masks. Only actual terrain correction uses a terrain-only support refresh. No rigid transform/gum edits. verify_compression.gd covers pressure/mass/rotation/gum/escape; COMPRESSION_RECOVERED is throttled30ticks.


- Non-support rigid contacts use a0.75px skin and8 sequential virtual-velocity impulse iterations. Floor normals use real move_and_slide support without skin separation/restitution; removed player normal momentum is transferred to the supporting body. Commit all contact impulses after player movement so automatic platform carry sees only pre-reaction physical velocities. Keep default platform layers; verify_compression.gd -- --support-only covers center/both edges, kicks and horizontally moving/ascending rigid platforms.

- Godot4.5.1 headless torque fixtures need a physics tick after unfreezing a RigidBody2D before checking inertia/angular impulse response. Contact lever arms use direct-state world COM offset, including automatic/custom COM, not the node's saved center_of_mass field.

- Grounded run animation uses movement input OR horizontal speed>12px/s, so pushing against blocks/walls stays animated even when collision removes velocity. Air/gum/landing pose priority remains higher. Existing verify_player.gd blocked fixture covers zero-displacement run.

- Corner support resolves the contacted rectangle edge (shape index/transform, <=0.5px face distance), sharing its actual face normal for momentum cleanup and friction; raw capsule normals still own engine contacts. All four edges support rotated boxes; unknown shapes retain raw normals. verify_player.gd checks 42 mirrored original-ledge landings including impact drift, upward departure/downward load and retained horizontal momentum.

- Extreme corner normals can be wall-classified even on a walkable rectangular top. Player predicts that geometric support with test_move, temporarily widens floor classification only during move_and_slide, then restores the configured angle. Supported motion removes into-face velocity before movement; external momentum remains for post-move rigid reaction. Rigid proximity contacts share face classification via shape indices. verify_player covers offsets9/9.8px, diagonal pushback, true walls/undersides and restored slope limit.

- One-way floor artwork: `images/tilesets/restaurant_one_way_platform.png` and matching Godot copy;128×32 RGBA, four32px cells left/middle/right/single, visible top y0,height10px (collision remains5px, same top). Registered as source1 in theater_tileset.tres; paint on collision-enabled OneWayPlatforms. Physics bit8, player mask77, box mask73; gum mask5 passes through. Current layout has15 strips/76cells. See specs/one-way-platforms.md and verify_one_way.gd.

- In Godot text resources serialize collision masks as integer values, never `1 | 2 | 4` expressions: Godot4.5.1 loaded that existing box expression as1. Box mask73 preserves terrain collision and adds one-way platforms.

- Stage geometry/markers are authored in `scripts/stage_layout.gd`; generator now intentionally produces1212 solid cells/27rectangles/59gum corners. Preserve160×24 grid. Current tuning gives69.48px floor-kick rise at60Hz: use64px kick steps,128px gum lifts,222px chest-to-beam shots within range240. `tools/verify_stage_route.gd` traverses actual Game including boxes through7 lifts without teleport/tuning overrides; rerun after terrain/tuning changes.

- TileMapLayer support faces use collision RID/server convex polygon geometry (not CollisionObject2D shape owners); guard has_body_rid against erased tiles. verify_one_way covers mirrored outer-edge landings0/5/7/8px for60ticks without sideways drift; native one-way passage remains authoritative.

- PS4/DualShock 4 uses any-device InputMap: D-pad/left stick move+eight-way aim (axis deadzone0.25), Cross=jump/detach, Square=gum_action, OPTIONS=pause_menu. Aim quantizes active axis signs; shared pre-attachment Up/Down gates and press-edge rules apply. verify_controls.gd includes synthetic joypad/live Game coverage; USB/Bluetooth hardware QA remains separate.

- Gum-only anchor artwork: `images/tilesets/restaurant_gum_anchor.png` plus identical runtime tileset copy,32×32 RGBA mint/coral hollow ring; see specs/gum-anchor-tile.md. TileSet source2/(0,0), collision-enabled GumAnchors layer, physics bit16 (player/boxes ignore), gum mask53. Layout.GUM_ANCHORS owns12 saved placements. Artwork fills30×30px inside32px (1px margin), gum-only48×48px octagon (Layout.GUM_ANCHOR_POLYGON),9px beyond artwork per side, including transparent hole for aiming; no wrapping obstacle. TileMap endpoints track collision RID, so erasing disables attachment. Run tools/verify_gum_anchors.gd.

- Gum minimum_length is minimum natural path length (default4px), not a hard endpoint-distance clamp; shared settings asset inherits script default when omitted. Shorter initial attachments never lengthen to4. Gravity stretches taut gum and release/overshoot can pass inside natural length with zero gum force.

- Atlas source0 cell(5,6) is a ring-like decoration with no collision; it cannot attach even when painted on GumAnchors. Use source2 cell(0,0) for functional rings.

- Ring adhesion always resolves hit RID to tile center (aim/tip/path/natural length); terrain/props retain actual hit points. GumAnchors.physics_quadrant_size must be1: Godot default16 groups cell RIDs and get_coords_for_body_rid returns quadrant coordinates. Keep generator/saved layer/fixtures aligned; center distance owns maximum_length validation.

- Gum adhesion VFX assets are `images/effects/gum_attach_{surface,ring}.png`:64px cells,4columns,10frames (last transparent),30fps,pivot32/32; surface normal-X,ring radial. Editable pixelfx source is images/effects/gum-attach.mjs. Runtime copies under assets/effects/; Game binds reusable GumAttachmentEffect to Gum adhesion_started/adhesion_ended signals, follows endpoint/rotating normal and hides at0.30s or release. See specs/gum-attachment-effect.md; run tools/verify_gum_attachment_effect.gd.

- Landing dust assets: images/effects/landing_dust_{normal,heavy}.png,64×32px cells,3columns,10frames (9visible+transparent end),30fps,pivot32/26. Editable landing-dust.mjs uses PixelFX core, heavy option selects strength. Game binds reusable LandingDustEffect to Player.landed, follows rigid contact points and expires at0.30s; suppress spawn settling, airborne<0.05s/<2px and compression recovery. Shared Landing Dust settings select80/450px/s relative normal impact thresholds. See specs/landing-dust-effect.md; run tools/verify_landing_dust.gd.

- READY aim tile blink lives in gum_connection.gd: merged Terrain hits map 0.1px inward to sibling TerrainTiles; ring hits use body RID cell. Draw-only 3Hz cell overlay; run tools/verify_aim_tile.gd.

- Confirmed settings baseline: minimum_length4px, attachment_range160px, pinning_diagnostics/gum_diagnostics OFF; script defaults match saved Resource overrides. Jump/Landing diagnostics remain OFF. See specs/game-settings.md.

- Shot trail is procedural `gum_shot_particles.gd`, bound by Game to Gum.shot_started/shot_advanced actual swept-tip segments; world-space residue survives detach/refire and expires, restart clears. Settings group Gum Shot Particles; draw z4 below gum5/adhesion6. No PNG assets. Run tools/verify_gum_shot_particles.gd with gum/controls/adhesion suites.

- Hit particle rings use procedural `gum_hit_particles.gd` via adhesion_started: ring360deg/surface outward hemisphere, frozen world-space centers, residue survives release/target deletion. Game clears on restart; cap4bursts/64particles; z5 after gum/before patch6. Gum Hit Particles settings include optional arcs(defaultOFF). Run tools/verify_gum_hit_particles.gd with gum/controls/adhesion/shot suites.

- Jump/landing squash-and-stretch is sprite-only in player.gd: accepted upward launches0.84×1.41/0.31s, qualified landed events1.44×0.82/0.31s, quadratic recovery. Scale sprite position with sprite scale around feet; never scale Player/capsule. Tune shared game_settings Player Squash and Stretch (jump_stretch/landing_squash Vector2 multipliers and corresponding duration seconds;0 disables). verify_player_deformation.gd checks actual jump/landing, custom settings and fixed collision geometry; specs/player-controller.md describes behavior.

- Confirmed shared settings baseline: jump stretch(0.84,1.41)/0.31s; landing squash(1.44,0.82)/0.31s; shot particles lifetime0.5/spread16/opacity1; hit particles count16/lifetime0.5/opacity1. All diagnostics OFF; schema defaults match saved Resource.

- Speed afterimages: Player calls player_afterimages.gd after animation/deformation, using actual fixed-step world displacement speed (default350px/s). Frozen nearest-filtered Sprite2D snapshots fade0.20s, interval0.04s, max8; shared Player Afterimages settings. Child lifecycle clears on restart; run tools/verify_player_afterimages.gd.

- Food collectibles use scene tiles in dedicated `assets/foods/food_tileset.tres` on stage `Foods` TileMapLayer;11 scenes under `scenes/items/foods/`,64px centered display on32px cells/36px pickup and gum-hit radius. Player group `player` plus physics bit2 owns contact pickup; Food Area bit32 is gum-ray target, no terrain collision. Default36 placements (six per section/all11 dishes) live in stage_layout.gd FOODS; keep saved Foods cells and generator aligned. Generator overwrites manual edits. See specs/food-item-assets.md and tools/verify_food_collectibles.gd.

- Top-level afterimage sprites use absolute Z one below the source artwork's accumulated CanvasItem Z; show_behind_parent alone does not establish their order behind Player.

- Afterimages share an unshaded afterimage_silhouette.gdshader material: texture alpha preserves silhouette, vertex COLOR carries afterimage_color RGB/opacity and per-snapshot fade. Capture COLOR in vertex before fragment texture multiplication; player material stays unchanged.

- Hit shockwave uses gum_hit_shockwave.gd and shaders/gum_hit_shockwave.gdshader via adhesion_started; frozen world center, max4 local screen-refraction quads at Z4, no physics effects. Shared Gum Hit Shockwave settings; restart clears. See specs/gum-hit-shockwave.md and tools/verify_gum_hit_shockwave.gd.

- Food gum hits enter REELING: Game locks Player across arrival/completion ticks, resets all velocities and skips movement/gravity; Gum moves food to visual hand at Food Collection/food_reel_speed600. Z/X ignored while pulling; success grants one consumed world-up Z jump (no autojump/stacking); target loss grants none. Normal terrain/rigid spring unchanged. Gum ray mask53 includes areas; terrain-only wrapping fixtures clear Foods. See specs/food-gum-reel.md and tools/verify_food_reel.gd.

- Food collection PixelFX burst: `images/effects/food-collect.mjs` wraps collect-burst (2× speed, restaurant palette); matching food_collect.png runtime copy,112×108 cells/5×5/22frames/30fps. food_collectible.collect spawns stage-owned world-frozen food_collect_effect.gd at collection center for0.7s (both contact/reel, once); no effect on initial gum hit. See specs/food-collect-effect.md and tools/verify_food_collect_effect.gd.

- One-way drop: grounded Down+fresh Z (pad Down+Cross) suppresses kick and temporarily clears player mask bit8; restores after feet descend58px or0.5s. Minimum descent60px/s, horizontal momentum retained, coyote consumed; solid floors retain normal kicks. See specs/one-way-platforms.md; verify_one_way.gd covers drop/restoration/solid floor.

- Hit shockwave shader uses a broad refraction band and narrow pink/white core, holds brightness through45% then fades; mask screen sample only once to avoid double attenuation. Saved tuning160px/1s/16px/opacity1 differs from schema defaults; verification sets duration explicitly.

- Textureless Polygon2D ignores its UV array in Godot4.5; shockwave radial coordinates must use vertex position/quad_radius varying. Run verify_gum_hit_shockwave_render.gd without --headless for GPU pixel regression; before/after captures live in /tmp.

- Jump buffering: Player Movement/jump_buffer_time defaults0.12s (0 disables), floor-only pending input executes on first supported physics tick; success/drop/reset/reel clears. Special gum/food/wall/ceiling actions require fresh presses. Run tools/verify_jump_buffer.gd with player/controls/one-way/food-reel suites.

- Ladder source artwork: `images/restaurant_ladder.png`,1024×1536 transparent RGBA, front-facing mint rails/cream rungs/coral fittings; runtime copy under `assets/props/`, used by the ladder scene.

- Climbable ladder: `scenes/props/ladder.tscn`, feet-origin bottom/height128, Up/Down grip/climb120px/s, neutral hold, sideways/Z/active gum release. Shared Player collision pipeline; bit8 ignored only while gripping, restored on release/reset/deletion. `stage_layout.LADDERS` owns saved optional first-shelf placement(464,640). See specs/ladders.md and tools/verify_ladder.gd.

- Spike artwork: `images/tilesets/restaurant_spikes.png` is32×32 transparent RGBA (three upward spikes/coral base), nearest filtering; matching `_source.png` is generated original. Runtime copy/scene TileSet live under assets/hazards; paint source0/scene0 on Spikes (20 authored cells), generator uses Layout.SPIKES. Non-solid Area bit64; Game sweeps Player capsule before/after simulate and shares idempotent restart() with R/fall. Run tools/verify_spikes.gd; see specs/spike-tile-assets.md.

- Climbing character source: `images/teto_climb.png`, single full-body rear-three-quarter Teto ladder-climb pose generated from character references; artwork only, not normalized or integrated into ladder animation.

- Ladder climb animation: `images/normalized/teto_climb.png` and matching runtime copy,512×256/two256px cells,4px pixel clusters/baseline232. Back-facing alternating left-hand/right-foot then right-hand/left-foot; climb_animations.tres6fps, neutral pauses and no facing flip. `images/teto_climb.png` stays reference-only; generated sheet source is images/teto_climb_sheet_source.png.

- Checkpoints: reusable feet-origin scenes/props/checkpoint.tscn under TheaterStage/Checkpoints; stage_layout.gd CHECKPOINTS owns5 placements. Player-only non-solid trigger;8-frame4x2 sign (restaurant_checkpoint_flip_source.png), inactive muted-coral flag → active mint check, stops on check without rebound; Sprite2D scale0.13 preserves approx58px size. Pit/spike deaths call Game.restart(true), restoring last touched node via consumed scene-scoped SceneTree metadata; manual R/menu Retry restart clears it. Reload resets world/food/gum/velocity. See specs/checkpoints.md; run tools/verify_checkpoints.gd with spikes/controls/map suites.

- Spike disappearance uses PixelFX source `images/effects/player-disappear.mjs`,128px cells/5×4/19frames/30fps/0.6s; matching runtime PNG. Game freezes/hides player and gum, clears afterimages, plays once at swept contact center, then checkpoint restart; R/fall stay immediate. See specs/player-disappear-effect.md and verify_spikes.gd.

- Background decorations: `restaurant_background_decor.png` in images/tilesets and runtime assets/tilesets is384×384 RGBA/16 stamps of96px. Dedicated background_decor_tileset.tres uses32px grid/source0/3×3-cell stamps at atlas coordinates0/3/6/9; BackgroundDecor is collision-free behind terrain. Layout.BACKGROUND_DECOR owns42 placements; shared background_decor.gd builds layer. tools/install_background_decor.gd updates only decor without full map regeneration. See specs/restaurant-background-decor.md and verify_background_decor.gd (-- --render for native capture).

- Checkpoint atlas has unequal transparent bottom padding: checkpoint.gd FRAME_BASELINES aligns each frame’s opaque base to feet-origin y0 via frame_changed. Keep per-frame baseline data aligned when replacing artwork; verify_checkpoints.gd measures alpha bottoms for all8 poses.

- Authored spikes: six64px floor strips plus four64px optional upper strips (20cells), stored in Layout.SPIKES. tools/install_spikes.gd updates only saved Spikes layer; verify_spike_placements.gd checks support/spawn clearance and six real-physics kick crossings. Full verify_stage_route currently fails first lift with saved attachment_range160 versus its240px design; do not claim full-route success from local spike checks.

- Hanging-arm angular in-between source: `images/gum-source/teto_gum_hang_inbetweens.png` (1774×887 RGBA,4×2 poses, target10–80deg from up). Runtime normalized sheet is `teto_gum_hang_angles.png` in normalized/runtime directories; Player selects raised nearest-angle frame in upper sector(<70deg from up; under5deg keeps original loop) during flight or loaded airborne attachment, independent of speed/distance; lateral fire/pull starts70deg,80deg sample currently unused; mirrors left and uses first wrapped support. Hand samples live in GUM_HANDS; run verify_hanging_poses.gd. See specs/character-gum-animations.md.

- Hanging Pose Diagnostics logs SELECTED/30-tick SAMPLE/EXIT with signed pose angle, angle_source(shot/support), upper_sector, frame/nominal/error/mirror and pose eligibility fields. Schema defaultOFF, saved shared Resource currentlyON for angle investigation; this log measures selection, not artwork arm geometry. verify_hanging_poses.gd sweeps17304 quarter-degree cases across mirrored directions/flight+attachment/speeds0,150,500/distances2,400; nearest-angle ties tolerate0.0001deg.

- Gum visual origin is a bounded player-local hand offset (Gum Appearance/gum_hand_follow_speed360px/s), updated once after deformation in normal and food-lock simulation; gum_visual_target returns raw pose sample. Renderer getters never advance tracking; player world translation follows immediately. Physics chest origin unchanged. verify_gum_hand_origin.gd covers pose/mirror/deformation/timestep/lock behavior.

- Gameplay SFX: root sounds/*.wav originals (non-2 variants) copied to assets/sounds; SoundEffects autoload owns up to24 overlapping non-positional one-shots and survives scene reload. Cue timing/spec: specs/sound-effects.md; verify_sound_effects.gd. Pull plays on first contraction step/relaxed restart (including food reel), checkpoint only first activation, manual restart silent.

- `pixelfx/` is an independent nested upstream clone, untracked by the game repository and locally hidden via `.git/info/exclude` (not a submodule). `images/effects/*.mjs` import its core for asset authoring; preserve the checkout when adjusting Git visibility.

- Double jump: one fresh airborne Z/Cross impulse, refreshed on floor or successful non-food gum adhesion; existing contact/coyote/gum-release/food/ladder jumps take priority without consuming it. Initial/contact/special jumps use kick_speed, spinning air jump uses Player Double Jump/double_jump_kick_speed (schema380/current saved300); vertical speed assignment for air jumps, gum-style downward cancellation for gum release; sprite-only rotation persists until landing/ladder/reset/non-food gum adhesion. Motion reset/reeling clears spin without restoring air allowance. See specs/player-controller.md and tools/verify_double_jump.gd; exhausted-air fixtures isolate landing-buffer/rejection tests.

- Rotation-jump tuck source: images/teto_double_jump.png,1254×1254 transparent RGBA single right-facing knees-hugged pose. Runtime copy assets/characters/teto_double_jump.png is byte-identical; player.tscn double_jump uses AtlasTexture region(328,145,606,935), sprite-only0.175 source scale on top of normal0.3125. Outbound spin prioritizes tuck; non-food adhesion stops spin and restores ordinary gum poses; mirrored/rotated visual hand uses crop-relative(143,194). See specs/character-sprite-audit.md.

- Double-jump visual speed is shared Player Double Jump/double_jump_rotation_speed in rev/s (schema2.5, current saved tuning3.0;0 freezes current angle); read live per step, physics/pose unchanged. verify_double_jump.gd checks custom/live/zero speed and momentum invariants.

- Double-jump spin follows current sprite.flip_h after pose selection: right clockwise/left counterclockwise, midair reversal retains angle, neutral retains facing. fposmod wraps signed rotation; settings speed is magnitude. verify_double_jump.gd exercises real left/right/neutral input with custom/zero speeds and fixed collision/momentum.

- Gum._attach_hit notifies Player.on_gum_attached only for non-food terrain/rigid/ring hits: one-shot air-jump refill and immediate rotation/pose/scale reset with unchanged velocities. Food retains reset_motion/reel reward rules. verify_double_jump_gum.gd covers actual Game flight→adhesion→release→air jump, held-attachment no-refill and food exclusion.

- Kick tuning is independent: Player Movement/kick_speed controls initial/contact/coyote/gum-release/food/ladder jumps; Player Double Jump/double_jump_kick_speed controls spinning air jumps only. Current saved values400/300; preserve user tuning. verify_double_jump.gd uses distinct310/470 fixtures and verifies gum-release priority.

- Double-jump launch directly assigns external_velocity.y = -double_jump_kick_speed, replacing upward/downward momentum and current-tick gravity while preserving X; gravity resumes next tick. Other jump types retain existing compensation. verify_double_jump.gd covers72 combinations of gravity/timestep/vertical+horizontal speed.

- Wall contact never grants a kick or restores air jumps. Wall-only Z uses an available floor coyote jump or ordinary one-use vertical double jump; ceiling kicks remain. verify_double_jump.gd covers both real wall sides.

- Gum-pass barriers: restaurant_gum_pass_barrier.png (32px thin light silver-gray frame, translucent blue glass and subdued blue-gray diagonal highlights), identical images/runtime copies normalized from restaurant_gum_pass_barrier_source.png by tools/build_gum_pass_barrier.py. theater_tileset source3/(0,0), full-cell solid physics bit64; player mask77/box73, gum53 excludes it. Paint collision-enabled GumPassBarriers; independent from one-way drop-through bit8. Layout.GUM_PASS_BARRIERS owns6 saved cells: (4–6,15)/(59–61,16), overhead screens below rings in sections01/03; generator matches. See specs/gum-pass-barrier-tile.md and tools/verify_gum_pass_barrier.gd.

- Checkpoint PixelFX: images/effects/checkpoint-{idle,activate}.mjs → tools/build_checkpoint_effects.mjs exports idle/active60-frame96×96 loops and activation25-frame128×96 burst to source/runtime. checkpoint_effect.gd owns art-only child sprites;0.4s stars/0.8s end, no replay on repeated contact or respawn. Both idle variants alternate50px rising side trails and up to10px top stars (1s side offset/2s cycle), cream/coral inactive and mint/cream active; activation uses2px arcs/up to9px stars with subtle local glow. See specs/checkpoints.md; verify_checkpoints.gd covers lifecycle.
- Local PixelFX Painter expects numeric colors (`hex()` or `fit()`), not raw hex strings; `px(x,y,c)` ignores extra alpha arguments. Use a zero-length `line` for a fading pixel and epsilon-safe end-time checks for transparent final frames.

- Food availability sparkles: PixelFX source images/effects/food-idle.mjs, regenerate with tools/build_food_idle_effect.mjs;96px cells/60frames/30fps/2s. food_collectible owns food_idle_effect child with position-based phase; being_pulled setter immediately hides/restores it, collection hides before success burst. See specs/food-idle-effect.md; verify_food_collect_effect.gd covers lifecycle.


- Hanging-only waypoint pulley: scenes/props/pulley_trolley.tscn + scripts/pulley_trolley.gd; Game at(944,384), F5 only. Bind existing Gum.adhesion_started: each fresh hit requests one segment, moving hits ignored/no queue, arrival waits, detach does not stop motor. Export local2D route_points(default80/184/288 on X), LOOP or PING_PONG(default), speed140/force18000. Force servo + per-segment native GrooveJoint2D retain real reciprocal gum physics; no tween/velocity overwrite. Carriage bit16/mask0, only pad(0,42) collides with gum; player/props pass through. Single-wheel PNG/atlas, generated dark route rails. See specs/pulley-trolley.md; verify_pulley_trolley.gd.

- Gameplay HUD has no persistent control-help text; keep control documentation in specs/keyboard-controls.md. HUD/Status remains for runtime gum state.

- F5 opens `scenes/mode_select.tscn`. Stage Mode opens `scenes/stage_select.tscn`, whose Back button and ui_cancel return to mode selection. Time Attack opens `scenes/game_time_attack.tscn`; stage_catalog.gd lists3 playable courses. Stage1 is original restaurant; inherited game_stage_2/3 scenes export stage_scene + stage_width2048. Rebuild only new maps via tools/build_provisional_stages.gd; original map/TileSet untouched. Game OPTIONS/Esc/HUD opens a pause menu with retry/selection/cancel; new entry clears checkpoint, R preserves selected scene, Exit player contact opens door, darkens/hides actor and closes before clear result. See specs/stage-selection.md and tools/verify_stage_select.gd.

- Stage-start entrance source artwork: `images/tilesets/restaurant_stage_entrance_source.png` (transparent cream/mint doorway with coral canopy and arrow sign). This original is retained; the ENTRANCE animation variant supplies the normalized runtime sprite, separate from the terrain TileSet.

- Entrance opening patterns: `images/tilesets/restaurant_stage_entrance_animation_source.png`, six states in3×2 reading order; reverse for closing, hold last for character emergence. The approved ENTRANCE variant is normalized separately; see specs/stage-entrance-art.md.

- Current entrance animation sign variant: `images/tilesets/restaurant_stage_entrance_animation_entrance.png`; all six signs read ENTRANCE without arrows. Original arrow sheet retained as source; normalized runtime sheet and lifecycle are documented in specs/stage-entrance-art.md.

- Stage entrance: Game advances stage_entrance.gd for1.10s on fresh/manual restart; checkpoint restore skips. Frozen player/reset_motion, hidden gum, no queued jump/shot.96×128 cells/3×2 sheet built by tools/build_stage_entrance_art.py; source/runtime copies identical. Same-Z ordering puts entrance after stage/before Player. Floor ray aligns feet. Run verify_stage_entrance.gd plus stage_select/controls suites.

- Pause menu is scripts/pause_menu.gd (CanvasLayer PROCESS_MODE_ALWAYS), pauses whole SceneTree; OPTIONS has its own pause_menu action, R remains restart. HUD/Menu and Esc also toggle. Retry/selection close/unpause before scene transition; close consumes next Game tick to avoid UI Cross becoming jump. _exit_tree releases owned pause. verify_pause_menu.gd covers actual pad events and frozen physics/entrance.

- UI accept explicitly maps any-device Cross plus Enter/KpEnter/Space in project.godot; Godot built-in ui_accept in this project contained keyboard events only. verify_pause_menu.gd uses actual D-pad/Cross events; do not rely solely on emitting Button.pressed for pad QA.

- Exit doorway source art: `images/tilesets/restaurant_stage_exit_source.png`, transparent closed double doors matching entrance with EXIT sign/no arrow. Static source retained; the opening sheet supplies normalized runtime art at Exit markers.

- EXIT opening patterns: `images/tilesets/restaurant_stage_exit_animation_source.png`, six states in3×2 reading order, closed→fully open; reverse closes. Runtime normalization/integration uses restaurant_stage_exit.png; see specs/stage-exit-art.md.

- Exit sequence: Game creates stage_exit.gd at floor-aligned Exit marker; non-solid40×64 Area(bit2/player) triggers once.0.4s opening→0.5s RGB-to-black→hide player/zero masks→0.4s closing→clear. Fixed-step lock, detach/hidden gum, no actor teleport. build_stage_exit_art.py regenerates identical96×128-cell3×2 sheets. Run verify_stage_exit.gd and stage_select/entrance/pause/map suites.

- Clear result uses a full-viewport CenterContainer under HUD; do not combine centered anchors with a second viewport-center position offset (that displaced the result outside the viewport).

- Entrance front-pose source: `images/teto_front_entrance_source.png`,1024×1536 transparent RGBA single neutral front-facing Teto. Normalize via `tools/build_character_door_art.py` to identical normalized/runtime256px cells (height196,feet232,alpha threshold128). stage_entrance.gd uses static entrance_front on the actor through emergence/closing and restores idle when controls unlock; checkpoint skips it. Original front reference is `images/original/teto.png`.

- Exit rear-pose source: `images/teto_back_exit_source.png`,1024×1536 transparent RGBA neutral back-facing Teto, matched to entrance front art. Runtime rear pose uses identical normalized/runtime256px cells (height196,feet232,alpha128) via `tools/build_character_door_art.py`; stage_exit runs to center120px/s with collision sliding before static exit_back/open/fade/close. See specs/character-back-exit.md.

- Exit contact locks controls immediately; stage_exit.gd first retains vertical entry speed and applies shared gravity without horizontal motion until a walkable floor collision, then runs horizontally120px/s to center before rear pose/open/fade/close. Game snapshots velocity.y before reset_motion; landing/approach own private motion while normal Player.simulate remains skipped. verify_stage_exit covers upward entry, no air drift/input and paused landing.

- Additional large hair-lag hanging source: images/gum-source/teto_gum_hair_followthrough.png,1774×887 RGBA4×2 temporal poses (gentle torso curve, exaggerated trailing drill-hair sweep/return). Existing poses preserved; tools/build_gum_hair_art.py creates matching normalized/runtime256px cells. gum_hair_pull loops8frames/10fps when airborne attached upward/lateral player_force has dominant horizontal component>=700 (hold>=525); shared Gum Pull Pose setting. Run verify_hair_pull.gd plus hanging/hand/player suites. See specs/character-gum-animations.md.

- Music note:32px transparent source in `images/items/`, identical runtime copy `assets/items/music_note.png`; `scenes/items/music_note.tscn` uses shaders/music_note.gdshader for3s local highlight plus4s±32deg yaw; compensated face width>=94%, ~2px extruded sides, no root/sprite scaling or sensor deformation. Both clocks have positional phases/pause support. Player-only18px contact pickup: hide/item sound/one-shot collected() then free; no score/gum reeling. F6 `scenes/music_note_preview.tscn`; run tools/verify_music_note.gd. See specs/music-note-item-assets.md.

- MusicNotes is an editable scene-tile layer in all3stages (restaurant70/terrace25/kitchen22); TileSet `assets/items/music_note_tileset.tres`, authored cells `scripts/music_note_layout.gd`. Keep saved cells/arrays aligned; restaurant generator shares helper. Player-only contact pickup; stage reload restores notes, no score. verify_music_note_placement.gd checks actual scene instances and terrain/platform/spike/food clearance.

- Current verify_stage_route.gd fails at first upward shot with saved/default attachment_range160 (fixture documents240/222px chest-to-beam). Reproduced with MusicNotes removed; do not treat this as a note placement regression or silently raise user tuning.

- music_note.gd resolves SoundEffects via `/root/SoundEffects` at pickup: early TileSet scene preloads in headless fixtures can compile before autoload identifiers register. verify_music_note_pickup.gd covers physical contacts across3stages, filtering, gum exclusion, pause/reload and duplicate requests.

- Small score-item baguette artwork is `images/foods/baguette.png`, a standalone 32 × 32 transparent RGBA sprite. Use nearest-neighbor filtering.
- Baguettes are 100-point contact pickups under each saved stage's `Baguettes` node (3 per stage); keep placements aligned with `scripts/baguette_layout.gd`. Game owns the stage score/HUD and scene reload resets score and pickups. Music notes and baguettes share `contact_pickup.gd`; only baguettes award points. Keep the source and runtime baguette PNG copies identical.

- Time Attack uses one dedicated 192×24 stage, `scenes/stages/time_attack.tscn`. `tools/build_time_attack_stage.gd` overwrites the saved map with its initial layout. After manual edits, sync Terrain rectangles to the saved TerrainTiles occupancy without rerunning the builder. Game counts active physics time immediately after the entrance animation, freezes it on goal contact, and saves one local best in `user://time_attack_sprint.cfg`. See `specs/time-attack-courses.md`.

- Time Attack's TerrainTiles material fills transparent pixels inside each painted 32px atlas cell. Keep terrain visuals on TileMapLayer and merged StaticBody2D shapes aligned for gum wrapping.

- Time Attack activates checkpoints under the stage’s Checkpoints node. The scene-scoped respawn payload carries elapsed time across automatic death reloads, including fallback to the entrance. Manual retry clears both checkpoint and timer.

- Game fall death checks the player origin against shared restart_y plus the scene’s fall_restart_offset. Time Attack adds64px (default Y=964).
