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

- The Godot project root is `gd-bungee-gum/`; open `gd-bungee-gum/project.godot` in Godot and place engine project files under that directory.
- Image assets are stored in the repository-root `images/` directory. Consult this directory when selecting or integrating game visuals.
- Character references: `images/teto.png` is the front view; `teto_idle.png`, `teto_run.png`, and `teto_jump.png` are the intended idle, run, and jump sheets. See `specs/character-sprite-audit.md` for measured sizes and slicing issues before integration. Root-level `images/` is outside Godot’s `res://`.

- Normalized Teto animation candidates live in `images/normalized/`: 1024 × 512 RGBA sheets, 4 × 2 cells of 256 px. Idle uses the first six cells; run/jump use eight. Ground baseline is cell y=232; see the sprite audit for generation caveats.

- During every task, proactively record durable, repository-specific knowledge in this `AGENTS.md` as soon as it is verified and likely to help future work.
- Examples include required commands, architectural constraints, non-obvious conventions, recurring pitfalls, and user preferences that apply to this repository.
- Keep entries concise, actionable, and generally applicable. Do not add guesses, temporary task state, information already obvious from the code, or duplicated guidance.
- Never record secrets, credentials, tokens, personal data, or other sensitive values.
- If later evidence invalidates an entry, update or remove it immediately instead of appending contradictory guidance.

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

