import { hex } from '../../pixelfx/src/core/index.js';
export const meta = {
  name: 'Food idle sparkles', desc: 'Warm four-point stars open in turn around a collectible dish.',
  size: [96, 96], origin: [48, 48], duration: 2, fps: 30, loop: true, bg: 'dark',
  options: {},
};
export function draw(p, t) {
  const sites = [[-33, -15], [29, -26], [34, 14], [-23, 29]];
  for (let i = 0; i < sites.length; i++) {
    const q = ((t / 2 + i / 4) % 1 + 1) % 1;
    // Each star lives for 0.7s; only one or two are visible together.
    if (q >= 0.35) continue;
    const life = Math.sin(Math.PI * q / 0.35);
    const [x, sy] = sites[i], y = sy - Math.round(q * 5);
    const radius = Math.round(3 * life);
    const alpha = Math.min(1, life * 1.5);
    p.line(x - radius, y, x + radius, y, hex('#edc779'), alpha);
    p.line(x, y - radius, x, y + radius, hex('#edc779'), alpha);
    if (radius >= 2) {
      p.line(x - 1, y, x + 1, y, hex('#fff2ce'), alpha);
      p.line(x, y - 1, x, y + 1, hex('#fff2ce'), alpha);
    }
    if (life > 0.9) p.line(x, y, x, y, hex('#ffffff'), (life - 0.9) * 10);
  }
}
