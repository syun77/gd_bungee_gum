# Entrance front-facing character artwork

- Source: `images/teto_front_entrance_source.png` (1024 × 1536, RGBA with transparent exterior).
- One full-body neutral front-facing Teto pose, lowered arms and level feet, matching the existing red drill curls, gray/red costume and black boots.
- Intended for character emergence from the stage entrance. The entrance timeline uses this pose throughout emergence/door closing, then restores normal animation when controls unlock. `tools/build_character_door_art.py` normalizes it to `images/normalized/teto_front_entrance.png` and the identical runtime `assets/characters/teto_front_entrance.png`: 256 px cell, 196 px figure height, feet at y232, nearest filtering. Alpha below128 is discarded to remove generated residue.
- Generated with built-in imagegen using `images/original/teto.png` for identity and `images/normalized/teto_idle.png` for runtime style.
- Final generation prompt: Single strictly front-facing full-body neutral standing Teto, shoulders/hips square, eyes and boots forward, arms naturally lowered, preserve reference identity/costume/chibi pixel-art proportions, centered with full silhouette/padding, transparent background, no doorway/scenery/shadow/text/additional poses.
- Extraction prompt: Preserve exact character/pose/costume; remove all exterior background haze, glow and shadows, including spaces between limbs, leaving transparent exterior and clean dark pixel outlines.
