import { hex, clamp } from '../../pixelfx/src/core/index.js';
export const meta = {
  name: 'Checkpoint idle', desc: 'Alternating side lights rise with short tails and bloom into stars above the sign.',
  size: [96, 96], origin: [48, 80], duration: 2, fps: 30, loop: true, bg: 'dark',
  options: { active: false },
};
const CREAM = hex('#fff0c9');
const CORE = hex('#fff9e8');
const CORAL = hex('#efa99a');
const MINT = hex('#8fd9be');

export function draw(p, t, o) {
  for (let i = 0; i < 2; i++) {
    const q = ((t / meta.duration + i * 0.5) % 1 + 1) % 1;
    const side = i === 0 ? -1 : 1;
    const travel = clamp(q / 0.72);
    const x = side * (34 + 2 * Math.sin(Math.PI * travel));
    const y = -8 - 50 * travel;
    const color = o.active ? MINT : CORAL;
    const brightness = Math.sin(Math.PI * clamp(q / 0.88)) ** 0.6;
    // A tapered tail follows the rising head; both disappear as the star blooms.
    if (q < 0.78) {
      const opacity = brightness * (1 - clamp((q - 0.65) / 0.13));
      for (let j = 5; j >= 1; j--) {
        const tailY = y + j * 2;
        p.ellipse(x - side * j * 0.2, tailY, 1.8 - j * 0.2, 1.3,
          j % 2 ? color : CREAM, opacity * (1 - j / 7));
      }
      p.ellipse(x, y, 2, 2.5, CREAM, opacity);
      p.line(x, y - 1, x, y + 1, CORE, opacity);
      p.glow(x, y, 6, color, opacity * 0.24);
    }
    if (q >= 0.62) {
      const star = clamp((q - 0.62) / 0.38);
      const pulse = Math.sin(Math.PI * star);
      const radius = 5 * pulse;
      p.line(x - radius, -58, x + radius, -58, CREAM, pulse);
      p.line(x, -58 - radius, x, -58 + radius, o.active ? MINT : CREAM, pulse);
      p.ellipse(x, -58, 1.5 * pulse, 1.5 * pulse, CORE, pulse);
      p.glow(x, -58, 8, color, pulse * 0.24);
    }
  }
}
