import { Rng, fit, clamp, TAU } from '../../pixelfx/src/core/index.js';
export const meta = {
  name: 'Player disappear', desc: 'A cream pop bursts into pink gum flecks, then shrinks away.',
  tags: ['death', 'despawn', 'one-shot'], size: [128, 128], origin: [64, 64],
  duration: 0.6, fps: 30, loop: false, bg: 'ground',
  options: { seed: 23, palette: ['#a64b73', '#e87da5', '#ffb9cf', '#fff4dc'] },
};
export function draw(p, t, o) {
  if (t < 0 || t >= meta.duration) return;
  const C = fit(o.palette, 4), R = new Rng(o.seed), q = t / meta.duration;
  const travel = 1 - (1 - q) ** 3;
  // Staggered lobes give the first flash a soft gum-like silhouette.
  if (t < 0.18) {
    const k = t / 0.18;
    for (let i = 0; i < 8; i++) {
      const a = i * TAU / 8;
      const d = 6 + k * 13, r = (9 + 3 * Math.sin(k * Math.PI)) * (1 - k);
      p.circle(Math.cos(a) * d, Math.sin(a) * d, r, C[2]);
    }
    p.circle(0, 0, 15 * (1 - k), C[3]);
  }
  if (t > 0.02 && t < 0.23) {
    const k = (t - 0.02) / 0.21;
    p.ring(0, 0, 12 + k * 23, Math.max(1, 3 * (1 - k)), C[2], 1 - k);
  }
  for (let i = 0; i < 20; i++) {
    const a = i * TAU / 20 + R.range(-0.12, 0.12);
    const distance = R.range(30, 53), life = R.range(0.36, 0.58);
    const k = clamp(t / life), r = R.range(2.5, 5) * (1 - k) ** 0.75;
    if (t >= life || r < 0.5) continue;
    const x = Math.cos(a) * (5 + distance * travel);
    const y = Math.sin(a) * (7 + distance * travel) * 0.85 - 8 * q;
    p.circle(x, y, r, C[0]);
    p.circle(x - 0.5, y - 0.7, r * 0.8, C[1]);
    p.circle(x - r * 0.25, y - r * 0.35, r * 0.38, C[3]);
  }
  if (t < 0.067) {
    const r = 15 - t * 40;
    p.circle(0, 0, r, C[3]);
    p.rect(-2, -24 * (1 - q), 4, 48 * (1 - q), C[3]);
    p.rect(-22 * (1 - q), -2, 44 * (1 - q), 4, C[3]);
  }
}
