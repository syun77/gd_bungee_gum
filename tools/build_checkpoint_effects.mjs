// Run with Node.js from any directory. Uses only the repository's PixelFX core.
import { writeFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { renderFrames } from '../pixelfx/tools/lib/fxlib.mjs';
import { encodePNG } from '../pixelfx/tools/lib/png.mjs';
import * as idle from '../images/effects/checkpoint-idle.mjs';
import * as burst from '../images/effects/checkpoint-activate.mjs';
for (const [name, mod, options, columns] of [
  ['checkpoint_idle', idle, {}, 10],
  ['checkpoint_active', idle, { active: true }, 10],
  ['checkpoint_activate', burst, {}, 5],
]) {
  const r = renderFrames({ id: name, meta: mod.meta, mod }, { bg: 'none', options });
  const width = r.w * columns, height = r.h * Math.ceil(r.n / columns);
  const pixels = new Uint8Array(width * height * 4);
  for (let i = 0; i < r.n; i++) {
    for (let y = 0; y < r.h; y++) {
      const offset = ((Math.floor(i / columns) * r.h + y) * width + i % columns * r.w) * 4;
      pixels.set(r.frames[i].clear.subarray(y * r.w * 4, (y + 1) * r.w * 4), offset);
    }
  }
  const png = encodePNG(width, height, pixels);
  for (const folder of ['images/effects', 'gd-bungee-gum/assets/effects']) {
    writeFileSync(fileURLToPath(new URL(`../${folder}/${name}.png`, import.meta.url)), png);
  }
}
