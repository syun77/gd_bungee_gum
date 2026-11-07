// Run: node tools/build_brick_break_effect.mjs. Uses the repository's PixelFX core only.
import { writeFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { renderFrames, contactSheet, spriteSheet } from '../pixelfx/tools/lib/fxlib.mjs';
import * as mod from '../images/effects/brick-break.mjs';
const fx = { id: 'custom/brick-break', meta: mod.meta, mod };
const frames = renderFrames(fx, { bg: 'dark' });
const sheet = spriteSheet(fx, frames, 'brick_break');
for (const folder of ['images/effects', 'gd-bungee-gum/assets/effects']) {
  writeFileSync(fileURLToPath(new URL(`../${folder}/brick_break.png`, import.meta.url)), sheet.png);
}
writeFileSync(fileURLToPath(new URL('../images/effects/brick_break.json', import.meta.url)), JSON.stringify(sheet.json, null, 2) + '\n');
writeFileSync(fileURLToPath(new URL('../images/effects/brick_break_contact.png', import.meta.url)), contactSheet(fx, frames, { max: 16, zoom: 3 }));
console.log(`Brick break: ${frames.n} frames, ${frames.w}x${frames.h}, ${frames.fps}fps`);
