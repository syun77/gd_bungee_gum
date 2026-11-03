import { hex, clamp } from '../../pixelfx/src/core/index.js';
export const meta = {
  name: 'Checkpoint activation', desc: 'Elastic side arcs recoil, then six stars celebrate the completed check.',
  size: [128, 96], origin: [64, 80], duration: 0.8, fps: 30, loop: false, bg: 'dark', options: {},
};
export function draw(p, t) {
  if (t < 0 || t >= meta.duration - 1e-6) return;
  if (t < 0.4) {
    const q = clamp(t / 0.4), swell = Math.sin(Math.PI * q);
    for (const side of [-1, 1]) {
      let last;
      for (let i = 0; i <= 14; i++) {
        const u = i / 14;
        const x = side * (30 + 15 * swell * Math.sin(Math.PI * u));
        const y = -5 - u * (20 + 33 * swell);
        if (last) {
          p.line(last.x, last.y, x, y, hex('#91ddbf'), Math.sqrt(swell));
          p.line(last.x + side, last.y, x + side, y, hex('#d0f5de'), Math.sqrt(swell) * 0.9);
        }
        last = { x, y };
      }
      p.ellipse(last.x, last.y, 2.5, 2.5, hex('#fff1ce'), swell);
    }
  }
  if (t >= 0.4) {
    const q = clamp((t - 0.4) / 0.4), ease = 1 - (1 - q) ** 2;
    for (let i = 0; i < 6; i++) {
      const side = i % 2 ? 1 : -1, row = Math.floor(i / 2);
      const x = side * (17 + row * 8 + ease * (9 + row * 2));
      const y = -53 + row * 13 - ease * (14 - row * 2);
      const r = (4.5 - row * 0.4) * Math.sin(Math.PI * (0.18 + q * 0.82));
      const color = i % 3 === 0 ? hex('#fff1ce') : hex('#9ce4c5');
      p.line(x - r, y, x + r, y, color, Math.sqrt(1 - q));
      p.line(x, y - r, x, y + r, color, Math.sqrt(1 - q));
      p.ellipse(x, y, 1.2, 1.2, hex('#fff5dd'), Math.sqrt(1 - q));
      p.glow(x, y, 7, color, (1 - q) * 0.2);
    }
  }
}
