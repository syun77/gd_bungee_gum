"""Normalize the temporal hair-lag sheet with a shared transform, preserving source."""
from pathlib import Path
from PIL import Image
ROOT = Path(__file__).resolve().parents[1]
source = Image.open(ROOT / 'images/gum-source/teto_gum_hair_followthrough.png').convert('RGBA')
sheet = Image.new('RGBA', (1024, 512))
for index in range(8):
    x, y = index % 4, index // 4
    cell = source.crop((x * source.width // 4, y * source.height // 2,
                        (x + 1) * source.width // 4, (y + 1) * source.height // 2))
    cell.putalpha(cell.getchannel('A').point(lambda a: 255 if a >= 128 else 0))
    cell = cell.resize((244, 244), Image.Resampling.NEAREST)
    sheet.paste(cell, (x * 256 + 6, y * 256 + 18))
for folder in ['images/normalized', 'gd-bungee-gum/assets/characters/teto']:
    sheet.save(ROOT / folder / 'teto_gum_hair_followthrough.png')
