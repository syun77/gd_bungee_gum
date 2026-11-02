import { Rng, fit, clamp } from '../../pixelfx/src/core/index.js';

export const meta = {
  name: 'Landing dust',
  desc: 'Small warm-gray clouds roll away from the feet, curl upward and break apart.',
  tags: ['landing', 'dust', 'impact', 'one-shot'],
  size: [64, 32], origin: [32, 26], duration: 0.3, fps: 30, loop: false, bg: 'ground',
  options: { palette: ['#8f8582', '#b5aaa0', '#d7ccba', '#f0e6d2'], seed: 17, heavy: false },
};

export function draw(p, t, o) {
  if (t < 0 || t >= meta.duration) return;
  const colors = fit(o.palette, 4), rng = new Rng(o.seed);
  const q = clamp(t / meta.duration);
  const spread = 1 - (1 - q) ** 3;
  const growth = 0.48 + 0.52 * Math.min(1, q / 0.22);
  const decay = (1 - clamp((q - 0.35) / 0.65)) ** 0.85;
  const lobes = [];
  for (const side of [-1, 1]) {
    for (let i = 0; i < (o.heavy ? 4 : 3); i++) {
      const size = (o.heavy ? 4.3 : 3.2) + rng.range(-0.5, 0.8);
      const distance = (o.heavy ? 12 : 8) + i * (o.heavy ? 3.3 : 2.8);
      const x = side * (3 + distance * spread + rng.range(-0.5, 0.5));
      const lift = (o.heavy ? 10 : 6) * q * (0.5 + i * 0.24) + (i % 2) * 2.8 * Math.sin(Math.PI * q);
      const radius = size * growth * decay * (1 - i * q * 0.13);
      const y = -radius * 0.7 - lift - rng.range(0, 1);
      lobes.push({ x, y, r: radius, aspect: 1.1 + rng.range(0, 0.25) });
      // A smaller trailing curl separates as the main cloud disperses.
      lobes.push({ x: x - side * radius * 0.7, y: y - radius * 0.55,
        r: radius * 0.68, aspect: 1.05 });
    }
  }
  function field(x, y) {
    let d = 100;
    for (const l of lobes) {
      d = Math.min(d, Math.hypot((x - l.x) / l.aspect, y - l.y) - l.r);
    }
    return d;
  }
  p.shade(-30, -23, 30, 0, (x, y) => {
    const d = field(x, y);
    if (d > 0) return;
    // The silhouette shrinks and splits instead of fading an unchanged sticker.
    if (d > -0.55) return colors[1];
    if (field(x - 0.5, y - 1) > -0.5) return colors[3];
    if (field(x + 0.2, y + 1) > -0.4) return colors[0];
    return colors[2];
  });
}
