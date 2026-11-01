# Work Log

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
