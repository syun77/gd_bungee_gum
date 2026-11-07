import { Rng, fit, clamp, TAU } from '../../pixelfx/src/core/index.js';

export const meta = {
  name: 'Brick break',
  desc: 'A quick cream impact, terracotta chunks tumble outward and fall through a thin cloud of warm dust.',
  tags: ['brick', 'break', 'debris', 'impact', 'one-shot'],
  size: [128, 128], origin: [64, 56], duration: 0.5, fps: 30, loop: false, bg: 'dark',
  options: { palette: ['#4a281b', '#824327', '#b86c42', '#d48c55', '#e8ab70', '#fff0cc'], seed: 23 },
};

export function draw(p, t, o) {
  if (t < 0 || t >= meta.duration) return;
  const C = fit(o.palette, 6), rng = new Rng(o.seed);
  const q = clamp(t / meta.duration);
  // Dust expands quickly, then thins behind the heavier fragments.
  for (let i = 0; i < 7; i++) {
    const a = i / 7 * TAU + rng.range(-0.25, 0.25);
    const spread = 4 + 24 * (1 - (1 - q) ** 3);
    const r = (3 + rng.range(0, 2)) * (1 - q);
    const x = Math.cos(a) * spread, y = Math.sin(a) * spread * 0.65 - q * 5;
    p.disc(x, y, r * 1.25, C[3], 0.45 * (1 - q));
    p.disc(x - 1, y - 1, r * 0.65, C[4], 0.22 * (1 - q));
  }
  for (let i = 0; i < 12; i++) {
    const sx = (i % 4 - 1.5) * 7 + rng.range(-1.5, 1.5);
    const sy = (Math.floor(i / 4) - 1) * 8 + rng.range(-1.5, 1.5);
    const vx = (sx * rng.range(3, 5) + rng.range(-18, 18)) * 1.9;
    const vy = (sy * rng.range(3, 5) - rng.range(15, 45)) * 1.65;
    const life = rng.range(0.36, 0.49);
    const angle = rng.range(-0.4, 0.4) + rng.range(-18, 18) * t;
    const baseSize = rng.range(3, 5);
    if (t >= life) continue;
    const shrink = 1 - clamp((t / life - 0.58) / 0.42);
    const x = sx + vx * t * (1 - 0.4 * q), y = sy + vy * t + 190 * t * t;
    const size = baseSize * Math.sqrt(shrink);
    const shape = [[-1,-0.7],[0.6,-1],[1,0.5],[-0.5,0.9]];
    const points = shape.map(([u,v]) => [x + (u * Math.cos(angle) - v * Math.sin(angle)) * size,
      y + (u * Math.sin(angle) + v * Math.cos(angle)) * size]);
    p.poly(points, C[0]);
    p.poly(points.map(([u,v]) => [x + (u-x)*0.72, y + (v-y)*0.72]), C[i % 3 === 0 ? 3 : 2]);
    p.line(points[0][0], points[0][1], points[1][0], points[1][1], C[4]);
  }
  // Small grit leaves the center ahead of the heavy chunks.
  for (let i = 0; i < 8; i++) {
    const a = i / 8 * TAU + rng.range(-0.2, 0.2);
    const speed = rng.range(100, 155), life = rng.range(0.18, 0.3);
    if (t >= life) continue;
    const d = 3 + speed * t * (1 - q * 0.45);
    const x = Math.cos(a) * d, y = Math.sin(a) * d - 12 * t + 80 * t * t;
    p.rect(x, y, t < life * 0.65 ? 2 : 1, 1, C[3]);
  }
  if (t < 0.067) {
    const r = 10 * (1 - t / 0.067);
    p.beam(-r, 0, r, 0, 2, C[5]);
    p.beam(0, -r, 0, r, 2, C[5]);
  }
}
