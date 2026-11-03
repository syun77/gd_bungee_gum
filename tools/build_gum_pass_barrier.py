"""Normalize the glass barrier edit and update both tile copies; requires Pillow."""
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / 'images/tilesets/restaurant_gum_pass_barrier_source.png'
# Crop to the silver frame, excluding generated outer padding and edge artifacts.
image = Image.open(SOURCE).convert('RGBA').crop((156, 156, 1098, 1098))
image = image.resize((32, 32), Image.Resampling.NEAREST)
for relative in ['images/tilesets/restaurant_gum_pass_barrier.png',
                 'gd-bungee-gum/assets/tilesets/restaurant_gum_pass_barrier.png']:
    image.save(ROOT / relative)
