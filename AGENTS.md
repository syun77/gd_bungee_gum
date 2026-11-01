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

- Food collectible art lives in `images/foods/`; `milano_doria.png`, `escargot_oven_baked.png`, `chicken_diavola.png`, `shrimp_salad.png`, `spicy_chicken.png`, and `margherita_pizza.png` are 64 × 64 transparent RGBA static sprites. Use nearest-neighbor filtering; see `specs/food-item-assets.md`.

- Current setting/art direction is a pop-colored family restaurant: cream ceramic, coral/mint trim, painted frames and muted teal background. `theater_*` filenames remain the current resource identifiers. Edit both atlas copies together (`images/tilesets/` and `gd-bungee-gum/assets/tilesets/`); `restaurant_tileset_source.png` is the color-edit source.

- The first editable map is `gd-bungee-gum/scenes/stages/theater_stage.tscn` (160 × 24 cells, 32 px grid). F6 opens the stage alone; F5 runs `scenes/game.tscn` with the Teto player (A/D or arrows, Z for detach/contact kick-off, R for restart). Open `scenes/map_preview.tscn` with F6 for arrows to pan, 1–6 to select a section and Tab for overview.
- Map layers have collision disabled; `TheaterStage/Terrain` owns merged rectangular static shapes on physics layer 1. When editing terrain tiles, update matching shapes and outline nodes together. `tools/build_theater_stage.gd` regenerates the scene/TileSet and overwrites manual edits; run only intentionally.
- Local Godot executable: `/Applications/Godot_mono.app/Contents/MacOS/Godot` (4.5.1). For sandboxed headless runs, use `--log-file /tmp/<task>.log` to avoid a crash writing default user logs. Run the saved-map collision check with `--headless --path gd-bungee-gum --log-file /tmp/map-check.log --script res://tools/verify_theater_stage.gd`.

- `images/tilesets/theater_tileset.png` is a 512 × 512 RGBA manual-placement atlas (32 px cells, 16 columns, 105 occupied cells). See `specs/theater-tileset-assets.md` and `specs/theater-tileset-atlas.json`; 47-pattern autotiling and seamless joins are not yet validated.

- `specs/tileset-specification.md` defines the proposed initial tileset art direction, 32 px grid, asset separation, and visual acceptance checks; scale and stage dimensions remain subject to prototype validation.

- The Godot project root is `gd-bungee-gum/`; open `gd-bungee-gum/project.godot` in Godot and place engine project files under that directory.
- Image assets are stored in the repository-root `images/` directory. Consult this directory when selecting or integrating game visuals.
- Character references: `images/teto.png` is the front view; `teto_idle.png`, `teto_run.png`, and `teto_jump.png` are the intended idle, run, and jump sheets. See `specs/character-sprite-audit.md` for measured sizes and slicing issues before integration. Root-level `images/` is outside Godot’s `res://`.

- Gum poses: `images/normalized/teto_gum_{fire,pull,hang}.png` and matching Godot copies under `assets/characters/teto/`; `gum_animations.tres` provides three eight-frame animations. See `specs/character-gum-animations.md`; poses do not drive physics.

- Normalized Teto animation candidates live in `images/normalized/`: 1024 × 512 RGBA sheets, 4 × 2 cells of 256 px. Idle uses the first six cells; run/jump use eight. Ground baseline is cell y=232; see the sprite audit for generation caveats.

- During every task, proactively record durable, repository-specific knowledge in this `AGENTS.md` as soon as it is verified and likely to help future work.
- Examples include required commands, architectural constraints, non-obvious conventions, recurring pitfalls, and user preferences that apply to this repository.
- Keep entries concise, actionable, and generally applicable. Do not add guesses, temporary task state, information already obvious from the code, or duplicated guidance.
- Never record secrets, credentials, tokens, personal data, or other sensitive values.
- If later evidence invalidates an entry, update or remove it immediately instead of appending contradictory guidance.

- Gum fixed-step owner is `scripts/game.gd`: input → `Gum.step` → `Player.simulate` → camera/HUD. Player has no independent physics callback. Tune `resources/game_settings.tres`; attachable terrain/props are physics layers 1/4, player is layer 2. Keep reciprocal forces and collision momentum cleanup together.
- Gum controls: hold X + arrows to aim in eight directions, release X to fire and auto-contract; attached X toggles fixed-length loosen/contract; Z detaches then contact-kicks (no airborne impulse). `tools/verify_controls.gd` exercises physical Z/X gestures and cancellation. `tools/verify_gum.gd` covers real ray queries, rigid force/mass response and live Game integration. Input bindings use device -1 (any device); editor-saved device 16 bindings do not match Godot 4.5 synthetic keyboard events.
- Assign the gum settings Resource through the scene's exported property; preloading its instance as a typed script property's default caused uninitialized Resource script values under Godot 4.5.1.

- `specs/keyboard-controls.md` is the implemented Z/X control authority. Keep input gesture state separate from physical slack: a toggle/canceled gesture waits for X release and never fires after connection loss. Loosen extends rest length once by the configured margin and then fixes it.

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
