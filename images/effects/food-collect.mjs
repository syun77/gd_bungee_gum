// Adapted from PixelFX collect-burst / Sprite Fusion pickup,
// MIT License, Copyright (c) 2026 Hugo Duprez.
import * as burst from '../../pixelfx/src/fx/pickups/collect-burst.js';
export const meta = {
  ...burst.meta, name: 'Food collection',
  desc: 'Cream flash, coral rings and mint twinkles celebrate a collected dish.',
  origin: [56, 84], duration: 0.7,
  options: { ...burst.meta.options,
    palette: ['#55464c', '#78545b', '#ac686c', '#d98b82', '#d86f68', '#ef9384', '#74c9ae', '#fff4d8'],
    light: 0.25 },
};
export function create(o) {
  const effect = burst.create(o);
  return { update(dt) { effect.update(dt * 2); }, draw(p) { effect.draw(p); } };
}
