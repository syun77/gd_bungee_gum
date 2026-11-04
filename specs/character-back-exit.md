# Exit rear-facing character artwork

- Source: `images/teto_back_exit_source.png`, single full-body rear-facing Teto, transparent RGBA1024×1536.
- Intended for looking into screen while leaving through the exit. Neutral lowered arms, level feet, rear head/jacket/boots; no face. Matches approved entrance front-pose palette/proportions.
- Runtime uses `assets/characters/teto_back_exit.png`, identical to `images/normalized/teto_back_exit.png`. `tools/build_character_door_art.py` produces a256px cell,196px figure height and feet y232 with nearest sampling and alpha128 cleanup. Exit waits for a physical landing with controls locked, then runs horizontally to door center, then displays the static rear pose through opening/fade until hidden.
- Built-in imagegen references: `images/teto_front_entrance_source.png` (identity/costume/proportions) and `images/normalized/teto_idle.png` (runtime style).
- Final prompt: One full-body strictly rear-facing Teto looking away into screen, neutral lowered arms, square shoulders/hips and level feet; preserve red drill curls/ahoge, anatomically consistent white ornament, gray/red/black military costume and rear boots. Match approved chibi pixel-art style, centered complete silhouette, transparent exterior; no face/front buttons/front boot laces, doorway/scenery/shadow/text/duplicates.
